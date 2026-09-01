package com.ndnt.services.impl;

import com.ndnt.services.EmailService;
import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class EmailServiceImpl implements EmailService {

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:noreply@propertysumdev.com}")
    private String senderEmail;

    @Override
    @Async
    public void sendOtpEmail(String toEmail, String otp, String recipientName) {
        log.info("==================================================");
        log.info(" [MÃ OTP XÁC THỰC]: Gửi đến email: {} | Mã OTP: {}", toEmail, otp);
        log.info("==================================================");

        if (mailSender == null) {
            log.warn("JavaMailSender chưa được cấu hình. Chỉ in OTP ra log để test.");
            return;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(senderEmail, "PropertySumDev Bất Động Sản");
            helper.setTo(toEmail);
            helper.setSubject(" Mã xác thực OTP đặt lại mật khẩu - PropertySumDev");

            String htmlContent = buildOtpHtmlContent(recipientName != null ? recipientName : "Quý khách", otp);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            log.info("Đã gửi email OTP thành công đến: {}", toEmail);
        } catch (Exception e) {
            log.error("Không thể gửi email OTP đến {}: {}", toEmail, e.getMessage());
        }
    }

    private String buildOtpHtmlContent(String name, String otp) {
        return "<div style=\"font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 580px; margin: 0 auto; padding: 25px; border-radius: 12px; border: 1px solid #eaeaea; background-color: #ffffff;\">" +
                "  <div style=\"text-align: center; margin-bottom: 25px;\">" +
                "    <h2 style=\"color: #945331; margin: 0; font-size: 24px;\">PropertySumDev</h2>" +
                "    <p style=\"color: #78736d; font-size: 13px; margin-top: 5px;\">Hệ thống Quản lý & Giao dịch Bất động sản</p>" +
                "  </div>" +
                "  <div style=\"padding: 20px; background-color: #fcf9f7; border-radius: 8px;\">" +
                "    <p style=\"font-size: 15px; color: #333333; margin-top: 0;\">Xin chào <strong>" + name + "</strong>,</p>" +
                "    <p style=\"font-size: 14px; color: #555555; line-height: 1.5;\">Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Vui lòng sử dụng mã OTP dưới đây để tiếp tục:</p>" +
                "    <div style=\"text-align: center; margin: 25px 0;\">" +
                "      <span style=\"display: inline-block; font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #945331; background: #f3e9e2; padding: 12px 28px; border-radius: 8px; border: 1px dashed #945331;\">" + otp + "</span>" +
                "    </div>" +
                "    <p style=\"font-size: 13px; color: #d9534f; margin-bottom: 5px;\">⏱ <strong>Lưu ý:</strong> Mã này có hiệu lực trong vòng <strong>2 phút</strong>.</p>" +
                "    <p style=\"font-size: 13px; color: #777777; margin-top: 0;\">Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này để bảo vệ tài khoản.</p>" +
                "  </div>" +
                "  <div style=\"text-align: center; margin-top: 25px; font-size: 12px; color: #999999;\">" +
                "    <p style=\"margin: 0;\">© 2026 PropertySumDev. All rights reserved.</p>" +
                "  </div>" +
                "</div>";
    }
}
