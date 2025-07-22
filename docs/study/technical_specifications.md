# Technical Specifications: LoyalNest App

## Overview
LoyalNest is a Shopify app for small, medium, and Plus merchants (100–50,000+ customers, AOV $20–$500), offering a points-based loyalty program (e.g., 1000 points for $100 purchase, 200 points for 10% discount), SMS/email referrals, RFM segmentation, analytics, GDPR/CCPA compliance, and multilingual support (`en`, `es`, `fr`). This specification aligns with `Wireframes.txt`, `schema.txt`, `ERD.txt`, `RFM.markdown` (artifact_id: `b4ca549b-7ffa-42c3-9db2-9a4a74151dbf`), `feature_analytics.txt`, `user_stories.markdown`, `Flow Diagram.txt`, and `Sequence Diagrams.txt`.

### Tech Stack
- **Backend**: NestJS, TypeORM, PostgreSQL (JSONB, `pgx` pooling, `pgcrypto` for encryption), Redis (Bull for queues, Streams for RFM and previews).
- **Frontend**: Vite + React, Shopify Polaris (merchant dashboard), Tailwind CSS (customer widget), Shopify App Bridge, i18next (multilingual).
- **Integrations**: Shopify Admin API (webhooks, discounts), Klaviyo/Postscript (notifications), PostHog (analytics), Rust/Wasm (Shopify Functions for checkout points).
- **Deployment**: VPS with Docker Compose, Nginx, Certbot for SSL, Railway for PostgreSQL/Redis, gRPC for microservices.

## System Architecture
- **Microservices**:
  - **Points**: Manages points earning/redemption (`/points.v1/*`, `/points.v1/RedeemCampaignDiscount` for campaign discounts).
  - **Referrals**: Handles referral links and notifications (`/referrals.v1/*`).
  - **Analytics**: Processes RFM, metrics, and segment previews (`/analytics.v1/*`, `/analytics.v1/AnalyticsService/GetNudges`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`).
  - **Admin**: Manages merchants, plans, GDPR requests, and notification templates (`/admin.v1/*`).
  - **Auth**: Handles Shopify OAuth and RBAC (`/auth.v1/*`).
  - **Frontend**: Serves React UI with Polaris/Tailwind for RFM configuration, GDPR form, referral status, customer import, and rate limit monitoring.
- **Communication**: gRPC for microservices (e.g., Analytics ↔ Points for RFM-driven rewards), REST/GraphQL for Shopify/Frontend integration.
- **Database**: PostgreSQL with JSONB (`program_settings.config`, `email_templates.body`, `customers.rfm_score`, `bonus_campaigns.conditions`). Partitioned tables (`points_transactions`, `api_logs`, `referrals`, `reward_redemptions`, `customer_segments`) by `merchant_id`.
- **Caching**: Redis Streams for `points:{customer_id}`, `config:{merchant_id}`, `rfm:preview:{merchant_id}`, `campaign_discount:{campaign_id}`, `leaderboard:{merchant_id}`, `template:{merchant_id}:{template_type}`.
- **Queue**: Bull for SMS/email notifications and customer imports.
- **External Services**:
  - Shopify Admin API for customers, orders, discounts.
  - Klaviyo/Postscript for SMS/email notifications.
  - PostHog for analytics (points, redemptions, referrals, RFM interactions).
  - Shopify Functions (Rust/Wasm) for real-time points and RFM calculations.

## Database Schema
Refer to `schema.txt` (artifact_id: `11afb340-73c5-4e4c-81e1-f6e37ff2d6c5`) and `ERD.txt` (artifact_id: `bf6eb50c-fa5a-40a9-8981-788f175dd68f`). Key tables:
- **merchants**: `merchant_id` (PK), `shopify_domain` (UK), `plan_id` (FK), `api_token` (AES-256), `status` (CHECK: `'active', 'suspended', 'trial'`), `language` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`), `staff_roles` (JSONB).
- **customers**: `customer_id` (PK), `merchant_id` (FK), `shopify_customer_id`, `email` (AES-256), `points_balance`, `rfm_score` (JSONB), `vip_tier_id` (FK).
- **points_transactions**: `transaction_id` (PK), `customer_id` (FK), `merchant_id` (FK), `type` (CHECK: `'earn', 'redeem', 'expire', 'adjust'`), `points`, `order_id`. Partitioned by `merchant_id`.
- **rewards**: `reward_id` (PK), `merchant_id` (FK), `type`, `points_cost`, `value`, `is_public` (CHECK), `campaign_id` (FK, nullable, `US-BI4`).
- **referral_links**: `referral_link_id` (PK), `advocate_customer_id` (FK), `merchant_id` (FK), `referral_code`, `status` (CHECK: `'pending', 'completed', 'expired'`).
- **program_settings**: `merchant_id` (PK, FK), `points_currency_singular`, `config` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`), `rfm_thresholds` (JSONB).
- **gdpr_requests**: `request_id` (PK), `merchant_id` (FK), `customer_id` (FK), `request_type` (CHECK: `'data_request', 'redact'`), `retention_expires_at` (90 days).
- **email_templates**: `template_id` (PK), `merchant_id` (FK), `type`, `body` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`).
- **bonus_campaigns**: `campaign_id` (PK), `merchant_id` (FK), `name`, `type`, `multiplier`, `conditions` (JSONB, e.g., `{"rfm_score": {"recency": ">=4"}}` for RFM-driven discounts).
- **rfm_segment_counts**: Materialized view (`merchant_id`, `segment_name`, `customer_count`, `last_refreshed`, `US-MD12`), refreshed daily (`0 1 * * *`).

### Indexes
```sql
CREATE INDEX idx_customers_email ON customers USING btree (email);
CREATE INDEX idx_points_transactions_customer_id ON points_transactions USING btree (customer_id, created_at);
CREATE INDEX idx_api_logs_merchant_id_timestamp ON api_logs USING btree (merchant_id, timestamp);
CREATE INDEX idx_program_settings_config ON program_settings USING gin (config);
CREATE INDEX idx_referrals_notification_status ON referrals USING btree (notification_status);
CREATE INDEX idx_rfm_segment_counts ON rfm_segment_counts USING btree (merchant_id, last_refreshed);
CREATE INDEX idx_customers_rfm_score_at_risk ON customers USING btree (rfm_score) WHERE (rfm_score->>'score' < '2');
```

### Database Initialization (init.sql)
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

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
- Update `customers.points_balance`, Redis cache (`points:{customer_id}`, `campaign_discount:{campaign_id}`).
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
  "language": { "default": "en", "supported": ["en", "es", "fr"] },
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
- Update `program_settings.config`, `program_settings.rfm_thresholds`, `merchants.language` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`).
- Update Redis (`config:{merchant_id}`).
- Log to `api_logs`, PostHog (`settings_updated`).

### 4. POST /api/rewards (Points Service, gRPC: `/points.v1/AddReward`)
**Description**: Adds a new reward with optional RFM-driven campaign (`US-MD2`).
**Authentication**: Shopify OAuth (merchant session token).
**Request**:
```http
POST /api/rewards
Headers: Authorization: Bearer <shopify_token>
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
- Send SMS/email via Klaviyo/Postscript (queued via Bull).
- Log to `api_logs`, PostHog (`referral_created`).

### 6. GET /api/referral/status (Referrals Service, gRPC: `/referrals.v1/GetReferralStatus`)
**Description**: Retrieves referral status (`US-CW7`).
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
    { "referral_code": "REF_abc123", "status": "pending", "created_at": "2025-07-09T02:03:00Z" }
  ]
}
```
**Error Responses**:
- 401: Invalid token.
- 404: Customer not found.
**Logic**:
- Query `referral_links` by `advocate_customer_id`, `merchant_id`.
- Cache in Redis (`referral:{customer_id}`, TTL: 3600s).
- Log to `api_logs`, PostHog (`referral_status_viewed`).

### 7. POST /api/gdpr/request (Admin Service, gRPC: `/admin.v1/SubmitGDPRRequest`)
**Description**: Submits customer GDPR request (`US-CW8`).
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

### 8. POST /api/notifications/template (Admin Service, gRPC: `/admin.v1/UpdateNotificationTemplate`)
**Description**: Configures notification templates for points, referrals, or RFM nudges (`US-MD8`).
**Authentication**: Shopify OAuth (merchant session token).
**Request**:
```http
POST /api/notifications/template
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "type": "points_earned",
  "body": { "en": "You earned {points} points!", "es": "¡Ganaste {points} puntos!", "fr": "Vous avez gagné {points} points !" }
}
```
**Response**:
```json
{
  "template_id": "t1",
  "message": "Template updated"
}
```
**Error Responses**:
- 401: Invalid token.
- 400: Invalid template format.
**Logic**:
- Insert/update `email_templates` (`body` JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`).
- Update Redis (`template:{merchant_id}:{type}`).
- Log to `api_logs`, PostHog (`template_edited`).

### 9. POST /api/customers/import (Admin Service, gRPC: `/admin.v1/ImportCustomers`)
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
- Parse CSV, validate `email`, `shopify_customer_id`.
- Insert into `customers` (AES-256 for `email`).
- Queue points and RFM calculation via Bull.
- Log to `api_logs`, PostHog (`customer_import_initiated`).

### 10. GET /api/rate-limits (Admin Service, gRPC: `/admin.v1/GetRateLimits`)
**Description**: Monitors Shopify API and integration rate limits (`US-AM11`).
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
  "postscript": "OK"
}
```
**Error Responses**:
- 401: Invalid token or insufficient role.
**Logic**:
- Query Shopify API rate limit headers.
- Check Klaviyo/Postscript status.
- Cache in Redis (`rate_limit:{merchant_id}`, TTL: 60s).
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
- Queue notification via Klaviyo/Postscript.
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
- Insert `type: 'adjust'`, update `customers.points_balance`, Redis (`points:{customer_id}`).
- Trigger RFM recalculation via gRPC (`/analytics.v1/AnalyticsService/PreviewRFMSegments`).
- Log to `api_logs`, PostHog (`points_adjusted`).

### 3. customers/data_request (Admin Service)
**Description**: Handles GDPR data requests (`US-AM6`).
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
- Send data via Klaviyo/Postscript.
- Log to `api_logs`, PostHog (`gdpr_request`).

### 4. customers/redact (Admin Service)
**Description**: Handles GDPR redaction requests (`US-AM6`).
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

## Notifications
### Klaviyo/Postscript (SMS/Email)
**Trigger**: Points earned, referral created, VIP tier change, GDPR request, RFM nudges (`US-MD8`, `US-BI2`, `US-MD12`).
**Logic**:
- Fetch `customers.phone`, `customers.email`, `email_templates.body`, `nudges.title`, `nudges.description` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`).
- Queue via Bull.
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
**Integration**: Call from Points/Analytics Service, log to `points_transactions`, `customers.rfm_score`.

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
          aria-label={t('redeem') + ` ${r.points_cost} ${t('points')} ${r.value} ${r.type}`}
        >
          {t('redeem')} {r.points_cost} ${t('points')} ${r.value} ${r.type}
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
        <p key={r.referral_code}>{r.referral_code}: {t(r.status)}</p>
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
      <button onClick={() => handleSubmit('data_request')} aria-label={t('request_data')}>
        {t('request_data')}
      </button>
      <button onClick={() => handleSubmit('redact')} aria-label={t('delete_data')}>
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

## Error Handling
- **Shopify API Rate Limits**:
```typescript
async retryShopifyCall(fn: () => Promise<any>, retries = 3) {
  try {
    const response = await fn();
    await redis.set(`rate_limit:{merchant_id}`, JSON.stringify(response.headers['x-shopify-api-request-limit']), 'EX', 60);
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
- **Database Errors**: Use TypeORM transactions for atomicity.
- **Logging**: Winston for errors, PostHog for events.

## Analytics
**PostHog Events** (aligned with `Wireframes.txt`, `RFM.markdown`):
- `points_earned`: `{ customer_id, points, merchant_id, order_id }`.
- `points_redeemed`: `{ customer_id, points_spent, reward_type, merchant_id, campaign_id }`.
- `referral_created`: `{ customer_id, merchant_id }`.
- `referral_status_viewed`: `{ customer_id, merchant_id }`.
- `gdpr_request_submitted`: `{ customer_id, merchant_id, request_type }`.
- `analytics_viewed`: `{ merchant_id }`.
- `template_edited`: `{ merchant_id, template_type }`.
- `customer_import_initiated`: `{ merchant_id, imported_count }`.
- `rate_limit_viewed`: `{ merchant_id }`.
- `rfm_nudge_viewed`: `{ customer_id, merchant_id, nudge_type }`.

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
  referrals:
    image: LoyalNest-referrals
    build: ./referrals-service
    ports:
      - "3002:3002"
  analytics:
    image: LoyalNest-analytics
    build: ./analytics-service
    ports:
      - "3003:3003"
  admin:
    image: LoyalNest-admin
    build: ./admin-service
    ports:
      - "3004:3004"
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
    location /admin { proxy_pass http://admin:3004; }
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

## Dependencies
**Backend**:
```bash
npm install @nestjs/core @nestjs/typeorm typeorm pgx ioredis @shopify/shopify-api @klaviyo/node postscript-sdk bull @hapi/joi uuid winston @nestjs/swagger @nestjs/grpc
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
- Encrypt `customers.email`, `merchants.api_token`, `reward_redemptions.discount_code`, `customers.rfm_score` (AES-256, `pgcrypto`).
- Store secrets in `.env` with `@nestjs/config`.
- Use HTTPS (Nginx, Certbot for SSL).

## Scalability
- Redis Streams caching (`points:{customer_id}`, `config:{merchant_id}`, `rfm:preview:{merchant_id}`, `campaign_discount:{campaign_id}`, `leaderboard:{merchant_id}`).
- Bull queue for notifications and customer imports.
- Partition `points_transactions`, `api_logs`, `referrals`, `reward_redemptions`, `customer_segments` by `merchant_id`.
- Pagination for `customers`, `referral_links`, `api_logs`, `customer_segments` (limit: 100).
- `pgx` for connection pooling.
- gRPC for microservices (e.g., `/analytics.v1/AnalyticsService/PreviewRFMSegments`, `/points.v1/RedeemCampaignDiscount`).

## How to Use the Specs
- **Development**: Implement microservices (`PointsService`, `ReferralsService`, `AnalyticsService`, etc.) with TypeORM entities and gRPC. Use `init.sql` for database setup.
- **Swagger Docs**:
```bash
npm install @nestjs/swagger
```
- **gRPC Setup**:
```bash
npm install @nestjs/grpc grpc-tools
```
- **Testing**:
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
- **Demo**: Share with Shopify reviewers or beta merchants.

## Additional Notes
- **MVP Focus**: Prioritize `orders/create`, `/api/customer/points`, `/api/redeem`, `/api/referral`, `/api/gdpr/request`, `/api/nudges`, `/api/admin/analytics`.
- **Extensibility**: Add endpoints for RFM (`/analytics.v1/AnalyticsService/GetNudges`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`), leaderboards (`/points.v1/GetLeaderboard`).
- **Performance**: Monitor with PostHog, Winston logs, `rfm_segment_counts` (daily refresh at `0 1 * * *`).
- **Accessibility**: ARIA labels, keyboard navigation, high-contrast mode, screen reader support for charts.