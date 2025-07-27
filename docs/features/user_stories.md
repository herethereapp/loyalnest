# LoyalNest App User Stories

## Merchant Dashboard (Phases 1–3)

### Phase 1: Core Management

**US-MD1: Complete Setup Tasks**  
As a merchant, I want to complete setup tasks on the Welcome Page, so that I can launch my loyalty program.  
**Acceptance Criteria**:  
- Display tasks (e.g., "Launch Program", "Add Widget") from `program_settings` in Polaris `Checklist`.  
- Allow checking tasks via `POST /v1/api/settings/setup`.  
- Save progress to `merchants.setup_progress` (JSONB).  
- Show congratulatory Polaris `Banner` on completion, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`setup_completed`, 80%+ completion).  
- **Accessibility**: ARIA label (`aria-label="Complete setup task"`), keyboard-navigable.  
- **Testing**: Jest (`SetupPage.tsx`), Cypress E2E, k6 (1,000 merchants).

**US-MD2: Configure Points Program**  
As a merchant, I want to configure earning and redemption rules, so that I can customize the loyalty program.  
**Acceptance Criteria**:  
- Display form for earning (e.g., "10 points/$") and redemptions (e.g., "$5 off: 500 points") in Polaris `Form`.  
- Save to `program_settings.config` (JSONB) via `PUT /v1/api/points-program`.  
- Preview rewards panel branding in real-time.  
- Toggle program status, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`points_configured`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Configure points"`), WCAG 2.1 AA.  
- **Testing**: Jest (`PointsPage.tsx`), Cypress, k6 (1,000 merchants).

**US-MD3: Manage Referrals Program**  
As a merchant, I want to configure the referrals program, so that I can incentivize customer referrals.  
**Acceptance Criteria**:  
- Display form for SMS/email/WhatsApp config (Klaviyo/Postscript) and rewards in Polaris `Form`.  
- Save to `program_settings.config` via `PUT /v1/api/referrals/config`.  
- Preview referral popup, toggle status, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`referrals_configured`, 7%+ SMS conversion).  
- **Accessibility**: ARIA label (`aria-label="Configure referrals"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`ReferralsPage.tsx`), Cypress, k6 (1,000 merchants).

**US-MD4: View Customer List**  
As a merchant, I want to view and search my customer list, so that I can manage customer data.  
**Acceptance Criteria**:  
- Display list from `customers` (name, email, points, RFM) via `GET /v1/api/customers` in Polaris `DataTable`.  
- Search by name/email, show details on click.  
- Handle empty list with Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`customer_list_viewed`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Search customers"`), screen reader support.  
- **Testing**: Jest (`CustomersPage.tsx`), Cypress, k6 (5,000 customers).

**US-MD5: View Basic Analytics**  
As a merchant, I want to view basic analytics (e.g., members, points issued), so that I can monitor program performance.  
**Acceptance Criteria**:  
- Display metrics from `customers`, `points_transactions` via `GET /v1/api/analytics` in Polaris `Card`.  
- Show Chart.js bar chart for RFM segments (`rfm_segment_counts`), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Handle API errors with fallback Polaris `Banner`.  
- Log to PostHog (`analytics_viewed`, 80%+ view rate).  
- **Accessibility**: ARIA label (`aria-live="Analytics data available"`), WCAG 2.1 AA.  
- **Testing**: Jest (`AnalyticsPage.tsx`), Cypress, k6 (5,000 merchants).

**US-MD6: Configure Store Settings**  
As a merchant, I want to configure store details and billing, so that I can manage my account.  
**Acceptance Criteria**:  
- Display form for store name, billing plan (Free: 300 orders, $29/mo: 500 orders) in Polaris `Form`.  
- Save to `merchants` (`plan_id`) via `PUT /v1/api/settings`.  
- Validate inputs, show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`settings_updated`, 90%+ success).  
- **Accessibility**: ARIA label (`aria-label="Configure store settings"`).  
- **Testing**: Jest (`SettingsPage.tsx`), Cypress, k6 (1,000 merchants).

**US-MD7: Customize On-Site Content**  
As a merchant, I want to customize loyalty page and popups, so that I can align with my brand.  
**Acceptance Criteria**:  
- Display editor for loyalty page, rewards panel, launcher button in Polaris `Form`.  
- Save to `program_settings.branding` (JSONB) via `PUT /v1/api/content`.  
- Preview in real-time, support post-purchase popup, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`content_updated`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Customize content"`), WCAG 2.1 AA.  
- **Testing**: Jest (`ContentPage.tsx`), Cypress, k6 (1,000 merchants).

### Phase 2: Enhanced Management

**US-MD8: Configure VIP Tiers**  
As a merchant, I want to set up VIP tiers based on spending, so that I can reward loyal customers.  
**Acceptance Criteria**:  
- Display form for tiers (e.g., "Gold: $500") and perks in Polaris `Form`.  
- Save to `vip_tiers` via `POST /v1/api/vip-tiers`.  
- Preview tier structure, notify customers via `email_templates`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`vip_tiers_configured`, 60%+ engagement).  
- **Accessibility**: ARIA label (`aria-label="Configure VIP tiers"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`VIPTiersPage.tsx`), Cypress, k6 (1,000 merchants).

**US-MD9: View Activity Logs**  
As a merchant, I want to view activity logs for points and referrals, so that I can track customer actions.  
**Acceptance Criteria**:  
- Display logs from `points_transactions`, `referrals` via `GET /v1/api/logs` in Polaris `DataTable`.  
- Filter by customer/date, show details (e.g., "John +200 points"), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Handle empty logs with Polaris `Banner`.  
- Log to PostHog (`logs_viewed`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Filter logs"`), screen reader support.  
- **Testing**: Jest (`LogsPage.tsx`), Cypress, k6 (5,000 logs).

**US-MD10: Configure RFM Settings**  
As a merchant, I want to configure RFM thresholds, so that I can segment customers effectively.  
**Acceptance Criteria**:  
- Display wizard for recency, frequency, monetary settings in Polaris `Form`.  
- Save to `program_settings.config` (JSONB) via `PUT /v1/api/rfm/config`.  
- Preview segment chart (Chart.js), validate thresholds, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`rfm_configured`, 80%+ completion).  
- **Accessibility**: ARIA label (`aria-label="Configure RFM"`), WCAG 2.1 AA.  
- **Testing**: Jest (`RFMPage.tsx`), Cypress, k6 (5,000 merchants).

**US-MD11: Manage Checkout Extensions**  
As a merchant, I want to enable points display at checkout, so that customers can see their balance during purchase.  
**Acceptance Criteria**:  
- Toggle checkout extensions in Polaris `Form`, save to `program_settings.config` via `PUT /v1/api/content`.  
- Preview points display, integrate with Shopify Checkout UI Extensions, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`checkout_extension_enabled`, 85%+ adoption).  
- **Accessibility**: ARIA label (`aria-label="Toggle checkout extensions"`).  
- **Testing**: Jest (`CheckoutPage.tsx`), Cypress, k6 (5,000 checkouts).

### Phase 3: Advanced Features

**US-MD12: Create Bonus Campaigns**  
As a merchant, I want to create time-sensitive bonus campaigns, so that I can boost engagement.  
**Acceptance Criteria**:  
- Display form for campaign type (e.g., double points), dates, multiplier in Polaris `Form`.  
- Save to `bonus_campaigns` via `POST /v1/api/campaigns`.  
- Schedule start/end, show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)).  
- Log to PostHog (`campaign_created`, 10%+ redemption).  
- **Accessibility**: ARIA label (`aria-label="Create campaign"`), RTL support.  
- **Testing**: Jest (`CampaignsPage.tsx`), Cypress, k6 (5,000 campaigns).

**US-MD13: Export Advanced Reports**  
As a merchant, I want to export advanced analytics reports, so that I can analyze program performance.  
**Acceptance Criteria**:  
- Provide export button for RFM/revenue data via `GET /v1/api/analytics/export` in Polaris `Button`.  
- Download CSV from `customer_segments`, `points_transactions`, show progress in Polaris `ProgressBar`, localized via i18next.  
- Log to PostHog (`report_exported`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Export report"`), screen reader support.  
- **Testing**: Jest (`ReportsPage.tsx`), Cypress, k6 (5,000 exports).

**US-MD14: Configure Sticky Bar**  
As a merchant, I want to enable a sticky bar for rewards, so that I can promote the loyalty program.  
**Acceptance Criteria**:  
- Display editor for sticky bar content in Polaris `Form`.  
- Save to `program_settings.branding` via `PUT /v1/api/content`, preview in real-time, localized via i18next.  
- Toggle visibility, log to PostHog (`sticky_bar_configured`, 10%+ click-through).  
- **Accessibility**: ARIA label (`aria-label="Configure sticky bar"`), RTL support.  
- **Testing**: Jest (`StickyBarPage.tsx`), Cypress, k6 (5,000 merchants).

**US-MD15: Use Developer Toolkit**  
As a merchant, I want to configure metafields via a developer toolkit, so that I can customize integrations.  
**Acceptance Criteria**:  
- Display form for metafield settings in Polaris `Form`.  
- Save to `integrations.settings` (JSONB) via `PUT /v1/api/settings/developer`, validate inputs, localized via i18next.  
- Log to PostHog (`metafields_configured`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Configure metafields"`).  
- **Testing**: Jest (`DeveloperPage.tsx`), Cypress, k6 (1,000 merchants).

**US-MD19: Automate Lifecycle Rewards**  
As a merchant, I want to automatically send rewards or campaigns when a customer’s RFM score drops or tier changes, so that I can re-engage them before they churn.  
**Acceptance Criteria**:  
- Display automation form for RFM/tier triggers in Polaris `Form`.  
- Save to `bonus_campaigns` (JSONB) via `PUT /v1/api/campaigns/lifecycle`, trigger via Shopify Flow, localized via i18next.  
- Log to PostHog (`lifecycle_campaign_triggered`, 15%+ redemption).  
- **Accessibility**: ARIA label (`aria-label="Configure lifecycle automation"`), RTL support.  
- **Testing**: Jest (`LifecyclePage.tsx`), Cypress, k6 (5,000 triggers).

**US-MD20: View Segment Benchmarking**  
As a merchant, I want to see how my loyalty segments compare with similar businesses, so that I can evaluate performance.  
**Acceptance Criteria**:  
- Display comparison from `rfm_segment_counts`, `rfm_benchmarks` via `GET /v1/api/rfm/benchmarks` in Chart.js bar chart.  
- Ensure GDPR-compliant anonymized data, localized via i18next.  
- Log to PostHog (`benchmarks_viewed`, 80%+ view rate).  
- **Accessibility**: ARIA label (`aria-live="Segment benchmark data available"`), WCAG 2.1 AA.  
- **Testing**: Jest (`BenchmarkingPage.tsx`), Cypress, k6 (5,000 views).

**US-MD21: A/B Test Nudges**  
As a merchant, I want to test different nudges with different copy or designs, so that I can optimize conversions.  
**Acceptance Criteria**:  
- Display form for A/B test variants in Polaris `Form`.  
- Save to `program_settings.ab_tests` (JSONB) via `PUT /v1/api/nudges/ab-test`, show results in Chart.js, localized via i18next.  
- Log to PostHog (`nudge_ab_tested`, 10%+ click-through).  
- **Accessibility**: ARIA label (`aria-label="Configure nudge A/B test"`), RTL support.  
- **Testing**: Jest (`NudgeABTestPage.tsx`), Cypress, k6 (5,000 nudges).

**US-MD22: Identify Churn Risk Customers**  
As a merchant, I want to see a list of high-spending customers at risk of churning, so that I can take action to win them back.  
**Acceptance Criteria**:  
- Display At-Risk customers (`rfm_segment_counts`) via `GET /v1/api/rfm/churn-risk` in Polaris `DataTable`.  
- Support xAI API (Phase 6, https://x.ai/api), GDPR-compliant AES-256 encryption, localized via i18next.  
- Log to PostHog (`churn_risk_viewed`, 80%+ view rate).  
- **Accessibility**: ARIA label (`aria-label="View churn risk customers"`), RTL support.  
- **Testing**: Jest (`ChurnRiskPage.tsx`), Cypress, k6 (5,000 views).

**US-MD23: Customize Notification Templates**  
As a merchant, I want to create and preview notification templates in real-time, so that I can tailor customer communications.  
**Acceptance Criteria**:  
- Display editor for templates in Polaris `Form` with live preview.  
- Save to `email_templates.body` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja']`) via `POST /v1/api/templates`, localized via i18next.  
- Log to PostHog (`template_edited`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Edit notification template"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`NotificationTemplatePage.tsx`), Cypress, k6 (1,000 templates).

**US-MD24: View Usage Thresholds and Upgrade Nudges**  
As a merchant, I want to see my plan’s usage (e.g., SMS referral limit) with nudges to upgrade, so that I can access more features.  
**Acceptance Criteria**:  
- Display usage in Polaris `ProgressBar`, nudge via Polaris `Banner` (`GET /v1/api/plan/usage`).  
- Trigger upgrade CTA for $29/month plan, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`plan_limit_warning`, 10%+ conversion).  
- **Accessibility**: ARIA label (`aria-label="View plan usage"`), WCAG 2.1 AA.  
- **Testing**: Jest (`UsagePage.tsx`), Cypress, k6 (1,000 merchants).

**US-MD25: Receive Contextual Tips**  
As a merchant, I want to receive contextual tips during onboarding and usage, so that I can optimize my loyalty program.  
**Acceptance Criteria**:  
- Display 2 tips/day in Polaris `Banner` (e.g., “Enable birthday bonus for 10%+ referral uplift”) via `GET /v1/api/tips`.  
- Log to PostHog (`tip_viewed`, 80%+ engagement), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="View contextual tip"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`TipsBanner.tsx`), Cypress, k6 (5,000 tips).

**US-MD26: Manage POS Offline Points**  
As a merchant, I want to award/redeem points via Shopify POS in offline mode, so that I can maintain loyalty during connectivity issues.  
**Acceptance Criteria**:  
- Sync points via SQLite queue, `POST /v1/api/points/pos`, reconcile on reconnect.  
- Show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`pos_offline_used`, 90%+ sync success).  
- **Accessibility**: ARIA label (`aria-label="Manage POS points"`).  
- **Testing**: Jest (`POSPage.tsx`), Cypress, k6 (1,000 POS transactions).

**US-MD27: Monitor Rate Limits**  
As a merchant, I want to view and receive alerts for Shopify API rate limit usage, so that I can avoid disruptions.  
**Acceptance Criteria**:  
- Display usage in Polaris `DataTable`, AWS SNS alerts at 80% limit via `GET /v1/api/rate-limits`.  
- Log to PostHog (`rate_limit_viewed`, 90%+ alert delivery), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="View rate limits"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`RateLimitPage.tsx`), Cypress, k6 (1,000 merchants).

**US-MD28: Invite Merchants via Referral Program**  
As a merchant, I want to invite other merchants and earn credits, so that I can reduce costs.  
**Acceptance Criteria**:  
- Generate referral link via `POST /v1/api/referrals/merchant`, share via email/SMS.  
- Award $50 credit on signup, log to PostHog (`merchant_referral_created`, 10%+ conversion), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Share merchant referral"`), RTL support.  
- **Testing**: Jest (`MerchantReferralPage.tsx`), Cypress, k6 (1,000 referrals).

**US-MD29: Integrate Non-Shopify POS**  
As a merchant, I want to award/redeem points via Square or Lightspeed, so that I can support in-store loyalty.  
**Acceptance Criteria**:  
- Integrate via Square/Lightspeed APIs, `POST /v1/api/points/non-shopify`.  
- Show confirmation in Polaris `Banner`, log to PostHog (`non_shopify_pos_used`, 90%+ sync success), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)).  
- **Accessibility**: ARIA label (`aria-label="Manage non-Shopify POS"`).  
- **Testing**: Jest (`NonShopifyPOSPage.tsx`), Cypress, k6 (1,000 transactions).

**US-MD30: Complete 3-Step Onboarding**  
As a merchant, I want a guided 3-step onboarding flow, so that I can quickly set up RFM, referrals, and checkout extensions.  
**Acceptance Criteria**:  
- Display Polaris `Checklist` for RFM wizard, referral config, checkout extensions via `POST /v1/api/setup`.  
- Log to PostHog (`onboarding_completed`, 80%+ completion), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Complete onboarding step"`), WCAG 2.1 AA.  
- **Testing**: Jest (`OnboardingPage.tsx`), Cypress, k6 (1,000 merchants).

## Customer Widget (Phases 1–3)

### Phase 1: Core Loyalty Features

**US-CW1: View Points Balance**  
As a customer, I want to view my current points balance in the Customer Widget, so that I can track my loyalty rewards.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display balance in Polaris `Badge` via `GET /v1/api/customer/points`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`points:customer:{customer_id}`), update within 1s.  
- Log to PostHog (`points_balance_viewed`, 80%+ engagement).  
- **Accessibility**: ARIA label (`aria-label="View points balance"`), WCAG 2.1 AA.  
- **Testing**: Jest (`PointsBalance.tsx`), Cypress, k6 (10,000 requests), OWASP ZAP.

**US-CW2: Earn Points from Purchase**  
As a customer, I want to earn points automatically when I make a purchase, so that I can accumulate rewards.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Trigger `POST /v1/api/points/earn` on Shopify `orders/create` webhook, insert into `points_transactions`.  
- Show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`points_earned`, 20%+ redemption rate).  
- **Accessibility**: ARIA label (`aria-label="Points earned notification"`).  
- **Testing**: Jest (`PurchaseConfirmation.tsx`), Cypress, k6 (10,000 orders/hour).

**US-CW3: Redeem Points for Discount**  
As a customer, I want to redeem points for a discount, so that I can save money on purchases.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- List rewards from `rewards` via `GET /v1/api/customer/points`, redeem via `POST /v1/api/redeem`.  
- Create Shopify discount code, show in Polaris `Modal`, localized via i18next.  
- Log to PostHog (`points_redeemed`, 20%+ redemption rate).  
- **Accessibility**: ARIA label (`aria-label="Redeem points"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`RewardsRedemption.tsx`), Cypress, k6 (5,000 redemptions).

**US-CW4: Share Referral Link**  
As a customer, I want to share a referral link via SMS, email, or social media, so that I can invite friends and earn rewards.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Generate `referral_code` via `POST /v1/api/referrals/create`, show in Polaris `Modal`.  
- Queue notification via Bull, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`referral_created`, 7%+ SMS conversion).  
- **Accessibility**: ARIA label (`aria-label="Send referral invite"`), RTL support.  
- **Testing**: Jest (`ReferralPopup.tsx`), Cypress, k6 (1,000 shares).

**US-CW5: Earn Referral Reward**  
As a customer, I want to earn points when a friend signs up using my referral link, so that I am rewarded for inviting others.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Trigger `POST /v1/api/referrals/complete`, insert into `referrals`, update `points_transactions`.  
- Show confirmation in Polaris `Banner`, localized via i18next.  
- Log to PostHog (`referral_completed`, 7%+ conversion).  
- **Accessibility**: ARIA label (`aria-label="Referral reward notification"`).  
- **Testing**: Jest (`ReferralConfirmation.tsx`), Cypress, k6 (1,000 completions).

**US-CW6: Adjust Points for Cancelled Order**  
As a customer, I want my points balance to be adjusted if an order is cancelled, so that my balance reflects accurate purchases.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Trigger `POST /v1/api/webhooks/orders/cancelled`, insert into `points_transactions`.  
- Update balance in Polaris `Badge`, localized via i18next.  
- Log to PostHog (`points_adjusted`).  
- **Accessibility**: ARIA label (`aria-label="Points adjusted notification"`).  
- **Testing**: Jest (`PointsHistory.tsx`), Cypress, k6 (10,000 orders/hour).

**US-CW7: View Referral Status**  
As a customer, I want to view the detailed status of my referrals, so that I can track my rewards.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display status from `referrals` via `GET /v1/api/referrals/status` in Polaris `DataTable`, `ProgressBar`.  
- Cache in Redis Streams, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`referral_status_viewed`, 60%+ engagement).  
- **Accessibility**: ARIA label (`aria-label="View referral status"`), RTL support.  
- **Testing**: Jest (`ReferralStatus.tsx`), Cypress, k6 (5,000 views).

**US-CW8: Request GDPR Data Access/Deletion**  
As a customer, I want to request access to or deletion of my data via the widget, so that I can exercise my privacy rights.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display GDPR form in Polaris `Modal`, submit via `POST /v1/api/gdpr`.  
- Insert into `gdpr_requests`, notify via Klaviyo/Postscript, localized via i18next.  
- Log to PostHog (`gdpr_request_submitted`, 50%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Submit GDPR request"`), RTL support.  
- **Testing**: Jest (`GDPRForm.tsx`), Cypress, k6 (1,000 requests), OWASP ZAP.

### Phase 2: Enhanced Features

**US-CW9: View VIP Tier Status**  
As a customer, I want to view my VIP tier status and progress, so that I can understand my benefits.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display tier and progress via `GET /v1/api/vip-tiers/status` in Polaris `Card`.  
- Cache in Redis Streams, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Log to PostHog (`vip_tier_viewed`, 60%+ engagement).  
- **Accessibility**: ARIA label (`aria-label="View VIP perks"`), RTL support.  
- **Testing**: Jest (`VIPTier.tsx`), Cypress, k6 (5,000 views).

**US-CW10: Receive RFM Nudges**  
As a customer, I want to receive personalized nudges encouraging engagement, so that I remain active in the loyalty program.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display nudge from `nudges` via `GET /v1/api/nudges` in Polaris `Banner`/`Modal`.  
- Log interactions to `nudge_events`, PostHog (`nudge_dismissed`, 10%+ click-through), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Dismiss nudge"`), RTL support.  
- **Testing**: Jest (`NudgeBanner.tsx`), Cypress, k6 (5,000 nudges).

**US-CW11: Earn Gamification Badges**  
As a customer, I want to earn badges for actions, so that I feel motivated to engage.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Trigger `POST /v1/api/gamification/action`, insert into `gamification_achievements`.  
- Display badge in Polaris `Card`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)).  
- Log to PostHog (`badge_earned`, 20%+ engagement).  
- **Accessibility**: ARIA label (`aria-label="View badges"`).  
- **Testing**: Jest (`BadgesSection.tsx`), Cypress, k6 (5,000 actions).

**US-CW12: View Leaderboard Rank**  
As a customer, I want to view my rank on a leaderboard, so that I can compete with others.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display rank from Redis sorted set via `GET /v1/api/gamification/leaderboard` in Polaris `Card`.  
- Log to PostHog (`leaderboard_viewed`, 15%+ engagement), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="View leaderboard"`), RTL support.  
- **Testing**: Jest (`Leaderboard.tsx`), Cypress, k6 (5,000 views).

**US-CW13: Select Language**  
As a customer, I want to select my preferred language in the widget, so that I can interact in my native language.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display dropdown from `merchants.language` (JSONB, `en`, `es`, `fr`, `de`, `pt`, `ja` in Phases 2–5; others in Phase 6) via `GET /v1/api/widget/config`.  
- Persist in `localStorage`, log to PostHog (`language_selected`, 10%+ usage), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Select language"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`LanguageSelector.tsx`), Cypress, Lighthouse CI.

**US-CW14: Interact with Sticky Bar**  
As a customer, I want to view and interact with a sticky bar promoting the loyalty program, so that I can join or redeem rewards.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display sticky bar from `program_settings.sticky_bar` via `GET /v1/api/widget/config` in Polaris `Banner`.  
- Log clicks to PostHog (`sticky_bar_clicked`, 10%+ click-through), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Join loyalty program"`), RTL support.  
- **Testing**: Jest (`StickyBar.tsx`), Cypress, k6 (5,000 views).

**US-CW15: View Post-Purchase Widget**  
As a customer, I want to view my points earned post-purchase with a referral CTA, so that I can engage further.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display points and CTA via `GET /v1/api/points/earn` in Polaris `Card`.  
- Log clicks to PostHog (`post_purchase_viewed`, 15%+ click-through), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="View points earned"`), RTL support.  
- **Testing**: Jest (`PostPurchaseWidget.tsx`), Cypress, k6 (5,000 views).

**US-CW16: View Progressive Tier Engagement**  
As a customer, I want to see actions needed to reach the next VIP tier, so that I stay motivated.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display progress and actions via `GET /v1/api/vip-tiers/progress` in Polaris `Card`, `ProgressBar`.  
- Log to PostHog (`tier_progress_viewed`, 60%+ engagement), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="View tier progress"`), RTL support.  
- **Testing**: Jest (`TierProgress.tsx`), Cypress, k6 (5,000 views).

**US-CW17: Save Loyalty Balance to Mobile Wallet**  
As a customer, I want to save my loyalty balance to my Apple/Google Wallet, so that I can check rewards on the go.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Generate pass via `GET /v1/api/wallet/pass`, store in `wallet_passes` (AES-256).  
- Log to PostHog (`wallet_pass_added`, 10%+ click-through), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Add to wallet"`), RTL support.  
- **Testing**: Jest (`WalletIntegration.tsx`), Cypress, k6 (5,000 requests).

### Phase 3: Advanced Features

[US-MD19–MD22 unchanged, included above for completeness.]

## Admin Module (Phases 1–3)

### Phase 1: Core Admin Functions

**US-AM1: View Merchant Overview**  
As an admin, I want to view an overview of all merchants, so that I can monitor platform usage.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display metrics via `GET /v1/admin-overview` in Chart.js bar chart, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams, log to PostHog (`overview_viewed`, 90%+ view rate).  
- **Accessibility**: ARIA label (`aria-live="Metrics data available"`), WCAG 2.1 AA.  
- **Testing**: Jest (`OverviewPage.tsx`), Cypress, k6 (5,000 merchants).

**US-AM2: Manage Merchant List**  
As an admin, I want to view and search merchants, so that I can manage their accounts.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display list via `GET /v1/admin/merchants` in Polaris `DataTable`, support undo via `POST /v1/admin/merchants/undo`.  
- Log to PostHog (`merchant_list_viewed`, 80%+ usage), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Search merchants"`), RTL support.  
- **Testing**: Jest (`MerchantsPage.tsx`), Cypress, k6 (5,000 merchants).

**US-AM3: Adjust Customer Points**  
As an admin, I want to adjust a customer’s point balance, so that I can correct errors or provide bonuses.  
**Service**: Admin Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Adjust via `POST /v1/admin/api/points`, insert into `points_transactions`, support undo.  
- Log to PostHog (`points_adjusted`, 90%+ success), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Adjust customer points"`).  
- **Testing**: Jest (`PointsAdjustment.tsx`), Cypress, k6 (1,000 adjustments).

**US-AM4: Manage Admin Users**  
As an admin, I want to add/edit/delete admin users, so that I can control platform access.  
**Service**: Auth Service (gRPC: `/auth.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Manage users via `POST/PUT/DELETE /v1/admin/users`, assign RBAC roles, MFA via Auth0.  
- Log to PostHog (`admin_user_updated`, 90%+ success), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Add admin user"`), RTL support.  
- **Testing**: Jest (`AdminUsers.tsx`), Cypress, k6 (1,000 updates), OWASP ZAP.

**US-AM5: Access Logs**  
As an admin, I want to access API and audit logs in real-time, so that I can monitor platform activity.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Stream logs via `GET /v1/admin/logs` with WebSocket, filter by date/merchant/action.  
- Log to PostHog (`logs_viewed`, 80%+ usage), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Filter logs"`), RTL support.  
- **Testing**: Jest (`LogsViewer.tsx`), Cypress, k6 (5,000 log views).

**US-AM6: Support GDPR Requests**  
As an admin, I want to process customer GDPR requests, so that I can comply with GDPR/CCPA requirements.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Process via Shopify webhooks, insert into `gdpr_requests`, notify via Klaviyo/Postscript.  
- Log to PostHog (`gdpr_processed`, 90%+ success), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Process GDPR request"`), RTL support.  
- **Testing**: Jest (`GDPRDashboard.tsx`), Cypress, k6 (1,000 requests), OWASP ZAP.

### Phase 2: Enhanced Admin Functions

**US-AM7: Manage Merchant Plans**  
As an admin, I want to upgrade/downgrade merchant plans, so that I can manage their subscriptions.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Change plan via `PUT /v1/admin/plans`, update `merchants.plan_id`, support undo.  
- Log to PostHog (`plan_updated`, 90%+ success), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Change merchant plan"`), RTL support.  
- **Testing**: Jest (`PlanManagement.tsx`), Cypress, k6 (1,000 updates).

**US-AM8: Monitor Integration Status**  
As an admin, I want to check the health of integrations, so that I can ensure platform reliability.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Check status via `GET /v1/admin/health`, show in Polaris `Card`, Chart.js for uptime.  
- Log to PostHog (`integration_health_checked`, 95%+ uptime), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Check integration status"`).  
- **Testing**: Jest (`IntegrationHealth.tsx`), Cypress, k6 (5,000 pings).

**US-AM9: Support RFM Configurations**  
As an admin, I want to manage RFM settings for merchants, so that I can optimize segmenting.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Edit thresholds via `GET /v1/admin/rfm`, preview in Chart.js, localized via i18next.  
- Log to PostHog (`rfm_updated`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Edit RFM config"`), RTL support.  
- **Testing**: Jest (`RFMConfigAdmin.tsx`), Cypress, k6 (5,000 previews).

**US-AM14: Manage Multi-Tenant Accounts**  
As a support engineer, I want to manage multiple stores under one admin account, so that I can assist merchants efficiently.  
**Service**: Auth Service (gRPC: `/auth.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Manage stores via `GET/PUT /v1/admin/multi-tenant`, assign RBAC roles, MFA via Auth0.  
- Log to PostHog (`multi_tenant_updated`, 80%+ usage), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Manage multi-tenant stores"`), RTL support.  
- **Testing**: Jest (`MultiTenantManagement.tsx`), Cypress, k6 (1,000 updates).

**US-AM15: Replay and Undo Customer Actions**  
As an admin, I want to replay a customer’s point journey or undo a bulk action, so that I can fix errors.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Replay via `GET /v1/admin/customer/journey`, undo via `POST /v1/admin/merchants/undo`.  
- Log to PostHog (`journey_replayed`, 90%+ success), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Replay customer journey"`), RTL support.  
- **Testing**: Jest (`ActionReplay.tsx`), Cypress, k6 (1,000 replays).

**US-AM16: Simulate RFM Segment Transitions**  
As a QA or support user, I want to simulate how a customer moves through RFM segments, so that I can debug scoring.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Simulate via `POST /v1/admin/rfm/simulate`, show transitions in Chart.js.  
- Log to PostHog (`rfm_simulation_run`, 80%+ usage), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Simulate RFM segments"`), RTL support.  
- **Testing**: Jest (`RFMSimulation.tsx`), Cypress, k6 (5,000 simulations).

**US-AM17: Monitor Notification Template Usage**  
As an admin, I want to track notification template usage, so that I can optimize merchant engagement.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display usage via `GET /v1/admin/templates/usage` in Polaris `DataTable`.  
- Log to PostHog (`template_usage_viewed`, 80%+ usage), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="View template usage"`), RTL support.  
- **Testing**: Jest (`TemplateUsagePage.tsx`), Cypress, k6 (1,000 views).

**US-AM18: Toggle Integration Kill Switch**  
As an admin, I want to enable/disable integrations, so that I can manage platform stability.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Toggle via `PUT /v1/admin/integrations/kill-switch`, show in Polaris `Toggle`.  
- Log to PostHog (`kill_switch_toggled`, 95%+ uptime), localized via i18next.  
- **Accessibility**: ARIA label (`aria-label="Toggle integration"`), RTL support.  
- **Testing**: Jest (`KillSwitchPage.tsx`), Cypress, k6 (1,000 toggles).

### Backend Integrations (Phases 1–3)

### Phase 1: Backend

**US-BI1: Sync Shopify Orders**  
As a system API, I want to sync orders via Shopify webhooks, so that points can be awarded automatically.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Accept webhook `POST /v1/api/orders/points`, insert into `points_transactions`.  
- Log to PostHog (`points_earned`, 20%+ redemption rate).  
- **Testing**: Jest (webhook handler), k6 (10,000 orders/hour), OWASP ZAP.

**US-BI2: Send Referral Notifications**  
As a system API, I want to send referral notifications via email/Klaviyo or SMS/Postscript, so that customers are informed.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Queue notification via Bull, fetch template from `email_templates.body` (JSONB).  
- Log to PostHog (`notification_sent`, 7%+ SMS conversion), localized via i18next.  
- **Testing**: Jest (notification queue), Cypress, k6 (1,000 notifications).

### Phase 2: Advanced Features

**US-BI3: Import Customer Data**  
As a system API, I want to import customer data via integrations, so that merchants can update existing programs.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Import via `POST /v1/api/customers/import`, process 50,000+ records via Bull queue.  
- Log to PostHog (`customer_import_completed`, 90%+ success), localized via i18next.  
- **Testing**: Jest (import handler), Cypress, k6 (50,000 records).

### Phase 3: Advanced Features

**US-BI4: Apply Campaign Discounts**  
As a system API, I want to apply discounts from bonus campaigns, so that customers receive promotional rewards.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Check `bonus_campaigns` via Rust/Wasm, insert into `reward_redemptions`.  
- Log to PostHog (`campaign_discount_applied`, 15%+ redemption), localized via i18next.  
- **Testing**: Jest (campaign handler), Cypress, k6 (5,000 redemptions).