<!-- AdminFeatures Service SQL -->
<xaiFile name="admin_features.sql" contentType="text/sql">
-- admin_features.sql: Schema for AdminFeatures Service
-- Tables: email_templates, integrations, setup_tasks, merchant_settings
-- Indexes, functions for template and integration management

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table: email_templates
CREATE TABLE IF NOT EXISTS email_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    template_data JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_email_templates_merchant_id ON email_templates (merchant_id);
CREATE INDEX IF NOT EXISTS idx_email_templates_created_at ON email_templates (created_at);

-- Table: integrations
CREATE TABLE IF NOT EXISTS integrations (
    integration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    credentials TEXT NOT NULL, -- AES-256 encrypted
    type VARCHAR(50) CHECK (type IN ('shopify', 'square', 'klaviyo')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_integrations_merchant_id ON integrations (merchant_id);
CREATE INDEX IF NOT EXISTS idx_integrations_type ON integrations (type);

-- Table: setup_tasks
CREATE TABLE IF NOT EXISTS setup_tasks (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_setup_tasks_merchant_id ON setup_tasks (merchant_id);
CREATE INDEX IF NOT EXISTS idx_setup_tasks_created_at ON setup_tasks (created_at);

-- Table: merchant_settings
CREATE TABLE IF NOT EXISTS merchant_settings (
    merchant_id UUID PRIMARY KEY,
    currency VARCHAR(10) NOT NULL,
    settings JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_merchant_settings_merchant_id ON merchant_settings (merchant_id);

-- Function: Encrypt integration credentials
CREATE OR REPLACE FUNCTION encrypt_integration_credentials(
    p_integration_id UUID,
    p_credentials TEXT,
    p_encryption_key TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE integrations
    SET credentials = pgp_sym_encrypt(p_credentials, p_encryption_key)
    WHERE integration_id = p_integration_id;
END;
$$ LANGUAGE plpgsql;
</xaiFile>