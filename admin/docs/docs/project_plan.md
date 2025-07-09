# Updated Project Plan: LoyalNest App for Shopify

## Objective
Develop a Shopify app delivering a customizable, user-friendly loyalty and rewards program to boost customer retention, repeat purchases, and brand loyalty, competing with Smile.io, Yotpo, and LoyaltyLion. Key differentiators include RFM segmentation in all plans, affordable pricing ($29/month for 500 orders), SMS-driven referrals via Klaviyo/Postscript, lightweight gamification, multilingual support, GDPR/CCPA compliance, and broad POS support. Deliver a production-grade TVP in 7–8 months, focusing on Must Have features (points, SMS/email referrals, basic RFM analytics, Shopify POS integration, checkout extensions, GDPR request form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring), with Should Have and Could Have features phased in later, using AI-driven development for efficiency and addressing Shopify Plus enterprise needs. Transition the monorepo to a microservices architecture with Docker to enhance modularity, scalability, and independent deployments.

## Phase 1: Research and Planning (4 Weeks)
### Goals
- Understand Shopify’s app ecosystem and competitors’ gaps.
- Define USPs, prioritizing Must Have features for TVP, including Shopify Plus requirements.
- Establish technical and business requirements for a scalable microservices-based monorepo.

### Tasks
- **Market Research**:
  - Analyze competitors (Smile.io, Yotpo, LoyaltyLion, BON Loyalty, Rivo, Gameball) for features, pricing, and reviews.
  - Target small (100–1,000 customers, AOV $20–$50), medium-sized (1,000–10,000 customers, AOV $50–$200), and Shopify Plus merchants (10,000+ customers, multi-store setups).
  - Identify gaps: SMS referrals (Smile.io/Yotpo weakness), affordable RFM analytics (BON/Gameball limitation), non-Shopify POS (Rivo/Gameball gap), lightweight gamification (Smile.io/BON gap), multilingual support (Smile.io/Rivo limitation), checkout extensions (LoyaltyLion strength).
  - Validate demand for Must Have features: points (purchases, signups, reviews, birthdays), SMS/email referrals, basic RFM analytics, Shopify POS, checkout extensions, automated loyalty email flows, data import from Smile.io/LoyaltyLion, GDPR request form, referral status display, notification templates, campaign discounts, rate limit monitoring.
- **Technical Requirements**:
  - Restructure monorepo into microservices (auth, points, referrals, analytics, admin) within a single repository, using NestJS (TypeScript) for APIs and Rust/Wasm for Shopify Functions.
  - Use Shopify’s Polaris and App Bridge for UI consistency in merchant dashboard, customer widget, and admin module.
  - Ensure Shopify and Shopify Plus compatibility (e.g., higher API rate limits, checkout extensions); defer BigCommerce/Wix/WooCommerce to Phase 6.
  - Adopt API-first microservices architecture:
    - **Auth Service**: Handles Shopify OAuth, JWT, RBAC for admin module.
    - **Points Service**: Manages points earning/redemption, Shopify POS integration, checkout extensions, campaign discounts.
    - **Referrals Service**: Handles SMS/email referrals via Klaviyo/Postscript, referral tracking, referral status display.
    - **Analytics Service**: Provides basic RFM analytics, RFM segment previews, PostHog event tracking.
    - **Admin Service**: Manages merchant accounts, logs, RBAC, GDPR retention tracking, rate limit monitoring, notification templates.
  - Implement API versioning (/v1/api/*) for backward compatibility, using gRPC for inter-service communication (e.g., AnalyticsService, AdminService).
  - Use Rust/Wasm for Shopify Functions (discounts, checkout extensions, basic RFM score updates, campaign discounts) for performance.
  - Consolidate database to PostgreSQL with JSONB for RFM/tier configs (e.g., program_settings.rfm_thresholds, vip_tiers.rfm_criteria, email_templates.body).
  - Add Redis for caching points, referrals, RFM scores, webhook idempotency keys, and rate limits to support 5,000+ customers (50,000+ for Plus).
  - Apply loyalnest_full_schema.sql with indexes on customers(email, merchant_id, rfm_score), points_transactions(customer_id), referrals(merchant_id, referral_link_id), vip_tiers(merchant_id), reward_redemptions(campaign_id), gdpr_requests(retention_expires_at).
  - Deploy on a VPS (Ubuntu with Docker) using Docker Compose for microservices and GitHub Actions for CI/CD with change detection for independent service deployments.
  - Leverage AI (GitHub Copilot, Cursor) for NestJS APIs, Rust Functions, React components, Jest/Cypress tests, and PostgreSQL index recommendations, with human review.
- **USPs**:
  - Free plan: 300 orders/month, basic RFM analytics (churn risk segments), undercutting Smile.io ($49/month).
  - SMS-driven referrals via Klaviyo/Postscript post-purchase popups, surpassing Smile.io/Yotpo’s email-only referrals.
  - Affordable $29/month plan with full RFM configuration, campaign discounts, checkout extensions, and rate limit monitoring, competing with LoyaltyLion’s $399/month.
- **Must Have Features for TVP**: Points (purchases, signups, reviews, birthdays), SMS/email referrals, basic RFM analytics (static thresholds), Shopify POS (points earning), checkout extensions (points redemption), automated loyalty email flows, data import from Smile.io/LoyaltyLion, GDPR request form in widget, referral status display, notification templates, campaign discounts with RFM conditions, rate limit monitoring.
- **Should Have Features (Phase 3–4)**: VIP tiers (spending-based), advanced RFM configuration, exit-intent popups, Klaviyo/Mailchimp integration, multi-store point sharing, behavioral segmentation.
- **Could Have Features (Phase 6)**: Gamification (badges, leaderboards), multilingual widget (10+ languages), multi-currency discounts, non-Shopify POS (Square, Lightspeed), advanced analytics (25+ reports), developer toolkit for Shopify metafields.
- **Team Formation**:
  - Solo developer handling NestJS, React, Rust; limited experience mitigated by AI tools and clear documentation.
  - Outsource UI/UX design (Polaris-compliant mockups, $2,500) and QA (Cypress testing, $2,500) to Upwork freelancers.
  - Use AI tools (GitHub Copilot, Cursor, Grok) for code generation, testing, and VPS setup guides.
  - Engage Shopify Partners program for feedback from 5–10 merchants (including 2–3 Shopify Plus) on TVP features.
- **Budget and Timeline**:
  - Development: $70,750 (TVP, AI tools, freelancers for UI/QA, Shopify Plus features, microservices setup).
  - Marketing: $3,000 (website, Shopify community ads).
  - Support Infrastructure: $4,000 (VPS hosting, PostHog, support tools).
  - Contingency (15%): $11,662.50.
  - Total: $89,412.50.
  - Timeline: 4 weeks.
- **Enhancements & Best Practices**:
  - Document API contracts using OpenAPI/Swagger for each microservice, including versioning (/v1/api/*).
  - Plan field-level encryption for PII (e.g., customers.email, rfm_score) using pgcrypto.
  - Implement GDPR webhook handlers for customers/data_request and customers/redact with retention_expires_at tracking in gdpr_requests.
  - Set up CI pipeline (GitHub Actions) with change detection for microservices (e.g., build only changed services: auth, points).
  - Use Kubernetes Service Discovery for inter-service communication in future scaling.
- **Additional Tasks**:
  - Develop notification system with Klaviyo/Postscript integration, multilingual support for referral notifications (SMS/email, JSONB email_templates.body).
  - Design GDPR request form for customer widget (request data, redact options, tied to gdpr_requests).
  - Plan customer referral status display in widget (referral_link_id, status: pending/completed/expired).
  - Add referral_link_id to referrals table for unique tracking.
  - Define GDPR retention tracking with retention_expires_at (90 days) in gdpr_requests table.
- **Deliverables**:
  - Competitive analysis report highlighting gaps in SMS referrals, RFM analytics, POS support, checkout extensions, GDPR compliance.
  - Feature list prioritizing Must Have for TVP, with Should Have and Could Have planned for Phases 3–6.
  - Pricing model: Free (300 orders, basic RFM), $29/month (500 orders, full RFM, checkout extensions, campaign discounts), $99/month (1,500 orders, multi-store), Enterprise (custom).
  - Technical architecture diagram (microservices: NestJS, Rust, PostgreSQL, Redis, VPS).
  - Solo developer plan with freelance outsourcing for UI/QA.

## Phase 2: Design and Prototyping (5 Weeks)
### Goals
- Create intuitive, Polaris-compliant UI for merchants and customers, focusing on Must Have features, including checkout extensions, GDPR request form, referral status, RFM segment preview, notification templates, and rate limit monitoring.
- Design scalable microservices architecture for 5,000+ merchants and 100,000+ users (50,000+ customers for Plus).

### Tasks
- **UI/UX Design**:
  - Develop wireframes/prototypes using Polaris and App Bridge for:
    - Merchant dashboard: Points, referrals (SMS/email), basic RFM analytics, checkout extension config, notification templates, rate limit monitoring, settings.
    - Customer widget: Points balance, redemption, SMS/email referral popup, GDPR request form, referral status display.
    - Admin module: Merchant management, RFM segment views, logs, rate limits, multi-user roles (Shopify Plus).
  - Design no-code RFM setup wizard with static thresholds (e.g., Recency 5: <30 days, Frequency 5: 5+ orders, Monetary 5: $250+ for AOV $50) and RFM segment preview.
  - Include Must Have on-site content: SEO-friendly loyalty page, rewards panel, launcher button, points display on product/checkout pages, post-purchase/email capture popups, GDPR request form, referral status.
  - Design notification template configuration UI for points earned, referrals, GDPR requests (multilingual, JSONB).
  - Plan Should Have UI elements (deferred to Phase 3): VIP tier display, exit-intent popups, discount banners.
  - Outsource Polaris-compliant mockups to freelancer ($2,500).
- **Technical Architecture**:
  - Tech stack: Vite + React with Polaris, Tailwind CSS, App Bridge; NestJS for microservices (auth, points, referrals, analytics, admin); Rust/Wasm for Shopify Functions; PostgreSQL (JSONB); Redis for caching.
  - Microservices:
    - **Auth Service**: /v1/api/auth (Shopify OAuth, JWT, RBAC).
    - **Points Service**: /v1/api/points (earn/redeem, POS, checkout extensions, campaign discounts).
    - **Referrals Service**: /v1/api/referral (SMS/email via Klaviyo/Postscript, referral status).
    - **Analytics Service**: /v1/api/rfm/segments (basic RFM, segment preview), /v1/api/rfm/config (Phase 3).
    - **Admin Service**: /admin/* (merchant management, RBAC, GDPR, rate limits, notification templates).
  - Schema: Use loyalnest_full_schema.sql with customers.rfm_score (JSONB), program_settings.rfm_thresholds (JSONB), merchants.staff_roles (JSONB for RBAC), email_templates.body (JSONB), rfm_segment_counts materialized view, gdpr_requests(retention_expires_at), referrals(referral_link_id), reward_redemptions(campaign_id).
  - Shopify integration: OAuth via @shopify/shopify-app-express, orders/create webhook for points and RFM updates, POS for points earning, Checkout UI Extensions for points redemption.
  - Use Docker Compose to manage microservices locally and in production.
  - Implement rfm_segment_counts materialized view for RFM analytics (merchant_id, segment_name, customer_count, last_refreshed, daily refresh at 0 1 * * *).
  - Design async CSV import system for customer data with validation (email, shopify_customer_id) and GDPR compliance (AES-256 encryption for PII).
  - Use AI for NestJS microservice boilerplate, React components, Jest/Cypress tests, and PostgreSQL index optimization.
- **Feature Prioritization**:
  - TVP (Must Have): Points, SMS/email referrals, basic RFM analytics, Shopify POS, checkout extensions, automated email flows, data import, GDPR request form, referral status display, notification templates, campaign discounts, rate limit monitoring.
  - Plan Should Have for Phase 3: VIP tiers, advanced RFM configuration, exit-intent popups, Klaviyo/Mailchimp integration, multi-store point sharing, behavioral segmentation.
  - Plan Could Have for Phase 6: Gamification, multilingual widget, multi-currency discounts, non-Shopify POS, advanced analytics, developer toolkit.
- **Prototyping**:
  - Build clickable prototype (Figma) for dashboard, widget, admin module, checkout extensions, GDPR request form, referral status, RFM segment preview, notification templates, rate limit monitoring.
  - Validate with 5–10 Shopify merchants (including 2–3 Shopify Plus) via Shopify Partners program, testing RFM usability, SMS referral popup effectiveness, POS integration, checkout extension adoption, GDPR form, referral status, notification templates, rate limits.
- **Enhancements & Best Practices**:
  - Integrate PostHog for feature usage tracking (e.g., RFM wizard completion rate, GDPR form submissions, referral status views, notification template edits, rate limit checks).
  - Include tooltips and guided onboarding in wireframes for Must Have features.
  - Document Docker Compose and Nginx configs for VPS setup, including microservices orchestration.
  - Conduct early user testing on RFM wizard, SMS referral popup, GDPR form, referral status, notification templates, rate limit monitoring, and checkout extensions.
- **Additional Tasks**:
  - Implement rfm_segment_counts materialized view (PostgreSQL, daily refresh).
  - Design RFM segment preview UI and API (/v1/api/rfm/segments/preview) for merchants.
  - Develop notification template configuration UI and API (/v1/api/notifications/template) with multilingual support.
  - Build rate limit monitoring UI and API (/v1/api/rate-limits) for Shopify API and integrations.
- **Deliverables**:
  - Wireframes/mockups for dashboard, widget, RFM analytics, admin module, checkout extensions, GDPR form, referral status, notification templates, rate limit monitoring.
  - Microservices architecture diagram (NestJS, Rust, PostgreSQL, Redis, VPS).
  - Clickable prototype (Figma) with Must Have features.
  - Merchant feedback report on RFM, SMS referrals, POS, checkout extensions, GDPR form, referral status, notification templates, rate limits.

## Phase 3: Development (19 Weeks)
### Goals
- Build production-grade TVP with Must Have features across microservices, including Shopify Plus checkout extensions, GDPR request form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring.
- Develop admin module with RBAC for multi-user support, VIP tiers management, and campaign management.
- Ensure Shopify compliance and performance for 5,000+ customers (50,000+ for Plus).

### Tasks
- **Backend Development (Microservices)**:
  - **Auth Service (NestJS)**:
    - APIs: /v1/api/auth/login, /v1/api/auth/refresh, /v1/api/auth/roles.
    - Shopify: OAuth via @shopify/shopify-app-express, JWT for admin module RBAC (roles: admin:full, admin:analytics, admin:support).
    - Cache tokens in Redis.
  - **Points Service (NestJS)**:
    - APIs: /v1/api/points/earn, /v1/api/points/redeem, /v1/api/points/adjust, /v1/api/rewards (campaign discounts).
    - Shopify: Orders/create webhook for points (1 point/$), POS for points earning, Checkout UI Extensions for redemption.
    - Implement campaign discounts with RFM conditions (e.g., bonus_campaigns.conditions JSONB: {"rfm_score": {"recency": ">=4"}}).
    - Add campaign_id to reward_redemptions table for tracking.
    - Cache points balances and campaign discounts in Redis.
  - **Referrals Service (NestJS)**:
    - APIs: /v1/api/referrals/create, /v1/api/referrals/complete, /v1/api/referrals/status.
    - Klaviyo/Postscript: SMS/email referrals, storing codes in referrals table (referral_link_id) via Bull queues.
    - Cache referral codes and statuses in Redis.
  - **Analytics Service (NestJS)**:
    - APIs: /v1/api/rfm/segments (basic RFM segments, churn risk), /v1/api/rfm/segments/preview (segment preview).
    - gRPC: /analytics.v1/AnalyticsService/GetSegments, /analytics.v1/AnalyticsService/PreviewRFMSegments.
    - RFM: Static calculations (e.g., Recency 5: <30 days, Frequency 5: 5+ orders, Monetary 5: $250+), stored in customers.rfm_score (JSONB).
    - Use rfm_segment_counts materialized view for analytics.
    - PostHog: Track events (e.g., points_earned, referral_clicked, rfm_preview_viewed).
  - **Admin Service (NestJS)**:
    - APIs: /admin/merchants, /admin/points/adjust, /admin/referrals, /admin/rfm-segments, /admin/logs, /admin/notifications/template, /admin/rate-limits, /admin/customers/import with JWT and RBAC.
    - gRPC: /admin.v1/AdminService/UpdateNotificationTemplate, /admin.v1/AdminService/GetRateLimits, /admin.v1/AdminService/ImportCustomers.
    - GDPR: Implement /webhooks/customers/data_request, /webhooks/customers/redact with retention_expires_at tracking.
    - Build async CSV import for customers with validation (email, shopify_customer_id) and GDPR compliance (AES-256 encryption).
    - Cache logs, merchant data, rate limits, and notification templates in Redis.
  - **Inter-Service Communication**: Use gRPC for high-performance communication (e.g., Points Service calls Auth Service for RBAC, Analytics Service for RFM previews).
  - **Rust/Wasm**:
    - Shopify Functions: Discount logic (amount/percentage off), checkout extensions (points redemption), basic RFM score updates, campaign discounts with RFM conditions.
    - Use Shopify CLI for testing; generate Rust code and tests with AI.
  - Use AI for microservice boilerplate, error handlers, Jest tests; manually review for Shopify compliance.
- **Frontend Development**:
  - Build dashboard with Vite + React, Polaris, Tailwind CSS, App Bridge:
    - WelcomePage.tsx: Setup tasks, RFM guide.
    - PointsPage.tsx: Configure purchases, signups, reviews, birthdays, campaign discounts.
    - ReferralsPage.tsx: SMS/email config, referral status.
    - AnalyticsPage.tsx: Basic RFM segments, segment preview (Chart.js bar chart).
    - SettingsPage.tsx: Store, billing, rewards panel, checkout extension customization, notification templates, rate limit monitoring.
  - Customer widget: Embeddable React component for points balance, redemption, SMS/email referral popup, GDPR request form, referral status display, RFM nudges.
  - On-Site Content (Must Have): SEO-friendly loyalty page, rewards panel, launcher button, points display on product/checkout pages, post-purchase/email capture popups, GDPR request form, referral status.
  - Admin module: Frontend for merchant management, RFM segments, analytics, logs, rate limits, multi-user roles, customer import, notification templates.
  - Use AI for React components and Cypress tests; outsource Polaris review ($1,000).
- **Integrations**:
  - Shopify: APIs for orders, customers, discounts; POS for points earning; Checkout UI Extensions for points redemption.
  - Klaviyo/Postscript: SMS/email referrals, notification templates for points, referrals, GDPR requests.
  - Reviews: Yotpo or Judge.me for points-for-reviews.
  - Email: Basic Klaviyo/Mailchimp for automated loyalty email flows.
  - Data Import: Async CSV import for Smile.io/LoyaltyLion migration with RBAC enforcement.
  - Multi-store point sharing: Enable points sharing across Shopify Plus multi-store setups, storing shared points in Redis with merchant_group_id.
  - Defer Should Have (advanced Klaviyo, behavioral segmentation) and Could Have (non-Shopify POS, advanced analytics) to Phase 6.
- **RBAC Enforcement**:
  - Enforce RBAC for customer import (admin:full role), campaign management (admin:full, admin:points), VIP tiers management (admin:full, admin:points), and admin user management (admin:full) in Admin Service.
- **Testing**:
  - Unit tests: Jest for NestJS APIs, cargo test for Rust Functions, Jest for RFM logic and campaign discounts.
  - Integration tests: Shopify/Klaviyo/Postscript/RFM/data-import/checkout extension/GDPR/referral status flows (Jest).
  - E2E tests: Dashboard, widget, RFM UI, popups, GDPR form, referral status, notification templates, rate limit monitoring, checkout extensions (Cypress).
  - Load test: 5,000 customers (Shopify) and 50,000 customers (Plus) with Redis caching and PostgreSQL indexes.
  - Optimize PostgreSQL with partitioning for points_transactions, referrals, reward_redemptions, and rfm_segment_counts tables for Plus-scale performance.
  - Outsource QA to freelancer ($2,500) for Cypress and exploratory testing.
- **Deployment**:
  - Deploy on VPS (Ubuntu with Docker) using Docker Compose for microservices (auth, points, referrals, analytics, admin), PostgreSQL, Redis, and Vite + React frontend.
  - Use Nginx for frontend assets and reverse proxy to NestJS APIs.
  - Set up GitHub Actions for CI/CD with change detection to build/deploy only changed microservices.
  - Provide Docker Compose scripts for VPS setup.
- **Enhancements & Best Practices**:
  - Integrate Grafana for monitoring API latency and database performance across microservices.
  - Implement rate-limiting middleware for Shopify API (2 req/s for Shopify, 40 req/s for Plus).
  - Use short-lived JWTs (15 minutes) with refresh tokens for admin APIs.
  - Add webhook idempotency using Redis and dead-letter queue for failures.
  - Use k6 for load testing in CI pipeline, including Plus-scale scenarios (50,000 customers, 1,000 orders/hour).
- **Additional Tasks**:
  - Implement campaign discounts with RFM conditions in Points Service, using Shopify Functions (Rust/Wasm).
  - Add campaign_id to reward_redemptions table for campaign tracking.
  - Build async CSV import system for customer data with RBAC enforcement (admin:full role).
  - Enforce RBAC for VIP tiers management and admin user management in Admin Service.
- **Deliverables**:
  - TVP with Must Have features across microservices: Points, SMS/email referrals, basic RFM analytics, Shopify POS, checkout extensions, email flows, data import, GDPR request form, referral status, notification templates, campaign discounts, rate limit monitoring.
  - Admin module with merchant management, RFM segments, analytics, logs, RBAC, customer import, rate limits, notification templates.
  - Shopify/Klaviyo/Postscript/Yotpo/Klaviyo integrations.
  - Test reports and bug fixes.
  - VPS deployment with Docker Compose and Nginx.

## Phase 4: Beta Testing and Refinement (5.5 Weeks)
### Goals
- Validate TVP with merchants, focusing on Must Have features across microservices, including checkout extensions, GDPR request form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring.
- Refine based on feedback for Shopify App Store launch.

### Tasks
- **Beta Testing**:
  - Recruit 10–15 merchants (including 2–3 Shopify Plus) via Shopify Reddit/Discord and Partners program (free 300-order plan).
  - Test Must Have features: Points, SMS/email referrals, basic RFM analytics, Shopify POS, checkout extensions, data import, GDPR request form, referral status display, notification templates, campaign discounts, rate limit monitoring.
  - Collect feedback on RFM usability, referral conversion rates, POS syncing, checkout extension adoption, GDPR form usability, referral status engagement, notification template effectiveness, customer import accuracy, campaign discount performance, rate limit monitoring utility.
  - Add PostHog events for Plus-specific features (e.g., checkout_extension_used, multi_store_points_shared, gdpr_request_submitted, campaign_discount_redeemed, rate_limit_viewed).
- **Refinement**:
  - Fix bugs in RFM calculations, referral popups, POS integration, checkout extensions, GDPR form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring across microservices.
  - Enhance RFM analytics with segment engagement metrics (e.g., repeat purchase rate) and segment preview accuracy.
  - Optimize Redis caching and PostgreSQL indexes/partitioning for performance.
  - Begin Should Have development: VIP tiers (spending-based), exit-intent popups, behavioral segmentation, multi-store point sharing.
- **Documentation and Support**:
  - Create guides/YouTube tutorials for no-code setup (RFM wizard, points, referrals, checkout extensions, GDPR form, notification templates, customer import, campaign discounts, rate limit monitoring, VPS deployment).
  - Develop Shopify Plus onboarding guide for multi-user setup, checkout extensions, multi-store point sharing, campaign discounts, rate limit monitoring; plan white-glove onboarding for $99/month and Enterprise plans.
  - Provide Docker Compose scripts for microservices and VPS setup.
  - Set up email support; plan live chat for paid plans.
- **Enhancements & Best Practices**:
  - Use PostHog to track feature adoption (e.g., SMS referral clicks, GDPR form submissions, referral status views, notification template edits, customer import completions, campaign discount redemptions, rate limit checks).
  - Conduct surveys and interviews for structured feedback.
  - Maintain a public changelog for transparency.
- **Deliverables**:
  - Beta test report (RFM usability, referral rates, POS performance, checkout extension adoption, GDPR form, referral status, notification templates, customer import, campaign discounts, rate limits).
  - Refined TVP with bug fixes and RFM enhancements.
  - Documentation, tutorials, support portal, VPS deployment guide, Shopify Plus onboarding guide.

## Phase 5: Launch and Marketing (6 Weeks)
### Goals
- Launch on Shopify App Store with Must Have features and select Should Have features.
- Attract 100+ merchants (including 5–10 Shopify Plus) in 3 months.

### Tasks
- **Shopify App Store Submission**:
  - Ensure Polaris UI, App Bridge, GDPR/CCPA compliance (encrypt customers.email, rfm_score; handle GDPR webhooks with gdpr_requests table; retention_expires_at tracking).
  - Optimize listing with demo videos highlighting RFM analytics, SMS referrals, checkout extensions, GDPR request form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring, $29/month pricing, and data import.
- **Marketing Strategy**:
  - Launch website with pricing: Free (300 orders, basic RFM), $29/month (500 orders, full RFM, checkout extensions, campaign discounts), $99/month (1,500 orders, multi-store), Enterprise (custom).
  - Promote via Shopify Reddit/Discord, social media (Facebook, Instagram), Shopify Plus agencies.
  - Highlight case studies (e.g., 15% churn reduction via RFM, 10% referral conversion, 20% checkout extension adoption, 5% campaign discount redemption for Plus).
- **Post-Launch Support**:
  - Monitor performance via admin module (audit_logs, api_logs) on VPS.
  - Offer 24/7 email support and live chat for paid plans; white-glove onboarding for Plus.
  - Add Should Have features: Multi-store point sharing, Klaviyo/Mailchimp integration, discount banners.
- **Enhancements & Best Practices**:
  - Use PostHog to monitor onboarding drop-off and feature adoption (e.g., checkout_extension_used, gdpr_request_submitted, campaign_discount_redeemed, rate_limit_viewed).
  - Include screenshots and videos in merchant documentation.
  - Optimize VPS (Nginx, Docker) for low latency across microservices.
- **Additional Tasks**:
  - Implement GDPR/CCPA webhook handling with gdpr_requests table for customers/data_request and customers/redact, ensuring retention_expires_at compliance.
- **Deliverables**:
  - Approved Shopify App Store listing.
  - Marketing website, promotional materials.
  - Support system with onboarding guides and VPS maintenance docs.

## Phase 6: Post-Launch and Scaling (Ongoing)
### Goals
- Grow to 100+ merchants (including 5–10 Shopify Plus) in 3 months.
- Achieve Built for Shopify certification.
- Implement Should Have and Could Have features.

### Tasks
- **User Acquisition**:
  - Partner with Shopify Plus agencies and Shopify Reddit/Discord.
  - Run ads emphasizing RFM analytics, SMS referrals, checkout extensions, campaign discounts, rate limit monitoring, and $29/month pricing.
  - Publish case studies (e.g., 20% repeat purchase increase via RFM, 50% multi-store point sharing adoption, 10% campaign discount redemption).
- **Feature Expansion**:
  - **Should Have**:
    - Full RFM configuration (thresholds, tiers, adjustments) with Rust/Wasm for real-time updates.
    - VIP tiers (engagement-based perks: early access, birthday gifts).
    - Advanced Klaviyo events, Postscript integration.
    - Point calculators, checkout extensions, behavioral segmentation.
  - **Could Have**:
    - Gamification (badges, leaderboards).
    - Multilingual widget (10+ languages).
    - Multi-currency discounts.
    - Non-Shopify POS (Square, Lightspeed).
    - Advanced analytics (25+ reports, ROI dashboard).
    - Developer toolkit with webhook-based custom integrations for Shopify Plus (ERP/CRM).
- **Maintenance**:
  - Release quarterly updates (e.g., RFM tiers, gamification).
  - Monitor Shopify API changes via webhooks.
  - Optimize PostgreSQL with partitioning for points_transactions, referrals, reward_redemptions, vip_tiers, rfm_segment_counts.
  - Maintain Docker containers and Nginx on VPS for microservices.
- **Certification**:
  - Apply for Built for Shopify certification (4.5+ star rating after 3–6 months).
- **Enhancements & Best Practices**:
  - Scale VPS to managed DB/Redis or Kubernetes for 5,000+ merchants (50,000+ for Plus).
  - Regularly update developer/merchant documentation.
  - Monitor RFM engagement, referral conversion rates, campaign discount redemption, and checkout extension adoption.
- **Deliverables**:
  - Monthly performance reports (merchant growth, RFM engagement, referral rates, campaign discount redemption, checkout extension adoption).
  - Feature updates (Should Have and Could Have).
  - Built for Shopify certification application.
  - VPS maintenance and optimization guide for microservices.

## Updated Timeline
- Phase 1: 4 weeks
- Phase 2: 5 weeks
- Phase 3: 19 weeks
- Phase 4: 5.5 weeks
- Phase 5: 6 weeks
- Phase 6: Ongoing
- **Total**: 39.5 weeks (7–8 months for TVP, 12–14 months for full implementation)

### Adjustments:
- Extended Phase 3 (19 weeks) to include microservices setup, checkout extensions, RBAC, GDPR webhooks, customer import, campaign discounts, rate limit monitoring, multi-store point sharing, and Plus-scale load testing.
- Extended Phase 4 (5.5 weeks) for Plus-specific onboarding and PostHog events for GDPR, campaign discounts, rate limits.
- Maintained total timeline within 7–8 months for TVP.

## Budget Estimate
- Development: $70,750 (TVP, AI tools, freelancers: $2,500 UI, $2,500 QA, Shopify Plus features, microservices setup).
- Marketing: $3,000 (website, Shopify community ads, social media).
- Support Infrastructure: $4,000 (VPS hosting, PostHog, support tools).
- Contingency (15%): $11,662.50.
- **Total**: $89,412.50.

### Adjustments:
- Increased development budget by $15,750 for microservices architecture (Docker setup, gRPC, CI/CD with change detection, GDPR form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring, additional testing).
- Reallocated $2,000 from marketing to development for Plus-scale QA and microservices orchestration.

## Risks and Mitigation
- **Risk**: Shopify API changes.
  - **Mitigation**: Use @shopify/shopify-app-express, monitor API updates, test webhooks in CI pipeline.
- **Risk**: High competition.
  - **Mitigation**: Emphasize free RFM analytics, SMS referrals, checkout extensions, campaign discounts, rate limit monitoring, $29/month pricing, and data import in marketing.
- **Risk**: Slow adoption.
  - **Mitigation**: Free plan (300 orders), 14-day trial, Shopify Reddit/Discord engagement, case studies.
- **Risk**: Onboarding complexity (especially for Shopify Plus).
  - **Mitigation**: RFM setup wizard, GDPR form, notification templates, tooltips, YouTube tutorials, Plus-specific onboarding guide, white-glove onboarding.
- **Risk**: Scalability for 5,000+ merchants (50,000+ for Plus).
  - **Mitigation**: Microservices with Redis caching, PostgreSQL indexes/partitioning, Rust for RFM/campaign discounts, Dockerized VPS, Plus-scale load testing.
- **Risk**: AI code quality.
  - **Mitigation**: Manual review, Jest/Cypress tests, freelance QA, load testing.
- **Risk**: Solo developer bandwidth.
  - **Mitigation**: Leverage AI for code/tests, outsource UI/QA, prioritize Must Have features for TVP.
- **Risk**: Microservices complexity.
  - **Mitigation**: Use Nx for monorepo management, gRPC for inter-service communication, Docker Compose for local development, and change detection in CI/CD.

## Success Metrics
- **TVP (Phase 3–4)**: 90%+ merchant satisfaction, 80% RFM wizard completion rate, 5%+ SMS referral conversion, 85%+ checkout extension adoption, 50%+ GDPR form usage, 60%+ referral status engagement, 70%+ notification template usage, 90%+ customer import success rate, 10%+ campaign discount redemption for Plus merchants.
- **Launch (Phase 5)**: 100+ merchants (including 5–10 Plus merchants) in 3 months, 4.5+ star rating in 6 months.
- **Post-Launch (Phase 6)**: 20% repeat purchase increase, 10%+ RFM tier engagement, 50%+ multi-store point sharing adoption, 15%+ campaign discount redemption for Plus merchants, Built for Shopify certification in 12 months.

## Key Improvements
- **Architecture**: Transitioned to microservices (auth, points, referrals, analytics, admin) within a monorepo, using Docker for containerization and gRPC for inter-service communication (AnalyticsService, AdminService).
- **Feature Clarity**: Integrated Must Have (points, SMS/email referrals, basic RFM, Shopify POS, checkout extensions, GDPR request form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring), Should Have (VIP tiers, advanced RFM, Klaviyo, popups, multi-store point sharing), and Could Have (gamification, multilingual, non-Shopify POS, advanced analytics, developer toolkit) into phases.
- **Task Optimization**: Streamlined tasks, prioritized Must Have features for TVP, added GDPR form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring, moved multi-store point sharing to Phase 3 for Plus merchants, deferred Could Have to Phase 6.
- **API Design**: Added versioning (/v1/api/*), modular endpoints (/rfm/segments, /rfm/segments/preview, /notifications/template, /rate-limits), rate limiting (Shopify vs. Plus), webhook idempotency, RBAC for admin APIs, gRPC for Analytics and Admin Services.
- **Shopify Plus**: Added checkout extensions, RBAC, multi-store point sharing, campaign discounts, rate limit monitoring, Plus-scale load testing, and dedicated onboarding guide.
- **Risk Mitigation**: Included GDPR webhooks with gdpr_requests, PostHog for Plus feature tracking, freelance QA, Docker Compose scripts, CI/CD with change detection, rfm_segment_counts materialized view, referral_link_id, campaign_id tracking.
- **Timeline/Budget**: Adjusted for microservices and Plus features (+1.5 weeks, +$10,000) while maintaining TVP timeline.