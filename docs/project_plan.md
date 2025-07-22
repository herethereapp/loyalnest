# Project Plan: LoyalNest Shopify App

## Objective
Develop a Shopify app, LoyalNest, delivering a customizable, user-friendly loyalty and rewards program to boost customer retention, repeat purchases, and brand loyalty, competing with Smile.io, Yotpo, and LoyaltyLion. Key differentiators include RFM segmentation in all plans, affordable pricing ($29/month for 500 orders), SMS-driven referrals via Klaviyo/Postscript with AWS SES fallback, lightweight gamification, multilingual support (`en`, `es`, `fr`, `de`, `pt`, `ja` in Phases 2–5; `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL) in Phase 6), GDPR/CCPA compliance, and broad POS support (Shopify, Square with manual sync). Deliver a production-grade TVP in 39.5 weeks (7–8 months, Phases 1–5), with full implementation in 12–14 months (Phase 6 ongoing). The app targets small (100–1,000 customers, AOV $20–$50), medium (1,000–10,000 customers, AOV $50–$200), Shopify Plus (10,000+ customers), and global/premium merchants (50,000+ customers). It uses a microservices architecture (NestJS/TypeORM, Rust/Wasm, PostgreSQL with JSONB and range partitioning, Redis Cluster/Streams, Kafka, Bull queues, Loki + Grafana, Prometheus, Sentry), deployed on a VPS with Docker (Kubernetes in Phase 6). Security includes Shopify OAuth, RBAC with MFA (Auth0), AES-256 encryption (pgcrypto), GDPR/CCPA compliance (90-day Backblaze B2 backups, RTO: 4 hours, RPO: 1 hour), and OWASP ZAP (ECL: 256). Development leverages AI tools (Grok, GitHub Copilot, Cursor), in-house UI/UX, and QA, with community-led growth via “LoyalNest Collective” Slack.

## Features
- **Must Have (TVP, Phases 3–4)**:
  - Points: Purchases (10 points/$), signups (200 points), reviews (100 points), birthdays (200 points).
  - SMS/email/WhatsApp referrals (Klaviyo/Postscript with AWS SES fallback, Twilio).
  - Basic RFM analytics: Default segments (“High-Value Loyal,” “At-Risk,” “New Customers”), incremental updates on `orders/create`.
  - Shopify POS with offline mode (SQLite queue).
  - Checkout extensions (Checkout UI Extensibility APIs, points redemption).
  - GDPR request form (submission/confirmation, `gdpr_requests.retention_expires_at`).
  - Referral status with progress bar (`ReferralProgress.tsx`).
  - Notification templates with live preview (JSONB `email_templates.body`).
  - Customer import (async CSV, Smile.io/LoyaltyLion migration).
  - Campaign discounts with RFM conditions (`bonus_campaigns.conditions`, JSONB).
  - Rate limit monitoring with alerts (Slack/email at 80% Shopify API limit) and queue handling (`/admin/rate-limits/queue`).
  - Usage thresholds (e.g., SMS referral limit progress bar).
  - Upgrade nudges (Polaris `Banner` for $29/month plan).
  - Contextual tips (2/day, e.g., “Add birthday bonus to boost referrals”).
  - Integration kill switch (`US-AM15`).
  - 3-step onboarding flow (RFM setup, referrals, checkout extensions).
- **Should Have (Phases 4–5)**:
  - VIP tiers with progress bars (`US-CW16`).
  - Exit-intent popups (referral-focused).
  - Behavioral segmentation (cart abandoners, frequent browsers via PostHog).
  - Multi-store point sharing (Shopify Plus, `merchant_group_id` in Redis).
  - Shopify Flow templates (welcome series, win-back, `US-MD19`).
  - Theme App Extensions (`US-CW15`).
- **Could Have (Phase 6)**:
  - Gamification (badges, leaderboards, streaks, `US-CW11`).
  - Multilingual widget (`ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL), `US-MD2`).
  - Multi-currency discounts (`US-CW6`).
  - Non-Shopify POS (Square, Lightspeed).
  - Advanced analytics (25+ reports, `US-MD11`, `US-MD22`).
  - Developer toolkit (Shopify metafields, custom webhooks).
  - AI-powered reward suggestions (xAI API, `US-AM16`, https://x.ai/api).
  - OpenTelemetry, WCAG 2.1 AA, dark mode, zero-downtime deployments, mobile wallet export (`US-CW17`), multi-tenant support (`US-AM14`).

## Success Metrics
- **Phases 3–4 (TVP)**:
  - 90%+ merchant satisfaction.
  - 80%+ RFM wizard completion.
  - 7%+ SMS referral conversion, 3%+ email referral conversion.
  - 85%+ checkout extension adoption, 20%+ redemption rate.
  - 50%+ GDPR form usage, 60%+ referral status engagement.
  - 80%+ notification template usage, 90%+ customer import success rate.
  - 10%+ campaign discount redemption, 10%+ RFM campaign repeat purchase uplift.
  - 90%+ i18n translation accuracy (`en`, `es`, `fr`, `de`, `pt`, `ja`).
- **Phase 5 (Launch)**: 100+ merchants (5–10 Shopify Plus) in 3 months, 4.5+ star rating in 6 months.
- **Phase 6 (Post-Launch)**: 20% repeat purchase increase, 10%+ RFM tier engagement, 50%+ multi-store sharing adoption, 15%+ campaign discount redemption, 20%+ mobile wallet adoption, 90%+ i18n adoption for additional languages, Built for Shopify certification in 12 months.

## Timeline and Phases
**Total**: 39.5 weeks (7–8 months for TVP, Phases 1–5), 12–14 months for full implementation (Phase 6 ongoing).

### Phase 1: Research and Planning (Weeks 1–4, July–August 2025)
- **Objective**: Define USPs, validate pricing and Must Have features, establish microservices architecture with AdminCore and AdminFeatures split.
- **Tasks**:
  - **Market Research**:
    - Analyze competitors (Smile.io, Yotpo, LoyaltyLion, BON Loyalty, Rivo, Gameball) for gaps in SMS referrals, RFM analytics, POS support, checkout extensions, GDPR compliance.
    - Run pricing surveys (Typeform/Google Forms) with 10–15 merchants (3–5 Shopify Plus, 1 global/premium) for Free (300 orders, basic RFM, 50 SMS referrals), $29/month (500 orders, full RFM, checkout extensions, campaign discounts), $99/month (1,500 orders, multi-store), Enterprise (custom) plans.
    - Engage Shopify Partners for feedback from 10–15 merchants (3–5 Shopify Plus, 1 global/premium).
  - **Technical Requirements**:
    - Design microservices (auth, points, referrals, rfm_analytics, event_tracking, admin_core, admin_features, campaign, gamification) using Nx monorepo, NestJS (TypeScript), Rust/Wasm (Shopify Functions), PostgreSQL (JSONB, range partitioning), Redis Cluster/Streams, Kafka, Bull queues, Loki + Grafana, Prometheus, Sentry.
    - Define `loyalnest_full_schema.sql` with tables: `customers` (email, rfm_score, AES-256 encrypted), `points_transactions`, `reward_redemptions` (campaign_id), `referrals` (referral_link_id, merchant_referral_id), `program_settings` (rfm_thresholds, JSONB), `email_templates` (body, JSONB), `gdpr_requests` (retention_expires_at), `rfm_segment_counts` (materialized view, incremental refresh via `rfm_segment_deltas`), `audit_logs`, `integrations`, `setup_tasks`, `merchant_settings` (currencies: JSONB), `customer_badges`, `leaderboard_rankings`, `merchant_feedback`.
    - Implement API versioning (`/v1/api/*` for REST, gRPC for RFM Analytics/AdminCore/AdminFeatures), circuit breakers (`node-circuitbreaker`), webhook idempotency (Redis: `webhook:{merchant_id}:{event_id}`), rate limit queue (Bull: `/admin/rate-limits/queue`).
    - Plan disaster recovery with `pg_dump`, Redis snapshotting, Backblaze B2 backups (90-day retention, RTO: 4 hours, RPO: 1 hour), validated via `restore.sh`.
    - Document API contracts (OpenAPI/Swagger for REST, gRPC specs).
    - Develop `dev.sh` script for Docker setup, mock data seeding (Faker), RFM simulation, rate limit simulation (standard vs. Plus).
  - **Team**: 2 developers, in-house UI/UX, QA, leveraging AI (Grok, Copilot, Cursor) for schema, architecture diagrams, and initial scripts.
- **Deliverables**:
  - Competitive analysis report.
  - Pricing model and survey report.
  - Feature prioritization matrix (Must Have, Should Have, Could Have).
  - Technical architecture diagram (Nx, Docker, VPS, gRPC, AdminCore/AdminFeatures split).
  - `loyalnest_full_schema.sql` and API specs.
- **Budget**: $8,000 (surveys, research, AI tools).
- **Dependencies**: Shopify Partners feedback precedes architecture finalization.

### Phase 2: Design and Prototyping (Weeks 5–11, August–September 2025)
- **Objective**: Create Polaris-compliant UI prototypes, finalize microservices with AdminCore and AdminFeatures split, validate pricing/UX with 10–15 merchants (3–5 Shopify Plus, 1 global/premium), implement i18n for `en`, `es`, `fr`, `de`, `pt`, `ja` with native speaker validation.
- **Tasks**:
  - **UI/UX (In-House)**:
    - Develop Figma wireframes/prototypes for Merchant Dashboard (`WelcomePage.tsx`, `PointsPage.tsx`, `ReferralsPage.tsx`, `AnalyticsPage.tsx`, `SettingsPage.tsx`), Customer Widget (`Widget.tsx`, `ReferralProgress.tsx`), Admin Module (`AdminPage.tsx`, `QueuesPage.tsx`, `RateLimitsPage.tsx`), checkout extensions, GDPR form, referral status, notification templates, rate limit monitoring, usage thresholds, upgrade nudges, 3-step onboarding flow (RFM setup, referrals, checkout extensions).
    - Design no-code RFM setup wizard with default segments (“High-Value Loyal,” “At-Risk,” “New Customers”) and Chart.js scatter plot for Recency vs. Monetary (`US-MD20`, `US-MD21`).
    - Plan on-site content: SEO-friendly loyalty page, rewards panel, launcher button, points display, post-purchase/email capture popups, GDPR form, referral status (`US-CW8–CW10`).
    - Implement i18next for `en`, `es`, `fr`, `de`, `pt`, `ja`, with placeholders for remaining languages, ensuring WCAG 2.1 AA partial compliance (Lighthouse CI 90+).
    - Use Polaris, Tailwind CSS, ARIA labels, and Storybook for component consistency.
  - **Prototyping**:
    - Build clickable Vite + React prototype (Vercel) with Must Have features, pricing mockup, onboarding flow, contextual tips (2/day, e.g., “Increase referrals with birthday bonus”).
    - Mock APIs (`/points.v1/GetPointsBalance`, `/referrals.v1/CreateReferral`, `/analytics.v1/GetRFMSegments`, `/admin.v1/GetRateLimits`) using JSON fixtures.
    - Test with Jest (unit, i18next fallbacks), Cypress (E2E, RTL rendering for `ar`, `he` placeholders), k6 (1,000 orders/hour), Lighthouse CI (90+ score).
  - **Merchant Feedback**:
    - Validate prototypes with 10–15 merchants (3–5 Shopify Plus, 1 global/premium) via Shopify Partners and “LoyalNest Collective” Slack, targeting 80%+ RFM wizard satisfaction, 90%+ checkout extension clarity, 90%+ i18n translation accuracy (2–3 native speakers per language).
    - Collect feedback on RFM, referrals, POS, checkout extensions, GDPR, onboarding, pricing, contextual tips via Zoom interviews and Google Forms.
  - **Architecture**:
    - Finalize microservices diagram (Draw.io) with REST APIs (`/v1/api/*`), gRPC (`/analytics.v1/*`, `/admin.v1/*`), and schema (`loyalnest_full_schema.sql`) including AdminCore and AdminFeatures.
    - Conduct k6 scalability tests (1,000 orders/hour) for Redis, PostgreSQL, and APIs.
    - Set up Bull queues (rate limit throttling, customer imports), Loki (logs), Prometheus (metrics), AWS SNS (alerts).
  - **i18n**:
    - Integrate i18next with `en.json`, `es.json`, `fr.json`, `de.json`, `pt.json`, `ja.json`, testing with Jest/Cypress for translation fallbacks and RTL rendering.
  - **Team**: 2 developers, in-house UI/UX, QA, using AI for mockups, components, and tests.
- **Deliverables**:
  - Figma wireframes/mockups for dashboard, widget, admin module (AdminCore/AdminFeatures), checkout extensions, GDPR form, referral status, notification templates, rate limit monitoring, usage thresholds, onboarding flow.
  - Clickable prototype (Vercel).
  - Microservices architecture diagram with k6 test results.
  - Merchant feedback report (RFM, referrals, POS, checkout extensions, GDPR, onboarding, i18n).
  - i18next integration (`en`, `es`, `fr`, `de`, `pt`, `ja`).
- **Budget**: $20,500 (Figma, Storybook, k6, Vercel, AI tools, feedback sessions, translations).
- **Dependencies**: Merchant feedback by Week 9; schema precedes development; Phase 1 survey data as fallback.

### Phase 3: Development (Weeks 12–30, October 2025–February 2026)
- **Objective**: Build production-grade TVP with Must Have features, admin module (AdminCore and AdminFeatures), Shopify Plus compatibility (40 req/s), and i18n (`en`, `es`, `fr`, `de`, `pt`, `ja`) for 5,000+ customers (10,000+ for Plus).
- **Tasks**:
  - **Backend (Microservices, NestJS)**:
    - **Auth Service**: `/v1/api/auth/login`, `/v1/api/auth/refresh`, `/v1/api/auth/roles` (Shopify OAuth, JWT, RBAC with MFA via Auth0, roles: `admin:full`, `admin:analytics`, `admin:support`).
    - **Points Service**: `/v1/api/points/earn`, `/v1/api/points/redeem`, `/v1/api/points/adjust`, `/v1/api/rewards` (earning: 10 points/$, redemption: $5/500 points, free shipping: 1000 points, free products: 1500 points, POS offline mode via SQLite queue, checkout extensions, campaign discounts with RFM conditions).
    - **Referrals Service**: `/v1/api/referrals/create`, `/v1/api/referrals/complete`, `/v1/api/referrals/status`, `/v1/api/referrals/progress`, `/v1/api/referrals/merchant` (SMS/email/WhatsApp via Klaviyo/Postscript with AWS SES fallback, referral status, spoof detection with xAI API, merchant referrals, `referral_fallback_triggered` to PostHog).
    - **RFM Analytics Service**: `/v1/api/rfm/segments`, `/v1/api/rfm/segments/preview`, gRPC (`/analytics.v1/RFMAnalyticsService/GetSegments`) (Recency ≤7 to >90 days, Frequency 1 to >10, Monetary <0.5x to >5x AOV, default segments, incremental updates on `orders/create`).
    - **Event Tracking Service**: `/v1/api/events` (PostHog: `points_earned`, `referral_completed`, `referral_fallback_triggered`, `rfm_updated`, `plan_limit_warning`, `campaign_discount_redeemed`, `rate_limit_viewed`).
    - **AdminCore Service**: `/admin/merchants`, `/admin/logs`, gRPC (`/admin.v1/GetMerchants`, `/admin.v1/GetAuditLogs`, `/admin.v1/HandleGDPRRequest`) (merchant management, GDPR webhooks, audit logs).
    - **AdminFeatures Service**: `/admin/points/adjust`, `/admin/referrals`, `/admin/rfm-segments`, `/admin/rfm/export`, `/admin/rfm/visualizations`, `/admin/notifications/template`, `/admin/rate-limits`, `/admin/rate-limits/queue`, `/admin/customers/import`, `/admin/queues`, `/v1/api/plan/usage`, `/admin/setup/stream`, `/admin/settings/currency`, `/admin/integrations/square`, `/admin/integrations/square/sync`, gRPC (`/admin.v1/UpdateNotificationTemplate`, `/admin.v1/GetRateLimits`, `/admin.v1/ImportCustomers`, `/admin.v1/StreamSetupProgress`, `/admin.v1/UpdateCurrencySettings`, `/admin.v1/ConfigureSquareIntegration`) (points adjustments, referrals, RFM segments, customer imports, notification templates, rate limit queue, integration health, onboarding, multi-currency settings).
    - Inter-service communication: gRPC with circuit breakers for RFM Analytics/AdminCore/AdminFeatures; Kafka for events (`points.earned`, `referral.created`, `referral_fallback_triggered`, `customer.imported`).
  - **Rust/Wasm**: Shopify Functions for discounts, checkout extensions, RFM updates, campaign discounts (JSONB `bonus_campaigns.conditions`).
  - **Frontend**: Vite + React, Polaris, Tailwind CSS, App Bridge:
    - Dashboard: `WelcomePage.tsx` (onboarding checklist, contextual tips), `PointsPage.tsx`, `ReferralsPage.tsx`, `AnalyticsPage.tsx` (RFM segments, Chart.js scatter plot for Recency vs. Monetary), `SettingsPage.tsx` (store, billing, rewards panel, checkout extensions, notification templates, rate limit monitoring, usage thresholds).
    - Widget: `Widget.tsx` (points balance, redemption, referral popup, GDPR form), `ReferralProgress.tsx` (progress bar).
    - Admin module: `AdminPage.tsx` (AdminCore: merchants, logs, GDPR; AdminFeatures: imports, templates, rate limits, Square sync), `QueuesPage.tsx`, `RateLimitsPage.tsx` (queue monitoring).
    - i18n: `en`, `es`, `fr`, `de`, `pt`, `ja` via i18next, validated with 2–3 native speakers per language.
    - Accessibility: ARIA, keyboard nav, Lighthouse CI (90+ score).
  - **Integrations**:
    - Shopify: APIs (`orders/create`, batched), POS (offline mode), Checkout UI Extensions.
    - Klaviyo/Postscript: SMS/email referrals, notification templates, AWS SES fallback.
    - Yotpo/Judge.me: Points-for-reviews.
    - Klaviyo/Mailchimp: Automated loyalty email flows (`US-BI1–BI3`).
    - Square: POS integration with health checks and manual sync (`/admin/integrations/square/sync`).
    - Async CSV import for customer data (Smile.io/LoyaltyLion migration, RBAC: `admin:full`).
  - **Database**:
    - PostgreSQL: JSONB (`customers.rfm_score`, `program_settings.rfm_thresholds`, `email_templates.body`), range partitioning (`points_transactions`, `referrals`, `reward_redemptions`, `created_at`), `rfm_segment_counts` materialized view (incremental refresh via `rfm_segment_deltas`, real-time on `orders/create`).
    - Redis Cluster/Streams: Cache points (`points:{customer_id}`), referrals (`referral:{referral_code}`), RFM scores (`rfm:{customer_id}`), rate limits (`shopify_api_rate_limit:{merchant_id}`), rate limit queue (`rate_limit_queue:{merchant_id}`).
  - **Security**:
    - AES-256 encryption for PII (`customers.email`, `rfm_score`, `wallet_passes`) via pgcrypto.
    - GDPR webhooks (`customers/data_request`, `customers/redact`) with retry logic (Redis dead-letter queue).
    - OWASP ZAP (ECL: 256), webhook idempotency (Redis).
  - **Testing**:
    - Unit/Integration: Jest for NestJS APIs, `cargo test` for Rust, RFM logic, campaign discounts, i18next fallbacks.
    - E2E: Cypress for dashboard, widget, RFM UI, popups, GDPR form, referral status, notification templates, rate limit monitoring, checkout extensions, usage thresholds, RTL rendering (`ar`, `he` placeholders).
    - Load: k6 for 10,000 orders/hour (Shopify Plus: 40 req/s).
    - Resilience: Chaos Mesh for microservices.
    - Test data factory: `test/factories/merchant.ts`, `test/factories/customer.ts`, `fixtures.rs` for merchants, customers, referrals, RFM scores.
  - **Deployment**:
    - VPS (Ubuntu, Docker Compose) for microservices, PostgreSQL, Redis Cluster, Kafka, Nginx, Loki, Prometheus.
    - `dev.sh` script for Docker setup, mock data seeding (Faker), RFM simulation, rate limit simulation (standard vs. Plus).
    - CI/CD: GitHub Actions with change detection, Lighthouse CI (90+ score), weekly backup validation (`restore.sh`).
    - Backups: `pg_dump`, Redis snapshotting, Backblaze B2 (90-day retention, RTO: 4 hours, RPO: 1 hour).
  - **Monitoring**:
    - Prometheus/Grafana (latency <1s, error rate <1%), Sentry, Loki (logs tagged with `shop_domain`, `merchant_id`, `service_name`), AWS SNS alerts (>100 points adjustments/hour).
  - **Team**: 2 developers, in-house UI/UX, QA, using AI for code, tests, components, and scripts.
- **Deliverables**:
  - TVP with Must Have features and i18n (`en`, `es`, `fr`, `de`, `pt`, `ja`).
  - Admin module with AdminCore (merchants, logs, GDPR) and AdminFeatures (imports, templates, rate limits, Square sync).
  - Integrations: Shopify, Klaviyo/Postscript (AWS SES fallback), Yotpo, Klaviyo/Mailchimp, Square.
  - Test reports (Jest, Cypress, k6, Chaos Mesh).
  - VPS deployment with `dev.sh`, `restore.sh`, backups.
- **Budget**: $49,500 (development, testing, integrations, AI tools, VPS, translations).
- **Dependencies**: Shopify OAuth/webhooks, Phase 2 feedback, schema completion.

### Phase 4: Beta Testing and Refinement (Weeks 31–36, March–April 2026)
- **Objective**: Validate TVP with 10–15 merchants (3–5 Shopify Plus, 1 global/premium), refine UX, implement Should Have features, test i18n (`en`, `es`, `fr`, `de`, `pt`, `ja`) with native speaker validation.
- **Tasks**:
  - **Beta Testing**:
    - Recruit 10–15 merchants via Shopify Reddit/Discord, Partners program, “LoyalNest Collective” Slack (free 300-order plan).
    - Test Must Have features: 80%+ RFM wizard completion, 7%+ SMS referral conversion, 3%+ email referral conversion, 85%+ checkout extension adoption, 20%+ redemption rate, 50%+ GDPR form usage, 60%+ referral status engagement, 80%+ notification template usage, 90%+ customer import success rate, 10%+ campaign discount redemption, 90%+ i18n translation accuracy (2–3 native speakers per language).
    - Collect feedback on RFM (incremental updates), referrals (AWS SES fallback), POS (Square sync), checkout extensions, GDPR, onboarding, notification templates, customer import, campaign discounts, rate limits (queue monitoring), upgrade funnel, contextual tips, i18n via Slack and Google Forms.
    - Track usage with PostHog (`checkout_extension_redeemed`, `gdpr_request_submitted`, `referral_progress_viewed`, `referral_fallback_triggered`, `notification_template_edited`, `campaign_discount_redeemed`, `rate_limit_viewed`, `plan_limit_warning`).
  - **Refinement**:
    - Fix bugs in RFM calculations (incremental updates), referral popups (AWS SES fallback), POS offline mode, Square sync, checkout extensions, GDPR form, referral status, notification templates, customer import, rate limit monitoring.
    - Enhance RFM analytics (10%+ repeat purchase uplift, `US-MD20`, incremental updates on `orders/create`).
    - Optimize Redis Cluster caching, PostgreSQL partitioning, Loki logging, Bull queue rate limit throttling.
    - Implement Should Have features: VIP tiers, exit-intent popups (`ReferralPopup.tsx`, PostHog `page_exit`), behavioral segmentation (`cart_abandoned`, `product_viewed`), multi-store point sharing, Shopify Flow templates.
    - Test disaster recovery (Backblaze B2 restore, RTO: 4 hours, RPO: 1 hour) with `restore.sh`.
  - **Documentation/Support**:
    - Create guides/YouTube tutorials for RFM wizard, points, referrals (AWS SES fallback), POS (Square sync), checkout extensions, GDPR form, notification templates, customer import, rate limit monitoring, usage thresholds, VPS deployment.
    - Develop Shopify Plus onboarding guide (multi-user setup, checkout extensions, multi-store sharing, campaign discounts).
    - Set up public changelog (Headway), feature voting (Canny/Trello), and AMA in “LoyalNest Collective” Slack.
  - **Team**: 2 developers, in-house UI/UX, QA.
- **Deliverables**:
  - Beta test report (RFM, referrals, POS, checkout extensions, GDPR, onboarding, i18n).
  - Refined TVP with Should Have features and i18n refinements.
  - Documentation, tutorials, support portal, Shopify Plus onboarding guide, Slack community.
- **Budget**: $10,000 (testing, Slack, tutorials, bug fixes, translations).
- **Dependencies**: Shopify Flow requires Plus API; RFM enhancements depend on Phase 3.

### Phase 5: Launch and Marketing (Weeks 37–43, April–May 2026)
- **Objective**: Launch on Shopify App Store, attract 100+ merchants (5–10 Shopify Plus), deploy remaining Should Have features, ensure i18n support (`en`, `es`, `fr`, `de`, `pt`, `ja`).
- **Tasks**:
  - **App Store Submission**:
    - Ensure Polaris UI, App Bridge, GDPR/CCPA compliance (AES-256 encryption, GDPR webhooks, `retention_expires_at`).
    - Optimize listing with 30-second demo videos (RFM setup, SMS referrals, checkout extensions, GDPR, i18n) and keywords (“loyalty program,” “RFM analytics,” “SMS referrals”).
    - A/B test listing copy (SensorTower).
  - **Marketing**:
    - Launch website with pricing, multilingual landing pages (`en`, `es`, `fr`, `de`, `pt`, `ja`), case studies (e.g., “10% referral conversion, 20% checkout extension adoption”), public changelog.
    - Promote via Shopify Reddit/Discord, “LoyalNest Collective,” social media (Facebook, Instagram), Shopify Plus agencies (Eastside Co, Pixel Union).
    - Implement merchant referral program ($50 credit, `/v1/api/referrals/merchant`).
  - **Support**:
    - Offer 24/7 email support, Slack community, live chat for paid plans, white-glove onboarding for Plus.
    - Monitor via admin module (`audit_logs`, `api_logs`), Loki + Grafana, Prometheus, Sentry.
  - **Development**:
    - Add Should Have features: Theme App Extensions (`US-CW15`), Shopify Flow templates (`US-MD19`), multi-store point sharing, Klaviyo/Mailchimp integration, discount banners.
  - **Team**: 2 developers, in-house UI/UX, QA, marketing support.
- **Deliverables**:
  - Approved App Store listing.
  - Marketing website, promotional materials, multilingual support system.
  - Theme App Extensions, Shopify Flow templates, multi-store sharing.
- **Budget**: $8,000 (App Store, marketing, support, translations).
- **Dependencies**: Shopify Flow/Theme App Extensions require Plus API; i18n requires Phase 4 validation.

### Phase 6: Post-Launch and Scaling (Weeks 44+, June 2026–Ongoing)
- **Objective**: Grow to 100+ merchants (5–10 Shopify Plus), achieve Built for Shopify certification, implement Could Have features, add remaining languages (`ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)).
- **Tasks**:
  - **User Acquisition**:
    - Partner with Shopify Plus agencies, offer white-label API (`/v1/api/whitelabel`).
    - Publish case studies (20% repeat purchase increase, 50% multi-store sharing, 15% campaign discount redemption).
    - Engage “LoyalNest Collective” for feedback, monthly AMAs, feature voting.
  - **Development**:
    - Implement Could Have features: gamification, multilingual widget, multi-currency discounts, non-Shopify POS, advanced analytics, developer toolkit, AI reward suggestions (xAI API), custom webhooks (`/v1/api/webhooks/custom`), OpenTelemetry, WCAG 2.1 AA, dark mode, zero-downtime deployments, mobile wallet export (`US-CW17`), multi-tenant support (`US-AM14`).
    - Scale to Kubernetes for 5,000+ merchants (50,000+ customers).
  - **Maintenance**:
    - Release quarterly updates, monitor Shopify API changes (changelog RSS), run daily Backblaze B2 backups, validate weekly with `restore.sh`.
    - Apply for Built for Shopify certification (4.5+ star rating).
  - **Team**: 2 developers, in-house UI/UX, QA, DevOps for Kubernetes.
- **Deliverables**:
  - Performance reports (merchant growth, RFM engagement, referral rates, i18n adoption).
  - Feature updates (Could Have features, multilingual widget).
  - Built for Shopify application.
  - Kubernetes deployment guide.
- **Budget**: $4,912.50 (features, Kubernetes, community, translations).
- **Dependencies**: xAI API key (https://x.ai/api), mobile wallet vendor coordination, Phase 2–5 i18n hooks.

## Technical Architecture
- **Stack**: Vite + React (Polaris, Tailwind CSS, App Bridge), NestJS (TypeScript), Rust/Wasm (Shopify Functions), PostgreSQL (JSONB, range partitioning), Redis Cluster/Streams, Kafka, Bull queues, Loki + Grafana, Prometheus, Sentry.
- **Microservices**:
  - **Auth**: `/v1/api/auth/*` (Shopify OAuth, JWT, RBAC with MFA).
  - **Points**: `/v1/api/points/*`, `/v1/api/rewards/*` (earning, redemption, POS, checkout extensions, campaign discounts).
  - **Referrals**: `/v1/api/referrals/*` (SMS/email/WhatsApp with AWS SES fallback, referral status, merchant referrals).
  - **RFM Analytics**: `/v1/api/rfm/segments`, gRPC (`/analytics.v1/*`) (basic RFM, segment preview, incremental updates).
  - **Event Tracking**: `/v1/api/events` (PostHog integration).
  - **AdminCore**: `/admin/merchants`, `/admin/logs`, gRPC (`/admin.v1/*`) (merchant management, GDPR, logs).
  - **AdminFeatures**: `/admin/points/adjust`, `/admin/rate-limits`, `/admin/customers/import`, gRPC (`/admin.v1/*`) (imports, templates, rate limits, Square sync).
  - **Campaign**: `/api/campaigns/*` (discounts, RFM conditions).
  - **Gamification**: `/api/gamification/*` (badges, leaderboards).
- **APIs**:
  - REST: `/v1/api/*` for UI-facing endpoints, documented with OpenAPI/Swagger.
  - gRPC: `/analytics.v1/*`, `/admin.v1/*` for inter-service communication with circuit breakers.
  - Webhooks: `orders/create`, `customers/data_request`, `customers/redact` with idempotency (Redis).
- **Schema**: `customers` (email, rfm_score, AES-256), `points_transactions`, `reward_redemptions` (campaign_id), `referrals` (referral_link_id, merchant_referral_id), `program_settings` (rfm_thresholds, JSONB), `email_templates` (body, JSONB), `gdpr_requests` (retention_expires_at), `rfm_segment_counts` (materialized view, daily refresh via `rfm_segment_deltas`, real-time on `orders/create`), `audit_logs`, `integrations`, `setup_tasks`, `merchant_settings` (currencies: JSONB), `customer_badges`, `leaderboard_rankings`, `merchant_feedback`.
- **Security**: AES-256 encryption (pgcrypto), GDPR webhooks with retries (Redis dead-letter queue), OWASP ZAP (ECL: 256), RBAC (Auth0, roles: `admin:full`, `admin:analytics`, `admin:support`).
- **Deployment**: VPS (Ubuntu, Docker Compose) with Nginx, `dev.sh` for local setup, `restore.sh` for backup validation, CI/CD (GitHub Actions, change detection, Lighthouse CI), Backblaze B2 backups (RTO: 4 hours, RPO: 1 hour).
- **Monitoring**: Prometheus/Grafana (latency <1s, error rate <1%), Sentry, Loki (logs tagged with `shop_domain`, `merchant_id`, `service_name`), AWS SNS alerts.
- **Testing**: Jest (unit/integration, i18next fallbacks, 80%+ coverage), Cypress (E2E, RTL rendering for `ar`, `he`), k6 (1,000 orders/hour in Phase 2, 10,000 in Phase 3), Chaos Mesh, Lighthouse CI (90+ score), test data factory (`test/factories/*.ts`, `fixtures.rs`).
- **i18n**: i18next for `en`, `es`, `fr`, `de`, `pt`, `ja` (Phases 2–5), remaining languages (Phase 6), with Jest/Cypress tests for translation accuracy and RTL rendering, validated by 2–3 native speakers per language.

## Budget Allocation
- **Development**: $74,250 (TVP, microservices, AI tools, UI/UX, QA, backups, community, i18n, onboarding, contextual tips, kill switch).
- **Marketing**: $3,000 (website, Shopify community ads, social media, AMAs).
- **Support Infrastructure**: $4,500 (VPS, PostHog, Loki, Prometheus, Backblaze, Headway/Canny, k6).
- **Contingency (15%)**: $10,162.50.
- **Total**: $91,912.50 (scalable to $150K for Phase 6 Kubernetes).

## Risks and Mitigation
- **Shopify API Changes**: Pin API versions (2025-01), monitor changelog RSS, use circuit breakers, exponential backoff (3 retries, 500ms), Redis caching, AWS SNS alerts.
- **xAI API Delays**: Fallback to heuristic models, early API key setup (https://x.ai/api).
- **High Competition**: Highlight USPs (RFM, SMS/WhatsApp referrals, checkout extensions, Shopify Flow, contextual tips, $29/month pricing), merchant referral program ($50 credit).
- **Slow Adoption**: Free plan (300 orders, 50 SMS referrals), 14-day trial, “LoyalNest Collective,” Reddit/Discord, usage thresholds, upgrade nudges, win-back workflows, 3-step onboarding.
- **Onboarding Complexity**: RFM wizard, guided onboarding, Shopify Flow templates, Theme App Extensions, Plus onboarding guide, white-glove support, contextual tips (2/day).
- **Scalability (10,000 orders/hour)**: Microservices, Redis Cluster/Streams, PostgreSQL partitioning, Rust/Wasm, Kafka, Bull queues, Chaos Mesh, Kubernetes (Phase 6), k6 testing (Phase 2: 1,000 orders/hour; Phase 3: 10,000 orders/hour).
- **Team Bandwidth**: AI tools (Grok, Copilot, Cursor), Nx monorepo, `dev.sh`, `restore.sh`, test data factory, CI/CD, Slack bots, Headway. Prioritize Must Have features in Phase 3, defer Should Have to Phase 4–5.
- **GDPR/CCPA Compliance**: Anonymize data (`rfm_benchmarks.anonymized_data`), AES-256 encryption, 90-day retention, OWASP ZAP, GDPR form with submission/confirmation, Cypress tests for GDPR webhooks.
- **Multilingual Accuracy**: Validate translations (`en`, `es`, `fr`, `de`, `pt`, `ja`) in Phases 2–5 with 2–3 native speakers per language via “LoyalNest Collective,” defer RTL languages (`ar`, `he`) to Phase 6 with dedicated Jest/Cypress tests.
- **Integration Reliability**: AWS SES fallback for Klaviyo/Postscript (`referral_fallback_triggered`), health checks and manual sync for Square (`/admin/integrations/square/sync`), kill switches (`US-AM15`), Grafana monitoring.

## Appendices
- **API Endpoints**:
  - REST: `/v1/api/auth/login`, `/v1/api/points/earn`, `/v1/api/referrals/progress`, `/v1/api/rfm/segments`, `/admin/rate-limits`, `/admin/rate-limits/queue`, `/admin/notifications/template`, `/admin/integrations/square/sync`.
  - gRPC: `/analytics.v1/RFMAnalyticsService/GetSegments`, `/admin.v1/AdminCoreService/GetMerchants`, `/admin.v1/AdminFeaturesService/UpdateNotificationTemplate`.
- **Schema Details**: `loyalnest_full_schema.sql` with indexes on `customers(email, merchant_id, rfm_score)`, `points_transactions(customer_id)`, `referrals(merchant_id, referral_link_id, merchant_referral_id)`, `reward_redemptions(campaign_id)`, `gdpr_requests(retention_expires_at)`, `rfm_segment_counts`, `audit_logs`.
- **Testing Plan**: Jest (80%+ coverage, i18next fallbacks), Cypress (dashboard, widget, GDPR form, referral status, notification templates, rate limits, RTL rendering), k6 (10,000 orders/hour), Chaos Mesh, Lighthouse CI (90+ score).
- **Deployment Guide**: Docker Compose, Nginx, `dev.sh`, `restore.sh`, Backblaze B2 setup instructions (RTO: 4 hours, RPO: 1 hour).