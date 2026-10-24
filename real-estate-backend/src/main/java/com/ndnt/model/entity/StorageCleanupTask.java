package com.ndnt.model.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;

@Entity @Getter @Setter
@Table(name="storage_cleanup_task", indexes=@Index(name="ix_storage_cleanup_due", columnList="state,next_attempt_at"))
public class StorageCleanupTask {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @Column(nullable=false, length=20) private String provider;
    @Column(name="object_key", nullable=false, length=120) private String objectKey;
    @Column(nullable=false, length=255) private String url;
    @Column(nullable=false, length=20) private String state = "PENDING";
    @Column(nullable=false) private int attempts;
    @Column(name="next_attempt_at", nullable=false) private Instant nextAttemptAt;
    @Column(name="created_at", nullable=false) private Instant createdAt = Instant.now();
}
