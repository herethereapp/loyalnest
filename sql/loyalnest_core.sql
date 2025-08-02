-- core.sql: Schema for Core Service
-- Tables: program_settings, customer_import_logs
-- Indexes, functions for settings management
-- Enables pgcrypto for encryption

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table: program_settings
CREATE TABLE IF NOT EXISTS program_settings (
    merchant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    settings JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_program_settings_merchant_id ON program_settings (merchant_id);
CREATE INDEX IF NOT EXISTS idx_program_settings_created_at ON program_settings (created_at);

-- Table: customer_import_logs
CREATE TABLE IF NOT EXISTS customer_import_logs (
    import_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL REFERENCES program_settings(merchant_id) ON DELETE CASCADE,
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed')),
    log_details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_customer_import_logs_merchant_id ON customer_import_logs (merchant_id);
CREATE INDEX IF NOT EXISTS idx_customer_import_logs_created_at ON customer_import_logs (created_at);

-- Function: Update settings with encryption for sensitive fields
CREATE OR REPLACE FUNCTION update_settings(
    p_merchant_id UUID,
    p_settings JSONB,
    p_encryption_key TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE program_settings
    SET settings = jsonb_set(
        settings,
        '{sensitive}',
        pgp_sym_encrypt(p_settings->>'sensitive'::TEXT, p_encryption_key)::JSONB
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE merchant_id = p_merchant_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_timestamp
BEFORE UPDATE ON program_settings
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();