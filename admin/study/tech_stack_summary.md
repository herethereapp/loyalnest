```markdown
# LoyalNest App Tech Stack Summary

## Backend
- **Framework**: NestJS (TypeScript) with Microservices
  - **Why**: Modular structure organizes APIs into microservices (auth, points, referrals, analytics, admin, campaign, gamification) within an Nx monorepo. TypeScript ensures type safety for points transactions, RFM scores (`customers.rfm_score` JSONB), GDPR handling, badges, campaigns, and composite segments, reducing bugs for a solo developer. Scales for Phase 3 (VIP tiers, RFM nudges), Phase 6 (gamification, bonus campaigns), and real-time features (WebSocket streams) without refactoring. Uses `@shopify/shopify-app-express` for Shopify OAuth and webhooks. gRPC for inter-service communication ensures performance, with WebSocket (`socket.io`/`ws`) for real-time updates and Nginx for gRPC proxy and service discovery.
  - **Use Case**: 
    - **Auth Service**: APIs (`/v1/api/auth/*`, `/admin/v1/auth/revoke`) for Shopify OAuth, JWT (15-minute expiry, revocation list in Redis), RBAC (`admin:full`, `admin:analytics`, `admin:support`, `admin:points`), MFA via Auth0.
    - **Points Service**: APIs (`/v1/api/points/*`, `/api/points/stream`) for earning (purchases, signups, birthdays, reviews), redemption, Shopify POS, checkout extensions (US-MD7), and real-time points streaming (US-CW1).
    - **Referrals Service**: APIs (`/v1/api/referral/*`) for SMS/email referrals via Klaviyo/Postscript, referral tracking (US-CW4), with error handling for timeouts (5s retry) and invalid codes (`INVALID_REFERRAL_CODE`).
    - **Analytics Service**: APIs (`/v1/api/rfm/*`, `/api/rfm/visualizations`, `/v1/api/rfm/composite`) for RFM segments, composite segments (e.g., At-Risk + High Churn), heatmaps, line charts, PostHog tracking (US-MD5, US-MD12, US-AM9).
    - **Admin Service**: APIs (`/admin/*`, `/admin/setup/stream`, `/admin/settings/currency`, `/admin/integrations/square`, `/admin/v1/feedback`, `/admin/v1/metrics`) for merchant management, logs, RBAC, GDPR handling, onboarding, multi-currency settings, Square integration, Typeform feedback, and SLO dashboard (US-AM1–AM6, US-MD1, US-MD6, US-AM13).
    - **Campaign Service**: APIs (`/api/campaigns/*`) for Shopify Discounts API, bonus campaigns, and VIP multipliers (US-MD14).
    - **Gamification Service**: APIs (`/api/gamification/badges`, `/api/gamification/leaderboard`) for badge awards and leaderboard rankings (US-CW11, US-CW12).
  - **Security**: Uses `pgcrypto` for encrypting `customers.email`, `merchants.api_token`. Implements RBAC, IP allowlisting, and HMAC signatures for `/admin/*`. Handles errors (`TIMEOUT`, `INVALID_REFERRAL_CODE`, `GDPR_RETRY_FAILED`) with retries (5s for timeouts, 3 retries for GDPR). Logs errors to Sentry, tracks in PostHog (`error_occurred`).
  - **AI Assistance**: Generates NestJS microservice boilerplate, controllers, services, TypeORM queries, WebSocket handlers, and Jest tests (e.g., "Write a NestJS microservice for composite segments"). Explains TypeScript decorators, gRPC, and WebSocket setup.

- **Additional Backend**: Rust/Wasm
  - **Why**: Powers Shopify Functions for high-performance real-time logic, minimizing latency for Plus merchants (1,000 orders/hour).
  - **Use Case**: Implements discounts (e.g., 500 points for $5 off), RFM score updates (`customers.rfm_score` JSONB), composite segments, VIP multipliers, campaign discounts (US-BI4), and gamification logic (badge awards).
  - **AI Assistance**: Provides Rust code, cargo test cases, and Shopify CLI setup guides (e.g., "Write a Rust Shopify Function for composite segments").

- **Database**: PostgreSQL (JSONB, pgcrypto)
  - **Why**: Stores all data in tables (`merchants`, `customers`, `points_transactions`, `referrals`, `rewards`, `program_settings`, `gdpr_requests`, `gamification_achievements`, `nudge_events`, `setup_tasks`, `merchant_settings`, `customer_badges`, `leaderboard_rankings`, `merchant_feedback`) with JSONB for flexible configs (`program_settings.config`, `email_templates.body`, `merchant_settings.currencies`). `tsvector` indexes for search (`merchants.name`, `customers.email`). Range partitioning ensures performance for 50,000+ customers. `pgcrypto` encrypts sensitive fields with AES-256, with quarterly key rotation via AWS KMS.
  - **Use Case**: Manages customer data, points transactions, referral codes, RFM segments, composite segments, GDPR requests, nudge events, onboarding tasks, multi-currency settings, badges, leaderboards, and Typeform feedback. Supports multilingual content (`email_templates.body`, `nudges.title` JSONB) with `fallback_language` (e.g., `en`).
  - **AI Assistance**: Optimizes indexes, generates schema scripts, and provides TypeORM queries (e.g., "Optimize PostgreSQL query for composite segments").

- **Caching**: Redis Cluster
  - **Why**: Caches points balances, referral codes, RFM scores, composite segments, program settings, webhook idempotency keys, visualizations, badges, leaderboards, onboarding tasks, SLO metrics, JWT revocation lists, and IP whitelists to reduce database load for high-traffic stores (10,000 orders/hour).
  - **Use Case**: Speeds up queries (e.g., points balance in `CustomerWidget.tsx`, RFM segments in `AnalyticsPage.tsx`, visualizations in `RFMConfigPage.tsx`, badges/leaderboards in `Widget.tsx`, onboarding tasks in `WelcomePage.tsx`, SLOs in `AdminPage.tsx`). Invalidates cache on updates (e.g., `PUT /settings`, `POST /rewards`, `POST /gamification/badges`). Supports dead-letter queue for GDPR webhook retries (3 retries).
  - **AI Assistance**: Provides Redis integration code for NestJS (e.g., "Cache composite segments in Redis").

- **Queue**: Bull (Redis-based)
  - **Why**: Handles async tasks (Klaviyo/Postscript notifications, RFM updates, customer imports, GDPR exports, campaign processing) for scalability and reliability across microservices.
  - **Use Case**: Queues SMS/email notifications (US-CW4, US-BI2), RFM score calculations (US-BI5), composite segment updates, customer imports (US-MD4), GDPR exports (US-AM6), and campaign processing (US-MD14). Supports DLQ with 5 retries and 2s delay.
  - **AI Assistance**: Generates Bull queue setup and error handling (e.g., "Add Bull queue for composite segment updates").

- **Event Processing**: Kafka
  - **Why**: Decouples microservices with async event handling for points, referrals, campaigns, gamification, and feedback.
  - **Use Case**: Publishes events (`points.earned`, `referral.created`, `campaign_discount_redeemed`, `badge_awarded`, `leaderboard_viewed`, `composite_segment_viewed`, `visualization_viewed`, `setup_progress_viewed`, `flow_template_installed`, `audit_replay_executed`, `merchant_feedback_submitted`) to PostHog for analytics.
  - **AI Assistance**: Generates Kafka producer/consumer code (e.g., "Publish badge_awarded event in NestJS").

## Frontend
- **Framework**: Vite + React (TypeScript)
  - **Why**: Vite’s fast builds and HMR accelerate development of Polaris-compliant components (`WelcomePage.tsx`, `PointsPage.tsx`, `AnalyticsPage.tsx`, `CustomerWidget.tsx`, `BonusCampaignsPage.tsx`, `RFMConfigPage.tsx`, `RateLimitsPage.tsx`). TypeScript ensures type-safe props (e.g., `interface Customer { points: number; rfm_score: RFMScore; }`). Supports Shopify App Bridge, Polaris, Tailwind CSS, `i18next` (with `fallback_language`), `socket.io-client` for compliance, responsive design, and real-time updates. Served as a microservice (Frontend Service).
  - **Use Case**: Builds Merchant Dashboard (points, referrals, RFM charts, campaigns, SLOs, feedback), Customer Widget (points balance, redemption, referrals, badges, leaderboards, nudges), and Admin Module (merchant management, GDPR requests, onboarding, multi-currency settings, Square integration, feedback). Supports Phase 6 features (gamification, multilingual via `Accept-Language` headers, `fallback_language: en`).
  - **Accessibility**: Uses ARIA labels (e.g., `aria-label="Redeem 500 points"`) and keyboard navigation for WCAG 2.1 compliance. Supports RTL (`ar`, `he`).
  - **AI Assistance**: Generates JSX components, Tailwind styles, WebSocket handlers, and Cypress tests (e.g., "Write a Polaris-compliant React component for SLO dashboard").

- **UI Framework**: Shopify Polaris
  - **Why**: Ensures Shopify App Store compliance with consistent, merchant-friendly UI.
  - **Use Case**: Implements Merchant Dashboard (Tabs, FormLayout, Button), Customer Widget, and Admin Module. Used for campaign creation (`BonusCampaignsPage.tsx`), onboarding (`WelcomePage.tsx`), visualizations (`RFMConfigPage.tsx`), and SLO dashboard (`AdminPage.tsx`).
  - **AI Assistance**: Provides Polaris component examples (e.g., "Use Polaris Tabs for SLO Dashboard").

- **Styling**: Tailwind CSS
  - **Why**: Enables rapid, utility-first styling for responsive design (`sm:`, `md:` breakpoints).
  - **Use Case**: Styles Customer Widget (mobile-friendly), Merchant Dashboard, and Admin Module. Complements Polaris for custom layouts (e.g., RFM heatmaps, leaderboards, SLO dashboard).
  - **AI Assistance**: Generates Tailwind classes (e.g., "Style a responsive SLO dashboard").

- **Shopify Integration**: App Bridge
  - **Why**: Embeds React components securely in Shopify admin and storefront.
  - **Use Case**: Authenticates Merchant Dashboard (US-MD1) and Customer Widget (US-CW1) with Shopify OAuth via Auth Service. Supports POS integration, checkout extensions, and Theme App Extensions (Phase 5).
  - **AI Assistance**: Provides App Bridge setup code (e.g., "Integrate App Bridge for Customer Widget").

- **Visualization**: Chart.js
  - **Why**: Renders RFM segment bar charts, heatmaps, line charts (repeat purchase rate, churn risk), and SLO metrics (API success rate, queue latency).
  - **Use Case**: Displays RFM segments, composite segments, redemption rates, loyalty revenue, rate limits, and SLOs in `AnalyticsPage.tsx`, `RFMConfigPage.tsx`, `RateLimitsPage.tsx`, and Admin Module (US-MD5, US-MD12, US-AM1).
  - **AI Assistance**: Generates Chart.js configs (e.g., "Create a heatmap for composite segments").

## Deployment and Testing
- **Deployment**: VPS (Ubuntu with Docker)
  - **Why**: Provides full control over infrastructure, replacing Railway. Docker Compose orchestrates microservices (auth, points, referrals, analytics, admin, campaign, gamification, frontend), PostgreSQL, Redis Cluster, Kafka, and Bull for consistent environments. Nginx serves frontend assets with Let’s Encrypt SSL, gRPC proxy, IP allowlisting, HMAC signatures, and canary routing. Supports WebSocket for real-time features.
  - **Use Case**: Hosts microservices, frontend assets, and databases. Scales to 50,000+ customers with Redis caching, Bull queues, PostgreSQL partitioning, and microservices isolation.
  - **Monitoring**: Uses Prometheus and Grafana for performance tracking (e.g., API latency <200ms, queue status, WebSocket connections, visualization latency, circuit breaker states, SLOs). Loki with structured logging (`trace_id`, `span_id`) for debugging.
  - **AI Assistance**: Provides Docker Compose files, Nginx configs, Prometheus/Grafana setup, and structured logging configs (e.g., "Dockerize NestJS microservices with gRPC proxy").

- **CI/CD**: GitHub Actions
  - **Why**: Automates testing, building, and deployment of microservices to VPS, with change detection to build only affected services (e.g., points, gamification).
  - **Use Case**: Runs Jest, Cypress, cargo test, k6, Lighthouse CI, OWASP ZAP, and nightly Chaos Mesh tests on push; deploys changed microservices to VPS with feature flags (`feature-flags.json`) for canary rollouts.
  - **AI Assistance**: Generates GitHub Actions workflows (e.g., "Create a CI/CD pipeline with Chaos Mesh").

- **Testing**: Jest, Cypress, cargo test, k6
  - **Why**: Jest tests NestJS APIs, TypeORM transactions, WebSocket handlers, and composite segments per microservice. Cypress tests end-to-end UI flows (e.g., campaign creation, badge animations, SLO dashboard). cargo test validates Rust Functions. k6 ensures scalability (1,000 orders/hour, 100 WebSocket connections). axe-core tests accessibility. Chaos Mesh tests resilience nightly.
  - **Use Case**: Validates Shopify/Klaviyo/Postscript/Square integrations, RFM logic, composite segments, GDPR handling, gamification, onboarding, feedback UI, and SLOs across microservices.
  - **AI Assistance**: Generates test cases (e.g., "Write Jest test for composite segments API", "Write k6 script for WebSocket streaming").

- **Development Scripts**: `dev.sh`, `replay-audit.ts`
  - **Why**: `dev.sh` starts Docker containers, seeds mock data (Faker), simulates RFM scores, and tests merchant referrals and onboarding. `replay-audit.ts` replays `audit_logs` for QA and training.
  - **Use Case**: Supports local development, RFM simulation, audit log replay, and merchant referral testing.
  - **AI Assistance**: Generates scripts (e.g., "Write a CLI for audit log replay").

## Integrations
- **Shopify**: `@shopify/shopify-app-express` (Auth Service), Shopify CLI (Rust Functions)
  - **Why**: Handles OAuth, webhooks (`orders/create`, `orders/cancelled`, `customers/data_request`, `customers/redact`, 3 retries), POS points earning (10 points/$), Discounts API (campaigns), and Flow templates (6–10, e.g., “RFM At-Risk → Email Nudge”).
  - **Use Case**: Authenticates merchants, syncs orders, processes GDPR requests, enables POS integration, manages campaigns, and publishes Flow templates to a public GitHub repo with install nudges (US-BI1, US-AM6, US-MD14).
  - **AI Assistance**: Provides webhook setup and OAuth code (e.g., "Handle Shopify orders/create webhook").

- **Klaviyo/Postscript**:
  - **Why**: Powers SMS/email referrals and notifications with timeout handling (5s retry) and `fallback_language` support.
  - **Use Case**: Sends referral codes, points updates, and GDPR notifications (US-CW4, US-BI2, US-AM6) via Bull queues.
  - **AI Assistance**: Generates integration code (e.g., "Send SMS referral via NestJS").

- **SendGrid**:
  - **Why**: Handles email notifications for referrals, points updates, and GDPR requests with timeout handling (5s retry) and `fallback_language`.
  - **Use Case**: Sends multilingual emails (`email_templates.body` JSONB, US-CW4, US-AM6) via Bull queues.
  - **AI Assistance**: Provides SendGrid integration code (e.g., "Send email via SendGrid in NestJS").

- **PostHog**:
  - **Why**: Tracks user interactions and analytics events for monitoring engagement.
  - **Use Case**: Logs events like `points_earned`, `referral_clicked`, `analytics_viewed`, `badge_awarded`, `leaderboard_viewed`, `visualization_viewed`, `setup_progress_viewed`, `composite_segment_viewed`, `flow_template_installed`, `audit_replay_executed`, `merchant_feedback_submitted` (US-MD5, US-AM1, US-CW11, US-CW12).
  - **AI Assistance**: Generates PostHog event tracking code (e.g., "Track composite segment view in Customer Widget").

- **Shopify Flow**:
  - **Why**: Automates workflows for nudges and GDPR processing.
  - **Use Case**: Triggers RFM nudges (US-CW8), GDPR data exports (US-AM6), and campaign actions via 6–10 templates published on a public GitHub repo with install nudges.
  - **AI Assistance**: Provides Shopify Flow scripts (e.g., "Create a Flow script for composite segment nudges").

- **Square**:
  - **Why**: Powers POS integration for points earning/redemption with health checks.
  - **Use Case**: Integrates via `/admin/integrations/square` for Plus merchants (US-AM13).
  - **AI Assistance**: Provides integration setup guides (e.g., "Integrate Square with NestJS").

- **Phase 3–6 Integrations**: Klaviyo, Mailchimp, Yotpo, Lightspeed, Gorgias
  - **Why**: Expands marketing, POS, and support capabilities for Plus merchants.
  - **Use Case**: Klaviyo/Mailchimp for email campaigns, Yotpo for reviews, Lightspeed for POS, Gorgias for support tickets (US-BI3, US-AM12). Integrates via Admin and Referrals Services with health checks and timeout handling (5s retry).
  - **AI Assistance**: Provides integration setup guides (e.g., "Integrate Klaviyo with NestJS").

## Development Tools
- **AI Tools**: GitHub Copilot, Cursor, Grok
  - **Why**: Accelerates coding, testing, and debugging for a solo developer. Ensures Shopify compliance through manual review.
  - **Use Case**: Generates NestJS microservices, React components, Rust Functions, SQL queries, WebSocket handlers, test cases, and audit replay CLI. Explains concepts (e.g., "Explain WebSocket integration in NestJS").
- **Monorepo Management**: Nx
  - **Why**: Optimizes builds with caching and dependency tracking for microservices.
  - **Use Case**: Manages dependencies between services (auth, points, referrals, analytics, admin, campaign, gamification, frontend) and shared libraries.
- **Version Control**: Git (GitHub)
  - **Why**: Tracks changes, enables collaboration, and supports CI/CD with change detection.
  - **Use Case**: Commits code (e.g., `git commit -m "Add Composite Segments"`) and manages branches for Phases 1–6.
- **IDE**: VS Code
  - **Why**: Supports TypeScript, React, Rust, and extensions (e.g., Prettier, ESLint, Mermaid).
  - **Use Case**: Edits code, renders Mermaid diagrams, runs Shopify CLI, and executes `replay-audit.ts`.
  - **AI Assistance**: Provides VS Code setup guides (e.g., "Configure ESLint for NestJS").
```