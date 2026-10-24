package com.ndnt.services.storage;

import com.ndnt.model.entity.StorageCleanupTask;
import com.ndnt.repositories.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.time.Instant;

@Service @RequiredArgsConstructor @Slf4j
public class StorageCleanup {
    private final StorageCleanupRepository tasks;
    private final UserRepository users;
    private final ObjectStorage storage;

    @Transactional(propagation=Propagation.REQUIRES_NEW)
    public Long planUpload(String key, String url) {
        return tasks.save(task(key, url, Instant.now().plusSeconds(3600))).getId();
    }

    @Transactional(propagation=Propagation.MANDATORY)
    public void completeUpload(Long id) {
        StorageCleanupTask task = tasks.findLocked(id).orElseThrow();
        task.setState("RETAINED");
        task.setNextAttemptAt(Instant.now());
    }

    @Transactional(propagation=Propagation.MANDATORY)
    public Long retire(String url) {
        return storage.managedKey(url).map(key -> tasks.save(task(key, url, Instant.now())).getId()).orElse(null);
    }
    private StorageCleanupTask task(String key, String url, Instant due) {
        StorageCleanupTask task = new StorageCleanupTask();
        task.setProvider(storage.provider()); task.setObjectKey(key); task.setUrl(url); task.setNextAttemptAt(due);
        return task;
    }

    @Transactional(propagation=Propagation.REQUIRES_NEW)
    public void process(Long id) {
        StorageCleanupTask task = tasks.findLocked(id).orElse(null);
        if (task == null || task.getNextAttemptAt().isAfter(Instant.now())) return;
        if ("RETAINED".equals(task.getState())) { tasks.delete(task); return; }
        if (!"PENDING".equals(task.getState())) return;
        if (users.existsByAvatar(task.getUrl())) { tasks.delete(task); return; }
        if (!storage.provider().equals(task.getProvider())) return;
        task.setAttempts(task.getAttempts() + 1);
        try {
            storage.delete(task.getObjectKey()); tasks.delete(task);
        } catch (Exception ex) {
            if (task.getAttempts() >= 8) task.setState("FAILED");
            task.setNextAttemptAt(Instant.now().plusSeconds(Math.min(86400L, 60L << Math.min(10, task.getAttempts()-1))));
            log.warn("Storage cleanup failed task={} attempt={}", id, task.getAttempts());
        }
    }

    @Transactional(propagation=Propagation.REQUIRES_NEW)
    public void rollbackUpload(Long id) {
        tasks.findLocked(id).ifPresent(task -> task.setNextAttemptAt(Instant.now().plusSeconds(60)));
    }
}
