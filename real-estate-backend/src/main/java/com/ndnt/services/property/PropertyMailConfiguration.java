package com.ndnt.services.property;

import org.springframework.context.annotation.*;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.*;
import org.slf4j.LoggerFactory;

@Configuration
public class PropertyMailConfiguration {
    @Bean
    @ConditionalOnProperty(name="property.mail.mode", havingValue="fake", matchIfMissing=true)
    PropertyMailer fakePropertyMailer() {
        return event -> LoggerFactory.getLogger(PropertyMailer.class).info("Fake property mail event={}", event.getId());
    }
    @Bean
    @ConditionalOnProperty(name="property.mail.mode", havingValue="smtp")
    PropertyMailer smtpPropertyMailer(ObjectProvider<JavaMailSender> provider,
                                     @Value("${spring.mail.username:}") String sender) {
        return event -> {
            JavaMailSender mail = provider.getObject();
            var message = mail.createMimeMessage();
            var helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(sender); helper.setTo(event.getRecipient()); helper.setSubject(event.getSubject());
            helper.setText(event.getTextBody(), event.getHtmlBody());
            mail.send(message);
        };
    }
}
