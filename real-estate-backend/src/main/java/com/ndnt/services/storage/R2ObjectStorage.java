package com.ndnt.services.storage;

import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import java.util.Optional;
import java.util.ArrayList;
import java.util.List;

public class R2ObjectStorage implements ObjectStorage {
    public static final String CACHE_CONTROL = "public, max-age=31536000, immutable";
    private final S3Client client;
    private final String bucket;
    private final String baseUrl;
    public R2ObjectStorage(S3Client client, String bucket, String baseUrl) {
        this.client = client; this.bucket = bucket; this.baseUrl = baseUrl.replaceAll("/+$", "");
    }
    public String provider() { return "r2"; }
    public String publicUrl(String key) { return baseUrl + "/" + key; }
    public void put(String key, ImageProcessor.Image image) {
        client.putObject(PutObjectRequest.builder().bucket(bucket).key(key).contentType(image.contentType())
                .cacheControl(CACHE_CONTROL).build(), RequestBody.fromBytes(image.bytes()));
    }
    public void delete(String key) { client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(key).build()); }
    public List<String> listPropertyImages(Integer propertyId) {
        if (propertyId == null || propertyId <= 0) throw new IllegalArgumentException("Invalid property ID");
        String prefix = "properties/" + propertyId + "/";
        List<String> urls = new ArrayList<>();
        String token = null;
        try {
            do {
                var page = client.listObjectsV2(ListObjectsV2Request.builder().bucket(bucket)
                        .prefix(prefix).continuationToken(token).build());
                for (var object : page.contents()) {
                    String url = publicUrl(object.key());
                    if (object.key().startsWith(prefix) && managedKey(url).isPresent()) urls.add(url);
                }
                String previous = token;
                token = Boolean.TRUE.equals(page.isTruncated()) ? page.nextContinuationToken() : null;
                if (token != null && token.equals(previous)) throw StorageProblem.unavailable();
                if (Boolean.TRUE.equals(page.isTruncated()) && (token == null || token.isBlank()))
                    throw StorageProblem.unavailable();
            } while (token != null);
            return urls.stream().sorted().toList();
        } catch (StorageProblem ex) { throw ex; }
        catch (Exception ex) { throw StorageProblem.unavailable(); }
    }
    public Optional<String> managedKey(String url) {
        if (url == null || !url.startsWith(baseUrl + "/")) return Optional.empty();
        String key = url.substring(baseUrl.length() + 1);
        boolean avatar = key.matches("avatars?/[0-9a-f-]{36}/[0-9a-f-]{36}\\.(jpg|png)");
        boolean property = key.matches("properties/[1-9][0-9]*/[0-9]{13}-[0-9]{2}-[0-9a-f-]{36}\\.(jpg|png)");
        return avatar || property ? Optional.of(key) : Optional.empty();
    }
}
