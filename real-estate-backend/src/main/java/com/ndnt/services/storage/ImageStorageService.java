package com.ndnt.services.storage;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.*;

@Service @RequiredArgsConstructor @Slf4j
public class ImageStorageService {
    private final ImageProcessor processor;
    private final ObjectStorage storage;
    private final StorageCleanup cleanup;

    public String uploadAvatar(MultipartFile file) { return upload(processor.process(file, true), "avatar/" + UUID.randomUUID() + "/" + UUID.randomUUID()); }

    public List<String> uploadProperty(Integer propertyId, List<MultipartFile> files, int retainedCount) {
        if (propertyId == null || propertyId <= 0) throw new IllegalArgumentException("Invalid property ID");
        List<MultipartFile> selected = files == null ? List.of() : files.stream().filter(Objects::nonNull)
                .filter(file -> !file.isEmpty() || (file.getOriginalFilename() != null && !file.getOriginalFilename().isBlank())).toList();
        if (selected.size() + retainedCount > 10)
            throw new StorageProblem(400, "TOO_MANY_IMAGES", "Mỗi bài đăng tối đa 10 ảnh");
        List<ImageProcessor.Image> images = selected.stream().map(file -> processor.process(file, false)).toList();
        List<String> urls = new ArrayList<>();
        long batch = System.currentTimeMillis();
        for (int i = 0; i < images.size(); i++) {
            String key = "properties/" + propertyId + "/" + String.format(java.util.Locale.ROOT, "%013d-%02d-", batch, i) + UUID.randomUUID();
            urls.add(upload(images.get(i), key));
        }
        return urls;
    }

    private String upload(ImageProcessor.Image image, String objectName) {
        if (!TransactionSynchronizationManager.isActualTransactionActive() || !TransactionSynchronizationManager.isSynchronizationActive())
            throw new IllegalStateException("Image upload requires a database transaction");
        String key = objectName + "." + image.extension();
        String url = storage.publicUrl(key);
        if (url == null || !url.startsWith("https://") || url.length() > 255)
            throw new StorageProblem(500, "STORAGE_CONFIGURATION", "URL ảnh không hợp lệ hoặc dài quá 255 ký tự");
        Long intent = cleanup.planUpload(key, url);
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { processAfterCommit(intent); }
            @Override public void afterCompletion(int status) {
                if (status == STATUS_ROLLED_BACK) {
                    try { cleanup.rollbackUpload(intent); }
                    catch (Exception ex) { log.warn("Storage rollback cleanup deferred task={}", intent); }
                }
            }
        });
        try { storage.put(key, image); cleanup.completeUpload(intent); return url; }
        catch (Exception ex) { throw StorageProblem.unavailable(); }
    }
    public List<String> propertyImages(Integer propertyId) { return storage.listPropertyImages(propertyId); }

    public void retire(String trustedUrl) {
        Long intent = cleanup.retire(trustedUrl);
        if (intent != null) TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { processAfterCommit(intent); }
        });
    }
    private void processAfterCommit(Long intent) {
        try { cleanup.process(intent); }
        catch (Exception ex) { log.warn("Storage cleanup deferred task={}", intent); }
    }
}
