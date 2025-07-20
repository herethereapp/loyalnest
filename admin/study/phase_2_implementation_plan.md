# LoyalNest App: Phase 2 Implementation Plan (Design and Prototyping, Weeks 5–11, August–September 2025)

## Overview
**Objective**: Create Shopify Polaris-compliant UI prototypes, finalize microservices architecture, and validate pricing and UX for the LoyalNest App, supporting Shopify Plus merchants (50,000+ customers, 1,000 orders/hour). This phase focuses on wireframes, clickable prototypes, RFM setup wizard, on-site content, microservices, and merchant feedback.

**Duration**: 7 weeks (August 4–September 19, 2025)  
**Team**: 1–2 developers, 1 in-house UI/UX designer, 1 QA engineer  
**Dependencies**: Merchant feedback for pricing validation; `loyalnest_full_schema.sql` for microservices  
**Tools**: Figma, Shopify Polaris, Tailwind CSS, Chart.js, i18next, NestJS, Rust, PostgreSQL, Redis, Kafka, Bull, Loki, Prometheus, Jest, Cypress, k6, Lighthouse CI, PostHog  
**Deliverables**:  
- Figma wireframes/mockups for Merchant Dashboard, Customer Widget, Admin Module, checkout extensions, GDPR form, referral status, notification templates, rate limit monitoring, usage thresholds, upgrade nudges, contextual tips  
- Clickable prototype with Must Have features and pricing mockup  
- Microservices architecture diagram  
- Merchant feedback report on RFM, referrals, POS, checkout extensions, GDPR, pricing, contextual tips  

## Milestones and Tasks

### 1. Design Wireframes and Prototypes (Weeks 5–7, August 4–August 24, 2025)
**Objective**: Develop Polaris-compliant wireframes and mockups for all UI components, leveraging `wireframes.md` (artifact_id: aebea41e-3395-415e-9be5-f47576ca5079).  
**Tasks**:  
- **Merchant Dashboard (US-MD1, US-MD2, US-MD19–US-MD22)**:  
  - Create Figma wireframes for Welcome Page, Points Program, Lifecycle Automation, Segment Benchmarking, Nudge A/B Testing, and Churn Risk Dashboard.  
  - Use Polaris `Card`, `Form`, `DataTable`, `Banner`, and Chart.js for RFM visualizations (`US-MD20`, `US-MD21`).  
  - Include checkout extension config (Polaris `Form`, `Select`), notification templates (Polaris `TextField`, `Button`), rate limit monitoring (Chart.js line charts), usage thresholds (Polaris `Badge`), upgrade nudges (Polaris `Banner`), and contextual tips (Polaris `CalloutCard`, e.g., “Add birthday bonus to boost referrals”).  
  - Ensure Tailwind CSS styling (`grid`, `animate-fade-in`), ARIA labels, and RTL support for Arabic (`ar`).  
- **Customer Widget (US-CW1–CW5, US-CW7–CW10, US-CW13–CW17)**:  
  - Design wireframes for Points Balance, Purchase Confirmation, Rewards Redemption, Referral Popup, Referral Status Page, GDPR Request Form, VIP Tier Dashboard, Nudge Popup/Banner, Badges Section, Leaderboard Page, Settings Panel, Sticky Bar, Post-Purchase Widget, VIP Tier Progress, and Wallet Integration.  
  - Use Polaris components (`Badge`, `Banner`, `Modal`, `DataTable`, `ProgressBar`, `Button`) and Tailwind CSS (`bg-blue-500`, `grid-cols-2`).  
  - Add progress bar for referral status (`US-CW7`) and VIP tier progress (`US-CW16`).  
  - Ensure accessibility (ARIA labels, Lighthouse CI score 90+), i18next for `en` (with `es`, `fr`, `ar`, `he` hooks), and RTL support.  
- **Admin Module (US-AM1–AM9, US-AM14–AM16)**:  
  - Design wireframes for Overview Dashboard, Merchant List, Customer Points Adjustment, User Management, Log Viewer, GDPR Request Dashboard, Plan Management, Integration Health Dashboard, RFM Configuration Admin, Multi-Tenant Management, and Action Replay Dashboard.  
  - Include RBAC roles (Polaris `Form`, `Select`) and integration kill switch (`US-AM14`, Polaris `Button`).  
  - Use Chart.js for RFM segments (Overview, RFM Configuration) and Tailwind CSS for styling.  
  - Ensure accessibility and RTL support.  
- **No-Code RFM Setup Wizard (US-MD20, US-MD21)**:  
  - Design a wizard in Figma with Polaris `Form`, `RangeSlider`, and `Card` for RFM threshold configuration and segment preview (Chart.js bar chart).  
  - Support inputs for recency, frequency, monetary weights and preview of segment distribution.  
  - Add Polaris `Banner` for confirmation/errors, Tailwind `grid grid-cols-2`.  
- **On-Site Content (US-CW8–CW10)**:  
  - Design SEO-friendly loyalty page (Polaris `Card`, Tailwind `p-4`), rewards panel (Polaris `Card`, `grid-cols-3`), launcher button (Polaris `Button`, Tailwind `fixed bottom-4 right-4`), points display (Polaris `Badge`), popups (Polaris `Modal`), GDPR form (Polaris `Form`), and referral status (Polaris `DataTable`, `ProgressBar`).  
  - Optimize for SEO with meta tags and structured data (JSON-LD).  
- **Validation**:  
  - Conduct internal review with UI/UX designer and QA for Polaris compliance, accessibility (Lighthouse CI), and multilingual hooks (i18next).  
  - Export wireframes as SVG/PNG for stakeholder review.  

**Timeline**:  
- Week 5: Merchant Dashboard and Customer Widget wireframes  
- Week 6: Admin Module and RFM wizard wireframes  
- Week 7: On-site content and internal validation  

**Owner**: UI/UX designer, QA for accessibility testing  
**Tools**: Figma, Shopify Polaris, Tailwind CSS, Chart.js, i18next  
**Deliverables**: Figma wireframes/mockups for all components, exported SVG/PNG files  

### 2. Develop Clickable Prototype (Weeks 8–9, August 25–September 7, 2025)
**Objective**: Build a clickable prototype with Must Have features (`US-CW1–CW5`, `US-MD1–MD2`, `US-AM1–AM3`) and pricing mockup.  
**Tasks**:  
- **Prototype Development**:  
  - Use Vite + React with Shopify Polaris and Tailwind CSS to implement clickable prototype based on Figma wireframes.  
  - Include Must Have features: Points Balance, Purchase Confirmation, Rewards Redemption, Referral Popup, Welcome Page, Points Program, Overview Dashboard, Merchant List, Customer Points Adjustment.  
  - Add pricing mockup page (Polaris `Card`, `Select` for plans, e.g., Free, $29/mo) linked to checkout flow.  
  - Implement i18next for `en` with hooks for `es`, `fr`, `ar`, `he` (RTL).  
  - Ensure accessibility (ARIA labels, keyboard navigation, Lighthouse CI score 90+).  
- **Checkout Extension Mockup**:  
  - Simulate checkout flow with points redemption and referral CTA (Polaris `Banner`, `Button`).  
  - Mock API responses for `/points.v1/GetPointsBalance` and `/points.v1/RedeemReward` using JSON fixtures.  
- **Testing**:  
  - Write Jest unit tests for UI components (e.g., `PointsBalance`, `ReferralPopup`).  
  - Run Cypress E2E tests for critical flows (points earning, redemption, referral sharing).  
  - Perform k6 load tests for 5,000 concurrent users on widget components.  
  - Validate accessibility with Lighthouse CI (target score 90+).  
- **Validation**:  
  - Conduct internal demo with team to ensure feature coverage and UX flow.  
  - Prepare prototype for merchant feedback (Task 3).  

**Timeline**:  
- Week 8: Develop Must Have features and pricing mockup  
- Week 9: Testing and internal validation  

**Owner**: 1–2 developers, UI/UX designer, QA  
**Tools**: Vite, React, Shopify Polaris, Tailwind CSS, i18next, Jest, Cypress, k6, Lighthouse CI  
**Deliverables**: Clickable prototype (hosted on Vercel or Netlify), test reports (Jest, Cypress, k6, Lighthouse CI)  

### 3. Validate Prototypes and Pricing with Merchants (Weeks 9–10, August 25–September 14, 2025)
**Objective**: Gather feedback from 5–10 merchants (2–3 Shopify Plus) via Shopify Partners on RFM, referrals, POS, checkout extensions, GDPR, pricing, and contextual tips.  
**Tasks**:  
- **Recruitment**:  
  - Identify 5–10 merchants (2–3 Shopify Plus, 50,000+ customers) via Shopify Partners program.  
  - Prepare outreach email with demo link and survey (Google Forms or Typeform).  
- **Feedback Collection**:  
  - Share clickable prototype (Vercel/Netlify) and pricing mockup.  
  - Conduct 30-minute Zoom interviews with merchants to review:  
    - RFM setup wizard and segment preview (`US-MD20`, `US-MD21`)  
    - Referral Popup and Status (`US-CW4`, `US-CW7`)  
    - POS integration flow (mock checkout)  
    - GDPR Request Form (`US-CW8`)  
    - Pricing plans (Free vs. paid tiers)  
    - Contextual tips (e.g., “Add birthday bonus to boost referrals”)  
  - Run survey for quantitative feedback on UX, pricing, and feature priority.  
- **Analysis**:  
  - Compile feedback into a report (Google Docs) with sections for RFM, referrals, POS, checkout extensions, GDPR, pricing, and tips.  
  - Identify common pain points and prioritize updates (e.g., simplify RFM wizard).  
- **Validation**:  
  - Share report with team and stakeholders for review.  
  - Update Figma wireframes and prototype based on feedback (e.g., adjust Polaris `Form` layouts).  

**Timeline**:  
- Week 9: Merchant recruitment and interviews  
- Week 10: Survey analysis and feedback report  

**Owner**: UI/UX designer, 1 developer for prototype updates, QA for validation  
**Tools**: Zoom, Google Forms/Typeform, Google Docs, Figma, Vercel/Netlify  
**Deliverables**: Merchant feedback report, updated Figma wireframes, updated prototype  

### 4. Finalize Microservices Architecture (Weeks 7–10, August 18–September 14, 2025)
**Objective**: Design microservices with REST APIs, gRPC, and PostgreSQL schema (`loyalnest_full_schema.sql`), integrating Redis, Kafka, and monitoring tools.  
**Tasks**:  
- **Architecture Diagram**:  
  - Create diagram (Draw.io or Lucidchart) for microservices:  
    - **Points Service** (`/points.v1/*`, G1a–G1h): Handles points earning, redemption, VIP tiers, wallet passes (NestJS, REST).  
    - **Referral Service** (`/referrals.v1/*`, G2a–G2d): Manages referral creation, completion, status (NestJS, REST).  
    - **Analytics Service** (`/analytics.v1/*`, G3a–G3j): RFM segmentation, nudges, leaderboards, benchmarks (Rust, gRPC).  
    - **Admin Service** (`/admin.v1/*`, G4a–G4k): Merchant management, GDPR, logs, health checks (NestJS, REST).  
    - **Auth Service** (`/auth.v1/*`, G5a–G5b): RBAC, multi-tenant accounts (NestJS, REST).  
    - **Frontend Service** (`/frontend.v1/*`, G6a–G6b): Widget config, sticky bar (NestJS, REST).  
  - Include integrations: Shopify OAuth (H1a), webhooks (`orders/create`, H1b), Klaviyo, PostHog (L).  
  - Add Redis Cluster/Streams (J1–J21), Kafka (K), Bull queues (M), Loki (logs), Prometheus (metrics).  
- **Database Schema**:  
  - Finalize `loyalnest_full_schema.sql` (PostgreSQL with JSONB, range partitioning for `points_transactions`, `orders`, `customers`).  
  - Define tables: `customers` (I1), `orders` (I2), `points_transactions` (I3), `reward_redemptions` (I6), `program_settings` (I7), `referrals` (I8), `rfm_segments` (I13), `bonus_campaigns` (I17), `gamification_achievements` (I18), `nudge_events` (I20), `gdpr_requests` (I21), `wallet_passes` (I26).  
  - Implement AES-256 encryption for PII (I1a, I2a, I26a).  
- **API Specifications**:  
  - Document REST APIs (`/v1/api/*`) in OpenAPI (Swagger) and gRPC protos for analytics service.  
  - Example endpoints: `/points.v1/GetPointsBalance`, `/referrals.v1/CreateReferral`, `/analytics.v1/GetChurnRisk`, `/admin.v1/ProcessGDPRRequest`.  
  - Ensure rate limiting (1,000 requests/hour per merchant) and caching (Redis, J1–J21).  
- **Monitoring and Queues**:  
  - Configure Bull queues for async tasks (e.g., referral processing, GDPR requests).  
  - Set up Loki for log aggregation and Prometheus for metrics (e.g., API latency, error rates).  
- **Validation**:  
  - Test schema with pgTAP for data integrity and partitioning.  
  - Simulate 10,000 orders/hour with k6 to validate API performance.  
  - Review architecture with team for scalability and security (OWASP ZAP).  

**Timeline**:  
- Week 7: Architecture diagram and schema design  
- Week 8–9: API specs and monitoring setup  
- Week 10: Validation and testing  

**Owner**: 1–2 developers, QA for testing  
**Tools**: Draw.io/Lucidchart, PostgreSQL, Redis, Kafka, Bull, Loki, Prometheus, pgTAP, k6, Swagger, OWASP ZAP  
**Deliverables**: Microservices architecture diagram, `loyalnest_full_schema.sql`, OpenAPI/gRPC specs, test reports  

### 5. Add i18n Hooks for Multilingual Support (Week 11, September 15–19, 2025)
**Objective**: Implement i18next for English (`en`) with hooks for `es`, `fr`, `ar`, `he` (RTL) in preparation for Phase 6.  
**Tasks**:  
- **i18next Integration**:  
  - Add i18next to Vite + React prototype for Customer Widget, Merchant Dashboard, and Admin Module.  
  - Create translation files for `en` (e.g., `en.json` with keys like `"points_balance": "Your balance: {{count}} points"`).  
  - Add placeholders for `es`, `fr`, `ar`, `he` in `locales/` directory.  
  - Implement RTL support for `ar` and `he` using Tailwind CSS (`dir="rtl"`, `text-right`).  
- **Testing**:  
  - Write Jest tests for i18next rendering (e.g., `PointsBalance` with `en` and `ar`).  
  - Run Cypress E2E tests for language switching (`US-CW13`).  
  - Validate RTL layout with Lighthouse CI.  
- **Validation**:  
  - Review translations with UI/UX designer for accuracy.  
  - Ensure all UI components (Polaris `Banner`, `Button`, etc.) support i18next keys.  

**Timeline**: Week 11  
**Owner**: 1 developer, UI/UX designer for review  
**Tools**: Vite, React, i18next, Tailwind CSS, Jest, Cypress, Lighthouse CI  
**Deliverables**: i18next integration in prototype, translation files, test reports  

## Weekly Schedule
- **Week 5 (August 4–10)**: Merchant Dashboard and Customer Widget wireframes  
- **Week 6 (August 11–17)**: Admin Module and RFM wizard wireframes  
- **Week 7 (August 18–24)**: On-site content wireframes, architecture diagram, schema design  
- **Week 8 (August 25–31)**: Prototype development (Must Have features, pricing mockup), API specs  
- **Week 9 (September 1–7)**: Prototype testing, merchant interviews, monitoring setup  
- **Week 10 (September 8–14)**: Merchant feedback analysis, prototype/wireframe updates, microservices validation  
- **Week 11 (September 15–19)**: i18n integration, final validation  

## Risk Mitigation
- **Dependency Delays**: Prioritize merchant recruitment in Week 8 to ensure timely feedback.  
- **Scalability Issues**: Use k6 to simulate 10,000 orders/hour early in Week 10 to identify bottlenecks.  
- **Accessibility Failures**: Run Lighthouse CI weekly during prototype development to maintain 90+ score.  
- **Security Concerns**: Validate APIs with OWASP ZAP in Week 10 to ensure secure endpoints (e.g., Shopify OAuth, RBAC).  
- **Team Bandwidth**: Allocate 1 developer for microservices and 1 for prototype to balance workload.  

## Success Criteria
- Figma wireframes/mockups cover all components in `wireframes.md` with Polaris compliance and accessibility.  
- Clickable prototype includes Must Have features, pricing mockup, and passes Jest/Cypress/k6 tests.  
- Merchant feedback report includes insights from 5–10 merchants with actionable updates applied.  
- Microservices architecture supports 50,000+ customers, 1,000 orders/hour, with Redis caching and PostgreSQL partitioning.  
- i18next supports `en` with hooks for `es`, `fr`, `ar`, `he` (RTL), validated by Cypress and Lighthouse CI.  

## Post-Phase Actions
- Share deliverables with stakeholders via Google Drive and Shopify Partners portal.  
- Update `README.md` with links to Figma, prototype, and architecture diagram.  
- Prepare Phase 3 plan (Development and Testing) based on merchant feedback and validated designs.