package com.ndnt.services.storage;

import com.ndnt.repositories.StorageCleanupRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.*;
import java.time.Instant;

@Configuration @EnableScheduling @RequiredArgsConstructor @Slf4j
@ConditionalOnProperty(name="storage.cleanup.enabled", havingValue="true")
public class StorageCleanupScheduler {
    private final StorageCleanupRepository tasks;
    private final StorageCleanup cleanup;
    private final ObjectStorage storage;
    @Scheduled(fixedDelayString="${storage.cleanup.poll-ms:60000}")
    public void poll() {
        for (Long id : tasks.due(storage.provider(), Instant.now(), PageRequest.of(0, 20))) {
            try { cleanup.process(id); }
            catch (Exception ex) { log.warn("Storage cleanup deferred task={}", id); }
        }
    }
}
