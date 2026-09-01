package com.ndnt.services;

public interface EmailService {
    void sendOtpEmail(String toEmail, String otp, String recipientName);
}
