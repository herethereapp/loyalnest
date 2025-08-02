-- users.sql: Schema for Users Service
-- Tables: users
-- Indexes, functions for PII encryption

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