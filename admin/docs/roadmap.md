# Roadmap
LoyalNest App

## Phase 1: TVP Development + Internal Admin Module (7 Months)

### Goal
Deliver a production-grade TVP with **Must Have** features across microservices (auth, points, referrals, analytics, admin, frontend): points earning/redemption, SMS/email referrals, basic RFM analytics (churn risk), Shopify POS integration, checkout extensions, automated loyalty email flows, customer data import, GDPR request form, referral status display, notification templates, rate limit monitoring, and a robust internal admin module with RBAC for Shopify Plus (50,000+ customers, 1,000 orders/hour). Deploy using Docker in an Nx-managed monorepo, ensuring GDPR/CCPA compliance and multilingual support.

### Enhancements & Best Practices
- Generate OpenAPI/Swagger for `/v1/api/*` and GraphQL schema for Shopify Admin/Storefront APIs.
- Implement centralized logging (Loki/Grafana), monitoring (Prometheus, Grafana), and alerting (Sentry) on VPS.
- Add health checks for microservices, Rust, Redis, PostgreSQL, Nginx with 5 retries (2s initial delay, exponential backoff).
- Schedule weekly PostgreSQL/Redis backups, quarterly disaster recovery drills.
- Conduct WCAG 2.1 a11y testing for dashboard, widget, checkout extensions, admin UI, GDPR request form.
- Track usage via PostHog (e.g., `rfm_wizard_completed`, `referral_popup_clicked`, `checkout_extension_used`, `admin_login`, `gdpr_request_submitted`, `referral_status_viewed`, `notification_template_updated`, `rate_limit_viewed`).
- Implement guided onboarding (tooltips, checklists) for merchants, with Plus-specific workflows (RBAC, checkout extensions, GDPR form, notification templates).
- Conduct usability testing with 5–10 merchants (2–3 Plus) for RFM, referrals, checkout extensions, GDPR form, referral status, admin module.
- Review security: OAuth, JWT (1-hour expiry, refresh tokens), MFA (Auth0), GDPR/CCPA webhooks (`customers/data_request`, `customers/redact`), encrypt `customers.email`, `rfm_score`, `api_token` with pgcrypto, webhook signature verification bi-monthly.
- Audit npm, cargo, Docker dependencies monthly.
- Document infrastructure (Docker Compose, Nginx) in GitHub with IaC.
- Allocate 10% buffer for freelancer coordination, AI code review (GitHub Copilot, Cursor).
- Maintain multilingual docs/videos (1–2 minutes) for RFM, points, admin module, GDPR form, referral status, notification templates.
- Monitor Shopify API changelogs for versioning updates.
- Use Nx for monorepo builds, dependency tracking, and CI/CD optimization.

### TVP Features
1. **Welcome Page** (Frontend Service):
   - Tasks: Launch program, add widget, configure points, basic RFM, checkout extensions, notification templates.
   - Real-time progress bar, tooltips (e.g., “Add widget to enable points display”).
   - Success Metric: 80%+ task completion rate.
2. **Program - Points** (Points Service):
   - Earn: Purchases (1 point/$), signups (200 points), reviews (100 points), birthdays (200 points).
   - Redeem: Discounts (500 points for $5), free shipping (1,000 points), free products (1,500 points), checkout coupons.
   - Branding: Customizable rewards panel, launcher button, points currency (e.g., “Stars”).
   - Status: Enable/disable with toggle.
   - Error Handling: `INVALID_ORDER_ID`, `INSUFFICIENT_POINTS`, `RATE_LIMIT_EXCEEDED`.
   - Success Metric: 90%+ successful point awards within 1s.
3. **Program - Referrals** (Referrals Service):
   - SMS/email referral popup via Klaviyo/Postscript, rewards (10% off for referrer/friend), multilingual support.
   - Dedicated referral page with incentives, referral status display (pending, completed, expired).
   - Track codes in `referrals` (referral_link_id, status).
   - Error Handling: `INVALID_REFERRAL_CODE`, `DUPLICATE_REFERRAL`.
   - Success Metric: 5%+ referral conversion rate.
4. **Customers** (Admin Service):
   - List: Name, email (encrypted), points balance, RFM segment (e.g., “At-Risk”).
   - Search: By name/email with pagination, fuzzy search support.
   - GDPR: Request form for data export/redaction, retention tracking (`retention_expires_at`).
   - Success Metric: 90%+ query performance under 1s, 95%+ GDPR request handling.
5. **Analytics** (Analytics Service):
   - Metrics: Program members, points issued/redeemed, referral ROI, RFM churn risk (static thresholds: Recency <90 days, Frequency 1–2, Monetary <$50 for AOV $50).
   - Chart: Bar chart for RFM segments in `AnalyticsPage.tsx` (Chart.js).
   - Materialized Views: For `rfm_segment_counts` (merchant_id, segment_name, customer_count).
   - Success Metric: 80%+ merchant interaction with analytics.
6. **On-Site Content** (Frontend Service):
   - SEO-friendly loyalty page, rewards panel, launcher button, points display on product/checkout pages, GDPR request form, referral status display.
   - Nudges: Post-purchase prompts, email capture popups with multilingual fallback (`en`).
   - Launchers: Embedded in Shopify checkout/customer accounts.
   - Success Metric: 85%+ content customization adoption.
7. **Settings** (Admin Service):
   - Store details, billing (Free: 300 orders, $29/month: 500 orders, $99/month: 1,500 orders, Enterprise: custom).
   - Branding: Rewards panel customization, multilingual labels, notification templates.
   - RFM: Static thresholds (e.g., Recency 5: <30 days) in `program_settings.rfm_thresholds` (JSONB).
   - Rate Limit Monitoring: Display Shopify API and integration rate limits.
   - Success Metric: 90%+ settings update success rate.
8. **Shopify Integration** (Auth and Points Services):
   - OAuth via `@shopify/shopify-app-express`, GraphQL Admin API for customers/orders/discounts, Storefront API for widget.
   - Webhooks: `orders/create`, `customers/data_request`, `customers/redact` with 5 retries (2s initial delay), `gdpr_requests` table for tracking.
   - POS: Points earning (1 point/$) via POS API.
   - Checkout UI Extensions: Points redemption for Plus.
   - Success Metric: 95%+ order sync success rate.
9. **Other**:
   - Automated loyalty email flows (points earned, redemption reminders, referral notifications) via Klaviyo/Postscript (Referrals Service).
   - Customer data import from Smile.io, LoyaltyLion (Admin Service).
   - Success Metric: 95%+ import success rate.
10. **Customer Widget** (Frontend Service):
    - React component for points balance, redemption, SMS/email referral popup, GDPR request form, referral status display, RFM nudges.
    - Multilingual support via Storefront API (`shop.locales`).
    - Success Metric: 85%+ redemption success rate for Plus.
11. **Internal Admin Module** (Admin Service):
    - **Overview**: Merchant count, points issued/redeemed, referral ROI, RFM segments (Chart.js).
    - **Merchants**: List (ID, domain, plan, status, RBAC roles), search, view details, activate/suspend, adjust points, GDPR export/delete, bulk actions.
    - **Admin Users**: Add/edit/delete in `admin_users` (bcrypt, JWT, RBAC: admin:full, admin:analytics, admin:support), MFA via Auth0.
    - **Logs**: View `api_logs`, `audit_logs` with filters (date, route, user, action).
    - **Rate Limit Monitoring**: Display Shopify API and integration rate limits (`/admin/v1/rate-limits`).
    - **Success Metrics**: 90%+ query performance under 1s, 100% secure user management.

### Database Schema
- **Tables**:
  - `merchants` (merchant_id, shopify_domain, plan_id, status CHECK('active', 'suspended', 'trial'), brand_settings, staff_roles, language JSONB)
  - `customers` (customer_id, email ENCRYPTED, first_name, last_name, points_balance, total_points_earned, total_points_redeemed, rfm_score ENCRYPTED, vip_tier_id JSONB)
  - `points_transactions` (transaction_id, customer_id, merchant_id, type CHECK('purchase', 'signup', 'review', 'birthday', 'admin_adjust'), points, source, order_id, created_at)
  - `referrals` (referral_id, referral_link_id, advocate_customer_id, friend_customer_id, reward_id, status CHECK('pending', 'completed', 'expired'), created_at)
  - `referral_links` (referral_link_id, referral_code UNIQUE, advocate_customer_id, merchant_id, created_at)
  - `rewards` (reward_id, merchant_id, type CHECK('discount', 'free_shipping', 'free_product'), points_cost, value)
  - `reward_redemptions` (redemption_id, customer_id, reward_id, points_spent, discount_code ENCRYPTED, status CHECK('issued', 'used', 'expired'), created_at)
  - `program_settings` (merchant_id, config, rfm_thresholds, branding, points_currency_singular, points_currency_plural JSONB)
  - `customer_segments` (segment_id, merchant_id, rules, name JSONB)
  - `rfm_segment_counts` (merchant_id, segment_name, customer_count, last_refreshed)
  - `admin_users` (id, username UNIQUE, email ENCRYPTED, password, metadata JSONB)
  - `api_logs` (id, merchant_id, route, method, status_code, created_at)
  - `audit_logs` (id UUID, admin_user_id, action, target_table, target_id, created_at)
  - `email_templates` (template_id, merchant_id, type CHECK('referral', 'tier_change', 'popup', 'points_earned', 'redemption_reminder'), subject, body JSONB)
  - `email_events` (event_id, merchant_id, event_type CHECK('sent', 'failed'), recipient_email ENCRYPTED)
  - `import_logs` (id, merchant_id, success_count, fail_count, fail_reason JSONB)
  - `integrations` (integration_id, merchant_id, type CHECK('shopify', 'klaviyo', 'postscript'), status CHECK('ok', 'error'), settings, api_key ENCRYPTED)
  - `gdpr_requests` (request_id, customer_id, merchant_id, type CHECK('data_request', 'redact'), retention_expires_at, status CHECK('pending', 'completed'), created_at)
- **Indexes**: `customers(email, merchant_id, rfm_score, vip_tier_id)`, `points_transactions(customer_id, merchant_id, order_id)`, `referrals(merchant_id, referral_link_id)`, `referral_links(referral_code)`, `merchants(shopify_domain, staff_roles, language)`, `reward_redemptions(customer_id)`, `api_logs(merchant_id, route)`, `audit_logs(admin_user_id)`, `email_templates(merchant_id)`, `integrations(merchant_id)`, `gdpr_requests(customer_id, merchant_id, retention_expires_at)`, `rfm_segment_counts(merchant_id)`
- **Partitioning**: `points_transactions`, `referrals`, `customer_segments`, `api_logs`, `reward_redemptions`, `gdpr_requests` by `merchant_id`.
- Use PostgreSQL with JSONB; defer MongoDB to Phase 4.

### Tasks
1. **Backend (NestJS/TypeScript)**:
   - **Auth Service**:
     - APIs: `/v1/api/auth/login`, `/v1/api/auth/refresh`, `/v1/api/auth/roles`.
     - Shopify OAuth, JWT (1-hour expiry, refresh tokens), RBAC via `merchants.staff_roles`, MFA via Auth0, IP whitelisting.
     - Cache tokens in Redis (`auth:token:{id}`, TTL 1h).
   - **Points Service**:
     - APIs: `/v1/api/points/earn`, `/v1/api/points/redeem`, `/v1/api/points/adjust`.
     - Shopify: `orders/create` webhook (5 retries), POS, Checkout UI Extensions, GraphQL Admin API for discounts.
     - Cache points in Redis Streams (`points:customer:{id}`).
     - Error Handling: `INVALID_ORDER_ID`, `INSUFFICIENT_POINTS`, `RATE_LIMIT_EXCEEDED`.
   - **Referrals Service**:
     - APIs: `/v1/api/referrals/create`, `/v1/api/referrals/complete`, `/v1/api/referrals/status`.
     - Klaviyo/Postscript: SMS/email referrals with multilingual notification templates via Bull queues, 5 retries (2s initial delay).
     - Cache referral codes, statuses in Redis (`referrals:code:{id}`, TTL 30d).
     - Error Handling: `INVALID_REFERRAL_CODE`, `DUPLICATE_REFERRAL`.
   - **Analytics Service**:
     - APIs: `/v1/api/rfm/segments`, `/v1/api/analytics`.
     - RFM: Static calculations in `customers.rfm_score` (JSONB), materialized views for `rfm_segment_counts` (daily refresh at 0 1 * * *).
     - PostHog: Track `points_earned`, `referral_completed`, `rfm_segment_viewed`, `referral_status_viewed`.
   - **Admin Service**:
     - APIs: `/admin/v1/overview`, `/admin/v1/merchants`, `/admin/v1/points/adjust`, `/admin/v1/users`, `/admin/v1/logs`, `/admin/v1/integrations/health`, `/admin/v1/gdpr/requests`.
     - GDPR: `/webhooks/customers/data_request`, `/webhooks/customers/redact` with `gdpr_requests` table, `retention_expires_at` (90 days).
     - Cache logs, metrics in Redis (`admin:metrics:{period}`, TTL 6h).
     - Error Handling: `UNAUTHORIZED`, `INVALID_MERCHANT_ID`.
   - **Frontend Service**:
     - APIs: `/v1/api/widget/config`, `/v1/api/content` for loyalty page, popups, GDPR request form, referral status, checkout extensions.
     - Storefront API for multilingual widget content (`shop.locales`).
   - **Inter-Service Communication**: gRPC for Points ↔ Auth, Analytics ↔ Admin.
   - Shopify: GraphQL Admin/Storefront APIs, webhook signature verification, rate limiting (2 req/s REST, 40 req/s Plus, 1–4 req/s Storefront).
   - Cache points, referrals, RFM, webhook idempotency keys, notification templates in Redis.
   - Implement referral notification system with Klaviyo/Postscript integration, multilingual support (`email_templates.body` JSONB).
   - Add GDPR request form API (`/v1/api/gdpr/request`) for widget.
   - Add referral status display API (`/v1/api/referrals/status`) for widget.
   - Use AI (GitHub Copilot, Cursor) for boilerplate, error handlers, Jest tests; review for Shopify compliance.
2. **Backend (Rust/Wasm)**:
   - Shopify Functions: Discounts, checkout extensions, basic RFM score updates.
   - Use Shopify CLI, `cargo test` with AI, log errors to Sentry.
3. **Frontend (Vite + React)** (Frontend Service):
   - Components: `WelcomePage.tsx` (setup tasks, tooltips), `PointsPage.tsx`, `ReferralsPage.tsx`, `CustomersPage.tsx`, `AnalyticsPage.tsx` (RFM chart), `SettingsPage.tsx` (store, billing, branding, checkout extensions, notification templates, rate limit monitoring), `CustomerWidget.tsx` (points, referrals, GDPR form, referral status, nudges).
   - On-Site Content: Loyalty page, rewards panel, launcher button, popups, GDPR request form, referral status display, checkout extensions.
   - Admin Frontend: Overview, merchants, logs, admin users, integration health, GDPR requests, rate limit monitoring.
   - Use Polaris, Tailwind CSS, WCAG 2.1, i18next for multilingual support (`en`, `es`, `fr`).
   - Use AI for components, Cypress tests; outsource Polaris compliance review ($1,000).
4. **Database**:
   - Apply `loyalnest_full_schema.sql` with JSONB, indexes, partitioning.
   - Add `referral_links`, `gdpr_requests`, `email_templates` tables.
   - Use materialized views for `rfm_segment_counts`.
   - Use AI for SQL optimization.
5. **Deployment**:
   - VPS (Ubuntu, Docker Compose) for microservices, PostgreSQL, Redis, Nginx, Vite + React frontend.
   - GitHub Actions with Nx change detection for CI/CD.
   - Provide Docker Compose scripts, feature flags (LaunchDarkly).
6. **Testing**:
   - Unit: Jest for APIs, `cargo test` for Rust, Jest for RFM logic, GDPR requests, referral status.
   - Integration: Shopify APIs, Klaviyo/Postscript, RFM, GDPR form, referral status, data import.
   - E2E: Dashboard, widget, popups, GDPR form, referral status, checkout extensions (Cypress).
   - Load Test: 5,000 customers (Shopify), 50,000 customers (Plus) with k6.
   - Outsource QA ($2,500).
7. **Shopify App Store**:
   - Optimize listing with demo videos (RFM, referrals, GDPR form, referral status, checkout extensions).
   - Ensure Polaris, App Bridge, GDPR/CCPA compliance.

### Timeline
- Month 1–2: Schema, OAuth, GraphQL APIs, webhook verification, RFM wizard, GDPR form, referral status, admin module APIs.
- Month 3–4: React dashboard, widget, admin frontend, RFM chart, on-site content, GDPR form, referral status, checkout extensions.
- Month 5–7: POS integration, checkout extensions, Rust Functions, data import, GDPR requests, referral notifications, testing, VPS deployment.

### Deliverables
- TVP with points, referrals, RFM analytics, POS, checkout extensions, email flows, data import, GDPR request form, referral status display, notification templates, rate limit monitoring.
- Admin module with overview, merchant management, points adjustment, user management, logs, GDPR requests, RBAC.
- Shopify/Klaviyo/Postscript integrations, test suite, VPS deployment.
- Multilingual merchant docs with Plus-specific onboarding.

## Phase 2: Core Feature Expansion + Admin Enhancements (4 Months)

### Goal
Add **Should Have** features: VIP tiers, advanced RFM configuration, exit-intent popups, Klaviyo/Mailchimp integration, multi-store point sharing, behavioral segmentation, RFM nudges, activity logs, checkout extensions, RFM segment preview, notification templates, customer data import, rate limit monitoring. Enhance admin module with plan management, integration health, RFM configuration, and rate limit monitoring.

### Enhancements & Best Practices
- Conduct bi-weekly feedback sessions with beta testers (surveys, PostHog).
- Maintain public changelog in GitHub.
- Implement i18next for multilingual UI (widget, dashboard, admin, notification templates).
- Add k6 load testing for RFM, VIP tiers, multi-store points, checkout extensions, customer import, rate limit monitoring.
- Monitor metrics: 80%+ RFM wizard completion, 5%+ referral conversion, 10%+ RFM tier engagement, 85%+ checkout extension adoption (Plus), 90%+ customer import success.
- Define acceptance criteria for outsourced UI/QA.
- Add PostHog events for Plus features (e.g., `multi_store_points_shared`, `rfm_nudge_action`, `rfm_segment_preview_viewed`, `notification_template_updated`, `rate_limit_viewed`).
- Monitor Shopify API changelogs.
- Use Nx for build optimization.

### Features
1. **Program - Referrals** (Referrals Service):
   - Configure rewards (points, 10% off), social sharing (Facebook, Instagram).
   - Status toggle, preview popup with multilingual fallback (`en`), notification templates.
   - Success Metric: 5%+ social referral conversion.
2. **Program - VIP Tiers** (Points Service):
   - Thresholds: Spending-based (Silver: $100+, Gold: $500+).
   - Perks: Early access, birthday gifts, multipliers (e.g., 1.5x for Gold).
   - Track in `vip_tiers` (JSONB), notify via Klaviyo/Postscript with default templates.
   - Success Metric: 10%+ tier engagement rate.
3. **Program - Activity** (Admin Service):
   - Display points, referrals, VIP tier changes with customer/date filters.
   - Paginate logs, cache in Redis Streams (`logs:activity:{merchant_id}`).
   - Success Metric: 90%+ log query performance under 1s.
4. **Analytics** (Analytics Service):
   - Reports: Loyalty-driven revenue, redemption rate, RFM engagement, repeat purchase rate.
   - Chart.js visualizations for tiers, segment previews, materialized views (`rfm_segment_counts`) for performance.
   - API: `/v1/api/rfm/segments/preview` for RFM segment preview.
   - gRPC: `/analytics.v1/AnalyticsService/GetSegments`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`.
   - Success Metric: 80%+ merchant interaction.
5. **On-Site Content** (Frontend Service):
   - Exit-intent popups, discount banners, point calculators, checkout extensions.
   - Multilingual fallback (`en`) for popups, notification templates.
   - Success Metric: 85%+ customization adoption.
6. **Settings** (Admin Service):
   - Advanced RFM: Custom thresholds (Recency 1–5: 7–90 days, Frequency 1–5: 1–10 orders, Monetary 1–5: $50–$2,500+), tiers, daily/weekly adjustments.
   - Wizard with “Reset to Defaults” (AOV-based, e.g., Monetary 5 = $2,500+ for Plus).
   - Chart.js segment preview, tooltips (e.g., “Recency <30 days targets active customers”).
   - Notification templates for points, referrals, GDPR requests.
   - Rate limit monitoring: Shopify API and integration limits (`/admin/v1/rate-limits`).
   - Success Metric: 80%+ wizard completion, 90%+ template updates.
7. **Integrations**:
   - Klaviyo/Mailchimp for events, email campaigns, notification templates (Referrals Service).
   - Multi-store point sharing for Plus (Points Service).
   - Customer data import: Async CSV import with validation (email, shopify_customer_id), GDPR compliance (Admin Service).
   - Success Metric: 50%+ multi-store adoption, 95%+ import success.
8. **Other**:
   - Behavioral segmentation (purchase frequency, churn risk) (Analytics Service).
   - RFM Nudges: “Stay Active!” in widget, log in `nudge_events`, multilingual support.
   - Success Metric: 10%+ nudge interaction rate.
9. **Admin Module Enhancements** (Admin Service):
   - Plan upgrades/downgrades, integration health (Shopify, Klaviyo, Postscript, detailed status), RFM config, rate limit monitoring.
   - “Login as Merchant” with temporary JWT, session timeout (30 min).
   - Success Metrics: 95%+ plan update success, 95%+ integration uptime.

### Database Schema
- **Add**:
  - `vip_tiers` (vip_tier_id, merchant_id, name, threshold_value, earning_multiplier, perks, entry_reward_id JSONB)
  - `nudges` (nudge_id, merchant_id, type CHECK('at-risk', 'loyal', 'new'), title, description JSONB, is_enabled)
  - `nudge_events` (event_id, customer_id, nudge_id, action CHECK('view', 'click', 'dismiss'), created_at)
  - `email_templates` (template_id, merchant_id, type, subject, body JSONB)
  - `email_events` (event_id, merchant_id, event_type, recipient_email ENCRYPTED)
  - `import_logs` (id, merchant_id, success_count, fail_count, fail_reason JSONB)
- **Indexes**: `vip_tiers(merchant_id)`, `nudges(merchant_id)`, `nudge_events(customer_id)`, `email_templates(merchant_id)`, `import_logs(merchant_id)`
- Partition `vip_tiers`, `nudges`, `nudge_events`, `import_logs` by `merchant_id`.
- Add partial indexes on `customers.rfm_score` for frequent segments.
- Implement `rfm_segment_counts` materialized view (merchant_id, segment_name, customer_count, last_refreshed, daily refresh).

### Tasks
1. **Backend (NestJS/TypeScript)**:
   - **Referrals Service**: APIs for social sharing, Klaviyo/Mailchimp/Postscript integration, notification templates, 5 retries.
   - **Points Service**: APIs for VIP tiers, multi-store point sharing.
   - **Analytics Service**: APIs for RFM config, segment previews (`/v1/api/rfm/segments/preview`), nudges, activity logs, advanced reports.
   - **Admin Service**: APIs for plan management, integration health, RFM config, rate limit monitoring (`/admin/v1/rate-limits`), customer import (`/admin/v1/customers/import`).
   - **gRPC**: `/analytics.v1/AnalyticsService/GetSegments`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`, `/admin.v1/AdminService/UpdateNotificationTemplate`, `/admin.v1/AdminService/GetRateLimits`, `/admin.v1/AdminService/ImportCustomers`.
   - Cache in Redis Streams, use AI for code/tests.
2. **Backend (Rust/Wasm)**:
   - Shopify Functions: VIP multipliers, RFM tier updates, checkout extensions.
3. **Frontend (Vite + React)** (Frontend Service):
   - Pages: `ReferralsPage.tsx` (social sharing, notification templates), `VIPPage.tsx`, `RFMConfigPage.tsx` (segment preview), `ActivityPage.tsx`, `IntegrationsPage.tsx`, `CheckoutExtensions.tsx`, `SettingsPage.tsx` (rate limit monitoring, customer import).
   - On-Site Content: Exit-intent popups, point calculators, checkout extensions, notification templates.
   - Admin Frontend: Plan management, integration health, RFM config, rate limit monitoring, customer import.
   - Use i18next for multilingual support.
4. **Database**:
   - Add tables for VIP tiers, nudges, email templates, import logs, `rfm_segment_counts`.
   - Optimize indexes, materialized views, partition for Plus-scale.
5. **Testing**:
   - Unit: Jest for APIs, RFM/VIP/nudge logic, customer import, rate limit monitoring.
   - Integration: Klaviyo/Mailchimp/Postscript, multi-store points, checkout extensions, customer import.
   - E2E: RFM UI, popups, admin roles, rate limit monitoring, customer import (Cypress).
   - Load Test: 5,000+ customers (Shopify), 50,000+ (Plus) with k6.
   - Outsource QA ($2,500).
6. **Deployment**:
   - Optimize Redis Streams, update Docker Compose for new endpoints.

### Timeline
- Month 8–9: Social referrals, VIP tiers, Klaviyo/Mailchimp/Postscript, multi-store points, RFM nudges, notification templates, customer import, rate limit monitoring.
- Month 10–11: Advanced RFM, activity logs, exit-intent popups, admin enhancements, RFM segment preview.

### Deliverables
- Features: Social referrals, VIP tiers, advanced RFM, Klaviyo/Mailchimp/Postscript, multi-store points, RFM nudges, activity logs, RFM segment preview, notification templates, customer import, rate limit monitoring.
- Enhanced admin module with plan management, integration health, RFM config, rate limit monitoring, customer import.
- Test suite, VPS deployment, multilingual docs.

## Phase 3: Advanced Features and Integrations + Admin Polish (4 Months)

### Goal
Add **Could Have** features: bonus campaigns (with RFM conditions), gamification, multilingual support, non-Shopify POS, advanced analytics, developer toolkit, sticky bar, RFM segment export, customer data import, campaign discounts, RBAC for import/campaign/VIP tiers management. Finalize admin module with advanced integrations and polish.

### Enhancements & Best Practices
- Implement load balancer (Nginx) for microservices scalability.
- Overlap testing with Phase 2 feedback for RFM, referrals, checkout extensions, customer import.
- Go/No-Go: 90% merchant satisfaction, 5%+ referral conversion, 85%+ checkout extension adoption (Plus), 10%+ campaign discount redemption.
- Monitor API latency, error rates via Grafana.
- Conduct a11y and localization testing with Storefront API.
- Use Nx for build optimization.

### Features
1. **Bonus Campaigns** (Points Service):
   - Types: Time-sensitive promotions, goal spend, multipliers (e.g., 2x points).
   - Conditions: Scheduled via dashboard, tied to purchases or RFM (`bonus_campaigns.conditions` JSONB, e.g., `{"rfm_score": {"recency": ">=4"}}`).
   - Track in `reward_redemptions` with `campaign_id`.
   - Success Metric: 20%+ campaign-driven engagement.
2. **Gamification** (Points Service):
   - Badges, leaderboards in widget via Storefront API, Redis sorted sets (`gamification:leaderboard:{merchant_id}`).
   - Success Metric: 15%+ gamification engagement.
3. **On-Site Content** (Frontend Service):
   - Sticky bar, checkout extensions, point calculators, multilingual fallback (`en`).
   - Success Metric: 10%+ sticky bar click-through rate.
4. **Integrations**:
   - Non-Shopify POS: Square (`/v2/payments`), Lightspeed (`/api/2.0/sales`) for points (Points Service).
   - Gorgias (`/api/tickets`), Yotpo (`/v1/reviews`), Postscript (`/sms/messages`), Shopify Flow, webhook-based ERP/CRM (Admin Service).
   - Success Metric: 50%+ integration adoption (Plus).
5. **Settings** (Admin Service):
   - Multilingual widget (10+ languages, `merchants.language` JSONB).
   - Multi-currency discounts via GraphQL Admin API.
   - Developer toolkit for metafields (`integrations.settings` JSONB).
   - Success Metric: 80%+ multilingual widget adoption.
6. **Analytics** (Analytics Service):
   - Advanced reports: 25+ metrics (ROI, behavior, redemption rates), comparisons with similar stores.
   - CSV/JSON export for RFM segments, revenue data, async processing.
   - Success Metric: 90%+ export completion under 5s.
7. **Admin Module** (Admin Service):
   - Platform settings, integration health (detailed status, `last_checked`), RFM segment export, customer import.
   - RBAC: Enforce for customer import (`admin:full`), campaign management (`admin:full`, `admin:points`), VIP tiers management (`admin:full`, `admin:points`), admin user management (`admin:full`).
   - Success Metrics: 95%+ integration uptime, 90%+ export performance.

### Database Schema
- **Add**:
  - `bonus_campaigns` (campaign_id, merchant_id, type, multiplier, start_date, end_date, conditions JSONB)
  - `gamification_achievements` (achievement_id, customer_id, merchant_id, badge, created_at)
  - `reward_redemptions` (add campaign_id)
- **Indexes**: `bonus_campaigns(merchant_id)`, `gamification_achievements(customer_id, merchant_id)`, `reward_redemptions(campaign_id)`
- Partition `bonus_campaigns`, `gamification_achievements`, `reward_redemptions` by `merchant_id`.

### Tasks
1. **Backend (NestJS/TypeScript)**:
   - **Points Service**: APIs for campaigns, gamification, campaign discounts with RFM conditions.
   - **Admin Service**: APIs for non-Shopify POS, developer toolkit, RFM export, customer import with RBAC.
   - Integrations: Square, Lightspeed, Gorgias, Yotpo, Postscript.
   - RBAC: Enforce for customer import, campaign management, VIP tiers, admin user management.
2. **Backend (Rust/Wasm)**:
   - Shopify Functions: Campaign discounts (with RFM conditions), gamification rewards.
3. **Frontend (Vite + React)** (Frontend Service):
   - Pages: `CampaignsPage.tsx`, `GamificationPage.tsx`, `SettingsPage.tsx` (multilingual, developer tools), `AnalyticsPage.tsx` (reports, export).
   - On-Site Content: Sticky bar, checkout extensions.
   - Admin Frontend: Integration health, RFM export, customer import with RBAC.
4. **Testing**:
   - Unit: Jest for campaigns, gamification, RFM export, customer import.
   - Integration: Non-Shopify POS, Gorgias/Yotpo, webhooks, customer import.
   - E2E: Multilingual widget, analytics, sticky bar, customer import (Cypress).
   - Load Test: 10,000+ customers (Shopify), 50,000+ (Plus) with k6.
5. **Deployment**:
   - VPS with Docker, Nginx, Cloudflare CDN for multilingual content.
   - Optimize PostgreSQL partitioning, Redis Streams.

### Timeline
- Month 12–13: Campaigns, gamification, sticky bar, webhook integrations, customer import.
- Month 14–15: Non-Shopify POS, multilingual support, advanced analytics, developer toolkit.

### Deliverables
- Features: Campaigns (with RFM conditions), gamification, multilingual widget, non-Shopify POS, advanced analytics, developer toolkit, sticky bar, RFM export, customer import.
- Polished admin module with integration health, RFM export, customer import, RBAC.
- Test suite, VPS deployment, multilingual docs.

## Phase 4: Optimization and Scaling (3 Months)

### Goal
Scale for 5,000+ merchants (50,000+ customers for Plus), achieve Built for Shopify certification, iterate based on feedback, optimize microservices performance, ensure GDPR/CCPA compliance.

### Enhancements & Best Practices
- Test against Shopify API sandbox for breaking changes.
- Monitor Shopify changelogs for versioning updates.
- Maintain runbook for Docker, Nginx, Redis restarts.
- Validate PostgreSQL/Redis backups monthly.
- Iterate on RFM, referrals, checkout extensions, gamification, nudges, customer import via PostHog (`checkout_extension_used`, `rfm_nudge_action`, `campaign_discount_redeemed`, `gdpr_request_submitted`).
- Use Nx for build optimization.

### Tasks
1. **Optimization**:
   - NestJS: Optimize APIs with async/await, GraphQL batching for complex queries.
   - Rust: Transition RFM analytics, campaign discounts to Rust for performance.
   - Redis: Cache points, referrals, RFM, gamification, nudges, customer import status in Streams.
   - PostgreSQL: Optimize partitioning, materialized views (`rfm_segment_counts`).
2. **Analytics Enhancements** (Analytics Service):
   - RFM reports (engagement, redemption rate, churn reduction) with Chart.js.
3. **Shopify Certification**:
   - Ensure Polaris, GDPR/CCPA compliance (with `gdpr_requests` table), load test for 5,000+ customers.
4. **User Feedback**:
   - Iterate with 20–30 merchants (5–7 Plus) via surveys/calls.
5. **Marketing**:
   - Promote via Shopify Reddit/Discord, ads, case studies (15% churn reduction, 20% checkout extension adoption, 10% campaign discount redemption).
6. **VPS Maintenance**:
   - Monitor Docker, Nginx, Redis performance via Grafana.
   - Update Docker Compose for new features.
7. **GDPR/CCPA Compliance**:
   - Implement webhook handling for `customers/data_request`, `customers/redact` with `gdpr_requests` table, `retention_expires_at` tracking.

### Timeline
- Month 16–18: Optimization, certification, feedback iteration, GDPR/CCPA webhook handling.

### Deliverables
- Scalable infrastructure for 5,000+ merchants.
- Advanced RFM analytics with reports.
- Built for Shopify certification.
- Marketing for 100+ merchants (5–10 Plus).
- Updated VPS maintenance and docs with GDPR/CCPA compliance.

## Full Roadmap Timeline
- Phase 1: 7 months
- Phase 2: 4 months
- Phase 3: 4 months
- Phase 4: 3 months
- **Total**: 18 months

## Success Metrics
- **Phase 1**: 90% merchant satisfaction, 80% RFM wizard completion, 5%+ referral conversion, 85%+ checkout extension adoption (Plus), 95%+ GDPR request handling, 60%+ referral status engagement, 70%+ notification template usage.
- **Phase 2**: 10%+ RFM tier engagement, 5%+ social referral conversion, 50%+ multi-store adoption, 10%+ nudge interaction, 80%+ RFM segment preview usage, 90%+ customer import success.
- **Phase 3**: 20%+ repeat purchase increase, 15%+ gamification engagement, 80%+ multilingual widget adoption, 10%+ campaign discount redemption.
- **Phase 4**: 100+ merchants (5–10 Plus), 4.5+ star rating, Built for Shopify certification.

## Next Steps
- **Month 1 Sprint**:
   - Set up `loyalnest_full_schema.sql` with JSONB, indexes, partitioning, `referral_links`, `gdpr_requests`, `email_templates`.
   - Implement Shopify OAuth, GraphQL APIs in Auth Service.
   - Generate APIs for points, referrals, RFM, settings, GDPR form, referral status, admin module with AI; review manually.
   - Implement webhook verification (5 retries) for `orders/create`, GDPR/CCPA webhooks.
   - Recruit 5–10 beta testers (2–3 Plus) via Shopify Reddit/Discord.
   - Set up VPS with Docker, Nginx, GitHub Actions with Nx change detection.
- **Seek Feedback**: Share TVP prototype with 3–5 merchants (1–2 Plus) by Month 3, focusing on RFM usability, referrals, GDPR form, referral status, checkout extensions, admin module.
- **Learning Plan**: Complete NestJS, Vite + React, Shopify GraphQL, Nx tutorials in Week 1.

## Ongoing Best Practices & Metrics
- Maintain multilingual docs with 1–2 minute videos for Plus merchants.
- Publish public changelog in GitHub.
- Monitor API latency, errors, database performance via Grafana.
- Review Shopify security/API changelogs monthly.
- Plan Kubernetes migration for 5,000+ merchants.
- Track PostHog metrics: RFM wizard, referral conversion, checkout extension adoption, GDPR requests, referral status, admin actions.
- Optimize PostgreSQL partitioning, Redis Streams caching.
- Document infrastructure (Docker Compose, Nginx) with IaC.
- Set up Grafana for microservices monitoring, alerting.
- Conduct monthly security/dependency audits.
- Ensure WCAG 2.1 and localization for user-facing features.