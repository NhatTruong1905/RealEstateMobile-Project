package com.ndnt.services.storage;

import com.ndnt.repositories.StorageCleanupRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@SpringBootTest(properties={"spring.config.location=classpath:test.properties",
        "spring.datasource.url=jdbc:h2:mem:r2-gallery;MODE=MYSQL;NON_KEYWORDS=USER;DB_CLOSE_DELAY=-1"})
class PropertyImageTransactionTest {
    @Autowired ImageStorageService images;
    @Autowired StorageCleanup cleanup;
    @Autowired StorageCleanupRepository tasks;
    @Autowired PlatformTransactionManager manager;
    @Autowired JdbcTemplate jdbc;
    @MockitoBean ObjectStorage storage;
    TransactionTemplate tx;

    @BeforeEach void setup() {
        tx = new TransactionTemplate(manager);
        tasks.deleteAll();
        when(storage.provider()).thenReturn("r2");
        when(storage.publicUrl(anyString())).thenAnswer(call -> "https://images.example.invalid/" + call.getArgument(0));
    }

    @Test void committedUploadsNeedNoPropertyImageTableOrPermanentImageRows() throws Exception {
        var file = ImageProcessorTest.image();
        List<String> urls = tx.execute(status -> images.uploadProperty(42, List.of(file), 0));
        assertEquals(1, urls.size());
        assertTrue(urls.getFirst().matches("https://images.example.invalid/properties/42/[0-9]{13}-00-[0-9a-f-]{36}\\.jpg"));
        verify(storage).put(startsWith("properties/42/"), any());
        verify(storage, never()).delete(anyString());
        assertEquals(0, tasks.count());
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='PROPERTY_IMAGE'", Integer.class));
    }

    @Test void rollbackPreservesCleanupIntentAndEventuallyDeletesOnlyTheFailedUpload() throws Exception {
        var file = ImageProcessorTest.image();
        tx.executeWithoutResult(status -> {
            images.uploadProperty(42, List.of(file), 0);
            status.setRollbackOnly();
        });
        assertEquals(1, tasks.count());
        var pending = tasks.findAll().getFirst();
        assertEquals("PENDING", pending.getState());
        verify(storage, never()).delete(anyString());
        tx.executeWithoutResult(status -> tasks.findById(pending.getId()).orElseThrow().setNextAttemptAt(Instant.now().minusSeconds(1)));
        cleanup.process(pending.getId());
        verify(storage).delete(pending.getObjectKey());
        assertEquals(0, tasks.count());
    }

    @Test void removedImagesAreDeletedOnlyAfterCommit() {
        String key = "properties/42/1761318000000-00-11111111-1111-1111-1111-111111111111.jpg";
        String url = "https://images.example.invalid/" + key;
        when(storage.managedKey(url)).thenReturn(Optional.of(key));
        tx.executeWithoutResult(status -> {
            images.retire(url);
            verify(storage, never()).delete(anyString());
            status.setRollbackOnly();
        });
        verify(storage, never()).delete(anyString());
        assertEquals(0, tasks.count());
        tx.executeWithoutResult(status -> images.retire(url));
        verify(storage).delete(key);
        assertEquals(0, tasks.count());
    }

    @Test void avatarUsesAvatarPrefixAndImageLimitIsValidatedBeforeUploading() throws Exception {
        var file = ImageProcessorTest.image();
        String url = tx.execute(status -> images.uploadAvatar(file));
        assertTrue(url.startsWith("https://images.example.invalid/avatar/"));
        clearInvocations(storage);
        assertThrows(StorageProblem.class, () -> tx.execute(status -> images.uploadProperty(42, List.of(file, file), 9)));
        verify(storage, never()).put(anyString(), any());
    }
}
