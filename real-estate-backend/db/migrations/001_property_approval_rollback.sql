-- Stop worker and old/new application writes; drain or export outbox before destructive rollback.
-- Roll back application before dropping columns. MySQL DDL implicitly commits.
DROP TABLE property_mail_outbox;
ALTER TABLE property DROP COLUMN reviewed_at;
ALTER TABLE property DROP COLUMN reviewed_by;
ALTER TABLE property DROP COLUMN rejection_reason;
