-- campaign.sql: Schema for Campaign Service
-- Table: campaigns
-- Indexes for campaign management

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: campaigns
CREATE TABLE IF NOT EXISTS campaigns (
    campaign_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_campaigns_merchant_id ON campaigns (merchant_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_created_at ON campaigns (created_at);

-- Trigger: Update updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_timestamp
BEFORE UPDATE ON campaigns
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();