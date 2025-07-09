```markdown
# LoyalNest App User Stories

## Customer Widget (Phase 1, 2, 3)

### Phase 1: Core Loyalty Features

**US-CW1: View Points Balance**  
As a customer, I want to view my current points balance in the Customer Widget, so that I can track my loyalty rewards and plan redemptions.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Points Dashboard.

**Acceptance Criteria**:  
- Display points balance (e.g., "500 Stars") in widget using Tailwind CSS, localized via i18next (`en`, `es`, `fr`).  
- Fetch balance from `customers.points_balance` via `GET /v1/api/customer/points` (REST) or `/points.v1/PointsService/GetPointsBalance` (gRPC) with Shopify OAuth token.  
- Update Redis cache (`points:{customer_id}`) after fetching.  
- Show error (e.g., "Unable to load balance") if API returns 401/404, localized via `Accept-Language`.  
- Update balance display after earning/redemption within 1s.  
- Handle Shopify GraphQL API limits (50 points/s, 100 points/s Plus) with exponential backoff.  
- Log to PostHog (`points_balance_viewed` event, `ui_action:points_viewed` for UI interaction).  

**US-CW2: Earn Points from Purchase**  
As a customer, I want to earn points automatically when I make a purchase, so that I can accumulate rewards for my loyalty.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Purchase Confirmation.

**Acceptance Criteria**:  
- Trigger `POST /v1/api/points/earn` (REST) or `/points.v1/PointsService/EarnPoints` (gRPC) on Shopify `orders/create` webhook (HMAC validated).  
- Insert record in `points_transactions` with `type='earn'`, partitioned by `merchant_id`, apply RFM multiplier (`program_settings.rfm_thresholds`).  
- Update `customers.points_balance` and Redis cache (`points:{customer_id}`).  
- Log to PostHog (`points_earned` event, `ui_action:purchase_completed` for UI confirmation).  
- Display confirmation (e.g., "You earned 100 points!") in widget, localized via i18next.  
- Show error (e.g., "Invalid order") if webhook fails (400) or rate limit exceeded (429, retry with exponential backoff).  
- Ensure transaction completes within 1s for 1,000 orders/hour (Plus-scale).  

**US-CW3: Redeem Points for Discount**  
As a customer, I want to redeem points for a discount (e.g., 10% off), so that I can save money on my purchases.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Rewards Redemption.

**Acceptance Criteria**:  
- List available rewards from `rewards` table (`is_public=true`) via `GET /v1/api/customer/points` (REST) or `/points.v1/PointsService/GetRewards` (gRPC).  
- Call `POST /v1/api/redeem` (REST) or `/points.v1/PointsService/RedeemReward` (gRPC) with `reward_id`, `customer_id`, Shopify OAuth token.  
- Validate `customers.points_balance` >= `rewards.points_cost` in TypeORM transaction.  
- Insert record in `reward_redemptions` (partitioned by `merchant_id`, `campaign_id` nullable), encrypt `discount_code` (AES-256).  
- Create Shopify discount code via GraphQL Admin API (Rust/Wasm for Plus).  
- Update `customers.points_balance` and Redis cache (`points:{customer_id}`).  
- Log to PostHog (`points_redeemed` event, `ui_action:reward_redeemed` for UI interaction).  
- Display discount code or localized error (e.g., "Insufficient points") for 400, using i18next.  
- Handle Shopify API rate limits (429, 2 req/s REST, 40 req/s Plus) with retry.  

**US-CW4: Share Referral Link**  
As a customer, I want to share a referral link via SMS, email, or social media, so that I can invite friends and earn rewards.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Referral Page.

**Acceptance Criteria**:  
- Generate unique `referral_code` via `POST /v1/api/referral` (REST) or `/referrals.v1/ReferralService/CreateReferral` (gRPC) with `advocate_customer_id`.  
- Insert record in `referral_links` (partitioned by `merchant_id`, `referral_link_id` as PK).  
- Display referral link and sharing options (SMS via Twilio, email via Klaviyo, social) in widget, localized via i18next.  
- Queue notification via Bull queue for Twilio/Klaviyo with `email_templates.body` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`).  
- Log to PostHog (`referral_created` event, `ui_action:referral_shared` for UI interaction).  
- Show localized error (e.g., "Failed to share") if API returns 400/429, with 3 retries.  
- Cache in Redis (`referral:{referral_code}`).  

**US-CW5: Earn Referral Reward**  
As a customer, I want to earn points when a friend signs up using my referral link, so that I am rewarded for inviting others.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Referral Confirmation.

**Acceptance Criteria**:  
- Friend signs up via `POST /v1/api/referrals/complete` (REST) or `/referrals.v1/ReferralService/CompleteReferral` (gRPC) with `referral_code`, `friend_customer_id`.  
- Validate `referral_code` in `referral_links` using `referral_link_id`.  
- Insert record in `referrals` (partitioned by `merchant_id`, `referral_link_id` as FK) with `advocate_customer_id`, `friend_customer_id`, `reward_id`.  
- Insert `points_transactions` for advocate with `type='referral'`, partitioned by `merchant_id`.  
- Update `customers.points_balance` and Redis cache (`points:{customer_id}`).  
- Queue reward notification via Bull (Klaviyo/Twilio, `email_templates.body`, `CHECK ?| ARRAY['en', 'es', 'fr']`).  
- Log to PostHog (`referral_completed` event, `ui_action:referral_reward_earned` for UI confirmation).  
- Display confirmation in widget (e.g., "You earned 50 points!"), localized via i18next.  
- Show localized error if `referral_code` is invalid (400).  

**US-CW6: Adjust Points for Cancelled Order**  
As a customer, I want my points balance to be adjusted if an order is cancelled, so that my balance reflects accurate purchases.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Points History.

**Acceptance Criteria**:  
- Trigger `POST /v1/api/webhooks/orders/cancelled` (REST) or `/points.v1/PointsService/AdjustPoints` (gRPC) on Shopify webhook (HMAC validated).  
- Query `points_transactions` for `order_id`, `type='earn'`.  
- Insert `points_transactions` with `type='adjust'`, negative points, partitioned by `merchant_id`.  
- Update `customers.points_balance` and Redis cache (`points:{customer_id}`).  
- Log to PostHog (`points_adjusted` event, `ui_action:points_adjusted_viewed` for UI update).  
- Display updated balance in widget within 1s.  
- Handle case where no transaction exists (no-op) or rate limit exceeded (429, retry).  

**US-CW7: View Referral Status**  
As a customer, I want to view the status of my referrals (e.g., pending, completed), so that I can track my referral rewards.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Referral Status Page.

**Acceptance Criteria**:  
- Display referral status (e.g., "Pending: John Doe") from `referrals` table via `GET /v1/api/referrals/status` (REST) or `/referrals.v1/ReferralService/GetReferralStatus` (gRPC) with `customer_id`, referencing `referral_link_id`.  
- Show details (friend name, status, reward) in widget using Tailwind CSS, localized via i18next.  
- Cache results in Redis (`referral_status:{customer_id}`).  
- Log to PostHog (`referral_status_viewed` event, `ui_action:referral_status_viewed` for UI interaction).  
- Show localized error (e.g., "No referrals found") if API returns 404.  
- Handle Shopify API rate limits (50 points/s, 100 points/s Plus) with exponential backoff.  

**US-CW8: Request GDPR Data Access/Deletion**  
As a customer, I want to request access to or deletion of my data via the widget, so that I can exercise my privacy rights.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - GDPR Request Form.

**Acceptance Criteria**:  
- Display GDPR request form (data access, deletion) in widget via Tailwind CSS, localized via i18next.  
- Submit request via `POST /v1/api/gdpr` (REST) or `/admin.v1/AdminService/ProcessGDPRRequest` (gRPC) with `customer_id`, `request_type`.  
- Insert record in `gdpr_requests` (`request_type='data_request'|'redact'`, partitioned by `merchant_id`).  
- Notify customer via Klaviyo (3 retries, `email_templates.body`, `CHECK ?| ARRAY['en', 'es', 'fr']`) using Redis Streams (`notification:{customer_id}`).  
- Log to PostHog (`gdpr_request_submitted` event, `ui_action:gdpr_form_submitted` for UI interaction).  
- Show confirmation (e.g., "Request submitted") or localized error (400).  
- Ensure 90-day backup retention for compliance via Dockerized backup service.  

### Phase 2: Enhanced Features

**US-CW9: View VIP Tier Status**  
As a customer, I want to view my VIP tier status and progress, so that I can understand my benefits and strive for higher tiers.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - VIP Tier Dashboard.

**Acceptance Criteria**:  
- Display current tier and progress (e.g., "Silver, $100/$500 to Gold") from `customers.vip_tier_id`, `vip_tiers.threshold_value` via `GET /v1/api/vip-tiers/status` (REST) or `/points.v1/PointsService/GetVipTierStatus` (gRPC).  
- Show perks from `vip_tiers.perks` (JSONB, localized via i18next).  
- Update display after tier change via Shopify webhook (`orders/create`).  
- Cache in Redis (`tier:{customer_id}`).  
- Show localized error if API fails (404, "Tier data unavailable").  
- Log to PostHog (`vip_tier_viewed` event, `ui_action:vip_status_viewed` for UI interaction).  
- Handle Shopify API rate limits (50 points/s) with retry.  

**US-CW10: Receive RFM Nudges**  
As a customer, I want to receive nudges encouraging engagement (e.g., "Stay Active!"), so that I remain active in the loyalty program.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Nudge Popup/Banner.

**Acceptance Criteria**:  
- Display nudge from `nudges` table (`title`, `description` in JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`) based on `customers.rfm_score` and `rfm_segment_counts`.  
- Fetch via `GET /v1/api/nudges` (REST) or `/analytics.v1/AnalyticsService/GetNudges` (gRPC).  
- Log interaction (`view`, `click`, `dismiss`) in `nudge_events` (partitioned by `merchant_id`) via `POST /v1/api/nudges/action`.  
- Show nudge as popup/banner in widget (Tailwind CSS, i18next).  
- Cache in Redis (`nudge:{customer_id}`).  
- Allow dismissal, log to PostHog (`nudge_action` event, `ui_action:nudge_interacted` for UI interaction).  
- Handle missing nudge with fallback message ("No nudges available").  

### Phase 3: Advanced Features

**US-CW11: Earn Gamification Badges**  
As a customer, I want to earn badges for actions (e.g., purchases, referrals), so that I feel motivated to engage with the program.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Badges Section.

**Acceptance Criteria**:  
- Trigger `POST /v1/api/gamification/action` (REST) or `/analytics.v1/AnalyticsService/AwardBadge` (gRPC) on qualifying action (e.g., purchase, referral).  
- Insert badge in `gamification_achievements` (partitioned by `merchant_id`) with `badge` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`).  
- Display badge in widget (e.g., "Loyal Customer") using Tailwind CSS, localized via i18next.  
- Cache in Redis (`badge:{customer_id}`).  
- Log to PostHog (`badge_earned` event, `ui_action:badge_viewed` for UI interaction).  
- Show localized error if action doesn’t qualify (400, "Action not eligible").  

**US-CW12: View Leaderboard Rank**  
As a customer, I want to view my rank on a leaderboard, so that I can compete with other customers.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Leaderboard Page.

**Acceptance Criteria**:  
- Call `GET /v1/api/gamification/leaderboard` (REST) or `/analytics.v1/AnalyticsService/GetLeaderboard` (gRPC) with `customer_id`.  
- Fetch rank from Redis sorted set (`leaderboard:{merchant_id}`) based on `customers.points_balance`.  
- Display rank in widget (e.g., "#5 of 100") using Tailwind CSS, localized via i18next.  
- Update rank after points change within 1s using Redis sorted sets (J6).  
- Cache in Redis (`leaderboard_rank:{customer_id}`).  
- Log to PostHog (`leaderboard_viewed` event, `ui_action:leaderboard_viewed` for UI interaction).  
- Show localized error if API fails (404, "Leaderboard unavailable").  

**US-CW13: Select Language**  
As a customer, I want to select my preferred language in the widget, so that I can interact in my native language.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Settings Panel.

**Acceptance Criteria**:  
- Display language dropdown from `merchants.language` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr']`) via `GET /v1/api/widget/config` (REST) or `/frontend.v1/FrontendService/GetWidgetConfig` (gRPC).  
- Send `Accept-Language` header in API calls.  
- Update widget UI (e.g., points label, nudges) using i18next based on selection.  
- Persist choice in browser `localStorage`.  
- Support `en`, `es`, `fr` with fallback to `en`.  
- Log to PostHog (`language_selected` event, `ui_action:language_changed` for UI interaction).  

## Merchant Dashboard (Phase 1, 2, 3)

### Phase 1: Core Management

**US-MD1: Complete Setup Tasks**  
As a merchant, I want to complete setup tasks on the Welcome Page, so that I can launch my loyalty program.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Welcome Page.

**Acceptance Criteria**:  
- Display tasks (e.g., "Launch Program", "Add Widget", "Configure RFM") from `program_settings.config` (JSONB) via Polaris components.  
- Call `POST /v1/api/settings/setup` (REST) or `/admin.v1/AdminService/CompleteSetupTask` (gRPC) with Shopify OAuth and RBAC (`merchants.staff_roles`).  
- Save progress in `program_settings.config`, cache in Redis (`setup:{merchant_id}`).  
- Show localized congratulatory message on completion using Polaris, i18next.  
- Handle API errors (401, 400) with localized message.  
- Log to PostHog (`setup_task_completed` event, `ui_action:setup_task_clicked` for UI interaction).  

**US-MD2: Configure Points Program**  
As a merchant, I want to configure earning and redemption rules, so that I can customize the loyalty program.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Points Configuration.

**Acceptance Criteria**:  
- Display form for earning rules (e.g., "1 point/$") and redemptions (e.g., "$5 off: 500 points") using Polaris, localized via i18next.  
- Save to `program_settings.config` and `rewards` via `PUT /v1/api/points-program` (REST) or `/admin.v1/AdminService/UpdatePointsProgram` (gRPC), OAuth and RBAC validated.  
- Apply RFM multipliers (`program_settings.rfm_thresholds`).  
- Update Redis cache (`program:{merchant_id}`).  
- Preview rewards panel branding in dashboard.  
- Toggle program status (`program_settings.config.program_status`).  
- Log to PostHog (`points_config_updated` event, `ui_action:points_config_saved` for UI interaction).  
- Handle invalid inputs (400) with localized error.  
- Handle Shopify API rate limits (50 points/s) with retry.  

**US-MD3: Manage Referrals Program**  
As a merchant, I want to configure the referrals program, so that I can incentivize customer referrals.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Referrals Configuration.

**Acceptance Criteria**:  
- Display form for SMS/email config and reward settings (e.g., "50 points for referral") using Polaris, localized via i18next.  
- Save to `program_settings.config` (JSONB) via `PUT /v1/api/referrals/config` (REST) or `/referrals.v1/ReferralService/UpdateReferralConfig` (gRPC), OAuth and RBAC validated.  
- Update Redis cache (`referral_config:{merchant_id}`).  
- Preview referral popup in dashboard.  
- Toggle referral program status.  
- Log to PostHog (`referral_config_updated` event, `ui_action:referral_config_saved` for UI interaction).  
- Handle API errors (400, 429) with localized message.  

**US-MD4: View Customer List**  
As a merchant, I want to view and search my customer list, so that I can manage customer data.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Customer List.

**Acceptance Criteria**:  
- Display list from `customers` (name, AES-256 encrypted `email`, `points_balance`, `rfm_score`) via `GET /v1/api/customers` (REST) or `/analytics.v1/AnalyticsService/ListCustomers` (gRPC), OAuth and RBAC validated.  
- Allow search by name/email (decrypted via `pgcrypto`) with pagination.  
- Show customer details (points history, RFM segment from `rfm_segment_counts`) on click using Polaris.  
- Handle empty list with localized message ("No customers found").  
- Cache in Redis (`customer_list:{merchant_id}:{page}`).  
- Log to PostHog (`customer_list_viewed` event, `ui_action:customer_list_viewed` for UI interaction).  
- Support 50,000+ customers with partitioning by `merchant_id`.  

**US-MD5: View Basic Analytics**  
As a merchant, I want to view basic analytics (e.g., members, points issued), so that I can monitor program performance.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Analytics Dashboard.

**Acceptance Criteria**:  
- Display metrics (members, points issued, referral ROI) from `customers`, `points_transactions`, `referrals` via `GET /v1/api/analytics` (REST) or `/analytics.v1/GetAnalytics` (gRPC), OAuth and RBAC validated.  
- Show RFM bar chart (Chart.js) from `rfm_segment_counts` materialized view, refreshed daily (`0 2 * * *`).  
- Cache in Redis (`analytics:{merchant_id}`).  
- Log to PostHog (`analytics_viewed` event, `ui_action:analytics_viewed` for UI interaction).  
- Handle API errors (404, 429) with localized error (e.g., "Data unavailable").  
- Support Plus-scale queries under 1s with Redis Streams.  

**US-MD6: Configure Store Settings**  
As a merchant, I want to configure store details and billing, so that I can manage my account.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Store Settings.

**Acceptance Criteria**:  
- Display form for store name, billing plan (e.g., Free: 300 orders, $5/mo: 500 orders) from `merchants.plan_id` using Polaris.  
- Save to `merchants` (e.g., `plan_id`, AES-256 encrypted `api_token`) via `PUT /v1/api/settings` (REST) or `/admin.v1/AdminService/UpdateStoreSettings` (gRPC), OAuth and RBAC validated.  
- Validate input fields (e.g., unique `shopify_domain`).  
- Update Redis cache (`settings:{merchant_id}`).  
- Log to PostHog (`store_settings_updated` event, `ui_action:settings_updated` for UI interaction).  
- Show localized error in Polaris for invalid inputs (400).  
- Support multi-store for Plus merchants via Dockerized services.  

**US-MD7: Customize On-Site Content**  
As a merchant, I want to customize loyalty page and popups, so that I can align with my brand.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Content Editor.

**Acceptance Criteria**:  
- Display editor for loyalty page, rewards panel, post-purchase widget using Polaris, localized via i18next.  
- Save branding to `program_settings.settings` (JSONB, `CHECK ?| ARRAY['en', 'fr']`) via `PUT /v1/api/content` (REST) or `/frontend.v1/UpdateContent` (gRPC), OAuth and RBAC validated.  
- Preview changes in real-time in dashboard.  
- Cache in Redis (`content:{merchant_id}:{locale}`).  
- Log to PostHog (`content:layout` event, `ui_action:content_updated` for UI interaction).  
- Handle invalid inputs (400) with localized error.  

**US-MD8: Configure Notification Templates**  
As a merchant, I want to customize notification templates for referrals, points, and campaigns, so that I can align messaging with my brand.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Notification Editor.

**Acceptance Criteria**:  
- Display editor for `email_templates` (e.g., `type='referral_completed'`, `points_earned`) using Polaris, supporting `en`, `fr`.  
- Save to `email_templates.subject`, `body.body` (JSONB, `CHECK ?| ARRAY['content']`) via `PUT /v1/api/templates` (REST) or `/admin.v1/UpdateNotificationService` (gRPC), OAuth and RBAC validated.  
- Preview template in dashboard.  
- Cache in Redis (`template:{email_templates}:{merchant_id}`).  
- Log to PostHog (`template:updated`, `ui_action:template_updated` for UI interaction).  
- Handle invalid JSONB inputs (400) with localized error.  

### Phase 8: Advanced Management

**US-MD9: Configure VIP Tiers**  
As a merchant, I want to set up VIP tiers based on spending, so that I can reward loyal customers.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - VIP Tier Configuration.

**Acceptance Criteria**:  
- Display form for tiers (e.g., "Gold: $50") and perks (JSONB, `CHECK ?| ARRAY['perks']`) using Polaris.  
- Save to `vip_tiers` (partitioned by `merchant_id`) via `POST /v1/admin/vip-tiers` (REST) or `/admin.v1/CreateTierService` (gRPC), OAuth and RBAC validated.  
- Apply RFM-driven multiplier (`program_settings.rfm_thresholds`) from `rfm_segment_counts`.  
- Preview tier structure in UI.  
- Queue customer notification via Bull using `email_templates.body` (JSONB, i18next).  
- Cache in Redis (`tiers:{merchant_id}`).  
- Log to PostHog (`tier:created`, `ui_action:tier_created` for UI interaction).  
- Handle duplicate tiers (400) with localized error.  

**US-MD10: View Activity Logs**  
As a merchant, I want to view activity logs for points, referrals, and tier changes, so that I can track customer actions.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Activity Logs.

**Acceptance Criteria**:  
- Display logs from `points_transactions`, `referrals`, `audit_logs.logs` (e.g., `action:tier_assigned`, `config:updated`) via `GET /v1/api/logs` (REST) or `/analytics.v1/ListActivityService` (gRPC), OAuth and RBAC validated.  
- Filter by `uid`/date/action using Polaris.  
- Show details (e.g., "John: +200 points") in table, localized via i18next.  
- Handle empty logs with localized error ("No activity").  
- Cache in Redis (`logs:{merchant_id}:{page}`).  
- Log to PostHog (`logs:viewed`, `ui_action:logs_viewed`).  
- Support Plus-scale with partitioning by `merchant_id`.  

**US-MD11: Configure RFM Settings**  
As a merchant, I want to configure RFM thresholds, so that I can segment customers effectively.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - RFM Configuration.

**Acceptance Criteria**:  
- Display wizard for recency, frequency, monetary thresholds (weights: 30% recency, 40% frequency, 30% monetary) using Polaris.  
- Save to `program_settings.rtm_thresholds` (JSONB) via `PUT /v1/api/rfm/config` (REST) or `/admin.v1/UpdateRFMService` (gRPC), OAuth and RBAC validated.  
- Preview segment chart (Chart.js) using `rfm_segment_counts` materialized view.  
- Validate thresholds (e.g., recency < 360 days).  
- Cache in Redis (`rfm:preview:{merchant_id}`).  
- Log to PostHog (`rfm:updated`, `ui_action:rfm_config_updated`).  
- Handle invalid inputs (400) with localized error.  

**US-MD12: Preview RFM Segment Distribution**  
As a REST, I want to GET RFM segment distributions, so that I can understand customer segments before applying settings.  
**Service**: Analytics Service (GET: `/analytics.v1/*`, Dockerized).  
**Wireform**: RFM12 - RFM Preview Segment.

**Acceptance Criteria**:  
- Display RFM chart (Chart.js) from `rfm_segment_counts` materialized view via `GET /v1/api/rfm/preview` (REST) or `/analytics.v1/PreviewRFMService` (GET), OAuth and RBAC validated.  
- Show segment counts (e.g., "Champions: 50") in UI, localized via i18next.  
- Cache in Redis (`rfm:preview:{merchant_id}`) using Redis Streams (J9).  
- Log to PostHog (`rfm:previewed`, `ui_action:rfm_preview_viewed`).  
- Handle empty segments with localized error ("No data").  
- Support daily refresh of `rfm_segment_counts` (`0 2 * * *`).  

**US-MD13: Manage Checkout Extensions**  
As a merchant, I want to enable points display at checkout, so that customers can see their balance via purchase.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Checkout Settings.

**Acceptance Criteria**:  
- Toggle checkout extensions in settings using Polaris, localized via i18next.  
- Save to `program_settings.config` (JSONB) and `integrations` (`type='shopify_flow'`) via `PUT /v1/api/content` (REST) or `/frontend.v1/UpdateCheckoutService` (gRPC), OAuth and RBAC validated.  
- Preview points via Shopify App Bridge (Rust/Wasm).  
- Cache in Redis (`checkout:{merchant_id}`).  
- Log to PostHog (`checkout:updated`, `ui_action:checkout_updated`).  
- Handle Shopify API rate limits (50 points/s, 100 points/s Plus) with retry.  

### Phase 9: Advanced Features

**US-MD14: Create Bonus Campaigns**  
As a merchant, I want to create time-sensitive bonus campaigns, so that I can boost engagement.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Campaign Management.

**Acceptance Criteria**:  
- Display form for campaign type (e.g., double points, discount), dates, multiplier, and RFM conditions (e.g., "Champions only") using Polaris.  
- Save to `bonus_campaigns` (partitioned by `merchant_id`, `campaign_id` as PK) via `POST /v1/api/campaigns` (REST) or `/points.v1/CreateCampaignService` (gRPC), OAuth and RBAC validated.  
- Schedule campaign start/end using Bull queue.  
- Cache in Redis (`campaign:{merchant_id}`).  
- Log to PostHog (`campaign:created`, `ui_action:campaign_created`).  
- Handle invalid conditions (400) with localized error.  

**US-MD15: Export Advanced Reports**  
As a merchant, I want to export advanced analytics reports, so that I can analyze program performance.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Reports Export.

**Acceptance Criteria**:  
- Provide export button via `GET /v1/api/analytics/export` (REST) or `/analytics.v1/ExportAnalyticsService` (gRPC), OAuth and RBAC validated.  
- Download CSV with `customer_segments`, `points_transactions`, `rfm_segment_counts`.  
- Log progress and completion using Polaris, localized via i18next.  
- Cache progress in Redis (`export:{merchant_id}`).  
- Log to PostHog (`analytics:exported`, `ui_action:report_exported`).  
- Handle large datasets (50,000+ records) with async processing under 5s.  

**US-MD16: Configure Sticky Bar**  
As a merchant, I want to enable a sticky bar for rewards, so that I can promote the loyalty program.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Sticky Bar Editor.

**Acceptance Criteria**:  
- Display editor for sticky bar content (e.g., "Earn $1/point!") using Polaris, localized via i18next.  
- Save to `program_settings.sticky_bar` (JSONB, `CHECK ?| ARRAY['content']`) via `PUT /v1/api/content` (REST) or `/frontend.v1/UpdateContentService` (gRPC), OAuth and RBAC validated.  
- Preview sticky bar in editor.  
- Toggle visibility and cache in Redis (`content:{merchant_id}:{locale}`)).  
- Log to PostHog (`sticky_bar:updated`, `ui_action:sticky_bar_updated`).  
- Handle invalid inputs (400) with localized error.  

**US-MD17: Use Developer Toolkit**  
As a merchant, I want to configure metafields via a developer toolkit, so that I can customize integrations.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Developer Toolkit.

**Acceptance Criteria**:  
- Display form for metafield settings (e.g., Shopify metafields) using Polaris.  
- Save to `integrations.settings` (JSONB) via `PUT /v1/api/settings/developer` (REST) or `/admin.v1/UpdateDeveloperService` (gRPC), OAuth and RBAC validated.  
- Validate JSON inputs.  
- Cache in Redis (`developer:{merchant_id}`).  
- Log to PostHog (`developer:updated`, `ui_action:developer_updated`).  
- Show localized confirmation in UI.  

**US-MD18: Customize Post-Purchase Widget**  
As a merchant, I want to customize the post-purchase widget, so that I can engage customers after checkout.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Post-Purchase Editor.

**Acceptance Criteria**:  
- Display editor for post-purchase widget (e.g., points, nudge) using Polaris, localized via i18next.  
- Save to `program_settings.post_purchase` (JSONB, `CHECK ?| ARRAY['content']`) via `PUT /v1/api/content` (REST) or `/frontend.v1/UpdateContentService` (gRPC), OAuth and RBAC validated.  
- Preview widget in UI.  
- Cache in Redis (`content:{merchant_id}:{locale}`)).  
- Log to PostHog (`post_purchase:updated`, `ui_action:post_purchase_updated`).  
- Handle Shopify API rate limits (50 points/s) with retry.  

## Admin Module (Phase 1, 2, 3)

### Phase 1: Core Admin Functions

**US-AM1: View Merchant Overview**  
As an admin, I want to view an overview of all merchants, so that I can monitor platform usage.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Overview Dashboard.

**Acceptance Criteria**:  
- Display metrics (merchant count, points issued, referral ROI) from `merchants`, `points_transactions`, `referrals` via `GET /admin-overview/v1` (REST) or `/admin.v1/GetOverviewService` (gRPC), RBAC validated (`admin_users.metadata`).  
- Show RFM chart (Chart.js) from `rfm_segment_counts` materialized view, refreshed daily (`0 2 * * *`).  
- Cache in Redis (`overview:{period}`).  
- Log to PostHog (`overview:viewed`, `ui_action:overview_viewed`).  
- Handle API errors (400, 404) with error ("No views").  
- Support Plus-scale queries under 1s.  

**US-AM2: Manage Merchant List**  
As an admin, I want to view and search merchants, so that I can manage their accounts.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Merchant List.

**Acceptance Criteria**:  
- Display list from `MERCHANTS` (`merchant_id`, `shopify_domain`, `plan_id`, `staff_roles`) via `GET /v1/admin/merchants` (REST) or `/admin.v1/ListMerchantsService` (gRPC), RBAC validated.  
- Allow search by `uid`/`domain` using Polaris.  
- Show details (id., e.g., plan, RBAC roles) on click  
- Cache in `Redis (`merchants:{page}`)).  
- Log to (`PostHog: `merchant_list:viewed`, `ui_action:merchant_list`).  
- Show empty list with localized error ("No merchants").  

**US-AM3: Adjust Customer Points for**  
As an admin, I want to points a customer’s point balance, so that I can correct errors or provide bonuses.  
**Service**: Admin Service (gRPC: `/points/v1/*`, Dockerized).  
**Wireframe**: Admin Module - Customer Points Adjustment.

**Acceptance Criteria**:  
- Display form for points adjustment via `POST /v1/admin/api/points` (REST) or `/points/v1/AdminService.AdjustPoints` (gRPC), RBAC validated.  
- Insert record in `points_transactions` (`type='award'`, partitioned by `merchant_id`).  
- Log to `audit_logs` (`action:'points_aissued`) and `PostHog` (`points:`).  
- Update `customers.points_balance` and `Redis` cache (`points:{merchant_id}`)).  
- Log in `PostHog` (`audit:adjusted`, `ui_action:points_adjusted`).  
- Handle invalid inputs (400) with localized error.  

**US-AM4: Manage Admin Users for**  
As an admin, I want to add/edit/delete users, so that I can control platform access.  
**Service**: Auth Service (gRPC: `/auth.v1/*`, Dockerized).  
**Wireframe**: Admin Module - User Management.

**Acceptance Criteria**:  
- Display list from `users` (username, `meta_key` encrypted) via `GET /auth/v1/admin/users` (REST) or `/auth.v1/ListUsersAdminService` (gRPC), RBAC validated.  
- Provide forms for CRUD via `POST/PUT/PUT/DELETE /auth/v1/users/admin` or `/auth.v1/* /.v1/*`.  
- Validate unique username/email, email decrypted (via `g`), encrypt password (`BCRYPT`, `AES-256`).  
- Log to `audit_logs` (`action='user_updated'`) and `PostHog` (`audit:user_updated`, `ui_action:user_updated`).  
- Show localized confirmation.  

**US-AM5: Access Logs**  
As an admin, I want to log to API and audit logs for, so that I can monitor platform activity.  
**Service**: Admin Service (Service: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Log Viewer.

**Acceptance Criteria**:  
- Display logs from `api_logs`, `logs_audit`, with actions `action` (e.g., `tier_assigned:` , `config:updated`) via `GET /v1/admin/api/logs` (REST) or `/admin.v1/GetLogService` (gRPC), RBAC validated.  
- Filter by `date`/`uid`/`action` using Polaris.  
- Log details (e.g., to "Points: Adjust by Admin1") in to table, localized by via `i18next`.  
- Handle empty logs with localized error ("No log").  
- Cache in `Redis` (`logs:{merchant_id}:{page}`)).  
- Log to `PostHog` (`logs:viewed`, `ui_action:logs_viewed`).  
- 
**US-AM6*: Support for GDPR Requests**  
*As an admin, I want to process customer requests, so that I can comply with GDPR/CCPA requirements.  
* **Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - GDPR Request Dashboard.

* **Acceptance Criteria**:  
- Receive via Shopify `GET /customers/v1/data_request`, `customers/v1/*` webhooks, insert into `gdpr_requests` (`request_type='data_request'|'redact'`, partitioned by by `merchant_id`).  
- Query `customers`, `points_transactions`, `reward_redemptions` (`AES-256` encrypted fields), `rfm_segment_counts` for customer data.  
- Send data via Klaviyo (via Bull, queue, `email_templates.body`, e.g., `CHECK ?| array ['locale']`, with 3 retries) using Redis Streams (`gdpr_data:{merchant_id}`)).  
- Log to `audit_logs` (`audit:gdpr_processed`) and `PostHog` (`gdpr:processed`, `ui_action:gdpr_processed`).  
- Log request status in UI module, localized via `i18next`.  
- Ensure 90-day retention backup for compliance with Dockerized service.  

### Phase 8: Enhanced Admin Functions

**US-AM7: Manage Merchant Plans**  
As an admin, I want to upgrade/downgrade a merchant plans, so that I can manage their subscriptions.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Plan Management.

**Acceptance Criteria**:  
- Display current plan via from `MERCHANTS.plan_id` (via `GET /v1/admin/merchants` (REST) or `/admin/v1/ListMerchants.v1` (gRPC)), RBAC validated.  
- Provide a form to change plan via `PUT /admin/v1/plans/api` (REST) or `/admin.v1/UpdatePlanService` (gRPC).  
- Update `MERCHANTS.plan_id`, update log in `audit_logs` (`action:'plan_updated').  
- Cache in `Redis` (`plan:{merchant_id}`)).  
- Log to `PostHog` (`plan:updated`, `ui_action:plan_updated`).  
- Show confirmation localized in admin UI module.  

**US-AM8: Monitor Integration Status**  
As an Admin, I want to check health of of integrations (e.g., Shopify, Shopify Klaviyo), so that I can ensure platform reliability.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Integration Health Dashboard.

**Acceptance Criteria**:  
- Check status from `integrations` (`e.g.,='shopify'|'klaviyo'`, `status='ok'|'error'`) via `GET /admin/v1/api/health/` (REST) or `/admin.v1/CheckHealthService.v1` (gRPC), RBAC validated).  
- Show status in (e.g., "Shopify: OK") in UI admin module, UI via `i18next`.  
- Allow manual ping to to external services (3 retries, with exponential backoff).  
- Log to checks to in `audit_logs` (`action:'health_check'`) and `PostHog` (`audit:health_checked`, `ui_action:health_checked`).  
- Cache in `Redis` (`health:{status:merchant}`)).  

**US-AM9: Support RFM Configurations**  
As an Admin, I want to manage RFM settings for merchants, so that I can optimize segmenting.  
**Service**: gRPC (Admin Service (gRPC: `/admin.v1/*`, `Dockerized).  
**Wireframe**: Admin Module - RFM Configuration Admin.

**Acceptance Criteria**:  
- Display RFM from `program_settings` via `GET /admin/v1/rfm` (REST) or `/admin.v1/GetRfmConfig.v1` (gRPC)), RBAC validated by.  
- Provide a form to edit thresholds (weighted by: 30% recency, by 40% frequency, 30% monetary) via `PUT /admin/v1/mfm`.  
- Preview segment in (Chart.js) using `rfm_segment_counts`.  
- Cache in `Redis` in (`rfm:preview:{merchant_id}`)).  
- Log to changes in `audit_logs` (`action:'config_updated'`) and `PostHog` (`audit:rfm_updated`, `ui_action:rfm_updated`).  
- 
**US-AM10: Suspend Merchant Account for**  
As an Admin, I want to suspend or or reactivate a merchant, so that I can manage non-compliant accounts.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Merchant Status.

**Acceptance Criteria**:  
- Display merchant status (`MERCHANTS.status`) via `GET /MERCHANTS/v1` (REST) or `/MERCHANTS.v1/ListMerchants` (gRPC), RBAC validated by.  
- Toggle toggle to change status (`status`, `active:'|'`, `suspended'`, `trial'`) via `PUT /admin/v1/merchants/status` (REST) or `/MERCHANTS.v1/UpdateStatusMerchantService` (gRPC).  
- Update `MERCHANTS.status`, update log in to `audit_logs` (`action:'status_updated'`).  
- Cache in `Redis` (`MERCHANT:{merchant_id}`)).  
- Log to (`PostHog: `MERCHANT:status_updated`, `ui_action:status_updated`).  
- Show confirmation localized in Admin admin UI module.  

**US-AM11: Analytics Rate Limit Violations**  
As an Admin, I want to monitor API rate limits violations, so that I can address performance issues.  
**Service**: Admin Service (gREST: `/`, Dockerized).  
**Wireframe**: Admin Module – Rate Limit Dashboard.

**Acceptance Criteria**:  
- Display violations from `api_logs` (`status_code='429'`) via `GET /api_logs/v1/admin/rate-limits` (REST).  
- Show details in (e.g., to UID, Merchant ID, route, and timestamp) in to table using Polaris UI.  
- Filter by `uid`/`date`, cache in in `Redis` (`rate_limit:{merchant_id}`)).  
- Notify via emailNOTIFY for repeated violations (3+ in in 1h).  
- Log to (`PostHog` (`audit:rate_limit`, `ui_action:rate_limit_viewed`).  
- Handle errors empty logs with error ("No violations").  

### Phase 9: Advanced Admin Functions

**US-AM12: Export RFM Segments**  
As an GET, I want to export RFM segments to for merchants, so that I can analyze customer behaviors.  
**Service**: Analytics Service (GET: ANALYTICS, `/analytics.v1/*`, `/Dockerized).  
**Wireframe**: Admin Module Exports. Exports

**Acceptance Criteria**:  
- Display export button via `GET /admin/v1/rfm/export` (REST) or `/analytics.v1/ExportRFMSegments` (gRPC).  
- Download CSV with `GET_segments`, `customer_segments`, `rfm_segment_counts`, `merchants.rfm_score`).  
- Log to segments progress and completion via `Polaris`, localized via `i18next`.  
- Cache in progress in `Redis` (`export:{merchant_id}`)).  
- Log to (`PostHog: `rfm:exported`, `audit:rfm_exported`, `ui_action:rfm_exported`).  
- Handle datasets large datasets (50,+ records) with async under 4s.  

**US-AM13: Support Advanced Integrations (REST**  
As an Admin, I want to REST advanced integrations (e.g., to Square, Shopify, Postscript), so that I can support new platforms with.  
**Service**: REST Admin Service (gRPC: `/admin.v1/*`, `/Dockerized`).  
**Wireframe**: Admin Module - Integration Admin Setup.

**Acceptance Criteria**:  
- **Display form fields for integration settings (e.g., Square, Square Postscript)** via `POST /admin/v1/api/integrations` (REST) or `/admin.v1/AddServiceIntegration/v1` (gRPC), OAuth and RBAC validated.  
- Save to `integrations.settings` (JSONB, JSONB), encrypt `api_key` (`api_key-256-256`).  
- Validate APIs key (keys with 3 retries, exponential backoff).  
- Log to setup in `audit_logs` (`action:'integration_added'`) and `PostHog` (`audit:integration_updated`, `ui_action:integration_updated`).  
- **Show confirmation localized error in admin UI module.**  

## Backends Integrations (Phase 1, 2, 8)

### Phase 1: Backend

**US-BI1: Sync Shopify APIs with Orders**  
As a system API, I want to sync orders via webhooks with from Shopify, so that points can be awarded automatically.  
**Service**: Points Service (POST: `/points.v1/*`, `/Dockerized*, API*).  
**Integration**: Shopify Webhooks.

**Acceptance Criteria**:  
- **- Accept webhook `POST /v1/api/orders/points`**, validate `HMAC`**, call `POST /v1/api/points/earn` (REST) or `/points/v1.v1/*EarnPoints` (gRPC).  
- Insert into record in `points_transactions` (`type='sale'`, `partitioned by by` `merchant_id`).  
- Update `POINTS` (`points_transactions.points_balance`) and `Redis` cache (`points:{merchant_id}`)).  
- Log to `api_logs`, (`api_logs`) and (`points:earned`).  
- Handle duplicates (no-op) or invalid (`INVALID`) with (400).  
- Show support 1,000 orders/hour+ with orders/hour with partitioning by `merchant_id`.  

**US-BI2: Send Referral Notifications via Email**  
As an API, I want to send notifications referral via via email/Klaviyo or Twilio, so that customers can be are informed of their rewards. via email.  
**Service**: Referrals Service (POST: `/referrals.v1/*`, `/data1/*`, Dockerized).  
**Integration**: Klaviyo/Twilio, Email/SMS.

**Acceptance Criteria**:  
- **Fetch template from `emails_templates.body` (JSONB, `CHECK ?|b| ['body']`) via `GET /v1/api/templates/email` (REST) or `GET /templates/v1/referral.v1/GetTemplatesService` (gRPC).  
- Queue via notification via `BullQueue` for via Klaviyo/ or API Twilio (3 retries, with exponential backoff).  
- Insert into in `events` (`event_type='referral_completed'|' 'created'', `partitioned by` `merchant`, `id`) by by`.  
- Cache in `event` (`{referral_id:notifications}`)).  
- Log to (`PostHog: `notification:notification_sent`, `audit:notification`).  
- **Handle API errors (429) with retry logic.**  

### Phase 2: Advanced Features

**US-BI3: Import Customers Data (Phase 2)**  
*As an API, I want to import customer data from via integrations, so that* merchants can update existing customer programs.  
* **Service**: Admin Service (REST: /, API, `/gRPC`, `Dockerized/*`).  
**Integration**: CSV/REST Imports.

* **Acceptance Criteria**:  
- Call `POST /v1/api/customer/import/customers` (REST) or `/rest/v1/*ImportCustomers` (REST) with CSV (data customer_id, customer_id email, points, actions RFM).  
- Validate data (unique emails, RFM scores 1–5, via), insert into `customers` (`email`, emails `points`, `points`, `rfm_score` JSONB), `points_transactions` (`type='sale'`, `type= by `merchant_id`).  
- Process 50,000+ records asynchronously under 4 minutes (Plus-scale).  
- Log to `audit_logs` (`action:'customer_imported'`) and `PostHog` (`audit:customer_import_completed`, error`audit_logs`).  
- Cache in `audit_log` (`import:{merchant_id}`)).  
- Log in (`audit_log`, `audit:import_completed`).  
- **Ensure GDPR compliance with with `gdpr_requests` check checks.**  

### Phase 8: Advanced Features

**US-BI4: Apply Campaign Discounts (Phase 8)**  
*As a REST, I want to apply discounts from via bonus campaigns*, so that *customers can receive promotional rewards*.  
* **Service**: Points Service (REST) * (gRPC, `/points/*`, `/v1/*`, Dockerized).  
* **Integration**: Shopify Discounts, Campaign Logic.

* **Acceptance Criteria**:  
- Check `bonus_campaigns` for active campaigns via `Rust/Wamp` Shopify Function (`calc_points`).  
- Validate `customer_id` eligibility (`programM_settings`) for `bonus_campaigns.conditions`.  
- Insert into `reward_redemptions` (partitioned by by `merchant_id`, `campaign_id`, with `AES-256` encrypted code).  
- Log to `api_logs`, (`audit_logs`) and `PostHog` (`audit:campaign_discount`, `campaign_discount`).  
- Update `POINTS` (`customers.points`) and `Redis` cache (`discounts:{merchant_id}`)).  
- **Handle expired campaigns (no-op, 400) or rate limits (429, retry) with 429.**  

**US-BI5: Calculate RFM Scores (Phase 5)**  
*As an admin, I want to calculate and update RFM scores for customers*, so that merchants can segment customers effectively.*  
* **Service**: Analytics Service (GET: `/analytics`, `/v1/*`, Dockerized).  

**Acceptance Criteria**:  
- Run job scheduled job (`0 2 * * /`) to calculate `customers.rfm_score` (JSONB, weighted by: 30% recency, by:40% frequency, 30% monetary) by based on: `points_transactions`, `orders`.  
- Update `segments` and `rfm_segment_counts` materialized view via `UPDATE /v1/api/rfm/score` (REST) or `/analytics.v1/*UpdateRFMScores` (gRPC).  
- Use index `idx_customers_rfm_score_at_risk` (`WHERE rfm_score->>'score' < 2`) for performance`.  
- Cache in `Redis` (`rfm:{merchant_id}`)).  
- Log to (`PostHog: `rfm:updated`, `audit:rfm_updated`).  
- **Handle datasets large datasets (50+) with async and with partitioning by** `merging_id`.**

</div>