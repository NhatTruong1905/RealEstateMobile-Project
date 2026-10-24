CREATE TABLE storage_cleanup_task (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    provider VARCHAR(20) NOT NULL,
    object_key VARCHAR(120) NOT NULL,
    url VARCHAR(255) NOT NULL,
    state VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempts INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMP(6) NOT NULL,
    created_at TIMESTAMP(6) NOT NULL,
    INDEX ix_storage_cleanup_due (state, next_attempt_at)
);
