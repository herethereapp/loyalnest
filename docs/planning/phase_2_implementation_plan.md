# Phase 2 Implementation Plan: LoyalNest Shopify App (Weeks 5–11, August–September 2025)

## Overview
Phase 2 focuses on building clickable prototypes for the LoyalNest Shopify app, hosted on a VPS (Ubuntu, Docker Compose) instead of Vercel, to validate user experience, pricing, and technical architecture without Figma wireframes. The prototypes cover Must Have features: points (10 points/$, signups: 200 points, reviews: 100 points, birthdays: 200 points), SMS/email/WhatsApp referrals (Klaviyo/Postscript, AWS SES fallback), basic RFM analytics (default segments: “High-Value Loyal,” “At-Risk,” “New Customers”), Shopify POS with offline mode, checkout extensions, GDPR form, referral status with progress bar, notification templates with live preview, customer import, campaign discounts, rate limit monitoring, usage thresholds, upgrade nudges, contextual tips (2/day), and 3-step onboarding flow. The plan finalizes the microservices architecture (AdminCore and AdminFeatures split), implements i18n for `en`, `es`, `fr`, `de`, `pt`, `ja`, validates with 10–15 merchants (3–5 Shopify Plus, 1 global/premium), and sets up the “LoyalNest Collective” Slack. It uses Vite + React (Polaris, Tailwind CSS, App Bridge), NestJS, PostgreSQL, Redis, Kafka, and Docker, with AI-driven development (Grok, GitHub Copilot, Cursor) and in-house QA, aligning with the 39.5-week TVP goal.

## Objectives
- **Develop Prototypes**: Build Vite + React prototypes for Merchant Dashboard, Customer Widget, Admin Module, checkout extensions, GDPR form, referral status, notification templates, rate limit monitoring, usage thresholds, and onboarding flow, deployed on VPS with Docker Compose.
- **Finalize Architecture**: Define microservices (Auth, Points, Referrals, RFM Analytics, Event Tracking, AdminCore, AdminFeatures, Campaign, Gamification) with REST/gRPC APIs, PostgreSQL schema, and Redis/Kafka integration.
- **Implement i18n**: Support `en`, `es`, `fr`, `de`, `pt`, `ja` with i18next, validated by native speakers.
- **Validate with Merchants**: Test prototypes with 10–15 merchants, targeting 80%+ RFM wizard satisfaction, 90%+ checkout extension clarity, and 90%+ i18n translation accuracy.
- **Ensure Compliance**: Incorporate GDPR/CCPA-compliant features (GDPR form, AES-256 encryption).
- **Set Up Community**: Establish “LoyalNest Collective” Slack for feedback.

## Timeline
**Total Duration**: Weeks 5–11 (7 weeks, August–September 2025)
- **Weeks 5–6 (Aug 3–16, 2025)**: Set up Vite + React and VPS environment, develop core components, initialize microservices, start i18n.
- **Weeks 7–8 (Aug 17–30, 2025)**: Complete prototype development, begin merchant feedback, validate i18n.
- **Weeks 9–11 (Aug 31–Sep 20, 2025)**: Refine prototypes, finalize feedback, architecture, and prepare for Phase 3.

## Tasks and Implementation Details

### 1. Prototype Development
- **Objective**: Build clickable prototypes for Must Have features, deployed on VPS with Docker Compose.
- **Tasks**:
  - **Setup**:
    - Initialize Vite + React project with Polaris, Tailwind CSS, App Bridge, and i18next.
    - Configure VPS (Ubuntu, Docker Compose) with Nginx for prototype hosting, using `dev.sh` for setup.
    - Use mock APIs with JSON fixtures (Faker for customers, orders, referrals).
  - **Prototypes**:
    - **Merchant Dashboard**:
      - `WelcomePage.tsx`: Onboarding checklist, contextual tips (2/day, e.g., “Add birthday bonus to boost referrals”).
      - `PointsPage.tsx`: Points configuration (10 points/$, signups: 200 points, reviews: 100 points, birthdays: 200 points).
      - `ReferralsPage.tsx`: SMS/email/WhatsApp referral setup (Klaviyo/Postscript, AWS SES fallback).
      - `AnalyticsPage.tsx`: RFM analytics with default segments, Chart.js scatter plot (Recency vs. Monetary, `US-MD20`).
      - `SettingsPage.tsx`: Store settings, billing ($29/month for 500 orders), rewards panel, checkout extensions, notification templates, rate limit monitoring, usage thresholds.
    - **Customer Widget**:
      - `Widget.tsx`: Points balance, redemption ($5/500 points, free shipping: 1000 points), referral popup, GDPR form.
      - `ReferralProgress.tsx`: Progress bar for referral status.
    - **Admin Module**:
      - `AdminPage.tsx`: AdminCore (merchant management, audit logs, GDPR requests), AdminFeatures (points adjustments, customer imports, notification templates, rate limits, Square sync).
      - `QueuesPage.tsx`: Rate limit queue monitoring (`/admin/rate-limits/queue`).
      - `RateLimitsPage.tsx`: Shopify API rate limit alerts (Slack/email at 80% limit).
    - **Additional Components**: GDPR form, notification templates with live preview (JSONB `email_templates.body`), checkout extensions, 3-step onboarding flow.
    - **On-Site Content**: SEO-friendly loyalty page, rewards panel, launcher button, points display, post-purchase/email capture popups, GDPR form, referral status (`US-CW8–CW10`).
  - **Standards**:
    - Use Polaris for UI consistency, Tailwind CSS for styling, ARIA labels for accessibility (WCAG 2.1 AA partial compliance, Lighthouse CI score 90+).
    - Implement components in Storybook for reusability.
    - Mock APIs:
      - `/points.v1/GetPointsBalance`: Points balance.
      - `/referrals.v1/CreateReferral`: Referral link generation.
      - `/analytics.v1/GetRFMSegments`: RFM segment data.
      - `/admin.v1/GetRateLimits`: Rate limit status.
  - **Testing**:
    - Unit Tests: Jest for React components, i18next fallbacks (80%+ coverage).
    - E2E Tests: Cypress for dashboard, widget, RFM UI, GDPR form, referral status, notification templates, checkout extensions, rate limits, RTL placeholders (`ar`, `he`).
    - Performance: k6 for 1,000 orders/hour.
    - Accessibility: Lighthouse CI (90+ score).
  - **AI Tools**: GitHub Copilot for React components and Jest tests, Cursor for Storybook, Grok for contextual tips and mock API responses.
- **Timeline**: Weeks 5–8.
- **Deliverables**: Prototypes for dashboard, widget, admin module, checkout extensions, GDPR form, referral status, notification templates, onboarding flow, deployed on VPS.

### 2. Microservices Architecture Finalization
- **Objective**: Finalize microservices with AdminCore and AdminFeatures split, including APIs, schema, and VPS infrastructure.
- **Tasks**:
  - **Microservices**:
    - **Auth**: `/v1/api/auth/login`, `/v1/api/auth/refresh`, `/v1/api/auth/roles` (Shopify OAuth, JWT, RBAC with Auth0).
    - **Points**: `/v1/api/points/earn`, `/v1/api/points/redeem`, `/v1/api/rewards`.
    - **Referrals**: `/v1/api/referrals/create`, `/v1/api/referrals/status` (SMS/email/WhatsApp, AWS SES fallback).
    - **RFM Analytics**: `/v1/api/rfm/segments`, gRPC (`/analytics.v1/RFMAnalyticsService/GetSegments`).
    - **Event Tracking**: `/v1/api/events` (PostHog).
    - **AdminCore**: `/admin/merchants`, `/admin/logs`, gRPC (`/admin.v1/GetMerchants`, `/admin.v1/GetAuditLogs`).
    - **AdminFeatures**: `/admin/points/adjust`, `/admin/rate-limits`, `/admin/customers/import`, gRPC (`/admin.v1/ImportCustomers`).
    - **Campaign**: `/api/campaigns/*` (RFM-based discounts).
    - **Gamification**: `/api/gamification/*` (Phase 6 placeholders).
  - **APIs**:
    - REST: `/v1/api/*` (OpenAPI/Swagger).
    - gRPC: `/analytics.v1/*`, `/admin.v1/*` (circuit breakers via `node-circuitbreaker`).
    - Webhooks: Shopify `orders/create`, `customers/data_request`, `customers/redact` (Redis idempotency: `webhook:{merchant_id}:{event_id}`).
  - **Database**:
    - PostgreSQL: `loyalnest_full_schema.sql` with tables (`customers`, `points_transactions`, `referrals`, `reward_redemptions`, `program_settings`, `email_templates`, `gdpr_requests`, `rfm_segment_counts`, `audit_logs`, `integrations`, `setup_tasks`, `merchant_settings`) using JSONB and range partitioning.
    - Redis Cluster/Streams: Cache points (`points:{customer_id}`), referrals (`referral:{referral_code}`), rate limits (`shopify_api_rate_limit:{merchant_id}`).
  - **Infrastructure**:
    - VPS (Ubuntu, Docker Compose) with Nginx, `dev.sh` for setup, and mock data seeding (Faker).
    - Bull queues for rate limits and customer imports.
    - Loki (logging), Prometheus (metrics), AWS SNS (alerts).
    - Backblaze B2 backups (90-day retention, RTO: 4 hours, RPO: 1 hour) with `restore.sh`.
  - **Scalability**: k6 tests for 1,000 orders/hour.
  - **Security**: AES-256 encryption (pgcrypto), GDPR webhook placeholders, OWASP ZAP (ECL: 256).
  - **AI Tools**: Grok for API documentation and schema validation, Copilot for NestJS and k6 scripts.
- **Timeline**: Weeks 5–8.
- **Deliverables**: Architecture diagram (Draw.io), `loyalnest_full_schema.sql`, API specs (OpenAPI/Swagger, gRPC), k6 test results.

### 3. i18n Implementation
- **Objective**: Integrate i18next for `en`, `es`, `fr`, `de`, `pt`, `ja` with 90%+ translation accuracy.
- **Tasks**:
  - Set up i18next with translation files (`en.json`, `es.json`, `fr.json`, `de.json`, `pt.json`, `ja.json`) for all prototype components.
  - Test fallbacks and RTL placeholders (`ar`, `he`) with Jest/Cypress.
  - Validate translations with 2–3 native speakers per language via “LoyalNest Collective” Slack.
  - Ensure GDPR/CCPA-compliant privacy policies in all languages.
  - **AI Tools**: Grok for translation templates and phrasing validation.
- **Timeline**: Weeks 6–9.
- **Deliverables**: i18next integration, Jest/Cypress test reports, native speaker validation report.

### 4. Merchant Feedback and Validation
- **Objective**: Validate prototypes with 10–15 merchants, targeting 80%+ RFM wizard satisfaction, 90%+ checkout extension clarity, 90%+ i18n translation accuracy.
- **Tasks**:
  - Recruit merchants via Shopify Partners and “LoyalNest Collective” Slack.
  - Conduct Zoom interviews and Google Forms surveys for feedback on RFM wizard, referrals, checkout extensions, GDPR form, notification templates, customer import, rate limit monitoring, usage thresholds, onboarding flow, pricing, and i18n.
  - Track usage with PostHog (`prototype_viewed`, `rfm_wizard_completed`, `referral_popup_viewed`).
  - Iterate prototypes based on feedback (e.g., simplify RFM wizard).
  - **AI Tools**: Grok to summarize feedback and suggest UX improvements.
- **Timeline**: Weeks 7–10.
- **Deliverables**: Merchant feedback report, updated prototypes.

### 5. Community Setup
- **Objective**: Establish “LoyalNest Collective” Slack for merchant engagement.
- **Tasks**:
  - Set up Slack workspace with channels for feedback, support, and feature voting.
  - Invite beta testers and Shopify Partners.
  - Share prototype access (VPS URL) and collect feedback via Slack polls.
  - **AI Tools**: Grok for community guidelines and tutorial drafts.
- **Timeline**: Weeks 8–9.
- **Deliverables**: Slack workspace, engagement plan.

## Architecture
- **Stack**: Vite + React (Polaris, Tailwind CSS, App Bridge), NestJS, PostgreSQL (JSONB, range partitioning), Redis Cluster/Streams, Kafka, Bull queues, Loki, Prometheus, Docker Compose.
- **Microservices**: Auth, Points, Referrals, RFM Analytics, Event Tracking, AdminCore, AdminFeatures, Campaign, Gamification.
- **APIs**: REST (`/v1/api/*`), gRPC (`/analytics.v1/*`, `/admin.v1/*`), Shopify webhooks.
- **Database**: PostgreSQL (`loyalnest_full_schema.sql`), Redis for caching/queues.
- **Security**: AES-256 encryption, GDPR webhooks, OWASP ZAP.
- **Deployment**: VPS (Ubuntu, Docker Compose, Nginx), `dev.sh`, `restore.sh`, Backblaze B2 backups.
- **Monitoring**: Loki, Prometheus, AWS SNS.

## Development Process
- **AI-Driven Development**:
  - GitHub Copilot: React components, Jest tests, NestJS APIs, k6 scripts.
  - Cursor: Storybook components, Cypress tests.
  - Grok: API docs, translation templates, contextual tips, feedback summaries.
- **QA**:
  - Jest (80%+ coverage, i18next fallbacks).
  - Cypress (E2E, RTL placeholders).
  - k6 (1,000 orders/hour).
  - Lighthouse CI (90+ score).
- **CI/CD**: GitHub Actions for build and deployment to VPS.

## Risks and Mitigation
- **Risk**: VPS setup delays.
  - **Mitigation**: Use `dev.sh` for streamlined Docker setup, test locally first.
- **Risk**: i18n inaccuracies.
  - **Mitigation**: Validate with native speakers, use Grok for translations, test with Jest/Cypress.
- **Risk**: Scalability issues.
  - **Mitigation**: Optimize Redis and Bull queues, validate with k6.
- **Risk**: GDPR/CCPA gaps.
  - **Mitigation**: Include GDPR form, AES-256 encryption, OWASP ZAP.
- **Risk**: Team bandwidth.
  - **Mitigation**: Use AI tools, prioritize reusable Storybook components.

## Milestones
- **Week 6 (Aug 16, 2025)**: VPS setup, core prototype components, architecture initialized.
- **Week 8 (Aug 30, 2025)**: Complete prototypes, initial feedback, i18n validation.
- **Week 11 (Sep 20, 2025)**: Finalized prototypes, feedback report, architecture ready for Phase 3.

## Budget
- **Development**: $10,000 (prototypes, VPS setup, Storybook, k6).
- **Merchant Feedback**: $3,000 (Zoom, Google Forms, Slack).
- **i18n**: $2,500 (translations, validation).
- **Total**: $15,500.

## Next Steps
- Set up Vite + React project and VPS with Docker Compose.
- Develop core prototype components (`WelcomePage.tsx`, etc.).
- Recruit merchants for feedback via Slack.
- Validate i18n with native speakers.
- Finalize architecture for Phase 3.