package com.ndnt.services.property;

import com.ndnt.repositories.PropertyIndexEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;

@Service @RequiredArgsConstructor
public class PropertyIndexDelivery {
    private final PropertyIndexEventRepository events;
    private final PropertyIndexSender sender;
    @Transactional
    public void deliver(String id) {
        var event = events.locked(id).orElse(null);
        if (event == null || !"PENDING".equals(event.getState()) || event.getNextAttemptAt().isAfter(Instant.now())) return;
        event.setAttempts(event.getAttempts()+1);
        try {
            sender.send(event);
            event.setState("SENT"); event.setSentAt(Instant.now()); event.setLastError(null);
        } catch (Exception error) {
            event.setLastError(error.getClass().getSimpleName());
            event.setNextAttemptAt(Instant.now().plusSeconds(Math.min(300, 5L << Math.min(6,event.getAttempts()))));
        }
    }
}
