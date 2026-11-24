package com.ndnt.services.impl;

import com.ndnt.services.EmailService;
import com.ndnt.services.EmailTemplate;
import com.ndnt.services.ResendMailClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailServiceImpl implements EmailService {
    private final ResendMailClient mail;
    private final EmailTemplate template;

    @Override
    public void sendOtpEmail(String toEmail, String otp, String recipientName) {
        String name = recipientName == null ? "Quý khách" : recipientName;
        String heading = "Mã OTP đặt lại mật khẩu";
        String message = "Chào " + name + ", hãy nhập mã sau để đặt lại mật khẩu.";
        String note = "Mã có hiệu lực trong 2 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.";
        try {
            mail.send(toEmail, heading + " | Nhà Thật", message + "\n\n" + otp + "\n\n" + note,
                    template.render(heading, message, Map.of("otp", otp, "note", note)), null);
            log.info("OTP email accepted by Resend");
        } catch (IllegalStateException failure) {
            log.warn("OTP email delivery failed: {}", failure.getMessage());
            throw failure;
        }
    }
}
