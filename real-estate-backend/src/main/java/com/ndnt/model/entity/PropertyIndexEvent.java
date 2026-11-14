package com.ndnt.model.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;

@Entity @Getter @Setter
@Table(name="property_index_outbox", indexes=@Index(name="ix_property_index_due", columnList="state,next_attempt_at"),
       uniqueConstraints=@UniqueConstraint(name="uk_property_index_version", columnNames={"property_id","aggregate_version"}))
public class PropertyIndexEvent {
    @Id @Column(length=36) private String id;
    @Column(name="property_id", nullable=false) private Integer propertyId;
    @Column(name="aggregate_version", nullable=false) private long aggregateVersion;
    @Column(nullable=false, length=10) private String operation;
    @Column(name="routing_key", nullable=false, length=50) private String routingKey;
    @Column(nullable=false, length=20) private String state = "PENDING";
    @Column(nullable=false) private int attempts;
    @Column(name="created_at", nullable=false) private Instant createdAt = Instant.now();
    @Column(name="next_attempt_at", nullable=false) private Instant nextAttemptAt = Instant.now();
    @Column(name="sent_at") private Instant sentAt;
    @Column(name="last_error", length=100) private String lastError;
}
