package com.ndnt.services.property;

import com.ndnt.repositories.PropertyMailEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.time.Instant;

@Service @RequiredArgsConstructor @Slf4j
public class PropertyMailDelivery {
    private final PropertyMailEventRepository events;
    private final PropertyMailer mailer;
    @Value("${property.mail.max-attempts:5}") private int maxAttempts;
    @Value("${property.mail.retry-seconds:60}") private long retrySeconds;
    // A separate transaction sees only committed events. Row lock serializes competing workers.
    // The SMTP request is bounded by provider timeouts; ACK loss still has external duplicate risk.
    @Transactional(propagation=Propagation.REQUIRES_NEW)
    public void deliver(Long id) {
        var event = events.findLocked(id).orElse(null);
        Instant now = Instant.now();
        if (event == null || !"PENDING".equals(event.getState()) || event.getNextAttemptAt().isAfter(now)) return;
        event.setAttempts(event.getAttempts()+1);
        try {
            mailer.send(event); event.setState("SENT"); event.setSentAt(now); event.setLastError(null);
            log.info("Property mail sent event={}", id);
        } catch (Exception ex) {
            event.setLastError("DELIVERY_FAILED");
            if (event.getAttempts() >= Math.max(1,maxAttempts)) event.setState("FAILED");
            long delay = Math.min(86400L, Math.max(1,retrySeconds) * (1L << Math.min(16,event.getAttempts()-1)));
            event.setNextAttemptAt(now.plusSeconds(delay));
            log.warn("Property mail delivery failed event={} attempt={}", id, event.getAttempts());
        }
    }
}
