# LoyalNest App Features - Should Have

## Overview
This document outlines **Should Have** features for the LoyalNest Shopify app, targeting medium to Shopify Plus merchants (5,000–50,000 customers) in Phase 3. It enhances the MVP from `features_1_must_have.md`, aligning with user stories (US-CW1–CW15, US-MD1–MD18, US-AM1–AM13, US-BI1–BI5), wireframes, and LoyalNest App Feature Analysis. The app uses microservices (`rfm-service`, `users-service`, `roles-service`, `Points`, `Referrals`, `Analytics`, `AdminCore`, `AdminFeatures`, `Frontend`) with NestJS/TypeORM, gRPC, Rust/Wasm Shopify Functions, PostgreSQL partitioning, Redis Streams, Bull queues, Kafka, and monitoring via Prometheus/Grafana, Sentry, Loki, and PostHog. It supports 10,000 orders/hour, Shopify Plus API limits (40 req/s), GDPR/CCPA compliance (AES-256 encryption, 90-day Backblaze B2 backups), multilingual support (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)), and WCAG 2.1 compliance (Lighthouse CI: 90+). The implementation aligns with a 39.5-week TVP timeline (ending February 17, 2026) and $97,012.50 budget, using Docker Compose (`artifact_id: 16fc7997-8a42-433e-a159-d8dad32a231f`) and SQL schemas (`artifact_id: 6f83061c-0a09-404f-8ca1-81a7aa15c25e`).

## SHOULD HAVE FEATURES

### 1. Points Program (Phase 3)
- **Goal**: Expand earning and redemption options. Success metric: 90%+ adoption of new actions, 85%+ redemption rate, 15%+ multi-store sync adoption (Phase 5), 90%+ multi-currency adoption.
- **Earning Actions**: Social follows (50 points), goal spend ($100 for 200 points), referrals (50 points), merchant referrals (Phase 5, e.g., 500 points).
- **Dynamic Point Multipliers**: Real-time multipliers (e.g., 2x for first purchase within 24 hours, 1.5x for Champions via `rfm-service` `/rfm.v1/RFMService/GetSegmentCounts`) calculated using Rust/Wasm Shopify Functions, logged in `points_transactions`.
- **Redemption Options**: Cashback, custom incentives (e.g., exclusive products) via GraphQL Admin API (40 req/s for Plus). Supports multi-store point sharing (Phase 5, US-CW6).
- **Multi-Currency Support**: Supports multi-currency discounts (e.g., USD, EUR, CAD) via Shopify’s multi-currency API, applied at checkout using Shopify Checkout UI Extensions (Rust/Wasm). Stores currency in `points_transactions.currency`.
- **Customization**: Fully customizable rewards page, no-code Sticky Bar (US-CW14), post-purchase widget (US-CW15), advanced branding with Polaris-compliant UI, i18next (`en`, `es`, `de`, `ja`, `fr`, `pt`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)), and Tailwind CSS.
- **Scalability**: Supports 50,000+ customers via Redis Streams (`points:{customer_id}`, `multiplier:{customer_id}`, `currency:{customer_id}`), Bull queues, PostgreSQL partitioning, circuit breakers, and Chaos Mesh testing for Black Friday surges (10,000 orders/hour).
- **Database Design**:
  - **Table**: `users` (users-service)
    - `id` (text, PK, NOT NULL): Unique ID.
    - `email` (text, AES-256 ENCRYPTED, NOT NULL): Customer email.
    - `rfm_score` (jsonb, AES-256 ENCRYPTED): e.g., `{"recency": 5, "frequency": 3, "monetary": 4, "score": 4.2}`.
    - `churn_score` (numeric(10,2), CHECK BETWEEN 0 AND 1): Churn probability.
    - `lifecycle_stage` (text, CHECK IN ('new_lead', 'repeat_buyer', 'churned', 'vip')): Lifecycle stage.
  - **Table**: `program_settings`
    - `merchant_id` (text, PK, FK → `merchants`, NOT NULL): Merchant.
    - `dynamic_multipliers` (jsonb): e.g., `{"first_purchase_24h": 2.0, "rfm_champion": 1.5}`.
    - `multi_store_config` (jsonb, Phase 5): e.g., `{"shared_stores": ["store1.myshopify.com", "store2.myshopify.com"]}`.
    - `multi_currency_config` (jsonb): e.g., `{"supported_currencies": ["USD", "EUR", "CAD"]}`.
  - **Table**: `points_transactions` (partitioned by `merchant_id`)
    - `transaction_id` (text, PK, NOT NULL): Unique ID.
    - `customer_id` (text, FK → `users`, NOT NULL): Customer.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `type` (text, CHECK IN ('earn', 'redeem', 'expire', 'adjust', 'import', 'referral', 'campaign')): Action type.
    - `points` (integer, CHECK >= 0): Points awarded.
    - `currency` (text): e.g., `USD`, `EUR`, `CAD`.
    - `source` (text): Source (e.g., "order", "rfm_reward").
    - `order_id` (text): Shopify order ID.
    - `expiry_date` (timestamp(3)): Expiry timestamp.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `multiplier_applied`, `multi_store_sync`, `multi_currency_applied`.
    - `actor_id` (text, FK → `admin_users` | NULL): Admin user.
    - `metadata` (jsonb): e.g., `{"multiplier": 2.0, "action": "first_purchase", "currency": "USD"}`.
  - **Indexes**: `idx_users_email` (btree: `email`), `idx_program_settings_merchant_id` (btree: `merchant_id`), `idx_points_transactions_customer_id` (btree: `customer_id`, `created_at`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days in Backblaze B2, encrypted with AES-256.
- **API Sketch**:
  - **PUT** `/v1/api/points-program` (REST) | gRPC `/admin.v1/AdminService/UpdatePointsProgram`
    - **Input**: `{ merchant_id: string, config: { purchase: number, signup: number, social_follow: number, referral: number }, dynamic_multipliers: object, branding: { points_currency_singular: string }, multi_store_config: object, multi_currency_config: { supported_currencies: array }, locale: string }`
    - **Output**: `{ status: string, error: { code: string, message: string } | null }`
    - **Flow**: Update `program_settings`, cache in Redis Streams (`program:{merchant_id}`, `multiplier:{merchant_id}`, `currency:{merchant_id}`), log in `audit_logs`, track via PostHog (`points_config_updated`, 80%+ usage, `multi_currency_configured`, 90%+ adoption).
  - **POST** `/v1/api/points/calculate` (REST) | gRPC `/points.v1/PointsService/CalculateDynamicPoints`
    - **Input**: `{ customer_id: string, action_type: string, order_id: string, currency: string, locale: string }`
    - **Output**: `{ status: string, points: number, multiplier: number, currency: string, error: { code: string, message: string } | null }`
    - **Flow**: Fetch RFM segment via `/rfm.v1/RFMService/GetSegmentCounts`, calculate multiplier via Rust/Wasm, validate currency via Shopify’s multi-currency API, cache in Redis Streams (`multiplier:{customer_id}`, `currency:{customer_id}`), log in `audit_logs`, track via PostHog (`multiplier_applied`, 90%+ adoption, `multi_currency_applied`, 90%+ adoption).
  - **POST** `/v1/api/points/sync` (Phase 5) | gRPC `/points.v1/PointsService/SyncPoints`
    - **Input**: `{ customer_id: string, store_ids: array, locale: string }`
    - **Output**: `{ status: string, points_balance: number, error: { code: string, message: string } | null }`
    - **Flow**: Sync `points_balance` across stores, update `points_transactions`, cache in Redis Streams (`points:{customer_id}`), log in `audit_logs`, track via PostHog (`multi_store_sync`, 15%+ adoption).
- **GraphQL Query Examples**:
  - **Query: Fetch Multi-Currency Order Details**
    - **Purpose**: Retrieves order details with currency information to apply multi-currency discounts, used in `/v1/api/points/calculate`.
    - **Query**:
      ```graphql
      query GetOrderDetails($id: ID!) {
        order(id: $id) {
          id
          totalPriceSet {
            shopMoney {
              amount
              currencyCode
            }
            presentmentMoney {
              amount
              currencyCode
            }
          }
          customer {
            id
          }
          createdAt
        }
      }
      ```
    - **Variables**: `{ "id": "gid://shopify/Order/123456789" }`
    - **Use Case**: Merchant Dashboard validates order currency for points calculation, storing `currency` in `points_transactions` for multi-currency support.
  - **Query: Create Cashback Reward**
    - **Purpose**: Creates a cashback discount for point redemption, used in `/v1/api/rewards/redeem`.
    - **Query**:
      ```graphql
      mutation CreateDiscount($input: DiscountCodeBasicInput!) {
        discountCodeBasicCreate(basicCodeDiscount: $input) {
          codeDiscountNode {
            id
            codeDiscount {
              ... on DiscountCodeBasic {
                title
                codes(first: 1) {
                  nodes {
                    code
                  }
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
      ```
    - **Variables**: 
      ```json
      {
        "input": {
          "title": "LoyalNest $10 Cashback",
          "code": "LN10CASH",
          "customerGets": {
            "value": {
              "discountAmount": {
                "amount": 10.0,
                "currencyCode": "USD"
              }
            }
          },
          "appliesOncePerCustomer": true
        }
      }
      ```
    - **Use Case**: Merchant Dashboard issues cashback rewards via Shopify Checkout UI Extensions, stored in `reward_redemptions` (AES-256 encrypted).
- **Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).

### 2. Referral Program (Phase 3)
- **Goal**: Enhance referral engagement. Success metric: 10%+ referral conversion rate (SMS), 5%+ (email), 85%+ dashboard interaction rate.
- **Multi-Tier Referrals**: Support tiered rewards (e.g., 100 points for 1st referral, 200 for 2nd) via `referrals.tier_level`, configurable in Merchant Dashboard.
- **Custom Referral Incentives**: Custom rewards (e.g., exclusive products) via GraphQL Admin API, integrated with Klaviyo/Postscript for notifications (3 retries, `en`, `es`, `fr`, `ar`(RTL)).
- **Advanced Analytics**: Track multi-tier referral performance, A/B test incentives via `referral_events.variants` (JSONB), visualized in Polaris `DataTable` and Chart.js (CTR, conversion rate).
- **Scalability**: Supports 50,000+ customers with Redis Streams (`referral:{referral_code}`, `multi_tier:{referral_code}`), Bull queues, PostgreSQL partitioning, and Chaos Mesh testing.
- **Database Design**:
  - **Table**: `referral_links` (partitioned by `merchant_id`)
    - `referral_link_id` (text, PK, NOT NULL): Unique ID.
    - `advocate_customer_id` (text, FK → `users`, NOT NULL): Advocate.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `referral_code` (text, UNIQUE, NOT NULL): Unique code.
    - `click_count` (integer, DEFAULT 0): Number of clicks.
    - `merchant_referral_id` (text, FK → `merchant_referrals` | NULL): Merchant referral (Phase 5).
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `referrals` (partitioned by `merchant_id`)
    - `referral_id` (text, PK, NOT NULL): Unique ID.
    - `advocate_customer_id` (text, FK → `users`, NOT NULL): Advocate.
    - `friend_customer_id` (text, FK → `users`, NOT NULL): Friend.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `reward_id` (text, FK → `rewards`): Reward.
    - `tier_level` (integer, DEFAULT 1): Referral tier.
    - `status` (text, CHECK IN ('pending', 'completed', 'expired')): Status.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `referral_events` (partitioned by `merchant_id`)
    - `event_id` (text, PK, NOT NULL): Event ID.
    - `referral_link_id` (text, FK → `referral_links`, NOT NULL): Link.
    - `action` (text, CHECK IN ('click', 'conversion', 'view')): Action type.
    - `variants` (jsonb): e.g., `{"incentive": "exclusive_product"}`.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `multi_tier_referral_created`, `referral_incentive_updated`.
    - `actor_id` (text, FK → `admin_users` | NULL): Admin user.
    - `metadata` (jsonb): e.g., `{"tier_level": 2, "incentive": "exclusive_product"}`.
  - **Indexes**: `idx_referral_links_referral_code` (btree: `referral_code`), `idx_referrals_merchant_id` (btree: `merchant_id`), `idx_referral_events_referral_link_id` (btree: `referral_link_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days in Backblaze B2, encrypted with AES-256.
- **API Sketch**:
  - **PUT** `/v1/api/referrals/config` (REST) | gRPC `/referrals.v1/ReferralService/UpdateReferralConfig`
    - **Input**: `{ merchant_id: string, tiers: array, incentives: object, locale: string }`
    - **Output**: `{ status: string, error: { code: string, message: string } | null }`
    - **Flow**: Update `program_settings.referral_config`, cache in Redis Streams (`referral_config:{merchant_id}`), log in `audit_logs`, track via PostHog (`referral_config_updated`, 85%+ usage).
  - **POST** `/v1/api/referrals/tier` (REST) | gRPC `/referrals.v1/ReferralService/AssignTierReward`
    - **Input**: `{ referral_id: string, tier_level: number, locale: string }`
    - **Output**: `{ status: string, reward_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Update `referrals.tier_level`, award points via `/points.v1/PointsService/EarnPoints`, notify via Klaviyo/Postscript, cache in Redis Streams (`multi_tier:{referral_code}`), log in `audit_logs`, track via PostHog (`multi_tier_referral_created`, 10%+ conversion).
- **GraphQL Query Examples**:
  - **Query: Create Multi-Tier Referral Reward**
    - **Purpose**: Creates a custom reward for a multi-tier referral, used in `/v1/api/referrals/tier`.
    - **Query**:
      ```graphql
      mutation CreateDiscount($input: DiscountCodeBasicInput!) {
        discountCodeBasicCreate(basicCodeDiscount: $input) {
          codeDiscountNode {
            id
            codeDiscount {
              ... on DiscountCodeBasic {
                title
                codes(first: 1) {
                  nodes {
                    code
                  }
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
      ```
    - **Variables**: 
      ```json
      {
        "input": {
          "title": "Referral Tier 2 Reward",
          "code": "REF2TIER",
          "customerGets": {
            "value": {
              "percentage": 0.15
            }
          },
          "appliesOncePerCustomer": true
        }
      }
      ```
    - **Use Case**: Merchant Dashboard issues tiered referral rewards (e.g., 15% off for 2nd referral), stored in `referrals.reward_id`.
  - **Query: Track Referral Analytics**
    - **Purpose**: Retrieves referral event data for advanced analytics, used in `/v1/api/referrals/analytics`.
    - **Query**:
      ```graphql
      query GetReferralAnalytics($merchantId: String!) {
        orders(first: 100, query: $merchantId) {
          edges {
            node {
              id
              customer {
                id
                metafield(namespace: "loyalnest", key: "referral_code") {
                  value
                }
              }
            }
          }
        }
      }
      ```
    - **Variables**: `{ "merchantId": "merchant_123" }`
    - **Use Case**: Merchant Dashboard tracks referral conversions, feeding into `referral_events` for Chart.js visualization.
- **Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).

### 3. On-Site Content (Phase 3)
- **Goal**: Improve engagement with advanced widgets. Success metric: 90%+ widget interaction rate, 15%+ nudge conversion rate, Lighthouse CI score 95+.
- **Advanced Widgets**: No-code Sticky Bar (US-CW14), post-purchase widget (US-CW15), personalized banners based on RFM segments (`rfm-service`, `nudges`), and Theme App Extensions (Phase 5). Supports A/B testing via `program_settings.ab_tests` (JSONB).
- **Dynamic Nudges**: Personalized nudges for RFM segments (e.g., “VIP Exclusive Offer” for Champions) via `rfm-service`, delivered through Klaviyo/Postscript/AWS SES (3 retries, `en`, `es`, `fr`, `ar`(RTL)).
- **Accessibility**: Enhanced ARIA labels, keyboard navigation, screen reader support, RTL for `ar`, `he`, WCAG 2.1 compliance, Lighthouse CI scores (95+ for ARIA, LCP, FID, CLS).
- **Scalability**: Renders <1s via Redis Streams (`content:{merchant_id}:{locale}`, `rfm:nudge:{customer_id}`), supports 10,000 orders/hour with circuit breakers and Chaos Mesh testing.
- **Database Design**:
  - **Table**: `program_settings`
    - `merchant_id` (text, PK, FK → `merchants`, NOT NULL): Merchant.
    - `branding` (jsonb, CHECK ?| ARRAY['en', `es`, `de`, `ja`, `fr`, `pt`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`]): e.g., `{"sticky_bar": {"en": {...}, "es": {...}, "ar": {...}}, "post_purchase": {...}}`.
    - `ab_tests` (jsonb): e.g., `{"sticky_bar": {"variant_a": {"color": "blue"}, "variant_b": {"color": "green"}}}`.
  - **Table**: `nudges` (rfm-service, partitioned by `merchant_id`)
    - `nudge_id`, `merchant_id`, `type` (CHECK IN ('at-risk', 'loyal', 'new', 'inactive', 'tier_dropped', 'vip')), `title` (jsonb), `description` (jsonb), `is_enabled`, `variants` (jsonb): Nudge configurations.
  - **Table**: `nudge_events` (rfm-service, partitioned by `merchant_id`)
    - `event_id`, `customer_id`, `nudge_id`, `action` (CHECK IN ('view', 'click', 'dismiss')), `created_at`: Nudge interactions.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `content_updated`, `ab_test_updated`, `rfm_nudge_viewed`.
    - `actor_id` (text, FK → `admin_users` | NULL): Admin user.
    - `metadata` (jsonb): e.g., `{"type": "sticky_bar", "variant": "blue"}`.
  - **Indexes**: `idx_program_settings_merchant_id` (btree: `merchant_id`), `idx_nudges_merchant_id` (btree: `merchant_id`), `idx_nudge_events_customer_id` (btree: `customer_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days in Backblaze B2, encrypted with AES-256.
- **API Sketch**:
  - **PUT** `/v1/api/content/advanced` (REST) | gRPC `/frontend.v1/FrontendService/UpdateAdvancedContent`
    - **Input**: `{ merchant_id: string, branding: { sticky_bar: object, post_purchase: object, banners: object }, ab_tests: object, locale: string }`
    - **Output**: `{ status: string, preview: object, error: { code: string, message: string } | null }`
    - **Flow**: Update `program_settings.branding`, `program_settings.ab_tests`, cache in Redis Streams (`content:{merchant_id}:{locale}`, `ab_test:{merchant_id}`), log in `audit_logs`, track via PostHog (`content_updated`, `ab_test_updated`, 15%+ conversion).
  - **POST** `/api/v1/rfm/nudges/personalized` (REST) | gRPC `/rfm.v1/RFMService/CreatePersonalizedNudge`
    - **Input**: `{ merchant_id: string, customer_id: string, segment_id: string, locale: string }`
    - **Output**: `{ status: string, nudge_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Create nudge in `nudges`, cache in Redis Streams (`rfm:nudge:{customer_id}`), notify via Klaviyo/Postscript, log in `audit_logs`, track via PostHog (`rfm_nudge_viewed`, 15%+ conversion).
- **GraphQL Query Examples**:
  - **Query: Fetch Customer Segment for Personalized Nudge**
    - **Purpose**: Retrieves RFM segment for dynamic nudge personalization, used in `/api/v1/rfm/nudges/personalized`.
    - **Query**:
      ```graphql
      query GetCustomerSegment($id: ID!) {
        customer(id: $id) {
          id
          metafield(namespace: "loyalnest", key: "rfm_score") {
            value
          }
        }
      }
      ```
    - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`
    - **Use Case**: Customer Widget displays personalized nudges (e.g., “VIP Exclusive Offer”) based on `rfm_score` from `users`.
- **Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).

### 4. Integrations (Phase 3)
- **Goal**: Expand third-party integrations. Success metric: 95%+ integration adoption, 99%+ sync accuracy, 90%+ notification delivery rate.
- **Advanced Integrations**: Gorgias (support tickets trigger points), Zapier (custom workflows), Shopify Flow (e.g., “High AOV → VIP Segment”), Klaviyo/Postscript for advanced flows (e.g., tier change notifications).
- **Custom Webhooks**: Allow merchants to define custom webhook endpoints via Admin Module, stored in `custom_webhooks`, triggered via Bull queues.
- **Scalability**: Supports 50,000+ customers with Redis Streams (`integration:{merchant_id}`, `webhook:{merchant_id}`), PostgreSQL partitioning, and Chaos Mesh testing.
- **Database Design**:
  - **Table**: `custom_webhooks` (partitioned by `merchant_id`)
    - `webhook_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `endpoint` (text, NOT NULL): Custom endpoint URL.
    - `event_type` (text, NOT NULL): e.g., `points_earned`, `referral_completed`.
    - `status` (text, CHECK IN ('active', 'inactive')): Status.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `custom_webhook_triggered`, `integration_added`.
    - `actor_id` (text, FK → `admin_users` | NULL): Admin user.
    - `metadata` (jsonb): e.g., `{"integration": "gorgias", "event_type": "ticket_created"}`.
  - **Indexes**: `idx_custom_webhooks_merchant_id` (btree: `merchant_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days in Backblaze B2, encrypted with AES-256.
- **API Sketch**:
  - **POST** `/v1/api/webhooks/custom` (REST) | gRPC `/admin.v1/AdminService/CreateCustomWebhook`
    - **Input**: `{ merchant_id: string, endpoint: string, event_type: string, locale: string }`
    - **Output**: `{ status: string, webhook_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Insert into `custom_webhooks`, validate endpoint, cache in Redis Streams (`webhook:{merchant_id}`), log in `audit_logs`, track via PostHog (`custom_webhook_created`, 95%+ adoption).
- **GraphQL Query Examples**:
  - **Query: Create Custom Webhook**
    - **Purpose**: Registers a custom webhook endpoint for Shopify events, used in `/v1/api/webhooks/custom`.
    - **Query**:
      ```graphql
      mutation CreateWebhook($input: WebhookSubscriptionInput!) {
        webhookSubscriptionCreate(input: $input) {
          webhookSubscription {
            id
            topic
            endpoint {
              ... on WebhookHttpEndpoint {
                callbackUrl
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
      ```
    - **Variables**: 
      ```json
      {
        "input": {
          "topic": "ORDERS_CREATE",
          "endpoint": {
            "callbackUrl": "https://custom-endpoint.com/webhook"
          }
        }
      }
      ```
    - **Use Case**: Admin Module configures custom webhooks for events like `points_earned`, stored in `custom_webhooks`.
- **Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).

### 5. Analytics (Phase 3)
- **Goal**: Provide advanced loyalty insights. Success metric: 85%+ dashboard interaction rate, <1s latency for predictive analytics.
- **Predictive Analytics**: Churn prediction (`users.churn_score`), next purchase likelihood via `rfm-service` (`/rfm.v1/RFMService/PredictChurn`), visualized in Merchant Dashboard using Chart.js.
- **Custom Reports**: Allow merchants to create custom reports (e.g., points by RFM segment) via `analytics-service`, stored in `custom_reports`.
- **Exportable Data**: Export reports as CSV/PDF (max 10MB) via Admin Module, encrypted with AES-256, processed async via Bull queues.
- **Scalability**: Supports 50,000+ customers with Redis Streams (`rfm:predict:{merchant_id}`, `analytics:{merchant_id}`), PostgreSQL partitioning, and circuit breakers.
- **Database Design**:
  - **Table**: `custom_reports` (analytics-service, partitioned by `merchant_id`)
    - `report_id` (text, PK, NOT NULL): Unique ID.
    - `merchant_id` (text, FK → `merchants`, NOT NULL): Merchant.
    - `report_type` (text, NOT NULL): e.g., `points_by_segment`, `churn_prediction`.
    - `filters` (jsonb): e.g., `{"segment": "Champions", "date_range": {"start": "2025-01-01", "end": "2025-12-31"}}`.
    - `created_at` (timestamp(3), DEFAULT CURRENT_TIMESTAMP): Timestamp.
  - **Table**: `audit_logs`
    - `action` (text, NOT NULL): e.g., `custom_report_created`, `churn_prediction_viewed`.
    - `actor_id` (text, FK → `admin_users` | NULL): Admin user.
    - `metadata` (jsonb): e.g., `{"report_type": "points_by_segment", "churn_score": 0.75}`.
  - **Indexes**: `idx_custom_reports_merchant_id` (btree: `merchant_id`), `idx_audit_logs_action` (btree: `action`).
  - **Backup Retention**: 90 days in Backblaze B2, encrypted with AES-256.
- **API Sketch**:
  - **POST** `/v1/api/analytics/custom-report` (REST) | gRPC `/analytics.v1/AnalyticsService/CreateCustomReport`
    - **Input**: `{ merchant_id: string, report_type: string, filters: object, locale: string }`
    - **Output**: `{ status: string, report_id: string, error: { code: string, message: string } | null }`
    - **Flow**: Insert into `custom_reports`, generate report via `analytics-service`, cache in Redis Streams (`analytics:{merchant_id}`), log in `audit_logs`, track via PostHog (`custom_report_created`, 85%+ usage).
  - **GET** `/api/v1/rfm/predict` (REST) | gRPC `/rfm.v1/RFMService/PredictChurn`
    - **Input**: `{ merchant_id: string, customer_id: string, locale: string }`
    - **Output**: `{ status: string, churn_score: number, next_purchase_likelihood: number, error: { code: string, message: string } | null }`
    - **Flow**: Calculate `churn_score` via `rfm-service`, cache in Redis Streams (`rfm:predict:{customer_id}`), log in `audit_logs`, track via PostHog (`churn_prediction_viewed`, <1s latency).
- **GraphQL Query Examples**:
  - **Query: Fetch Customer Orders for Churn Prediction**
    - **Purpose**: Retrieves order history for churn prediction, used in `/api/v1/rfm/predict`.
    - **Query**:
      ```graphql
      query GetCustomerOrders($customerId: ID!) {
        customer(id: $customerId) {
          id
          orders(first: 100) {
            edges {
              node {
                id
                totalPriceSet {
                  shopMoney {
                    amount
                    currencyCode
                  }
                }
                createdAt
              }
            }
          }
        }
      }
      ```
    - **Variables**: `{ "customerId": "gid://shopify/Customer/987654321" }`
    - **Use Case**: Merchant Dashboard calculates `churn_score` in `users` table, visualized in Chart.js for predictive analytics.
- **Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized), RFM Service (gRPC: `/rfm.v1/*`, Dockerized).