# LoyalNest Shopify App Roadmap

## Overview
The LoyalNest Shopify app delivers a competitive loyalty and rewards program for small (100–1,000 customers), medium (1,000–10,000 customers), and Shopify Plus merchants (10,000+ customers), scaling to global/premium merchants (50,000+ customers) in Phase 6. The roadmap outlines a production-grade TVP in 39.5 weeks (7–8 months), followed by scaling over 12–14 months, aligning with `features.md` and `user_stories.md` (artifact_id: `4fdff392-16f3-4052-8fe0-0df2a18f87c9`). The app uses a microservices architecture (NestJS/TypeORM, Rust/Wasm, PostgreSQL with JSONB and range partitioning, Redis Cluster/Streams, Kafka, Bull queues, Loki + Grafana, Prometheus, Sentry), deployed on a VPS with Docker (Kubernetes for Phase 6). Security includes Shopify OAuth, RBAC with MFA (Auth0), AES-256 encryption (pgcrypto), GDPR/CCPA compliance (90-day Backblaze B2 backups), and OWASP ZAP (ECL: 256). The app supports Black Friday surges (10,000 orders/hour), Shopify Plus (40 req/s), and multilingual UI (`en`, `es`, `fr`, `ar`, `he` with RTL) via i18next, with WCAG 2.1 AA compliance (Lighthouse CI 90+). Development leverages AI tools (Grok, GitHub Copilot, Cursor), in-house UI/UX, and QA, with community-led growth via “LoyalNest Collective” Slack.

## Timeline and Milestones
Total timeline: **39.5 weeks** for TVP (7–8 months, Phases 1–5), **12–14 months** for full implementation (Phase 6 ongoing). Budget: **$91,912.50**.

### Phase 1: Research and Planning (Weeks 1–4, July–August 2025)
- **Objective**: Define USPs, validate pricing and Must Have features, establish microservices architecture.
- **Milestones**:
  - Conduct competitive analysis of Smile.io, Yotpo, LoyaltyLion, BON Loyalty, Rivo, Gameball.
  - Validate Must Have features: points (purchases: 10 points/$, signups: 200 points, reviews: 100 points, birthdays: 200 points), SMS/email referrals, basic RFM analytics, Shopify POS with offline mode, checkout extensions, GDPR request form, referral status with progress bar, notification templates with live preview, customer import, campaign discounts, rate limit monitoring, usage thresholds, upgrade nudges, contextual tips.
  - Run pricing surveys (Typeform/Google Forms) with 5–10 merchants (2–3 Shopify Plus) for Free (300 orders, basic RFM, 50 SMS referrals), $29/month (500 orders, full RFM, checkout extensions, campaign discounts), $99/month (1,500 orders, multi-store), Enterprise (custom) plans.
  - Design microservices (auth, points, referrals, rfm_analytics, event_tracking, admin) with NestJS, Rust/Wasm, PostgreSQL (JSONB, range partitioning), Redis Cluster/Streams, Kafka, Bull queues, Loki + Grafana, Prometheus, Sentry.
  - Engage Shopify Partners for feedback from 5–10 merchants (2–3 Shopify Plus).
- **Deliverables**:
  - Competitive analysis report (gaps: SMS referrals, RFM, POS, checkout extensions, contextual tips).
  - Feature list: Must Have (Phase 3), Should Have (Phases 4–5: VIP tiers, exit-intent popups, behavioral segmentation, multi-store sharing, Shopify Flow templates, Theme App Extensions), Could Have (Phase 6 CURSIVE

System: : gamification, multilingual widget, multi-currency discounts, non-Shopify POS, advanced analytics, developer toolkit, AI reward suggestions, custom webhooks, OpenTelemetry, WCAG 2.1 AA, dark mode, zero-downtime deployments).
  - Technical architecture diagram (Nx monorepo, Docker, VPS, gRPC).
  - Pricing model, USP documentation, pricing survey report.
- **Dependencies**: Shopify Partners feedback precedes architecture finalization.
- **Team**: 1–2 developers (AI-assisted: Grok, Copilot, Cursor), in-house UI/UX, QA.

### Phase 2: Design and Prototyping (Weeks 5–11, August–September 2025)
- **Objective**: Create Polaris-compliant UI prototypes, finalize microservices, validate pricing and UX.
- **Milestones**:
  - Design wireframes/prototypes (in-house, AI-assisted) for:
    - Merchant dashboard: Points, referrals, RFM analytics, checkout extension config, notification templates, rate limit monitoring, usage thresholds, upgrade nudges, contextual tips (e.g., “Add birthday bonus to boost referrals”).
    - Customer widget: Points balance, redemption, SMS/email referral popup, GDPR request form, referral status with progress bar (`US-CW7`, `US-CW16`).
    - Admin module: Merchant management, RFM segments, logs, rate limits, multi-user roles (RBAC), integration kill switch (`US-AM14`).
  - Develop no-code RFM setup wizard and segment preview (Chart.js, `US-MD20`, `US-MD21`).
  - Plan on-site content: SEO-friendly loyalty page, rewards panel, launcher button, points display, popups, GDPR form, referral status (`US-CW8–CW10`).
  - Validate prototypes and pricing (mock checkout/survey) with 5–10 merchants (2–3 Shopify Plus) via Shopify Partners.
  - Finalize microservices with REST APIs (`/v1/api/*`), gRPC, and `loyalnest_full_schema.sql` (PostgreSQL with JSONB, range partitioning).
  - Add i18n hooks (i18next) for English, with `es`, `fr`, `ar`, `he` (RTL) planned for Phase 6.
- **Deliverables**:
  - Figma wireframes/mockups for dashboard, widget, admin module, checkout extensions, GDPR form, referral status, notification templates, rate limit monitoring, usage thresholds, upgrade nudges, contextual tips.
  - Clickable prototype with Must Have features and pricing mockup.
  - Microservices architecture diagram (NestJS, Rust, PostgreSQL, Redis Cluster/Streams, Kafka, Bull queues, Loki, Prometheus).
  - Merchant feedback report on RFM, referrals, POS, checkout extensions, GDPR, pricing, contextual tips.
- **Dependencies**: Pricing validation requires merchant feedback; schema precedes development.
- **Team**: 1–2 developers, in-house UI/UX, QA.

### Phase 3: Development (Weeks 12–30, October 2025–February 2026)
- **Objective**: Build production-grade TVP with Must Have features, admin module, Shopify Plus compatibility (40 req/s), and UX enhancements for 5,000+ customers (10,000+ for Plus).
- **Milestones**:
  - Develop microservices (NestJS):
    - **Auth Service**: Shopify OAuth, JWT, RBAC with MFA (Auth0, `US-AM4–AM6`, `/v1/api/auth`).
    - **Points Service**: Earning (purchases: 10 points/$, signups: 200 points, reviews: 100 points, birthdays: 200 points), redemption (discounts: $5/500 points, free shipping: 1000 points, free products: 1500 points), Shopify POS with offline mode, checkout extensions, campaign discounts (`US-CW1–CW5`, `/v1/api/points`, `/v1/api/rewards`).
    - **Referrals Service**: SMS/email/WhatsApp referrals (Twilio, `US-CW7`), referral status with progress bar (`US-CW16`), spoof detection (heuristic + xAI API, https://x.ai/api), merchant referrals (`US-AM9`, `/v1/api/referral`).
    - **RFM Analytics Service**: Basic RFM (Recency ≤7 to >90 days, Frequency 1 to >10, Monetary <0.5x to >5x AOV), segment preview, A/B testing for nudges (`US-MD4–MD6`, `US-MD21`, `/v1/api/rfm/segments`).
    - **Event Tracking Service**: PostHog integration (`points_earned`, `referral_completed`, `rfm_updated`, `/v1/api/events`).
    - **Admin Service**: Merchant management, logs, GDPR, rate limits, customer import, notification templates, integration kill switch, action replay/undo (`US-AM9–AM13`, `US-AM15`, `/admin/integrations`).
  - Implement Rust/Wasm Shopify Functions for discounts, checkout extensions, RFM updates.
  - Build frontend (Vite + React, Polaris, App Bridge): Dashboard (`WelcomePage.tsx`, `SettingsPage.tsx`), widget (`Widget.tsx`, `ReferralProgress.tsx`), admin module, with i18n hooks, contextual tips (rule-based, e.g., “Increase referrals by 20% with birthday bonus”), usage thresholds, upgrade nudges.
  - Integrate Shopify (APIs, POS, Checkout UI Extensions), Klaviyo/Postscript (referrals, notifications), Yotpo/Judge.me (reviews), Klaviyo/Mailchimp (email flows, `US-BI1–BI3`).
  - Set up PostgreSQL (JSONB, range partitioning: `merchants`, `points_transactions`), Redis Cluster/Streams (`points:{customer_id}`, `referral:{referral_code}`, `rfm:{customer_id}`), Kafka, Bull queues.
  - Implement security: AES-256 encryption for PII (`customers.email`, `rfm_score`, `wallet_passes`, `US-AM1–AM3`, `US-CW17`), OWASP ZAP (ECL: 256), webhook idempotency (Redis: `webhook:{merchant_id}:{event_id}`).
  - Develop `dev.sh` for local Docker setup, mock data seeding (Finder), RFM simulation (`US-MD22`).
  - Build test data factory (`test/factories/*.ts`, `fixtures.rs`) for merchants, customers, referrals, RFM scores.
  - Run Jest (unit/integration), Cypress (E2E), k6 (10,000 orders/hour), Chaos Mesh (resilience) for 80%+ coverage.
  - Set up monitoring: Prometheus/Grafana (latency <1s, error rate <1%), Sentry, Loki, AWS SNS alerts for anomalies (>100 points adjustments/hour).
  - Implement disaster recovery: `pg_dump`, Redis snapshotting, Backblaze B2 backups (90-day retention).
  - Run Lighthouse CI for accessibility (ARIA, keyboard nav, partial WCAG 2.1 AA) and performance (LCP, FID, CLS).
- **Deliverables**:
  - TVP with Must Have features: points, SMS/email/WhatsApp referrals, basic RFM, Shopify POS, checkout extensions, GDPR form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring, usage thresholds, upgrade nudges, contextual tips, integration kill switch.
  - Admin module with RBAC, logs, rate limits, customer import, notification templates, kill switch, action replay/undo (`US-AM15`).
  - Integrations: Shopify, Klaviyo/Postscript, Yotpo, Klaviyo/Mailchimp.
  - Test reports (Jest, Cypress, k6, Chaos Mesh) and bug fixes.
  - VPS deployment with Docker Compose, Nginx, Loki, Prometheus, `dev.sh`, backups.
- **Dependencies**:
  - Shopify OAuth and webhooks precede integrations.
  - Points/referrals require `customers`, `points_transactions`, `referral_links` tables.
  - RFM depends on points/referrals completion.
- **Team**: 1–2 developers, in-house UI/UX, QA.

### Phase 4: Beta Testing and Refinement (Weeks 31–36, March–April 2026)
- **Objective**: Validate TVP with merchants, refine UX, implement Should Have features, establish “LoyalNest Collective” for community-led growth.
- **Milestones**:
  - Recruit 10–15 merchants (2–3 Shopify Plus) via Shopify Reddit/Discord, Partners program, “LoyalNest Collective” Slack (free 300-order plan).
  - Test Must Have features: 80%+ RFM wizard completion, 7%+ SMS referral conversion, 3%+ email referral conversion, 85%+ checkout extension adoption, 20%+ redemption rate, 50%+ GDPR form usage, 60%+ referral status engagement, 80%+ notification template usage, 90%+ customer import success rate, 10%+ campaign discount redemption.
  - Implement Should Have features: VIP tiers with progress bars (`US-CW16`), exit-intent popups, behavioral segmentation, multi-store point sharing (`US-CW6`), Shopify Flow templates (welcome series, win-back, `US-MD19`).
  - Add win-back workflows and RFM-based churn triggers (Shopify Flow/Klaviyo, `US-AM16`).
  - Collect feedback via “LoyalNest Collective” on RFM, referrals, POS, checkout extensions, GDPR, notification templates, customer import, campaign discounts, rate limits, upgrade funnel, pricing, contextual tips.
  - Fix bugs and enhance RFM analytics (10%+ repeat purchase uplift, `US-MD20` for benchmarks).
  - Set up public changelog (Headway) and feature voting (Canny/Trello) in “LoyalNest Collective.”
  - Test disaster recovery (Backblaze B2 restore).
  - Host one AMA in “LoyalNest Collective” with $50 referral credits for active members.
- **Deliverables**:
  - Beta test report (RFM usability, referral rates, POS performance, checkout extension adoption, GDPR, referral status, notification templates, customer import, campaign discounts, rate limits, upgrade funnel, pricing, contextual tips).
  - Refined TVP with bug fixes, RFM enhancements, win-back workflows, churn triggers.
  - “LoyalNest Collective” Slack with changelog, feature voting, AMA.
  - Documentation, YouTube tutorials, support portal, Shopify Plus onboarding guide.
- **Dependencies**:
  - Shopify Flow (`US-MD19`) requires Plus API access (40 req/s).
  - RFM enhancements (`US-MD20`, `US-AM16`) depend on Phase 3 analytics.
- **Team**: 1–2 developers, in-house UI/UX, QA.

### Phase 5: Launch and Marketing (Weeks 37–43, April–May 2026)
- **Objective**: Launch on Shopify App Store, attract 100+ merchants (5–10 Shopify Plus) in 3 months, deploy remaining Should Have features.
- **Milestones**:
  - Submit to Shopify App Store with Polaris UI, App Bridge, GDPR/CCPA compliance, optimized listing (30-second demo videos, keywords: “loyalty program,” “RFM analytics,” “SMS referrals”).
  - Launch marketing website with pricing, mini-case studies (e.g., “10% referral conversion, 20% checkout extension adoption”), public changelog.
  - Promote via Shopify Reddit/Discord, “LoyalNest Collective” (monthly AMAs), social media, Shopify Plus agencies (Eastside Co, Pixel Union).
  - Implement merchant referral program ($50 credit, `US-AM9`) and A/B test App Store listing (SensorTower, `US-MD21`).
  - Add Should Have features: Theme App Extensions (`US-CW15`), Shopify Flow templates (`US-MD19`), multi-store point sharing (`US-CW6`), Klaviyo/Mailchimp integration, discount banners.
  - Monitor via admin module, Loki + Grafana, Prometheus, Sentry, PostHog (`plan_limit_warning`, `campaign_discount_redeemed`, `rfm_updated`).
  - Offer 24/7 email support, “LoyalNest Collective” Slack, live chat for paid plans, white-glove onboarding for Plus.
- **Deliverables**:
  - Approved Shopify App Store listing.
  - Marketing website, promotional materials (case studies, videos), public changelog.
  - Support system with onboarding guides, “LoyalNest Collective,” VPS maintenance docs.
  - Theme App Extensions, Shopify Flow templates, multi-store sharing.
- **Dependencies**: Shopify Flow and Theme App Extensions require Plus API access.
- **Team**: 1–2 developers, in-house UI/UX, QA, marketing support.

### Phase 6: Post-Launch and Scaling (Weeks 44+, June 2026–Ongoing)
- **Objective**: Grow to 100+ merchants (5–10 Shopify Plus) in 3 months, achieve Built for Shopify certification, implement Could Have features for 50,000+ customers.
- **Milestones**:
  - Partner with Shopify Plus agencies, offer white-label API (`/v1/api/whitelabel`) for Enterprise plans.
  - Publish case studies (20% repeat purchase increase, 50% multi-store sharing adoption, 15% campaign discount redemption).
  - Implement Could Have features: gamification (badges, leaderboards, streaks, `US-CW11`), multilingual widget (`es`, `fr`, `ar`, `he` with RTL, `US-MD2`), multi-currency discounts (`US-CW6`), non-Shopify POS (Square, Lightspeed), advanced analytics (25+ reports, `US-MD11`, `US-MD22`), developer toolkit, AI reward suggestions (xAI API, `US-AM16`), custom webhooks (`/v1/api/webhooks/custom`), OpenTelemetry, WCAG 2.1 AA, dark mode, zero-downtime deployments (Klotho/Kubernetes).
  - Add mobile wallet export (Apple Wallet/Google Pay, `US-CW17`, AES-256 encrypted `wallet_exports.pass_data`).
  - Enhance admin module with multi-tenant support (`US-AM14`, `merchants.multi_tenant_group_id`) and action replay/undo (`US-AM15`).
  - Scale to Kubernetes for 5,000+ merchants (50,000+ customers), with Redis Streams, PostgreSQL sharding.
  - Apply for Built for Shopify certification (4.5+ star rating).
  - Maintain quarterly updates, Shopify API compliance, daily Backblaze B2 backups.
  - Engage “LoyalNest Collective” for feedback, monthly AMAs, feature voting.
- **Deliverables**:
  - Monthly performance reports (merchant growth, RFM engagement, referral rates, campaign discount redemption, checkout extension adoption).
  - Feature updates (Could Have features, mobile wallet, multi-tenant support).
  - Built for Shopify certification application.
  - Kubernetes deployment, VPS maintenance guide.
- **Dependencies**:
  - xAI API (`US-AM16`, `US-MD22`, `US-CW7`) requires API key (https://x.ai/api).
  - Mobile wallet (`US-CW17`) needs vendor coordination.
  - Multi-tenant support (`US-AM14`) depends on RBAC enhancements.
- **Team**: 1–2 developers, in-house UI/UX, QA, DevOps for Kubernetes.

## Key Features by Phase
- **Phase 3 (TVP)**: Points, SMS/email/WhatsApp referrals, basic RFM analytics, Shopify POS with offline mode, checkout extensions, GDPR request form, referral status with progress bar, notification templates, customer import, campaign discounts, rate limit monitoring, usage thresholds, upgrade nudges, contextual tips, integration kill switch, action replay/undo (`US-CW7`, `US-MD21`, `US-AM15`).
- **Phase 4**: VIP tiers with progress bars, exit-intent popups, behavioral segmentation, multi-store point sharing, win-back workflows, RFM-based churn triggers, Shopify Flow templates (`US-CW16`, `US-MD19`, `US-AM16`).
- **Phase 5**: Theme App Extensions, Shopify Flow templates, multi-store point sharing, Klaviyo/Mailchimp integration, discount banners (`US-CW15`, `US-MD19`, `US-CW6`).
- **Phase 6**: Gamification, multilingual widget, multi-currency discounts, non-Shopify POS, advanced analytics, developer toolkit, AI reward suggestions, custom webhooks, OpenTelemetry, WCAG 2.1 AA, dark mode, zero-downtime deployments, mobile wallet export, multi-tenant support (`US-CW11`, `US-MD2`, `US-MD11`, `US-MD22`, `US-AM16`, `US-CW17`, `US-AM14`).

## Success Metrics
- **Phase 3–4 (TVP)**: 90%+ merchant satisfaction, 80%+ RFM wizard completion, 7%+ SMS referral conversion, 3%+ email referral conversion, 85%+ checkout extension adoption, 20%+ redemption rate, 50%+ GDPR form usage, 60%+ referral status engagement, 80%+ notification template usage, 90%+ customer import success rate, 10%+ campaign discount redemption, 10%+ RFM campaign repeat purchase uplift.
- **Phase 5 (Launch)**: 100+ merchants (5–10 Shopify Plus) in 3 months, 4.5+ star rating in 6 months.
- **Phase 6 (Post-Launch)**: 20% repeat purchase increase, 10%+ RFM tier engagement, 50%+ multi-store sharing adoption, 15%+ campaign discount redemption, 20%+ mobile wallet adoption, Built for Shopify certification in 12 months.

## Budget Allocation
- **Development**: $74,750 (TVP, microservices, AI tools, UI/UX, QA, backups, community, i18n, contextual tips, kill switch).
- **Marketing**: $3,000 (website, Shopify community ads, social media, “LoyalNest Collective” AMAs).
- **Support Infrastructure**: $4,000 (VPS, PostHog, Loki, Prometheus, Backblaze, Headway/Canny).
- **Contingency (15%)**: $11,362.50.
- **Total**: $91,912.50 (scalable to $150K for Phase 6 Kubernetes).

## Risks and Mitigation
- **Shopify API Changes/Rate Limits**: Pin API versions (2025-01), monitor changelog RSS, use circuit breakers, exponential backoff (3 retries, 500ms delay), Redis caching, AWS SNS alerts.
- **xAI API Delays (`US-AM16`, `US-MD22`, `US-CW7`)**: Fallback to heuristic models, early API key setup (https://x.ai/api).
- **High Competition**: Highlight USPs (RFM, SMS/WhatsApp referrals, checkout extensions, Shopify Flow, contextual tips, $29/month pricing), merchant referral program.
- **Slow Adoption**: Offer free plan, 14-day trial, “LoyalNest Collective,” Reddit/Discord engagement, usage thresholds, upgrade nudges, win-back workflows.
- **Onboarding Complexity**: Provide RFM wizard, gamified onboarding, Shopify Flow templates, Theme App Extensions, Plus onboarding guide, white-glove support, contextual tips.
- **Scalability (10,000 orders/hour)**: Use microservices, Redis Cluster/Streams, PostgreSQL partitioning, Rust/Wasm, Kafka, Bull queues, Chaos Mesh, Kubernetes (Phase 6).
- **Solo Developer Bandwidth**: Leverage AI tools (Grok, Copilot, Cursor), Nx monorepo, `dev.sh`, test data factory, CI/CD with change detection, Slack bots, Headway.
- **GDPR/CCPA Compliance**: Anonymize data (`rfm_benchmarks.anonymized_data`, `US-MD20`), AES-256 encryption, 90-day retention, OWASP ZAP.