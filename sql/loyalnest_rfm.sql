-- rfm.sql: Schema for RFM Service (TimescaleDB)
-- Tables: rfm_segment_deltas, rfm_segment_counts, rfm_score_history, customer_segments
-- Hypertables, materialized views, triggers for RFM updates

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Table: rfm_segment_deltas (Hypertable)
CREATE TABLE IF NOT EXISTS rfm_segment_deltas (
    customer_id UUID NOT NULL,
    merchant_id UUID NOT NULL,
    recency NUMERIC NOT NULL,
    frequency NUMERIC NOT NULL,
    monetary NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

SELECT create_hypertable('rfm_segment_deltas', 'created_at', chunk_time_interval => INTERVAL '1 month');

-- Indexes
CREATE INDEX IF NOT EXISTS idx_rfm_segment_deltas_customer_id ON rfm_segment_deltas (customer_id);
CREATE INDEX IF NOT EXISTS idx_rfm_segment_deltas_merchant_id ON rfm_segment_deltas (merchant_id);
CREATE INDEX IF NOT EXISTS idx_rfm_segment_deltas_created_at ON rfm_segment_deltas (created_at);

-- Table: rfm_score_history
CREATE TABLE IF NOT EXISTS rfm_score_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL,
    merchant_id UUID NOT NULL,
    rfm_score JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_rfm_score_history_customer_id ON rfm_score_history (customer_id);
CREATE INDEX IF NOT EXISTS idx_rfm_score_history_merchant_id ON rfm_score_history (merchant_id);
CREATE INDEX IF NOT EXISTS idx_rfm_score_history_created_at ON rfm_score_history (created_at);

-- Table: customer_segments
CREATE TABLE IF NOT EXISTS customer_segments (
    customer_id UUID NOT NULL,
    merchant_id UUID NOT NULL,
    segment VARCHAR(20) CHECK (segment IN ('high_value', 'at_risk', 'new')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, merchant_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_customer_segments_merchant_id ON customer_segments (merchant_id);
CREATE INDEX IF NOT EXISTS idx_customer_segments_created_at ON customer_segments (created_at);

-- Materialized View: rfm_segment_counts
CREATE MATERIALIZED VIEW IF NOT EXISTS rfm_segment_counts
WITH (timescaledb.continuous) AS
SELECT
    merchant_id,
    segment,
    COUNT(*) AS count,
    time_bucket('1 day', created_at) AS created_at
FROM customer_segments
GROUP BY merchant_id, segment, time_bucket('1 day', created_at)
WITH DATA;

-- Indexes on materialized view
CREATE INDEX IF NOT EXISTS idx_rfm_segment_counts_merchant_id ON rfm_segment_counts (merchant_id);
CREATE INDEX IF NOT EXISTS idx_rfm_segment_counts_created_at ON rfm_segment_counts (created_at);

-- Function: Update RFM segment
CREATE OR REPLACE FUNCTION update_rfm_segment(
    p_customer_id UUID,
    p_merchant_id UUID,
    p_recency NUMERIC,
    p_frequency NUMERIC,
    p_monetary NUMERIC
) RETURNS VOID AS $$
DECLARE
    v_segment VARCHAR(20);
BEGIN
    -- Calculate segment based on thresholds
    v_segment := CASE
        WHEN p_recency > 80 AND p_frequency > 5 THEN 'high_value'
        WHEN p_recency < 30 THEN 'at_risk'
        ELSE 'new'
    END;

    -- Insert into rfm_segment_deltas
    INSERT INTO rfm_segment_deltas (customer_id, merchant_id, recency, frequency, monetary, created_at)
    VALUES (p_customer_id, p_merchant_id, p_recency, p_frequency, p_monetary, CURRENT_TIMESTAMP);

    -- Update customer_segments
    INSERT INTO customer_segments (customer_id, merchant_id, segment, created_at)
    VALUES (p_customer_id, p_merchant_id, v_segment, CURRENT_TIMESTAMP)
    ON CONFLICT (customer_id, merchant_id)
    DO UPDATE SET segment = v_segment, created_at = CURRENT_TIMESTAMP;

    -- Log score history
    INSERT INTO rfm_score_history (customer_id, merchant_id, rfm_score, created_at)
    VALUES (p_customer_id, p_merchant_id, jsonb_build_object('recency', p_recency, 'frequency', p_frequency, 'monetary', p_monetary), CURRENT_TIMESTAMP);
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update segment on order events
CREATE OR REPLACE FUNCTION trigger_update_rfm()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_rfm_segment(NEW.customer_id, NEW.merchant_id, NEW.recency, NEW.frequency, NEW.monetary);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_rfm_update
AFTER INSERT ON rfm_segment_deltas
FOR EACH ROW
EXECUTE FUNCTION trigger_update_rfm();