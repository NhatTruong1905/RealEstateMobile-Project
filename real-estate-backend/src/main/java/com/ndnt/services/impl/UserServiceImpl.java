package com.ndnt.services.impl;

import com.ndnt.converter.UserConverter;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@Transactional
public class UserServiceImpl implements UserService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserConverter userConverter;

    @Autowired
    private BCryptPasswordEncoder bCryptPasswordEncoder;

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
    public List<UserDTO> getUsers() {
        List<UserEntity> userEntities = this.userRepository.findAllByStatusOrderByIdDesc(1);

        List<UserDTO> userDTOs = new ArrayList<>();
        for (UserEntity u : userEntities) {
            UserDTO uDTO = this.userConverter.toUserDTO(u);
            uDTO.setRoleId(u.getRole().getId());
            uDTO.setRoleCode(u.getRole().getCode());
            uDTO.setRoleName(u.getRole().getName());
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
    public void createOrUpdateUser(UserDTO userDTO) {
//        UserEntity user = userConverter.toUserEntity(userDTO);
//        UserEntity existingUser = userRepository.getUserByUsername(userDTO.getUsername());
//        UserEntity existingEmailUser = null;
//
//        if (userDTO.getEmail() != null && !userDTO.getEmail().trim().isEmpty()) {
//            existingEmailUser = userRepository.getUserByEmail(userDTO.getEmail().trim());
//        }
//        if (userDTO.getId() == null) {
//            if (existingUser != null) {
//                throw new DuplicateUsernameException("Tên đăng nhập đã tồn tại!");
//            }
//            if (existingEmailUser != null) {
//                throw new DuplicateEmailException("Email này đã được sử dụng!");
//            }
//            if (userDTO.getPassword() == null || userDTO.getPassword().trim().isEmpty()) {
//                throw new InvalidPasswordException("Vui lòng nhập mật khẩu!");
//            }
//            user.setRole(RoleUser.ROLE_CUSTOMER.name());
//            user.setPassword(bCryptPasswordEncoder.encode(userDTO.getPassword()));
//        } else {
//            if (existingUser != null && !existingUser.getId().equals(userDTO.getId())) {
//                throw new DuplicateUsernameException("Tên đăng nhập đã tồn tại!");
//            }
//            if (existingEmailUser != null && !existingEmailUser.getId().equals(userDTO.getId())) {
//                throw new DuplicateEmailException("Email này đã được sử dụng bởi người khác!");
//            }
//            if (userDTO.getPassword() != null && !userDTO.getPassword().trim().isEmpty()) {
//                user.setPassword(bCryptPasswordEncoder.encode(userDTO.getPassword()));
//            } else {
//                User oldUser = userRepository.getUserById(userDTO.getId());
//                user.setPassword(oldUser.getPassword());
//            }
//        }
    }
}
