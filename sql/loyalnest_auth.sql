-- auth.sql: Schema for Auth Service
-- Tables: merchants, admin_users, admin_sessions, impersonation_sessions
-- Indexes, functions for JWT and PII encryption

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table: merchants
CREATE TABLE IF NOT EXISTS merchants (
    merchant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_domain VARCHAR(255) NOT NULL UNIQUE,
    access_token TEXT NOT NULL, -- AES-256 encrypted
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_merchants_shop_domain ON merchants (shop_domain);
CREATE INDEX IF NOT EXISTS idx_merchants_created_at ON merchants (created_at);

-- Table: admin_users
CREATE TABLE IF NOT EXISTS admin_users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL, -- AES-256 encrypted
    merchant_id UUID NOT NULL REFERENCES merchants(merchant_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users USING hash (email);
CREATE INDEX IF NOT EXISTS idx_admin_users_merchant_id ON admin_users (merchant_id);

-- Table: admin_sessions
CREATE TABLE IF NOT EXISTS admin_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES admin_users(user_id) ON DELETE CASCADE,
    jwt_token TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_admin_sessions_user_id ON admin_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_expires_at ON admin_sessions (expires_at);

-- Table: impersonation_sessions
CREATE TABLE IF NOT EXISTS impersonation_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES admin_users(user_id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(merchant_id) ON DELETE CASCADE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_impersonation_sessions_admin_id ON impersonation_sessions (admin_id);
CREATE INDEX IF NOT EXISTS idx_impersonation_sessions_merchant_id ON impersonation_sessions (merchant_id);

-- Function: Encrypt email and access token
CREATE OR REPLACE FUNCTION encrypt_pii(
    p_email TEXT,
    p_access_token TEXT,
    p_encryption_key TEXT
) RETURNS RECORD AS $$
DECLARE
    encrypted_email TEXT;
    encrypted_token TEXT;
BEGIN
    encrypted_email := pgp_sym_encrypt(p_email, p_encryption_key);
    encrypted_token := pgp_sym_encrypt(p_access_token, p_encryption_key);
    RETURN (encrypted_email, encrypted_token)::RECORD;
END;
$$ LANGUAGE plpgsql;

-- Function: Decrypt PII
CREATE OR REPLACE FUNCTION decrypt_pii(
    p_encrypted_text TEXT,
    p_encryption_key TEXT
) RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(p_encrypted_text::BYTEA, p_encryption_key);
END;
$$ LANGUAGE plpgsql;