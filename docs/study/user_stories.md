```markdown
# LoyalNest App User Stories

## Customer Widget (Phase 1, 2, 3)

### Phase 1: Core Loyalty Features

**US-CW1: View Points Balance**  
As a customer, I want to view my current points balance in the Customer Widget, so that I can track my loyalty rewards and plan redemptions.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Points Balance.  

**Acceptance Criteria**:  
- Display points balance (e.g., "500 Stars") in widget using Tailwind CSS and Polaris `Badge`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL support).  
- Fetch balance from `customers.points_balance` via `GET /v1/api/customer/points` (REST) or `/points.v1/PointsService/GetPointsBalance` (gRPC) with Shopify OAuth token.  
- Update Redis Streams cache (`points:customer:{customer_id}`) after fetching, with 50ms latency target.  
- Show error in Polaris `Banner` (e.g., "Unable to load balance") if API returns 401/404, localized via `Accept-Language`.  
- Update balance display within 1s after earning/redemption, supporting multi-store point sharing (Phase 5).  
- Handle Shopify GraphQL API limits (2 req/s REST, 40 req/s Plus) with circuit breakers and exponential backoff (3 retries, 500ms base delay).  
- Log to PostHog (`points_balance_viewed` event, `ui_action:points_viewed`, 80%+ engagement target).  
- **Accessibility**: ARIA label (`aria-label="View points balance"`) and screen reader support (`aria-live="polite"`), Lighthouse CI score 90+.  
- **Testing**: Jest test for `PointsBalance` component, Cypress E2E test for balance display flow, k6 load test for 10,000 concurrent requests (Black Friday), OWASP ZAP for security, Chaos Mesh for resilience.

**US-CW2: Earn Points from Purchase**  
As a customer, I want to earn points automatically when I make a purchase, so that I can accumulate rewards for my loyalty.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Purchase Confirmation.  

**Acceptance Criteria**:  
- Trigger `POST /v1/api/points/earn` (REST) or `/points.v1/PointsService/EarnPoints` (gRPC) on Shopify `orders/create` webhook (HMAC validated, Redis idempotency key).  
- Insert record in `points_transactions` with `type='earn'`, partitioned by `merchant_id`, apply RFM multiplier (`program_settings.rfm_thresholds: JSONB`).  
- Update `customers.points_balance` and Redis Streams cache (`points:customer:{customer_id}`).  
- Log to PostHog (`points_earned` event, `ui_action:purchase_completed`, 20%+ redemption rate target).  
- Display confirmation in Polaris `Banner` (e.g., "You earned 100 points!") in widget, localized via i18next (`en`, `es`, `fr`, `ar` with RTL), with 300ms fade-in animation.  
- Show error in Polaris `Banner` (e.g., "Invalid order") if webhook fails (400) or rate limit exceeded (429, 3 retries with exponential backoff).  
- Ensure transaction completes within 1s for 10,000 orders/hour (Plus-scale, Black Friday).  
- Support multi-store point sharing via `/v1/api/points/sync` (Phase 5).  
- **Accessibility**: ARIA label (`aria-label="Points earned notification"`) for confirmation, keyboard-navigable.  
- **Testing**: Jest test for `PurchaseConfirmation` component, Cypress E2E test for points earning flow, k6 load test for 10,000 orders/hour, Chaos Mesh for resilience.

**US-CW3: Redeem Points for Discount**  
As a customer, I want to redeem points for a discount (e.g., 10% off), so that I can save money on my purchases.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Rewards Redemption.  

**Acceptance Criteria**:  
- List available rewards from `rewards` table (`is_public=true`) via `GET /v1/api/customer/points` (REST) or `/points.v1/PointsService/GetRewards` (gRPC) using Polaris `Card`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Call `POST /v1/api/redeem` (REST) or `/points.v1/PointsService/RedeemReward` (gRPC) with `reward_id`, `customer_id`, Shopify OAuth token.  
- Validate `customers.points_balance` >= `rewards.points_cost` in TypeORM transaction.  
- Insert record in `reward_redemptions` (partitioned by `merchant_id`, `campaign_id` nullable), encrypt `discount_code` (AES-256 via `pgcrypto`).  
- Create Shopify discount code via GraphQL Admin API (Rust/Wasm for Plus, 40 req/s).  
- Update `customers.points_balance` and Redis Streams cache (`points:customer:{customer_id}`).  
- Log to PostHog (`points_redeemed` event, `ui_action:reward_redeemed`, 15%+ redemption rate for Plus).  
- Display discount code in Polaris `Modal` or error in Polaris `Banner` (e.g., "Insufficient points") for 400, localized via i18next.  
- Handle Shopify API rate limits (429, 2 req/s REST, 40 req/s Plus) with circuit breakers and 3 retries (500ms base delay).  
- Support multi-currency discounts (Phase 6).  
- **Accessibility**: ARIA label (`aria-label="Redeem points"`) for redeem button, screen reader support for error messages.  
- **Testing**: Jest test for `RewardsRedemption` component, Cypress E2E test for redemption flow, k6 load test for 5,000 concurrent redemptions, OWASP ZAP for security.

**US-CW4: Share Referral Link**  
As a customer, I want to share a referral link via SMS, email, or social media, so that I can invite friends and earn rewards.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Referral Popup.  

**Acceptance Criteria**:  
- Generate unique `referral_code` via `POSTწ

System: **POST /v1/api/referral` (REST) or `/referrals.v1/ReferralService/CreateReferral` (gRPC) with `advocate_customer_id`.  
- Insert record in `referral_links` (partitioned by `merchant_id`, `referral_link_id` as PK).  
- Display referral link and sharing options (SMS via Postscript, email via Klaviyo, social: FB/IG in Phase 2) in Polaris `Modal`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Queue notification via Bull queue for Postscript/Klaviyo with `email_templates.body` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`).  
- Log to PostHog (`referral_created` event, `ui_action:referral_shared`, 7%+ SMS conversion target).  
- Show error in Polaris `Banner` (e.g., "Failed to share: duplicate code") if API returns 400/429, with 3 retries (500ms base delay).  
- Cache in Redis Streams (`referral:code:{referral_code}`).  
- Support merchant referral program (Phase 5, `merchant_referral_id`).  
- **Accessibility**: ARIA label (`aria-label="Send referral invite"`) for share button, keyboard-navigable modal, RTL support for Arabic.  
- **Testing**: Jest test for `ReferralPopup` component, Cypress E2E test for referral sharing, k6 test for 1,000 concurrent shares, Chaos Mesh for resilience.

**US-CW5: Earn Referral Reward**  
As a customer, I want to earn points when a friend signs up using my referral link, so that I am rewarded for inviting others.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Referral Confirmation.  

**Acceptance Criteria**:  
- Friend signs up via `POST /v1/api/referrals/complete` (REST) or `/referrals.v1/ReferralService/CompleteReferral` (gRPC) with `referral_code`, `friend_customer_id`.  
- Validate `referral_code` in `referral_links` using `referral_link_id`.  
- Insert record in `referrals` (partitioned by `merchant_id`, `referral_link_id` as FK) with `advocate_customer_id`, `friend_customer_id`, `reward_id`.  
- Insert `points_transactions` for advocate with `type='referral'`, partitioned by `merchant_id`.  
- Update `customers.points_balance` and Redis Streams cache (`points:customer:{customer_id}`).  
- Queue reward notification via Bull (Postscript/Klaviyo, `email_templates.body`, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`).  
- Log to PostHog (`referral_completed` event, `ui_action:referral_reward_earned`, 7%+ conversion target).  
- Display confirmation in Polaris `Banner` (e.g., "You earned 50 points!") in widget, localized via i18next, with 300ms fade-in, RTL support for Arabic.  
- Show error in Polaris `Banner` (e.g., "Invalid referral code") if API returns 400.  
- Support merchant referral program (Phase 5).  
- **Accessibility**: ARIA label (`aria-label="Referral reward notification"`) for confirmation, keyboard-navigable.  
- **Testing**: Jest test for `ReferralConfirmation` component, Cypress E2E test for reward earning flow, k6 test for 1,000 concurrent completions.

**US-CW6: Adjust Points for Cancelled Order**  
As a customer, I want my points balance to be adjusted if an order is cancelled, so that my balance reflects accurate purchases.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Points History.  

**Acceptance Criteria**:  
- Trigger `POST /v1/api/webhooks/orders/cancelled` (REST) or `/points.v1/PointsService/AdjustPoints` (gRPC) on Shopify webhook (HMAC validated, Redis idempotency key).  
- Query `points_transactions` for `order_id`, `type='earn'`.  
- Insert `points_transactions` with `type='adjust'`, negative points, partitioned by `merchant_id`.  
- Update `customers.points_balance` and Redis Streams cache (`points:customer:{customer_id}`).  
- Log to PostHog (`points_adjusted` event, `ui_action:points_adjusted_viewed`).  
- Display updated balance in widget within 1s using Polaris `Badge`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Show error in Polaris `Banner` (e.g., "No points to adjust") if no transaction exists (no-op) or rate limit exceeded (429, 3 retries).  
- Support multi-store sync via `/v1/api/points/sync` (Phase 5).  
- **Accessibility**: ARIA label (`aria-label="Points adjusted notification"`) for balance update, screen reader support.  
- **Testing**: Jest test for `PointsHistory` component, Cypress E2E test for cancellation adjustment, k6 test for 10,000 orders/hour.

**US-CW7: View Referral Status**  
As a customer, I want to view the detailed status of my referrals (e.g., who signed up, who purchased), so that I can track my referral rewards and trust the system.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Referral Status Page.  

**Acceptance Criteria**:  
- Display referral status (e.g., "Pending: John Doe (Signed Up)", "Completed: Jane Smith (Purchased)") from `referrals` table via `GET /v1/api/referrals/status` (REST) or `/referrals.v1/ReferralService/GetReferralStatus` (gRPC) with `customer_id`, referencing `referral_link_id`.  
- Include friend actions (e.g., `event_type='signup'|'purchase'` from `referral_events`) in Polaris `DataTable` and `ProgressBar`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Cache results in Redis Streams (`referral_status:customer:{customer_id}`).  
- Log to PostHog (`referral_status_viewed` event, `ui_action:referral_status_viewed`, 60%+ engagement target).  
- Show error in Polaris `Banner` (e.g., "No referrals found") if API returns 404.  
- Handle Shopify API rate limits (2 req/s REST, 40 req/s Plus) with circuit breakers and exponential backoff (3 retries, 500ms base delay).  
- Support merchant referral program (Phase 5).  
- **Accessibility**: ARIA label (`aria-label="View referral status"`) for status table, screen reader support (`aria-live="polite"`), RTL for Arabic.  
- **Testing**: Jest test for `ReferralStatus` component, Cypress E2E test for detailed status display, Lighthouse CI for table accessibility, k6 test for 5,000 concurrent views.

**US-CW8: Request GDPR Data Access/Deletion**  
As a customer, I want to request access to or deletion of my data via the widget, so that I can exercise my privacy rights.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - GDPR Request Form.  

**Acceptance Criteria**:  
- Display GDPR request form (data access, deletion) in Polaris `Modal` with `Form` and disclosures, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Submit request via `POST /v1/api/gdpr` (REST) or `/admin.v1/AdminService/ProcessGDPRRequest` (gRPC) with `customer_id`, `request_type`.  
- Insert record in `gdpr_requests` (`request_type='data_request'|'redact'`, partitioned by `merchant_id`, `retention_expires_at` for 90-day retention).  
- Notify customer via Klaviyo/Postscript (3 retries, `email_templates.body`, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`) using Redis Streams (`notification:gdpr:{customer_id}`).  
- Log to PostHog (`gdpr_request_submitted` event, `ui_action:gdpr_form_submitted`, 50%+ usage target).  
- Show confirmation in Polaris `Banner` (e.g., "Request submitted") or error (e.g., "Invalid request") for 400, localized via i18next, RTL support.  
- Ensure 90-day backup retention in Backblaze B2 for compliance via Dockerized backup service.  
- Encrypt PII (`customers.email`, `rfm_score`) with AES-256 via `pgcrypto`.  
- **Accessibility**: ARIA label (`aria-label="Submit GDPR request"`) for submit button, keyboard-navigable modal, RTL for Arabic.  
- **Testing**: Jest test for `GDPRForm` component, Cypress E2E test for request submission, k6 test for 1,000 concurrent requests, OWASP ZAP for security.

### Phase 2: Enhanced Features

**US-CW9: View VIP Tier Status**  
As a customer, I want to view my VIP tier status and progress, so that I can understand my benefits and strive for higher tiers.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - VIP Tier Dashboard.  

**Acceptance Criteria**:  
- Display current tier and progress (e.g., "Silver, $100/$500 to Gold") from `customers.vip_tier_id`, `vip_tiers.threshold_value` via `GET /v1/api/vip-tiers/status` (REST) or `/points.v1/PointsService/GetVipTierStatus` (gRPC).  
- Show perks from `vip_tiers.perks` (JSONB, localized via i18next: `en`, `es`, `fr`, `ar` with RTL) in Polaris `Card`.  
- Update display after tier change via Shopify webhook (`orders/create`) within 1s, supporting multi-store sync (Phase 5).  
- Cache in Redis Streams (`tier:customer:{customer_id}`).  
- Show error in Polaris `Banner` (e.g., "Tier data unavailable") if API fails (404).  
- Log to PostHog (`vip_tier_viewed` event, `ui_action:vip_status_viewed`, 60%+ engagement target).  
- Handle Shopify API rate limits (2 req/s REST, 40 req/s Plus) with circuit breakers and 3 retries (500ms base delay).  
- **Accessibility**: ARIA label (`aria-label="View VIP perks"`) for tier details, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `VIPTier` component, Cypress E2E test for tier display flow, k6 test for 5,000 concurrent views.

**US-CW10: Receive RFM Nudges**  
As a customer, I want to receive personalized nudges encouraging engagement (e.g., "Invite a friend!" for At-Risk), so that I remain active in the loyalty program.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Nudge Popup/Banner.  

**Acceptance Criteria**:  
- Display nudge from `nudges` table (`title`, `description` in JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`) based on `customers.rfm_score` (time-weighted recency, e.g., R5 ≤14 days for subscriptions) and `rfm_segment_counts` (segments: Champions, Loyal, At-Risk, New, Inactive, VIP) via `GET /v1/api/nudges` (REST) or `/analytics.v1/AnalyticsService/GetNudges` (gRPC).  
- Show nudge as Polaris `Banner` (300ms fade-in) or `Modal` based on `nudge_type`, localized via i18next, RTL support for Arabic.  
- Support A/B testing for nudge variants (e.g., "Invite a friend!" vs. "Shop now!") with results tracked in `nudge_events`.  
- Log interaction (`view`, `click`, `dismiss`) in `nudge_events` (partitioned by `merchant_id`) via `POST /v1/api/nudges/action`.  
- Cache in Redis Streams (`nudge:customer:{customer_id}`).  
- Allow dismissal with Polaris `Button` (ARIA: `aria-label="Dismiss nudge"`, PostHog: `nudge_dismissed`, 10%+ click-through target).  
- Show fallback message in Polaris `Banner` (e.g., "No nudges available") if API returns 404.  
- Handle lifecycle stages (new lead, repeat buyer, churned) and industry benchmarks (`rfm_benchmarks`).  
- **Accessibility**: ARIA label (`aria-label="Dismiss nudge"`) for dismissal, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `NudgeBanner` component, Cypress E2E test for nudge display and dismissal, k6 test for 5,000 concurrent nudges, OWASP ZAP for security.

**US-CW11: Earn Gamification Badges**  
As a customer, I want to earn badges for actions (e.g., purchases, referrals), so that I feel motivated to engage with the program.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Badges Section.  

**Acceptance Criteria**:  
- Trigger `POST /v1/api/gamification/action` (REST) or `/analytics.v1/AnalyticsService/AwardBadge` (gRPC) on qualifying action (e.g., purchase, referral, 5+ orders for RFM Frequency).  
- Insert badge in `gamification_achievements` (partitioned by `merchant_id`) with `badge` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`).  
- Display badge in Polaris `Card` (e.g., "Loyal Customer") using Tailwind CSS, localized via i18next, RTL support for Arabic.  
- Cache in Redis Streams (`badge:customer:{customer_id}`).  
- Log to PostHog (`badge_earned` event, `ui_action:badge_viewed`, 20%+ engagement target).  
- Show error in Polaris `Banner` (e.g., "Action not eligible") if API returns 400.  
- Support gamified onboarding (Phase 5).  
- **Accessibility**: ARIA label (`aria-label="View badges"`) for badge section, screen reader support.  
- **Testing**: Jest test for `BadgesSection` component, Cypress E2E test for badge earning, k6 test for 5,000 concurrent actions.

**US-CW12: View Leaderboard Rank**  
As a customer, I want to view my rank on a leaderboard, so that I can compete with other customers.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Leaderboard Page.  

**Acceptance Criteria**:  
- Call `GET /v1/api/gamification/leaderboard` (REST) or `/analytics.v1/AnalyticsService/GetLeaderboard` (gRPC) with `customer_id`.  
- Fetch rank from Redis sorted set (`leaderboard:merchant:{merchant_id}`) based on `customers.points_balance` and RFM scores.  
- Display rank in Polaris `Card` (e.g., "#5 of 100") using Tailwind CSS, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Update rank after points change within 1s using Redis Streams.  
- Cache in Redis Streams (`leaderboard_rank:customer:{customer_id}`).  
- Log to PostHog (`leaderboard_viewed` event, `ui_action:leaderboard_viewed`, 15%+ engagement target).  
- Show error in Polaris `Banner` (e.g., "Leaderboard unavailable") if API fails (404).  
- **Accessibility**: ARIA label (`aria-label="View leaderboard"`) for rank display, screen reader support.  
- **Testing**: Jest test for `Leaderboard` component, Cypress E2E test for rank display, k6 test for 5,000 concurrent views.

**US-CW13: Select Language**  
As a customer, I want to select my preferred language in the widget, so that I can interact in my native language.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Settings Panel.  

**Acceptance Criteria**:  
- Display language dropdown from `merchants.language` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`) via `GET /v1/api/widget/config` (REST) or `/frontend.v1/FrontendService/GetWidgetConfig` (gRPC) using Polaris `Select`.  
- Send `Accept-Language` header in API calls, supporting `en`, `es`, `fr`, `ar` with RTL.  
- Update widget UI (e.g., points label, nudges) using i18next based on selection.  
- Persist choice in browser `localStorage`.  
- Log to PostHog (`language_selected` event, `ui_action:language_changed`, 10%+ usage target).  
- Show fallback to `en` if language unavailable, with error in Polaris `Banner` (e.g., "Language not supported").  
- **Accessibility**: ARIA label (`aria-label="Select language"`) for dropdown, keyboard-navigable, RTL support for Arabic.  
- **Testing**: Jest test for `LanguageSelector` component, Cypress E2E test for language switch, Lighthouse CI for accessibility.

**US-CW14: Interact with Sticky Bar**  
As a customer, I want to view and interact with a sticky bar promoting the loyalty program, so that I can join or redeem rewards.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Sticky Bar.  

**Acceptance Criteria**:  
- Display sticky bar with loyalty CTA (e.g., "Earn 1 point/$!") from `program_settings.sticky_bar` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`) via `GET /v1/api/widget/config` (REST) or `/frontend.v1/FrontendService/GetWidgetConfig` (gRPC).  
- Show bar using Polaris `Banner` (fixed top, Tailwind `sm: hidden, md: block`), localized via i18next, RTL support for Arabic.  
- Log clicks to PostHog (`sticky_bar_clicked` event, `ui_action:sticky_bar_interacted`, 10%+ click-through target).  
- Trigger widget open or referral form (`/v1/api/referrals/create`) on click, supporting Theme App Extensions (Phase 5).  
- Cache in Redis Streams (`content:merchant:{merchant_id}:locale`).  
- Show error in Polaris `Banner` (e.g., "Failed to load content") if API fails (404).  
- **Accessibility**: ARIA label (`aria-label="Join loyalty program"`) for CTA, keyboard-navigable, RTL for Arabic.  
- **Testing**: Jest test for `StickyBar` component, Cypress E2E test for click-through flow, Lighthouse CI for accessibility.

**US-CW15: View Post-Purchase Widget**  
As a customer, I want to view my points earned post-purchase with a referral CTA, so that I can engage further with the loyalty program.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - Post-Purchase Widget.  

**Acceptance Criteria**:  
- Display points earned (e.g., "You earned 100 points!") and referral CTA in Polaris `Card` post-checkout via `GET /v1/api/points/earn` (REST) or `/points.v1/PointsService/GetEarnedPoints` (gRPC).  
- Show content from `program_settings.post_purchase` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`), localized via i18next, RTL support for Arabic.  
- Log CTA clicks to PostHog (`post_purchase_viewed` event, `ui_action:post_purchase_clicked`, 15%+ click-through target).  
- Trigger referral form (`/v1/api/referrals/create`) on CTA click, supporting Theme App Extensions (Phase 5).  
- Cache in Redis Streams (`content:merchant:{merchant_id}:locale`).  
- Show error in Polaris `Banner` (e.g., "Failed to load points") if API fails (404).  
- Support Shopify Checkout UI Extensions for seamless integration.  
- **Accessibility**: ARIA label (`aria-label="View points earned"`) for card, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `PostPurchaseWidget` component, Cypress E2E test for post-purchase flow, k6 test for 5,000 concurrent views.

**US-CW16: View Progressive Tier Engagement**  
As a customer, I want to see what actions I need to take to reach the next VIP tier, so that I stay motivated to engage with the program.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Customer Widget - VIP Tier Progress.  

**Acceptance Criteria**:  
- Display current tier, progress (e.g., "Silver, $100/$500 to Gold"), and recommended actions (e.g., “Spend $100 more”, “Refer 2 friends”) from `customers.vip_tier_id`, `vip_tiers.threshold_value`, and `program_settings.actions` (JSONB) via `GET /v1/api/vip-tiers/progress` (REST) or `/points.v1/PointsService/GetVipTierProgress` (gRPC).  
- Show actions in Polaris `Card` with `ProgressBar`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Update display after tier-relevant actions (e.g., purchase, referral) within 1s via Shopify webhook (`orders/create`, `referrals/complete`), supporting multi-store sync (Phase 5).  
- Cache in Redis Streams (`tier_progress:customer:{customer_id}`).  
- Log to PostHog (`tier_progress_viewed` event, `ui_action:tier_progress_viewed`, 60%+ engagement target).  
- Show error in Polaris `Banner` (e.g., "Tier progress unavailable") if API fails (404).  
- Handle Shopify API rate limits (2 req/s REST, 40 req/s Plus) with circuit breakers and 3 retries (500ms base delay).  
- **Accessibility**: ARIA label (`aria-label="View tier progress"`) for progress details, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `TierProgress` component, Cypress E2E test for progress display and updates, k6 test for 5,000 concurrent views, Lighthouse CI for accessibility.

**US-CW17: Save Loyalty Balance to Mobile Wallet**  
As a customer, I want to save my loyalty balance to my Apple/Google Wallet, so that I can easily check my rewards on the go.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Integration**: Apple Wallet, Google Pay APIs.  
**Wireframe**: Customer Widget - Wallet Integration.  

**Acceptance Criteria**:  
- Display “Add to Wallet” button in Polaris `Button` via `GET /v1/api/wallet/pass` (REST) or `/points.v1/PointsService/GenerateWalletPass` (gRPC) with `customer_id`.  
- Generate wallet pass with `points_balance`, `vip_tier_id`, and QR code for redemption, stored in `wallet_passes` (AES-256 encrypted `pass_data`, partitioned by `merchant_id`).  
- Integrate with Apple Wallet/Google Pay APIs for pass creation, supporting `en`, `es`, `fr`, `ar` with RTL via i18next.  
- Update pass on points/tier changes via Shopify webhooks (`orders/create`, `points/earn`), cached in Redis Streams (`wallet:customer:{customer_id}`).  
- Log to PostHog (`wallet_pass_added` event, `ui_action:wallet_added`, 10%+ click-through target).  
- Show error in Polaris `Banner` (e.g., "Failed to add to wallet") if API fails (400, 429, 3 retries with exponential backoff).  
- Handle 5,000 concurrent pass requests with Bull queues and circuit breakers.  
- **Accessibility**: ARIA label (`aria-label="Add to wallet"`) for button, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `WalletIntegration` component, Cypress E2E test for pass generation, k6 test for 5,000 concurrent requests, OWASP ZAP for security.

### Phase 3: Advanced Features

**US-MD19: Automate Lifecycle Rewards**  
As a merchant, I want to automatically send rewards or campaigns when a customer’s RFM score drops or tier changes, so that I can re-engage them before they churn.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Integration**: Shopify Flow, Klaviyo/Postscript.  
**Wireframe**: Merchant Dashboard - Lifecycle Automation.  

**Acceptance Criteria**:  
- Display automation setup form for RFM/tier triggers (e.g., “At-Risk → 100 points”, “Silver to Gold → $5 off”) using Polaris `Form`, `Select`, and `TextField`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Save to `bonus_campaigns` (`conditions: JSONB`, e.g., `{"rfm_segment": "At-Risk", "tier_change": "Silver->Gold"}`) via `PUT /v1/api/campaigns/lifecycle` (REST) or `/analytics.v1/AnalyticsService/ConfigureLifecycleCampaign` (gRPC), OAuth and RBAC validated (`merchants.staff_roles`).  
- Trigger campaigns via Shopify Flow templates (e.g., “RFM Drop → Award Points”) using `rfm_segment_counts` and `customers.vip_tier_id`, queued via Bull.  
- Notify via Klaviyo/Postscript (3 retries, `email_templates.body`, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`), cached in Redis Streams (`campaign:merchant:{merchant_id}`).  
- Log to PostHog (`lifecycle_campaign_triggered` event, `ui_action:campaign_triggered`, 15%+ redemption target).  
- Show confirmation in Polaris `Banner` (e.g., “Automation saved”) or error (e.g., “Invalid conditions”) for 400, localized with RTL support.  
- Handle 10,000 orders/hour with PostgreSQL partitioning and circuit breakers.  
- **Accessibility**: ARIA label (`aria-label="Configure lifecycle automation"`) for form, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `LifecycleAutomation` component, Cypress E2E test for automation setup and triggering, k6 test for 5,000 concurrent triggers, OWASP ZAP for security.

**US-MD20: View Segment Benchmarking**  
As a merchant, I want to see how my loyalty segments compare with similar businesses, so that I can evaluate performance and identify areas for growth.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Segment Benchmarking.  

**Acceptance Criteria**:  
- Display segment comparison (e.g., “Champions: 10% vs. Industry: 8%”) from `rfm_segment_counts` and `rfm_benchmarks` (JSONB, aggregated anonymized data) via `GET /v1/api/rfm/benchmarks` (REST) or `/analytics.v1/AnalyticsService/GetSegmentBenchmarks` (gRPC), OAuth and RBAC validated.  
- Show Chart.js bar chart in Polaris `Card`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Cache in Redis Streams (`benchmarks:merchant:{merchant_id}`).  
- Log to PostHog (`benchmarks_viewed` event, `ui_action:benchmarks_viewed`, 80%+ view rate target).  
- Show error in Polaris `Banner` (e.g., “No benchmark data”) if API fails (404).  
- Ensure GDPR/CCPA compliance by anonymizing data before aggregation, with 90-day retention in Backblaze B2.  
- Support industry-specific benchmarks (e.g., Pet Store, Electronics) in `rfm_benchmarks`.  
- **Accessibility**: ARIA label (`aria-live="Segment benchmark data available"`) for chart, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `SegmentBenchmarking` component, Cypress E2E test for benchmark display, k6 test for 5,000 concurrent views, Lighthouse CI for accessibility.

**US-MD21: A/B Test Nudges**  
As a merchant, I want to test different nudges with different copy or designs, so that I can optimize which messages drive more conversions.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Merchant Dashboard - Nudge A/B Testing.  

**Acceptance Criteria**:  
- Display form to configure A/B test variants (e.g., “Invite a friend!” vs. “Shop now!”) in `program_settings.ab_tests` (JSONB) using Polaris `Form`, `TextField`, and `Select`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Save via `PUT /v1/api/nudges/ab-test` (REST) or `/analytics.v1/AnalyticsService/ConfigureNudgeABTest` (gRPC), OAuth and RBAC validated.  
- Track interactions in `nudge_events` (`event_type='view'|'click'|'dismiss'`, `variant_id`, partitioned by `merchant_id`).  
- Display results (e.g., click-through rates) in Chart.js (bar type) in Polaris `Card`.  
- Cache in Redis Streams (`nudge_ab:merchant:{merchant_id}`).  
- Log to PostHog (`nudge_ab_tested` event, `ui_action:nudge_ab_tested`, 10%+ click-through target).  
- Show error in Polaris `Banner` (e.g., “Invalid variant”) for 400 errors, localized with RTL support.  
- Handle 5,000 concurrent nudges with Bull queues and circuit breakers.  
- **Accessibility**: ARIA label (`aria-label="Configure nudge A/B test"`) for form, screen reader support for chart, RTL for Arabic.  
- **Testing**: Jest test for `NudgeABTest` component, Cypress E2E test for A/B test setup and results, k6 test for 5,000 concurrent interactions.

**US-MD22: Identify Churn Risk Customers**  
As a merchant, I want to see a list of high-spending customers who are at risk of churning, so that I can take action to win them back.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Integration**: xAI API (Phase 6).  
**Wireframe**: Merchant Dashboard - Churn Risk Dashboard.  

**Acceptance Criteria**:  
- Display list of At-Risk customers (`rfm_segment_counts` where `segment='At-Risk'` and `monetary > 2x AOV`) via `GET /v1/api/rfm/churn-risk` (REST) or `/analytics.v1/AnalyticsService/GetChurnRisk` (gRPC), OAuth and RBAC validated.  
- Show details (customer ID, email, last order, RFM score) in Polaris `DataTable`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Integrate with xAI API for churn prediction (Phase 6, https://x.ai/api) for enhanced accuracy.  
- Cache in Redis Streams (`churn_risk:merchant:{merchant_id}`).  
- Log to PostHog (`churn_risk_viewed` event, `ui_action:churn_risk_viewed`, 80%+ view rate target).  
- Show error in Polaris `Banner` (e.g., “No at-risk customers”) if API fails (404).  
- Support manual actions (e.g., award points) via `POST /v1/api/points` and Shopify Flow templates (Phase 5).  
- Ensure GDPR/CCPA compliance with AES-256 encrypted PII (`customers.email`).  
- **Accessibility**: ARIA label (`aria-label="View churn risk customers"`) for table, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `ChurnRiskDashboard` component, Cypress E2E test for churn list display, k6 test for 5,000 concurrent views, OWASP ZAP for security.

## Admin Module (Phase 1, 2, 3)

### Phase 1: Core Admin Functions

**US-AM1: View Merchant Overview**  
As an admin, I want to view an overview of all merchants, so that I can monitor platform usage.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Overview Dashboard.  

**Acceptance Criteria**:  
- Display metrics (merchant count, points issued/redeemed, referral ROI, RFM segments, churn prediction via gRPC) from `merchants`, `points_transactions`, `referrals`, `rfm_segment_counts` via `GET /v1/admin-overview` (REST) or `/admin.v1/AdminService/GetOverview` (gRPC), RBAC validated (`admin_users.metadata: JSONB`, e.g., `admin:full`).  
- Show RFM chart (Chart.js, bar type) from `rfm_segment_counts` materialized view, refreshed daily (`0 1 * * *`), with benchmarks (`rfm_benchmarks`) in Polaris `Card`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Display merchant timelines (e.g., plan upgrades, point adjustments) using Chart.js.  
- Cache in Redis Streams (`overview:period:{period}`).  
- Log to PostHog (`overview_viewed` event, `ui_action:overview_viewed`, 90%+ view rate target).  
- Show error in Polaris `Banner` (e.g., "No data") for API errors (400, 404).  
- Support Plus-scale queries (50,000+ customers) under 1s with PostgreSQL partitioning and Redis Streams.  
- Include predictive analytics (churn prediction via `/admin.v1/AdminService/GetChurnPrediction`).  
- **Accessibility**: ARIA label (`aria-live="Metrics data available"`) for chart, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `OverviewPage` component, Cypress E2E test for metrics display, k6 test for 5,000 merchants, Chaos Mesh for resilience.

**US-AM2: Manage Merchant List**  
As an admin, I want to view and search merchants, so that I can manage their accounts.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Merchant List.  

**Acceptance Criteria**:  
- Display list from `merchants` (`merchant_id`, `shopify_domain`, `plan_id`, `staff_roles: JSONB`) via `GET /v1/admin/merchants` (REST) or `/admin.v1/AdminService/ListMerchants` (gRPC), RBAC validated (`admin:full`, `admin:support`).  
- Allow search by `merchant_id`/`shopify_domain` using Polaris `TextField`, with pagination (50 rows/page).  
- Show details (plan, RBAC roles, timeline of actions) on click in Polaris `Card`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Support undo actions (e.g., revert point adjustments) via `POST /v1/admin/merchants/undo` with `action_id` from `audit_logs`.  
- Cache in Redis Streams (`merchants:page:{page}`).  
- Log to PostHog (`merchant_list_viewed` event, `ui_action:merchant_list_viewed`, 80%+ usage target).  
- Show error in Polaris `Banner` (e.g., "No merchants found") for empty list (404).  
- Support 5,000+ merchants with partitioning by `merchant_id`.  
- **Accessibility**: ARIA label (`aria-label="Search merchants"`) for search field, screen reader support for table, RTL for Arabic.  
- **Testing**: Jest test for `MerchantsPage` component, Cypress E2E test for merchant search and undo actions, k6 test for 5,000 merchants.

**US-AM3: Adjust Customer Points**  
As an admin, I want to adjust a customer’s point balance, so that I can correct errors or provide bonuses.  
**Service**: Admin Service (gRPC: `/points.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Customer Points Adjustment.  

**Acceptance Criteria**:  
- Display form for points adjustment via `POST /v1/admin/api/points` (REST) or `/points.v1/AdminService/AdjustPoints` (gRPC), RBAC validated (`admin:full`, `admin:support`).  
- Insert record in `points_transactions` (`type='award'`, partitioned by `merchant_id`).  
- Log to `audit_logs` (`action='points_adjusted'`, `actor_id` from `admin_users`) and PostHog (`points_adjusted` event, `ui_action:points_adjusted`).  
- Support undo action via `POST /v1/admin/merchants/undo` with `action_id`.  
- Update `customers.points_balance` and Redis Streams cache (`points:customer:{customer_id}`).  
- Show confirmation in Polaris `Banner` (e.g., "Points adjusted") or error (e.g., "Invalid points amount") for 400, localized via i18next, RTL support for Arabic.  
- Handle multi-store sync via `/v1/api/points/sync` (Phase 5).  
- **Accessibility**: ARIA label (`aria-label="Adjust customer points"`) for form, screen reader support.  
- **Testing**: Jest test for `PointsAdjustment` component, Cypress E2E test for points adjustment and undo, k6 test for 1,000 concurrent adjustments.

**US-AM4: Manage Admin Users**  
As an admin, I want to add/edit/delete admin users, so that I can control platform access.  
**Service**: Auth Service (gRPC: `/auth.v1/*`, Dockerized).  
**Wireframe**: Admin Module - User Management.  

**Acceptance Criteria**:  
- Display list from `admin_users` (username, `metadata: JSONB` encrypted with AES-256) via `GET /v1/admin/users` (REST) or `/auth.v1/AuthService/ListUsers` (gRPC), RBAC validated (`admin:full`).  
- Provide forms for CRUD via `POST/PUT/DELETE /v1/admin/users` (REST) or `/auth.v1/*` (gRPC), with MFA via Auth0.  
- Validate unique username/email, encrypt password (Bcrypt, AES-256 via `pgcrypto`).  
- Assign RBAC roles (`admin:full`, `admin:analytics`, `admin:support`) in `admin_users.metadata`.  
- Log to `audit_logs` (`action='user_updated'`) and PostHog (`admin_user_updated` event, `ui_action:user_updated`).  
- Show confirmation in Polaris `Banner` (e.g., "User added") or error (e.g., "Username exists") for 400, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Detect anomalies (e.g., >100 points adjustments/hour) with alerts via AWS SNS.  
- **Accessibility**: ARIA label (`aria-label="Add admin user"`) for form actions, RTL support for Arabic.  
- **Testing**: Jest test for `AdminUsers` component, Cypress E2E test for user management with MFA, OWASP ZAP for security.

**US-AM5: Access Logs**  
As an admin, I want to access API and audit logs in real-time, so that I can monitor platform activity.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Log Viewer.  

**Acceptance Criteria**:  
- Stream logs from `api_logs`, `audit_logs` (e.g., `action='tier_assigned'`, `points_adjusted`, `config_updated`) via `GET /v1/admin/logs` (REST) or `/admin.v1/AdminService/GetLogs` (gRPC) with WebSocket for real-time updates, RBAC validated (`admin:full`, `admin:analytics`).  
- Filter by `date`/`merchant_id`/`action` using Polaris `Select`, `TextField`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Show details (e.g., "Points adjusted by Admin1") in Polaris `DataTable`, with undo option for reversible actions (e.g., point adjustments).  
- Cache in Redis Streams (`logs:merchant:{merchant_id}:page`).  
- Log to PostHog (`logs_viewed` event, `ui_action:logs_viewed`, 80%+ usage target).  
- Show error in Polaris `Banner` (e.g., "No logs found") for empty logs (404).  
- Support log replay for QA via `dev.sh` script.  
- Handle 5,000 merchants with PostgreSQL partitioning and Loki + Grafana for centralized logging.  
- **Accessibility**: ARIA label (`aria-label="Filter logs"`) for filters, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `LogsViewer` component, Cypress E2E test for log filtering and streaming, k6 test for 5,000 concurrent log views.

**US-AM6: Support GDPR Requests**  
As an admin, I want to process customer GDPR requests, so that I can comply with GDPR/CCPA requirements.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - GDPR Request Dashboard.  

**Acceptance Criteria**:  
- Receive via Shopify `GET /v1/customers/data_request`, `customers/redact` webhooks, insert into `gdpr_requests` (`request_type='data_request'|'redact'`, partitioned by `merchant_id`, `retention_expires_at` for 90-day retention).  
- Query `customers`, `points_transactions`, `reward_redemptions`, `rfm_score_history` (AES-256 encrypted fields) for customer data.  
- Send data via Klaviyo/Postscript (Bull queue, `email_templates.body`, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`, 3 retries) using Redis Streams (`gdpr_data:merchant:{merchant_id}`).  
- Log to `audit_logs` (`action='gdpr_processed'`, `actor_id`) and PostHog (`gdpr_processed` event, `ui_action:gdpr_processed`, 90%+ success rate).  
- Show request status in Polaris `DataTable`, localized via i18next, RTL support for Arabic.  
- Ensure 90-day backup retention in Backblaze B2 for compliance via Dockerized backup service.  
- Show error in Polaris `Banner` (e.g., "Request processing failed") for webhook errors (400).  
- Support async processing for 50,000+ customers.  
- **Accessibility**: ARIA label (`aria-label="Process GDPR request"`) for actions, screen reader support.  
- **Testing**: Jest test for `GDPRDashboard` component, Cypress E2E test for request processing, k6 test for 1,000 concurrent requests, OWASP ZAP for security.

### Phase 2: Enhanced Admin Functions

**US-AM7: Manage Merchant Plans**  
As an admin, I want to upgrade/downgrade merchant plans, so that I can manage their subscriptions.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Plan Management.  

**Acceptance Criteria**:  
- Display current plan from `merchants.plan_id` (e.g., Free: 300 orders, $29/mo: 500 orders, $99/mo: 1500 orders) via `GET /v1/admin/merchants` (REST) or `/admin.v1/AdminService/ListMerchants` (gRPC), RBAC validated (`admin:full`).  
- Provide form to change plan via `PUT /v1/admin/plans` (REST) or `/admin.v1/AdminService/UpdatePlan` (gRPC) using Polaris `Select`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Update `merchants.plan_id`, log to `audit_logs` (`action='plan_updated'`, `actor_id`) with undo option via `POST /v1/admin/merchants/undo`.  
- Cache in Redis Streams (`plan:merchant:{merchant_id}`).  
- Log to PostHog (`plan_updated` event, `ui_action:plan_updated`, 90%+ success rate).  
- Show confirmation in Polaris `Banner` (e.g., "Plan updated") or error (e.g., "Invalid plan") for 400, localized with RTL support.  
- Support bulk plan upgrades for merchant referral program (Phase 5).  
- **Accessibility**: ARIA label (`aria-label="Change merchant plan"`) for form, screen reader support.  
- **Testing**: Jest test for `PlanManagement` component, Cypress E2E test for plan changes and undo, k6 test for 1,000 concurrent updates.

**US-AM8: Monitor Integration Status**  
As an admin, I want to check the health of integrations (e.g., Shopify, Klaviyo, Postscript), so that I can ensure platform reliability.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Integration Health Dashboard.  

**Acceptance Criteria**:  
- Check status from `integrations` (`type='shopify'|'klaviyo'|'postscript'|'yotpo'|'judgeme'`, `status='ok'|'error'`) via `GET /v1/admin/health` (REST) or `/admin.v1/AdminService/CheckHealth` (gRPC), RBAC validated (`admin:full`, `admin:support`).  
- Show status (e.g., "Shopify: OK") in Polaris `Card`, with Chart.js visualization for uptime trends, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Allow manual ping to external services (3 retries, exponential backoff) with alerts via AWS SNS (Slack/email).  
- Log checks to `audit_logs` (`action='health_check'`, `actor_id`) and PostHog (`integration_health_checked` event, `ui_action:health_checked`, 95%+ uptime target).  
- Cache in Redis Streams (`health:merchant:{merchant_id}`).  
- Show error in Polaris `Banner` (e.g., "Klaviyo API down") for failed pings (500).  
- Support Shopify Flow templates (Phase 5, e.g., “Integration Down → Notify Admin”).  
- **Accessibility**: ARIA label (`aria-label="Check integration status"`) for ping button, screen reader support for chart.  
- **Testing**: Jest test for `IntegrationHealth` component, Cypress E2E test for health checks, k6 test for 5,000 concurrent pings, Chaos Mesh for resilience.

**US-AM9: Support RFM Configurations**  
As an admin, I want to manage RFM settings for merchants, so that I can optimize segmenting and troubleshoot issues.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - RFM Configuration Admin.  

**Acceptance Criteria**:  
- Display RFM settings from `program_settings.rfm_thresholds` (JSONB, segments: Champions, Loyal, At-Risk, New, Inactive, VIP) via `GET /v1/admin/rfm` (REST) or `/admin.v1/AdminService/GetRfmConfig` (gRPC), RBAC validated (`admin:full`, `admin:analytics`).  
- Provide form to edit thresholds (Recency: ≤7 to >90 days, Frequency: 1 to >10 orders, Monetary: <0.5x to >5x AOV, weights: 30% recency, 40% frequency, 30% monetary) using Polaris `Form`, `RangeSlider`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Support time-weighted recency, lifecycle stages, and industry benchmarks (`rfm_benchmarks`).  
- Preview segment distribution (Chart.js, bar type) using `rfm_segment_counts` materialized view in Polaris `Card`.  
- Cache in Redis Streams (`rfm:preview:merchant:{merchant_id}`).  
- Log to `audit_logs` (`action='rfm_config_updated'`, `actor_id`) and PostHog (`rfm_updated` event, `ui_action:rfm_updated`, 80%+ usage target).  
- Show error in Polaris `Banner` (e.g., "Invalid thresholds") for invalid inputs (400).  
- Support A/B testing for RFM nudges and multi-segment membership (Phase 5).  
- **Accessibility**: ARIA label (`aria-label="Edit RFM config"`) for form fields, screen reader support for chart, RTL for Arabic.  
- **Testing**: Jest test for `RFMConfigAdmin` component, Cypress E2E test for RFM config update, k6 test for 5,000 concurrent previews, OWASP ZAP for security.

**US-AM10 to US-AM13**: *[Unchanged from user_stories.md, omitted for brevity but included in full artifact.]*

**US-AM14: Manage Multi-Tenant Accounts**  
As a support engineer, I want to manage multiple stores under one admin account with scoped permissions, so that I can assist multiple merchants efficiently.  
**Service**: Auth Service (gRPC: `/auth.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Multi-Tenant Management.  

**Acceptance Criteria**:  
- Display list of linked stores from `merchants` (`multi_tenant_group_id`) via `GET /v1/admin/multi-tenant` (REST) or `/auth.v1/AuthService/ListMultiTenantStores` (gRPC), RBAC validated (`admin:full`, `admin:support`, `multi_tenant:group_id`).  
- Provide form to link/unlink stores and assign scoped RBAC roles (e.g., `multi_tenant:group_id:read`) in `admin_users.metadata` (JSONB, AES-256 encrypted) using Polaris `Form`, `Select`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Save via `PUT /v1/admin/multi-tenant` (REST) or `/auth.v1/AuthService/UpdateMultiTenantConfig` (gRPC), with MFA via Auth0.  
- Cache in Redis Streams (`multi_tenant:group:{group_id}`).  
- Log to `audit_logs` (`action='multi_tenant_updated'`, `actor_id`) and PostHog (`multi_tenant_updated` event, `ui_action:multi_tenant_updated`, 80%+ usage target).  
- Show confirmation in Polaris `Banner` (e.g., “Stores linked”) or error (e.g., “Invalid group ID”) for 400, localized with RTL support.  
- Support multi-store sync (Phase 5) via `/v1/api/points/sync`.  
- **Accessibility**: ARIA label (`aria-label="Manage multi-tenant stores"`) for form, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `MultiTenantManagement` component, Cypress E2E test for store linking and RBAC, k6 test for 1,000 concurrent updates, OWASP ZAP for security.

**US-AM15: Replay and Undo Customer Actions**  
As an admin, I want to replay a customer’s point journey or undo a bulk action if it was misconfigured, so that I can fix errors quickly and confidently.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Wireframe**: Admin Module - Action Replay Dashboard.  

**Acceptance Criteria**:  
- Display customer’s point journey (e.g., `points_transactions`, `reward_redemptions`) via `GET /v1/admin/customer/journey` (REST) or `/admin.v1/AdminService/GetCustomerJourney` (gRPC), RBAC validated (`admin:full`, `admin:support`).  
- Provide replay option using `dev.sh` script to simulate actions (e.g., purchase, referral) in sandbox mode, logged in `audit_logs` (`action='journey_replayed'`).  
- Allow undo for bulk actions (e.g., point adjustments) via `POST /v1/admin/merchants/undo` with `action_id` from `audit_logs`, updating `points_transactions` and `customers.points_balance`.  
- Cache in Redis Streams (`journey:customer:{customer_id}`).  
- Log to PostHog (`journey_replayed` event, `ui_action:journey_replayed`, 90%+ success rate).  
- Show confirmation in Polaris `Banner` (e.g., “Action undone”) or error (e.g., “Non-reversible action”) for 400, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Support 5,000 concurrent replays with PostgreSQL partitioning and circuit breakers.  
- **Accessibility**: ARIA label (`aria-label="Replay customer journey"`) for replay button, screen reader support, RTL for Arabic.  
- **Testing**: Jest test for `ActionReplay` component, Cypress E2E test for replay and undo, k6 test for 1,000 concurrent replays, OWASP ZAP for security.

**US-AM16: Simulate RFM Segment Transitions**  
As a QA or support user, I want to simulate how a customer would move through different RFM segments based on order events, so that I can debug or validate scoring.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Wireframe**: Admin Module - RFM Simulation Dashboard.  

**Acceptance Criteria**:  
- Provide form to input mock order events (e.g., order date, amount) via `POST /v1/admin/rfm/simulate` (REST) or `/analytics.v1/AnalyticsService/SimulateRFMSegments` (gRPC), RBAC validated (`admin:full`, `admin:analytics`).  
- Simulate RFM scores (`rfm_score_history`, weights: 30% recency, 40% frequency, 30% monetary) in sandbox mode (`dev.sh`), updating `rfm_segment_counts` materialized view.  
- Display segment transitions (e.g., “New → Loyal”) in Chart.js (line type) within Polaris `Card`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Cache in Redis Streams (`rfm_simulation:merchant:{merchant_id}`).  
- Log to PostHog (`rfm_simulation_run` event, `ui_action:rfm_simulation_run`, 80%+ usage target).  
- Show error in Polaris `Banner` (e.g., “Invalid event data”) for 400 errors, localized with RTL support.  
- Support 5,000 concurrent simulations with PostgreSQL partitioning and circuit breakers.  
- **Accessibility**: ARIA label (`aria-label="Simulate RFM segments"`) for simulation form, screen reader support for chart, RTL for Arabic.  
- **Testing**: Jest test for `RFMSimulation` component, Cypress E2E test for simulation and visualization, k6 test for 5,000 concurrent simulations, OWASP ZAP for security.

## Backend Integrations (Phase 1, 2, 3)

### Phase 1: Backend

**US-BI1: Sync Shopify Orders**  
As a system API, I want to sync orders via Shopify webhooks, so that points can be awarded automatically.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Integration**: Shopify Webhooks.  

**Acceptance Criteria**:  
- Accept webhook `POST /v1/api/orders/points`, validate HMAC with Redis idempotency key, call `POST /v1/api/points/earn` (REST) or `/points.v1/PointsService/EarnPoints` (gRPC).  
- Insert record in `points_transactions` (`type='earn'`, partitioned by `merchant_id`).  
- Update `customers.points_balance` and Redis Streams cache (`points:customer:{customer_id}`).  
- Log to `api_logs`, `audit_logs` (`action='points_earned'`) and PostHog (`points_earned` event, 20%+ redemption rate target).  
- Handle duplicates (no-op) or invalid HMAC (400) with error logging to Loki + Grafana.  
- Support 10,000 orders/hour (Black Friday) with PostgreSQL partitioning and circuit breakers.  
- Support multi-store sync via `/v1/api/points/sync` (Phase 5).  
- **Testing**: Jest test for webhook handler, k6 load test for 10,000 orders/hour, Chaos Mesh for resilience, OWASP ZAP for security.

**US-BI2: Send Referral Notifications**  
As a system API, I want to send referral notifications via email/Klaviyo or SMS/Postscript, so that customers are informed of their rewards.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Integration**: Klaviyo/Postscript, Email/SMS.  

**Acceptance Criteria**:  
- Fetch template from `email_templates.body` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'ar']`) via `GET /v1/api/templates` (REST) or `/referrals.v1/ReferralService/GetTemplates` (gRPC).  
- Queue notification via Bull queue for Klaviyo/Postscript (3 retries, exponential backoff), monitored via `QueuesPage.tsx` with Chart.js.  
- Insert record in `events` (`event_type='referral_created'|'referral_completed'|'merchant_referral_created'`, partitioned by `merchant_id`).  
- Cache in Redis Streams (`notification:referral:{referral_id}`).  
- Log to PostHog (`notification_sent` event, `ui_action:notification_sent`, 7%+ SMS conversion, 3%+ email conversion).  
- Handle API errors (429) with retry logic and error logging to Loki + Grafana.  
- Support A/B testing for referral nudges (Phase 5).  
- **Testing**: Jest test for notification queue, Cypress E2E test for notification delivery, k6 test for 1,000 concurrent notifications.

### Phase 2: Advanced Features

**US-BI3: Import Customer Data**  
As a system API, I want to import customer data via integrations, so that merchants can update existing customer programs.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Integration**: CSV/REST Imports.  

**Acceptance Criteria**:  
- Call `POST /v1/api/customers/import` (REST) or `/admin.v1/AdminService/ImportCustomers` (gRPC) with CSV (max 10MB, fields: `customer_id`, `email`, `points`, `rfm_score`).  
- Validate data (unique emails, RFM scores 1–5), insert into `customers` (AES-256 encrypted `email`, `points_balance`, `rfm_score: JSONB`), `points_transactions` (`type='import'`, partitioned by `merchant_id`), and `rfm_score_history`.  
- Process 50,000+ records asynchronously under 4 minutes (Plus-scale) via Bull queue, monitored in `QueuesPage.tsx` with Chart.js.  
- Log to `audit_logs` (`action='customer_imported'`, `actor_id`) and PostHog (`customer_import_completed` event, `ui_action:import_completed`, 90%+ success rate).  
- Cache progress in Redis Streams (`import:merchant:{merchant_id}`).  
- Show progress via WebSocket in Polaris `ProgressBar`, localized via i18next (`en`, `es`, `fr`, `ar` with RTL).  
- Show error in Polaris `Banner` (e.g., "Invalid CSV format") for validation errors (400).  
- Ensure GDPR compliance with `gdpr_requests` check and 90-day backup retention in Backblaze B2.  
- **Testing**: Jest test for import handler, k6 test for 50,000+ records, Cypress E2E test for import UI flow, OWASP ZAP for security.

### Phase 3: Advanced Features

**US-BI4: Apply Campaign Discounts**  
As a system API, I want to apply discounts from bonus campaigns, so that customers can receive promotional rewards.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Integration**: Shopify Discounts, Campaign Logic.  

**Acceptance Criteria**:  
- Check `bonus_campaigns` for active campaigns via Rust/Wasm Shopify Function (`calc_points`) with RFM conditions (e.g., Champions only, `customers.rfm_score`).  
- Validate `customer_id` eligibility (`program_settings`, `bonus_campaigns.conditions: JSONB`).  
- Insert record in `reward_redemptions` (partitioned by `merchant_id`, `campaign_id`, AES-256 encrypted `discount_code`).  
- Log to `api_logs`, `audit_logs` (`action='campaign_discount_applied'`), and PostHog (`campaign_discount_applied` event, `ui_action:campaign_discount`, 15%+ redemption target for Plus).  
- Update `customers.points_balance` and Redis Streams cache (`discounts:merchant:{merchant_id}`).  
- Handle expired campaigns (no-op, 400) or rate limits (429, 3 retries with circuit breakers).  
- Support Shopify Flow templates (Phase 5, e.g., “Campaign Discount Applied → Notify Customer”).  
- **Testing**: Jest test for campaign handler, Cypress E2E test for discount application, k6 test for 5,000 concurrent redemptions