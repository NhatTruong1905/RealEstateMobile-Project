package com.ndnt.services.impl;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class OtpServiceImplTest {

    private OtpServiceImpl otpService;

    @BeforeEach
    void setUp() {
        otpService = new OtpServiceImpl();
    }

    @Test
    @DisplayName("generateOtp - Sinh mã OTP 6 chữ số hợp lệ")
    void generateOtp_Success() {
        String key = "testuser";
        String email = "test@gmail.com";

        String otp = otpService.generateOtp(key, email);

        assertNotNull(otp);
        assertEquals(6, otp.length());
        assertTrue(otp.matches("\\d{6}"));
        assertEquals("test@gmail.com", otpService.getTargetEmail(key));
    }

    @Test
    @DisplayName("validateOtp - Xác thực đúng mã OTP và cấp resetToken")
    void validateOtp_Success() {
        String key = "testuser";
        String email = "test@gmail.com";
        String otp = otpService.generateOtp(key, email);

        boolean isValid = otpService.validateOtp(key, otp);

        assertTrue(isValid);
        String resetToken = otpService.getResetToken(key);
        assertNotNull(resetToken);
        assertFalse(resetToken.isEmpty());
        assertTrue(otpService.validateResetToken(key, resetToken));
    }

    @Test
    @DisplayName("validateOtp - Xác thực thất bại khi nhập sai mã OTP")
    void validateOtp_WrongOtp() {
        String key = "testuser";
        String email = "test@gmail.com";
        otpService.generateOtp(key, email);

        boolean isValid = otpService.validateOtp(key, "999999");

        assertFalse(isValid);
        assertNull(otpService.getResetToken(key));
    }

    @Test
    @DisplayName("validateOtp - Không thể dùng lại mã OTP đã xác thực")
    void validateOtp_CannotReuseOtp() {
        String key = "testuser";
        String email = "test@gmail.com";
        String otp = otpService.generateOtp(key, email);

        assertTrue(otpService.validateOtp(key, otp));
        assertFalse(otpService.validateOtp(key, otp));
    }

    @Test
    @DisplayName("generateOtp - Gửi lại OTP sẽ ghi đè và làm vô hiệu hóa mã OTP cũ")
    void generateOtp_ResendOtp_InvalidatesOldOtp() {
        String key = "testuser";
        String email = "test@gmail.com";

        String otp1 = otpService.generateOtp(key, email);
        String otp2 = otpService.generateOtp(key, email);

        assertFalse(otpService.validateOtp(key, otp1));
        assertTrue(otpService.validateOtp(key, otp2));
    }

    @Test
    @DisplayName("clear - Xóa dữ liệu OTP và ResetToken")
    void clear_Success() {
        String key = "testuser";
        String email = "test@gmail.com";
        String otp = otpService.generateOtp(key, email);
        otpService.validateOtp(key, otp);

        otpService.clear(key);

        assertNull(otpService.getResetToken(key));
        assertFalse(otpService.validateResetToken(key, "some_token"));
    }
}
