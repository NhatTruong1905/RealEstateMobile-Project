package com.ndnt.services.property;

import com.ndnt.model.entity.PropertyMailEvent;
import jakarta.mail.Multipart;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.core.io.support.ResourcePropertySource;
import org.springframework.mail.javamail.JavaMailSender;

import java.util.Properties;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PropertyMailConfigurationTest {
    @Test void listingNotificationsProfileDefaultsToMockWithoutDelivery() throws Exception {
        try (var context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().getPropertySources().addFirst(
                    new ResourcePropertySource("classpath:application-listing-notifications.properties"));
            context.register(PropertyMailConfiguration.class);
            context.refresh();
            assertEquals("fake", context.getEnvironment().getProperty("property.mail.mode"));
            assertEquals("false", context.getEnvironment().getProperty("property.mail.worker-enabled"));
            assertTrue(context.containsBean("fakePropertyMailer"));
            assertFalse(context.containsBean("smtpPropertyMailer"));
            PropertyMailEvent event = new PropertyMailEvent();
            event.setId(1001L);
            context.getBean(PropertyMailer.class).send(event);
        }
    }

    @Test void propertyMailProfileSendsAllThreeNotificationsThroughConfiguredSender() throws Exception {
        JavaMailSender sender = mock(JavaMailSender.class);
        when(sender.createMimeMessage()).thenAnswer(invocation -> new MimeMessage(Session.getInstance(new Properties())));
        try (var context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().getPropertySources().addFirst(
                    new ResourcePropertySource("classpath:application-listing-notifications.properties"));
            context.getEnvironment().getPropertySources().addFirst(new org.springframework.core.env.MapPropertySource("test-sender", java.util.Map.of("spring.mail.username", "sender@example.invalid", "property.mail.mode", "smtp", "property.mail.worker-enabled", "true")));

            context.registerBean(JavaMailSender.class, () -> sender);
            context.register(PropertyMailConfiguration.class);
            context.refresh();
            assertEquals("smtp", context.getEnvironment().getProperty("property.mail.mode"));
            assertEquals("true", context.getEnvironment().getProperty("property.mail.worker-enabled"));
            assertFalse(context.containsBean("fakePropertyMailer"));
            PropertyMailer mailer = context.getBean(PropertyMailer.class);
            for (String subject : new String[] {
                    "[RealEstateMobile] Đã tiếp nhận bài đăng bất động sản",
                    "[RealEstateMobile] Bài đăng của bạn đã được phê duyệt",
                    "[RealEstateMobile] Bài đăng của bạn chưa được phê duyệt"}) {
                PropertyMailEvent event = new PropertyMailEvent();
                event.setRecipient("owner@example.invalid");
                event.setSubject(subject);
                event.setTextBody("Bài đăng nhà ở. Lý do: Thiếu giấy tờ <b>pháp lý</b>.");
                event.setHtmlBody("<p>Bài đăng nhà ở. Lý do: Thiếu giấy tờ &lt;b&gt;pháp lý&lt;/b&gt;.</p>");
                mailer.send(event);
            }
            var messages = org.mockito.ArgumentCaptor.forClass(MimeMessage.class);
            verify(sender, times(3)).send(messages.capture());
            for (MimeMessage message : messages.getAllValues()) {
                message.saveChanges();
                assertEquals("sender@example.invalid", message.getFrom()[0].toString());
                assertEquals("owner@example.invalid", message.getAllRecipients()[0].toString());
                assertTrue(message.getSubject().startsWith("[RealEstateMobile]"));
                assertEquals("Bài đăng nhà ở. Lý do: Thiếu giấy tờ <b>pháp lý</b>.", body(message, "text/plain"));
                assertEquals("<p>Bài đăng nhà ở. Lý do: Thiếu giấy tờ &lt;b&gt;pháp lý&lt;/b&gt;.</p>", body(message, "text/html"));
            }

        }
    }

    private String body(jakarta.mail.Part part, String type) throws Exception {
        if (part.isMimeType(type)) return part.getContent().toString();
        if (part.getContent() instanceof Multipart multipart) {
            for (int i = 0; i < multipart.getCount(); i++) {
                String found = body(multipart.getBodyPart(i), type);
                if (found != null) return found;
            }
        }
        return null;
    }
}
