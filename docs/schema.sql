--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

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

--
-- Name: diesel_manage_updated_at(regclass); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.diesel_manage_updated_at(_tbl regclass) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE format('CREATE TRIGGER set_updated_at BEFORE UPDATE ON %s
                    FOR EACH ROW EXECUTE PROCEDURE diesel_set_updated_at()', _tbl);
END;
$$;


ALTER FUNCTION public.diesel_manage_updated_at(_tbl regclass) OWNER TO postgres;

--
-- Name: diesel_set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.diesel_set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: __diesel_schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.__diesel_schema_migrations (
    version character varying(50) NOT NULL,
    run_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.__diesel_schema_migrations OWNER TO postgres;

--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_users (
    id integer NOT NULL,
    username text NOT NULL,
    password text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    email text NOT NULL
);


ALTER TABLE public.admin_users OWNER TO postgres;

--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_users_id_seq OWNER TO postgres;

--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- Name: api_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_logs (
    id text NOT NULL,
    merchant_id text NOT NULL,
    route text NOT NULL,
    method text NOT NULL,
    status_code integer NOT NULL,
    "timestamp" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.api_logs OWNER TO postgres;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id uuid NOT NULL,
    admin_user_id integer,
    action text NOT NULL,
    target_table text NOT NULL,
    target_id uuid NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: bonus_campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bonus_campaigns (
    campaign_id text NOT NULL,
    merchant_id text NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    multiplier numeric(10,2),
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    conditions jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.bonus_campaigns OWNER TO postgres;

--
-- Name: customer_segments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_segments (
    segment_id text NOT NULL,
    merchant_id text NOT NULL,
    name text NOT NULL,
    rules jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.customer_segments OWNER TO postgres;

--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    customer_id text NOT NULL,
    merchant_id text NOT NULL,
    shopify_customer_id text,
    email text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    points_balance integer NOT NULL,
    vip_tier_id text,
    referral_url text,
    state text NOT NULL,
    birthday timestamp(3) without time zone,
    email_preferences jsonb NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    phone text,
    total_points_earned integer DEFAULT 0,
    total_points_redeemed integer DEFAULT 0,
    redeemed_rewards_count integer DEFAULT 0
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: email_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_events (
    event_id text NOT NULL,
    email_id integer,
    recipient_email text,
    event_type text NOT NULL,
    event_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb
);


ALTER TABLE public.email_events OWNER TO postgres;

--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_templates (
    template_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL,
    "group" text NOT NULL,
    sub_type text NOT NULL,
    subject text NOT NULL,
    body text NOT NULL,
    is_enabled boolean NOT NULL,
    banner_image text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.email_templates OWNER TO postgres;

--
-- Name: emails; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.emails (
    id integer NOT NULL,
    subject text NOT NULL,
    body text,
    sent_at timestamp without time zone DEFAULT now(),
    recipient_count integer DEFAULT 0,
    status text DEFAULT 'sent'::text
);


ALTER TABLE public.emails OWNER TO postgres;

--
-- Name: emails_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.emails_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.emails_id_seq OWNER TO postgres;

--
-- Name: emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.emails_id_seq OWNED BY public.emails.id;


--
-- Name: import_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.import_logs (
    id text DEFAULT gen_random_uuid() NOT NULL,
    success_count integer NOT NULL,
    fail_count integer NOT NULL,
    fail_reason text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    source text
);


ALTER TABLE public.import_logs OWNER TO postgres;

--
-- Name: integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integrations (
    integration_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL,
    api_key text NOT NULL,
    status text NOT NULL,
    prebuilt_flows jsonb NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.integrations OWNER TO postgres;

--
-- Name: merchants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.merchants (
    merchant_id text NOT NULL,
    shopify_domain text NOT NULL,
    plan_id text,
    billing_cycle_start timestamp(3) without time zone,
    api_token text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    brand_settings jsonb DEFAULT '{}'::jsonb,
    language character varying DEFAULT 'en'::character varying,
    features_enabled jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.merchants OWNER TO postgres;

--
-- Name: nudge_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nudge_events (
    event_id text NOT NULL,
    customer_id text,
    merchant_id text NOT NULL,
    nudge_id text,
    action text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.nudge_events OWNER TO postgres;

--
-- Name: nudges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nudges (
    nudge_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL,
    title jsonb NOT NULL,
    description jsonb NOT NULL,
    icon_url text,
    is_enabled boolean NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public.nudges OWNER TO postgres;

--
-- Name: plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plans (
    plan_id text NOT NULL,
    name text NOT NULL,
    order_limit integer NOT NULL,
    base_price numeric(65,30) NOT NULL,
    additional_order_rate numeric(65,30) NOT NULL,
    features jsonb NOT NULL
);


ALTER TABLE public.plans OWNER TO postgres;

--
-- Name: points_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.points_transactions (
    transaction_id text NOT NULL,
    customer_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL,
    points integer NOT NULL,
    source text NOT NULL,
    order_id text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.points_transactions OWNER TO postgres;

--
-- Name: program_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.program_settings (
    merchant_id text NOT NULL,
    points_currency_singular text DEFAULT 'Point'::text,
    points_currency_plural text DEFAULT 'Points'::text,
    expiry_days integer,
    allow_guests boolean DEFAULT true,
    branding jsonb,
    config jsonb
);


ALTER TABLE public.program_settings OWNER TO postgres;

--
-- Name: referral_links; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.referral_links (
    referral_link_id text NOT NULL,
    advocate_customer_id text NOT NULL,
    merchant_id text NOT NULL,
    referral_code text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.referral_links OWNER TO postgres;

--
-- Name: referrals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.referrals (
    referral_id text NOT NULL,
    merchant_id text NOT NULL,
    advocate_customer_id text NOT NULL,
    friend_customer_id text NOT NULL,
    status text NOT NULL,
    reward_id text,
    order_id text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    source text,
    campaign_id text
);


ALTER TABLE public.referrals OWNER TO postgres;

--
-- Name: reward_redemptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reward_redemptions (
    redemption_id text NOT NULL,
    customer_id text NOT NULL,
    reward_id text NOT NULL,
    merchant_id text NOT NULL,
    discount_code text,
    points_spent integer NOT NULL,
    status text DEFAULT 'issued'::text NOT NULL,
    issued_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone,
    metadata jsonb
);


ALTER TABLE public.reward_redemptions OWNER TO postgres;

--
-- Name: rewards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rewards (
    reward_id text NOT NULL,
    merchant_id text NOT NULL,
    type text NOT NULL,
    points_cost integer NOT NULL,
    value numeric(65,30) NOT NULL,
    is_combinable boolean NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    category text,
    is_public boolean DEFAULT true,
    platform text DEFAULT 'online_store'::text
);


ALTER TABLE public.rewards OWNER TO postgres;

--
-- Name: shopify_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shopify_sessions (
    id integer NOT NULL,
    session_id text NOT NULL,
    shop text NOT NULL,
    state text,
    is_online boolean DEFAULT false NOT NULL,
    scope text NOT NULL,
    access_token text NOT NULL,
    expires_at timestamp without time zone,
    online_access_info jsonb,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.shopify_sessions OWNER TO postgres;

--
-- Name: shopify_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shopify_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shopify_sessions_id_seq OWNER TO postgres;

--
-- Name: shopify_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shopify_sessions_id_seq OWNED BY public.shopify_sessions.id;


--
-- Name: usage_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usage_records (
    id integer NOT NULL,
    merchant_id text NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    order_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.usage_records OWNER TO postgres;

--
-- Name: usage_records_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usage_records_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usage_records_id_seq OWNER TO postgres;

--
-- Name: usage_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usage_records_id_seq OWNED BY public.usage_records.id;


--
-- Name: vip_tiers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vip_tiers (
    vip_tier_id text NOT NULL,
    merchant_id text NOT NULL,
    name text NOT NULL,
    threshold_type text NOT NULL,
    threshold_value numeric(65,30) NOT NULL,
    earning_multiplier numeric(65,30) NOT NULL,
    entry_reward_id text,
    perks jsonb NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    tier_level integer DEFAULT 1
);


ALTER TABLE public.vip_tiers OWNER TO postgres;

--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: emails id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emails ALTER COLUMN id SET DEFAULT nextval('public.emails_id_seq'::regclass);


--
-- Name: shopify_sessions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_sessions ALTER COLUMN id SET DEFAULT nextval('public.shopify_sessions_id_seq'::regclass);


--
-- Name: usage_records id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usage_records ALTER COLUMN id SET DEFAULT nextval('public.usage_records_id_seq'::regclass);


--
-- Name: __diesel_schema_migrations __diesel_schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.__diesel_schema_migrations
    ADD CONSTRAINT __diesel_schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: admin_users admin_users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_email_key UNIQUE (email);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: admin_users admin_users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_username_key UNIQUE (username);


--
-- Name: api_logs api_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_logs
    ADD CONSTRAINT api_logs_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: bonus_campaigns bonus_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bonus_campaigns
    ADD CONSTRAINT bonus_campaigns_pkey PRIMARY KEY (campaign_id);


--
-- Name: customer_segments customer_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_segments
    ADD CONSTRAINT customer_segments_pkey PRIMARY KEY (segment_id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: email_events email_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_events
    ADD CONSTRAINT email_events_pkey PRIMARY KEY (event_id);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (template_id);


--
-- Name: emails emails_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);


--
-- Name: import_logs import_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.import_logs
    ADD CONSTRAINT import_logs_pkey PRIMARY KEY (id);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (integration_id);


--
-- Name: merchants merchants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_pkey PRIMARY KEY (merchant_id);


--
-- Name: merchants merchants_shopify_domain_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_shopify_domain_key UNIQUE (shopify_domain);


--
-- Name: nudge_events nudge_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nudge_events
    ADD CONSTRAINT nudge_events_pkey PRIMARY KEY (event_id);


--
-- Name: nudges nudges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nudges
    ADD CONSTRAINT nudges_pkey PRIMARY KEY (nudge_id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (plan_id);


--
-- Name: points_transactions points_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: program_settings program_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_settings
    ADD CONSTRAINT program_settings_pkey PRIMARY KEY (merchant_id);


--
-- Name: referral_links referral_links_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referral_links
    ADD CONSTRAINT referral_links_pkey PRIMARY KEY (referral_link_id);


--
-- Name: referral_links referral_links_referral_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referral_links
    ADD CONSTRAINT referral_links_referral_code_key UNIQUE (referral_code);


--
-- Name: referrals referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (referral_id);


--
-- Name: reward_redemptions reward_redemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_pkey PRIMARY KEY (redemption_id);


--
-- Name: rewards rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (reward_id);


--
-- Name: shopify_sessions shopify_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_sessions
    ADD CONSTRAINT shopify_sessions_pkey PRIMARY KEY (id);


--
-- Name: shopify_sessions shopify_sessions_session_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shopify_sessions
    ADD CONSTRAINT shopify_sessions_session_id_key UNIQUE (session_id);


--
-- Name: usage_records usage_records_merchant_id_period_start_period_end_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usage_records
    ADD CONSTRAINT usage_records_merchant_id_period_start_period_end_key UNIQUE (merchant_id, period_start, period_end);


--
-- Name: usage_records usage_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usage_records
    ADD CONSTRAINT usage_records_pkey PRIMARY KEY (id);


--
-- Name: vip_tiers vip_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vip_tiers
    ADD CONSTRAINT vip_tiers_pkey PRIMARY KEY (vip_tier_id);


--
-- Name: audit_logs audit_logs_admin_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_admin_user_id_fkey FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id) ON DELETE SET NULL;


--
-- Name: bonus_campaigns bonus_campaigns_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bonus_campaigns
    ADD CONSTRAINT bonus_campaigns_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;


--
-- Name: customer_segments customer_segments_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_segments
    ADD CONSTRAINT customer_segments_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;


--
-- Name: customers customers_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: customers customers_vip_tier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_vip_tier_id_fkey FOREIGN KEY (vip_tier_id) REFERENCES public.vip_tiers(vip_tier_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: email_events email_events_email_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_events
    ADD CONSTRAINT email_events_email_id_fkey FOREIGN KEY (email_id) REFERENCES public.emails(id);


--
-- Name: email_templates email_templates_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: integrations integrations_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: nudge_events nudge_events_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nudge_events
    ADD CONSTRAINT nudge_events_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: nudge_events nudge_events_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nudge_events
    ADD CONSTRAINT nudge_events_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id);


--
-- Name: nudge_events nudge_events_nudge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nudge_events
    ADD CONSTRAINT nudge_events_nudge_id_fkey FOREIGN KEY (nudge_id) REFERENCES public.nudges(nudge_id);


--
-- Name: nudges nudges_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nudges
    ADD CONSTRAINT nudges_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: points_transactions points_transactions_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: points_transactions points_transactions_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.points_transactions
    ADD CONSTRAINT points_transactions_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: program_settings program_settings_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.program_settings
    ADD CONSTRAINT program_settings_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON DELETE CASCADE;


--
-- Name: referral_links referral_links_advocate_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referral_links
    ADD CONSTRAINT referral_links_advocate_customer_id_fkey FOREIGN KEY (advocate_customer_id) REFERENCES public.customers(customer_id);


--
-- Name: referral_links referral_links_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referral_links
    ADD CONSTRAINT referral_links_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id);


--
-- Name: referrals referrals_advocate_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_advocate_customer_id_fkey FOREIGN KEY (advocate_customer_id) REFERENCES public.customers(customer_id);


--
-- Name: referrals referrals_friend_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_friend_customer_id_fkey FOREIGN KEY (friend_customer_id) REFERENCES public.customers(customer_id);


--
-- Name: referrals referrals_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: referrals referrals_reward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_reward_id_fkey FOREIGN KEY (reward_id) REFERENCES public.rewards(reward_id);


--
-- Name: reward_redemptions reward_redemptions_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: reward_redemptions reward_redemptions_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id);


--
-- Name: reward_redemptions reward_redemptions_reward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reward_redemptions
    ADD CONSTRAINT reward_redemptions_reward_id_fkey FOREIGN KEY (reward_id) REFERENCES public.rewards(reward_id);


--
-- Name: rewards rewards_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: usage_records usage_records_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usage_records
    ADD CONSTRAINT usage_records_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id);


--
-- Name: vip_tiers vip_tiers_entry_reward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vip_tiers
    ADD CONSTRAINT vip_tiers_entry_reward_id_fkey FOREIGN KEY (entry_reward_id) REFERENCES public.rewards(reward_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: vip_tiers vip_tiers_merchant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vip_tiers
    ADD CONSTRAINT vip_tiers_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(merchant_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

