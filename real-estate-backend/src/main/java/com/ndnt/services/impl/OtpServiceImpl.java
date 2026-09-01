package com.ndnt.services.impl;

import com.ndnt.services.OtpService;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OtpServiceImpl implements OtpService {

    private static final long OTP_VALIDITY_DURATION_MS = 2 * 60 * 1000;
    private static final long RESET_TOKEN_VALIDITY_DURATION_MS = 5 * 60 * 1000;

    private final SecureRandom secureRandom = new SecureRandom();
    private final Map<String, OtpData> otpStorage = new ConcurrentHashMap<>();
    private final Map<String, ResetTokenData> resetTokenStorage = new ConcurrentHashMap<>();

    @Override
    public String generateOtp(String key, String targetEmail) {
        String normalizedKey = normalizeKey(key);
        int number = secureRandom.nextInt(1000000);
        String otp = String.format("%06d", number);
        long expiryTime = System.currentTimeMillis() + OTP_VALIDITY_DURATION_MS;

        otpStorage.put(normalizedKey, new OtpData(otp, targetEmail, expiryTime));
        return otp;
    }

    @Override
    public boolean validateOtp(String key, String otp) {
        String normalizedKey = normalizeKey(key);
        OtpData data = otpStorage.get(normalizedKey);

        if (data == null) {
            return false;
        }

        if (System.currentTimeMillis() > data.expiryTime()) {
            otpStorage.remove(normalizedKey);
            return false;
        }

        if (data.otp().equals(otp != null ? otp.trim() : "")) {
            String resetToken = UUID.randomUUID().toString();
            long resetTokenExpiry = System.currentTimeMillis() + RESET_TOKEN_VALIDITY_DURATION_MS;
            resetTokenStorage.put(normalizedKey, new ResetTokenData(resetToken, data.email(), resetTokenExpiry));

            otpStorage.remove(normalizedKey);
            return true;
        }

        return false;
    }

    @Override
    public String getResetToken(String key) {
        String normalizedKey = normalizeKey(key);
        ResetTokenData tokenData = resetTokenStorage.get(normalizedKey);
        if (tokenData != null && System.currentTimeMillis() <= tokenData.expiryTime()) {
            return tokenData.token();
        }
        return null;
    }

    @Override
    public boolean validateResetToken(String key, String resetToken) {
        String normalizedKey = normalizeKey(key);
        ResetTokenData tokenData = resetTokenStorage.get(normalizedKey);

        if (tokenData == null) {
            return false;
        }

        if (System.currentTimeMillis() > tokenData.expiryTime()) {
            resetTokenStorage.remove(normalizedKey);
            return false;
        }

        return tokenData.token().equals(resetToken != null ? resetToken.trim() : "");
    }

    @Override
    public String getTargetEmail(String key) {
        String normalizedKey = normalizeKey(key);
        ResetTokenData resetData = resetTokenStorage.get(normalizedKey);
        if (resetData != null && resetData.email() != null && !resetData.email().isBlank()) {
            return resetData.email();
        }

        OtpData otpData = otpStorage.get(normalizedKey);
        if (otpData != null) {
            return otpData.email();
        }

        return null;
    }

    @Override
    public void clear(String key) {
        String normalizedKey = normalizeKey(key);
        otpStorage.remove(normalizedKey);
        resetTokenStorage.remove(normalizedKey);
    }

    private String normalizeKey(String key) {
        return key != null ? key.trim().toLowerCase() : "";
    }

    private record OtpData(String otp, String email, long expiryTime) {}
    private record ResetTokenData(String token, String email, long expiryTime) {}
}
