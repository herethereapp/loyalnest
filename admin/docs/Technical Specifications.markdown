```markdown
# Technical Specifications: LoyalNest App

## Overview
The LoyalNest App is a Shopify app for small, medium, and Plus merchants (100–50,000+ customers, AOV $20–$500), providing a points-based loyalty program, SMS referrals, RFM segmentation, and analytics. This specification focuses on the points program (e.g., 1000 points for a $100 purchase, 200 points for a 10% discount), referrals, and admin features, aligning with the ERD (`docs/erd/loyalnest.dbml`) and schema (`schema.sql`).

### Tech Stack
- **Backend**: NestJS, TypeORM, PostgreSQL (JSONB), Redis (Bull for queues).
- **Frontend**: Vite + React, Shopify Polaris (merchant dashboard), Tailwind CSS (customer widget), Shopify App Bridge.
- **Integrations**: Shopify Admin API (webhooks, discounts), Twilio (SMS), SendGrid (email), PostHog (analytics), Rust/Wasm (Shopify Functions for checkout points).
- **Deployment**: VPS with Docker Compose, Nginx, Railway for PostgreSQL/Redis.

## System Architecture
- **Backend**: NestJS handles API requests, Shopify webhooks, and business logic. TypeORM with `pgx` connection pooling manages PostgreSQL queries. Redis caches points balances, configs, and queues notifications (Bull).
- **Frontend**: React with Vite serves the merchant dashboard (`SettingsPage`, `RewardsPage` with Polaris) and customer widget (`PointsBalance`, `RedeemForm` with Tailwind). Shopify App Bridge handles authentication and Shopify UI integration.
- **Database**: PostgreSQL with JSONB for flexible settings (e.g., `program_settings.config`, `customers.rfm_score`). Partitioned tables (`points_transactions`, `api_logs`) for Plus-scale performance.
- **External Services**:
  - Shopify Admin API for customers, orders, and discount codes.
  - Twilio for SMS notifications (referrals, points).
  - SendGrid for email notifications.
  - PostHog for analytics (points, redemptions, referrals).
  - Shopify Functions (Rust/Wasm) for real-time points calculation (optional for MVP).

## Database Schema
Refer to the updated ERD (`docs/erd/loyalnest.dbml`) and `schema.sql`. Key tables:
- **merchants**: `merchant_id` (PK), `shopify_domain` (UK), `plan_id` (FK to `plans`), `api_token` (encrypted), `status` (CHECK: `'active', 'suspended', 'trial'`), `language` (JSONB), `staff_roles` (JSONB).
- **customers**: `customer_id` (PK), `merchant_id` (FK), `shopify_customer_id`, `email` (encrypted), `points_balance`, `rfm_score` (JSONB), `vip_tier_id` (FK).
- **points_transactions**: `transaction_id` (PK), `customer_id` (FK), `merchant_id` (FK), `type` (CHECK: `'earn', 'redeem', 'expire', 'adjust'`), `points`, `order_id`. Partitioned by `merchant_id`.
- **rewards**: `reward_id` (PK), `merchant_id` (FK), `type`, `points_cost`, `value`, `is_public` (CHECK).
- **program_settings**: `merchant_id` (PK, FK), `points_currency_singular`, `config` (JSONB, e.g., `{"points_per_dollar": 10, "rewards": [...]}`).
- **gdpr_requests**: `request_id` (PK), `merchant_id` (FK), `customer_id` (FK), `request_type` (CHECK: `'data_request', 'redact'`).

### Indexes
```sql
CREATE INDEX idx_customers_email ON customers USING btree (email);
CREATE INDEX idx_points_transactions_customer_id ON points_transactions USING btree (customer_id, created_at);
CREATE INDEX idx_api_logs_merchant_id_timestamp ON api_logs USING btree (merchant_id, timestamp);
CREATE INDEX idx_program_settings_config ON program_settings USING gin (config);
```

## API Endpoints

### 1. GET /api/customer/points
**Description**: Retrieves a customer’s points balance, available rewards, and RFM score.
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
  "rfm_score": { "recency": 5, "frequency": 4, "monetary": 3 },
  "rewards": [
    { "reward_id": "r1", "points_cost": 200, "type": "DISCOUNT", "value": "10%" },
    { "reward_id": "r2", "points_cost": 500, "type": "FREE_SHIPPING", "value": "100%" }
  ]
}
```
**Error Responses**:
- 401: Invalid token.
- 404: Customer not found.
**Logic**:
- Check Redis (`points:customer:{customer_id}`).
- Query `customers.points_balance`, `customers.rfm_score`, and `rewards` (filtered by `is_public` and `merchant_id`).
- Cache result in Redis (TTL: 3600s).
**Example**:
```typescript
async getCustomerPoints(customerId: string, merchantId: string) {
  const cached = await redis.get(`points:customer:${customerId}`);
  if (cached) return JSON.parse(cached);
  const [customer] = await this.typeOrmRepository.query(
    'SELECT points_balance, rfm_score FROM customers WHERE customer_id = $1 AND merchant_id = $2',
    [customerId, merchantId]
  );
  if (!customer) throw new NotFoundException('Customer not found');
  const rewards = await this.typeOrmRepository.query(
    'SELECT reward_id, points_cost, type, value FROM rewards WHERE merchant_id = $1 AND is_public = true',
    [merchantId]
  );
  const result = { balance: customer.points_balance, rfm_score: customer.rfm_score, rewards };
  await redis.set(`points:customer:${customerId}`, JSON.stringify(result), 'EX', 3600);
  return result;
}
```

### 2. POST /api/redeem
**Description**: Redeems points for a reward, creates a Shopify discount code.
**Authentication**: Shopify OAuth (customer session token).
**Request**:
```http
POST /api/redeem
Headers: Authorization: Bearer <shopify_token>
Body:
{
  "reward_id": "r1",
  "points_cost": 200
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
- 404: Reward not found.
- 429: Shopify API rate limit exceeded.
**Logic**:
- Validate `customers.points_balance >= points_cost`.
- Create Shopify discount code via Admin API.
- Insert into `points_transactions` (`type: 'redeem'`) and `reward_redemptions`.
- Update `customers.points_balance` and Redis cache.
- Log to `api_logs` and PostHog (`points_redeemed`).
**Example**:
```typescript
async redeemPoints(customerId: string, merchantId: string, dto: RedeemDto) {
  return await this.typeOrmRepository.transaction(async (manager) => {
    const [customer] = await manager.query(
      'SELECT points_balance FROM customers WHERE customer_id = $1 AND merchant_id = $2',
      [customerId, merchantId]
    );
    if (!customer) throw new NotFoundException('Customer not found');
    if (customer.points_balance < dto.points_cost) throw new BadRequestException('Insufficient points');
    const [reward] = await manager.query(
      'SELECT type, value FROM rewards WHERE reward_id = $1 AND merchant_id = $2',
      [dto.reward_id, merchantId]
    );
    if (!reward) throw new NotFoundException('Reward not found');
    const shopify = new Shopify({ shopName: merchantId, accessToken: process.env.SHOPIFY_ACCESS_TOKEN });
    const discount = await this.retryShopifyCall(() =>
      shopify.discountCode.create({
        code: `LOYALTY_${uuidv4()}`,
        discount_type: reward.type.toLowerCase(),
        value: reward.value.replace('%', '')
      })
    );
    await manager.query(
      'UPDATE customers SET points_balance = points_balance - $1 WHERE customer_id = $2; ' +
      'INSERT INTO points_transactions (transaction_id, customer_id, merchant_id, type, points, created_at) ' +
      'VALUES ($3, $2, $4, \'redeem\', $1, NOW()); ' +
      'INSERT INTO reward_redemptions (redemption_id, customer_id, reward_id, merchant_id, discount_code, points_spent, status, issued_at) ' +
      'VALUES ($5, $2, $6, $4, $7, $1, \'issued\', NOW())',
      [dto.points_cost, customerId, uuidv4(), merchantId, uuidv4(), dto.reward_id, discount.code]
    );
    await redis.set(`points:customer:${customerId}`, customer.points_balance - dto.points_cost, 'EX', 3600);
    posthog.capture('points_redeemed', { customer_id: customerId, points_spent: dto.points_cost, reward_type: reward.type, merchant_id: merchantId });
    return { discount_code: discount.code, new_balance: customer.points_balance - dto.points_cost };
  });
}
```

### 3. POST /api/settings
**Description**: Updates merchant points program settings (e.g., points_per_dollar).
**Authentication**: Shopify OAuth (merchant session token).
**Request**:
```http
POST /api/settings
Headers: Authorization: Bearer <shopify_token>, Accept-Language: en
Body:
{
  "points_per_dollar": 10,
  "program_status": "active",
  "language": { "default": "en", "supported": ["en", "es"] }
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
- Update `program_settings.config` and `merchants.language` using JSONB.
- Update Redis cache (`config:merchant:{merchant_id}`).
- Log to `api_logs` and PostHog (`settings_updated`).
**Example**:
```typescript
async updateSettings(merchantId: string, dto: SettingsDto) {
  await this.typeOrmRepository.transaction(async (manager) => {
    await manager.query(
      'UPDATE program_settings SET config = jsonb_set(jsonb_set(config, \'{points_per_dollar}\', to_jsonb($1::int)), \'{program_status}\', to_jsonb($2)) WHERE merchant_id = $3',
      [dto.points_per_dollar, dto.program_status, merchantId]
    );
    await manager.query(
      'UPDATE merchants SET language = $1 WHERE merchant_id = $2',
      [JSON.stringify(dto.language), merchantId]
    );
  });
  await redis.set(`config:merchant:${merchantId}`, JSON.stringify(dto), 'EX', 3600);
  posthog.capture('settings_updated', { merchant_id: merchantId, points_per_dollar: dto.points_per_dollar });
  return { message: 'Settings updated' };
}
```

### 4. POST /api/rewards
**Description**: Adds a new reward to the merchant’s configuration.
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
  "is_public": true
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
- Insert into `rewards` table.
- Update Redis cache (`config:merchant:{merchant_id}`).
- Log to `api_logs` and PostHog (`reward_added`).
**Example**:
```typescript
async addReward(merchantId: string, dto: RewardDto) {
  const rewardId = uuidv4();
  await this.typeOrmRepository.query(
    'INSERT INTO rewards (reward_id, merchant_id, type, points_cost, value, is_combinable, is_public, created_at) ' +
    'VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())',
    [rewardId, merchantId, dto.type, dto.points_cost, dto.value, dto.is_combinable || false, dto.is_public]
  );
  await redis.del(`config:merchant:${merchantId}`);
  posthog.capture('reward_added', { merchant_id: merchantId, reward_id: rewardId, type: dto.type });
  return { reward_id: rewardId, message: 'Reward added' };
}
```

### 5. POST /api/referral
**Description**: Creates an SMS referral link for a customer.
**Authentication**: Shopify OAuth (customer session token).
**Request**:
```http
POST /api/referral
Headers: Authorization: Bearer <shopify_token>
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
- 404: Customer or merchant not found.
**Logic**:
- Insert into `referral_links` with a unique `referral_code`.
- Send SMS via Twilio with the referral URL.
- Log to `api_logs` and PostHog (`referral_created`).
**Example**:
```typescript
async createReferral(dto: ReferralDto) {
  const referralCode = `REF_${uuidv4().slice(0, 8)}`;
  await this.typeOrmRepository.query(
    'INSERT INTO referral_links (referral_link_id, advocate_customer_id, merchant_id, referral_code, created_at) ' +
    'VALUES ($1, $2, $3, $4, NOW())',
    [uuidv4(), dto.advocate_customer_id, dto.merchant_id, referralCode]
  );
  const [customer] = await this.typeOrmRepository.query(
    'SELECT phone FROM customers WHERE customer_id = $1 AND merchant_id = $2',
    [dto.advocate_customer_id, dto.merchant_id]
  );
  if (customer.phone) {
    const client = require('twilio')(process.env.TWILIO_SID, process.env.TWILIO_TOKEN);
    await client.messages.create({
      body: `Share your referral link: https://${dto.merchant_id}/ref/${referralCode}`,
      from: process.env.TWILIO_PHONE,
      to: customer.phone
    });
  }
  posthog.capture('referral_created', { customer_id: dto.advocate_customer_id, merchant_id: dto.merchant_id });
  return { referral_code: referralCode, referral_url: `https://${dto.merchant_id}/ref/${referralCode}` };
}
```

### 6. GET /api/admin/analytics
**Description**: Retrieves analytics for merchant (e.g., points earned, redemptions).
**Authentication**: Shopify OAuth (merchant session token, RBAC: `admin` or `analytics` role).
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
  "top_customers": [
    { "customer_id": "c1", "points_earned": 5000, "rfm_score": { "recency": 5, "frequency": 4, "monetary": 3 } }
  ]
}
```
**Error Responses**:
- 401: Invalid token or insufficient role.
- 400: Invalid date range.
**Logic**:
- Check `merchants.staff_roles` for RBAC.
- Query `points_transactions`, `reward_redemptions`, `customers.rfm_score`.
- Aggregate with PostHog data.
**Example**:
```typescript
async getAnalytics(merchantId: string, startDate: string, endDate: string) {
  const [staff] = await this.typeOrmRepository.query(
    'SELECT staff_roles FROM merchants WHERE merchant_id = $1',
    [merchantId]
  );
  if (!staff.staff_roles?.roles?.includes('analytics')) throw new UnauthorizedException('Insufficient permissions');
  const pointsData = await this.typeOrmRepository.query(
    'SELECT SUM(points) as points_earned, COUNT(*) as transactions_count ' +
    'FROM points_transactions WHERE merchant_id = $1 AND type = \'earn\' AND created_at BETWEEN $2 AND $3',
    [merchantId, startDate, endDate]
  );
  const redemptionData = await this.typeOrmRepository.query(
    'SELECT SUM(points_spent) as points_redeemed, COUNT(*) as redemptions_count ' +
    'FROM reward_redemptions WHERE merchant_id = $1 AND issued_at BETWEEN $2 AND $3',
    [merchantId, startDate, endDate]
  );
  const topCustomers = await this.typeOrmRepository.query(
    'SELECT c.customer_id, SUM(pt.points) as points_earned, c.rfm_score ' +
    'FROM customers c JOIN points_transactions pt ON c.customer_id = pt.customer_id ' +
    'WHERE c.merchant_id = $1 AND pt.created_at BETWEEN $2 AND $3 ' +
    'GROUP BY c.customer_id, c.rfm_score ORDER BY points_earned DESC LIMIT 10',
    [merchantId, startDate, endDate]
  );
  return { ...pointsData[0], ...redemptionData[0], top_customers: topCustomers };
}
```

## Webhooks

### 1. orders/create
**Description**: Awards points for a purchase (e.g., 1000 points for $100).
**Endpoint**: `POST /webhooks/orders/create`
**Payload** (Shopify):
```json
{
  "id": "987654321",
  "total_price": "100.00",
  "customer": { "id": "123456789" },
  "shop_id": "store.myshopify.com"
}
```
**Logic**:
- Verify HMAC using `@shopify/shopify-api`.
- Fetch `points_per_dollar` from `program_settings.config`.
- Calculate points: `total_price * points_per_dollar`.
- Insert into `points_transactions` (`type: 'earn'`), update `customers.points_balance`.
- Update Redis cache.
- Check reward eligibility and queue notifications (Twilio/SendGrid).
- Log to `api_logs` and PostHog (`points_earned`).
**Example**:
```typescript
@Post('webhooks/orders/create')
async handleOrderCreate(@Body() payload: any, @Headers('x-shopify-hmac-sha256') hmac: string) {
  if (!this.shopifyService.verifyWebhook(payload, hmac)) throw new UnauthorizedException('Invalid webhook');
  const { total_price, customer, shop_id } = payload;
  const [config] = await this.typeOrmRepository.query(
    'SELECT config->\'points_per_dollar\' AS points_per_dollar FROM program_settings WHERE merchant_id = $1',
    [shop_id]
  );
  const points = parseFloat(total_price) * parseInt(config.points_per_dollar);
  await this.typeOrmRepository.transaction(async (manager) => {
    await manager.query(
      'INSERT INTO points_transactions (transaction_id, customer_id, merchant_id, type, points, order_id, created_at) ' +
      'VALUES ($1, $2, $3, \'earn\', $4, $5, NOW()); ' +
      'UPDATE customers SET points_balance = points_balance + $4 WHERE shopify_customer_id = $2 AND merchant_id = $3',
      [uuidv4(), customer.id, shop_id, points, payload.id]
    );
  });
  await redis.set(`points:customer:${customer.id}`, points, 'EX', 3600);
  await this.notifyCustomer(customer.id, shop_id, points);
  posthog.capture('points_earned', { customer_id: customer.id, points, merchant_id: shop_id, order_id: payload.id });
}
```

### 2. orders/cancelled
**Description**: Adjusts points for cancelled orders.
**Endpoint**: `POST /webhooks/orders/cancelled`
**Payload** (Shopify):
```json
{
  "id": "987654321",
  "customer": { "id": "123456789" },
  "shop_id": "store.myshopify.com"
}
```
**Logic**:
- Verify HMAC.
- Find `points_transactions` by `order_id` and `type: 'earn'`.
- Insert adjustment transaction (`type: 'adjust'`, negative points).
- Update `customers.points_balance` and Redis cache.
- Log to `api_logs` and PostHog (`points_adjusted`).
**Example**:
```typescript
@Post('webhooks/orders/cancelled')
async handleOrderCancelled(@Body() payload: any, @Headers('x-shopify-hmac-sha256') hmac: string) {
  if (!this.shopifyService.verifyWebhook(payload, hmac)) throw new UnauthorizedException('Invalid webhook');
  const { customer, shop_id, id } = payload;
  const [transaction] = await this.typeOrmRepository.query(
    'SELECT points, customer_id FROM points_transactions WHERE order_id = $1 AND type = \'earn\' AND merchant_id = $2',
    [id, shop_id]
  );
  if (transaction) {
    await this.typeOrmRepository.transaction(async (manager) => {
      await manager.query(
        'INSERT INTO points_transactions (transaction_id, customer_id, merchant_id, type, points, order_id, created_at) ' +
        'VALUES ($1, $2, $3, \'adjust\', $4, $5, NOW()); ' +
        'UPDATE customers SET points_balance = points_balance + $4 WHERE customer_id = $2 AND merchant_id = $3',
        [uuidv4(), transaction.customer_id, shop_id, -transaction.points, id]
      );
    });
    await redis.set(`points:customer:${transaction.customer_id}`, transaction.points, 'EX', 3600);
    posthog.capture('points_adjusted', { customer_id: transaction.customer_id, points: -transaction.points, merchant_id: shop_id });
  }
}
```

### 3. customers/data_request
**Description**: Handles GDPR data requests.
**Endpoint**: `POST /webhooks/customers/data_request`
**Payload** (Shopify):
```json
{
  "shop_id": "store.myshopify.com",
  "customer": { "id": "123456789", "email": "user@example.com" }
}
```
**Logic**:
- Verify HMAC.
- Insert into `gdpr_requests` (`request_type: 'data_request'`).
- Query `customers`, `points_transactions`, `reward_redemptions` for customer data.
- Send data to customer via SendGrid.
- Log to `api_logs` and PostHog (`gdpr_request`).
**Example**:
```typescript
@Post('webhooks/customers/data_request')
async handleDataRequest(@Body() payload: any, @Headers('x-shopify-hmac-sha256') hmac: string) {
  if (!this.shopifyService.verifyWebhook(payload, hmac)) throw new UnauthorizedException('Invalid webhook');
  const { shop_id, customer } = payload;
  await this.typeOrmRepository.query(
    'INSERT INTO gdpr_requests (request_id, merchant_id, customer_id, request_type, status, created_at) ' +
    'VALUES ($1, $2, $3, \'data_request\', \'pending\', NOW())',
    [uuidv4(), shop_id, customer.id]
  );
  const customerData = await this.typeOrmRepository.query(
    'SELECT c.*, (SELECT json_agg(pt) FROM points_transactions pt WHERE pt.customer_id = c.customer_id) as transactions, ' +
    '(SELECT json_agg(rr) FROM reward_redemptions rr WHERE rr.customer_id = c.customer_id) as redemptions ' +
    'FROM customers c WHERE c.customer_id = $1 AND c.merchant_id = $2',
    [customer.id, shop_id]
  );
  const sgMail = require('@sendgrid/mail');
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
  await sgMail.send({
    to: customer.email,
    from: 'support@herethere.dev',
    subject: 'Your Data Request',
    text: JSON.stringify(customerData, null, 2)
  });
  posthog.capture('gdpr_request', { customer_id: customer.id, merchant_id: shop_id, request_type: 'data_request' });
}
```

## Notifications

### Twilio SMS
**Trigger**: Points earned (`points_balance >= reward threshold`) or referral link created.
**Logic**:
- Fetch `customers.phone`, `program_settings.config`, `rewards`.
- Send SMS via Twilio (queued via Bull).
**Example**:
```typescript
async notifyCustomer(customerId: string, merchantId: string, points: number) {
  const [customer] = await this.typeOrmRepository.query(
    'SELECT points_balance, phone FROM customers WHERE customer_id = $1 AND merchant_id = $2',
    [customerId, merchantId]
  );
  const [rewards] = await this.typeOrmRepository.query(
    'SELECT * FROM rewards WHERE merchant_id = $1 AND is_public = true',
    [merchantId]
  );
  if (customer.phone && customer.points_balance >= rewards[0]?.points_cost) {
    const queue = new Queue('notifications', process.env.REDIS_URL);
    await queue.add('sms', {
      to: customer.phone,
      body: `You earned ${points} points! Redeem ${rewards[0].points_cost} for a ${rewards[0].value} discount.`,
      from: process.env.TWILIO_PHONE
    });
  }
}
```

### SendGrid Email
**Trigger**: Similar to SMS, using `customers.email`.
**Logic**:
- Fetch multilingual `email_templates.body` (JSONB) based on `Accept-Language`.
- Queue email via Bull.
**Example**:
```typescript
async notifyCustomerEmail(customerId: string, merchantId: string, language: string = 'en') {
  const [customer] = await this.typeOrmRepository.query(
    'SELECT email FROM customers WHERE customer_id = $1 AND merchant_id = $2',
    [customerId, merchantId]
  );
  const [template] = await this.typeOrmRepository.query(
    'SELECT body->>$2 AS body FROM email_templates WHERE merchant_id = $1 AND type = \'points_earned\'',
    [merchantId, language]
  );
  const queue = new Queue('notifications', process.env.REDIS_URL);
  await queue.add('email', {
    to: customer.email,
    from: 'support@herethere.dev',
    subject: 'Points Earned',
    text: template.body
  });
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
    Ok(Output { points })
}
```
**Integration**: Deploy via Shopify CLI, call from NestJS to log points.

## Frontend Components
### Customer Widget
- **PointsBalance**: Displays `points_balance` and `rfm_score` (Tailwind CSS).
```jsx
function PointsBalance({ balance, rfm_score }) {
  return (
    <div className="p-4 bg-white rounded shadow">
      <h2>Your Points: {balance}</h2>
      <p>RFM: R{rfm_score.recency} F{rfm_score.frequency} M{rfm_score.monetary}</p>
    </div>
  );
}
```
- **RedeemForm**: Form to redeem points (Tailwind CSS, Axios for API calls).
```jsx
function RedeemForm({ rewards }) {
  const handleRedeem = async (rewardId, pointsCost) => {
    const { data } = await axios.post('/api/redeem', { reward_id: rewardId, points_cost: pointsCost }, {
      headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
    });
    alert(`Discount Code: ${data.discount_code}`);
  };
  return (
    <div className="p-4 bg-white rounded shadow">
      {rewards.map(r => (
        <button key={r.reward_id} onClick={() => handleRedeem(r.reward_id, r.points_cost)}>
          Redeem {r.points_cost} points for {r.value} {r.type}
        </button>
      ))}
    </div>
  );
}
```

### Merchant Dashboard
- **SettingsPage**: Configure `points_per_dollar`, `program_status` (Polaris).
```jsx
import { Card, TextField, Button } from '@shopify/polaris';
function SettingsPage({ settings }) {
  const [pointsPerDollar, setPointsPerDollar] = useState(settings.points_per_dollar);
  const handleSave = async () => {
    await axios.post('/api/settings', { points_per_dollar: pointsPerDollar }, {
      headers: { Authorization: `Bearer ${getSessionToken(appBridge)}` }
    });
  };
  return (
    <Card sectioned>
      <TextField label="Points per Dollar" value={pointsPerDollar} onChange={setPointsPerDollar} />
      <Button onClick={handleSave}>Save</Button>
    </Card>
  );
}
```

## Error Handling
- **Shopify API Rate Limits**:
```typescript
async retryShopifyCall(fn: () => Promise<any>, retries = 3) {
  try {
    return await fn();
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
- **Logging**: Use Winston for API errors:
```typescript
import { createLogger, transports } from 'winston';
const logger = createLogger({
  transports: [new transports.File({ filename: 'api.log' })]
});
```

## Analytics
**PostHog Events**:
- `points_earned`: `{ customer_id, points, merchant_id, order_id }`.
- `points_redeemed`: `{ customer_id, points_spent, reward_type, merchant_id }`.
- `referral_created`: `{ customer_id, merchant_id }`.
- `gdpr_request`: `{ customer_id, merchant_id, request_type }`.
**Example**:
```javascript
posthog.capture('points_earned', { customer_id, points, merchant_id, order_id });
```

## Deployment
**Docker Compose**:
```yaml
services:
  backend:
    image: LoyalNest-backend
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/LoyalNest
      - REDIS_URL=redis://redis:6379
      - SHOPIFY_API_KEY
      - TWILIO_SID
      - SENDGRID_API_KEY
  frontend:
    image: LoyalNest-frontend
    ports:
      - "80:80"
  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=LoyalNest
  redis:
    image: redis:6
```
**Nginx**: Proxy to backend (`/api`) and frontend (`/`), enforce HTTPS.
**Railway**: Host PostgreSQL/Redis for production.

## Dependencies
**Backend**:
```bash
npm install @nestjs/core @nestjs/typeorm typeorm pgx ioredis @shopify/shopify-api twilio @sendgrid/mail bull @hapi/joi uuid winston @nestjs/swagger
```
**Frontend**:
```bash
npm install react@18.3.1 react-dom@18.3.1 @shopify/app-bridge-react @shopify/polaris tailwindcss axios posthog-js
```

## Security
- Validate Shopify OAuth tokens and webhook HMAC.
- Encrypt sensitive fields (`customers.email`, `merchants.api_token`) using `pgcrypto`.
- Store secrets in `.env` with `@nestjs/config`.
- Use HTTPS (Nginx) for all requests.

## Scalability
- Redis caching for `points_balance`, `program_settings.config`.
- Bull queue for notifications.
- Partition `points_transactions`, `api_logs`, `customer_segments` by `merchant_id`.
- Use `pgx` for connection pooling.

## How to Use the Specs
- **Development**: Implement `PointsService`, `RewardsService`, `ReferralService`, and `WebhookController` in NestJS. Use TypeORM entities from `schema.sql`.
- **Swagger Docs**:
```bash
npm install @nestjs/swagger
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
});
```
- **Demo**: Share with Shopify reviewers or beta merchants.

## Additional Notes
- **MVP Focus**: Prioritize `orders/create`, `/api/customer/points`, `/api/redeem`, `/api/referral`.
- **Extensibility**: Add endpoints for RFM (`GET /api/customer/rfm`) or admin analytics.
- **Performance**: Monitor with PostHog and Winston logs.
```