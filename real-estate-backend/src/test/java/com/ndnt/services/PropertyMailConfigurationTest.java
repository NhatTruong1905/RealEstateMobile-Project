package com.ndnt.services;

import com.ndnt.model.entity.PropertyMailEvent;
import com.ndnt.services.impl.EmailServiceImpl;
import com.ndnt.services.property.PropertyMailConfiguration;
import com.ndnt.services.property.PropertyMailer;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.io.support.ResourcePropertySource;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.thymeleaf.spring6.SpringTemplateEngine;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;

import java.time.Instant;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

class PropertyMailConfigurationTest {
    @Test void rendersPasswordResetCodeInHtmlAndPlainText() {
        var resolver = new ClassLoaderTemplateResolver();
        resolver.setPrefix("templates/");
        resolver.setSuffix(".html");
        resolver.setCharacterEncoding("UTF-8");
        var engine = new SpringTemplateEngine();
        engine.setTemplateResolver(resolver);
        var mail = mock(ResendMailClient.class);
        new EmailServiceImpl(mail, new EmailTemplate(engine))
                .sendOtpEmail("owner@example.invalid", "012345", "<An>");

        verify(mail).send(eq("owner@example.invalid"), eq("Mã đặt lại mật khẩu | Nhà Thật"),
                argThat(text -> text.contains("\n\n012345\n\n") && text.contains("2 phút")),
                argThat(html -> html.contains(">012345</p>") && html.contains("Chào &lt;An&gt;,")
                        && html.contains("mailto:support@nhtr.id.vn") && !html.contains("Mã tin #")), isNull());
    }

    @Test void applicationDefaultsToResendWithWorkerDisabled() throws Exception {
        try (var context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().getPropertySources().addFirst(
                    new ResourcePropertySource("classpath:application.properties"));
            context.registerBean(ResendMailClient.class, () -> new ResendMailClient("", "sender@example.invalid"));
            context.register(PropertyMailConfiguration.class);
            context.refresh();
            assertEquals("resend", context.getEnvironment().getProperty("property.mail.mode"));
            assertEquals("false", context.getEnvironment().getProperty("property.mail.worker-enabled"));
            assertNotNull(context.getBean(PropertyMailer.class));
            assertFalse(context.containsBean("fakePropertyMailer"));
        }
    }

    @Test void resendsAnOutboxEventWithTheSameKeyAfterProviderFailure() throws Exception {
        var builder = RestClient.builder().baseUrl("https://api.resend.com");
        var mock = MockRestServiceServer.bindTo(builder).build();
        var sender = new ResendMailClient(builder.build(), "test-key", "sender@example.invalid");
        try (var context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().getPropertySources().addFirst(new MapPropertySource("test",
                    Map.of("property.mail.mode", "resend")));
            context.registerBean(ResendMailClient.class, () -> sender);
            context.register(PropertyMailConfiguration.class);
            context.refresh();

            PropertyMailEvent event = new PropertyMailEvent();
            event.setId(42L);
            event.setCreatedAt(Instant.parse("2026-01-01T00:00:00Z"));
            event.setRecipient("owner@example.invalid");
            event.setSubject("Property notification");
            event.setTextBody("Listing updated");
            event.setHtmlBody("<p>Listing updated</p>");
            var mailer = context.getBean(PropertyMailer.class);
            for (var response : java.util.List.of(withStatus(HttpStatus.TOO_MANY_REQUESTS),
                    withSuccess("{\"id\":\"test-id\"}", MediaType.APPLICATION_JSON))) {
                mock.expect(requestTo("https://api.resend.com/emails"))
                        .andExpect(method(HttpMethod.POST))
                        .andExpect(header("Authorization", "Bearer test-key"))
                        .andExpect(header("Idempotency-Key", "property-mail/42/2026-01-01T00:00:00Z"))
                        .andExpect(content().json("""
                                {"from":"sender@example.invalid","to":["owner@example.invalid"],
                                "subject":"Property notification","text":"Listing updated","html":"<p>Listing updated</p>"}
                                """))
                        .andRespond(response);
            }
            assertEquals("Resend HTTP 429", assertThrows(IllegalStateException.class, () -> mailer.send(event)).getMessage());
            mailer.send(event);
            mock.verify();
        }
    }
}
