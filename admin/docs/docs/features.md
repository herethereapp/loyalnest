```markdown
# LoyalNest App Features

## Overview
This document outlines the feature set for the LoyalNest app, a loyalty program for Shopify merchants, categorized into **Must Have** (Phase 1, MVP for small merchants, 100–5,000 customers), **Should Have** (Phase 3, enhancements for medium to Shopify Plus merchants), and **Could Have** (Phase 6, polish for global/premium merchants). Features align with user stories (US-CW1–CW11, US-MD1–MD12, US-AM1–AM9, US-BI1–BI3), wireframes (Customer Widget, Merchant Dashboard, Admin Module), and the LoyalNest App Feature Analysis. The app uses a microservices architecture (Analytics, Admin, Points, Referrals, Auth, Frontend) with NestJS/TypeORM, gRPC, and Rust/Wasm for Shopify Functions. Scalability is ensured via Redis Streams (e.g., `rfm:customer:{id}`, `leaderboard:{merchant_id}`), Bull queues, PostgreSQL partitioning by `merchant_id`, and Docker Compose deployment. Security includes Shopify OAuth, RBAC, AES-256 encryption (pgcrypto), and GDPR/CCPA compliance. Monitoring uses Prometheus/Grafana (API latency <1s, error rate <1%) and Sentry for error tracking. Events are tracked via PostHog (e.g., `points_earned`, `referral_created`).

## MUST HAVE FEATURES
Essential for core functionality, user engagement, Shopify App Store compliance, and scalability for 100–5,000 customers.

### 1. Points Program (Phase 1)
- **Goal**: Enable customers to earn and redeem points to drive loyalty. Success metric: 90%+ successful point awards within 1s, 85%+ redemption rate.
- **Earning Actions**: Purchases (10 points/$), account creation (200 points), newsletter signups (100 points), reviews (100 points), birthdays (200 points). Adjusted by RFM multipliers (`program_settings.rfm_thresholds`, e.g., 1.5x for Champions).
- **Redemption Options**: Discounts ($5 off for 500 points), free shipping (1000 points), free products (1500 points), coupons at checkout via Shopify Checkout UI Extensions (Rust/Wasm).
- **Points Adjustments**: Deductions for order cancellations/refunds via `orders/cancel` webhook, logged in `points_transactions`.
- **Customization**: Customizable rewards panel, launcher button, points currency (e.g., Stars) with i18next support (`en`, `es`, `fr`).
- **Scalability**: Handles 1,000 orders/hour via Redis Streams (`points:{customer_id}`), Bull queues for async processing, PostgreSQL partitioning by `merchant_id`. Shopify rate limits (2 req/s REST, 50 points/s GraphQL) managed with exponential backoff.
- **Database Design**:
  - **Table**: `points_transactions` (partitioned by `merchant_id`)
    - `transaction_id` (text, PK, NOT NULL): Unique ID.
    - `customer_id` (text, FK → `customers`, NOT NULL): Customer.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `type` (text, CHECK IN ('earn', 'redeem', 'expire', 'adjust', 'import', 'referral', 'campaign')): Action type.
    - `points` (integer, CHECK >= 0): Points awarded.
    - `source` (text): Source (e.g., "order", "rfm_reward").
    - `order_id` (text): Shopify order ID.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `customers`
    - `points_balance` (integer, NOT NULL, DEFAULT 0): Current balance.
    - `total_points_earned` (integer, NOT NULL, DEFAULT 0): Cumulative points.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `points_earned`.
    - `metadata` (jsonb): e.g., `{"points": 100, "source": "order"}`.
  - **Indexes**: `idx_points_transactions_customer_id` (btree: `customer_id`, `created_at`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/points/earn` (REST) | gRPC `/points.v1/PointsService/EarnPoints`
    - **Input**: `{ customer_id: string, order_id: string, action_type: string, locale: string }`
    - **Output**: `{ status: string, transaction_id: string, points: number, error: { code: string, message: string } | null }`
    - **Flow**: Validate order via GraphQL Admin API, apply RFM multiplier, insert into `points_transactions`, update `customers.points_balance`, cache in Redis (`points:{customer_id}`), notify via SendGrid (3 retries, exponential backoff), log in `audit_logs`, track via PostHog (`points_earned`).
  - **POST** `/v1/api/rewards/redeem` (REST) | gRPC `/points.v1/PointsService/RedeemReward`
    - **Input**: `{ customer_id: string, reward_id: string, locale: string }`
    - **Output**: `{ status: string, redemption_id: string, discount_code: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate `points_balance`, create discount via GraphQL Admin API (Rust/Wasm), insert into `reward_redemptions`, deduct points, cache in Redis, log in `audit_logs`, track via PostHog (`points_redeemed`).
- **Service**: Points Service (gRPC: `/points.v1/*`).

### 2. Referral Program (Phase 1)
- **Goal**: Drive customer acquisition via referrals. Success metric: 5%+ referral conversion rate.
- **Sharing Options**: Email, SMS (Twilio/SendGrid), social media (Facebook, Instagram). Generates unique referral link/code via Storefront API.
- **Rewards**: Points (50 for referrer/referee) or discounts (10% off) issued via GraphQL Admin API.
- **Dedicated Referral Page**: Displays incentives for referrer and friend, localized (`en`, `es`, `fr`).
- **Async Processing**: Queued notifications via Bull, cached in Redis (`referral:{referral_code}`).
- **Database Design**:
  - **Table**: `referral_links` (partitioned by `merchant_id`)
    - `referral_link_id` (text, PK, NOT NULL): Unique ID.
    - `advocate_customer_id` (text, FK → `customers`, NOT NULL): Advocate.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `referral_code` (text, UNIQUE, NOT NULL): Unique code.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `referrals` (partitioned by `merchant_id`)
    - `referral_id` (text, PK, NOT NULL): Unique ID.
    - `advocate_customer_id` (text, FK → `customers`, NOT NULL): Advocate.
    - `friend_customer_id` (text, FK → `customers`, NOT NULL): Friend.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `reward_id` (text, FK → `rewards`): Reward.
    - `status` (text, CHECK IN ('pending', 'completed', 'expired')): Status.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `referral_created`, `referral_completed`.
    - `metadata` (jsonb): e.g., `{"referral_code": "REF123"}`.
  - **Indexes**: `idx_referral_links_referral_code` (btree: `referral_code`), `idx_referrals_merchant_id` (btree: `merchant_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/referrals/create` (REST) | gRPC `/referrals.v1/ReferralService/CreateReferral`
    - **Input**: `{ advocate_customer_id: string, locale: string }`
    - **Output**: `{ status: string, referral_code: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate input, insert into `referral_links`, cache in Redis (`referral:{referral_code}`), notify via Twilio/SendGrid (3 retries), log in `audit_logs`, track via PostHog (`referral_created`).
  - **POST** `/v1/api/referrals/complete` (REST) | gRPC `/referrals.v1/ReferralService/CompleteReferral`
    - **Input**: `{ referral_code: string, friend_customer_id: string, locale: string }`
    - **Output**: `{ status: string, referral_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Verify `customers/create` webhook, validate `referral_code`, insert into `referrals`, award points, notify via Twilio/SendGrid, cache in Redis, log in `audit_logs`, track via PostHog (`referral_completed`).
- **Service**: Referrals Service (gRPC: `/referrals.v1/*`).

### 3. On-Site Content (Phase 1)
- **Goal**: Enhance visibility and engagement via widgets. Success metric: 85%+ widget interaction rate, 10%+ nudge conversion rate.
- **Widgets**: SEO-friendly loyalty page, rewards panel, launcher button, checkout integration, points display on product pages via Storefront API.
- **Nudges**: Post-purchase prompts, email capture popups, localized (`en`, `es`, `fr`) with i18next.
- **Accessibility**: ARIA labels, keyboard navigation for screen reader support.
- **Scalability**: Renders <1s via Redis caching (`content:{merchant_id}:{locale}`), supports 1,000 orders/hour.
- **Database Design**:
  - **Table**: `program_settings`
    - `merchant_id` (text, PK, FK → `merchants`, NOT NULL): Merchant.
    - `branding` (jsonb): e.g., `{"loyalty_page": {"en": {...}, "es": {...}}, "popup": {...}}`.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `content_updated`.
    - `metadata` (jsonb): e.g., `{"type": "loyalty_page"}`.
  - **Indexes**: `idx_program_settings_merchant_id` (btree: `merchant_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **PUT** `/v1/api/content` (REST) | gRPC `/frontend.v1/FrontendService/UpdateContent`
    - **Input**: `{ merchant_id: string, branding: { loyalty_page: object, popup: object }, locale: string }`
    - **Output**: `{ status: string, preview: object, error: { code: string, message: string } | null }`
    - **Flow**: Validate inputs, update `program_settings.branding`, cache in Redis (`content:{merchant_id}:{locale}`), log in `audit_logs`, track via PostHog (`content_updated`).
- **Service**: Frontend Service (gRPC: `/frontend.v1/*`).

### 4. Integrations (Phase 1)
- **Goal**: Seamlessly connect with Shopify and third-party tools. Success metric: 99%+ sync accuracy, 90%+ notification delivery rate.
- **Shopify**: OAuth, webhooks (`orders/create`, `customers/data_request`, `customers/redact`) with HMAC validation, POS for online/in-store rewards (10 points/$). Handles rate limits (2 req/s REST, 40 req/s Plus) with exponential backoff.
- **Email**: SendGrid for notifications (points, referrals) with 3 retries, exponential backoff.
- **Reviews**: Yotpo or Judge.me for points-for-reviews, integrated via GraphQL Admin API.
- **Database Design**:
  - **Table**: `api_logs`
    - `log_id` (text, PK, NOT NULL): Log ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `endpoint` (text, NOT NULL): e.g., `orders/create`.
    - `payload` (jsonb): Webhook payload.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `shopify_sync`.
    - `metadata` (jsonb): e.g., `{"endpoint": "orders/create"}`.
  - **Indexes**: `idx_api_logs_merchant_id` (btree: `merchant_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/shopify/webhook` (REST) | gRPC `/admin.v1/AdminService/HandleShopifyWebhook`
    - **Input**: `{ merchant_id: string, endpoint: string, payload: object }`
    - **Output**: `{ status: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate HMAC, process webhook, update `customers`, `points_transactions`, cache in Redis (`order:{order_id}`), log in `api_logs`, `audit_logs`, track via PostHog (`shopify_sync`).
- **Service**: Auth, Points, Admin Services (gRPC: `/auth.v1/*`, `/points.v1/*`, `/admin.v1/*`).

### 5. Analytics (Phase 1)
- **Goal**: Provide merchants with actionable loyalty insights. Success metric: 80%+ dashboard interaction rate.
- **Reports**: Customer engagement, points redemption, retention metrics, sales attribution via GraphQL Admin API.
- **Basic RFM Analytics**: Recency, Frequency, Monetary segmentation with static thresholds (e.g., Recency <30 days) in `rfm_segment_counts`.
- **PostHog Tracking**: Events (`points_earned`, `redeem_clicked`) for usage insights.
- **Scalability**: Handles 5,000 customers with Redis caching (`analytics:{merchant_id}`), PostgreSQL partitioning.
- **Database Design**:
  - **Table**: `customer_segments` (partitioned by `merchant_id`)
    - `segment_id` (text, PK, NOT NULL): Segment ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `rules` (jsonb, NOT NULL): e.g., `{"recency": ">=4"}`.
    - `name` (text, NOT NULL): e.g., "At-Risk".
  - **Materialized View**: `rfm_segment_counts`
    - `merchant_id`, `segment_name`, `customer_count`: Refreshed daily (`0 1 * * *`).
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `analytics_viewed`.
    - `metadata` (jsonb): e.g., `{"segment_name": "Champions"}`.
  - **Indexes**: `idx_customer_segments_rules` (gin: `rules`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **GET** `/v1/api/analytics` (REST) | gRPC `/analytics.v1/AnalyticsService/GetAnalytics`
    - **Input**: `{ merchant_id: string, locale: string }`
    - **Output**: `{ status: string, metrics: { members: number, points_issued: number, referral_roi: number }, segments: array, error: { code: string, message: string } | null }`
    - **Flow**: Query `customer_segments`, `rfm_segment_counts`, cache in Redis, generate Chart.js data, use i18next, log in `audit_logs`, track via PostHog (`analytics_viewed`).
- **Service**: Analytics Service (gRPC: `/analytics.v1/*`).

### 6. GDPR Compliance (Phase 1)
- **Goal**: Ensure compliance with GDPR/CCPA. Success metric: 100% request completion within 72 hours.
- **Webhooks**: Handle `customers/data_request`, `customers/redact` webhooks with HMAC validation.
- **Data Export/Redaction**: UI in Admin Module to process requests, encrypt `customers.email` (AES-256).
- **Data Import**: Import from Smile.io, LoyaltyLion via CSV, validate unique emails.
- **Database Design**:
  - **Table**: `gdpr_requests`
    - `request_id` (text, PK, NOT NULL): Request ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `customer_id` (text, FK → `customers`): Customer.
    - `request_type` (text, CHECK IN ('data_request', 'redact')): Type.
    - `status` (text, CHECK IN ('pending', 'completed', 'failed')): Status.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `customers`
    - `email` (text, AES-256 ENCRYPTED, NOT NULL): Email.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `gdpr_request_submitted`, `gdpr_processed`.
    - `metadata` (jsonb): e.g., `{"request_type": "redact"}`.
  - **Indexes**: `idx_gdpr_requests_merchant_id_request_type` (btree: `merchant_id`, `request_type`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/gdpr/request` (REST) | gRPC `/admin.v1/AdminService/SubmitGDPRRequest`
    - **Input**: `{ customer_id: string, request_type: string, locale: string }`
    - **Output**: `{ status: string, request_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate `customer_id`, insert into `gdpr_requests`, notify via SendGrid (3 retries), cache in Redis (`gdpr:{customer_id}`), log in `audit_logs`, track via PostHog (`gdpr_request_submitted`).
- **Service**: Admin Service (gRPC: `/admin.v1/*`).

### 7. Security (Phase 1)
- **Goal**: Secure access and data. Success metric: 100% secure authentication, zero data breaches.
- **Authentication**: Shopify OAuth for Merchant Dashboard/Customer Widget, RBAC for Admin Module.
- **Encryption**: AES-256 (pgcrypto) for `customers.email`, `merchants.api_token`, `reward_redemptions.discount_code`.
- **Error Handling**: Returns 400 (invalid input), 429 (rate limits) with transaction rollbacks.
- **Database Design**:
  - **Table**: `merchants`
    - `merchant_id` (text, PK, NOT NULL): Unique ID.
    - `api_token` (text, AES-256 ENCRYPTED, NOT NULL): Shopify token.
    - `staff_roles` (jsonb): RBAC roles.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `auth_failed`, `access_granted`.
    - `metadata` (jsonb): e.g., `{"role": "admin"}`.
  - **Indexes**: `idx_merchants_api_token` (btree: `api_token`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/auth/login` (REST) | gRPC `/auth.v1/AuthService/Login`
    - **Input**: `{ shopify_domain: string, token: string }`
    - **Output**: `{ status: string, access_token: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate OAuth token, generate JWT, cache in Redis (`auth:{merchant_id}`), log in `audit_logs`, track via PostHog (`login_success`).
- **Service**: Auth Service (gRPC: `/auth.v1/*`).

### 8. Testing and Monitoring (Phase 1)
- **Goal**: Ensure reliability and performance. Success metric: 99%+ uptime, <1s alert latency, 80%+ test coverage.
- **Automated Testing**: Jest (unit/integration tests for APIs), Cypress (E2E for Customer Widget, Merchant Dashboard), cargo test (Rust Functions), k6 (load testing for 1,000 orders/hour).
- **Monitoring Metrics**: API latency (<1s), Redis cache hits (>90%), Bull queue delays (<5s), error rates (<1%) via Prometheus/Grafana. Error tracking with Sentry.
- **Database Design**:
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `system_alert`.
    - `metadata` (jsonb): e.g., `{"error_rate": 0.01}`.
  - **Indexes**: `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **GET** `/v1/api/monitoring` (REST) | gRPC `/admin.v1/AdminService/GetMonitoringMetrics`
    - **Input**: `{ service: string, time_range: string }`
    - **Output**: `{ status: string, metrics: { latency: number, error_rate: number }, error: { code: string, message: string } | null }`
    - **Flow**: Query Prometheus, cache in Redis (`metrics:{service}`), log in `audit_logs`, enforce RBAC.
- **Service**: Admin Service (gRPC: `/admin.v1/*`).

### 9. Admin Module (Phase 1)
- **Goal**: Provide tools for platform management. Success metric: 90%+ task completion rate.
- **Features**: Overview (metrics), Merchants (management), Admin Users (RBAC), Logs (API/audit).
- **Automated Email Flows**: Points updates, referral confirmations via SendGrid (3 retries).
- **Database Design**:
  - **Table**: `merchants`
    - `merchant_id` (text, PK, NOT NULL): Unique ID.
    - `shopify_domain` (text, UNIQUE, NOT NULL): Shopify domain.
    - `plan_id` (text, FK → `plans`): Plan.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `merchant_added`.
    - `metadata` (jsonb): e.g., `{"plan_id": "basic"}`.
  - **Indexes**: `idx_merchants_shopify_domain` (btree: `shopify_domain`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **GET** `/v1/api/admin/merchants` (REST) | gRPC `/admin.v1/AdminService/ListMerchants`
    - **Input**: `{ page: number, per_page: number }`
    - **Output**: `{ status: string, merchants: array, total: number, error: { code: string, message: string } | null }`
    - **Flow**: Query `merchants`, enforce RBAC, cache in Redis (`merchants:{page}`), log in `audit_logs`, track via PostHog (`merchants_listed`).
- **Service**: Admin Service (gRPC: `/admin.v1/*`).

## SHOULD HAVE FEATURES
Enhance user experience, scalability, or efficiency for medium to Shopify Plus merchants (Phase 3).

### 1. Points Program (Phase 3)
- **Goal**: Expand earning and redemption options. Success metric: 90%+ adoption of new actions, 85%+ redemption rate.
- **Earning Actions**: Social follows (50 points), goal spend ($100 for 200 points), referrals (50 points).
- **Redemption Options**: Cashback, custom incentives via GraphQL Admin API.
- **Customization**: Fully customizable rewards page, no-code Sticky Bar, advanced branding with i18next (`en`, `es`, `fr`).
- **Scalability**: Supports 50,000+ customers via Redis Streams (`points:{customer_id}`), Bull queues.
- **API Sketch**:
  - **PUT** `/v1/api/points-program` (REST) | gRPC `/admin.v1/AdminService/UpdatePointsProgram`
    - **Input**: `{ merchant_id: string, config: { purchase: number, signup: number, social_follow: number }, branding: { points_currency_singular: string }, locale: string }`
    - **Output**: `{ status: string, error: { code: string, message: string } | null }`
    - **Flow**: Update `program_settings`, cache in Redis (`program:{merchant_id}`), log in `audit_logs`, track via PostHog (`points_config_updated`).
- **Service**: Points Service (gRPC: `/points.v1/*`).

### 2. Referral Program (Phase 3)
- **Goal**: Enhance referral engagement. Success metric: 10%+ interaction rate.
- **Sharing Options**: WhatsApp integration via Twilio.
- **Popups/Nudges**: Exit-intent, time-optimized popups for referrals/email capture.
- **API Sketch**:
  - **PUT** `/v1/api/referrals/config` (REST) | gRPC `/referrals.v1/ReferralService/UpdateReferralConfig`
    - **Input**: `{ merchant_id: string, config: { reward: string, whatsapp_enabled: boolean }, locale: string }`
    - **Output**: `{ status: string, error: { code: string, message: string } | null }`
    - **Flow**: Update `program_settings.config`, notify via Twilio, cache in Redis (`referral_config:{merchant_id}`), log in `audit_logs`, track via PostHog (`referral_config_updated`).
- **Service**: Referrals Service (gRPC: `/referrals.v1/*`).

### 3. VIP Tiers (Phase 3)
- **Goal**: Reward loyal customers with tiered benefits. Success metric: 10%+ tier engagement rate.
- **Thresholds**: Silver ($100+), Gold ($500+), Platinum ($1000+).
- **Perks**: Early product access, birthday gifts, exclusive discounts.
- **Notifications**: Emails for tier upgrades/downgrades via Klaviyo/Postscript (3 retries, `en`, `es`, `fr`).
- **Database Design**:
  - **Table**: `vip_tiers` (partitioned by `merchant_id`)
    - `vip_tier_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `name` (text, NOT NULL): Tier name.
    - `threshold_value` (numeric(65,30), CHECK >= 0): Threshold.
    - `perks` (jsonb): e.g., `{"discount": 10}`.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `tier_assigned`.
  - **Indexes**: `idx_vip_tiers_merchant_id` (btree: `merchant_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/vip-tiers` (REST) | gRPC `/admin.v1/AdminService/CreateVipTier`
    - **Input**: `{ merchant_id: string, name: string, threshold_value: number, perks: object, locale: string }`
    - **Output**: `{ status: string, vip_tier_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Insert into `vip_tiers`, cache in Redis (`tiers:{merchant_id}`), log in `audit_logs`, track via PostHog (`vip_tier_created`).
- **Service**: Points Service (gRPC: `/points.v1/*`).

### 4. On-Site Content (Phase 3)
- **Goal**: Improve engagement with advanced widgets. Success metric: 85%+ adoption.
- **Widgets**: Discount banners, point calculators, checkout extensions via Storefront API.
- **Launchers**: Apple/Google Wallet integration.
- **API Sketch**:
  - **PUT** `/v1/api/content` (REST) | gRPC `/frontend.v1/FrontendService/UpdateContent`
    - **Input**: `{ merchant_id: string, branding: { discount_banner: object, point_calculator: object }, locale: string }`
    - **Output**: `{ status: string, preview: object, error: { code: string, message: string } | null }`
    - **Flow**: Update `program_settings.branding`, cache in Redis (`content:{merchant_id}:{locale}`), log in `audit_logs`, track via PostHog (`content_updated`).
- **Service**: Frontend Service (gRPC: `/frontend.v1/*`).

### 5. Bonus Campaigns (Phase 3)
- **Goal**: Drive urgency with time-sensitive campaigns. Success metric: 20%+ engagement rate.
- **Types**: Time-sensitive promotions, goal spend ($100 for 200 points), points multipliers (2x).
- **Conditions**: Scheduled/automated via no-code dashboard, RFM-based eligibility (`program_settings.rfm_thresholds`).
- **Database Design**:
  - **Table**: `bonus_campaigns` (partitioned by `merchant_id`)
    - `campaign_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `type` (text, CHECK IN ('discount', 'double_points', 'goal_spend')): Type.
    - `multiplier` (numeric(10,2), CHECK >= 1): Multiplier.
    - `start_date`, `end_date` (timestamp(3)): Dates.
    - `conditions` (jsonb): e.g., `{"rfm_segment": "Champions"}`.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `campaign_created`.
  - **Indexes**: `idx_bonus_campaigns_merchant_id_type` (btree: `merchant_id`, `type`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/campaigns` (REST) | gRPC `/points.v1/PointsService/CreateCampaign`
    - **Input**: `{ merchant_id: string, type: string, multiplier: number, dates: { start: string, end: string }, conditions: object, locale: string }`
    - **Output**: `{ status: string, campaign_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Insert into `bonus_campaigns`, notify via Klaviyo/Postscript, cache in Redis (`campaign:{campaign_id}`), log in `audit_logs`, track via PostHog (`campaign_created`).
- **Service**: Points Service (gRPC: `/points.v1/*`).

### 6. Analytics (Phase 3)
- **Goal**: Enhance analytics for campaign optimization. Success metric: 80%+ dashboard interaction rate.
- **Reports**: ROI dashboard, comparisons with similar stores, advanced retention analytics.
- **Insights**: Real-time RFM data for targeting, behavioral segments (e.g., churn risk).
- **API Sketch**:
  - **GET** `/v1/api/analytics/advanced` (REST) | gRPC `/analytics.v1/AnalyticsService/GetAdvancedAnalytics`
    - **Input**: `{ merchant_id: string, metrics: array, locale: string }`
    - **Output**: `{ status: string, metrics: { roi: number, retention_rate: number }, segments: array, error: { code: string, message: string } | null }`
    - **Flow**: Query `customer_segments`, `rfm_segment_counts`, cache in Redis (`analytics:{merchant_id}`), log in `audit_logs`, track via PostHog (`analytics_viewed`).
- **Service**: Analytics Service (gRPC: `/analytics.v1/*`).

### 7. Integrations (Phase 3)
- **Goal**: Broaden compatibility with advanced tools. Success metric: 95%+ integration success rate.
- **Email/SMS**: Klaviyo, Mailchimp, Yotpo Email & SMS, Postscript for personalized campaigns (3 retries, exponential backoff).
- **Others**: Shopify Plus, ReCharge, Gorgias, Shopify Flow for automation.
- **API Sketch**:
  - **POST** `/v1/api/integrations` (REST) | gRPC `/admin.v1/AdminService/ConfigureIntegration`
    - **Input**: `{ merchant_id: string, type: string, settings: object }`
    - **Output**: `{ status: string, integration_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate settings, update `integrations`, cache in Redis (`integration:{merchant_id}`), log in `audit_logs`, track via PostHog (`integration_configured`).
- **Service**: Admin Service (gRPC: `/admin.v1/*`).

### 8. Multilingual Support (Phase 3)
- **Goal**: Support multi-region stores. Success metric: 80%+ adoption of localized widgets.
- **Implementation**: Uses i18next for widget localization (`en`, `es`, `fr`), JSONB fields in `email_templates.body`, `nudges.title`. Persists user choice in `localStorage`, respects `Accept-Language` headers.
- **Database Design**:
  - **Table**: `merchants`
    - `language` (jsonb, CHECK ?| ARRAY['en', 'es', 'fr']): e.g., `{"default": "en", "supported": ["en", "es", "fr"]}`.
  - **Indexes**: `idx_merchants_language` (gin: `language`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **GET** `/v1/api/widget/config` (REST) | gRPC `/frontend.v1/FrontendService/GetWidgetConfig`
    - **Input**: `{ merchant_id: string, locale: string }`
    - **Output**: `{ status: string, language: string, translations: { points_label: string, rewards: object }, error: { code: string, message: string } | null }`
    - **Flow**: Query `merchants.language`, cache in Redis (`config:{merchant_id}:{locale}`), log in `audit_logs`, track via PostHog (`language_selected`).
- **Service**: Frontend Service (gRPC: `/frontend.v1/*`).

### 9. RFM Nudges (Phase 3)
- **Goal**: Encourage engagement with RFM-based nudges. Success metric: 10%+ interaction rate.
- **Features**: Displays nudges (e.g., "Stay Active!" for At-Risk) in widget via Storefront API, logs interactions in `nudge_events`, supports `en`, `es`, `fr` via i18next.
- **Database Design**:
  - **Table**: `nudges`
    - `nudge_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `type` (text, CHECK IN ('at-risk', 'loyal', 'new', 'inactive')): Nudge type.
    - `title` (jsonb, CHECK ?| ARRAY['en', 'es', 'fr']): e.g., `{"en": "Stay Active"}`.
  - **Table**: `nudge_events` (partitioned by `merchant_id`)
    - `event_id` (text, PK, NOT NULL): Interaction ID.
    - `customer_id` (text, FK → `customers`): Customer.
    - `nudge_id` (text, FK → `nudges`): Nudge.
    - `action` (text, CHECK IN ('view', 'click', 'dismiss')): Action.
  - **Indexes**: `idx_nudges_merchant_id` (btree: `merchant_id`), `idx_nudge_events_customer_id` (btree: `customer_id`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **GET** `/v1/api/nudges` (REST) | gRPC `/analytics.v1/AnalyticsService/GetNudges`
    - **Input**: `{ customer_id: string, locale: string }`
    - **Output**: `{ status: string, nudges: [{ nudge_id: string, title: string }], error: { code: string, message: string } | null }`
    - **Flow**: Query `nudges` based on `customers.rfm_score`, cache in Redis (`nudge:{customer_id}`), log in `audit_logs`, track via PostHog (`rfm_nudge_viewed`).
- **Service**: Analytics Service (gRPC: `/analytics.v1/*`).

### 10. Gamification (Phase 3)
- **Goal**: Motivate customers with badges and leaderboards. Success metric: 15%+ engagement rate.
- **Features**: Awards badges for actions (purchases, referrals), displays ranks in Redis sorted sets (`leaderboard:{merchant_id}`). Notifies via Klaviyo/Postscript (3 retries).
- **Database Design**:
  - **Table**: `gamification_achievements` (partitioned by `merchant_id`)
    - `achievement_id` (text, PK, NOT NULL): Unique ID.
    - `customer_id` (text, FK → `customers`, NOT NULL): Customer.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `badge` (jsonb, CHECK ?| ARRAY['en', 'es', 'fr']): e.g., `{"en": "Loyal Customer"}`.
  - **Indexes**: `idx_gamification_achievements_customer_id` (btree: `customer_id`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/gamification/action` (REST) | gRPC `/analytics.v1/AnalyticsService/AwardBadge`
    - **Input**: `{ customer_id: string, action_type: string, locale: string }`
    - **Output**: `{ status: string, achievement_id: string, badge: string, error: { code: string, message: string } | null }`
    - **Flow**: Insert into `gamification_achievements`, notify via Klaviyo, cache in Redis (`badge:{customer_id}`), log in `audit_logs`, track via PostHog (`badge_earned`).
- **Service**: Analytics Service (gRPC: `/analytics.v1/*`).

### 11. Customer Data Import (Phase 3)
- **Goal**: Initialize loyalty programs with imported data. Success metric: 95%+ import success for 50,000+ records under 5 minutes.
- **Features**: Supports CSV imports (email, points, RFM data), encrypts email (AES-256), processes async via Bull. Notifies via Klaviyo/Postscript (3 retries).
- **Database Design**:
  - **Table**: `customers`
    - `customer_id` (text, PK, NOT NULL): Unique ID.
    - `email` (text, AES-256 ENCRYPTED, NOT NULL): Email.
    - `points_balance` (integer, DEFAULT 0): Points.
    - `rfm_score` (jsonb, CHECK (score BETWEEN 1 AND 5)): e.g., `{"recency": 5, "score": 4.1}`.
  - **Indexes**: `idx_customers_email` (btree: `email`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/customers/import` (REST) | gRPC `/admin.v1/AdminService/ImportCustomers`
    - **Input**: `{ merchant_id: string, file: CSV, locale: string }`
    - **Output**: `{ status: string, import_id: string, progress: number, error: { code: string, message: string } | null }`
    - **Flow**: Validate CSV, queue import via Bull, insert into `customers`, `points_transactions`, cache in Redis (`import:{merchant_id}`), log in `audit_logs`, track via PostHog (`customer_import_completed`).
- **Service**: Admin Service (gRPC: `/admin.v1/*`).

### 12. Campaign Discounts (Phase 3)
- **Goal**: Drive sales with time-sensitive discounts. Success metric: 15%+ redemption rate.
- **Features**: Creates campaigns (10% off for 500 points) via GraphQL Admin API, issues codes with Rust/Wasm, notifies via Klaviyo/Postscript (3 retries, `en`, `es`, `fr`).
- **Database Design**:
  - **Table**: `reward_redemptions` (partitioned by `merchant_id`)
    - `redemption_id` (text, PK, NOT NULL): Unique ID.
    - `customer_id` (text, FK → `customers`, NOT NULL): Customer.
    - `campaign_id` (text, FK → `bonus_campaigns`): Campaign.
    - `discount_code` (text, AES-256 ENCRYPTED): Discount code.
  - **Indexes**: `idx_reward_redemptions_campaign_id` (btree: `campaign_id`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/campaigns/redeem` (REST) | gRPC `/points.v1/PointsService/RedeemCampaignDiscount`
    - **Input**: `{ customer_id: string, campaign_id: string, locale: string }`
    - **Output**: `{ status: string, redemption_id: string, discount_code: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate `customers.rfm_score`, deduct points, insert into `reward_redemptions`, cache in Redis (`discount:{redemption_id}`), log in `audit_logs`, track via PostHog (`campaign_discount_redeemed`).
- **Service**: Points Service (gRPC: `/points.v1/*`).

### 13. Advanced Reports Export (Phase 3)
- **Goal**: Export analytics for in-depth analysis. Success metric: 90%+ completion under 5s.
- **Features**: Exports RFM segments (`rfm_segment_counts`), revenue, points transactions, campaigns as CSV (async via Bull). Notifies via Klaviyo/Postscript (3 retries, `en`, `es`, `fr`). Supports 50,000+ customers with PostgreSQL partitioning.
- **Database Design**:
  - **Table**: `export_jobs` (partitioned by `merchant_id`)
    - `export_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `type` (text, CHECK IN ('rfm_segments', 'revenue', 'points_transactions', 'campaign_performance')): Export type.
    - `status` (text, CHECK IN ('pending', 'processing', 'completed', 'failed')): Status.
    - `file_url` (text): Signed URL (expires in 7 days).
  - **Indexes**: `idx_export_jobs_merchant_id_status` (btree: `merchant_id`, `status`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/reports/export` (REST) | gRPC `/analytics.v1/AnalyticsService/ExportReport`
    - **Input**: `{ merchant_id: string, type: string, date_range: { start: string, end: string }, locale: string }`
    - **Output**: `{ status: string, export_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Queue export job in Bull, generate CSV, store in S3, cache in Redis (`export:{merchant_id}`), notify via Klaviyo/Postscript, log in `audit_logs`, track via PostHog (`report_exported`).
- **Service**: Analytics Service (gRPC: `/analytics.v1/*`).

## COULD HAVE FEATURES
Nice-to-have features for polish or advanced use cases, deferred to Phase 6 for global or premium merchants.

### 1. Points Program (Phase 6)
- **Goal**: Enhance customization for premium brands. Success metric: 90%+ adoption of custom branding.
- **Customization**: Advanced branding with custom CSS/fonts via Storefront API, supports Tailwind CSS classes and Google Fonts integration. Allows merchants to upload custom stylesheets (max 1MB) and preview in real-time.
- **Scalability**: Handles 50,000+ customers with Redis caching (`branding:{merchant_id}:{locale}`), processes style updates async via Bull queues.
- **Database Design**:
  - **Table**: `program_settings` (partitioned by `merchant_id`)
    - `merchant_id` (text, PK, FK → `merchants`, NOT NULL): Merchant.
    - `branding` (jsonb): e.g., `{"css": {"primary_color": "#FF5733", "font": "Roboto"}, "custom_css": "string"}`.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `branding_updated`.
    - `metadata` (jsonb): e.g., `{"css_field": "primary_color"}`.
  - **Indexes**: `idx_program_settings_merchant_id` (btree: `merchant_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **PUT** `/v1/api/points/branding` (REST) | gRPC `/points.v1/PointsService/UpdateBranding`
    - **Input**: `{ merchant_id: string, branding: { css: { primary_color: string, font: string }, custom_css: string }, locale: string }`
    - **Output**: `{ status: string, preview_url: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate CSS (sanitize with csso), update `program_settings.branding`, cache in Redis (`branding:{merchant_id}:{locale}`), queue preview render via Bull, log in `audit_logs`, track via PostHog (`branding_updated`).
- **Service**: Points Service (gRPC: `/points.v1/*`).

### 2. VIP Tiers (Phase 6)
- **Goal**: Offer premium tier perks to enhance loyalty. Success metric: 15%+ engagement rate with premium perks.
- **Perks**: Bonus points (e.g., 1.5x multiplier), exclusive rewards (e.g., limited-edition products via Shopify product variants). Notifies via Klaviyo/Postscript (3 retries, `en`, `es`, `fr`).
- **Scalability**: Supports 50,000+ customers with Redis sorted sets (`vip:{merchant_id}:{tier}`) for tier rankings, PostgreSQL partitioning by `merchant_id`.
- **Database Design**:
  - **Table**: `vip_tiers` (partitioned by `merchant_id`)
    - `vip_tier_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `name` (text, NOT NULL): Tier name (e.g., "Diamond").
    - `threshold_value` (numeric(65,30), CHECK >= 0): Threshold (e.g., $2000).
    - `perks` (jsonb): e.g., `{"multiplier": 1.5, "exclusive_product_id": "prod123"}`.
  - **Table**: `vip_assignments` (partitioned by `merchant_id`)
    - `assignment_id` (text, PK, NOT NULL): Unique ID.
    - `customer_id` (text, FK → `customers`, NOT NULL): Customer.
    - `vip_tier_id` (text, FK → `vip_tiers`, NOT NULL): Tier.
    - `assigned_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `vip_perk_assigned`.
    - `metadata` (jsonb): e.g., `{"tier_name": "Diamond"}`.
  - **Indexes**: `idx_vip_tiers_merchant_id` (btree: `merchant_id`), `idx_vip_assignments_customer_id` (btree: `customer_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/vip-tiers/assign` (REST) | gRPC `/points.v1/PointsService/AssignVipTier`
    - **Input**: `{ customer_id: string, vip_tier_id: string, locale: string }`
    - **Output**: `{ status: string, assignment_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate `customer_id`, check `threshold_value`, insert into `vip_assignments`, notify via Klaviyo/Postscript, cache in Redis (`vip:{customer_id}`), log in `audit_logs`, track via PostHog (`vip_perk_assigned`).
- **Service**: Points Service (gRPC: `/points.v1/*`).

### 3. On-Site Content (Phase 6)
- **Goal**: Add advanced branding and in-store focus. Success metric: 85%+ adoption of new widgets.
- **Widgets**: Rewards Sticky Bar (configurable via no-code dashboard), omnichannel Shopify POS integration for in-store point earning/redemption. Supports `en`, `es`, `fr` via i18next.
- **Scalability**: Renders <1s via Redis caching (`content:{merchant_id}:{locale}`), handles 1,000 orders/hour with Bull queues for POS sync.
- **Database Design**:
  - **Table**: `program_settings` (partitioned by `merchant_id`)
    - `merchant_id` (text, PK, FK → `merchants`, NOT NULL): Merchant.
    - `branding` (jsonb): e.g., `{"sticky_bar": {"en": {...}, "es": {...}}, "pos_config": {...}}`.
  - **Table**: `pos_transactions` (partitioned by `merchant_id`)
    - `transaction_id` (text, PK, NOT NULL): Unique ID.
    - `customer_id` (text, FK → `customers`, NOT NULL): Customer.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `points` (integer, CHECK >= 0): Points earned/redeemed.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `pos_content_updated`.
    - `metadata` (jsonb): e.g., `{"widget_type": "sticky_bar"}`.
  - **Indexes**: `idx_program_settings_merchant_id` (btree: `merchant_id`), `idx_pos_transactions_customer_id` (btree: `customer_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **PUT** `/v1/api/content/pos` (REST) | gRPC `/frontend.v1/FrontendService/UpdatePosContent`
    - **Input**: `{ merchant_id: string, branding: { sticky_bar: object, pos_config: object }, locale: string }`
    - **Output**: `{ status: string, preview: object, error: { code: string, message: string } | null }`
    - **Flow**: Validate inputs, update `program_settings.branding`, cache in Redis (`content:{merchant_id}:{locale}`), queue POS sync via Bull, log in `audit_logs`, track via PostHog (`pos_content_updated`).
- **Service**: Frontend Service (gRPC: `/frontend.v1/*`).

### 4. Bonus Campaigns (Phase 6)
- **Goal**: Add gamified campaigns to drive engagement. Success metric: 20%+ engagement rate.
- **Types**: Social media engagement (e.g., 50 points for Instagram share), limited-time bonuses (e.g., 100 points for login), points events (e.g., holiday double points). Configurable via no-code dashboard, RFM-based eligibility.
- **Scalability**: Supports 50,000+ customers with Redis Streams (`campaign:{campaign_id}`), Bull queues for async notifications.
- **Database Design**:
  - **Table**: `bonus_campaigns` (partitioned by `merchant_id`)
    - `campaign_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `type` (text, CHECK IN ('social_engagement', 'limited_bonus', 'points_event')): Campaign type.
    - `multiplier` (numeric(10,2), CHECK >= 1): Multiplier.
    - `start_date`, `end_date` (timestamp(3)): Dates.
    - `conditions` (jsonb): e.g., `{"rfm_segment": "Champions", "action": "instagram_share"}`.
  - **Table**: `campaign_participations` (partitioned by `merchant_id`)
    - `participation_id` (text, PK, NOT NULL): Unique ID.
    - `customer_id` (text, FK → `customers`, NOT NULL): Customer.
    - `campaign_id` (text, FK → `bonus_campaigns`, NOT NULL): Campaign.
    - `action` (text, NOT NULL): e.g., `instagram_share`.
    - `points` (integer, CHECK >= 0): Points awarded.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `campaign_participated`.
    - `metadata` (jsonb): e.g., `{"campaign_type": "social_engagement"}`.
  - **Indexes**: `idx_bonus_campaigns_merchant_id_type` (btree: `merchant_id`, `type`), `idx_campaign_participations_customer_id` (btree: `customer_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/campaigns/participate` (REST) | gRPC `/points.v1/PointsService/ParticipateCampaign`
    - **Input**: `{ customer_id: string, campaign_id: string, action: string, locale: string }`
    - **Output**: `{ status: string, participation_id: string, points: number, error: { code: string, message: string } | null }`
    - **Flow**: Validate `campaign_id`, check `conditions`, insert into `campaign_participations`, award points, notify via Klaviyo/Postscript, cache in Redis (`campaign:{campaign_id}`), log in `audit_logs`, track via PostHog (`campaign_participated`).
- **Service**: Points Service (gRPC: `/points.v1/*`).

### 5. Analytics (Phase 6)
- **Goal**: Provide comprehensive analytics for Plus merchants. Success metric: 80%+ interaction rate with advanced reports.
- **Reports**: 25+ advanced reports (e.g., customer lifetime value, churn prediction, campaign ROI, cross-store comparisons) via GraphQL Admin API and Chart.js visualizations.
- **Developer Toolkit**: Shopify metafields for custom analytics (e.g., `loyalty.custom_metrics`), accessible via REST/gRPC APIs.
- **Scalability**: Handles 50,000+ customers with Redis caching (`analytics:{merchant_id}`), PostgreSQL partitioning, and async report generation via Bull.
- **Database Design**:
  - **Table**: `analytics_reports` (partitioned by `merchant_id`)
    - `report_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `type` (text, CHECK IN ('clv', 'churn', 'campaign_roi', 'cross_store')): Report type.
    - `data` (jsonb): e.g., `{"clv": {"avg": 500, "segment": "Champions"}}`.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `metafields` (partitioned by `merchant_id`)
    - `metafield_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `namespace` (text, NOT NULL): e.g., `loyalty`.
    - `key` (text, NOT NULL): e.g., `custom_metrics`.
    - `value` (jsonb): e.g., `{"metric1": 100}`.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `report_generated`.
    - `metadata` (jsonb): e.g., `{"report_type": "clv"}`.
  - **Indexes**: `idx_analytics_reports_merchant_id_type` (btree: `merchant_id`, `type`), `idx_metafields_namespace_key` (btree: `namespace`, `key`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **GET** `/v1/api/analytics/custom` (REST) | gRPC `/analytics.v1/AnalyticsService/GetCustomAnalytics`
    - **Input**: `{ merchant_id: string, report_type: string, metafields: [{ namespace: string, key: string }], date_range: { start: string, end: string }, locale: string }`
    - **Output**: `{ status: string, report: { id: string, data: object }, error: { code: string, message: string } | null }`
    - **Flow**: Query `analytics_reports`, `metafields`, cache in Redis (`report:{merchant_id}:{report_type}`), generate Chart.js data, log in `audit_logs`, track via PostHog (`custom_analytics_viewed`).
- **Service**: Analytics Service (gRPC: `/analytics.v1/*`).

### 6. Integrations (Phase 6)
- **Goal**: Expand market reach to non-Shopify platforms. Success metric: 95%+ integration success rate.
- **Platforms**: BigCommerce, Wix, Adobe Commerce, Salla, Meta, Okendo, Skio. Supports webhooks and OAuth for third-party sync.
- **Developer Toolkit**: Shopify metafields for custom data access (e.g., `loyalty.integration_data`), REST/gRPC APIs for third-party platforms.
- **Scalability**: Handles 1,000 orders/hour with Bull queues for async sync, Redis caching (`integration:{merchant_id}`).
- **Database Design**:
  - **Table**: `integrations` (partitioned by `merchant_id`)
    - `integration_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `platform` (text, CHECK IN ('bigcommerce', 'wix', 'adobe_commerce', 'salla', 'meta', 'okendo', 'skio')): Platform.
    - `settings` (jsonb): e.g., `{"api_key": "AES-256 encrypted"}`.
    - `status` (text, CHECK IN ('active', 'inactive', 'failed')): Status.
  - **Table**: `metafields` (partitioned by `merchant_id`)
    - `metafield_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `namespace` (text, NOT NULL): e.g., `loyalty`.
    - `key` (text, NOT NULL): e.g., `integration_data`.
    - `value` (jsonb): e.g., `{"platform": "bigcommerce"}`.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `integration_sync`.
    - `metadata` (jsonb): e.g., `{"platform": "bigcommerce"}`.
  - **Indexes**: `idx_integrations_merchant_id_platform` (btree: `merchant_id`, `platform`), `idx_metafields_namespace_key` (btree: `namespace`, `key`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **POST** `/v1/api/integrations/sync` (REST) | gRPC `/admin.v1/AdminService/SyncIntegration`
    - **Input**: `{ merchant_id: string, platform: string, settings: object, metafields: [{ namespace: string, key: string, value: object }] }`
    - **Output**: `{ status: string, integration_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Validate settings, update `integrations`, `metafields`, queue sync via Bull, cache in Redis (`integration:{merchant_id}`), log in `audit_logs`, track via PostHog (`integration_sync`).
- **Service**: Admin Service (gRPC: `/admin.v1/*`).

### 7. Other (Phase 6)
- **Goal**: Enhance global engagement. Success metric: 80%+ adoption of advanced features.
- **Gamification**: Leaderboards with Redis sorted sets (`leaderboard:{merchant_id}`) for top customers, badges for milestones (e.g., 10 purchases). Notifies via Klaviyo/Postscript.
- **Multi-Currency Discounts**: Supports global pricing (e.g., USD, EUR) via GraphQL Admin API and Rust/Wasm for dynamic discount codes.
- **Multilingual Widget**: Full support for 250+ languages with i18next, JSONB fields for translations, respects `Accept-Language` headers.
- **Targeted Communication**: Event-triggered push notifications (e.g., points expiring) via Klaviyo/Postscript (3 retries).
- **Scalability**: Handles 50,000+ customers with Redis Streams (`leaderboard:{merchant_id}`, `notification:{customer_id}`), Bull queues for async processing.
- **Database Design**:
  - **Table**: `leaderboards` (partitioned by `merchant_id`)
    - `leaderboard_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `customer_id` (text, FK → `customers`, NOT NULL): Customer.
    - `score` (integer, CHECK >= 0): Points-based score.
    - `updated_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `email_templates` (partitioned by `merchant_id`)
    - `template_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `type` (text, CHECK IN ('points_expiry', 'leaderboard_update', 'badge_earned')): Template type.
    - `body` (jsonb): e.g., `{"en": "Your points are expiring!", "es": "¡Tus puntos están expirando!"}`.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `leaderboard_updated`, `notification_sent`.
    - `metadata` (jsonb): e.g., `{"template_type": "points_expiry"}`.
  - **Indexes**: `idx_leaderboards_merchant_id_score` (btree: `merchant_id`, `score`), `idx_email_templates_merchant_id_type` (btree: `merchant_id`, `type`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days.
- **API Sketch**:
  - **GET** `/v1/api/leaderboards` (REST) | gRPC `/points.v1/PointsService/GetLeaderboard`
    - **Input**: `{ merchant_id: string, limit: number, locale: string }`
    - **Output**: `{ status: string, leaderboard: [{ customer_id: string, score: number, rank: number }], error: { code: string, message: string } | null }`
    - **Flow**: Query Redis sorted set (`leaderboard:{merchant_id}`), fallback to `leaderboards`, cache in Redis, log in `audit_logs`, track via PostHog (`leaderboard_viewed`).
  - **POST** `/v1/api/notifications/push` (REST) | gRPC `/referrals.v1/ReferralService/SendPushNotification`
    - **Input**: `{ merchant_id: string, customer_id: string, type: string, locale: string }`
    - **Output**: `{ status: string, notification_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Query `email_templates`, send notification via Klaviyo/Postscript, cache in Redis (`notification:{customer_id}`), log in `audit_logs`, track via PostHog (`notification_sent`).
- **Service**: Points, Referrals, Frontend Services (gRPC: `/points.v1/*`, `/referrals.v1/*`, `/frontend.v1/*`).

## Notes
- **Alignment**: Features map to user stories (US-CW1–CW11, US-MD1–MD12, US-AM1–AM9, US-BI1–BI3) and wireframes (Customer Widget, Merchant Dashboard, Admin Module).
- **Roadmap**: Phase 1 (Must Have) targets MVP for small merchants, Phase 3 (Should Have) enhances for Shopify Plus, and Phase 6 (Could Have) supports global expansion.
- **Scalability**: Supports 50,000+ customers, 1,000 orders/hour via Redis caching, Bull queues, PostgreSQL partitioning, and Docker-based microservices.
- **Security**: Shopify OAuth, RBAC, AES-256 encryption, GDPR/CCPA compliance with 72-hour request processing.
- **Monitoring**: Prometheus/Grafana for metrics (API latency, Redis hits), Sentry for error tracking.
- **Testing**: Jest (80%+ coverage), Cypress (E2E), k6 (load testing), cargo test (Rust Functions).
```