-- Admin_sessions table: Tracks admin sessions for MFA and security
CREATE TABLE admin_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_admin_sessions_admin_id ON admin_sessions(admin_id);
CREATE INDEX idx_admin_sessions_expires_at ON admin_sessions(expires_at);

-- Impersonation_sessions table: Tracks admin impersonation of merchants
CREATE TABLE impersonation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_impersonation_sessions_admin_id ON impersonation_sessions(admin_id);
CREATE INDEX idx_impersonation_sessions_merchant_id ON impersonation_sessions(merchant_id);
CREATE INDEX idx_impersonation_sessions_expires_at ON impersonation_sessions(expires_at);

-- Admin_users table: Stores admin user details
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('super_admin', 'support', 'analyst')),
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (email)
);
CREATE INDEX idx_admin_users_email ON admin_users(email);
CREATE INDEX idx_admin_users_role ON admin_users(role);

CREATE TRIGGER trg_admin_users_updated_at
BEFORE UPDATE ON admin_users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Points_transactions table: Tracks loyalty points transactions
CREATE TABLE points_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    multi_tenant_group_id UUID,
    points INT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('earn', 'redeem', 'adjust')),
    reason VARCHAR(255),
    source VARCHAR(50) CHECK (source IN ('shopify', 'klaviyo', 'zapier', 'shopify_flow', 'manual')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);
CREATE INDEX idx_points_transactions_customer_id ON points_transactions(customer_id);
CREATE INDEX idx_points_transactions_merchant_id ON points_transactions(merchant_id);
CREATE INDEX idx_points_transactions_multi_tenant_group_id ON points_transactions(multi_tenant_group_id);
CREATE INDEX idx_points_transactions_created_at ON points_transactions(created_at);

CREATE TABLE points_transactions_p0 PARTITION OF points_transactions FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE points_transactions_p1 PARTITION OF points_transactions FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE points_transactions_p2 PARTITION OF points_transactions FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE points_transactions_p3 PARTITION OF points_transactions FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE points_transactions_p4 PARTITION OF points_transactions FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE points_transactions_p5 PARTITION OF points_transactions FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE points_transactions_p6 PARTITION OF points_transactions FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE points_transactions_p7 PARTITION OF points_transactions FOR VALUES WITH (MODULUS 8, REMAINDER 7);

CREATE TRIGGER points_transactions_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON points_transactions
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Referrals table: Tracks customer referrals
CREATE TABLE referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    referrer_customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    referral_link_id VARCHAR(50) NOT NULL,
    merchant_referral_id VARCHAR(50),
    multi_tenant_group_id UUID,
    type VARCHAR(50) NOT NULL CHECK (type IN ('sms', 'email', 'whatsapp', 'merchant')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'completed', 'expired')),
    spoof_detection JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);
CREATE INDEX idx_referrals_merchant_id ON referrals(merchant_id);
CREATE INDEX idx_referrals_referral_link_id ON referrals(referral_link_id);
CREATE INDEX idx_referrals_merchant_referral_id ON referrals(merchant_referral_id);
CREATE INDEX idx_referrals_referrer_customer_id ON referrals(referrer_customer_id);
CREATE INDEX idx_referrals_multi_tenant_group_id ON referrals(multi_tenant_group_id);
CREATE INDEX idx_referrals_spoof_detection ON referrals USING GIN (spoof_detection);
CREATE INDEX idx_referrals_created_at ON referrals(created_at);

CREATE TRIGGER trg_referrals_updated_at
BEFORE UPDATE ON referrals
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER referrals_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON referrals
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

CREATE TABLE referrals_p0 PARTITION OF referrals FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE referrals_p1 PARTITION OF referrals FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE referrals_p2 PARTITION OF referrals FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE referrals_p3 PARTITION OF referrals FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE referrals_p4 PARTITION OF referrals FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE referrals_p5 PARTITION OF referrals FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE referrals_p6 PARTITION OF referrals FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE referrals_p7 PARTITION OF referrals FOR VALUES WITH (MODULUS 8, REMAINDER 7);

-- Reward_redemptions table: Tracks reward redemptions
CREATE TABLE reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    campaign_id VARCHAR(50) NOT NULL,
    points INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);
CREATE INDEX idx_reward_redemptions_customer_id ON reward_redemptions(customer_id);
CREATE INDEX idx_reward_redemptions_merchant_id ON reward_redemptions(merchant_id);
CREATE INDEX idx_reward_redemptions_campaign_id ON reward_redemptions(campaign_id);
CREATE INDEX idx_reward_redemptions_created_at ON reward_redemptions(created_at);

CREATE TABLE reward_redemptions_p0 PARTITION OF reward_redemptions FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE reward_redemptions_p1 PARTITION OF reward_redemptions FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE reward_redemptions_p2 PARTITION OF reward_redemptions FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE reward_redemptions_p3 PARTITION OF reward_redemptions FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE reward_redemptions_p4 PARTITION OF reward_redemptions FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE reward_redemptions_p5 PARTITION OF reward_redemptions FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE reward_redemptions_p6 PARTITION OF reward_redemptions FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE reward_redemptions_p7 PARTITION OF reward_redemptions FOR VALUES WITH (MODULUS 8, REMAINDER 7);

CREATE TRIGGER reward_redemptions_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON reward_redemptions
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Vip_tiers table: Stores VIP tier configurations
CREATE TABLE vip_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    name JSONB NOT NULL DEFAULT '{}'::jsonb,
    rfm_criteria JSONB NOT NULL DEFAULT '{}'::jsonb,
    benefits JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_vip_tiers_merchant_id ON vip_tiers(merchant_id);
CREATE INDEX idx_vip_tiers_name ON vip_tiers USING GIN (name);
CREATE INDEX idx_vip_tiers_created_at ON vip_tiers(created_at);

CREATE TRIGGER vip_tiers_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON vip_tiers
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Shopify_flow_templates table: Stores Shopify Flow automation templates
CREATE TABLE shopify_flow_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    template_id VARCHAR(50) NOT NULL,
    name JSONB NOT NULL DEFAULT '{}'::jsonb,
    trigger_type VARCHAR(50) NOT NULL CHECK (trigger_type IN ('rfm_change', 'points_earned', 'referral_completed', 'churn_risk')),
    actions JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_shopify_flow_templates_merchant_id ON shopify_flow_templates(merchant_id);
CREATE INDEX idx_shopify_flow_templates_template_id ON shopify_flow_templates(template_id);
CREATE INDEX idx_shopify_flow_templates_trigger_type ON shopify_flow_templates(trigger_type);
CREATE INDEX idx_shopify_flow_templates_created_at ON shopify_flow_templates(created_at);

CREATE TRIGGER shopify_flow_templates_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON shopify_flow_templates
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Email_templates table: Stores email templates with multi-language support
CREATE TABLE email_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('points_earned', 'referral_invite', 'gdpr_request', 'tier_upgraded', 'referral_completed', 'badge_earned', 'onboarding_task_completed', 'tier_change', 'nudge')),
    subject JSONB NOT NULL DEFAULT '{}'::jsonb,
    body JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_email_template_subject CHECK (
        EXISTS (
            SELECT 1
            FROM merchants m
            WHERE m.id = email_templates.merchant_id
            AND email_templates.subject ? (m.language->>'default')
        )
    ),
    CONSTRAINT valid_email_template_body CHECK (
        EXISTS (
            SELECT 1
            FROM merchants m
            WHERE m.id = email_templates.merchant_id
            AND email_templates.body ? (m.language->>'default')
        )
    )
);
CREATE INDEX idx_email_templates_merchant_id ON email_templates(merchant_id);
CREATE INDEX idx_email_templates_type ON email_templates(type);
CREATE INDEX idx_email_templates_created_at ON email_templates(created_at);

CREATE TRIGGER trg_email_templates_updated_at
BEFORE UPDATE ON email_templates
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER email_templates_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON email_templates
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Email_events table: Tracks email sending events
CREATE TABLE email_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('sent', 'failed')),
    recipient_email TEXT ENCRYPTED WITH (COLUMN ENCRYPTION KEY = 'aws_kms_key', ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'),
    template_id UUID REFERENCES email_templates(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);
CREATE INDEX idx_email_events_merchant_id ON email_events(merchant_id);
CREATE INDEX idx_email_events_customer_id ON email_events(customer_id);
CREATE INDEX idx_email_events_created_at ON email_events(created_at);

CREATE TABLE email_events_p0 PARTITION OF email_events FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE email_events_p1 PARTITION OF email_events FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE email_events_p2 PARTITION OF email_events FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE email_events_p3 PARTITION OF email_events FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE email_events_p4 PARTITION OF email_events FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE email_events_p5 PARTITION OF email_events FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE email_events_p6 PARTITION OF email_events FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE email_events_p7 PARTITION OF email_events FOR VALUES WITH (MODULUS 8, REMAINDER 7);

CREATE TRIGGER email_events_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON email_events
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Gdpr_requests table: Tracks GDPR/CCPA requests
CREATE TABLE gdpr_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('data_request', 'redact')),
    request_source VARCHAR(50) NOT NULL CHECK (request_source IN ('customer', 'admin')),
    redaction_status VARCHAR(50) CHECK (redaction_status IN ('pending', 'in_progress', 'completed', 'failed')),
    request_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    retention_expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_gdpr_requests_merchant_id ON gdpr_requests(merchant_id);
CREATE INDEX idx_gdpr_requests_customer_id ON gdpr_requests(customer_id);
CREATE INDEX idx_gdpr_requests_retention_expires_at ON gdpr_requests(retention_expires_at);
CREATE INDEX idx_gdpr_requests_created_at ON gdpr_requests(created_at);

CREATE TRIGGER gdpr_requests_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON gdpr_requests
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Gdpr_redaction_log table: Tracks redaction history for GDPR/CCPA compliance
CREATE TABLE gdpr_redaction_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    redaction_type VARCHAR(50) NOT NULL CHECK (redaction_type IN ('email', 'name', 'full')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'completed', 'failed')),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_gdpr_redaction_log_merchant_id ON gdpr_redaction_log(merchant_id);
CREATE INDEX idx_gdpr_redaction_log_customer_id ON gdpr_redaction_log(customer_id);
CREATE INDEX idx_gdpr_redaction_log_created_at ON gdpr_redaction_log(created_at);

CREATE TRIGGER gdpr_redaction_log_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON gdpr_redaction_log
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Webhook_idempotency_keys table: Ensures webhook idempotency
CREATE TABLE webhook_idempotency_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    webhook_id VARCHAR(50) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    signature VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    UNIQUE (merchant_id, webhook_id)
);
CREATE INDEX idx_webhook_idempotency_keys_merchant_id ON webhook_idempotency_keys(merchant_id);
CREATE INDEX idx_webhook_idempotency_keys_expires_at ON webhook_idempotency_keys(expires_at);

CREATE TRIGGER webhook_idempotency_keys_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON webhook_idempotency_keys
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Integrations table: Stores third-party integration settings
CREATE TABLE integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL CHECK (platform IN ('shopify', 'klaviyo', 'mailchimp', 'yotpo', 'postscript', 'recharge', 'gorgias', 'shopify_flow', 'zapier')),
    api_key TEXT ENCRYPTED WITH (COLUMN ENCRYPTION KEY = 'aws_kms_key', ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'),
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(50) NOT NULL CHECK (status IN ('active', 'inactive', 'failed', 'pending')) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (merchant_id, platform),
    CONSTRAINT valid_config_languages CHECK (
        EXISTS (
            SELECT 1
            FROM merchants m
            WHERE m.id = integrations.merchant_id
            AND (integrations.config->>'language' IS NULL OR integrations.config->>'language' = m.language->>'default')
        )
    )
);
CREATE INDEX idx_integrations_merchant_id ON integrations(merchant_id);
CREATE INDEX idx_integrations_platform ON integrations(platform);
CREATE INDEX idx_integrations_status ON integrations(status);
CREATE INDEX idx_integrations_created_at ON integrations(created_at);

CREATE TRIGGER trg_integrations_updated_at
BEFORE UPDATE ON integrations
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER integrations_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON integrations
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Audit_logs table: Stores audit logs for all table operations
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID REFERENCES merchants(id) ON DELETE SET NULL,
    actor_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(100) NOT NULL,
    severity VARCHAR(50) NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);
CREATE INDEX idx_audit_logs_merchant_id ON audit_logs(merchant_id);
CREATE INDEX idx_audit_logs_actor_id ON audit_logs(actor_id);
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

CREATE TABLE audit_logs_p0 PARTITION OF audit_logs FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE audit_logs_p1 PARTITION OF audit_logs FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE audit_logs_p2 PARTITION OF audit_logs FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE audit_logs_p3 PARTITION OF audit_logs FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE audit_logs_p4 PARTITION OF audit_logs FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE audit_logs_p5 PARTITION OF audit_logs FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE audit_logs_p6 PARTITION OF audit_logs FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE audit_logs_p7 PARTITION OF audit_logs FOR VALUES WITH (MODULUS 8, REMAINDER 7);

-- Queue_tasks table: Manages asynchronous tasks for microservices
CREATE TABLE queue_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID REFERENCES merchants(id) ON DELETE CASCADE,
    task_type VARCHAR(50) NOT NULL CHECK (task_type IN ('rfm_calculation', 'email_send', 'webhook_trigger', 'data_sync', 'report_generation')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')) DEFAULT 'pending',
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    retry_count INT NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
    priority INT NOT NULL DEFAULT 0 CHECK (priority >= 0),
    channel VARCHAR(50) NOT NULL DEFAULT 'email' CHECK (channel IN ('email', 'sms', 'whatsapp')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
) PARTITION BY HASH (merchant_id);
CREATE INDEX idx_queue_tasks_merchant_id ON queue_tasks(merchant_id);
CREATE INDEX idx_queue_tasks_task_type ON queue_tasks(task_type);
CREATE INDEX idx_queue_tasks_status ON queue_tasks(status);
CREATE INDEX idx_queue_tasks_created_at ON queue_tasks(created_at);
CREATE INDEX idx_queue_tasks_scheduled_at ON queue_tasks(scheduled_at);
CREATE INDEX idx_queue_tasks_priority ON queue_tasks(priority);
CREATE INDEX idx_queue_tasks_channel ON queue_tasks(channel);

CREATE TABLE queue_tasks_p0 PARTITION OF queue_tasks FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE queue_tasks_p1 PARTITION OF queue_tasks FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE queue_tasks_p2 PARTITION OF queue_tasks FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE queue_tasks_p3 PARTITION OF queue_tasks FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE queue_tasks_p4 PARTITION OF queue_tasks FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE queue_tasks_p5 PARTITION OF queue_tasks FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE queue_tasks_p6 PARTITION OF queue_tasks FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE queue_tasks_p7 PARTITION OF queue_tasks FOR VALUES WITH (MODULUS 8, REMAINDER 7);

CREATE TRIGGER trg_queue_tasks_updated_at
BEFORE UPDATE ON queue_tasks
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER queue_tasks_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON queue_tasks
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

-- Api_tokens table: Stores API tokens for secure access
CREATE TABLE api_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    token TEXT NOT NULL ENCRYPTED WITH (COLUMN ENCRYPTION KEY = 'aws_kms_key', ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'),
    scopes JSONB NOT NULL DEFAULT '[]'::jsonb,
    status VARCHAR(50) NOT NULL CHECK (status IN ('active', 'revoked', 'expired')) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (merchant_id, token)
);
CREATE INDEX idx_api_tokens_merchant_id ON api_tokens(merchant_id);
CREATE INDEX idx_api_tokens_status ON api_tokens(status);
CREATE INDEX idx_api_tokens_expires_at ON api_tokens(expires_at);
CREATE INDEX idx_api_tokens_scopes ON api_tokens USING GIN (scopes);

CREATE TRIGGER trg_api_tokens_updated_at
BEFORE UPDATE ON api_tokens
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER api_tokens_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON api_tokens
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

CREATE TABLE rate_limit_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    endpoint VARCHAR(255) NOT NULL,
    request_count INT NOT NULL DEFAULT 0 CHECK (request_count >= 0),
    limit_threshold INT NOT NULL,
    last_reset TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) NOT NULL CHECK (status IN ('normal', 'warning', 'critical')) DEFAULT 'normal',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);
CREATE INDEX idx_rate_limit_tracking_merchant_id ON rate_limit_tracking(merchant_id);
CREATE INDEX idx_rate_limit_tracking_endpoint ON rate_limit_tracking(endpoint);
CREATE INDEX idx_rate_limit_tracking_status ON rate_limit_tracking(status);
CREATE INDEX idx_rate_limit_tracking_last_reset ON rate_limit_tracking(last_reset);

CREATE TABLE rate_limit_tracking_p0 PARTITION OF rate_limit_tracking FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE rate_limit_tracking_p1 PARTITION OF rate_limit_tracking FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE rate_limit_tracking_p2 PARTITION OF rate_limit_tracking FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE rate_limit_tracking_p3 PARTITION OF rate_limit_tracking FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE rate_limit_tracking_p4 PARTITION OF rate_limit_tracking FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE rate_limit_tracking_p5 PARTITION OF rate_limit_tracking FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE rate_limit_tracking_p6 PARTITION OF rate_limit_tracking FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE rate_limit_tracking_p7 PARTITION OF rate_limit_tracking FOR VALUES WITH (MODULUS 8, REMAINDER 7);

CREATE TRIGGER trg_rate_limit_tracking_updated_at
BEFORE UPDATE ON rate_limit_tracking
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER rate_limit_tracking_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON rate_limit_tracking
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

CREATE TABLE pos_offline_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('earn', 'redeem')),
    points INT NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'synced', 'failed')) DEFAULT 'pending',
    sync_attempt_count INT NOT NULL DEFAULT 0 CHECK (sync_attempt_count >= 0),
    last_sync_attempt TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);
CREATE INDEX idx_pos_offline_queue_merchant_id ON pos_offline_queue(merchant_id);
CREATE INDEX idx_pos_offline_queue_status ON pos_offline_queue(status);
CREATE INDEX idx_pos_offline_queue_created_at ON pos_offline_queue(created_at);

CREATE TABLE pos_offline_queue_p0 PARTITION OF pos_offline_queue FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE pos_offline_queue_p1 PARTITION OF pos_offline_queue FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE pos_offline_queue_p2 PARTITION OF pos_offline_queue FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE pos_offline_queue_p3 PARTITION OF pos_offline_queue FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE pos_offline_queue_p4 PARTITION OF pos_offline_queue FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE pos_offline_queue_p5 PARTITION OF pos_offline_queue FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE pos_offline_queue_p6 PARTITION OF pos_offline_queue FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE pos_offline_queue_p7 PARTITION OF pos_offline_queue FOR VALUES WITH (MODULUS 8, REMAINDER 7);

CREATE TRIGGER pos_offline_queue_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON pos_offline_queue
FOR EACH ROW EXECUTE FUNCTION trigger_audit_log();

