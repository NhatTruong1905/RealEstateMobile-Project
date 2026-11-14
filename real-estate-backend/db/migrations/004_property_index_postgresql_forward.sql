BEGIN;
ALTER TABLE property ADD COLUMN index_version BIGINT NOT NULL DEFAULT 1;
CREATE TABLE property_index_outbox (
    id VARCHAR(36) PRIMARY KEY,
    property_id INTEGER NOT NULL,
    aggregate_version BIGINT NOT NULL,
    operation VARCHAR(10) NOT NULL,
    routing_key VARCHAR(50) NOT NULL,
    state VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    next_attempt_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP(6) WITH TIME ZONE,
    last_error VARCHAR(100),
    CONSTRAINT uk_property_index_version UNIQUE (property_id, aggregate_version)
);
CREATE INDEX ix_property_index_due ON property_index_outbox(state,next_attempt_at);
COMMIT;
