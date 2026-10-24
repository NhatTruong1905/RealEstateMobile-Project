

DROP TABLE property_mail_outbox;
ALTER TABLE property DROP COLUMN reviewed_at;
ALTER TABLE property DROP COLUMN reviewed_by;
ALTER TABLE property DROP COLUMN rejection_reason;
