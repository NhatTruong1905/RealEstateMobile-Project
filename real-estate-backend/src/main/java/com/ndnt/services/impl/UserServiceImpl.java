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
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
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
    public Page<UserDTO> getUsers(Pageable pageable) {
        Page<UserEntity> userEntities = this.userRepository.findAllByStatus(1, pageable);

        return userEntities.map(u -> {
            UserDTO uDTO = this.userConverter.toUserDTO(u);
            if (u.getRole() != null) {
                uDTO.setRoleId(u.getRole().getId());
                uDTO.setRoleCode(u.getRole().getCode());
                uDTO.setRoleName(u.getRole().getName());
            }
            return uDTO;
        });
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

}

