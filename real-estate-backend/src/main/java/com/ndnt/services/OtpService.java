package com.ndnt.services;

public interface OtpService {
    String generateOtp(String key, String targetEmail);

    boolean validateOtp(String key, String otp);

    String getResetToken(String key);

    boolean validateResetToken(String key, String resetToken);

    String getTargetEmail(String key);

    void clear(String key);
}
