-- loyalnest_audit-logs.sql: Schema for audit-logs-service
-- Tables: audit_logs as TimescaleDB hypertable
-- Indexes, functions for GDPR compliance (90-day retention, PII encryption)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "timescaledb";

-- Create merchants table for foreign key reference (assumed for cross-service consistency)
CREATE TABLE IF NOT EXISTS merchants (
    merchant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_domain TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create audit_logs hypertable
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_user_id UUID,
    action TEXT NOT NULL CHECK (action IN (
        'merchant_added', 'merchant_updated', 'auth_token_issued', 'settings_updated',
        'integration_configured', 'data_import_initiated', 'points_adjusted',
        'plan_changed', 'undo_action', 'gdpr_processed', 'user_created', 'user_updated'
    )),
    target_table TEXT,
    target_id UUID,
    reverted BOOLEAN DEFAULT FALSE,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    merchant_id UUID NOT NULL,
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

-- Convert audit_logs to TimescaleDB hypertable with monthly partitioning
SELECT create_hypertable('audit_logs', 'created_at', chunk_time_interval => interval '1 month');

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_audit_logs_merchant_id ON audit_logs (merchant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_user_id_action ON audit_logs (admin_user_id, action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs (created_at);

-- Function: Encrypt PII in metadata
CREATE OR REPLACE FUNCTION encrypt_metadata_pii(data JSONB, encryption_key TEXT)
RETURNS JSONB AS $$
DECLARE
    encrypted JSONB := '{}';
    key TEXT;
    value TEXT;
BEGIN
    FOR key, value IN SELECT * FROM jsonb_each_text(data)
    LOOP
        IF key IN ('username', 'email', 'shop_domain') THEN
            encrypted := encrypted || jsonb_build_object(
                key, encode(pgcrypto.encrypt(decode(value, 'escape'), decode(encryption_key, 'escape'), 'aes-256-cbc'), 'base64')
            );
        ELSE
            encrypted := encrypted || jsonb_build_object(key, value);
        END IF;
    END LOOP;
    RETURN encrypted;
END;
$$ LANGUAGE plpgsql;

-- Function: Enforce 90-day retention for GDPR compliance
CREATE OR REPLACE FUNCTION delete_old_audit_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM audit_logs WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Example: Schedule retention cleanup (requires pg_cron or external scheduler)
-- e.g., SELECT cron.schedule('delete_old_audit_logs', '0 0 * * *', $$CALL delete_old_audit_logs()$$);