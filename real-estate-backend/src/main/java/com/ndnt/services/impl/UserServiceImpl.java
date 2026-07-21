package com.ndnt.services.impl;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.ndnt.controlleradvices.exceptions.DuplicateEmailException;
import com.ndnt.controlleradvices.exceptions.DuplicatePhoneException;
import com.ndnt.controlleradvices.exceptions.DuplicateUsernameException;
import com.ndnt.controlleradvices.exceptions.InvalidUserException;
import com.ndnt.converter.UserConverter;
import com.ndnt.model.dto.UserAdminDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.request.UserRequestDTO;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.UserService;
import jakarta.persistence.criteria.Predicate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
@Transactional
public class UserServiceImpl implements UserService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserConverter userConverter;

    @Autowired
    private BCryptPasswordEncoder bCryptPasswordEncoder;

    @Autowired
    private Cloudinary cloudinary;


    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        UserEntity userEntity = this.userRepository.getUserByUsername(username);
        if (userEntity == null) {
            throw new UsernameNotFoundException("Không tồn tại!");
        }

        Set<GrantedAuthority> authorities = new HashSet<>();
        authorities.add(new SimpleGrantedAuthority(userEntity.getRole().getCode()));

        return new org.springframework.security.core.userdetails.User(userEntity.getUsername(),
                userEntity.getPassword(), authorities);
    }

    @Override
    public Page<UserDTO> getUsers(UserRequestDTO searchDTO, Pageable pageable) {
        Specification<UserEntity> spec = (root, query, builder) -> {
            List<Predicate> predicates = new ArrayList<>();

            predicates.add(builder.equal(root.get("status"), 1));

            if (searchDTO != null) {
                if (searchDTO.getUsername() != null && !searchDTO.getUsername().isBlank())
                    predicates.add(builder.like(root.get("username"), "%" + searchDTO.getUsername().trim() + "%"));
                if (searchDTO.getFullname() != null && !searchDTO.getFullname().isBlank())
                    predicates.add(builder.like(root.get("fullname"), "%" + searchDTO.getFullname().trim() + "%"));
                if (searchDTO.getEmail() != null && !searchDTO.getEmail().isBlank())
                    predicates.add(builder.like(root.get("email"), "%" + searchDTO.getEmail().trim() + "%"));
                if (searchDTO.getPhone() != null && !searchDTO.getPhone().isBlank())
                    predicates.add(builder.like(root.get("phone"), "%" + searchDTO.getPhone().trim() + "%"));
                if (searchDTO.getStaffId() != null) {
                    predicates.add(builder.equal(root.join("assignmentUserUsers").join("staff").get("id"), searchDTO.getStaffId()));
                }
                if (searchDTO.getRoleId() != null) {
                    predicates.add(builder.equal(root.join("role").get("id"), searchDTO.getRoleId()));
                }
            }
            return builder.and(predicates.toArray(new Predicate[0]));
        };

        return this.userRepository.findAll(spec, pageable).map(u -> {
            UserDTO uDTO = this.userConverter.toUserDTO(u);
            if (u.getRole() != null) {
                uDTO.setRoleCode(u.getRole().getCode());
                uDTO.setRoleName(u.getRole().getName());
                uDTO.setRoleId(u.getRole().getId());
            }
            return uDTO;
        });
    }

    @Override
    public List<UserDTO> getUsers() {
        List<UserEntity> userEntities = this.userRepository.findAllByStatusAndRole_Code(1, "ROLE_USER");
        List<UserDTO> userDTOs = new ArrayList<>();
        for (UserEntity uEntity : userEntities) {
            UserDTO uDTO = this.userConverter.toUserDTO(uEntity);
            if (uEntity.getRole() != null) {
                uDTO.setRoleId(uEntity.getRole().getId());
                uDTO.setRoleCode(uEntity.getRole().getCode());
                uDTO.setRoleName(uEntity.getRole().getName());
            }
            userDTOs.add(uDTO);
        }
        return userDTOs;
    }

    @Override
    public List<UserDTO> getListStaff() {
        List<UserEntity> userEntities = this.userRepository.findAllByStatusAndRole_Code(1, "ROLE_STAFF");
        List<UserDTO> userDTOs = new ArrayList<>();
        for (UserEntity uEntity : userEntities) {
            UserDTO uDTO = this.userConverter.toUserDTO(uEntity);
            if (uEntity.getRole() != null) {
                uDTO.setRoleId(uEntity.getRole().getId());
                uDTO.setRoleCode(uEntity.getRole().getCode());
                uDTO.setRoleName(uEntity.getRole().getName());
            }
            userDTOs.add(uDTO);
        }
        return userDTOs;
    }

    @Override
    public UserDTO findById(Integer id) {
        return this.userConverter.toUserDTO(this.userRepository.findById(id).get());
    }

    @Override
    public void deleteUser(Integer id) {
        UserEntity userEntity = this.userRepository.findById(id).get();
        userEntity.setStatus(0);
        this.userRepository.save(userEntity);
    }

    @Override
    public void createOrUpdateUser(UserAdminDTO userDTO) {
        UserEntity userEntity = this.userConverter.toUserEntity(userDTO);
        if (userDTO.getId() == null) {
            if (userDTO.getUsername() != null
                    && !userDTO.getUsername().isEmpty()
                    && this.userRepository.existsByUsername(userDTO.getUsername().trim())) {
                throw new DuplicateUsernameException("Tên đăng nhập đã tồn tại! Thử tên khác!");
            }
            if (userDTO.getPhone() != null
                    && !userDTO.getPhone().isEmpty()
                    && this.userRepository.existsByPhone(userDTO.getPhone().trim())) {
                throw new DuplicatePhoneException("Số điện thoại người dùng đã tồn tại! Thử số khác!");
            }
            if (userDTO.getEmail() != null
                    && !userDTO.getEmail().isEmpty()
                    && this.userRepository.existsByEmail(userDTO.getEmail().trim())) {
                throw new DuplicateEmailException("Email người dùng đã tồn tại! Thử số khác!");
            }
            userEntity.setPassword(this.bCryptPasswordEncoder.encode("123456"));
        } else {
            if (userDTO.getPassword() != null && !userDTO.getPassword().trim().isEmpty()) {
                userEntity.setPassword(bCryptPasswordEncoder.encode(userDTO.getPassword()));
            } else {
                UserEntity oldUser = userRepository.findById(userDTO.getId()).get();
                userEntity.setPassword(oldUser.getPassword());
            }
        }

        if (userDTO.getFile() != null && !userDTO.getFile().isEmpty()) {
            try {
                Map res = this.cloudinary.uploader().upload(userDTO.getFile().getBytes(),
                        ObjectUtils.asMap("resource_type", "auto"));
                userEntity.setAvatar(res.get("secure_url").toString());
            } catch (IOException ex) {
                Logger.getLogger(UserServiceImpl.class.getName()).log(Level.SEVERE, "Lỗi upload avatar", ex);
                throw new RuntimeException("Lỗi hệ thống: Không thể tải lên ảnh đại diện!", ex);
            }
        } else {
            if (userDTO.getId() != null) {
                UserEntity oldUser = this.userRepository.findById(userDTO.getId()).get();
                userEntity.setAvatar(oldUser.getAvatar());
            }
        }
        this.userRepository.save(userEntity);
    }

    @Override
    public UserDTO findByUsername(String username) {
        return this.userConverter.toUserDTO(this.userRepository.findByUsername(username));
    }

    @Override
    public boolean authenticate(String username, String password) {
        UserEntity u = this.userRepository.findByUsername(username);
        return this.bCryptPasswordEncoder.matches(password, u.getPassword());
    }

}

