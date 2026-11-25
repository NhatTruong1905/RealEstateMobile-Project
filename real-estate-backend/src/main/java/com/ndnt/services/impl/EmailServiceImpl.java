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
        String greeting = recipientName == null || recipientName.isBlank()
                ? "Xin chào," : "Chào " + recipientName.trim() + ",";
        String heading = "Mã đặt lại mật khẩu";
        String message = "Nhập mã dưới đây vào màn hình đặt lại mật khẩu trên Nhà Thật. Mã có hiệu lực trong 2 phút.";
        String note = "Vui lòng giữ kín mã này. Nếu bạn không yêu cầu đặt lại mật khẩu, bạn có thể bỏ qua email.";
        try {
            String text = greeting + "\n\n" + message + "\n\n" + otp + "\n\n" + note
                    + "\n\nTrân trọng,\nNhà Thật\n\nHỗ trợ qua support@nhtr.id.vn";
            mail.send(toEmail, heading + " | Nhà Thật", text,
                    template.render(heading, message, Map.of("greeting", greeting, "otp", otp, "note", note)), null);
            log.info("OTP email accepted by Resend");
        } catch (IllegalStateException failure) {
            log.warn("OTP email delivery failed: {}", failure.getMessage());
            throw failure;
        }
    }
}
