<!-- AdminCore Service SQL -->
<xaiFile name="admin_core.sql" contentType="text/sql">
-- admin_core.sql: Schema for AdminCore Service
-- Tables: gdpr_requests, audit_logs (shared), webhook_idempotency_keys
-- Indexes, functions for GDPR handling

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: gdpr_requests
CREATE TABLE IF NOT EXISTS gdpr_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    user_id UUID,
    status VARCHAR(20) CHECK (status IN ('pending', 'completed')),
    retention_expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_gdpr_requests_merchant_id ON gdpr_requests (merchant_id);
CREATE INDEX IF NOT EXISTS idx_gdpr_requests_user_id ON gdpr_requests (user_id);
CREATE INDEX IF NOT EXISTS idx_gdpr_requests_retention_expires_at ON gdpr_requests (retention_expires_at);

-- Table: webhook_idempotency_keys
CREATE TABLE IF NOT EXISTS webhook_idempotency_keys (
    key_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    webhook_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_webhook_idempotency_keys_merchant_id ON webhook_idempotency_keys (merchant_id);
CREATE INDEX IF NOT EXISTS idx_webhook_idempotency_keys_webhook_id ON webhook_idempotency_keys (webhook_id);

-- Function: Process GDPR request
CREATE OR REPLACE FUNCTION process_gdpr_request(
    p_request_id UUID,
    p_status VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE gdpr_requests
    SET status = p_status,
        retention_expires_at = CURRENT_TIMESTAMP + INTERVAL '90 days'
    WHERE request_id = p_request_id;
END;
$$ LANGUAGE plpgsql;
</xaiFile>