# LoyalNest App Wireframes

This document outlines the wireframes for the LoyalNest Shopify App’s UI components, aligning with `flow_diagram.txt` and `user_stories.md`. It covers the Customer Widget, Merchant Dashboard, and Admin Module for Phases 1–3, supporting Shopify Plus merchants (50,000+ customers, 1,000 orders/hour). Wireframes use Shopify Polaris components, Tailwind CSS for styling, i18next for multilingual support (`en`, `es`, `fr`, `ar` with RTL), and ensure accessibility (ARIA labels, Lighthouse CI score 90+). Each wireframe references corresponding user stories and flow diagram components.

## Customer Widget Wireframes (Phase 1, 2, 3)

### Points Balance (US-CW1)
**Description**: Displays the customer’s current points balance in a visually clear format.  
**Components**:  
- **Polaris `Badge`**: Shows points (e.g., “500 Stars”), styled with Tailwind `text-lg font-bold text-green-600`.  
- **Polaris `Banner`**: Displays errors (e.g., “Unable to load balance”) with `status="critical"`.  
- **Container**: Tailwind `p-4 bg-white rounded-lg shadow-md`.  
**Layout**:  
- Centered `Badge` with points balance.  
- Error `Banner` below if API fails (401/404).  
**Accessibility**: ARIA label (`aria-label="View points balance"`, `aria-live="polite"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Fetches from `/points.v1/GetPointsBalance` (G1e), updates in real-time via Shopify webhook (`orders/create`, H1b), caches in Redis (`points:{customer_id}`, J2).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `PointsBalance`, Cypress E2E for display flow, k6 for 10,000 concurrent requests.  

### Purchase Confirmation (US-CW2)
**Description**: Shows points earned post-purchase with a confirmation message.  
**Components**:  
- **Polaris `Banner`**: Displays confirmation (e.g., “You earned 100 points!”) with `status="success"`, Tailwind `animate-fade-in duration-300`.  
- **Polaris `Button`**: “View Balance” linking to Points Balance.  
- **Container**: Tailwind `p-4 bg-gray-50 rounded-lg`.  
**Layout**:  
- Top `Banner` with confirmation message.  
- Bottom `Button` for navigation.  
**Accessibility**: ARIA label (`aria-label="Points earned notification"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Triggered by `/points.v1/EarnPoints` (G1a) via Shopify webhook (`orders/create`, H1b), logs to PostHog (`points_earned`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `PurchaseConfirmation`, Cypress E2E for earning flow, k6 for 10,000 orders/hour.  

### Rewards Redemption (US-CW3)
**Description**: Allows customers to redeem points for rewards (e.g., discounts, free shipping).  
**Components**:  
- **Polaris `Card`**: Lists rewards from `rewards` table, Tailwind `grid grid-cols-2 gap-4`.  
- **Polaris `Modal`**: Displays discount code post-redemption.  
- **Polaris `Banner`**: Shows errors (e.g., “Insufficient points”).  
- **Polaris `Button`**: “Redeem” for each reward, Tailwind `bg-blue-500 hover:bg-blue-600`.  
**Layout**:  
- Grid of `Card` components for each reward (title, points cost, description).  
- `Modal` for confirmation with copyable discount code.  
- Error `Banner` at top if redemption fails.  
**Accessibility**: ARIA label (`aria-label="Redeem points"`), screen reader support for modal, RTL for Arabic.  
**Interactions**: Calls `/points.v1/RedeemReward` (G1b), updates `reward_redemptions` (I6), logs to PostHog (`points_redeemed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `RewardsRedemption`, Cypress E2E for redemption flow, k6 for 5,000 concurrent redemptions.  

### Referral Popup (US-CW4, US-CW5)
**Description**: Enables customers to share referral links and view confirmation of rewards.  
**Components**:  
- **Polaris `Modal`**: Contains sharing options (SMS, email, social), Tailwind `p-4`.  
- **Polaris `Button`**: “Share via SMS/Email/Social” (social in Phase 2), Tailwind `bg-green-500`.  
- **Polaris `Banner`**: Confirmation (e.g., “You earned 50 points!”) or errors.  
**Layout**:  
- `Modal` with sharing buttons and referral link input (copyable).  
- `Banner` for confirmation or errors at top.  
**Accessibility**: ARIA label (`aria-label="Send referral invite"`), keyboard-navigable modal, RTL for Arabic.  
**Interactions**: Calls `/referrals.v1/CreateReferral` (G2a) and `/referrals.v1/CompleteReferral` (G2b), logs to PostHog (`referral_created`, `referral_completed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `ReferralPopup`, Cypress E2E for sharing and reward, k6 for 1,000 concurrent shares.  

### Referral Status Page (US-CW7)
**Description**: Shows detailed referral status (e.g., pending, completed).  
**Components**:  
- **Polaris `DataTable`**: Lists referrals (friend name, status, action), Tailwind `table-auto`.  
- **Polaris `ProgressBar`**: Visualizes referral progress.  
- **Polaris `Banner`**: Errors (e.g., “No referrals found”).  
**Layout**:  
- `DataTable` with columns: Name, Status, Action (e.g., “Signed Up”).  
- `ProgressBar` for visual status.  
- Error `Banner` at top if no data.  
**Accessibility**: ARIA label (`aria-label="View referral status"`, `aria-live="polite"`), RTL for Arabic.  
**Interactions**: Queries `/referrals.v1/GetReferralStatus` (G2d), caches in Redis (`referral_status:{customer_id}`, J11), logs to PostHog (`referral_status_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `ReferralStatus`, Cypress E2E for status display, k6 for 5,000 concurrent views.  

### GDPR Request Form (US-CW8)
**Description**: Allows customers to submit GDPR data access/deletion requests.  
**Components**:  
- **Polaris `Modal`**: Contains `Form` with `Select` (request type) and `TextField` (details).  
- **Polaris `Button`**: “Submit Request”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Modal` with form fields and submit button.  
- `Banner` for confirmation (e.g., “Request submitted”) or errors.  
**Accessibility**: ARIA label (`aria-label="Submit GDPR request"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Submits to `/admin.v1/ProcessGDPRRequest` (G4e), logs to `gdpr_requests` (I21), PostHog (`gdpr_request_submitted`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `GDPRForm`, Cypress E2E for submission, k6 for 1,000 concurrent requests.  

### VIP Tier Dashboard (US-CW9)
**Description**: Displays VIP tier status and perks.  
**Components**:  
- **Polaris `Card`**: Shows tier (e.g., “Silver”), perks, Tailwind `p-4 bg-gray-50`.  
- **Polaris `Banner`**: Errors (e.g., “Tier data unavailable”).  
**Layout**:  
- `Card` with tier name, perks list, and progress to next tier.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-label="View VIP perks"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/points.v1/GetVipTierStatus` (G1f), caches in Redis (`tier:{customer_id}`, J5), logs to PostHog (`vip_tier_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `VIPTier`, Cypress E2E for tier display, k6 for 5,000 concurrent views.  

### Nudge Popup/Banner (US-CW10)
**Description**: Shows personalized RFM nudges (e.g., “Invite a friend!”).  
**Components**:  
- **Polaris `Banner` or `Modal`**: Displays nudge content, Tailwind `animate-fade-in duration-300`.  
- **Polaris `Button`**: “Dismiss” or action (e.g., “Shop Now”), Tailwind `bg-blue-500`.  
**Layout**:  
- `Banner` or `Modal` with nudge message and action/dismiss buttons.  
**Accessibility**: ARIA label (`aria-label="Dismiss nudge"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/analytics.v1/GetNudges` (G3c), logs to `nudge_events` (I20), PostHog (`nudge_dismissed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `NudgeBanner`, Cypress E2E for display/dismissal, k6 for 5,000 concurrent nudges.  

### Badges Section (US-CW11)
**Description**: Displays earned gamification badges.  
**Components**:  
- **Polaris `Card`**: Lists badges, Tailwind `grid grid-cols-3 gap-4`.  
- **Polaris `Banner`**: Errors (e.g., “Action not eligible”).  
**Layout**:  
- Grid of `Card` components for each badge (icon, title).  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-label="View badges"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/analytics.v1/AwardBadge`, logs to `gamification_achievements` (I18), PostHog (`badge_earned`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `BadgesSection`, Cypress E2E for badge earning, k6 for 5,000 concurrent actions.  

### Leaderboard Page (US-CW12)
**Description**: Shows customer’s rank on the leaderboard.  
**Components**:  
- **Polaris `Card`**: Displays rank (e.g., “#5 of 100”), Tailwind `p-4`.  
- **Polaris `Banner`**: Errors (e.g., “Leaderboard unavailable”).  
**Layout**:  
- `Card` with rank and leaderboard summary.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-label="View leaderboard"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/analytics.v1/GetLeaderboard` (G3d), caches in Redis (`leaderboard:{merchant_id}`, J6), logs to PostHog (`leaderboard_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `Leaderboard`, Cypress E2E for rank display, k6 for 5,000 concurrent views.  

### Settings Panel (US-CW13)
**Description**: Allows language selection.  
**Components**:  
- **Polaris `Select`**: Language dropdown (`en`, `es`, `fr`, `ar`), Tailwind `w-full`.  
- **Polaris `Banner`**: Errors (e.g., “Language not supported”).  
**Layout**:  
- `Select` dropdown for language.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-label="Select language"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Queries `/frontend.v1/GetWidgetConfig` (G6b), persists in `localStorage` (J1), logs to PostHog (`language_selected`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `LanguageSelector`, Cypress E2E for language switch, Lighthouse CI for accessibility.  

### Sticky Bar (US-CW14)
**Description**: Promotes loyalty program with a CTA.  
**Components**:  
- **Polaris `Banner`**: Fixed top bar with CTA (e.g., “Earn 1 point/$!”), Tailwind `sm:hidden md:block fixed top-0`.  
- **Polaris `Button`**: “Join Now” or “Redeem”.  
**Layout**:  
- Fixed `Banner` at top with CTA and button.  
**Accessibility**: ARIA label (`aria-label="Join loyalty program"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Queries `/frontend.v1/GetWidgetConfig` (G6b), logs to PostHog (`sticky_bar_clicked`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `StickyBar`, Cypress E2E for click-through, Lighthouse CI for accessibility.  

### Post-Purchase Widget (US-CW15)
**Description**: Shows points earned and referral CTA post-purchase.  
**Components**:  
- **Polaris `Card`**: Displays points and CTA, Tailwind `p-4 bg-gray-50`.  
- **Polaris `Button`**: “Share Referral”, Tailwind `bg-green-500`.  
- **Polaris `Banner`**: Errors (e.g., “Failed to load points”).  
**Layout**:  
- `Card` with points earned and referral CTA.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-label="View points earned"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/points.v1/GetEarnedPoints`, logs to PostHog (`post_purchase_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `PostPurchaseWidget`, Cypress E2E for post-purchase flow, k6 for 5,000 concurrent views.  

### VIP Tier Progress (US-CW16)
**Description**: Shows progress to next VIP tier with recommended actions.  
**Components**:  
- **Polaris `Card`**: Displays tier, progress, actions, Tailwind `p-4`.  
- **Polaris `ProgressBar`**: Visualizes progress (e.g., “$100/$500”).  
- **Polaris `Banner`**: Errors (e.g., “Tier progress unavailable”).  
**Layout**:  
- `Card` with tier name, `ProgressBar`, and action list.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-label="View tier progress"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/points.v1/GetVipTierProgress` (G1g), caches in Redis (`tier_progress:{customer_id}`, J14), logs to PostHog (`tier_progress_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `TierProgress`, Cypress E2E for progress display, k6 for 5,000 concurrent views.  

### Wallet Integration (US-CW17)
**Description**: Allows adding loyalty balance to Apple/Google Wallet.  
**Components**:  
- **Polaris `Button`**: “Add to Wallet”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Confirmation or errors (e.g., “Failed to add to wallet”).  
**Layout**:  
- `Button` for wallet pass generation.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Add to wallet"`), screen reader support, RTL for Arabic.  
**Interactions**: Calls `/points.v1/GenerateWalletPass` (G1h), logs to `wallet_passes` (I26), PostHog (`wallet_pass_added`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `WalletIntegration`, Cypress E2E for pass generation, k6 for 5,000 concurrent requests.  

## Merchant Dashboard Wireframes (Phase 1, 2, 3)

### Welcome Page (US-MD1)
**Description**: Guides merchants through setup tasks and displays congratulatory messages.  
**Components**:  
- **Polaris `Card`**: Lists setup tasks, Tailwind `p-4`.  
- **Polaris `Banner`**: Congratulatory messages or errors.  
**Layout**:  
- `Card` with task checklist (e.g., “Configure Points Program”).  
- `Banner` at top for messages or errors.  
**Accessibility**: ARIA label (`aria-label="Complete setup tasks"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/admin.v1/CompleteSetupTask` (G4a), logs to PostHog (`setup_task_completed`).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `WelcomePage`, Cypress E2E for task flow, k6 for 1,000 concurrent views.  

### Points Program (US-MD2)
**Description**: Configures points earning and redemption settings.  
**Components**:  
- **Polaris `Form`**: Fields for points per dollar, redemption options, Tailwind `grid grid-cols-2`.  
- **Polaris `Button`**: “Save” or “Toggle Status”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with input fields and toggle switch.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Configure points program"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Updates `program_settings` (I7) via `/admin.v1/UpdatePointsProgram` (G4b), logs to PostHog.  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `PointsProgram`, Cypress E2E for configuration, k6 for 1,000 concurrent updates.  

### Lifecycle Automation (US-MD19)
**Description**: Configures RFM/tier-based reward triggers.  
**Components**:  
- **Polaris `Form`**: Fields for triggers (e.g., “At-Risk → 100 points”), Tailwind `grid grid-cols-2`.  
- **Polaris `Select`**: RFM/tier options.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with trigger conditions and save button.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Configure lifecycle automation"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Saves to `bonus_campaigns` (I17) via `/points.v1/CreateCampaign` (G1d), logs to PostHog (`lifecycle_campaign_triggered`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `LifecycleAutomation`, Cypress E2E for setup/trigger, k6 for 5,000 concurrent triggers.  

### Segment Benchmarking (US-MD20)
**Description**: Shows RFM segment comparisons with industry benchmarks.  
**Components**:  
- **Polaris `Card`**: Contains Chart.js bar chart, Tailwind `p-4`.  
- **Polaris `Banner`**: Errors (e.g., “No benchmark data”).  
**Layout**:  
- `Card` with Chart.js bar chart comparing segments.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-live="Segment benchmark data available"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/analytics.v1/GetSegmentBenchmarks` (G3g), caches in Redis (`benchmarks:{merchant_id}`, J16), logs to PostHog (`benchmarks_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `SegmentBenchmarking`, Cypress E2E for display, k6 for 5,000 concurrent views.  

### Nudge A/B Testing (US-MD21)
**Description**: Configures and views A/B test results for nudges.  
**Components**:  
- **Polaris `Form`**: Fields for nudge variants, Tailwind `grid grid-cols-2`.  
- **Polaris `Card`**: Chart.js bar chart for results.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` for variant configuration.  
- `Card` with results chart.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Configure nudge A/B test"`), screen reader support, RTL for Arabic.  
**Interactions**: Configures `program_settings.ab_tests` (I7) via `/analytics.v1/ConfigureNudgeABTest` (G3h), logs to PostHog (`nudge_ab_tested`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `NudgeABTest`, Cypress E2E for setup/results, k6 for 5,000 concurrent interactions.  

### Churn Risk Dashboard (US-MD22)
**Description**: Lists high-spending At-Risk customers.  
**Components**:  
- **Polaris `DataTable`**: Customer details (ID, email, last order, RFM score), Tailwind `table-auto`.  
- **Polaris `Banner`**: Errors (e.g., “No at-risk customers”).  
**Layout**:  
- `DataTable` with customer list.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-label="View churn risk customers"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/analytics.v1/GetChurnRisk` (G3i), caches in Redis (`churn_risk:{merchant_id}`, J18), logs to PostHog (`churn_risk_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `ChurnRiskDashboard`, Cypress E2E for list display, k6 for 5,000 concurrent views.  

## Admin Module Wireframes (Phase 1, 2, 3)

### Overview Dashboard (US-AM1)
**Description**: Displays platform metrics and RFM charts.  
**Components**:  
- **Polaris `Card`**: Contains Chart.js bar chart for RFM segments, Tailwind `p-4`.  
- **Polaris `Badge`**: Shows metrics (e.g., merchant count, points issued).  
- **Polaris `Banner`**: Errors (e.g., “No data”).  
**Layout**:  
- Grid of `Badge` components for metrics.  
- `Card` with RFM chart.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-live="Metrics data available"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/admin.v1/GetOverview` (G4a), caches in Redis (`overview:period:{period}`), logs to PostHog (`overview_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `OverviewPage`, Cypress E2E for metrics display, k6 for 5,000 merchants.  

### Merchant List (US-AM2)
**Description**: Lists and searches merchants with undo options.  
**Components**:  
- **Polaris `TextField`**: Search by ID/domain, Tailwind `w-full`.  
- **Polaris `DataTable`**: Merchant details, Tailwind `table-auto`.  
- **Polaris `Button`**: “Undo Action”.  
- **Polaris `Banner`**: Errors (e.g., “No merchants found”).  
**Layout**:  
- `TextField` for search at top.  
- `DataTable` with merchant list and undo buttons.  
- Error `Banner` at top if no data.  
**Accessibility**: ARIA label (`aria-label="Search merchants"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/admin.v1/ListMerchants` (G4a), caches in Redis (`merchants:page:{page}`), logs to PostHog (`merchant_list_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `MerchantsPage`, Cypress E2E for search/undo, k6 for 5,000 merchants.  

### Customer Points Adjustment (US-AM3)
**Description**: Allows admins to adjust customer points.  
**Components**:  
- **Polaris `Form`**: Fields for customer ID, points amount, Tailwind `grid grid-cols-2`.  
- **Polaris `Button`**: “Adjust Points”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with input fields and submit button.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Adjust customer points"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Calls `/points.v1/AdjustPoints` (G1c), logs to `points_transactions` (I3), PostHog (`points_adjusted`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `PointsAdjustment`, Cypress E2E for adjustment/undo, k6 for 1,000 concurrent adjustments.  

### User Management (US-AM4)
**Description**: Manages admin users with RBAC roles.  
**Components**:  
- **Polaris `DataTable`**: Lists admins (username, roles), Tailwind `table-auto`.  
- **Polaris `Form`**: CRUD forms for users, Tailwind `grid grid-cols-2`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `DataTable` for admin list.  
- `Form` for adding/editing users.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Add admin user"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/auth.v1/ListAdminUsers` (G5a), logs to PostHog (`admin_user_updated`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `AdminUsers`, Cypress E2E for user management, k6 for 1,000 concurrent updates.  

### Log Viewer (US-AM5)
**Description**: Streams API and audit logs in real-time.  
**Components**:  
- **Polaris `Select` & `TextField`**: Filters for date/merchant/action, Tailwind `w-full`.  
- **Polaris `DataTable`**: Log entries, Tailwind `table-auto`.  
- **Polaris `Button`**: “Undo” for reversible actions.  
- **Polaris `Banner`**: Errors (e.g., “No logs found”).  
**Layout**:  
- Filters at top.  
- `DataTable` with log details and undo buttons.  
- Error `Banner` at top if no data.  
**Accessibility**: ARIA label (`aria-label="Filter logs"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/admin.v1/GetLogs` (G4d) with WebSocket, logs to PostHog (`logs_viewed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `LogsViewer`, Cypress E2E for filtering/streaming, k6 for 5,000 concurrent views.  

### GDPR Request Dashboard (US-AM6)
**Description**: Processes customer GDPR requests.  
**Components**:  
- **Polaris `DataTable`**: Lists requests (type, status), Tailwind `table-auto`.  
- **Polaris `Button`**: “Process Request”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `DataTable` with request details.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Process GDPR request"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/admin.v1/ProcessGDPRRequest` (G4e), logs to `gdpr_requests` (I21), PostHog (`gdpr_processed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `GDPRDashboard`, Cypress E2E for processing, k6 for 1,000 concurrent requests.  

### Plan Management (US-AM7)
**Description**: Manages merchant plans.  
**Components**:  
- **Polaris `Select`**: Plan options (e.g., Free, $29/mo), Tailwind `w-full`.  
- **Polaris `Button`**: “Update Plan”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Select` for plan selection.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Change merchant plan"`), keyboard-navigable, RTL for Arabic.  
**Interactions**: Calls `/admin.v1/UpdatePlan`, logs to PostHog (`plan_updated`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `PlanManagement`, Cypress E2E for plan changes, k6 for 1,000 concurrent updates.  

### Integration Health Dashboard (US-AM8)
**Description**: Monitors integration status (e.g., Shopify, Klaviyo).  
**Components**:  
- **Polaris `Card`**: Chart.js for uptime trends, Tailwind `p-4`.  
- **Polaris `Button`**: “Ping Service”.  
- **Polaris `Banner`**: Errors (e.g., “Klaviyo API down”).  
**Layout**:  
- `Card` with status and chart.  
- `Button` for manual pings.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA label (`aria-label="Check integration status"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/admin.v1/CheckHealth`, logs to PostHog (`integration_health_checked`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `IntegrationHealth`, Cypress E2E for health checks, k6 for 5,000 concurrent pings.  

### RFM Configuration Admin (US-AM9)
**Description**: Manages RFM settings for merchants.  
**Components**:  
- **Polaris `Form`**: Fields for thresholds, Tailwind `grid grid-cols-2`.  
- **Polaris `RangeSlider`**: Adjusts weights (recency, frequency, monetary).  
- **Polaris `Card`**: Chart.js for segment preview.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with sliders and fields.  
- `Card` with preview chart.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Edit RFM config"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/admin.v1/GetRfmConfig` (G4h), caches in Redis (`rfm:preview:{merchant_id}`, J9), logs to PostHog (`rfm_updated`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `RFMConfigAdmin`, Cypress E2E for config update, k6 for 5,000 concurrent previews.  

### Multi-Tenant Management (US-AM14)
**Description**: Manages linked stores and RBAC roles.  
**Components**:  
- **Polaris `Form`**: Fields for linking stores, roles, Tailwind `grid grid-cols-2`.  
- **Polaris `DataTable`**: Lists linked stores, Tailwind `table-auto`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` for store linking and RBAC.  
- `DataTable` for store list.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Manage multi-tenant stores"`), screen reader support, RTL for Arabic.  
**Interactions**: Calls `/auth.v1/UpdateMultiTenantConfig` (G5b), caches in Redis (`multi_tenant:group:{group_id}`, J19), logs to PostHog (`multi_tenant_updated`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `MultiTenantManagement`, Cypress E2E for linking/RBAC, k6 for 1,000 concurrent updates.  

### Action Replay Dashboard (US-AM15)
**Description**: Replays customer journeys and undoes actions.  
**Components**:  
- **Polaris `DataTable`**: Lists actions (points, redemptions), Tailwind `table-auto`.  
- **Polaris `Button`**: “Replay” or “Undo”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `DataTable` with action details.  
- `Button` for replay/undo.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Replay customer journey"`), screen reader support, RTL for Arabic.  
**Interactions**: Queries `/admin.v1/GetCustomerJourney` (G4k), caches in Redis (`journey:{customer_id}`, J20), logs to PostHog (`journey_replayed`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `ActionReplay`, Cypress E2E for replay/undo, k6 for 1,000 concurrent replays.  

### RFM Simulation Dashboard (US-AM16)
**Description**: Simulates RFM segment transitions.  
**Components**:  
- **Polaris `Form`**: Fields for mock order events, Tailwind `grid grid-cols-2`.  
- **Polaris `Card`**: Chart.js line chart for transitions.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` for event input.  
- `Card` with transition chart.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA label (`aria-label="Simulate RFM segments"`), screen reader support, RTL for Arabic.  
**Interactions**: Calls `/analytics.v1/SimulateRFMSegments` (G3j), caches in Redis (`rfm_simulation:{merchant_id}`, J21), logs to PostHog (`rfm_simulation_run`, L).  
**Multilingual**: Localized via i18next (`en`, `es`, `fr`, `ar`).  
**Testing**: Jest for `RFMSimulation`, Cypress E2E for simulation, k6 for 5,000 concurrent simulations.  

## How to Use
- **Render**: Use Figma or Balsamiq to visualize wireframes based on descriptions. Export as SVG/PNG for stakeholder presentations.  
- **Documentation**: Save to `docs/wireframes/wireframes.md`. Link in `README.md` for reference.  
- **Development**: Guide Vite + React implementation with Polaris and Tailwind CSS.  
- **Testing**: Map to Jest tests for UI components, Cypress E2E for flows, k6 for load testing (5,000–10,000 concurrent requests), Lighthouse CI for accessibility (90+ score), OWASP ZAP for security.  
- **Scalability**: Supports 50,000+ customers with Redis caching and PostgreSQL partitioning.  
- **Security**: Implements Shopify OAuth (H1a), RBAC (F0), AES-256 encryption (I1a, I2a, I26a).  
- **Analytics**: Tracks UI interactions via PostHog (L) for events like `points_earned`, `referral_status_viewed`, `churn_risk_viewed`.