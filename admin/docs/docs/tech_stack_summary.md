```plain
LoyalNest App Tech Stack Summary

## Backend
- **Framework**: NestJS (TypeScript) with Microservices
  - **Why**: Modular structure organizes APIs into microservices (auth, points, referrals, analytics, admin) within a monorepo. TypeScript ensures type safety for points transactions, RFM scores (customers.rfm_score JSONB), and GDPR handling, reducing bugs for a solo developer. Scales for Phase 3 (VIP tiers, RFM nudges) and Phase 6 (gamification, bonus campaigns) without refactoring. Uses @shopify/shopify-app-express for Shopify OAuth and webhooks. gRPC for inter-service communication ensures performance.
  - **Use Case**: 
    - **Auth Service**: APIs (/v1/api/auth/*) for Shopify OAuth, JWT, RBAC (admin:full, admin:analytics, admin:support).
    - **Points Service**: APIs (/v1/api/points/*) for earning (purchases, signups, birthdays), redemption, Shopify POS, checkout extensions (US-MD7).
    - **Referrals Service**: APIs (/v1/api/referral/*) for SMS/email referrals via Twilio/SendGrid, referral tracking (US-CW4).
    - **Analytics Service**: APIs (/v1/api/rfm/*, /v1/api/analytics) for RFM segments, PostHog tracking (US-MD5, US-AM9).
    - **Admin Service**: APIs (/admin/*) for merchant management, logs, RBAC, GDPR handling (US-AM1–AM6).
  - **Security**: Uses pgcrypto for encrypting customers.email, merchants.api_token. Implements RBAC in Auth and Admin Services.
  - **AI Assistance**: Generates NestJS microservice boilerplate, controllers, services, TypeORM queries, and Jest tests (e.g., "Write a NestJS microservice for points redemption"). Explains TypeScript decorators and gRPC setup.

- **Additional Backend**: Rust/Wasm
  - **Why**: Powers Shopify Functions for high-performance real-time logic, minimizing latency for Plus merchants (1,000 orders/hour).
  - **Use Case**: Implements discounts (e.g., 500 points for $5 off), RFM score updates (customers.rfm_score JSONB), VIP multipliers, and campaign discounts (US-BI4).
  - **AI Assistance**: Provides Rust code, cargo test cases, and Shopify CLI setup guides (e.g., "Write a Rust Shopify Function for RFM updates").

- **Database**: PostgreSQL (JSONB, pgcrypto)
  - **Why**: Stores all data in tables (merchants, customers, points_transactions, referrals, rewards, program_settings, gdpr_requests, gamification_achievements, nudge_events) with JSONB for flexible configs (program_settings.config, email_templates.body). Indexes and partitioning ensure performance for 50,000+ customers. pgcrypto encrypts sensitive fields.
  - **Use Case**: Manages customer data, points transactions, referral codes, RFM segments, GDPR requests, and nudge events across microservices. Supports multilingual content (email_templates.body, nudges.title JSONB).
  - **AI Assistance**: Optimizes indexes, generates schema scripts, and provides TypeORM queries (e.g., "Optimize PostgreSQL query for RFM segments").

- **Caching**: Redis
  - **Why**: Caches points balances, referral codes, RFM scores, program settings, and webhook idempotency keys to reduce database load for high-traffic stores.
  - **Use Case**: Speeds up frequent queries (e.g., points balance in CustomerWidget.tsx, RFM segments in AnalyticsPage.tsx). Invalidates cache on updates (e.g., PUT /settings, POST /rewards).
  - **AI Assistance**: Provides Redis integration code for NestJS (e.g., "Cache points balance in Redis").

- **Queue**: Bull (Redis-based)
  - **Why**: Handles async tasks (Twilio/SendGrid notifications, RFM updates) for scalability and reliability across microservices.
  - **Use Case**: Queues SMS/email notifications (US-CW4, US-BI2) and RFM score calculations (US-BI5) in Referrals and Analytics Services.
  - **AI Assistance**: Generates Bull queue setup and error handling (e.g., "Add Bull queue for Twilio SMS").

## Frontend
- **Framework**: Vite + React (TypeScript)
  - **Why**: Vite’s fast builds and HMR accelerate development of Polaris-compliant components (WelcomePage.tsx, PointsPage.tsx, AnalyticsPage.tsx, CustomerWidget.tsx). TypeScript ensures type-safe props (e.g., interface Customer { points: number; rfm_score: RFMScore; }). Supports Shopify App Bridge, Polaris, and Tailwind CSS for compliance and responsive design. Served as a microservice (Frontend Service).
  - **Use Case**: Builds Merchant Dashboard (points, referrals, RFM charts), Customer Widget (points balance, redemption, referrals, nudges), and Admin Module (merchant management, GDPR requests). Supports Phase 6 features (gamification, multilingual via Accept-Language headers).
  - **Accessibility**: Uses ARIA labels (e.g., aria-label="Redeem 500 points") and keyboard navigation for screen reader support.
  - **AI Assistance**: Generates JSX components, Tailwind styles, and Cypress tests (e.g., "Write a Polaris-compliant React component for RFM chart").

- **UI Framework**: Shopify Polaris
  - **Why**: Ensures Shopify App Store compliance with consistent, merchant-friendly UI.
  - **Use Case**: Implements Merchant Dashboard (Tabs, FormLayout, Button) and Admin Module. Used minimally in Customer Widget for consistency.
  - **AI Assistance**: Provides Polaris component examples (e.g., "Use Polaris Tabs for Points Program").

- **Styling**: Tailwind CSS
  - **Why**: Enables rapid, utility-first styling for responsive design (sm:, md: breakpoints).
  - **Use Case**: Styles Customer Widget (mobile-friendly), Merchant Dashboard, and Admin Module. Complements Polaris for custom layouts (e.g., RFM chart).
  - **AI Assistance**: Generates Tailwind classes (e.g., "Style a responsive points balance display").

- **Shopify Integration**: App Bridge
  - **Why**: Embeds React components securely in Shopify admin and storefront.
  - **Use Case**: Authenticates Merchant Dashboard (US-MD1) and Customer Widget (US-CW1) with Shopify OAuth via Auth Service.
  - **AI Assistance**: Provides App Bridge setup code (e.g., "Integrate App Bridge for Customer Widget").

- **Visualization**: Chart.js
  - **Why**: Renders RFM segment bar charts and analytics visualizations.
  - **Use Case**: Displays RFM segments (US-MD5, US-AM1), redemption rates, and loyalty revenue in AnalyticsPage.tsx and Admin Module.
  - **AI Assistance**: Generates Chart.js configs (e.g., "Create a bar chart for RFM segments").

## Deployment and Testing
- **Deployment**: VPS (Ubuntu with Docker)
  - **Why**: Provides full control over infrastructure, replacing Railway. Docker Compose orchestrates microservices (auth, points, referrals, analytics, admin, frontend), PostgreSQL, Redis, and Bull for consistent environments. Nginx serves frontend assets with Let’s Encrypt SSL for security.
  - **Use Case**: Hosts microservices, frontend assets, and databases. Scales to 50,000+ customers with Redis caching, Bull queues, PostgreSQL partitioning, and microservices isolation.
  - **Monitoring**: Uses Prometheus and Grafana for performance tracking (e.g., API latency, queue status, inter-service communication).
  - **AI Assistance**: Provides Docker Compose files, Nginx configs, and Prometheus/Grafana setup (e.g., "Dockerize NestJS microservices and PostgreSQL for VPS").

- **CI/CD**: GitHub Actions
  - **Why**: Automates testing, building, and deployment of individual microservices to VPS, with change detection to build only affected services (e.g., points, referrals).
  - **Use Case**: Runs Jest, Cypress, and cargo tests on push; deploys changed microservices to VPS.
  - **AI Assistance**: Generates GitHub Actions workflows (e.g., "Create a CI/CD pipeline for NestJS microservices").

- **Testing**: Jest, Cypress, cargo test, k6
  - **Why**: Jest tests NestJS APIs and TypeORM transactions per microservice. Cypress tests end-to-end UI flows. cargo test validates Rust Functions. k6 ensures scalability (1,000 orders/hour). axe-core tests accessibility.
  - **Use Case**: Validates Shopify/Twilio/SendGrid integrations, RFM logic, GDPR handling, and UI interactions across microservices.
  - **AI Assistance**: Generates test cases (e.g., "Write Jest test for points API", "Write k6 script for load testing").

## Integrations
- **Shopify**: @shopify/shopify-app-express (Auth Service), Shopify CLI (Rust Functions)
  - **Why**: Handles OAuth, webhooks (orders/create, orders/cancelled, customers/data_request, customers/redact), and POS points earning (10 points/$).
  - **Use Case**: Authenticates merchants, syncs orders, processes GDPR requests, and enables POS integration (US-BI1, US-AM6).
  - **AI Assistance**: Provides webhook setup and OAuth code (e.g., "Handle Shopify orders/create webhook").

- **Twilio**:
  - **Why**: Powers SMS referrals and notifications in Referrals Service.
  - **Use Case**: Sends referral codes and points updates (US-CW4, US-BI2) via Bull queues.
  - **AI Assistance**: Generates Twilio integration code (e.g., "Send SMS referral via NestJS").

- **SendGrid**:
  - **Why**: Handles email notifications for referrals, points updates, and GDPR requests in Referrals Service.
  - **Use Case**: Sends multilingual emails (email_templates.body JSONB, US-CW4, US-AM6) via Bull queues.
  - **AI Assistance**: Provides SendGrid integration code (e.g., "Send email via SendGrid in NestJS").

- **PostHog**:
  - **Why**: Tracks user interactions and analytics events for monitoring engagement in Analytics Service.
  - **Use Case**: Logs events like points_earned, referral_clicked, analytics_viewed (US-MD5, US-AM1).
  - **AI Assistance**: Generates PostHog event tracking code (e.g., "Track redemption click in Customer Widget").

- **Shopify Flow**:
  - **Why**: Automates workflows for nudges and GDPR processing in Admin Service.
  - **Use Case**: Triggers RFM nudges (US-CW8) and GDPR data exports (US-AM6).
  - **AI Assistance**: Provides Shopify Flow scripts (e.g., "Create a Flow script for RFM nudges").

- **Phase 3–6 Integrations**: Klaviyo, Mailchimp, Yotpo, Square, Lightspeed, Gorgias, Postscript
  - **Why**: Expands marketing, POS, and support capabilities for Plus merchants.
  - **Use Case**: Klaviyo/Mailchimp for email campaigns, Square/Lightspeed for POS, Gorgias for support tickets, Yotpo for reviews, Postscript for SMS (US-BI3, US-AM12), integrated via Admin and Referrals Services.
  - **AI Assistance**: Provides integration setup guides (e.g., "Integrate Klaviyo with NestJS").

## Development Tools
- **AI Tools**: GitHub Copilot, Cursor, Grok
  - **Why**: Accelerates coding, testing, and debugging for a solo developer. Ensures Shopify compliance through manual review.
  - **Use Case**: Generates NestJS microservices, React components, SQL queries, and tests. Explains concepts (e.g., "Explain NestJS microservices").
- **Monorepo Management**: Nx
  - **Why**: Optimizes builds with caching and dependency tracking for microservices within the monorepo.
  - **Use Case**: Manages dependencies between services (auth, points, referrals, analytics, admin, frontend) and shared libraries.
- **Version Control**: Git (GitHub)
  - **Why**: Tracks changes, enables collaboration, and supports CI/CD with change detection.
  - **Use Case**: Commits code (e.g., git commit -m "Add Points Service") and manages branches for Phases 1–6.
- **IDE**: VS Code
  - **Why**: Supports TypeScript, React, Rust, and extensions (e.g., Prettier, ESLint, Mermaid).
  - **Use Case**: Edits code, renders Mermaid diagrams, and runs Shopify CLI.
  - **AI Assistance**: Provides VS Code setup guides (e.g., "Configure ESLint for NestJS").
```