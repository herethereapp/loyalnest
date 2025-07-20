# Technical Specifications: LoyalNest App

## Overview
LoyalNest is a Shopify app for small, medium, and Plus merchants (100–50,000+ customers, AOV $20–$500), offering a points-based loyalty program (e.g., 1000 points for $100 purchase, 200 points for 10% discount), SMS/email referrals, RFM segmentation, analytics, GDPR/CCPA compliance, and multilingual support (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`). This specification aligns with `Wireframes.txt`, `schema.txt`, `ERD.txt`, `RFM.markdown` (artifact_id: `b4ca549b-7ffa-42c3-9db2-9a4a74151dbf`), `feature_analytics.txt`, `user_stories.markdown`, `Flow Diagram.txt`, and `Sequence Diagrams.txt` (artifact_id: `478975db-7432-4070-826d-f9040af8fbd0`).

### Tech Stack
- **Backend**: NestJS, TypeORM, PostgreSQL (JSONB, `pgx` pooling, `pgcrypto` for encryption), Redis (Bull for queues, Streams for RFM, previews, and rate limits), Rust/Wasm (Shopify Functions for checkout points and RFM).
- **Frontend**: Vite + React, Shopify Polaris (merchant dashboard), Tailwind CSS (customer widget), Shopify App Bridge, i18next (multilingual, RTL for `ar`, `he`).
- **Integrations**: Shopify Admin API (webhooks, discounts, POS offline mode), Klaviyo/Postscript (notifications), AWS SES (fallback), PostHog (analytics), Square POS (sync), LaunchDarkly (feature flags).
- **Deployment**: VPS with Docker Compose, Nginx, Certbot for SSL, Railway for PostgreSQL/Redis, gRPC for microservices, Kubernetes for Plus-scale merchants.

## System Architecture
- **Microservices**:
  - **Points**: Manages points earning/redemption (`/points.v1/*`, `/points.v1/RedeemCampaignDiscount`, `/points.v1/SyncOfflineTransactions`).
  - **Referrals**: Handles referral links and notifications (`/referrals.v1/*`, `/referrals.v1/CreateReferral`, `/referrals.v1/GetReferralStatus`).
  - **Analytics**: Processes RFM, metrics, nudges, and segment previews (`/analytics.v1/*`, `/analytics.v1/AnalyticsService/GetNudges`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`, `/analytics.v1/SimulateRFM`).
  - **AdminCore**: Manages merchant configurations, plans, and GDPR requests (`/admin.v1/*`, `/admin.v1/SubmitGDPRRequest`, `/admin.v1/UpdateNotificationTemplate`).
  - **AdminFeatures**: Handles advanced admin features (e.g., replay/undo actions, Square POS sync, RFM simulation; `/admin.v1/GetCustomerJourney`, `/admin.v1/SyncSquarePOS`, `/admin.v1/SimulateRFMTransition`).
  - **Auth**: Handles Shopify OAuth and RBAC (`/auth.v1/*`).
  - **Frontend**: Serves React UI with Polaris/Tailwind for RFM configuration, GDPR form, referral status, customer import, rate limit monitoring, and Square POS sync.
- **Communication**: gRPC for microservices (e.g., Analytics ↔ Points for RFM-driven rewards, AdminFeatures ↔ Analytics for simulations), REST/GraphQL for Shopify/Frontend integration, WebSocket (`/admin/v1/setup/stream`) for onboarding.
- **Database**: PostgreSQL with JSONB (`program_settings.config`, `email_templates.body`, `customers.rfm_score`, `bonus_campaigns.conditions`, `rfm_segment_deltas.delta`). Partitioned tables (`points_transactions`, `api_logs`, `referrals`, `reward_redemptions`, `customer_segments`, `audit_logs`, `simulation_logs`) by `merchant_id`.
- **Caching**: Redis Streams for `points:{customer_id}`, `config:{merchant_id}`, `rfm:preview:{merchant_id}`, `rfm:burst:{merchant_id}`, `campaign_discount:{campaign_id}`, `leaderboard:{merchant_id}`, `template:{merchant_id}:{template_type}`, `rate_limit:{merchant_id}` (TTL: 60s–1h).
- **Queue**: Bull for SMS/email notifications, customer imports, and rate limit alerts (`rate_limit_queue:{merchant_id}`).
- **External Services**:
  - Shopify Admin API (customers, orders, discounts, POS offline mode).
  - Klaviyo/Postscript for SMS/email notifications, AWS SES fallback.
  - PostHog for analytics (points, redemptions, referrals, RFM, admin events).
  - Square POS API (`/v2/orders`) for transaction sync.
  - Shopify Functions (Rust/Wasm) for real-time points and RFM calculations.
  - LaunchDarkly for feature flags (`rfm_simulation`, `rfm_advanced`).
  - AWS SNS for rate limit alerts.

## Database Schema
Refer to `schema.txt` (artifact_id: `11afb340-73c5-4e4c-81e1-f6e37ff2d6c5`) and `ERD.txt` (artifact_id: `bf6eb50c-fa5a-40a9-8981-788f175dd68f`). Key tables:
- **merchants**: `merchant_id` (PK), `shopify_domain` (UK), `plan_id` (FK), `api_token` (AES-256), `status` (CHECK: `'active', 'suspended', 'trial', 'freemium'`), `language` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja', 'ru', 'it', 'nl', 'pl', 'tr', 'fa', 'zh-CN', 'vi', 'id', 'cs', 'ar', 'ko', 'uk', 'hu', 'sv', 'he']`), `staff_roles` (JSONB).
- **customers**: `customer_id` (PK), `merchant_id` (FK), `shopify_customer_id`, `email` (AES-256), `phone` (AES-256), `points_balance`, `rfm_score` (JSONB), `vip_tier_id` (FK).
- **points_transactions**: `transaction_id` (PK), `customer_id` (FK), `merchant_id` (FK), `type` (CHECK: `'earn', 'redeem', 'expire', 'adjust', 'offline_earn', 'square_earn'`), `points`, `order_id`, `metadata` (JSONB, e.g., `{"offline_txn_id": "txn123", "square_order_id": "sq123"}`). Partitioned by `merchant_id`.
- **rewards**: `reward_id` (PK), `merchant_id` (FK), `type`, `points_cost`, `value`, `is_public` (CHECK), `campaign_id` (FK, nullable, `US-BI4`).
- **referral_links**: `referral_link_id` (PK), `advocate_customer_id` (FK), `merchant_id` (FK), `referral_code`, `status` (CHECK: `'pending', 'completed', 'expired'`), `notification_status` (CHECK: `'pending', 'sent'`).
- **program_settings**: `merchant_id` (PK, FK), `points_currency_singular`, `config` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja', 'ru', 'it', 'nl', 'pl', 'tr', 'fa', 'zh-CN', 'vi', 'id', 'cs', 'ar', 'ko', 'uk', 'hu', 'sv', 'he']`), `rfm_thresholds` (JSONB).
- **gdpr_requests**: `request_id` (PK), `merchant_id` (FK), `customer_id` (FK), `request_type` (CHECK: `'data_request', 'redact'`), `retention_expires_at` (90 days).
- **email_templates**: `template_id` (PK), `merchant_id` (FK), `type`, `body` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja', 'ru', 'it', 'nl', 'pl', 'tr', 'fa', 'zh-CN', 'vi', 'id', 'cs', 'ar', 'ko', 'uk', 'hu', 'sv', 'he']`).
- **bonus_campaigns**: `campaign_id` (PK), `merchant_id` (FK), `name`, `type`, `multiplier`, `conditions` (JSONB, e.g., `{"rfm_score": {"recency": ">=4"}}`).
- **rfm_segment_counts**: Materialized view (`merchant_id`, `segment_name`, `customer_count`, `last_refreshed`, `US-MD12`), refreshed daily (`0 1 * * *`).
- **rfm_segment_deltas**: `delta_id` (PK), `merchant_id` (FK), `customer_id` (FK), `segment`, `delta` (JSONB), `delta_timestamp`.
- **audit_logs**: `log_id` (PK), `merchant_id` (FK), `admin_user_id`, `action` (CHECK: `'undo_action', 'replay_action', 'square_sync', 'rfm_simulation'`), `metadata` (JSONB). Partitioned by `merchant_id`.
- **simulation_logs**: `log_id` (PK), `merchant_id` (FK), `customer_id` (FK), `simulation_params` (JSONB), `result_segment`. Partitioned by `merchant_id`.

### Indexes
```sql
CREATE INDEX idx_customers_email ON customers USING btree (email);
CREATE INDEX idx_points_transactions_customer_id ON points_transactions USING btree (customer_id, created_at);
CREATE INDEX idx_api_logs_merchant_id_timestamp ON api_logs USING btree (merchant_id, timestamp);
CREATE INDEX idx_program_settings_config ON program_settings USING gin (config);
CREATE INDEX idx_referrals_notification_status ON referrals USING btree (notification_status);
CREATE INDEX idx_rfm_segment_counts ON rfm_segment_counts USING btree (merchant_id, last_refreshed);
CREATE INDEX idx_customers_rfm_score_at_risk ON customers USING btree (rfm_score) WHERE (rfm_score->>'score' < '2');
CREATE INDEX idx_audit_logs_action ON audit_logs USING btree (action, created_at);
CREATE INDEX idx_simulation_logs_customer_id ON simulation_logs USING btree (customer_id, created_at);
CREATE INDEX idx_rfm_segment_deltas_customer_id ON rfm_segment_deltas USING btree (customer_id, delta_timestamp);
```

### Database Initialization (init.sql)
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS cron;

CREATE MATERIALIZED VIEW rfm_segment_counts AS
  SELECT merchant_id, name AS segment_name, COUNT(*) AS customer_count, NOW() AS last_refreshed
  FROM customer_segments
  GROUP BY merchant_id, name
WITH DATA;

CREATE INDEX idx_rfm_segment_counts_merchant_id ON rfm_segment_counts USING btree (merchant_id, last_refreshed);

SELECT cron.schedule('refresh_rfm_segment_counts', '0 1 * * *', $$REFRESH MATERIALIZED VIEW rfm_segment_counts$$);
```

## API Endpoints

### 1. GET /api/customer/points (Points Service, gRPC: `/points.v1/GetPoints`)
**Description**: Retrieves customer’s points balance, rewards, and RFM score (`US-CW1`).
**Authentication**: Shopify OAuth (customer session token).
**Request**:
```http
GET /api/customer/points
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
```
**Response**:
```json
{
  "balance": 1000,
  "rfm_score": { "recency": 5, "frequency": 4, "monetary": 3, "score": 4.1 },
  "rewards": [
    { "reward_id": "r1", "points_cost": 200, "type": "DISCOUNT", "value": "10%" },
    { "reward_id": "r2", "points_cost": 500, "type": "FREE_SHIPPING", "value": "100%", "campaign_id": "c1" }
  ]
}
```
**Error Responses**:
- 401: Invalid token.
- 404: Customer not found.
**Logic**:
- Check Redis (`points:{customer_id}`).
- Query `customers.points_balance`, `customers.rfm_score`, `rewards` (filtered by `is_public`, `merchant_id`).
- Cache in Redis (TTL: 3600s).
- Log to PostHog (`points_viewed`).
**gRPC**:
```proto
service PointsService {
  rpc GetPoints(GetPointsRequest) returns (GetPointsResponse);
}
message GetPointsRequest {
  string customer_id = 1;
  string merchant_id = 2;
}
message GetPointsResponse {
  int32 balance = 1;
  map<string, int32> rfm_score = 2;
  repeated Reward rewards = 3;
}
```

### 2. POST /api/redeem (Points Service, gRPC: `/points.v1/RedeemPoints`, `/points.v1/RedeemCampaignDiscount`)
**Description**: Redeems points for a reward or campaign discount, creates Shopify discount code (`US-CW2`, `US-BI4`).
**Authentication**: Shopify OAuth (customer session token).
**Request**:
```http
POST /api/redeem
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "reward_id": "r1",
  "points_cost": 200,
  "campaign_id": "c1"
}
```
**Response**:
```json
{
  "discount_code": "LOYALTY_abc123",
  "new_balance": 800
}
```
**Error Responses**:
- 400: Insufficient points.
- 404: Reward/campaign not found.
- 429: Shopify API rate limit exceeded.
**Logic**:
- Validate `customers.points_balance >= points_cost` and `bonus_campaigns.conditions` for RFM eligibility.
- Create Shopify discount code via Admin API.
- Insert into `points_transactions` (`type: 'redeem'`), `reward_redemptions` (`campaign_id` if provided).
- Update `customers.points_balance`, Redis (`points:{customer_id}`, `campaign_discount:{campaign_id}`).
- Log to `api_logs`, PostHog (`points_redeemed`).
**gRPC**:
```proto
service PointsService {
  rpc RedeemCampaignDiscount(RedeemCampaignDiscountRequest) returns (RedeemCampaignDiscountResponse);
}
message RedeemCampaignDiscountRequest {
  string customer_id = 1;
  string merchant_id = 2;
  string campaign_id = 3;
  int32 points_cost = 4;
}
message RedeemCampaignDiscountResponse {
  string discount_code = 1;
  int32 new_balance = 2;
}
```

### 3. POST /api/settings (Points Service, gRPC: `/points.v1/UpdateSettings`)
**Description**: Updates merchant points program settings, including RFM thresholds (`US-MD2`).
**Authentication**: Shopify OAuth (merchant session token).
**Request**:
```http
POST /api/settings
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "points_per_dollar": 10,
  "program_status": "active",
  "language": { "default": "en", "supported": ["en", "es", "fr", "de", "pt", "ja", "ru", "it", "nl", "pl", "tr", "fa", "zh-CN", "vi", "id", "cs", "ar", "ko", "uk", "hu", "sv", "he"] },
  "rfm_thresholds": { "recency": { "5": { "maxDays": 7 } }, "frequency": { "5": { "minOrders": 10 } }, "monetary": { "5": { "minSpend": 2500 } } }
}
```
**Response**:
```json
{
  "message": "Settings updated"
}
```
**Error Responses**:
- 401: Invalid token.
- 400: Invalid settings format.
**Logic**:
- Update `program_settings.config`, `program_settings.rfm_thresholds`, `merchants.language` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja', 'ru', 'it', 'nl', 'pl', 'tr', 'fa', 'zh-CN', 'vi', 'id', 'cs', 'ar', 'ko', 'uk', 'hu', 'sv', 'he']`).
- Update Redis (`config:{merchant_id}`).
- Log to `api_logs`, PostHog (`settings_updated`).

### 4. POST /api/rewards (Points Service, gRPC: `/points.v1/AddReward`)
**Description**: Adds a new reward with optional RFM-driven campaign (`US-MD2`).
**Authentication**: Shopify OAuth (merchant session token).
**Request**:
```http
POST /api/rewards
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "points_cost": 200,
  "type": "DISCOUNT",
  "value": "10%",
  "is_public": true,
  "campaign_id": "c1",
  "conditions": { "rfm_score": { "recency": ">=4" } }
}
```
**Response**:
```json
{
  "reward_id": "r1",
  "message": "Reward added"
}
```
**Error Responses**:
- 401: Invalid token.
- 400: Invalid reward format.
**Logic**:
- Insert into `rewards`, `bonus_campaigns` (`conditions` JSONB for RFM eligibility).
- Update Redis (`config:{merchant_id}`, `campaign_discount:{campaign_id}`).
- Log to `api_logs`, PostHog (`reward_added`).

### 5. POST /api/referral (Referrals Service, gRPC: `/referrals.v1/CreateReferral`)
**Description**: Creates a referral link (`US-CW7`).
**Authentication**: Shopify OAuth (customer session token).
**Request**:
```http
POST /api/referral
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "advocate_customer_id": "c1",
  "merchant_id": "m1"
}
```
**Response**:
```json
{
  "referral_code": "REF_abc123",
  "referral_url": "https://store.myshopify.com/ref/abc123"
}
```
**Error Responses**:
- 401: Invalid token.
- 404: Customer/merchant not found.
**Logic**:
- Insert into `referral_links` with unique `referral_code`.
- Queue SMS/email via Klaviyo/Postscript (Bull, fallback to AWS SES).
- Update Redis (`referral:{referral_code}`).
- Log to `api_logs`, PostHog (`referral_created`, `referral_fallback_triggered` if AWS SES used).

### 6. GET /api/referral/status (Referrals Service, gRPC: `/referrals.v1/GetReferralStatus`)
**Description**: Retrieves referral status with progress bar (`US-CW7`).
**Authentication**: Shopify OAuth (customer session token).
**Request**:
```http
GET /api/referral/status
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Query: ?customer_id=c1&merchant_id=m1
```
**Response**:
```json
{
  "referrals": [
    { "referral_code": "REF_abc123", "status": "pending", "created_at": "2025-07-09T02:03:00Z", "progress": 0.5 }
  ]
}
```
**Error Responses**:
- 401: Invalid token.
- 404: Customer not found.
**Logic**:
- Query `referral_links` by `advocate_customer_id`, `merchant_id`.
- Calculate `progress` based on referral milestones (e.g., 0.5 for 1/2 referred purchases).
- Cache in Redis (`referral:{customer_id}`, TTL: 3600s).
- Log to `api_logs`, PostHog (`referral_status_viewed`).

### 7. POST /api/gdpr/request (AdminCore Service, gRPC: `/admin.v1/SubmitGDPRRequest`)
**Description**: Submits customer GDPR/CCPA request (`US-CW8`).
**Authentication**: Shopify OAuth (customer session token).
**Request**:
```http
POST /api/gdpr/request
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "customer_id": "c1",
  "merchant_id": "m1",
  "request_type": "data_request"
}
```
**Response**:
```json
{
  "request_id": "gr1",
  "message": "GDPR request submitted"
}
```
**Error Responses**:
- 401: Invalid token.
- 400: Invalid request type.
**Logic**:
- Insert into `gdpr_requests` (`retention_expires_at` = `NOW() + 90 days`).
- Log to `api_logs`, PostHog (`gdpr_request_submitted`).

### 8. POST /api/notifications/template (AdminCore Service, gRPC: `/admin.v1/UpdateNotificationTemplate`)
**Description**: Configures notification templates for points, referrals, or RFM nudges with live preview (`US-MD8`).
**Authentication**: Shopify OAuth (merchant session token).
**Request**:
```http
POST /api/notifications/template
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "type": "points_earned",
  "body": { 
    "en": "You earned {points} points!", 
    "es": "¡Ganaste {points} puntos!", 
    "fr": "Vous avez gagné {points} points!",
    "de": "Sie haben {points} Punkte verdient!",
    "pt": "Você ganhou {points} pontos!",
    "ja": "{points}ポイントを獲得しました！",
    "ru": "Вы заработали {points} баллов!",
    "it": "Hai guadagnato {points} punti!",
    "nl": "Je hebt {points} punten verdiend!",
    "pl": "Zdobyłeś {points} punktów!",
    "tr": "{points} puan kazandınız!",
    "fa": "شما {points} امتیاز کسب کردید!",
    "zh-CN": "您获得了{points}积分！",
    "vi": "Bạn đã kiếm được {points} điểm!",
    "id": "Anda telah memperoleh {points} poin!",
    "cs": "Získali jste {points} bodů!",
    "ar": "لقد ربحت {points} نقطة!",
    "ko": "{points} 포인트를 획득했습니다!",
    "uk": "Ви заробили {points} балів!",
    "hu": "{points} pontot szereztél!",
    "sv": "Du har tjänat {points} poäng!",
    "he": "הרווחת {points} נקודות!"
  }
}
```
**Response**:
```json
{
  "template_id": "t1",
  "message": "Template updated",
  "preview": { "en": "You earned 100 points!" }
}
```
**Error Responses**:
- 401: Invalid token.
- 400: Invalid template format.
**Logic**:
- Insert/update `email_templates` (`body` JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja', 'ru', 'it', 'nl', 'pl', 'tr', 'fa', 'zh-CN', 'vi', 'id', 'cs', 'ar', 'ko', 'uk', 'hu', 'sv', 'he']`).
- Generate live preview using Redis Streams (`template:{merchant_id}:{type}`).
- Update Redis cache.
- Log to `api_logs`, PostHog (`template_edited`).

### 9. POST /api/customers/import (AdminCore Service, gRPC: `/admin.v1/ImportCustomers`)
**Description**: Imports customers via CSV (`US-BI3`).
**Authentication**: Shopify OAuth (merchant session token).
**Request**:
```http
POST /api/customers/import
Headers: Authorization: Bearer <shopify_token>, Content-Type: multipart/form-data
Body: { file: <CSV file> }
```
**Response**:
```json
{
  "imported_count": 100,
  "message": "Customers imported"
}
```
**Error Responses**:
- 401: Invalid token.
- 400: Invalid CSV format.
**Logic**:
- Parse CSV, validate `email`, `shopify_customer_id`, `phone`.
- Insert into `customers` (AES-256 for `email`, `phone`).
- Queue points and RFM calculation via Bull.
- Log to `api_logs`, PostHog (`customer_import_initiated`).

### 10. GET /api/rate-limits (AdminCore Service, gRPC: `/admin.v1/GetRateLimits`)
**Description**: Monitors Shopify API and integration rate limits with alerts (`US-AM11`).
**Authentication**: Shopify OAuth (merchant session token, RBAC: `admin`).
**Request**:
```http
GET /api/rate-limits
Headers: Authorization: Bearer <shopify_token>
```
**Response**:
```json
{
  "shopify_api": { "current": 45, "max": 50, "unit": "points/s" },
  "klaviyo": "OK",
  "postscript": "OK",
  "square": "OK"
}
```
**Error Responses**:
- 401: Invalid token or insufficient role.
- 429: Rate limit exceeded (triggers AWS SNS alert).
**Logic**:
- Query Shopify API, Klaviyo, Postscript, Square rate limit headers.
- Cache in Redis (`rate_limit:{merchant_id}`, TTL: 60s).
- Trigger AWS SNS alert via Bull queue (`rate_limit_queue:{merchant_id}`) if limits near threshold.
- Log to `api_logs`, PostHog (`rate_limit_viewed`).

### 11. GET /api/admin/analytics (Analytics Service, gRPC: `/analytics.v1/GetAnalytics`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`)
**Description**: Retrieves merchant analytics with RFM segments (`US-MD5`, `US-MD12`).
**Authentication**: Shopify OAuth (merchant session token, RBAC: `admin` or `analytics`).
**Request**:
```http
GET /api/admin/analytics
Headers: Authorization: Bearer <shopify_token>
Query: ?start_date=2025-01-01&end_date=2025-07-01
```
**Response**:
```json
{
  "points_earned": 50000,
  "points_redeemed": 20000,
  "redemptions_count": 100,
  "rfm_segments": [
    { "segment_name": "At-Risk", "customer_count": 100 },
    { "segment_name": "Active", "customer_count": 200 }
  ]
}
```
**Error Responses**:
- 401: Invalid token or insufficient role.
- 400: Invalid date range.
**Logic**:
- Check `merchants.staff_roles` for RBAC.
- Query `points_transactions`, `reward_redemptions`, `rfm_segment_counts` (refreshed daily at `0 1 * * *`).
- Cache in Redis Streams (`rfm:preview:{merchant_id}`, TTL: 1h).
- Log to `api_logs`, PostHog (`analytics_viewed`).

### 12. GET /api/nudges (Analytics Service, gRPC: `/analytics.v1/AnalyticsService/GetNudges`)
**Description**: Retrieves RFM-based nudges for customers (`US-MD12`).
**Authentication**: Shopify OAuth (merchant session token).
**Request**:
```http
GET /api/nudges
Headers: Authorization: Bearer <shopify_token>
Query: ?customer_id=c1&merchant_id=m1
```
**Response**:
```json
{
  "nudges": [
    { "nudge_id": "n1", "type": "at-risk", "title": { "en": "Stay Active!" }, "description": { "en": "Make a purchase to stay in the VIP tier!" } }
  ]
}
```
**Error Responses**:
- 401: Invalid token.
- 404: Customer/merchant not found.
**Logic**:
- Query `nudges` by `merchant_id`, filter by `rfm_score` (e.g., At-Risk: `rfm_score->>'score' < '2'`).
- Cache in Redis Streams (`rfm:preview:{merchant_id}`).
- Log to `api_logs`, PostHog (`nudge_viewed`).

### 13. POST /api/admin/replay (AdminFeatures Service, gRPC: `/admin.v1/GetCustomerJourney`)
**Description**: Replays or undoes customer actions (points, rewards, referrals; `US-AM15`).
**Authentication**: Shopify OAuth (merchant session token, RBAC: `superadmin`).
**Request**:
```http
POST /api/admin/replay
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "customer_id": "c1",
  "merchant_id": "m1",
  "action_type": "undo_action",
  "transaction_id": "t1",
  "points": 200
}
```
**Response**:
```json
{
  "message": "Action undone",
  "new_balance": 800
}
```
**Error Responses**:
- 401: Invalid token or insufficient role.
- 404: Customer/transaction not found.
**Logic**:
- Check `merchants.staff_roles` for RBAC.
- For `undo_action`: Insert `points_transactions` (`type: 'adjust'`, `points: -points`), update `customers.points_balance`, insert `audit_logs` (`action: 'undo_action'`).
- For `replay_action`: Insert `points_transactions` (`type: 'replay'`), update `customers.points_balance`, insert `audit_logs` (`action: 'replay_action'`).
- Update Redis (`points:{customer_id}`, `rfm:burst:{merchant_id}`, TTL: 1h).
- Log to `api_logs`, PostHog (`action_undone` or `action_replayed`).
**gRPC**:
```proto
service AdminFeaturesService {
  rpc GetCustomerJourney(GetCustomerJourneyRequest) returns (GetCustomerJourneyResponse);
}
message GetCustomerJourneyRequest {
  string admin_id = 1;
  string customer_id = 2;
  string merchant_id = 3;
  string action_type = 4;
}
message GetCustomerJourneyResponse {
  string message = 1;
  int32 new_balance = 2;
}
```

### 14. POST /api/admin/rfm/simulate (AdminFeatures Service, gRPC: `/admin.v1/SimulateRFMTransition`)
**Description**: Simulates RFM segment transitions for a customer (`US-AM16`).
**Authentication**: Shopify OAuth (merchant session token, RBAC: `superadmin`).
**Request**:
```http
POST /api/admin/rfm/simulate
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "customer_id": "c1",
  "merchant_id": "m1",
  "simulation_params": { "orders": 2, "total_spend": 500, "last_purchase": "2025-07-01" }
}
```
**Response**:
```json
{
  "result_segment": "Active",
  "message": "Simulation completed"
}
```
**Error Responses**:
- 401: Invalid token or insufficient role.
- 403: Feature flag `rfm_simulation` disabled.
- 404: Customer/merchant not found.
**Logic**:
- Check `merchants.staff_roles` and LaunchDarkly (`rfm_simulation`).
- Call `/analytics.v1/SimulateRFM` with `simulation_params`.
- Insert into `simulation_logs` (`simulation_params`, `result_segment`).
- Update Redis (`rfm_simulation:{merchant_id}:{customer_id}`, TTL: 1h).
- Insert `audit_logs` (`action: 'rfm_simulation'`).
- Log to `api_logs`, PostHog (`admin_event_simulated`).
**gRPC**:
```proto
service AdminFeaturesService {
  rpc SimulateRFMTransition(SimulateRFMTransitionRequest) returns (SimulateRFMTransitionResponse);
}
message SimulateRFMTransitionRequest {
  string admin_id = 1;
  string customer_id = 2;
  string merchant_id = 3;
  map<string, string> simulation_params = 4;
}
message SimulateRFMTransitionResponse {
  string result_segment = 1;
  string message = 2;
}
```

### 15. POST /api/admin/square/sync (AdminFeatures Service, gRPC: `/admin.v1/SyncSquarePOS`)
**Description**: Syncs Square POS transactions (`US-BI6`).
**Authentication**: Shopify OAuth (merchant session token, RBAC: `superadmin`).
**Request**:
```http
POST /api/admin/square/sync
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "merchant_id": "m1"
}
```
**Response**:
```json
{
  "message": "Square sync completed",
  "transaction_count": 50
}
```
**Error Responses**:
- 401: Invalid token or insufficient role.
- 404: Merchant not found.
**Logic**:
- Check `merchants.staff_roles` for RBAC.
- Fetch Square transactions via `/v2/orders` (OAuth).
- Insert into `points_transactions` (`type: 'square_earn'`, `metadata: {"square_order_id": "sq123"}`).
- Update `customers.points_balance`, Redis (`points:{customer_id}`).
- Insert `audit_logs` (`action: 'square_sync'`).
- Log to `api_logs`, PostHog (`square_sync_triggered`).
**gRPC**:
```proto
service AdminFeaturesService {
  rpc SyncSquarePOS(SyncSquarePOSRequest) returns (SyncSquarePOSResponse);
}
message SyncSquarePOSRequest {
  string admin_id = 1;
  string merchant_id = 2;
}
message SyncSquarePOSResponse {
  string message = 1;
  int32 transaction_count = 2;
}
```

## Webhooks

### 1. orders/create (Points Service)
**Description**: Awards points for purchases (`US-CW1`).
**Endpoint**: `POST /webhooks/orders/create`
**Payload**:
```json
{
  "id": "987654321",
  "total_price": "100.00",
  "customer": { "id": "123456789" },
  "shop_id": "store.myshopify.com"
}
```
**Logic**:
- Verify HMAC.
- Fetch `points_per_dollar` from `program_settings.config`.
- Calculate points: `total_price * points_per_dollar`.
- Insert into `points_transactions` (`type: 'earn'`), update `customers.points_balance`, Redis (`points:{customer_id}`).
- Trigger RFM recalculation via gRPC (`/analytics.v1/AnalyticsService/PreviewRFMSegments`).
- Queue notification via Klaviyo/Postscript (fallback to AWS SES).
- Log to `api_logs`, PostHog (`points_earned`).

### 2. orders/cancelled (Points Service)
**Description**: Adjusts points for cancelled orders (`US-CW6`).
**Endpoint**: `POST /webhooks/orders/cancelled`
**Payload**:
```json
{
  "id": "987654321",
  "customer": { "id": "123456789" },
  "shop_id": "store.myshopify.com"
}
```
**Logic**:
- Verify HMAC.
- Find `points_transactions` by `order_id`, `type: 'earn'`.
- Insert `points_transactions` (`type: 'adjust'`), update `customers.points_balance`, Redis (`points:{customer_id}`).
- Trigger RFM recalculation via gRPC (`/analytics.v1/AnalyticsService/PreviewRFMSegments`).
- Log to `api_logs`, PostHog (`points_adjusted`).

### 3. customers/data_request (AdminCore Service)
**Description**: Handles GDPR/CCPA data requests (`US-AM6`).
**Endpoint**: `POST /webhooks/customers/data_request`
**Payload**:
```json
{
  "shop_id": "store.myshopify.com",
  "customer": { "id": "123456789", "email": "user@example.com" }
}
```
**Logic**:
- Verify HMAC.
- Insert into `gdpr_requests` (`request_type: 'data_request'`, `retention_expires_at`).
- Query `customers`, `points_transactions`, `reward_redemptions`, `referral_links`.
- Send data via Klaviyo/Postscript (fallback to AWS SES).
- Log to `api_logs`, PostHog (`gdpr_request`).

### 4. customers/redact (AdminCore Service)
**Description**: Handles GDPR/CCPA redaction requests (`US-AM6`).
**Endpoint**: `POST /webhooks/customers/redact`
**Payload**:
```json
{
  "shop_id": "store.myshopify.com",
  "customer": { "id": "123456789", "email": "user@example.com" }
}
```
**Logic**:
- Verify HMAC.
- Insert into `gdpr_requests` (`request_type: 'redact'`, `retention_expires_at`).
- Delete/anonymize `customers`, `points_transactions`, `reward_redemptions`, `referral_links`, `customer_segments`.
- Log to `api_logs`, PostHog (`gdpr_request`).

### 5. pos/offline_sync (Points Service)
**Description**: Syncs Shopify POS offline transactions (`US-BI2`).
**Endpoint**: `POST /webhooks/pos/offline_sync`
**Payload**:
```json
{
  "shop_id": "store.myshopify.com",
  "transactions": [
    { "id": "txn123", "customer_id": "123456789", "total_price": "50.00", "created_at": "2025-07-09T02:03:00Z" }
  ]
}
```
**Logic**:
- Verify HMAC.
- Validate OAuth token via Shopify Admin API.
- Insert into `points_transactions` (`type: 'offline_earn'`, `metadata: {"offline_txn_id": "txn123"}`).
- Update `customers.points_balance`, Redis (`points:{customer_id}`).
- Log to `api_logs`, PostHog (`offline_sync_completed`).

## Notifications
### Klaviyo/Postscript (SMS/Email)
**Trigger**: Points earned, referral created, VIP tier change, GDPR request, RFM nudges, Square sync confirmation (`US-MD8`, `US-BI2`, `US-MD12`, `US-BI6`).
**Logic**:
- Fetch `customers.phone`, `customers.email`, `email_templates.body`, `nudges.title`, `nudges.description` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja', 'ru', 'it', 'nl', 'pl', 'tr', 'fa', 'zh-CN', 'vi', 'id', 'cs', 'ar', 'ko', 'uk', 'hu', 'sv', 'he']`).
- Queue via Bull, fallback to AWS SES if Klaviyo/Postscript unavailable.
- Log to PostHog (`referral_fallback_triggered` for AWS SES).
**Example**:
```typescript
async notifyCustomer(customerId: string, merchantId: string, type: string, language: string = 'en') {
  const [customer] = await this.typeOrmRepository.query(
    'SELECT phone, email FROM customers WHERE customer_id = $1 AND merchant_id = $2',
    [customerId, merchantId]
  );
  const [template] = await this.typeOrmRepository.query(
    'SELECT body->>$2 AS body FROM email_templates WHERE merchant_id = $1 AND type = $3',
    [merchantId, language, type]
  );
  const queue = new Queue('notifications', process.env.REDIS_URL);
  try {
    if (customer.phone) {
      await queue.add('sms', {
        to: customer.phone,
        body: template.body,
        from: process.env.POSTSCRIPT_PHONE
      });
    }
    if (customer.email) {
      await queue.add('email', {
        to: customer.email,
        from: 'support@herethere.dev',
        subject: `${type}_notification`,
        text: template.body
      });
    }
  } catch (error) {
    await queue.add('email_fallback', {
      to: customer.email,
      from: 'support@herethere.dev',
      subject: `${type}_notification`,
      text: template.body
    }, { queue: 'aws_ses' });
    posthog.capture('referral_fallback_triggered', { customer_id: customerId, merchant_id: merchantId });
  }
  posthog.capture(`${type}_notification`, { customer_id: customerId, merchant_id: merchantId });
}
```

## Shopify Functions (Rust/Wasm)
**Function**: `calculate_points`
**Purpose**: Compute points at checkout for Plus merchants.
**Logic**:
```rust
#[shopify_function]
fn calculate_points(input: Input) -> Result<Output, Error> {
    let points = input.order.total_price * input.shop.config.points_per_dollar;
    if points < 0.0 {
        return Err(Error::InvalidInput("Negative points"));
    }
    Ok(Output { points: points as i32 })
}
```
**Function**: `update_rfm_score`
**Purpose**: Update RFM scores in real-time for Plus merchants.
**Logic**:
```rust
#[shopify_function]
fn update_rfm_score(input: Input) -> Result<Output, Error> {
    let score = calculate_rfm(&input.order, input.merchant_aov)?;
    update_customer(&score, &input.customer_id)?;
    Ok(Output { score })
}
```
**Deployment**: Use Shopify CLI (`shopify function push`).
**Integration**: Call from Points/Analytics Service, log to `points_transactions`, `customers.rfm_score`, `rfm_segment_deltas`.

## Frontend Components
### Customer Widget (Tailwind CSS, i18next)
- **PointsBalance** (`US-CW1`):
```jsx
import { useTranslation } from 'react-i18next';
function PointsBalance({ balance, rfm_score }) {
  const { t } = useTranslation();
  return (
    <div className="p-4 bg-white rounded shadow" aria-label={t('points_balance')}>
      <h2>{t('your_points')}: {balance}</h2>
      <p>RFM: R{rfm_score.recency} F{rfm_score.frequency} M{rfm_score.monetary}</p>
    </div>
  );
}
```
- **RedeemForm** (`US-CW2`, `US-BI4`):
```jsx
import { useTranslation } from 'react-i18next';
function RedeemForm({ rewards }) {
  const { t } = useTranslation();
  const handleRedeem = async (rewardId, pointsCost, campaignId) => {
    try {
      const { data } = await axios.post('/api/redeem', { reward_id: rewardId, points_cost: pointsCost, campaign_id: campaignId }, {
        headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
      });
      alert(t('discount_code') + `: ${data.discount_code}`);
    } catch (error) {
      alert(t('error_insufficient_points'));
    }
  };
  return (
    <div className="p-4 bg-white rounded shadow" aria-label={t('redeem_points')}>
      {rewards.map(r => (
        <button
          key={r.reward_id}
          onClick={() => handleRedeem(r.reward_id, r.points_cost, r.campaign_id)}
          className="bg-blue-500 text-white p-2 rounded"
          aria-label={t('redeem') + ` ${r.points_cost} ${t('points')} ${r.value} ${r.type}`}
        >
          {t('redeem')} {r.points_cost} {t('points')} {r.value} {r.type}
        </button>
      ))}
    </div>
  );
}
```
- **ReferralStatus** (`US-CW7`):
```jsx
import { useTranslation } from 'react-i18next';
function ReferralStatus({ referrals }) {
  const { t } = useTranslation();
  return (
    <div className="p-4 bg-white rounded shadow" aria-label={t('referral_status')}>
      <h2>{t('your_referrals')}</h2>
      {referrals.map(r => (
        <div key={r.referral_code}>
          <p>{r.referral_code}: {t(r.status)}</p>
          <progress value={r.progress} max="1" aria-label={t('referral_progress')}></progress>
        </div>
      ))}
    </div>
  );
}
```
- **GDPRRequestForm** (`US-CW8`):
```jsx
import { useTranslation } from 'react-i18next';
function GDPRRequestForm({ customerId, merchantId }) {
  const { t } = useTranslation();
  const handleSubmit = async (requestType) => {
    await axios.post('/api/gdpr/request', { customer_id: customerId, merchant_id: merchantId, request_type: requestType }, {
      headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
    });
    alert(t('gdpr_request_submitted'));
  };
  return (
    <div className="p-4 bg-white rounded shadow" aria-label={t('gdpr_request')}>
      <button onClick={() => handleSubmit('data_request')} className="bg-blue-500 text-white p-2 rounded" aria-label={t('request_data')}>
        {t('request_data')}
      </button>
      <button onClick={() => handleSubmit('redact')} className="bg-red-500 text-white p-2 rounded" aria-label={t('delete_data')}>
        {t('delete_data')}
      </button>
    </div>
  );
}
```

### Merchant Dashboard (Polaris)
- **SettingsPage** (`US-MD2`):
```jsx
import { Card, TextField, Button } from '@shopify/polaris';
import { useTranslation } from 'react-i18next';
function SettingsPage({ settings }) {
  const { t } = useTranslation();
  const [pointsPerDollar, setPointsPerDollar] = useState(settings.points_per_dollar);
  const [rfmThresholds, setRfmThresholds] = useState(settings.rfm_thresholds);
  const handleSave = async () => {
    await axios.post('/api/settings', { points_per_dollar: pointsPerDollar, rfm_thresholds: rfmThresholds }, {
      headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
    });
  };
  return (
    <Card sectioned>
      <TextField
        label={t('points_per_dollar')}
        value={pointsPerDollar}
        onChange={setPointsPerDollar}
        aria-label={t('points_per_dollar')}
      />
      <TextField
        label={t('rfm_thresholds')}
        value={JSON.stringify(rfmThresholds)}
        onChange={(value) => setRfmThresholds(JSON.parse(value))}
        aria-label={t('rfm_thresholds')}
      />
      <Button onClick={handleSave} aria-label={t('save_settings')}>
        {t('save')}
      </Button>
    </Card>
  );
}
```
- **NotificationTemplatePage** (`US-MD8`):
```jsx
import { Card, TextField, Button } from '@shopify/polaris';
import { useTranslation } from 'react-i18next';
function NotificationTemplatePage({ template }) {
  const { t } = useTranslation();
  const [body, setBody] = useState(template.body);
  const handleSave = async () => {
    await axios.post('/api/notifications/template', { type: template.type, body }, {
      headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
    });
  };
  return (
    <Card sectioned>
      <TextField
        label={t('template_body')}
        value={body.en}
        onChange={(value) => setBody({ ...body, en: value })}
        aria-label={t('template_body')}
      />
      <Button onClick={handleSave} aria-label={t('save_template')}>
        {t('save')}
      </Button>
    </Card>
  );
}
```
- **RateLimitPage** (`US-AM11`):
```jsx
import { Card, Text } from '@shopify/polaris';
import { useTranslation } from 'react-i18next';
function RateLimitPage({ rateLimits }) {
  const { t } = useTranslation();
  return (
    <Card sectioned>
      <Text>{t('shopify_api')}: {rateLimits.shopify_api.current}/{rateLimits.shopify_api.max} {rateLimits.shopify_api.unit}</Text>
      <Text>{t('klaviyo')}: {rateLimits.klaviyo}</Text>
      <Text>{t('postscript')}: {rateLimits.postscript}</Text>
      <Text>{t('square')}: {rateLimits.square}</Text>
    </Card>
  );
}
```
- **CustomerImportPage** (`US-BI3`):
```jsx
import { Card, Button, FileUpload } from '@shopify/polaris';
import { useTranslation } from 'react-i18next';
function CustomerImportPage() {
  const { t } = useTranslation();
  const [file, setFile] = useState(null);
  const handleImport = async () => {
    const formData = new FormData();
    formData.append('file', file);
    await axios.post('/api/customers/import', formData, {
      headers: { Authorization: `Bearer ${getSessionToken(appBridge)}`, 'Content-Type': 'multipart/form-data' }
    });
    alert(t('customers_imported'));
  };
  return (
    <Card sectioned>
      <FileUpload onChange={setFile} accept=".csv" aria-label={t('upload_csv')} />
      <Button onClick={handleImport} aria-label={t('import_customers')}>
        {t('import')}
      </Button>
    </Card>
  );
}
```
- **ActionReplayPage** (`US-AM15`):
```jsx
import { Card, Button, Text } from '@shopify/polaris';
import { useTranslation } from 'react-i18next';
function ActionReplayPage({ customerId, merchantId }) {
  const { t } = useTranslation();
  const handleAction = async (actionType, transactionId, points) => {
    try {
      const { data } = await axios.post('/api/admin/replay', { customer_id: customerId, merchant_id: merchantId, action_type: actionType, transaction_id: transactionId, points }, {
        headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
      });
      alert(t('action_completed', { message: data.message }));
    } catch (error) {
      alert(t('error_unauthorized'));
    }
  };
  return (
    <Card sectioned>
      <Text>{t('replay_undo_actions')}</Text>
      <Button onClick={() => handleAction('undo_action', 't1', 200)} aria-label={t('undo_action')}>
        {t('undo')}
      </Button>
      <Button onClick={() => handleAction('replay_action', 't1', 200)} aria-label={t('replay_action')}>
        {t('replay')}
      </Button>
    </Card>
  );
}
```
- **RFMSimulationPage** (`US-AM16`):
```jsx
import { Card, TextField, Button } from '@shopify/polaris';
import { useTranslation } from 'react-i18next';
function RFMSimulationPage({ customerId, merchantId }) {
  const { t } = useTranslation();
  const [params, setParams] = useState({ orders: 2, total_spend: 500, last_purchase: '2025-07-01' });
  const handleSimulate = async () => {
    try {
      const { data } = await axios.post('/api/admin/rfm/simulate', { customer_id: customerId, merchant_id: merchantId, simulation_params: params }, {
        headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
      });
      alert(t('simulation_completed', { segment: data.result_segment }));
    } catch (error) {
      alert(t('error_unauthorized'));
    }
  };
  return (
    <Card sectioned>
      <TextField
        label={t('simulation_params')}
        value={JSON.stringify(params)}
        onChange={(value) => setParams(JSON.parse(value))}
        aria-label={t('simulation_params')}
      />
      <Button onClick={handleSimulate} aria-label={t('simulate_rfm')}>
        {t('simulate')}
      </Button>
    </Card>
  );
}
```
- **SquareSyncPage** (`US-BI6`):
```jsx
import { Card, Button } from '@shopify/polaris';
import { useTranslation } from 'react-i18next';
function SquareSyncPage({ merchantId }) {
  const { t } = useTranslation();
  const handleSync = async () => {
    try {
      const { data } = await axios.post('/api/admin/square/sync', { merchant_id: merchantId }, {
        headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
      });
      alert(t('square_sync_completed', { count: data.transaction_count }));
    } catch (error) {
      alert(t('error_unauthorized'));
    }
  };
  return (
    <Card sectioned>
      <Button onClick={handleSync} aria-label={t('square_sync')}>
        {t('sync_square')}
      </Button>
    </Card>
  );
}
```

## Error Handling
- **Shopify API Rate Limits**:
```typescript
async retryShopifyCall(fn: () => Promise<any>, retries = 3) {
  try {
    const response = await fn();
    await redis.set(`rate_limit:{merchant_id}`, JSON.stringify(response.headers['x-shopify-api-request-limit']), 'EX', 60);
    if (response.headers['x-shopify-api-request-limit'].current >= 0.9 * response.headers['x-shopify-api-request-limit'].max) {
      const queue = new Queue('rate_limit_alerts', process.env.REDIS_URL);
      await queue.add('sns_alert', { merchant_id, type: 'shopify_api', current: response.headers['x-shopify-api-request-limit'].current });
    }
    return response;
  } catch (error) {
    if (error.statusCode === 429 && retries > 0) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      return this.retryShopifyCall(fn, retries - 1);
    }
    throw error;
  }
}
```
- **Webhook Validation**: Use `@shopify/shopify-api` HMAC verification.
- **Database Errors**: Use TypeORM transactions for atomicity (e.g., `points_transactions`, `audit_logs`).
- **Circuit Breakers**: Use `nestjs-circuit-breaker` for external integrations (Shopify, Klaviyo, Postscript, Square).
- **Logging**: Winston + Loki + Grafana for errors (alerts for median >1s, P95 >3s), PostHog for events.

## Analytics
**PostHog Events** (aligned with `Wireframes.txt`, `RFM.markdown`, `Sequence Diagrams.txt`):
- `points_earned`: `{ customer_id, points, merchant_id, order_id }`.
- `points_redeemed`: `{ customer_id, points_spent, reward_type, merchant_id, campaign_id }`.
- `referral_created`: `{ customer_id, merchant_id }`.
- `referral_status_viewed`: `{ customer_id, merchant_id }`.
- `referral_fallback_triggered`: `{ customer_id, merchant_id }`.
- `gdpr_request_submitted`: `{ customer_id, merchant_id, request_type }`.
- `analytics_viewed`: `{ merchant_id }`.
- `template_edited`: `{ merchant_id, template_type }`.
- `customer_import_initiated`: `{ merchant_id, imported_count }`.
- `rate_limit_viewed`: `{ merchant_id }`.
- `rfm_nudge_viewed`: `{ customer_id, merchant_id, nudge_type }`.
- `action_undone`: `{ admin_id, customer_id, merchant_id, transaction_id }`.
- `action_replayed`: `{ admin_id, customer_id, merchant_id, transaction_id }`.
- `admin_event_simulated`: `{ admin_id, customer_id, merchant_id, result_segment }`.
- `square_sync_triggered`: `{ admin_id, merchant_id, transaction_count }`.
- `offline_sync_completed`: `{ merchant_id, transaction_count }`.

## Deployment
**Docker Compose** (docker-compose.yml):
```yaml
services:
  points:
    image: LoyalNest-points
    build: ./points-service
    ports:
      - "3001:3001"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/LoyalNest
      - REDIS_URL=redis://redis:6379
      - LAUNCHDARKLY_SDK_KEY=${LAUNCHDARKLY_SDK_KEY}
  referrals:
    image: LoyalNest-referrals
    build: ./referrals-service
    ports:
      - "3002:3002"
    environment:
      - AWS_SES_ACCESS_KEY=${AWS_SES_ACCESS_KEY}
      - AWS_SES_SECRET_KEY=${AWS_SES_SECRET_KEY}
  analytics:
    image: LoyalNest-analytics
    build: ./analytics-service
    ports:
      - "3003:3003"
    environment:
      - LAUNCHDARKLY_SDK_KEY=${LAUNCHDARKLY_SDK_KEY}
  admin-core:
    image: LoyalNest-admin-core
    build: ./admin-core-service
    ports:
      - "3004:3004"
  admin-features:
    image: LoyalNest-admin-features
    build: ./admin-features-service
    ports:
      - "3006:3006"
    environment:
      - SQUARE_ACCESS_TOKEN=${SQUARE_ACCESS_TOKEN}
      - LAUNCHDARKLY_SDK_KEY=${LAUNCHDARKLY_SDK_KEY}
  auth:
    image: LoyalNest-auth
    build: ./auth-service
    ports:
      - "3005:3005"
  frontend:
    image: LoyalNest-frontend
    build: ./frontend-service
    ports:
      - "80:80"
  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=LoyalNest
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
  redis:
    image: redis:6
  nginx:
    image: nginx:latest
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - /etc/letsencrypt:/etc/letsencrypt
```
**Dockerfile Example** (points-service/Dockerfile):
```dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
CMD ["npm", "run", "start:prod"]
```
**Nginx Configuration** (nginx.conf):
```nginx
http {
  server {
    listen 443 ssl;
    server_name LoyalNest.example.com;
    ssl_certificate /etc/letsencrypt/live/LoyalNest.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/LoyalNest.example.com/privkey.pem;
    location /points { proxy_pass http://points:3001; }
    location /referrals { proxy_pass http://referrals:3002; }
    location /analytics { proxy_pass http://analytics:3003; }
    location /admin { proxy_pass http://admin-core:3004; }
    location /admin/features { proxy_pass http://admin-features:3006; }
    location /auth { proxy_pass http://auth:3005; }
    location / { proxy_pass http://frontend:80; }
  }
}
```
**Certbot Configuration**:
```bash
certbot certonly --standalone -d LoyalNest.example.com
certbot renew --dry-run
```
**Railway**: Host PostgreSQL/Redis for production, initialize with `init.sql`.
**Kubernetes** (for Plus merchants):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: LoyalNest-points
spec:
  replicas: 3
  selector:
    matchLabels:
      app: points
  template:
    metadata:
      labels:
        app: points
    spec:
      containers:
      - name: points
        image: LoyalNest-points:latest
        ports:
        - containerPort: 3001
        env:
        - name: DATABASE_URL
          value: postgres://user:pass@db:5432/LoyalNest
        - name: REDIS_URL
          value: redis://redis:6379
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: LoyalNest-points-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: LoyalNest-points
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Dependencies
**Backend**:
```bash
npm install @nestjs/core @nestjs/typeorm typeorm pgx ioredis @shopify/shopify-api @klaviyo/node postscript-sdk bull @hapi/joi uuid winston @nestjs/swagger @nestjs/grpc @nestjs/schedule aws-sdk launchdarkly-node-server-sdk nestjs-circuit-breaker
```
**Frontend**:
```bash
npm install react@18.3.1 react-dom@18.3.1 @shopify/app-bridge-react @shopify/polaris tailwindcss axios posthog-js react-i18next
```
**Certbot**:
```bash
apt-get install certbot python3-certbot-nginx
```

## Security
- Validate Shopify OAuth tokens, RBAC (`merchants.staff_roles`), webhook HMAC.
- Encrypt `customers.email`, `customers.phone`, `merchants.api_token`, `reward_redemptions.discount_code`, `customers.rfm_score` (AES-256, `pgcrypto`).
- Store secrets in `.env` with `@nestjs/config`.
- Use HTTPS (Nginx, Certbot for SSL).
- OWASP ZAP for security testing.

## Scalability
- Redis Streams caching (`points:{customer_id}`, `config:{merchant_id}`, `rfm:preview:{merchant_id}`, `rfm:burst:{merchant_id}`, `campaign_discount:{campaign_id}`, `leaderboard:{merchant_id}`, `rate_limit:{merchant_id}`).
- Bull queue for notifications, customer imports, rate limit alerts.
- Partition `points_transactions`, `api_logs`, `referrals`, `reward_redemptions`, `customer_segments`, `audit_logs`, `simulation_logs` by `merchant_id`.
- Pagination for `customers`, `referral_links`, `api_logs`, `customer_segments`, `audit_logs`, `simulation_logs` (limit: 100).
- `pgx` for connection pooling (max 50 connections).
- gRPC for microservices (e.g., `/analytics.v1/AnalyticsService/PreviewRFMSegments`, `/points.v1/RedeemCampaignDiscount`, `/admin.v1/SyncSquarePOS`).
- Kubernetes Horizontal Pod Autoscaling (HPA) for Plus merchants (70% CPU utilization, 3–10 replicas).
- k6 for load testing (5,000 concurrent requests for admin, 1,000 for RFM simulations, 1,000 for Square syncs).

## Testing
- **Unit Tests** (Jest):
```typescript
describe('PointsService', () => {
  it('should award points for order', async () => {
    const points = await pointsService.awardPoints('c1', 'm1', 100);
    expect(points).toBe(1000);
  });
  it('should fail redemption with insufficient points', async () => {
    await expect(pointsService.redeemPoints('c1', 'm1', { reward_id: 'r1', points_cost: 2000 }))
      .rejects.toThrow('Insufficient points');
  });
  it('should calculate RFM score', async () => {
    const score = await analyticsService.calculateRFM('c1', 'm1');
    expect(score).toMatchObject({ recency: expect.any(Number), frequency: expect.any(Number), monetary: expect.any(Number) });
  });
});
```
- **E2E Tests** (Cypress):
```javascript
describe('Customer Widget', () => {
  it('displays points balance', () => {
    cy.intercept('GET', '/api/customer/points', { balance: 1000, rfm_score: { recency: 5, frequency: 4, monetary: 3 } });
    cy.visit('/customer');
    cy.contains('Your Points: 1000');
    cy.contains('RFM: R5 F4 M3');
  });
});
```
- **Performance Tests** (k6):
```javascript
import http from 'k6/http';
export default function () {
  http.get('https://LoyalNest.example.com/api/customer/points', {
    headers: { Authorization: 'Bearer test_token' }
  });
}
```
- **Accessibility**: Lighthouse CI (score 90+), ARIA labels, keyboard navigation, RTL support for `ar`, `he`.

## Additional Features
- **Freemium-to-Plus Funnel**: Feature flags (`rfm_simulation`, `rfm_advanced`) via LaunchDarkly, WebSocket (`/admin/v1/setup/stream`) for onboarding tasks.
- **Shopify Flow Integration**: Trigger workflows for RFM nudges, points awards, and referral completions.
- **Centralized Logging**: Loki + Grafana (alerts for median >1s, P95 >3s).
- **Disaster Recovery**: Daily PostgreSQL backups, Redis persistence, Kubernetes multi-zone deployment.
- **Merchant Community**: WebSocket-based forum for merchants (`/admin/v1/community/stream`).

## How to Use the Specs
- **Development**: Implement microservices (`PointsService`, `ReferralsService`, `AnalyticsService`, `AdminCoreService`, `AdminFeaturesService`) with TypeORM entities and gRPC. Use `init.sql` for database setup.
- **Swagger Docs**:
```bash
npm install @nestjs/swagger
```
- **gRPC Setup**:
```bash
npm install @nestjs/grpc grpc-tools
```
- **Demo**: Share with Shopify reviewers or beta merchants.

## Additional Notes
- **MVP Focus**: Prioritize `orders/create`, `pos/offline_sync`, `/api/customer/points`, `/api/redeem`, `/api/referral`, `/api/gdpr/request`, `/api/nudges`, `/api/admin/analytics`, `/api/admin/replay`, `/api/admin/rfm/simulate`, `/api/admin/square/sync`.
- **Extensibility**: Add endpoints for leaderboards (`/points.v1/GetLeaderboard`), gamification (`/points.v1/GetSetupTasks`), and merchant community (`/admin.v1/GetCommunity`).
- **Performance**: Monitor with PostHog, Loki + Grafana, `rfm_segment_counts` (daily refresh at `0 1 * * *`).
- **Accessibility**: ARIA labels, keyboard navigation, high-contrast mode, screen reader support for charts, RTL for `ar`, `he`.