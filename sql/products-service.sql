-- products.sql: Schema for Products Service
-- Tables: products, product_rfm_scores
-- Indexes for product and RFM queries

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: products
CREATE TABLE IF NOT EXISTS products (
    product_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_products_merchant_id ON products (merchant_id);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products (created_at);

-- Table: product_rfm_scores
CREATE TABLE IF NOT EXISTS product_rfm_scores (
    score_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL,
    rfm_score JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_product_rfm_scores_product_id ON product_rfm_scores (product_id);
CREATE INDEX IF NOT EXISTS idx_product_rfm_scores_merchant_id ON product_rfm_scores (merchant_id);
CREATE INDEX IF NOT EXISTS idx_product_rfm_scores_created_at ON product_rfm_scores (created_at);

-- Function: Update product RFM score
CREATE OR REPLACE FUNCTION update_product_rfm_score(
    p_product_id UUID,
    p_merchant_id UUID,
    p_rfm_score JSONB
) RETURNS VOID AS $$
BEGIN
    INSERT INTO product_rfm_scores (product_id, merchant_id, rfm_score, created_at)
    VALUES (p_product_id, p_merchant_id, p_rfm_score, CURRENT_TIMESTAMP)
    ON CONFLICT (product_id, merchant_id)
    DO UPDATE SET rfm_score = p_rfm_score, created_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;