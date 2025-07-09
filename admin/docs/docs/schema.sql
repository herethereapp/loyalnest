--
-- PostgreSQL database dump
-- Updated for LoyalNest App with RFM, Admin Module, and microservices enhancements
-- Aligned with RFM.txt (artifact_id: 751121e8-8fa6-4888-9904-7313c14683db), project plan, roadmap, Internal Admin Module.txt, feature_analytics.txt, and flow_diagram.txt (artifact_id: 7b136271-8099-43dd-8da6-33da4dd48c97)
-- Supports microservices: Analytics (RFM calculations, segments, nudges), Admin (configuration, audit logs), Frontend (UI), Points (rewards), Referrals (referral nudges), Auth (RBAC, sessions)
-- GDPR/CCPA compliance with AES-256 encryption, 90-day backup retention
-- Scalability for Shopify Plus (50,000+ customers, 1,000 orders/hour)
-- Multilingual support for en, es, fr
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Enable pgcrypto for AES-256 encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

--
-- Name: diesel_manage_updated_at(regclass); Type: FUNCTION
--

CREATE FUNCTION public.diesel_manage_updated_at(_tbl regclass) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE format('CREATE TRIGGER set_updated_at BEFORE UPDATE ON %s
                    FOR EACH ROW EXECUTE PROCEDURE diesel_set_updated_at()', _tbl);
END;
$$;

--
-- Name: diesel_set_updated_at(); Type: FUNCTION
--

CREATE FUNCTION public.diesel_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (
        NEW IS DISTINCT FROM OLD AND
        NEW.updated_at IS NOT DISTINCT FROM OLD.updated_at
    ) THEN
        NEW.updated_at := current_timestamp;
    END IF;
    RETURN NEW;
END;
$$;

--
-- Name: refresh_rfm_segment_counts(); Type: FUNCTION
-- Refreshes materialized view rfm_segment_counts daily for analytics performance
--

CREATE FUNCTION public.refresh_rfm_segment_counts() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW public.rfm_segment_counts;
END;
$$;

SET default_tablespace = '';
SET default_table_access_method = heap;

--
-- Name: __diesel_schema_migrations; Type: TABLE
-- Managed by: All Services (migration tracking)
--

CREATE TABLE public.__diesel_schema_migrations (
    version character varying(50) NOT NULL,
    run_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

--
-- Name: admin_users; Type: TABLE
-- Managed by: Admin Service (RBAC, staff management)
-- Stores admin users for merchant staff with roles for RFM configuration access
--

CREATE TABLE public.admin_users (
    id integer NOT NULL,
    username text NOT NULL,
    password text NOT NULL, -- Encrypted via pgcrypto (AES-256)
    email text NOT NULL, -- Encrypted via pgcrypto (AES-256)
    metadata jsonb DEFAULT '{"role": "support"}'::jsonb, -- e.g., {"role": "admin:full"} for RBAC
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE SEQUENCE public.admin_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;

--
-- Name: api_logs; Type: TABLE
-- Managed by: Analytics Service (API usage tracking)
-- Partitioned by merchant_id for scalability
-- Backup retention: 90 days
--

CREATE TABLE public.api_logs (
    id text NOT NULL,
    merchant_id text NOT NULL,
    route text NOT NULL, -- e.g., /api/v1/rfm/customers
    method text NOT NULL,
    status_code integer NOT NULL,
    "timestamp" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);

--
-- Name: audit_logs; Type: TABLE
-- Managed by: Admin Service (audit logging for RFM config, tier assignments)
-- Backup retention: 90 days
--

CREATE TABLE public.audit_logs (
    id uuid NOT NULL,
    admin_user_id integer,
    action text NOT NULL, -- e.g., tier_assigned, config_updated
    target_table text NOT NULL, -- e.g., customers, program_settings
    target_id uuid NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb -- e.g., {"tier_name": "Gold", "config_field": "rfm_thresholds"}
);

--
-- Name: bonus_campaigns; Type: TABLE
-- Managed by: Points Service (bonus points campaigns)
-- Partitioned by merchant_id for scalability
--

CREATE TABLE public.bonus_campaigns (
    campaign_id text NOT NULL,
    merchant_id text NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    multiplier numeric(10,2),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    conditions jsonb, -- e.g., {"min_order_value": 100}
    status text CHECK (status IN ('active', 'inactive', 'expired')) DEFAULT 'inactive',
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);

--
-- Name: customer_segments; Type: TABLE
-- Managed by: Analytics Service (RFM segment assignments)
-- Partitioned by merchant_id for Plus-scale scalability
--

CREATE TABLE public.customer_segments (
    segment_id text NOT NULL,
    merchant_id text NOT NULL,
    name text NOT NULL, -- e.g., Champions, At-Risk
    rules jsonb NOT NULL, -- e.g., {"recency": ">=4", "frequency": ">=3", "monetary": ">=4"}
    language jsonb DEFAULT '{"en": "Champions", "es": "Campeones", "fr": "Champions"}'::jsonb, -- Localized segment names
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT customer_segments_language_check CHECK (
        jsonb_typeof(language) = 'object' AND
        language ?| ARRAY['en', 'es', 'fr']
    )
) PARTITION BY HASH (merchant_id);

--
-- Name: customers; Type: TABLE
-- Managed by: Analytics Service (customer data, RFM scores)
-- rfm_score stores weighted scores (Recency: 40%, Frequency: 30%, Monetary: 30%)
--

CREATE TABLE public.customers (
    customer_id text NOT NULL,
    merchant_id text NOT NULL,
    shopify_customer_id text,
    email text NOT NULL, -- Encrypted via pgcrypto (AES-256)
    first_name text NOT NULL,
    last_name text NOT NULL,
    points_balance integer NOT NULL,
    vip_tier_id text,
    rfm_score jsonb, -- e.g., {"recency": 5, "frequency": 4, "monetary": 3, "score": 4.1}
    referral_url text,
    state text NOT NULL,
    birthday timestamp(3) without time zone,
    email_preferences jsonb NOT NULL, -- e.g., {"marketing": true, "nudges": true}
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    phone text,
    total_points_earned integer DEFAULT 0,
    total_points_redeemed integer DEFAULT 0,
    redeemed_rewards_count integer DEFAULT 0,
    CONSTRAINT customers_rfm_score_check CHECK (
        (rfm_score->>'recency' IN ('1', '2', '3', '4', '5')) AND
        (rfm_score->>'frequency' IN ('1', '2', '3', '4', '5')) AND
        (rfm_score->>'monetary' IN ('1', '2', '3', '4', '5')) AND
        (rfm_score->>'score' IS NULL OR (rfm_score->>'score')::numeric BETWEEN 1 AND 5)
    )
);

--
-- Name: email_events; Type: TABLE
-- Managed by: Analytics Service (notification tracking for Klaviyo/Postscript)
-- Partitioned by merchant_id for scalability
-- Backup retention: 90 days
--

CREATE TABLE public.email_events (
    event_id text NOT NULL,
    merchant_id text NOT NULL,
    email_id integer,
    recipient_email text, -- Encrypted via pgcrypto (AES-256)
    event_type text NOT NULL CHECK (event_type IN ('sent', 'failed', 'opened', 'clicked')),
    event_time timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb -- e.g., {"template_id": "123", "nudge_type": "at-risk"}
) PARTITION BY HASH (merchant_id);

--
-- Name: email_templates; Type: TABLE
-- Managed by: Analytics Service (multilingual notification templates)
--

CREATE TABLE public.email_templates (
    template_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL CHECK (type IN ('tier_change', 'nudge', 'welcome')),
    "group" text NOT NULL,
    sub_type text NOT NULL,
    subject text NOT NULL,
    body jsonb NOT NULL, -- e.g., {"en": "Welcome to Gold!", "es": "¡Bienvenido a Oro!"}
    is_enabled boolean NOT NULL,
    banner_image text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    CONSTRAINT email_templates_body_check CHECK (
        jsonb_typeof(body) = 'object' AND
        body ?| ARRAY['en', 'es', 'fr']
    )
);

--
-- Name: emails; Type: TABLE
-- Managed by: Analytics Service (email campaign tracking)
--

CREATE TABLE public.emails (
    id integer NOT NULL,
    subject text NOT NULL,
    body text,
    sent_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    recipient_count integer DEFAULT 0,
    status text DEFAULT 'sent'::text CHECK (status IN ('sent', 'pending', 'failed'))
);

CREATE SEQUENCE public.emails_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.emails_id_seq OWNED BY public.emails.id;

--
-- Name: import_logs; Type: TABLE
-- Managed by: Analytics Service (data import tracking)
-- Partitioned by merchant_id for scalability
--

CREATE TABLE public.import_logs (
    id text DEFAULT gen_random_uuid() NOT NULL,
    merchant_id text NOT NULL,
    success_count integer NOT NULL,
    fail_count integer NOT NULL,
    fail_reason text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    source text
) PARTITION BY HASH (merchant_id);

--
-- Name: integrations; Type: TABLE
-- Managed by: Admin Service (third-party integrations, e.g., Klaviyo, Postscript)
--

CREATE TABLE public.integrations (
    integration_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL CHECK (type IN ('klaviyo', 'postscript', 'shopify_flow')),
    api_key text NOT NULL, -- Encrypted via pgcrypto (AES-256)
    status text NOT NULL CHECK (status IN ('active', 'inactive', 'error')),
    prebuilt_flows jsonb NOT NULL, -- e.g., {"flow_id": "123", "trigger": "rfm_segment_change"}
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb
);

--
-- Name: merchants; Type: TABLE
-- Managed by: Admin Service (merchant configuration)
--

CREATE TABLE public.merchants (
    merchant_id text NOT NULL,
    shopify_domain text NOT NULL,
    plan_id text,
    billing_cycle_start timestamp(3) without time zone,
    api_token text, -- Encrypted via pgcrypto (AES-256)
    status varchar CHECK (status IN ('active', 'suspended', 'trial')),
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    brand_settings jsonb DEFAULT '{}'::jsonb,
    language jsonb DEFAULT '{"default": "en", "supported": ["en", "es", "fr"]}'::jsonb,
    features_enabled jsonb DEFAULT '{"rfm_enabled": false}'::jsonb, -- e.g., {"rfm_enabled": true, "rfm_advanced": false}
    staff_roles jsonb DEFAULT '{}'::jsonb, -- e.g., {"admin:full": ["user_id_1"], "support": ["user_id_2"]}
    rate_limit_threshold jsonb DEFAULT '{"requests_per_hour": 1000}'::jsonb, -- e.g., {"requests_per_hour": 1000, "endpoint": "/points.v1/*"}
    CONSTRAINT merchants_language_check CHECK (
        jsonb_typeof(language) = 'object' AND
        language ?| ARRAY['en', 'es', 'fr']
    )
);

COMMENT ON COLUMN public.merchants.rate_limit_threshold IS 'Stores per-merchant API rate limit configuration (e.g., requests per hour)';

--
-- Name: nudge_events; Type: TABLE
-- Managed by: Analytics Service (nudge interaction tracking)
-- Partitioned by merchant_id for scalability
-- Backup retention: 90 days
--

CREATE TABLE public.nudge_events (
    event_id text NOT NULL,
    customer_id text, -- Encrypted via pgcrypto (AES-256)
    merchant_id text NOT NULL,
    nudge_id text,
    action text NOT NULL CHECK (action IN ('view', 'click', 'dismiss')),
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (merchant_id);

--
-- Name: nudges; Type: TABLE
-- Managed by: Analytics Service (nudge configurations)
--

CREATE TABLE public.nudges (
    nudge_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL CHECK (type IN ('at-risk', 'loyal', 'new', 'inactive', 'referral')),
    title jsonb NOT NULL, -- e.g., {"en": "Stay Active!", "es": "¡Mantente Activo!"}
    description jsonb NOT NULL, -- e.g., {"en": "Shop now for 10% off", "es": "Compra ahora para 10% de descuento"}
    icon_url text,
    is_enabled boolean NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    CONSTRAINT nudges_title_check CHECK (
        jsonb_typeof(title) = 'object' AND
        title ?| ARRAY['en', 'es', 'fr']
    ),
    CONSTRAINT nudges_description_check CHECK (
        jsonb_typeof(description) = 'object' AND
        description ?| ARRAY['en', 'es', 'fr']
    )
);

--
-- Name: plans; Type: TABLE
-- Managed by: Admin Service (pricing plans)
--

CREATE TABLE public.plans (
    plan_id text NOT NULL,
    name text NOT NULL,
    order_limit integer NOT NULL,
    base_price numeric(65,30) NOT NULL,
    additional_order_rate numeric(65,30) NOT NULL,
    features jsonb NOT NULL -- e.g., {"rfm_basic": true, "rfm_advanced": false}
);

--
-- Name: points_transactions; Type: TABLE
-- Managed by: Points Service (points tracking)
-- Partitioned by merchant_id for scalability
--

CREATE TABLE public.points_transactions (
    transaction_id text NOT NULL,
    customer_id text NOT NULL,
    merchant_id text NOT NULL,
    type text CHECK (type IN ('earn', 'redeem', 'expire', 'adjust')),
    points integer NOT NULL,
    source text NOT NULL, -- e.g., order, referral, rfm_reward
    order_id text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
) PARTITION BY HASH (merchant_id);

--
-- Name: program_settings; Type: TABLE
-- Managed by: Admin Service (RFM and loyalty configuration)
--

CREATE TABLE public.program_settings (
    merchant_id text NOT NULL,
    points_currency_singular text DEFAULT 'Point'::text,
    points_currency_plural text DEFAULT 'Points'::text,
    expiry_days integer,
    allow_guests boolean DEFAULT true,
    branding jsonb, -- e.g., {"logo": "url", "color": "#FFD700"}
    config jsonb, -- e.g., {"grace_period_days": 30}
    rfm_thresholds jsonb, -- e.g., {"recency": {"5": {"maxDays": 7}}, "frequency": {"5": {"minOrders": 10}}, "monetary": {"5": {"minSpend": 2500}}}
    CONSTRAINT program_settings_config_check CHECK (
        jsonb_typeof(config) = 'object' AND
        config ?| ARRAY['en', 'es', 'fr']
    )
);

--
-- Name: referral_links; Type: TABLE
-- Managed by: Referrals Service (referral link tracking)
--

CREATE TABLE public.referral_links (
    referral_link_id text NOT NULL,
    advocate_customer_id text NOT NULL,
    merchant_id text NOT NULL,
    referral_code text NOT NULL, -- Encrypted via pgcrypto (AES-256)
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    last_viewed_at timestamp(3) without time zone
);

--
-- Name: referrals; Type: TABLE
-- Managed by: Referrals Service (referral tracking)
-- Partitioned by merchant_id for scalability
--

CREATE TABLE public.referrals (
    referral_id text NOT NULL,
    merchant_id text NOT NULL,
    advocate_customer_id text NOT NULL,
    friend_customer_id text NOT NULL,
    referral_link_id text,
    status text NOT NULL CHECK (status IN ('pending', 'completed', 'expired')),
    notification_status text CHECK (notification_status IN ('sent', 'failed', 'pending')),
    reward_id text,
    order_id text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    source text,
    campaign_id text,
    metadata jsonb DEFAULT '{}'::jsonb -- e.g., {"channel": "sms", "sent_at": "2025-07-09T10:00:00Z"}
) PARTITION BY HASH (merchant_id);

COMMENT ON COLUMN public.referrals.metadata IS 'Stores referral context (e.g., channel, sent timestamp) for analytics';

--
-- Name: reward_redemptions; Type: TABLE
-- Managed by: Points Service (reward redemption tracking)
-- Partitioned by merchant_id for scalability
--

CREATE TABLE public.reward_redemptions (
    redemption_id text NOT NULL,
    customer_id text NOT NULL,
    reward_id text NOT NULL,
    merchant_id text NOT NULL,
    campaign_id text,
    discount_code text,
    points_spent integer NOT NULL,
    status text DEFAULT 'issued'::text NOT NULL CHECK (status IN ('issued', 'used', 'expired')),
    issued_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp(3) without time zone,
    metadata jsonb -- e.g., {"rfm_segment": "Champions"}
) PARTITION BY HASH (merchant_id);

--
-- Name: rewards; Type: TABLE
-- Managed by: Points Service (reward configurations)
--

CREATE TABLE public.rewards (
    reward_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL CHECK (type IN ('discount', 'free_shipping', 'gift')),
    points_cost integer NOT NULL,
    value numeric(65,30) NOT NULL,
    is_combinable boolean NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    category text,
    is_public boolean DEFAULT true CHECK (is_public IN (true, false)),
    platform text DEFAULT 'online_store'::text CHECK (platform IN ('online_store', 'pos'))
);

--
-- Name: shopify_sessions; Type: TABLE
-- Managed by: Auth Service (Shopify OAuth sessions)
--

CREATE TABLE public.shopify_sessions (
    id integer NOT NULL,
    session_id text NOT NULL,
    shop text NOT NULL,
    state text,
    is_online boolean DEFAULT false NOT NULL,
    scope text NOT NULL,
    access_token text NOT NULL, -- Encrypted via pgcrypto (AES-256)
    expires_at timestamp(3) without time zone,
    online_access_info jsonb,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE SEQUENCE public.shopify_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.shopify_sessions_id_seq OWNED BY public.shopify_sessions.id;

--
-- Name: usage_records; Type: TABLE
-- Managed by: Admin Service (billing and usage tracking)
--

CREATE TABLE public.usage_records (
    id integer NOT NULL,
    merchant_id text NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    order_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE SEQUENCE public.usage_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.usage_records_id_seq OWNED BY public.usage_records.id;

--
-- Name: vip_tiers; Type: TABLE
-- Managed by: Points Service (VIP tier configurations)
--

CREATE TABLE public.vip_tiers (
    vip_tier_id text NOT NULL,
    merchant_id text NOT NULL,
    name text NOT NULL, -- e.g., Gold, Platinum
    threshold_type text NOT NULL CHECK (threshold_type IN ('points', 'spend', 'orders')),
    threshold_value numeric(65,30) NOT NULL,
    earning_multiplier numeric(65,30) NOT NULL,
    entry_reward_id text,
    perks jsonb NOT NULL, -- e.g., {"discount": 10, "free_shipping": true}
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    tier_level integer DEFAULT 1
);

--
-- Name: gdpr_requests; Type: TABLE
-- Managed by: Analytics Service (GDPR/CCPA compliance)
-- Partitioned by merchant_id for scalability
--

CREATE TABLE public.gdpr_requests (
    request_id text NOT NULL,
    merchant_id text NOT NULL,
    customer_id text,
    request_type text CHECK (request_type IN ('data_request', 'redact')),
    status text CHECK (status IN ('pending', 'completed', 'failed')),
    retention_expires_at timestamp(3) without time zone,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb DEFAULT '{}'::jsonb -- e.g., {"origin": "widget", "tables": ["customers", "points_transactions"]}
) PARTITION BY HASH (merchant_id);

COMMENT ON COLUMN public.gdpr_requests.metadata IS 'Stores additional context for GDPR requests (e.g., origin, affected tables)';

--
-- Name: rfm_segment_counts; Type: MATERIALIZED VIEW
-- Managed by: Analytics Service (real-time RFM segment analytics)
-- Refreshed daily via refresh_rfm_segment_counts() (cron: 0 1 * * *)
--

CREATE MATERIALIZED VIEW public.rfm_segment_counts AS
    SELECT 
        cs.merchant_id,
        cs.name AS segment_name,
        COUNT(*) AS customer_count,
        CURRENT_TIMESTAMP AS last_refreshed
    FROM public.customer_segments cs
    JOIN public.customers c ON cs.merchant_id = c.merchant_id
    WHERE c.rfm_score @> cs.rules AND cs.created_at IS NOT NULL
    GROUP BY cs.merchant_id, cs.name
    WITH DATA;

--
-- Set default sequences
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);
ALTER TABLE ONLY public.emails ALTER COLUMN id SET DEFAULT nextval('public.emails_id_seq'::regclass);
ALTER TABLE ONLY public.shopify_sessions ALTER COLUMN id SET DEFAULT nextval('public.shopify_sessions_id_seq'::regclass);
ALTER TABLE ONLY public.usage_records ALTER COLUMN id SET DEFAULT nextval('public.usage_records_id_seq'::regclass);

--
-- Constraints
--

ALTER TABLE ONLY public.__diesel_schema_migrations
    ADD CONSTRAINT __diesel_schema_migrations_pkey PRIMARY KEY (version);

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_username_key UNIQUE (username);
ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_email_key UNIQUE (email);

ALTER TABLE ONLY public.api_logs
    ADD CONSTRAINT api_logs_pkey PRIMARY KEY (id, merchant_id);

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.bonus_campaigns
    ADD CONSTRAINT bonus_campaigns_pkey PRIMARY KEY (campaign_id, merchant_id);

ALTER TABLE ONLY public.customer_segments
    ADD CONSTRAINT customer_segments_pkey PRIMARY KEY (segment_id, merchant_id);

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);

ALTER TABLE ONLY public.email_events
    ADD CONSTRAINT email_events_pkey PRIMARY KEY (event_id, merchant_id);

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (template_id);

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.import_logs
    ADD CONSTRAINT import_logs_pkey PRIMARY KEY (id, merchant_id);

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (integration_id);

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_pkey PRIMARY KEY (merchant_id);
ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_shopify_domain_key UNIQUE (shopify_domain);

ALTER TABLE ONLY public.nudge_events
    ADD CONSTRAINT nudge_events_pkey PRIMARY KEY (event_id, merchant_id);

ALTER TABLE ONLY public.nudges
    ADD CONSTRAINT nudges_pkey PRIMARY KEY (nudge_id);

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (plan_id);

ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_pkey PRIMARY KEY (transaction_id, merchant_id);

ALTER TABLE ONLY public.program_settings
    ADD CONSTRAINT program_settings_pkey PRIMARY KEY (merchant_id);

ALTER TABLE ONLY public.referral_links
    ADD CONSTRAINT referral_links_pkey PRIMARY KEY (referral_link_id);

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (referral_id, merchant_id);

ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_pkey PRIMARY KEY (redemption_id, merchant_id);

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (reward_id);

ALTER TABLE ONLY public.shopify_sessions
    ADD CONSTRAINT shopify_sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.shopify_sessions
    ADD CONSTRAINT shopify_sessions_session_id_key UNIQUE (session_id);

ALTER TABLE ONLY public.usage_records
    ADD CONSTRAINT usage_records_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usage_records
    ADD CONSTRAINT usage_records_merchant_id_period_start_period_end_key UNIQUE (merchant_id, period_start, period_end);

ALTER TABLE ONLY public.vip_tiers
    ADD CONSTRAINT vip_tiers_pkey PRIMARY KEY (vip_tier_id);

ALTER TABLE ONLY public.gdpr_requests
    ADD CONSTRAINT gdpr_requests_pkey PRIMARY KEY (request_id, merchant_id);

--
-- Foreign Keys
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_admin_user_id_fkey FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.bonus_campaigns
    ADD CONSTRAINT bonus_campaigns_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.customer_segments
    ADD CONSTRAINT customer_segments_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_vip_tier_id_fkey FOREIGN KEY (vip_tier_id) REFERENCES public.vip_tiers(vip_tier_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE ONLY public.email_events
    ADD CONSTRAINT email_events_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.email_events
    ADD CONSTRAINT email_events_email_id_fkey FOREIGN KEY (email_id) REFERENCES public.emails(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY public.import_logs
    ADD CONSTRAINT import_logs_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY public.nudge_events
    ADD CONSTRAINT nudge_events_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.nudge_events
    ADD CONSTRAINT nudge_events_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.nudge_events
    ADD CONSTRAINT nudge_events_nudge_id_fkey FOREIGN KEY (nudge_id) REFERENCES public.nudges(nudge_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.nudges
    ADD CONSTRAINT nudges_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY public.program_settings
    ADD CONSTRAINT program_settings_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.referral_links
    ADD CONSTRAINT referral_links_advocate_customer_id_fkey FOREIGN KEY (advocate_customer_id) REFERENCES public.customers(customer_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.referral_links
    ADD CONSTRAINT referral_links_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_advocate_customer_id_fkey FOREIGN KEY (advocate_customer_id) REFERENCES public.customers(customer_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_friend_customer_id_fkey FOREIGN KEY (friend_customer_id) REFERENCES public.customers(customer_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_reward_id_fkey FOREIGN KEY (reward_id) REFERENCES public.rewards(reward_id) ON DELETE SET NULL;
ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referral_link_id_fkey FOREIGN KEY (referral_link_id) REFERENCES public.referral_links(referral_link_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_reward_id_fkey FOREIGN KEY (reward_id) REFERENCES public.rewards(reward_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.bonus_campaigns(campaign_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY public.usage_records
    ADD CONSTRAINT usage_records_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.vip_tiers
    ADD CONSTRAINT vip_tiers_entry_reward_id_fkey FOREIGN KEY (entry_reward_id) REFERENCES public.rewards(reward_id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE ONLY public.vip_tiers
    ADD CONSTRAINT vip_tiers_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE ONLY public.gdpr_requests
    ADD CONSTRAINT gdpr_requests_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.gdpr_requests
    ADD CONSTRAINT gdpr_requests_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON DELETE CASCADE;

--
-- Indexes
--

CREATE INDEX idx_customers_email ON public.customers USING btree (email);
CREATE INDEX idx_customers_rfm_score ON public.customers USING gin (rfm_score);
CREATE INDEX idx_customers_rfm_score_at_risk ON public.customers USING btree ((rfm_score->>'score')::numeric) WHERE (rfm_score->>'score')::numeric < 2; -- Partial index for At-Risk segment
CREATE INDEX idx_points_transactions_customer_id ON public.points_transactions USING btree (customer_id, created_at);
CREATE INDEX idx_points_transactions_merchant_id_type ON public.points_transactions USING btree (merchant_id, type);
CREATE INDEX idx_api_logs_merchant_id_timestamp ON public.api_logs USING btree (merchant_id, timestamp);
CREATE INDEX idx_api_logs_status_code ON public.api_logs USING btree (merchant_id, status_code) WHERE status_code = 429;
CREATE INDEX idx_customer_segments_rules ON public.customer_segments USING gin (rules);
CREATE INDEX idx_program_settings_config ON public.program_settings USING gin (config);
CREATE INDEX idx_program_settings_rfm_thresholds ON public.program_settings USING gin (rfm_thresholds);
CREATE INDEX idx_reward_redemptions_reward_id ON public.reward_redemptions USING btree (reward_id);
CREATE INDEX idx_nudge_events_customer_id ON public.nudge_events USING btree (customer_id);
CREATE INDEX idx_nudge_events_merchant_id ON public.nudge_events USING btree (merchant_id);
CREATE INDEX idx_email_events_merchant_id ON public.email_events USING btree (merchant_id);
CREATE INDEX idx_email_events_merchant_id_event_type ON public.email_events USING btree (merchant_id, event_type);
CREATE INDEX idx_email_templates_merchant_id ON public.email_templates USING btree (merchant_id);
CREATE INDEX idx_email_templates_type ON public.email_templates USING btree (type);
CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action); -- For gRPC-driven RBAC queries
CREATE INDEX idx_audit_logs_admin_user_id ON public.audit_logs USING btree (admin_user_id);
CREATE INDEX idx_gdpr_requests_merchant_id_request_type ON public.gdpr_requests USING btree (merchant_id, request_type);
CREATE INDEX idx_referrals_notification_status ON public.referrals USING btree (notification_status);
CREATE INDEX idx_bonus_campaigns_merchant_id_type ON public.bonus_campaigns USING btree (merchant_id, type);
CREATE INDEX idx_rfm_segment_counts_merchant_id ON public.rfm_segment_counts USING btree (merchant_id);
CREATE INDEX idx_rfm_segment_counts_merchant_id_segment_name ON public.rfm_segment_counts USING btree (merchant_id, segment_name);

--
-- Triggers
--

CREATE TRIGGER set_updated_at_admin_users
    BEFORE UPDATE ON public.admin_users
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_bonus_campaigns
    BEFORE UPDATE ON public.bonus_campaigns
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_customer_segments
    BEFORE UPDATE ON public.customer_segments
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_email_templates
    BEFORE UPDATE ON public.email_templates
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_gdpr_requests
    BEFORE UPDATE ON public.gdpr_requests
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_integrations
    BEFORE UPDATE ON public.integrations
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_merchants
    BEFORE UPDATE ON public.merchants
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_nudges
    BEFORE UPDATE ON public.nudges
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_referrals
    BEFORE UPDATE ON public.referrals
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_rewards
    BEFORE UPDATE ON public.rewards
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_shopify_sessions
    BEFORE UPDATE ON public.shopify_sessions
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

CREATE TRIGGER set_updated_at_vip_tiers
    BEFORE UPDATE ON public.vip_tiers
    FOR EACH ROW EXECUTE FUNCTION public.diesel_set_updated_at();

--
-- Comments
--

COMMENT ON TABLE public.api_logs IS 'Tracks API usage for Analytics Service; partitioned by merchant_id; 90-day backup retention';
COMMENT ON TABLE public.audit_logs IS 'Tracks RFM config changes and tier assignments for Admin Service; 90-day backup retention';
COMMENT ON TABLE public.email_events IS 'Tracks notification events for Analytics Service (Klaviyo/Postscript); partitioned by merchant_id; 90-day backup retention';
COMMENT ON TABLE public.nudge_events IS 'Tracks nudge interactions for Analytics Service; partitioned by merchant_id; 90-day backup retention';
COMMENT ON TABLE public.customers IS 'Stores customer data and RFM scores for Analytics Service; email and rfm_score encrypted with AES-256';
COMMENT ON TABLE public.email_templates IS 'Stores multilingual notification templates for Analytics Service; body supports en, es, fr';
COMMENT ON TABLE public.nudges IS 'Stores nudge configurations for Analytics Service; title and description support en, es, fr';
COMMENT ON TABLE public.program_settings IS 'Stores RFM and loyalty configurations for Admin Service; rfm_thresholds defines RFM rules';
COMMENT ON TABLE public.integrations IS 'Stores third-party integrations (Klaviyo, Postscript, Shopify Flow) for Admin Service; api_key encrypted with AES-256';
COMMENT ON TABLE public.merchants IS 'Stores merchant configurations for Admin Service; api_token encrypted with AES-256';
COMMENT ON TABLE public.rfm_segment_counts IS 'Materialized view for RFM segment counts in Analytics Service; refreshed daily via cron (0 1 * * *)';
COMMENT ON TABLE public.import_logs IS 'Tracks customer import logs for Analytics Service; partitioned by merchant_id';
COMMENT ON TABLE public.gdpr_requests IS 'Tracks GDPR/CCPA requests for Analytics Service; partitioned by merchant_id; 90-day backup retention';