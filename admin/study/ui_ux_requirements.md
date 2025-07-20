# UI/UX Requirements Document: LoyalNest Shopify App

## 1. Overview
The LoyalNest Shopify app provides a loyalty and rewards platform to enhance customer retention for Shopify merchants, targeting small (100–1,000 customers), medium (1,000–10,000 customers), and Shopify Plus merchants (10,000+ customers). The UI/UX is designed to be intuitive, Polaris-compliant, and optimized for accessibility, performance, and GDPR/CCPA compliance, supporting Must Have features: points (purchases, signups, reviews, birthdays), SMS/email referrals, basic RFM analytics, Shopify POS with offline mode, checkout extensions, GDPR request form, referral status with progress bar, notification templates with live preview, customer import, campaign discounts, rate limit monitoring with alerts, usage thresholds, and upgrade nudges. The UI comprises **Merchant Dashboard**, **Customer Widget**, **Admin Module**, and **On-Site Content**, built with Vite + React, Polaris, Tailwind CSS, and App Bridge. The design prioritizes ease of use, scalability for 5,000+ merchants (50,000+ customers for Plus), and Shopify App Store compliance (4.5+ star rating in Phase 6), developed by a solo developer with in-house UI/UX and QA, using AI tools (GitHub Copilot, Cursor, Grok).

## 2. Objectives
- **Usability**: Simplify merchant tasks with a gamified onboarding checklist (80%+ completion rate) and no-code RFM wizard (80%+ completion rate).
- **Shopify Compliance**: Adhere to Shopify Polaris and App Bridge for seamless integration, targeting Built for Shopify certification.
- **Accessibility**: Achieve 90+ Lighthouse accessibility scores for ARIA compliance, keyboard navigation, and screen reader support (WCAG 2.1 AA).
- **Performance**: Target 90+ Lighthouse scores for Largest Contentful Paint (LCP <2.5s), First Input Delay (FID <100ms), and Cumulative Layout Shift (CLS <0.1).
- **Scalability**: Support 5,000+ merchants and 50,000+ customers with paginated tables, lazy-loaded components, and Redis caching.
- **GDPR/CCPA Compliance**: Include GDPR request form with clear disclosures and 90-day retention tracking.
- **Engagement**: Achieve 7%+ SMS referral conversion, 3%+ email referral conversion, 85%+ checkout extension adoption, 20%+ redemption rate, 60%+ referral status engagement, 80%+ notification template usage, 90%+ customer import success rate, and 10%+ campaign discount redemption.

## 3. UI Components

### 3.1 Merchant Dashboard
- **Purpose**: Primary interface for merchants to manage loyalty programs, view analytics, and configure settings.
- **Framework**: Vite + React, Polaris, Tailwind CSS, App Bridge.
- **Pages** (aligned with `wireframes.txt` and `user_stories.md`):
  - **WelcomePage.tsx** (US-MD1):
    - **Overview**: Displays metrics (total points issued, referral conversions, RFM segment counts, redemption rates, campaign discount usage) using Polaris `Card` and Chart.js bar charts (US-MD5).
    - **Onboarding Checklist**: Gamified checklist for setup (e.g., "Configure Points", "Set RFM Thresholds", "Add Widget to Theme") using Polaris `ProgressBar` with real-time updates via WebSocket `/admin/v1/setup/stream` (aria-label: "Save setup tasks", PostHog: `setup_saved`, `setup_progress_viewed`). Skipped tasks trigger Polaris `Banner` (e.g., "Complete RFM setup to activate", aria-label: "Resolve skipped task", PostHog: `skipped_task_viewed`).
    - **Upgrade Nudge**: Polaris `Banner` for plan upgrades (e.g., "Unlock checkout extensions with Standard plan!") based on `/v1/api/plan/usage` (US-MD6).
    - **Rate Limit Monitoring**: Real-time Shopify API usage (`/admin/rate-limits`) with Polaris `ProgressBar` and `Banner` alert at 80%+ usage (US-MD11, US-AM11).
    - **Error States**: Show Polaris `Banner` for network errors (500, "Failed to load metrics, retry?") with retry button (exponential backoff: 100ms–1s, PostHog: `metrics_load_failed`).
  - **PointsProgramPage.tsx** (US-MD2):
    - **Earning Rules**: Form for rules (e.g., 10 points/$, 200 points/signup, 100 points/review, 200 points/birthday) using Polaris `Form`, `TextField`, and `Select` (aria-label: "Edit earning rules", PostHog: `rules_edited`).
    - **Redemption Options**: List rewards (e.g., $5 discount: 500 points) using Polaris `Card` and `Button` (aria-label: "Edit redemption options", PostHog: `redemptions_edited`).
    - **Branding**: Customize rewards panel, launcher button, and points currency (e.g., "Stars") with Polaris `Form` and preview (aria-label: "Customize branding", PostHog: `branding_customized`).
    - **Status Toggle**: Enable/disable program with Polaris `Checkbox` (aria-label: "Toggle program status").
    - **Error States**: Display Polaris `Banner` for invalid inputs (400, "Points/$ must be positive") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `points_config_failed`).
  - **ReferralsProgramPage.tsx** (US-MD3, US-CW7):
    - **Referral Config**: Form for SMS/email settings (Klaviyo/Postscript) and rewards (e.g., 50 points) using Polaris `Select` and `TextField` (aria-label: "Edit referral config", PostHog: `referral_config_edited`).
    - **Referral Page**: Preview incentives and status (pending/completed) with Polaris `Card` (aria-label: "Preview referral page").
    - **Referral Codes**: Paginated table of codes (pending/completed/expired) with Polaris `DataTable` and `Button` (aria-label: "View referral details", PostHog: `referral_details_viewed`).
    - **Error States**: Show Polaris `Banner` for duplicate codes (400, "Referral code exists"), rate limit (429, retry after 1s), or server errors (500, retry with exponential backoff: 100ms–1s, PostHog: `referral_config_failed`).
  - **CustomersPage.tsx** (US-MD4, US-BI3):
    - **Search**: Search by name/email (AES-256 encrypted) with Polaris `TextField` (aria-label: "Search customers") and pagination (50,000+ customers).
    - **Customer List**: Table of name, email (decrypted), points, RFM segment using Polaris `DataTable` (aria-label: "View customer details", PostHog: `customer_details_viewed`).
    - **Import CSV**: Upload via Polaris `FileUpload` (max 10MB, .csv) with async job status (`/admin/customers/import`) and real-time progress via WebSocket `/admin/v1/imports/stream` (aria-label: "View import progress", PostHog: `customer_import_initiated`, `import_progress_viewed`).
    - **Error States**: Show Polaris `Banner` for invalid CSV (400, "Missing email column"), rate limit (429, retry after 1s), or server errors (500, retry with exponential backoff: 100ms–1s, PostHog: `import_failed`).
    - **Mobile Responsiveness**: Single-column `DataTable` (Tailwind sm: 320px, aria-label: "Scroll customer table"), collapsible filters.
  - **AnalyticsPage.tsx** (US-MD5, US-MD12):
    - **Metrics**: Display program members, points transactions, referral ROI, churn risk, redemption rate (Phase 2), repeat purchase rate (Phase 3) using Polaris `Card` (PostHog: `analytics_viewed`).
    - **RFM Segments**: Chart.js bar chart and heatmap (Phase 3) for segment counts (`/v1/api/rfm/segments`, cached in Redis: `rfm:preview:{merchant_id}`), line chart for repeat purchase rate and churn risk (Phase 3, aria-label: "View RFM heatmap", PostHog: `rfm_heatmap_viewed`, `rfm_exported`).
    - **Error States**: Polaris `Banner` for empty data (404, "No analytics available") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `analytics_load_failed`).
  - **SettingsPage.tsx** (US-MD6, US-MD11, US-MD13, US-MD17):
    - **Store Details**: Form for store name, billing plan (Free: 300 orders, $29/mo: 500 orders, $99/mo: 1500 orders) using Polaris `TextField`, `Select` (aria-label: "Save store details", PostHog: `store_details_saved`).
    - **RFM Configuration**: No-code wizard for thresholds (recency: <30 days, frequency: 1–2, monetary: <$50) with Polaris `Stepper`, `RangeSlider`, and Chart.js preview (aria-label: "Configure RFM", PostHog: `rfm_configured`).
    - **Checkout Extensions**: Toggle points display (`/v1/api/points/redeem`) with Polaris `Checkbox` (aria-label: "Configure checkout extensions", PostHog: `checkout_extensions_configured`).
    - **Developer Toolkit**: Form for metafields (Phase 3) with Polaris `TextField` (aria-label: "Save developer config", PostHog: `developer_config_saved`).
    - **Language Config**: Dropdown for English, Spanish, French, Arabic (Phase 3) with fallback to English for unsupported languages or malformed JSONB (`program_settings.settings->>'en'`), logged to PostHog (`language_fallback_triggered`, `language_config_saved`).
    - **Multi-Currency**: Toggle for multi-currency discounts (Phase 3, aria-label: "Enable multi-currency", PostHog: `multi_currency_enabled`).
    - **Square Integration**: Form for Square API keys (Phase 3, aria-label: "Configure Square", PostHog: `square_configured`).
    - **Error States**: Polaris `Banner` for invalid inputs (400, "Invalid store name"), rate limit (429, retry after 1s), or server errors (500, retry with exponential backoff: 100ms–1s, PostHog: `settings_save_failed`).
  - **OnSiteContentPage.tsx** (US-MD7, US-MD16, US-MD18):
    - **Loyalty Page**: SEO-friendly editor with Polaris `TextField` and preview (aria-label: "Edit loyalty page", PostHog: `loyalty_page_edited`).
    - **Rewards Panel**: Customize points display with Polaris `Form` (aria-label: "Customize rewards panel", PostHog: `rewards_panel_customized`).
    - **Launcher Button**: Icon editor with Polaris `Button` (aria-label: "Edit launcher button", PostHog: `launcher_edited`).
    - **Popups**: Configure post-purchase and exit-intent (Phase 2) popups with Polaris `Form` (aria-label: "Configure popups", PostHog: `popups_configured`).
    - **Sticky Bar**: Editor for rewards bar (Phase 3) with Polaris `TextField` (aria-label: "Configure sticky bar", PostHog: `sticky_bar_configured`).
    - **Post-Purchase Widget**: Customize points display (Phase 1) with Polaris `Form` (aria-label: "Customize post-purchase widget", PostHog: `post_purchase_customized`).
    - **Error States**: Polaris `Banner` for invalid configurations (400, "Invalid popup content") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `onsite_content_failed`).
  - **NotificationTemplatesPage.tsx** (US-MD8):
    - **Template Config**: Editor for referral, points, VIP tier templates with Polaris `TextField`, live preview, Klaviyo/Postscript toggle, and fallback to English for invalid JSONB (`email_templates.body->>'en'`, aria-label: "Edit notification template", PostHog: `template_edited`, `template_fallback_triggered`).
    - **Error States**: Polaris `Banner` for invalid JSONB (400, "Invalid template format") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `template_save_failed`).
  - **VIPTiersPage.tsx** (US-MD9):
    - **Tier Configuration**: Form for tiers (e.g., Silver: $100+, Gold: $500+) and perks with Polaris `Form` (aria-label: "Edit VIP tiers", PostHog: `vip_tiers_edited`).
    - **Notifications**: Configure tier change emails with Polaris `TextField` (aria-label: "Configure tier notifications", PostHog: `tier_notifications_configured`).
    - **Error States**: Polaris `Banner` for duplicate tiers (400, "Tier name exists") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `vip_tiers_failed`).
  - **ActivityLogsPage.tsx** (US-MD10):
    - **Logs Viewer**: Paginated table of points, referrals, and tier changes (`/v1/api/logs`) with Polaris `DataTable` and filters (aria-label: "View log details", PostHog: `log_details_viewed`).
    - **Error States**: Polaris `Banner` for empty logs (404, "No activity found") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `logs_load_failed`).
  - **BonusCampaignsPage.tsx** (US-MD14):
    - **Campaign Types**: Form for time-sensitive, goal spend, points multipliers, limited bonuses with Shopify Discounts API (Phase 3, aria-label: "Create campaign", PostHog: `campaign_created`).
    - **Schedule**: Date inputs for start/end with Polaris `TextField` (aria-label: "Save campaign schedule", PostHog: `campaign_schedule_saved`).
    - **Error States**: Polaris `Banner` for invalid dates (400, "End date before start") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `campaign_failed`).
  - **RateLimitMonitoringPage.tsx** (US-MD11, US-AM11):
    - **Status**: Display Shopify API, Klaviyo, Postscript limits with Polaris `ProgressBar` (aria-label: "Refresh rate limits", PostHog: `rate_limit_viewed`).
    - **Error States**: Polaris `Banner` for API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `rate_limit_load_failed`).
- **User Flows** (aligned with `user_stories.md`):
  - **Onboarding (US-MD1)**: Login via Shopify OAuth, complete checklist, activate program.
  - **Points Management (US-MD2)**: Configure earning/redemption rules, preview branding, toggle status.
  - **Referrals (US-MD3, US-CW7)**: Set up SMS/email referrals, view paginated codes, track status.
  - **Customers (US-MD4, US-BI3)**: Search customers, view details, import CSV with job status.
  - **Analytics (US-MD5, US-MD12)**: View metrics, RFM charts, export reports.
  - **Settings (US-MD6, US-MD11, US-MD13, US-MD17)**: Update store details, RFM thresholds, checkout extensions, metafields, language, multi-currency, Square integration.
  - **On-Site Content (US-MD7, US-MD16, US-MD18)**: Customize loyalty page, popups, sticky bar, post-purchase widget.
- **Accessibility**: ARIA labels (`aria-label`, `aria-live`), keyboard navigation (tab index), screen reader support for charts (aria-live: "RFM segment data available"), high-contrast text (4.5:1 ratio).
- **Performance**: Lazy-load Chart.js, cache API responses in Redis (`points:{customer_id}`, `rfm:preview:{merchant_id}`), WebP images, paginated tables (50 rows/page).
- **Mobile Responsiveness**: Tailwind breakpoints (sm: 320px, md: 768px, lg: 1024px) for collapsed layouts (e.g., hamburger menu for Settings, single-column `DataTable`).

### 3.2 Customer Widget
- **Purpose**: Embeddable widget for customers to view points, redeem rewards, submit GDPR requests, and engage with referrals, VIP tiers, and gamification.
- **Framework**: Vite + React, Polaris, Tailwind CSS, Theme App Extensions (Phase 5).
- **Components** (aligned with `wireframes.txt`, US-CW1–CW15):
  - **Widget.tsx** (US-CW1–CW8, US-CW13–CW15):
    - **Points Balance**: Display balance (e.g., "500 Stars") with real-time updates via WebSocket `/points.v1/PointsStream`, Polaris `Badge` animation (300ms fade-in, aria-label: "View points history", PostHog: `points_history_viewed`, `points_stream_updated`, US-CW1).
    - **Redemption Options**: List rewards (e.g., $5 discount: 500 points) with Polaris `Card` and `Button` (aria-label: "Redeem points", PostHog: `redeem_clicked`, US-CW3).
    - **Referral Popup**: SMS/email form (`/v1/api/referrals/create`) with Polaris `Modal`, Klaviyo/Postscript integration (aria-label: "Send referral invite", PostHog: `referral_clicked`, US-CW4).
    - **Referral Status**: Progress bar (`/v1/api/referrals/status`) with Polaris `ProgressBar` and swipe gestures (aria-label: "Swipe to view referrals", PostHog: `referral_status_viewed`, US-CW7).
    - **GDPR Request Form**: Form for data access/deletion (`/v1/api/gdpr`) with Polaris `Form` and disclosures (aria-label: "Submit GDPR request", PostHog: `gdpr_request_submitted`, US-CW8).
    - **RFM Nudges**: Banner for engagement (e.g., "Stay Active!") with Polaris `Banner`, 300ms fade-in (aria-label: "Dismiss nudge", PostHog: `nudge_dismissed`, US-CW10).
    - **VIP Tier**: Display tier (e.g., "Silver, $100/$500 to Gold") with Polaris `Card` and progress bar (aria-label: "View VIP perks", PostHog: `vip_perks_viewed`, US-CW9).
    - **Gamification**: Show badges with 300ms scale animation (aria-label: "View badge details", PostHog: `badge_viewed`, US-CW11). Leaderboard with paginated ranks (50 ranks/page, aria-label: "View leaderboard page", PostHog: `leaderboard_page_viewed`, US-CW12).
    - **Language Config**: Dropdown for English, Spanish, French, Arabic (Phase 3) with fallback to English (`program_settings.settings->>'en'`, aria-label: "Select language", PostHog: `language_selected`, `language_fallback_triggered`, US-CW13).
    - **Post-Purchase Widget**: Points earned display post-checkout with CTA (aria-label: "View points earned", PostHog: `post_purchase_viewed`, US-CW15).
    - **Error States**: Polaris `Banner` for insufficient points (400, "Need 100 more points"), invalid referral codes (400, "Invalid code"), network errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `widget_error`).
  - **ReferralProgress.tsx** (US-CW7):
    - **Status**: Paginated list of referrals (pending/completed) with Polaris `DataTable` and swipe gestures (aria-label: "Swipe to view referrals", PostHog: `referral_status_viewed`).
    - **Error States**: Polaris `Banner` for no referrals (404, "No referrals found") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `referral_status_failed`).
- **User Flows**:
  - **Points (US-CW1–CW3, US-CW6)**: View balance, earn points on purchase, redeem rewards, adjust for cancellations.
  - **Referrals (US-CW4, US-CW5, US-CW7)**: Share link via SMS/email, track status, earn rewards.
  - **GDPR (US-CW8)**: Submit data request/redaction with confirmation.
  - **VIP and Nudges (US-CW9, US-CW10)**: View tier progress, receive nudges.
  - **Gamification (US-CW11, US-CW12)**: Earn badges, check leaderboard.
  - **Post-Purchase (US-CW15)**: View points earned, click referral CTA.
- **Accessibility**: ARIA labels, keyboard-navigable modals, screen reader support (aria-live: "Widget content available"), high-contrast toggle.
- **Performance**: Minified <50KB, lazy-loaded images, Redis caching (`points:{customer_id}`, `referral:{customer_id}`).
- **Mobile Responsiveness**: Collapsed layout (Tailwind sm: 320px) with hamburger menu and swipe gestures for referrals/leaderboard.

### 3.3 Admin Module
- **Purpose**: Interface for internal admin tasks (merchant management, logs, rate limits, GDPR compliance).
- **Framework**: Vite + React, Polaris, Tailwind CSS, App Bridge.
- **Components** (aligned with `wireframes.txt`, US-AM1–AM13):
  - **OverviewPage.tsx** (US-AM1):
    - **Metrics**: Display merchant count, points issued, referral ROI, RFM segments with Chart.js bar chart (aria-label: "Refresh metrics", PostHog: `overview_viewed`).
    - **Error States**: Polaris `Banner` for API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `overview_load_failed`).
  - **MerchantsPage.tsx** (US-AM2, US-AM7, US-AM10):
    - **Merchant List**: Paginated table of merchants (`/admin/merchants`) with Polaris `DataTable` (aria-label: "View merchant details", PostHog: `merchant_details_viewed`).
    - **Plan Management**: Upgrade/downgrade plans with Polaris `Select` (aria-label: "Change merchant plan", PostHog: `plan_changed`).
    - **Status**: Suspend/reactivate with Polaris `Button` (aria-label: "Toggle merchant status", PostHog: `merchant_status_toggled`).
    - **Points Adjustment**: Form for manual points changes (aria-label: "Adjust customer points", PostHog: `points_adjusted`, US-AM3).
    - **Error States**: Polaris `Banner` for no merchants (404, "No merchants found") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `merchants_load_failed`).
  - **AdminUsersPage.tsx** (US-AM4):
    - **User List**: Table of admin users with Polaris `DataTable` (aria-label: "Add admin user", PostHog: `admin_user_added`).
    - **Error States**: Polaris `Banner` for duplicate users (400, "User exists") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `admin_users_failed`).
  - **LogsPage.tsx** (US-AM5):
    - **API and Audit Logs**: Paginated tables (`/admin/logs`) with Polaris `DataTable` and filters (aria-label: "Filter logs", PostHog: `api_logs_filtered`, `audit_logs_filtered`).
    - **Error States**: Polaris `Banner` for empty logs (404, "No logs found") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `logs_load_failed`).
  - **IntegrationHealthPage.tsx** (US-AM8, US-AM13):
    - **Status**: Display Shopify, Klaviyo, Postscript, Square (Phase 3) health with Polaris `Card` (aria-label: "Check integration status", PostHog: `integration_health_checked`).
    - **Error States**: Polaris `Banner` for failed pings (500, "Klaviyo API down", retry with exponential backoff: 100ms–1s, PostHog: `integration_health_failed`).
  - **RFMConfigPage.tsx** (US-AM9):
    - **Thresholds**: Form for recency, frequency, monetary with Polaris `Form` and Chart.js preview (aria-label: "Edit RFM config", PostHog: `rfm_config_edited`).
    - **Error States**: Polaris `Banner` for invalid thresholds (400, "Recency > 360 days") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `rfm_config_failed`).
  - **RFMSegmentExportPage.tsx** (US-AM12):
    - **Export**: Button for CSV export (`/admin/v1/rfm/export`) with Polaris `Button` and progress bar (aria-label: "Export RFM segments", PostHog: `rfm_exported`).
    - **Error States**: Polaris `Banner` for no segments (404, "No segments available"), rate limit (429, retry after 1s), or server errors (500, retry with exponential backoff: 100ms–1s, PostHog: `rfm_export_failed`).
  - **GDPRRequestsPage.tsx** (US-AM6):
    - **Request List**: Paginated table of GDPR requests (`/admin/v1/gdpr`) with Polaris `DataTable` (aria-label: "Process GDPR request", PostHog: `gdpr_request_processed`).
    - **Error States**: Polaris `Banner` for no requests (404, "No requests found") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `gdpr_requests_failed`).
  - **RateLimitMonitoringPage.tsx** (US-AM11):
    - **Status**: Display API limits with Polaris `ProgressBar` (aria-label: "Refresh rate limits", PostHog: `rate_limit_viewed`).
    - **Error States**: Polaris `Banner` for API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `rate_limit_load_failed`).
- **User Flows**:
  - **Overview (US-AM1)**: View platform metrics, RFM charts.
  - **Merchants (US-AM2, US-AM7, US-AM10)**: Search merchants, adjust plans, suspend accounts, modify points.
  - **Admin Users (US-AM4)**: Add/edit/delete users with RBAC.
  - **Logs (US-AM5)**: Filter/view API and audit logs.
  - **Integrations (US-AM8, US-AM13)**: Monitor health, configure Square/Postscript.
  - **RFM (US-AM9, US-AM12)**: Manage thresholds, export segments.
  - **GDPR (US-AM6)**: Process requests/redactions within 90 days.
- **Accessibility**: ARIA-compliant tables, keyboard navigation, screen reader support (aria-live: "Metrics data available").
- **Performance**: Paginated tables (50 rows/page), cached logs in Redis (`api_logs:{merchant_id}`), optimized API calls.

### 3.4 On-Site Content
- **Purpose**: Embeddable content for merchant storefronts to promote loyalty program engagement.
- **Components** (aligned with `wireframes.txt`, US-MD7, US-MD16, US-MD18, US-CW14, US-CW15):
  - **Loyalty Page**: SEO-friendly page with program overview, points rules, referral CTA using Polaris `CalloutCard` (PostHog: `loyalty_page_viewed`).
  - **Rewards Panel**: Displays rewards (`/v1/api/rewards`) with Polaris `Card` (PostHog: `rewards_panel_viewed`).
  - **Launcher Button**: Floating button to open Customer Widget, styled with Tailwind CSS (PostHog: `launcher_clicked`).
  - **Sticky Bar**: Rewards bar (Phase 3) with Polaris `Banner` (aria-label: "Join loyalty program", PostHog: `sticky_bar_clicked`, US-CW14).
  - **Post-Purchase Widget**: Points earned display with referral CTA (Phase 1) with Polaris `Card` (aria-label: "View points earned", PostHog: `post_purchase_viewed`, US-CW15).
  - **Popups**: Post-purchase and exit-intent (Phase 2) popups with Polaris `Modal` (PostHog: `popup_viewed`).
  - **GDPR Form**: Embedded form for data requests/redactions with Polaris `Form` (PostHog: `gdpr_request_submitted`).
  - **Error States**: Polaris `Banner` for invalid submissions (400, "Invalid form data") or API errors (429, retry after 1s; 500, retry with exponential backoff: 100ms–1s, PostHog: `onsite_content_error`).
- **User Flows**:
  - **Engagement**: Click launcher/sticky bar to open Widget, join program.
  - **Referrals**: Trigger popup post-purchase or on exit-intent, submit referral.
  - **GDPR**: Access form via footer link, submit request.
  - **Post-Purchase**: View points earned, click referral CTA.
- **Accessibility**: ARIA labels for modals, keyboard-navigable buttons, WCAG 2.1 AA compliance.
- **Performance**: Minified assets (<20KB), lazy-loaded popups, WebP images.

## 4. Design Requirements
- **Polaris Compliance**: Use Polaris components (`Card`, `Form`, `ProgressBar`, `Banner`, `DataTable`, `Stepper`, `RangeSlider`, `Badge`, `CalloutCard`, `Modal`) for Shopify UX consistency.
- **Tailwind CSS**: Utility classes for responsive layouts, high-contrast text (4.5:1), and custom styling within Polaris guidelines.
- **App Bridge**: Integrate for Shopify admin embedding, navigation, and OAuth.
- **Chart.js**: Bar charts and heatmaps (Phase 3) for RFM segments, line charts for redemption trends/repeat purchase rate, with ARIA labels (aria-live: "Chart data available").
- **Color Scheme**: Primary (#2CB1A5, teal), secondary (#FFFFFF, white), accents (#FF5733, CTAs).
- **Typography**: Helvetica Neue, 16px base, 1.5 line height, bold headings.
- **Responsive Design**: Tailwind breakpoints (sm: 320px, md: 768px, lg: 1024px).
- **Localization**: Support English (default), Spanish, French, Arabic (Phase 3) via i18next with fallback to English (`program_settings.settings->>'en'`), stored in JSONB fields (`email_templates.body`, `program_settings.settings`).

## 5. User Flows
- **Merchant Onboarding (US-MD1)**: Login via Shopify OAuth, complete checklist with real-time progress, activate program.
- **Customer Interaction (US-CW1–CW15)**: View points with real-time updates, redeem rewards, share referrals, track status, submit GDPR requests, view VIP tiers, earn badges, check leaderboard, select language, interact with sticky bar/post-purchase widget.
- **Admin Tasks (US-AM1–AM13)**: Monitor merchants, adjust plans/points, manage users, view logs, process GDPR requests, configure RFM, export segments, check integrations.

## 6. Accessibility Requirements
- **WCAG 2.1 AA**: High-contrast text, focus indicators, ARIA labels for buttons, forms, charts.
- **Keyboard Navigation**: Tab navigation for forms, modals, dropdowns.
- **Screen Readers**: ARIA landmarks (`aria-label`, `aria-live`) for dynamic content (e.g., charts, progress bars).
- **Lighthouse CI**: Target 90+ accessibility score in GitHub Actions.

## 7. Performance Requirements
- **Lighthouse Scores**: LCP <2.5s, FID <100ms, CLS <0.1.
- **Optimization**:
  - Minify JavaScript/CSS (<50KB Widget, <200KB Dashboard).
  - WebP images, lazy-load non-critical assets.
  - Cache API responses (`/v1/api/points`, `/v1/api/rfm/segments`) in Redis.
  - Paginate tables (`/admin/merchants`, `/admin/logs`, 50 rows/page).
- **Load Testing**: Test with 5,000 customers (Shopify) and 50,000 customers (Plus) using k6.

## 8. Testing Requirements
- **Unit Tests**: Jest for React components (`WelcomePage.tsx`, `Widget.tsx`, etc.).
- **E2E Tests**: Cypress for flows (onboarding, RFM wizard, referral popup, GDPR form, customer import, sticky bar interaction) and edge cases (Shopify API 429 retries with exponential backoff, Klaviyo/Postscript timeouts with 5s retry, invalid referral codes with Polaris `Banner` error).
- **Accessibility Tests**: Lighthouse CI for ARIA, keyboard navigation, contrast (90+ score).
- **Mock Data**: Faker for merchants, customers, RFM scores (`test/factories/*.ts`).
- **Edge Cases**: Test rate limit alerts (80%+ usage), failed imports (invalid CSV), GDPR webhook retries, duplicate referral codes, network errors (429, 500).

## 9. Mockups and Wireframes
- **Tools**: Figma (Shopify Polaris UI kit), Mermaid for layouts, AI-assisted with Grok/Cursor.
- **Deliverables** (Phase 2, Weeks 5–11):
  - **WelcomePage**: Metrics, checklist with real-time progress, upgrade nudge (US-MD1).
  - **PointsProgramPage**: Earning/redemption rules, branding (US-MD2).
  - **ReferralsProgramPage**: Referral config, codes table (US-MD3).
  - **CustomersPage**: Customer list, CSV import with real-time progress (US-MD4).
  - **AnalyticsPage**: Metrics, RFM charts with heatmaps, export (US-MD5, US-MD12).
  - **SettingsPage**: Store details, RFM wizard, checkout extensions, developer toolkit, language, multi-currency, Square integration (US-MD6, US-MD11, US-MD13, US-MD17).
  - **OnSiteContentPage**: Loyalty page, rewards panel, launcher, popups, sticky bar, post-purchase widget (US-MD7, US-MD16, US-MD18).
  - **NotificationTemplatesPage**: Template editor with preview and fallback (US-MD8).
  - **VIPTiersPage**: Tier config, notifications (US-MD9).
  - **ActivityLogsPage**: Logs table with filters (US-MD10).
  - **BonusCampaignsPage**: Campaign types with Shopify Discounts API, schedule (US-MD14).
  - **RateLimitMonitoringPage**: API status (US-MD11).
  - **Widget**: Points with real-time updates, redemptions, referrals with swipe gestures, GDPR, VIP, gamification with animations, language (US-CW1–CW15).
  - **Admin Module**: Overview, merchants, users, logs, integrations, RFM, GDPR, rate limits (US-AM1–AM13).
- **Mermaid Layout Example** (Welcome Page):
  ```mermaid
  graph TD
      A[WelcomePage] --> B[Shopify OAuth Login: Button]
      A --> C[Checklist: ProgressBar, WebSocket /admin/v1/setup/stream]
      A --> D[Metrics: Card, Chart.js]
      A --> E[Upgrade Nudge: Banner]
      A --> F[Rate Limits: ProgressBar]
      C --> G[Save Button: aria-label="Save setup tasks"]
      C --> H[Skipped Task Banner: aria-label="Resolve skipped task"]
      E --> I[Upgrade Button: aria-label="Upgrade plan"]
      F --> J[Alert Banner: aria-label="Rate limit alert"]
  ```
- **Validation**: Test with 5–10 merchants (2–3 Shopify Plus) via Shopify Partners program for usability feedback (90%+ satisfaction).

## 10. Success Metrics
- **Phase 3–4 (TVP)**:
  - 80%+ onboarding checklist completion (PostHog: `setup_task_completed`).
  - 80%+ RFM wizard completion (PostHog: `rfm_configured`).
  - 7%+ SMS referral conversion (PostHog: `referral_completed`).
  - 3%+ email referral conversion (PostHog: `referral_completed`).
  - 85%+ checkout extension adoption (PostHog: `checkout_extensions_configured`).
  - 20%+ redemption rate (PostHog: `redeem_clicked`).
  - 50%+ GDPR form usage (PostHog: `gdpr_request_submitted`).
  - 60%+ referral status engagement (PostHog: `referral_status_viewed`).
  - 80%+ notification template usage (PostHog: `template_edited`).
  - 90%+ customer import success rate (PostHog: `customer_import_initiated`).
  - 10%+ campaign discount redemption (PostHog: `campaign_created`).
  - 90%+ merchant satisfaction (Shopify Partners feedback).
- **Phase 5 (Launch)**: 4.5+ star rating in Shopify App Store, 100+ merchants (5–10 Plus) in 3 months.
- **Phase 6 (Scaling)**: 20% repeat purchase increase, 50%+ multi-store point sharing adoption.

## 11. Assumptions and Constraints
- **Assumptions**:
  - Merchants expect Polaris-compliant UI and App Bridge integration.
  - AI tools (Grok, Copilot, Cursor) reduce UI design effort by 30–40%.
  - Shopify Plus merchants require white-glove onboarding for RFM and checkout extensions.
- **Constraints**:
  - Solo developer with in-house UI/UX and QA, relying on AI tools.
  - Budget: $74,750 for development, including UI/UX.
  - Timeline: Phase 2 (Weeks 5–11) for design, Phase 3 (Weeks 12–30) for implementation.

## 12. Future Considerations (Phase 6)
- **Should Have**: VIP tiers (US-CW9, US-MD9), exit-intent popups (US-MD7), behavioral segmentation (US-CW10), multi-store point sharing (US-MD6), Shopify Flow templates (US-MD13).
- **Could Have**: Gamification badges with animations (US-CW11), paginated leaderboards (US-CW12), multilingual widget (US-CW13), multi-currency discounts (US-MD14), advanced analytics (25+ Chart.js reports, US-MD15).
- **Admin Enhancements**: Developer toolkit UI (US-MD17), custom webhook configuration (US-AM13).