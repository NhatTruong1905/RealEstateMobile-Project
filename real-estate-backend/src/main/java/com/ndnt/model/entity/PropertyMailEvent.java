package com.ndnt.model.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;

@Entity
@Table(name="property_mail_outbox", uniqueConstraints=@UniqueConstraint(name="uk_property_mail_event_key", columnNames="event_key"),
       indexes=@Index(name="ix_property_mail_due", columnList="state,next_attempt_at"))
@Getter @Setter
public class PropertyMailEvent {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @Column(name="property_id", nullable=false) private Integer propertyId;
    @Column(name="event_key", nullable=false, length=100) private String eventKey;
    @Column(name="event_type", nullable=false, length=20) private String eventType;
    @Column(nullable=false) private String recipient;
    @Column(nullable=false) private String subject;
    @Column(name="text_body", nullable=false, columnDefinition="TEXT") private String textBody;
    @Column(name="html_body", nullable=false, columnDefinition="TEXT") private String htmlBody;
    @Column(nullable=false, length=20) private String state = "PENDING";
    @Column(nullable=false) private int attempts;
    @Column(name="next_attempt_at", nullable=false) private Instant nextAttemptAt = Instant.now();
    @Column(name="created_at", nullable=false) private Instant createdAt = Instant.now();
    @Column(name="sent_at") private Instant sentAt;
    @Column(name="last_error", length=50) private String lastError;
}
