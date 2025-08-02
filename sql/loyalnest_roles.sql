-- roles.sql: Schema for Roles Service
-- Tables: roles, audit_logs (shared)
-- Indexes, triggers for audit logging

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: roles
CREATE TABLE IF NOT EXISTS roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    permissions JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_roles_merchant_id ON roles (merchant_id);
CREATE INDEX IF NOT EXISTS idx_roles_created_at ON roles (created_at);

-- Trigger: Log role changes (uses shared audit_logs from users.sql)
CREATE OR REPLACE FUNCTION log_role_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (merchant_id, user_id, action, details, created_at)
    VALUES (
        NEW.merchant_id,
        NULL,
        CASE WHEN TG_OP = 'INSERT' THEN 'create'
             WHEN TG_OP = 'UPDATE' THEN 'update'
             WHEN TG_OP = 'DELETE' THEN 'delete' END,
        row_to_json(NEW)::JSONB,
        CURRENT_TIMESTAMP
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_role_change
AFTER INSERT OR UPDATE OR DELETE ON roles
FOR EACH ROW
EXECUTE FUNCTION log_role_change();

-- Trigger: Update updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_timestamp
BEFORE UPDATE ON roles
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();