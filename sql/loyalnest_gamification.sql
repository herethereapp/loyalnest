-- gamification.sql: Schema for Gamification Service
-- Tables: customer_badges, leaderboard_rankings
-- Indexes for badge and leaderboard queries

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: customer_badges
CREATE TABLE IF NOT EXISTS customer_badges (
    badge_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL,
    merchant_id UUID NOT NULL,
    badge_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_customer_badges_customer_id ON customer_badges (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_badges_merchant_id ON customer_badges (merchant_id);
CREATE INDEX IF NOT EXISTS idx_customer_badges_created_at ON customer_badges (created_at);

-- Table: leaderboard_rankings
CREATE TABLE IF NOT EXISTS leaderboard_rankings (
    ranking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL,
    merchant_id UUID NOT NULL,
    score NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_leaderboard_rankings_customer_id ON leaderboard_rankings (customer_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_rankings_merchant_id ON leaderboard_rankings (merchant_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_rankings_score ON leaderboard_rankings (score);
CREATE INDEX IF NOT EXISTS idx_leaderboard_rankings_created_at ON leaderboard_rankings (created_at);

-- Function: Update leaderboard score
CREATE OR REPLACE FUNCTION update_leaderboard_score(
    p_customer_id UUID,
    p_merchant_id UUID,
    p_score NUMERIC
) RETURNS VOID AS $$
BEGIN
    INSERT INTO leaderboard_rankings (customer_id, merchant_id, score, created_at)
    VALUES (p_customer_id, p_merchant_id, p_score, CURRENT_TIMESTAMP)
    ON CONFLICT (customer_id, merchant_id)
    DO UPDATE SET score = p_score, created_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;