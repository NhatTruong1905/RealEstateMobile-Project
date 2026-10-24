package com.ndnt.services.property;

import com.ndnt.repositories.PropertyMailEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.*;
import org.springframework.data.domain.PageRequest;
import java.time.Instant;

@Configuration @EnableScheduling @RequiredArgsConstructor
@ConditionalOnProperty(name="property.mail.worker-enabled", havingValue="true")
public class PropertyMailScheduler {
    private final PropertyMailEventRepository events;
    private final PropertyMailDelivery delivery;
    @Scheduled(fixedDelayString="${property.mail.poll-ms:10000}")
    public void poll() { events.due(Instant.now(), PageRequest.of(0,20)).forEach(delivery::deliver); }
}
