```markdown
# LoyalNest App User Stories

## Customer Widget (Phase 1, 2, 3)

### Phase 1: Core Loyalty Features

**US-CW1: View Points Balance**
As a customer, I want to view my current points balance in the Customer Widget, so that I can track my loyalty rewards and plan redemptions.

**Acceptance Criteria**:
- Display points balance (e.g., "500 Stars") in widget using Tailwind CSS.
- Fetch balance from `customers.points_balance` via `GET /api/customer/points` with Shopify OAuth token.
- Update Redis cache (`points:customer:{customer_id}`) after fetching.
- Show error (e.g., "Unable to load balance") if API returns 401/404.
- Update balance display after earning/redemption.

**US-CW2: Earn Points from Purchase**
As a customer, I want to earn points automatically when I make a purchase, so that I can accumulate rewards for my loyalty.

**Acceptance Criteria**:
- Trigger `POST /api/points/earn` on Shopify `orders/create` webhook (HMAC validated).
- Insert record in `points_transactions` with `type="earn"`, partitioned by `merchant_id`.
- Update `customers.points_balance` and Redis cache (`points:customer:{customer_id}`).
- Log to PostHog (`points_earned` event).
- Display confirmation (e.g., "You earned 100 points!") in widget.
- Show error (e.g., "Invalid order") if webhook fails (400).

**US-CW3: Redeem Points for Discount**
As a customer, I want to redeem points for a discount (e.g., 10% off), so that I can save money on my purchases.

**Acceptance Criteria**:
- List available rewards from `rewards` table (`is_public=true`) via `GET /api/customer/points`.
- Call `POST /api/redeem` with `reward_id`, `customer_id`, Shopify OAuth token.
- Validate `customers.points_balance` >= `rewards.points_cost` in TypeORM transaction.
- Insert record in `reward_redemptions`, deduct points from `customers.points_balance`.
- Create Shopify discount code via Admin API.
- Update Redis cache (`points:customer:{customer_id}`).
- Log to PostHog (`points_redeemed` event).
- Display discount code or error (e.g., "Insufficient points" for 400).
- Handle Shopify API rate limits (429) with retry.

**US-CW4: Share Referral Link**
As a customer, I want to share a referral link via SMS, email, or social media, so that I can invite friends and earn rewards.

**Acceptance Criteria**:
- Generate unique `referral_code` via `POST /api/referral` with `advocate_customer_id`.
- Insert record in `referral_links` with `advocate_customer_id`, `merchant_id`.
- Display referral link and sharing options (SMS via Twilio, email via SendGrid, social).
- Queue notification via Bull for Twilio/SendGrid with `email_templates.body` (JSONB, `Accept-Language`).
- Log to PostHog (`referral_created` event).
- Show error (e.g., "Failed to share") if API returns 400/429.

**US-CW5: Earn Referral Reward**
As a customer, I want to earn points when a friend signs up using my referral link, so that I am rewarded for inviting others.

**Acceptance Criteria**:
- Friend signs up via `POST /api/referrals/complete` with `referral_code`, `friend_customer_id`.
- Validate `referral_code` in `referral_links`.
- Insert record in `referrals` with `advocate_customer_id`, `friend_customer_id`, `reward_id`.
- Insert `points_transactions` for advocate with `type="referral"`, partitioned by `merchant_id`.
- Update `customers.points_balance` and Redis cache for advocate.
- Queue reward notification via Bull (Twilio/SendGrid, `email_templates.body`).
- Log to PostHog (`referral_completed` event).
- Display confirmation in widget (e.g., "You earned 50 points!").
- Show error if `referral_code` is invalid (400).

**US-CW6: Adjust Points for Cancelled Order**
As a customer, I want my points balance to be adjusted if an order is cancelled, so that my balance reflects accurate purchases.

**Acceptance Criteria**:
- Trigger `POST /webhooks/orders/cancelled` on Shopify webhook (HMAC validated).
- Query `points_transactions` for `order_id`, `type="earn"`.
- Insert `points_transactions` with `type="adjust"`, negative points, partitioned by `merchant_id`.
- Update `customers.points_balance` and Redis cache (`points:customer:{customer_id}`).
- Log to PostHog (`points_adjusted` event).
- Display updated balance in widget.
- Handle case where no transaction exists (no-op).

### Phase 2: Enhanced Features

**US-CW7: View VIP Tier Status**
As a customer, I want to view my VIP tier status and progress, so that I can understand my benefits and strive for higher tiers.

**Acceptance Criteria**:
- Display current tier and progress (e.g., "Silver, $100/$500 to Gold") from `customers.vip_tier_id`, `vip_tiers.threshold_value`.
- Call `GET /api/vip-tiers/status` with Shopify OAuth token.
- Show perks from `vip_tiers.perks` (JSONB, `Accept-Language`).
- Update display after tier change via webhook.
- Show error if API fails (404).

**US-CW8: Receive RFM Nudges**
As a customer, I want to receive nudges encouraging engagement (e.g., "Stay Active!"), so that I remain active in the loyalty program.

**Acceptance Criteria**:
- Display nudge from `nudges` table (`title` in JSONB, `Accept-Language`) based on `customers.rfm_score`.
- Log interaction in `nudge_events` via `POST /api/nudges/trigger`.
- Show nudge as popup/banner in widget (Tailwind CSS).
- Allow dismissal, log to PostHog (`nudge_triggered` event).
- Handle missing nudge with fallback message.

### Phase 3: Advanced Features

**US-CW9: Earn Gamification Badges**
As a customer, I want to earn badges for actions (e.g., purchases, referrals), so that I feel motivated to engage with the program.

**Acceptance Criteria**:
- Trigger `POST /api/gamification/action` on qualifying action (e.g., purchase, referral).
- Insert badge in `gamification_achievements` with `metadata` (JSONB).
- Display badge in widget (e.g., "Loyal Customer") using Tailwind CSS.
- Log to PostHog (`badge_earned` event).
- Show error if action doesn’t qualify (400).

**US-CW10: View Leaderboard Rank**
As a customer, I want to view my rank on a leaderboard, so that I can compete with other customers.

**Acceptance Criteria**:
- Call `GET /api/gamification/leaderboard` with `customer_id`, fetch rank from `customers.points_balance`.
- Display rank in widget (e.g., "#5 of 100") using Tailwind CSS.
- Update rank after points change.
- Log to PostHog (`leaderboard_viewed` event).
- Show error if API fails (404).

**US-CW11: Select Language**
As a customer, I want to select my preferred language in the widget, so that I can interact in my native language.

**Acceptance Criteria**:
- Display language dropdown from `merchants.language` (JSONB).
- Send `Accept-Language` header in API calls (`GET /api/customer/points`).
- Update widget UI (e.g., points label, nudges) based on selection.
- Persist choice in browser session storage.
- Support at least English and Spanish.

## Merchant Dashboard (Phase 1, 2, 3)

### Phase 1: Core Management

**US-MD1: Complete Setup Tasks**
As a merchant, I want to complete setup tasks on the Welcome Page, so that I can launch my loyalty program.

**Acceptance Criteria**:
- Display tasks (e.g., "Launch Program", "Add Widget") from `program_settings.config` via Polaris components.
- Call `POST /api/settings/setup` to mark tasks complete, Shopify OAuth validated.
- Save progress in `program_settings.config` (JSONB).
- Show congratulatory message on completion using Polaris.
- Handle API errors (401, 400) with message.

**US-MD2: Configure Points Program**
As a merchant, I want to configure earning and redemption rules, so that I can customize the loyalty program.

**Acceptance Criteria**:
- Display form for earning rules (e.g., "10 points/$") and redemptions (e.g., "10% off: 200 points") using Polaris.
- Save to `program_settings.config` (JSONB) via `PUT /api/settings`, Shopify OAuth and `staff_roles` validated.
- Update Redis cache (`config:merchant:{merchant_id}`).
- Preview rewards panel branding in dashboard.
- Toggle program status (`program_settings.config.program_status`).
- Log to PostHog (`settings_updated` event).
- Handle invalid inputs (400) with error message.

**US-MD3: Manage Referrals Program**
As a merchant, I want to configure the referrals program, so that I can incentivize customer referrals.

**Acceptance Criteria**:
- Display form for SMS/email config and reward settings (e.g., "50 points for referral") using Polaris.
- Save to `program_settings.config` (JSONB) via `PUT /api/referrals/config`, OAuth validated.
- Update Redis cache (`config:merchant:{merchant_id}`).
- Preview referral popup in dashboard.
- Toggle referral program status.
- Log to PostHog (`referral_config_updated` event).
- Handle API errors (400) with message.

**US-MD4: View Customer List**
As a merchant, I want to view and search my customer list, so that I can manage customer data.

**Acceptance Criteria**:
- Display list from `customers` (name, encrypted `email`, `points_balance`, `rfm_score`) via `GET /api/customers`, OAuth validated.
- Allow search by name/email (decrypted via `pgcrypto`).
- Show customer details (e.g., points history) on click using Polaris.
- Handle empty list with message ("No customers found").
- Log to PostHog (`customer_list_viewed` event).

**US-MD5: View Basic Analytics**
As a merchant, I want to view basic analytics (e.g., members, points issued), so that I can monitor program performance.

**Acceptance Criteria**:
- Display metrics from `customers`, `points_transactions` via `GET /api/admin/analytics`, OAuth and `staff_roles` validated.
- Show RFM bar chart (Chart.js) from `customer_segments`, `customers.rfm_score` (JSONB).
- Log to PostHog (`analytics_viewed` event).
- Handle API errors (404, 429) with fallback message ("Data unavailable").

**US-MD6: Configure Store Settings**
As a merchant, I want to configure store details and billing, so that I can manage my account.

**Acceptance Criteria**:
- Display form for store name, billing plan (e.g., Free, $29/mo) from `merchants.plan_id` using Polaris.
- Save to `merchants` (e.g., `plan_id`, encrypted `api_token`) via `PUT /api/settings`, OAuth validated.
- Validate input fields (e.g., unique domain).
- Show confirmation on save.
- Log to PostHog (`store_settings_updated` event).

**US-MD7: Customize On-Site Content**
As a merchant, I want to customize loyalty page and popups, so that I can align with my brand.

**Acceptance Criteria**:
- Display editor for loyalty page, rewards panel, post-purchase widget using Polaris.
- Save branding to `program_settings.branding` (JSONB) via `PUT /api/content`, OAuth validated.
- Preview changes in real-time.
- Support multilingual content (`Accept-Language`, JSONB).
- Log to PostHog (`content_updated` event).
- Handle invalid inputs (400) with error message.

### Phase 2: Enhanced Management

**US-MD8: Configure VIP Tiers**
As a merchant, I want to set up VIP tiers based on spending, so that I can reward loyal customers.

**Acceptance Criteria**:
- Display form for tiers (e.g., "Gold: $500") and perks (JSONB) using Polaris.
- Save to `vip_tiers` via `POST /api/vip-tiers`, OAuth and `staff_roles` validated.
- Preview tier structure in dashboard.
- Queue customer notifications via Bull using `email_templates.body` (JSONB, `Accept-Language`).
- Log to PostHog (`vip_tier_created` event).
- Handle duplicate tiers (400) with error.

**US-MD9: View Activity Logs**
As a merchant, I want to view activity logs for points and referrals, so that I can track customer actions.

**Acceptance Criteria**:
- Display logs from `points_transactions`, `referrals` via `GET /api/logs`, OAuth validated.
- Filter by customer/date using Polaris filters.
- Show details (e.g., "John +200 points") in table.
- Handle empty logs with message ("No activity found").
- Log to PostHog (`logs_viewed` event).

**US-MD10: Configure RFM Settings**
As a merchant, I want to configure RFM thresholds, so that I can segment customers effectively.

**Acceptance Criteria**:
- Display wizard for recency, frequency, monetary thresholds using Polaris.
- Save to `program_settings.config` (JSONB) via `PUT /api/admin/rfm-config`, OAuth validated.
- Preview segment chart (Chart.js).
- Validate thresholds (e.g., positive integers).
- Log to PostHog (`rfm_config_updated` event).

**US-MD11: Manage Checkout Extensions**
As a merchant, I want to enable points display at checkout, so that customers can see their balance during purchase.

**Acceptance Criteria**:
- Toggle checkout extensions in settings using Polaris.
- Save to `program_settings.config` (JSONB) via `PUT /api/content`, OAuth validated.
- Preview points display via Shopify App Bridge.
- Integrate with Shopify `integrations` table.
- Log to PostHog (`checkout_extension_updated` event).

### Phase 3: Advanced Features

**US-MD12: Create Bonus Campaigns**
As a merchant, I want to create time-sensitive bonus campaigns, so that I can boost engagement.

**Acceptance Criteria**:
- Display form for campaign type (e.g., double points), dates, multiplier using Polaris.
- Save to `bonus_campaigns` via `POST /api/campaigns`, OAuth validated.
- Schedule campaign start/end using Bull queue.
- Show confirmation in dashboard.
- Log to PostHog (`campaign_created` event).

**US-MD13: Export Advanced Reports**
As a merchant, I want to export advanced analytics reports, so that I can analyze program performance.

**Acceptance Criteria**:
- Provide export button via `GET /api/analytics/export`, OAuth validated.
- Download CSV with `customer_segments`, `points_transactions`, `customers.rfm_score`.
- Show export progress and completion using Polaris.
- Log to PostHog (`analytics_exported` event).
- Handle large datasets with async processing.

**US-MD14: Configure Sticky Bar**
As a merchant, I want to enable a sticky bar for rewards, so that I can promote the loyalty program.

**Acceptance Criteria**:
- Display editor for sticky bar content (e.g., "Earn 10 points/$!") using Polaris.
- Save to `program_settings.branding` (JSONB) via `PUT /api/content`, OAuth validated.
- Preview sticky bar in dashboard.
- Toggle visibility and support multilingual content (`Accept-Language`).
- Log to PostHog (`sticky_bar_updated` event).

**US-MD15: Use Developer Toolkit**
As a merchant, I want to configure metafields via a developer toolkit, so that I can customize integrations.

**Acceptance Criteria**:
- Display form for metafield settings (e.g., Shopify metafields) using Polaris.
- Save to `integrations.settings` (JSONB) via `PUT /api/settings/developer`, OAuth validated.
- Validate metafield inputs (e.g., valid JSON).
- Show confirmation in dashboard.
- Log to PostHog (`developer_settings_updated` event).

**US-MD16: Customize Post-Purchase Widget**
As a merchant, I want to customize the post-purchase widget, so that I can engage customers after checkout.

**Acceptance Criteria**:
- Display editor for post-purchase widget (e.g., points display, nudge) using Polaris.
- Save to `program_settings.branding` (JSONB) via `PUT /api/content`, OAuth validated.
- Preview widget in dashboard.
- Support multilingual content (`Accept-Language`).
- Log to PostHog (`post_purchase_widget_updated` event).

## Admin Module (Phase 1, 2, 3)

### Phase 1: Core Admin Functions

**US-AM1: View Merchant Overview**
As an admin, I want to view an overview of all merchants, so that I can monitor platform usage.

**Acceptance Criteria**:
- Display metrics (merchant count, points issued) from `merchants`, `points_transactions` via `GET /api/admin/overview`, RBAC validated (`admin_users.metadata`).
- Show RFM chart (Chart.js) for aggregated `customers.rfm_score`.
- Log to PostHog (`overview_viewed` event).
- Handle API errors (401, 404) with message ("Data unavailable").

**US-AM2: Manage Merchant List**
As an admin, I want to view and search merchants, so that I can manage their accounts.

**Acceptance Criteria**:
- Display list from `merchants` (ID, `shopify_domain`, `plan_id`, `status`) via `GET /api/admin/merchants`, RBAC validated.
- Allow search by ID/domain using Polaris filters.
- Show details (e.g., plan, status) on click.
- Handle empty list with message ("No merchants found").
- Log to PostHog (`merchant_list_viewed` event).

**US-AM3: Adjust Customer Points**
As an admin, I want to adjust a customer's points balance, so that I can correct errors or provide bonuses.

**Acceptance Criteria**:
- Display form for points adjustment via `POST /api/admin/points/adjust`, RBAC validated.
- Insert record in `points_transactions` with `type="admin_adjust"`, partitioned by `merchant_id`.
- Update `customers.points_balance` and Redis cache (`points:customer:{customer_id}`).
- Log to `audit_logs` and PostHog (`points_adjusted` event).
- Show confirmation in admin module.
- Handle invalid inputs (400) with error.

**US-AM4: Manage Admin Users**
As an admin, I want to add, edit, or delete admin users, so that I can control platform access.

**Acceptance Criteria**:
- Display list from `admin_users` (username, encrypted `email`) via `GET /api/admin/users`, RBAC validated.
- Provide forms for add/edit/delete via `POST/PUT/DELETE /api/admin/users`.
- Validate unique username, email (decrypted via `pgcrypto`).
- Log actions in `audit_logs` and PostHog (`admin_user_updated` event).
- Show confirmation on save.

**US-AM5: View Logs**
As an admin, I want to view API and audit logs, so that I can monitor platform activity.

**Acceptance Criteria**:
- Display logs from `api_logs`, `audit_logs` via `GET /api/admin/logs`, RBAC validated.
- Filter by date/user using Polaris filters.
- Show details (e.g., "Points Adjust by Admin1") in table.
- Handle empty logs with message ("No logs found").
- Log to PostHog (`logs_viewed` event).

**US-AM6: Handle GDPR Data Request**
As an admin, I want to process customer data requests, so that I can comply with GDPR regulations.

**Acceptance Criteria**:
- Receive Shopify `customers/data_request` webhook, insert into `gdpr_requests` (`request_type="data_request"`).
- Query `customers`, `points_transactions`, `reward_redemptions` for customer data (encrypted `email`).
- Send data via SendGrid (Bull queue, `email_templates.body`, JSONB).
- Log to `audit_logs` and PostHog (`gdpr_request` event).
- Show request status in admin module.

### Phase 2: Enhanced Admin Functions

**US-AM7: Manage Merchant Plans**
As an admin, I want to upgrade or downgrade merchant plans, so that I can manage billing.

**Acceptance Criteria**:
- Display current plan from `merchants.plan_id` via `GET /api/admin/merchants`, RBAC validated.
- Provide form to change plan via `PUT /api/admin/plans`.
- Update `merchants.plan_id` and log in `audit_logs`.
- Log to PostHog (`plan_updated` event).
- Show confirmation in admin module.

**US-AM8: Monitor Integration Health**
As an admin, I want to check the health of integrations (e.g., Shopify, Twilio), so that I can ensure platform reliability.

**Acceptance Criteria**:
- Display status from `integrations` (e.g., `type`, `status`) via `GET /api/admin/integrations/health`, RBAC validated.
- Show status (e.g., "Shopify: OK") in admin module.
- Allow manual ping to external services (e.g., Shopify OAuth check).
- Log checks in `audit_logs` and PostHog (`integration_health_checked` event).

**US-AM9: Manage RFM Configurations**
As an admin, I want to manage RFM configurations for merchants, so that I can optimize segmentation.

**Acceptance Criteria**:
- Display RFM settings from `program_settings.config` (JSONB) via `GET /api/admin/rfm`, RBAC validated.
- Provide form to edit thresholds via `PUT /api/admin/rfm`.
- Preview segment chart (Chart.js).
- Log changes in `audit_logs` and PostHog (`rfm_config_updated` event).

**US-AM10: Suspend Merchant Account**
As an admin, I want to suspend or reactivate a merchant account, so that I can manage non-compliant merchants.

**Acceptance Criteria**:
- Display merchant status (`merchants.status`) via `GET /api/admin/merchants`, RBAC validated.
- Provide toggle to change status (`active`, `suspended`, `trial`) via `PUT /api/admin/merchants/status`.
- Update `merchants.status` and log in `audit_logs`.
- Log to PostHog (`merchant_status_updated` event).
- Show confirmation in admin module.

### Phase 3: Advanced Admin Functions

**US-AM11: Export RFM Segments**
As an admin, I want to export RFM segments for merchants, so that I can analyze customer behavior.

**Acceptance Criteria**:
- Provide export button via `GET /api/admin/rfm/export`, RBAC validated.
- Download CSV with `customer_segments`, `customers.rfm_score` (JSONB).
- Show export progress and completion using Polaris.
- Log to `audit_logs` and PostHog (`rfm_exported` event).
- Handle large datasets with async processing.

**US-AM12: Manage Advanced Integrations**
As an admin, I want to configure advanced integrations (e.g., Square, Lightspeed), so that I can support new platforms.

**Acceptance Criteria**:
- Display form for integration settings via `POST /api/admin/integrations`, RBAC validated.
- Save to `integrations.settings` (JSONB).
- Validate API keys (e.g., encrypted via `pgcrypto`).
- Log setup in `audit_logs` and PostHog (`integration_updated` event).
- Show confirmation in admin module.

## Backend Integrations (Phase 1, 2, 3)

**US-BI1: Sync Shopify Orders**
As a system, I want to sync orders from Shopify via webhooks, so that points are awarded automatically.

**Acceptance Criteria**:
- Receive `orders/create` webhook, validate HMAC, call `POST /api/points/earn`.
- Insert record in `points_transactions` (`type="earn"`, partitioned by `merchant_id`).
- Update `customers.points_balance` and Redis cache (`points:customer:{customer_id}`).
- Log to `api_logs` and PostHog (`points_earned` event).
- Handle duplicate orders (no-op) or invalid HMAC (400).

**US-BI2: Send Referral Notifications**
As a system, I want to send referral notifications via Twilio/SendGrid, so that customers are informed of rewards.

**Acceptance Criteria**:
- Fetch template from `email_templates.body` (JSONB, `Accept-Language`) via `GET /api/templates`.
- Queue notification via Bull for Twilio/SendGrid API.
- Log in `email_events` (`event_type="sent"`) and PostHog (`notification_sent` event).
- Handle API failures with retry logic (429).

**US-BI3: Import Customer Data (Phase 2)**
As a system, I want to import customer data from integrations, so that merchants can onboard existing customers.

**Acceptance Criteria**:
- Call `POST /api/data/import` with customer data (e.g., Shopify CSV).
- Insert records in `customers` (encrypted `email`), log in `import_logs`.
- Handle failures with `fail_reason` in `import_logs`.
- Log to `api_logs` and PostHog (`data_imported` event).
- Support async processing for large datasets.

**US-BI4: Apply Campaign Discounts (Phase 3)**
As a system, I want to apply discounts from bonus campaigns, so that customers receive promotional rewards.

**Acceptance Criteria**:
- Check `bonus_campaigns` for active campaigns via Rust/Wasm function (`calculate_points`).
- Apply multiplier to points in `points_transactions` (`type="earn"`).
- Update `customers.points_balance` and Redis cache.
- Log to `api_logs` and PostHog (`campaign_applied` event).
- Handle expired campaigns (no-op).

**US-BI5: Calculate RFM Scores (Phase 2)**
As a system, I want to calculate and update RFM scores for customers, so that merchants can segment customers effectively.

**Acceptance Criteria**:
- Run scheduled job to calculate `customers.rfm_score` (JSONB) based on `points_transactions`, `orders`.
- Update `customer_segments` and `customers.rfm_score` via `POST /api/rfm/update`.
- Log to `api_logs` and PostHog (`rfm_updated` event).
- Handle large datasets with async processing and partitioning.
```