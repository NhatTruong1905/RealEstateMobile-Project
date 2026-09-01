package com.ndnt.services.impl;

import com.cloudinary.Cloudinary;
import com.ndnt.controlleradvices.exceptions.DuplicateEmailException;
import com.ndnt.controlleradvices.exceptions.DuplicatePhoneException;
import com.ndnt.controlleradvices.exceptions.DuplicateUsernameException;
import com.ndnt.converter.UserConverter;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.UserInfoDTO;
import com.ndnt.model.entity.RoleEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.RoleRepository;
import com.ndnt.repositories.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserConverter userConverter;

    @Mock
    private BCryptPasswordEncoder bCryptPasswordEncoder;

    @Mock
    private Cloudinary cloudinary;

    @Mock
    private RoleRepository roleRepository;

    @InjectMocks
    private UserServiceImpl userService;

    @Test
    @DisplayName("loadUserByUsername - Tìm thấy user trả về UserDetails")
    void loadUserByUsername_Success() {
        UserEntity userEntity = new UserEntity();
        userEntity.setUsername("testuser");
        userEntity.setPassword("hashedpassword");
        RoleEntity role = new RoleEntity();
        role.setCode("ROLE_USER");
        userEntity.setRole(role);

        when(userRepository.getUserByUsername("testuser")).thenReturn(userEntity);

        UserDetails userDetails = userService.loadUserByUsername("testuser");

        assertNotNull(userDetails);
        assertEquals("testuser", userDetails.getUsername());
        assertEquals("hashedpassword", userDetails.getPassword());
        assertTrue(userDetails.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_USER")));
        verify(userRepository, times(1)).getUserByUsername("testuser");
    }

    @Test
    @DisplayName("loadUserByUsername - Không tìm thấy user ném UsernameNotFoundException")
    void loadUserByUsername_NotFound() {
        when(userRepository.getUserByUsername("nonexistent")).thenReturn(null);

        assertThrows(UsernameNotFoundException.class, () -> {
            userService.loadUserByUsername("nonexistent");
        });

        verify(userRepository, times(1)).getUserByUsername("nonexistent");
    }

    @Test
    @DisplayName("findById - Tìm thấy user")
    void findById_Success() {
        UserEntity userEntity = new UserEntity();
        userEntity.setId(1);
        UserDTO userDTO = new UserDTO();
        userDTO.setId(1);

        when(userRepository.findById(1)).thenReturn(Optional.of(userEntity));
        when(userConverter.toUserDTO(userEntity)).thenReturn(userDTO);

        UserDTO result = userService.findById(1);

        assertNotNull(result);
        assertEquals(1, result.getId());
        verify(userRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("deleteUser - Xóa mềm (cập nhật status = 0)")
    void deleteUser_Success() {
        UserEntity userEntity = new UserEntity();
        userEntity.setId(1);
        userEntity.setStatus(1);

        when(userRepository.findById(1)).thenReturn(Optional.of(userEntity));
        when(userRepository.save(userEntity)).thenReturn(userEntity);

        userService.deleteUser(1);

        assertEquals(0, userEntity.getStatus());
        verify(userRepository, times(1)).save(userEntity);
    }

    @Test
    @DisplayName("createOrUpdateUser - Ném DuplicateUsernameException nếu username đã tồn tại")
    void createOrUpdateUser_DuplicateUsername() {
        UserInfoDTO infoDTO = new UserInfoDTO();
        infoDTO.setUsername("existinguser");

        when(userRepository.existsByUsername("existinguser")).thenReturn(true);

        assertThrows(DuplicateUsernameException.class, () -> {
            userService.createOrUpdateUser(infoDTO);
        });

        verify(userRepository, times(1)).existsByUsername("existinguser");
    }

    @Test
    @DisplayName("createOrUpdateUser - Ném DuplicatePhoneException nếu phone đã tồn tại")
    void createOrUpdateUser_DuplicatePhone() {
        UserInfoDTO infoDTO = new UserInfoDTO();
        infoDTO.setUsername("newuser");
        infoDTO.setPhone("0987654321");

        when(userRepository.existsByUsername("newuser")).thenReturn(false);
        when(userRepository.existsByPhone("0987654321")).thenReturn(true);

        assertThrows(DuplicatePhoneException.class, () -> {
            userService.createOrUpdateUser(infoDTO);
        });

        verify(userRepository, times(1)).existsByPhone("0987654321");
    }

    @Test
    @DisplayName("createOrUpdateUser - Ném DuplicateEmailException nếu email đã tồn tại")
    void createOrUpdateUser_DuplicateEmail() {
        UserInfoDTO infoDTO = new UserInfoDTO();
        infoDTO.setUsername("newuser");
        infoDTO.setPhone("0987654321");
        infoDTO.setEmail("duplicate@gmail.com");

        when(userRepository.existsByUsername("newuser")).thenReturn(false);
        when(userRepository.existsByPhone("0987654321")).thenReturn(false);
        when(userRepository.existsByEmail("duplicate@gmail.com")).thenReturn(true);

        assertThrows(DuplicateEmailException.class, () -> {
            userService.createOrUpdateUser(infoDTO);
        });

        verify(userRepository, times(1)).existsByEmail("duplicate@gmail.com");
    }

    @Test
    @DisplayName("authenticate - Kiểm tra mật khẩu chính xác")
    void authenticate_Success() {
        UserEntity userEntity = new UserEntity();
        userEntity.setUsername("testuser");
        userEntity.setPassword("hashedpassword");

        when(userRepository.findByUsername("testuser")).thenReturn(userEntity);
        when(bCryptPasswordEncoder.matches("rawpassword", "hashedpassword")).thenReturn(true);

        boolean result = userService.authenticate("testuser", "rawpassword");

        assertTrue(result);
        verify(userRepository, times(1)).findByUsername("testuser");
        verify(bCryptPasswordEncoder, times(1)).matches("rawpassword", "hashedpassword");
    }

    @Test
    @DisplayName("authenticate - Kiểm tra mật khẩu sai trả về false")
    void authenticate_WrongPassword() {
        UserEntity userEntity = new UserEntity();
        userEntity.setUsername("testuser");
        userEntity.setPassword("hashedpassword");

        when(userRepository.findByUsername("testuser")).thenReturn(userEntity);
        when(bCryptPasswordEncoder.matches("wrongpassword", "hashedpassword")).thenReturn(false);

        boolean result = userService.authenticate("testuser", "wrongpassword");

        assertFalse(result);
    }
}
