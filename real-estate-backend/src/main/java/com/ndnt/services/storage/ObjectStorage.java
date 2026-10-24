package com.ndnt.services.storage;

import java.util.Optional;
import java.util.List;

public interface ObjectStorage {
    String provider();
    String publicUrl(String key);
    void put(String key, ImageProcessor.Image image);
    void delete(String key);
    List<String> listPropertyImages(Integer propertyId);
    Optional<String> managedKey(String url);
}
