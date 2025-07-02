
-- ========== BASE TABLES FROM OLD DATABASE (copied) ==========

-- 1. admin_users
CREATE TABLE admin_users (
  id SERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  email TEXT NOT NULL UNIQUE
);

-- 2. api_logs
CREATE TABLE api_logs (
  id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL,
  route TEXT NOT NULL,
  method TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  timestamp TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. audit_logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  admin_user_id INTEGER REFERENCES admin_users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_table TEXT NOT NULL,
  target_id UUID NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB
);

-- 4. customers
CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL,
  shopify_customer_id TEXT,
  email TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  points_balance INTEGER NOT NULL,
  vip_tier_id TEXT,
  referral_url TEXT,
  state TEXT NOT NULL,
  birthday TIMESTAMP(3),
  email_preferences JSONB NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL,
  phone TEXT,
  FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (vip_tier_id) REFERENCES vip_tiers(vip_tier_id) ON UPDATE CASCADE ON DELETE SET NULL
);

-- 5. email_templates
CREATE TABLE email_templates (
  template_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  type TEXT NOT NULL,
  "group" TEXT NOT NULL,
  sub_type TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  is_enabled BOOLEAN NOT NULL,
  banner_image TEXT,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL
);

-- 6. emails
CREATE TABLE emails (
  id SERIAL PRIMARY KEY,
  subject TEXT NOT NULL,
  body TEXT,
  sent_at TIMESTAMP DEFAULT now(),
  recipient_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'sent'
);

-- 7. import_logs
CREATE TABLE import_logs (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid(),
  success_count INTEGER NOT NULL,
  fail_count INTEGER NOT NULL,
  fail_reason TEXT NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 8. integrations
CREATE TABLE integrations (
  integration_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  type TEXT NOT NULL,
  api_key TEXT NOT NULL,
  status TEXT NOT NULL,
  prebuilt_flows JSONB NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL
);

-- 9. merchants
CREATE TABLE merchants (
  merchant_id TEXT PRIMARY KEY,
  shopify_domain TEXT NOT NULL UNIQUE,
  plan_id TEXT,
  billing_cycle_start TIMESTAMP(3),
  api_token TEXT,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL,
  brand_settings JSONB DEFAULT '{}'::jsonb,
  language VARCHAR DEFAULT 'en',
  features_enabled JSONB DEFAULT '{}'::jsonb
);

-- 10. nudges
CREATE TABLE nudges (
  nudge_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  type TEXT NOT NULL,
  title JSONB NOT NULL,
  description JSONB NOT NULL,
  icon_url TEXT,
  is_enabled BOOLEAN NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL
);

-- 11. plans
CREATE TABLE plans (
  plan_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  order_limit INTEGER NOT NULL,
  base_price NUMERIC(65,30) NOT NULL,
  additional_order_rate NUMERIC(65,30) NOT NULL,
  features JSONB NOT NULL
);

-- 12. points_transactions
CREATE TABLE points_transactions (
  transaction_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  type TEXT NOT NULL,
  points INTEGER NOT NULL,
  source TEXT NOT NULL,
  order_id TEXT,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 13. referrals
CREATE TABLE referrals (
  referral_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  advocate_customer_id TEXT NOT NULL REFERENCES customers(customer_id),
  friend_customer_id TEXT NOT NULL REFERENCES customers(customer_id),
  status TEXT NOT NULL,
  reward_id TEXT REFERENCES rewards(reward_id),
  order_id TEXT,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL,
  source TEXT,
  campaign_id TEXT
);

-- 14. rewards
CREATE TABLE rewards (
  reward_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  type TEXT NOT NULL,
  points_cost INTEGER NOT NULL,
  value NUMERIC(65,30) NOT NULL,
  is_combinable BOOLEAN NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL,
  category TEXT,
  is_public BOOLEAN DEFAULT true,
  platform TEXT DEFAULT 'online_store'
);

-- 15. shopify_sessions
CREATE TABLE shopify_sessions (
  id SERIAL PRIMARY KEY,
  session_id TEXT NOT NULL UNIQUE,
  shop TEXT NOT NULL,
  state TEXT,
  is_online BOOLEAN NOT NULL DEFAULT false,
  scope TEXT NOT NULL,
  access_token TEXT NOT NULL,
  expires_at TIMESTAMP,
  online_access_info JSONB,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- 16. usage_records
CREATE TABLE usage_records (
  id SERIAL PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  order_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (merchant_id, period_start, period_end)
);

-- 17. vip_tiers
CREATE TABLE vip_tiers (
  vip_tier_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  name TEXT NOT NULL,
  threshold_type TEXT NOT NULL,
  threshold_value NUMERIC(65,30) NOT NULL,
  earning_multiplier NUMERIC(65,30) NOT NULL,
  entry_reward_id TEXT REFERENCES rewards(reward_id) ON UPDATE CASCADE ON DELETE SET NULL,
  perks JSONB NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP(3) NOT NULL,
  tier_level INTEGER DEFAULT 1
);

-- ========== PATCH ==========

-- 1. merchants: add brand, language, and feature flags
ALTER TABLE merchants
ADD COLUMN brand_settings JSONB DEFAULT '{}'::jsonb,
ADD COLUMN language VARCHAR DEFAULT 'en',
ADD COLUMN features_enabled JSONB DEFAULT '{}'::jsonb;

-- 2. customers: optional denormalized fields
ALTER TABLE customers
ADD COLUMN total_points_earned INTEGER DEFAULT 0,
ADD COLUMN total_points_redeemed INTEGER DEFAULT 0,
ADD COLUMN redeemed_rewards_count INTEGER DEFAULT 0;

-- 3. rewards: support grouping, visibility
ALTER TABLE rewards
ADD COLUMN category TEXT,
ADD COLUMN is_public BOOLEAN DEFAULT true,
ADD COLUMN platform TEXT DEFAULT 'online_store';

-- 4. referrals: campaign/source tracking
ALTER TABLE referrals
ADD COLUMN source TEXT,
ADD COLUMN campaign_id TEXT;

-- 5. vip_tiers: level field for sorting
ALTER TABLE vip_tiers
ADD COLUMN tier_level INTEGER DEFAULT 1;

-- 6. integrations: flexible config
ALTER TABLE integrations
ADD COLUMN settings JSONB DEFAULT '{}'::jsonb;

-- 7. import_logs: source identifier
ALTER TABLE import_logs
ADD COLUMN source TEXT;

-- ========== NEW TABLES ==========

-- 1. bonus_campaigns
CREATE TABLE bonus_campaigns (
  campaign_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- e.g., "multiplier", "fixed"
  multiplier NUMERIC(10, 2),
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  conditions JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. reward_redemptions
CREATE TABLE reward_redemptions (
  redemption_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES customers(customer_id),
  reward_id TEXT NOT NULL REFERENCES rewards(reward_id),
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id),
  discount_code TEXT,
  points_spent INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'issued',
  issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  metadata JSONB
);

-- 3. nudge_events
CREATE TABLE nudge_events (
  event_id TEXT PRIMARY KEY,
  customer_id TEXT REFERENCES customers(customer_id),
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id),
  nudge_id TEXT REFERENCES nudges(nudge_id),
  action TEXT NOT NULL, -- e.g., "viewed", "clicked"
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. email_events
CREATE TABLE email_events (
  event_id TEXT PRIMARY KEY,
  email_id INTEGER REFERENCES emails(id),
  recipient_email TEXT,
  event_type TEXT NOT NULL, -- "sent", "opened", "clicked", "bounced"
  event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB
);

-- 5. referral_links
CREATE TABLE referral_links (
  referral_link_id TEXT PRIMARY KEY,
  advocate_customer_id TEXT NOT NULL REFERENCES customers(customer_id),
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id),
  referral_code TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. program_settings
CREATE TABLE program_settings (
  merchant_id TEXT PRIMARY KEY REFERENCES merchants(merchant_id) ON DELETE CASCADE,
  points_currency_singular TEXT DEFAULT 'Point',
  points_currency_plural TEXT DEFAULT 'Points',
  expiry_days INTEGER,
  allow_guests BOOLEAN DEFAULT TRUE,
  branding JSONB,
  config JSONB
);

-- 7. customer_segments
CREATE TABLE customer_segments (
  segment_id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(merchant_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  rules JSONB NOT NULL, -- dynamic segment rules (e.g., points > 1000)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

