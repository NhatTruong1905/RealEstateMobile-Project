package com.ndnt.controllers.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.dto.UserInfoDTO;
import com.ndnt.model.dto.request.ForgotPasswordRequest;
import com.ndnt.model.dto.request.ResetPasswordRequest;
import com.ndnt.model.dto.request.VerifyOtpRequest;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.services.EmailService;
import com.ndnt.services.OtpService;
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

    @Mock
    private EmailService emailService;

    @Mock
    private OtpService otpService;

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

    @Test
    @DisplayName("POST /api/auth/forgot-password - Tài khoản đã có email -> Gửi OTP thành công")
    void forgotPassword_WithExistingEmail_Success() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .identifier("testuser")
                .build();

        UserEntity user = new UserEntity();
        user.setUsername("testuser");
        user.setEmail("user@gmail.com");
        user.setFullname("Nguyen Van A");

        when(userService.findEntityByIdentifier("testuser")).thenReturn(user);
        when(otpService.generateOtp("testuser", "user@gmail.com")).thenReturn("123456");
        doNothing().when(emailService).sendOtpEmail(eq("user@gmail.com"), eq("123456"), eq("Nguyen Van A"));

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("OTP_SENT"))
                .andExpect(jsonPath("$.hasEmail").value(true))
                .andExpect(jsonPath("$.maskedEmail").value("us***@gmail.com"));

        verify(otpService, times(1)).generateOtp("testuser", "user@gmail.com");
        verify(emailService, times(1)).sendOtpEmail(eq("user@gmail.com"), eq("123456"), eq("Nguyen Van A"));
    }

    @Test
    @DisplayName("POST /api/auth/forgot-password - Tài khoản chưa có email -> Yêu cầu nhập email")
    void forgotPassword_NoEmail_RequireEmail() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .identifier("0987654321")
                .build();

        UserEntity user = new UserEntity();
        user.setUsername("phoneuser");
        user.setPhone("0987654321");
        user.setEmail(null);

        when(userService.findEntityByIdentifier("0987654321")).thenReturn(user);

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REQUIRE_EMAIL"))
                .andExpect(jsonPath("$.hasEmail").value(false));

        verify(otpService, never()).generateOtp(any(), any());
        verify(emailService, never()).sendOtpEmail(any(), any(), any());
    }

    @Test
    @DisplayName("POST /api/auth/forgot-password - Tài khoản chưa có email + Người dùng cung cấp email -> Gửi OTP thành công")
    void forgotPassword_NoEmail_WithProvidedEmail_Success() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .identifier("0987654321")
                .email("newemail@gmail.com")
                .build();

        UserEntity user = new UserEntity();
        user.setUsername("phoneuser");
        user.setPhone("0987654321");
        user.setEmail(null);
        user.setFullname("Phone User");

        when(userService.findEntityByIdentifier("0987654321")).thenReturn(user);
        when(otpService.generateOtp("0987654321", "newemail@gmail.com")).thenReturn("654321");
        doNothing().when(emailService).sendOtpEmail(eq("newemail@gmail.com"), eq("654321"), eq("Phone User"));

        mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("OTP_SENT"))
                .andExpect(jsonPath("$.hasEmail").value(false))
                .andExpect(jsonPath("$.maskedEmail").value("ne***@gmail.com"));

        verify(otpService, times(1)).generateOtp("0987654321", "newemail@gmail.com");
    }

    @Test
    @DisplayName("POST /api/auth/verify-otp - Xác thực OTP thành công -> Trả về resetToken")
    void verifyOtp_Success() throws Exception {
        VerifyOtpRequest request = VerifyOtpRequest.builder()
                .identifier("testuser")
                .otp("123456")
                .build();

        when(otpService.validateOtp("testuser", "123456")).thenReturn(true);
        when(otpService.getResetToken("testuser")).thenReturn("mock-reset-token-uuid");

        mockMvc.perform(post("/api/auth/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUCCESS"))
                .andExpect(jsonPath("$.resetToken").value("mock-reset-token-uuid"));
    }

    @Test
    @DisplayName("POST /api/auth/verify-otp - Nhập sai OTP -> Trả về 400 Bad Request")
    void verifyOtp_WrongOtp() throws Exception {
        VerifyOtpRequest request = VerifyOtpRequest.builder()
                .identifier("testuser")
                .otp("999999")
                .build();

        when(otpService.validateOtp("testuser", "999999")).thenReturn(false);

        mockMvc.perform(post("/api/auth/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value("FAIL"));
    }

    @Test
    @DisplayName("POST /api/auth/reset-password - Đặt lại mật khẩu thành công")
    void resetPassword_Success() throws Exception {
        ResetPasswordRequest request = ResetPasswordRequest.builder()
                .identifier("testuser")
                .resetToken("valid-token")
                .newPassword("newPass1234")
                .build();

        when(otpService.validateResetToken("testuser", "valid-token")).thenReturn(true);
        when(otpService.getTargetEmail("testuser")).thenReturn("test@gmail.com");
        doNothing().when(userService).resetPassword("testuser", "newPass1234", "test@gmail.com");
        doNothing().when(otpService).clear("testuser");

        mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUCCESS"));

        verify(userService, times(1)).resetPassword("testuser", "newPass1234", "test@gmail.com");
        verify(otpService, times(1)).clear("testuser");
    }
}
