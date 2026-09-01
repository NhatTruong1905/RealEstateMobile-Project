package com.ndnt.controllers.api;

import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.UserInfoDTO;
import com.ndnt.services.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.security.Principal;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
public class APIUserControllerTest {

    private MockMvc mockMvc;

    @Mock
    private UserService userService;

    @InjectMocks
    private APIUserController apiUserController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(apiUserController).build();
    }

    @Test
    @DisplayName("GET /api/secure/profile - Lấy thông tin user thành công")
    void getProfile_Success() throws Exception {
        Principal principal = () -> "testuser";
        UserDTO userDTO = new UserDTO();
        userDTO.setId(1);
        userDTO.setUsername("testuser");
        userDTO.setEmail("test@gmail.com");

        when(userService.findByUsername("testuser")).thenReturn(userDTO);

        mockMvc.perform(get("/api/secure/profile").principal(principal))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data.username").value("testuser"))
                .andExpect(jsonPath("$.data.email").value("test@gmail.com"));

        verify(userService, times(1)).findByUsername("testuser");
    }

    @Test
    @DisplayName("POST /api/secure/update/profile - Cập nhật thông tin profile thành công")
    void updateProfile_Success() throws Exception {
        Principal principal = () -> "testuser";
        UserDTO currentUser = new UserDTO();
        currentUser.setId(1);
        currentUser.setUsername("testuser");

        when(userService.findByUsername("testuser")).thenReturn(currentUser);
        doNothing().when(userService).createOrUpdateUser(any(UserInfoDTO.class));

        mockMvc.perform(multipart("/api/secure/update/profile")
                        .param("username", "testuser")
                        .param("fullname", "Nguyen Van A")
                        .param("phone", "0912345678")
                        .principal(principal))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"));

        verify(userService, times(1)).findByUsername("testuser");
        verify(userService, times(1)).createOrUpdateUser(any(UserInfoDTO.class));
    }
}
