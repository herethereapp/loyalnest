-- users.sql: Schema for Users Service
-- Tables: users, audit_logs with range partitioning
-- Indexes, triggers for audit logging, functions for PII encryption

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table: users
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL, -- AES-256 encrypted
    merchant_id UUID NOT NULL,
    role_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users USING hash (email);
CREATE INDEX IF NOT EXISTS idx_users_merchant_id ON users (merchant_id);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users (role_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at);

-- Parent Table: audit_logs
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    user_id UUID,
    action VARCHAR(20) CHECK (action IN ('create', 'update', 'delete')),
    details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (created_at);

-- Partitions (example for 2025)
CREATE TABLE audit_logs_2025 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_merchant_id ON audit_logs (merchant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs (created_at);

-- Function: Log user changes
CREATE OR REPLACE FUNCTION log_user_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (merchant_id, user_id, action, details, created_at)
    VALUES (
        NEW.merchant_id,
        NEW.user_id,
        CASE WHEN TG_OP = 'INSERT' THEN 'create'
             WHEN TG_OP = 'UPDATE' THEN 'update'
             WHEN TG_OP = 'DELETE' THEN 'delete' END,
        row_to_json(NEW)::JSONB,
        CURRENT_TIMESTAMP
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Audit user changes
CREATE TRIGGER trigger_log_user_change
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION log_user_change();

-- Function: Encrypt user email
CREATE OR REPLACE FUNCTION encrypt_user_email(
    p_user_id UUID,
    p_email TEXT,
    p_encryption_key TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE users
    SET email = pgp_sym_encrypt(p_email, p_encryption_key)
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;