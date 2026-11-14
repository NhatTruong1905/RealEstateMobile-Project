package com.ndnt.services.property;

import com.ndnt.repositories.PropertyIndexEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.*;
import org.springframework.data.domain.PageRequest;
import java.time.Instant;

@Configuration @EnableScheduling @RequiredArgsConstructor
@ConditionalOnProperty(name="property.index.enabled", havingValue="true")
public class PropertyIndexScheduler {
    private final PropertyIndexEventRepository events;
    private final PropertyIndexDelivery delivery;
    @Scheduled(fixedDelayString="${property.index.poll-ms:5000}")
    public void poll() { events.due(Instant.now(), PageRequest.of(0,20)).forEach(delivery::deliver); }
}
