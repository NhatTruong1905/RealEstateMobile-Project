package com.ndnt.services.property;

import org.springframework.context.annotation.*;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import com.ndnt.services.ResendMailClient;
import org.slf4j.LoggerFactory;

@Configuration
public class PropertyMailConfiguration {
    @Bean
    @ConditionalOnProperty(name="property.mail.mode", havingValue="fake")
    PropertyMailer fakePropertyMailer() {
        return event -> LoggerFactory.getLogger(PropertyMailer.class).info("Fake property mail event={}", event.getId());
    }
    @Bean
    @ConditionalOnProperty(name="property.mail.mode", havingValue="resend", matchIfMissing=true)
    PropertyMailer resendPropertyMailer(ResendMailClient client) {
        return event -> client.send(event.getRecipient(), event.getSubject(), event.getTextBody(), event.getHtmlBody(),
                "property-mail/" + event.getId() + "/" + event.getCreatedAt());
    }
}
