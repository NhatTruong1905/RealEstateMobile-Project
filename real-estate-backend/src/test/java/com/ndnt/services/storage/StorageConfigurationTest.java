package com.ndnt.services.storage;

import com.ndnt.configs.StorageConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.MapPropertySource;
import java.util.Map;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import static org.junit.jupiter.api.Assertions.*;

class StorageConfigurationTest {
    @Test void r2FailsClearlyWithoutCredentialsRatherThanFallingBack() {
        try (var context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().getPropertySources().addFirst(new MapPropertySource("r2-test", Map.of(
                    "storage.r2.bucket", "media-test",
                    "storage.r2.public-base-url", "https://images.example.invalid")));
            context.register(StorageConfiguration.class);
            Exception error = assertThrows(Exception.class, context::refresh);
            Throwable root = error; while (root.getCause() != null) root = root.getCause();
            assertTrue(root.getMessage().contains("R2_"));
        }
    }
    @Test void r2IsTheOnlyStorageWithoutSelectingAProvider() {
        try (var context = new AnnotationConfigApplicationContext()) {
            context.getEnvironment().getPropertySources().addFirst(new MapPropertySource("r2-test", Map.of(
                    "storage.r2.bucket", "media-test",
                    "storage.r2.public-base-url", "https://images.example.invalid",
                    "storage.r2.endpoint", "https://r2.example.invalid",
                    "storage.r2.access-key-id", "test-access",
                    "storage.r2.secret-access-key", "test-secret")));
            context.register(StorageConfiguration.class);
            context.refresh();
            ObjectStorage storage = context.getBean(ObjectStorage.class);
            assertInstanceOf(R2ObjectStorage.class, storage);
            assertEquals("r2", storage.provider());
        }
    }
    @Test void onlyServerGeneratedKeysOnExactManagedOriginAreEligibleForDeletion() {
        var storage = new R2ObjectStorage(null, "media-test", "https://images.example.invalid");
        String key = "avatars/"+java.util.UUID.randomUUID()+"/"+java.util.UUID.randomUUID()+".jpg";
        assertEquals(key, storage.managedKey(storage.publicUrl(key)).orElseThrow());
        for (String url : new String[] {"https://images.example.invalid.evil/"+key,
                "https://legacy-images.example.invalid/x/"+key, "https://images.example.invalid/../"+key,
                storage.publicUrl(key)+"?x=1", "https://images.example.invalid/avatars/shared.png"})
            assertTrue(storage.managedKey(url).isEmpty());
    }
}
