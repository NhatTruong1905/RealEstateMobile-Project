package com.ndnt.controllers.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.UserInfoDTO;
import com.ndnt.services.UserService;
import com.ndnt.utils.JwtUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
public class APILoginControllerTest {

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @Mock
    private UserService userService;

    @Mock
    private JwtUtils jwtUtils;

    @InjectMocks
    private APILoginController apiLoginController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(apiLoginController).build();
        objectMapper = new ObjectMapper();
    }

    @Test
    @DisplayName("POST /api/auth/login - Đăng nhập thành công trả về JWT token")
    void login_Success() throws Exception {
        UserDTO loginRequest = new UserDTO();
        loginRequest.setUsername("testuser");
        loginRequest.setPassword("password123");

        UserDTO fullUser = new UserDTO();
        fullUser.setId(1);
        fullUser.setUsername("testuser");

        when(userService.findByUsername("testuser")).thenReturn(fullUser);
        when(userService.authenticate("testuser", "password123")).thenReturn(true);
        when(jwtUtils.generateToken(fullUser)).thenReturn("mocked-jwt-token");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("mocked-jwt-token"));

        verify(userService, times(1)).findByUsername("testuser");
        verify(userService, times(1)).authenticate("testuser", "password123");
        verify(jwtUtils, times(1)).generateToken(fullUser);
    }

    @Test
    @DisplayName("POST /api/auth/login - Tài khoản không tồn tại trả về 404")
    void login_UserNotFound() throws Exception {
        UserDTO loginRequest = new UserDTO();
        loginRequest.setUsername("nonexistent");
        loginRequest.setPassword("password123");

        when(userService.findByUsername("nonexistent")).thenReturn(null);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isNotFound())
                .andExpect(result -> {
                    String content = result.getResponse().getContentAsString();
                    assertNotNull(content);
                    assertFalse(content.isEmpty());
                });

        verify(userService, times(1)).findByUsername("nonexistent");
        verify(userService, never()).authenticate(any(), any());
    }

    @Test
    @DisplayName("POST /api/auth/login - Sai mật khẩu trả về 401")
    void login_WrongPassword() throws Exception {
        UserDTO loginRequest = new UserDTO();
        loginRequest.setUsername("testuser");
        loginRequest.setPassword("wrongpassword");

        UserDTO fullUser = new UserDTO();
        fullUser.setId(1);
        fullUser.setUsername("testuser");

        when(userService.findByUsername("testuser")).thenReturn(fullUser);
        when(userService.authenticate("testuser", "wrongpassword")).thenReturn(false);

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(result -> {
                    String content = result.getResponse().getContentAsString();
                    assertNotNull(content);
                    assertFalse(content.isEmpty());
                });

        verify(userService, times(1)).findByUsername("testuser");
        verify(userService, times(1)).authenticate("testuser", "wrongpassword");
    }

    @Test
    @DisplayName("POST /api/auth/register - Đăng ký tài khoản thành công")
    void register_Success() throws Exception {
        UserInfoDTO registerRequest = new UserInfoDTO();
        registerRequest.setUsername("newuser");
        registerRequest.setPassword("password123");
        registerRequest.setEmail("newuser@gmail.com");
        registerRequest.setPhone("0987654321");
        registerRequest.setFullname("New User");

        doNothing().when(userService).createOrUpdateUser(any(UserInfoDTO.class));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Register Success"));

        verify(userService, times(1)).createOrUpdateUser(any(UserInfoDTO.class));
    }
}
