-- referrals.sql: Schema for Referrals Service
-- Table: referrals with range partitioning
-- Indexes, triggers for status updates

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Parent Table: referrals
CREATE TABLE IF NOT EXISTS referrals (
    referral_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    referrer_id UUID NOT NULL,
    referral_link_id UUID NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (created_at);

-- Partitions (example for 2025)
CREATE TABLE referrals_2025 PARTITION OF referrals
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_referrals_merchant_id ON referrals (merchant_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer_id ON referrals (referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referral_link_id ON referrals (referral_link_id);
CREATE INDEX IF NOT EXISTS idx_referrals_created_at ON referrals (created_at);

-- Trigger: Update updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_timestamp
BEFORE UPDATE ON referrals
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Function: Update referral status
CREATE OR REPLACE FUNCTION update_referral_status(
    p_referral_id UUID,
    p_status VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE referrals
    SET status = p_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE referral_id = p_referral_id;
END;
$$ LANGUAGE plpgsql;