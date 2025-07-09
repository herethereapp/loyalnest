# RFM Configuration
LoyalNest App

## Overview
To implement the RFM (Recency, Frequency, Monetary) configuration feature for the LoyalNest App, targeting small (100–1,000 customers, AOV $20), medium (1,000–10,000 customers, AOV $100), and Shopify Plus merchants (50,000+ customers, AOV $500, 1,000 orders/hour), this task list outlines actionable steps using a microservices architecture (auth, points, referrals, analytics, admin, frontend services). The implementation uses NestJS with TypeScript (Analytics and Admin Services), Vite + React (Frontend Service), Rust with Shopify Functions (Analytics Service), PostgreSQL, and Redis Streams, managed via Nx monorepo. The plan prioritizes a minimum viable feature with iterative improvements, focusing on usability, performance, GDPR/CCPA compliance, and multilingual support (English, Spanish, French).

## Microservices Architecture
- **Analytics Service**: Handles RFM calculations, segment exports, and nudge tracking; exposes REST (`/api/v1/rfm/*`), gRPC APIs (`/analytics.v1/AnalyticsService/GetNudges`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`); uses PostgreSQL (`customers`, `customer_segments`, `rfm_segment_counts` materialized view with daily refresh at `0 1 * * *`), and Redis Streams (`rfm:customer:{id}`, `rfm:preview:{merchant_id}`).
- **Admin Service**: Manages RFM configuration, scheduling, and audit logging; exposes REST (`/admin/v1/rfm/*`) and gRPC APIs; uses PostgreSQL (`program_settings`, `audit_logs`).
- **Frontend Service**: Delivers RFM configuration UI and customer widget nudges; uses Vite + React with Polaris, Tailwind CSS, and i18next; communicates via REST (`/api/v1/rfm/*`).
- **Points Service**: Integrates with RFM for reward assignments (e.g., points for Champions) and campaign discounts (`/points.v1/PointsService/RedeemCampaignDiscount`); exposes gRPC APIs.
- **Referrals Service**: Supports referral-based nudges (e.g., “Invite a friend!” for At-Risk); exposes gRPC APIs.
- **Auth Service**: Handles RBAC for RFM configuration (`merchants.staff_roles`) and customer authentication; exposes gRPC APIs.
- **Communication**: gRPC for inter-service communication (e.g., Analytics ↔ Admin for RFM config), REST/GraphQL for Frontend ↔ Analytics/Admin, Redis Streams for cross-service caching (`rfm:preview:{merchant_id}`, `campaign_discount:{campaign_id}`).
- **Deployment**: Docker Compose for service containers, Nx monorepo for build management, Kubernetes for Plus-scale orchestration.

## Task List for Implementing RFM Configuration

### Phase 1: Planning and Setup
*Goal*: Establish a robust foundation for RFM configuration across microservices, aligning with merchant needs, Shopify Plus scalability, and GDPR/CCPA compliance.

*Enhancements & Best Practices*:
- Interview 5–10 merchants (2–3 Plus) to validate RFM thresholds and usability.
- Ensure GDPR/CCPA compliance (encrypted `rfm_score`, webhook handling for `customers/redact`).
- Support multilingual UI and notifications (JSONB, i18next for `en`, `es`, `fr`).
- Use PostHog to track interactions across services (e.g., `rfm_config_field_changed`).
- Implement LaunchDarkly feature flags for phased rollouts (e.g., `rfm_advanced`).
- Conduct monthly security audits for npm, cargo, Docker dependencies.

1. **Define Feature Requirements** (Admin Service)
   - *Description*: Finalize RFM configuration scope for small, medium, and Plus merchants.
   - *Tasks*:
     - Document RFM thresholds (weighted: 40% Recency, 30% Frequency, 30% Monetary):
       - Recency: Days since last order (1: >90 days, 2: 61–90 days, 3: 31–60 days, 4: 8–30 days, 5: ≤7 days).
       - Frequency: Number of orders (1: 1, 2: 2–3, 3: 4–5, 4: 6–10, 5: >10).
       - Monetary: Total spend, normalized by AOV (1: <0.5x AOV, 2: 0.5–1x AOV, 3: 1–2x AOV, 4: 2–5x AOV, 5: >5x AOV).
     - Define 2–5 tiers (e.g., Champions: R5, F4–5, M4–5; At-Risk: R1–2, F1–2, M1–2) with rewards (e.g., 500 points for Champions, 10% off for At-Risk via `bonus_campaigns.conditions`).
     - Specify adjustment frequencies: Daily (<10,000 customers), weekly (10,000+), monthly, quarterly, event-based (`orders/create`).
     - Include multilingual notification templates (`email_templates.body` as JSONB, e.g., `{"en": "Welcome to Gold!", "es": "¡Bienvenido a Oro!"}`).
     - Implement GDPR/CCPA webhooks (`customers/data_request`, `customers/redact`) with cascade deletes in Analytics Service.
     - Define success metrics: 80%+ wizard completion rate, 10%+ repeat purchase rate increase, 90%+ query performance under 1s.
     - Add edge cases: Zero orders (R1, F1, M1), high AOV ($10,000+ capped at M5), negative AOV (returns, M1), partial orders (exclude cancelled), inactive customers (>365 days, flag for nudges).
     - Store requirements in Admin Service (`program_settings.rfm_thresholds` JSONB).
     - Initialize `rfm_segment_counts` materialized view (US-MD12, US-BI5, I24a) with daily refresh (`0 1 * * *`) for segment analytics.
   - *Deliverable*: Requirements document (Notion/Google Docs) with Plus, GDPR, and multilingual considerations.

2. **Analyze Merchant Data Patterns** (Analytics Service)
   - *Description*: Study purchase cycles and AOV to suggest default RFM thresholds.
   - *Tasks*:
     - Use Shopify GraphQL Admin API to calculate median purchase interval and AOV:
       - Small: AOV $20, Monetary 5 = $100+.
       - Medium: AOV $100, Monetary 5 = $500+.
       - Plus: AOV $500, Monetary 5 = $2,500+.
     - Validate with 5–10 merchant personas (e.g., pet store, fashion, electronics, Plus-scale retailer).
     - Store defaults in `program_settings.rfm_thresholds` (JSONB, e.g., `{"monetary_5": 2500}`) via Admin Service.
     - Cache AOV analysis in Redis Streams (`rfm:aov:{merchant_id}`, TTL 7d).
     - Cache configuration previews in Redis Streams (`rfm:preview:{merchant_id}`, TTL 1h) for US-MD12.
     - Track analysis via PostHog (`rfm_aov_analyzed`).
   - *Deliverable*: Default RFM thresholds for small, medium, and Plus merchants.

3. **Set Up Development Environment** (All Services)
   - *Description*: Configure microservices for RFM development.
   - *Tasks*:
     - Initialize branch (`feature/rfm-config`) in Nx monorepo.
     - **Frontend Service**: Set up Vite + React with Shopify Polaris, TypeScript, Tailwind CSS, i18next for multilingual support (`en`, `es`, `fr`).
     - **Analytics Service**: Configure NestJS with GraphQL client (`@shopify/shopify-api`), PostgreSQL (TypeORM, partitioned `customer_segments`, `rfm_segment_counts` materialized view), Redis (ioredis), PostHog SDK, and Bull queues.
     - **Admin Service**: Configure NestJS with PostgreSQL (TypeORM, `program_settings`), gRPC server, and LaunchDarkly SDK.
     - Install Shopify CLI for Rust Functions (`cargo shopify`) in Analytics Service.
     - Set up gRPC proto files for Analytics ↔ Admin, Analytics ↔ Points (`/points.v1/PointsService/RedeemCampaignDiscount`), Analytics ↔ Referrals, Analytics (`/analytics.v1/AnalyticsService/GetNudges`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`).
     - Configure Docker Compose for service containers (analytics, admin, frontend, redis, postgres).
     - Add `init.sql` to initialize `rfm_segment_counts` materialized view with daily refresh (`0 1 * * *`).
   - *Deliverable*: Dev environment with microservices, GraphQL, gRPC, partitioned database, PostHog, and feature flags.

### Phase 2: Backend Development (NestJS/TypeScript)
*Goal*: Build scalable backend logic for RFM calculations, tier assignments, and notifications across Analytics and Admin Services.

*Enhancements & Best Practices*:
- Use API versioning (`/api/v1/rfm/*` for Analytics, `/admin/v1/rfm/*` for Admin).
- Implement input validation (e.g., `recency < 365 days`) and GDPR-compliant encryption (AES-256).
- Optimize for Plus-scale with PostgreSQL partitioning, materialized views (`rfm_segment_counts`, daily refresh at `0 1 * * *`), and Redis Streams (`rfm:preview:{merchant_id}`, `campaign_discount:{campaign_id}`).
- Log errors to Sentry, monitor performance with Prometheus/Grafana.
- Use gRPC for Analytics ↔ Admin, Analytics ↔ Points, Analytics ↔ Referrals.

4. **Integrate Shopify APIs** (Analytics Service)
   - *Description*: Fetch customer/order data for RFM calculations.
   - *Tasks*:
     - Set up GraphQL Admin API client in Analytics Service:
       ```graphql
       query {
         customer(id: "gid://shopify/Customer/123") {
           id
           email
           orders(first: 100, after: $cursor) {
             edges {
               node { totalPrice, createdAt, status }
             }
           }
         }
       }
       ```
     - Create REST endpoints: `GET /api/v1/rfm/customers`, `GET /api/v1/rfm/orders` with pagination (batch 100).
     - Cache results in PostgreSQL (`customers`, `orders`) and Redis Streams (`rfm:customer:{id}`, TTL 24h).
     - Verify webhook signatures (HMAC-SHA256) for `orders/create`, `customers/data_request`, `customers/redact` with 5 retries (2s initial delay, exponential backoff).
     - Handle rate limits (2 req/s REST, 40 req/s Plus, 1–4 req/s Storefront) with exponential backoff.
     - Track API calls via PostHog (`shopify_api_called`).
     - Handle service downtime: Fallback to cached data in Redis if Shopify API unavailable.
   - *Deliverable*: GraphQL-based API service with webhook verification, caching, and error handling.

5. **Implement RFM Calculation Logic** (Analytics Service)
   - *Description*: Calculate RFM scores based on merchant thresholds (40% Recency, 30% Frequency, 30% Monetary).
   - *Tasks*:
     - Define TypeScript interfaces:
       ```typescript
       interface RFMConfig {
         recency: { [key: number]: { maxDays: number } };
         frequency: { [key: number]: { minOrders: number } };
         monetary: { [key: number]: { minSpend: number } };
       }
       interface RFMScore {
         recency: number;
         frequency: number;
         monetary: number;
         score: number; // Weighted average (40% Recency, 30% Frequency, 30% Monetary)
       }
       ```
     - Write NestJS service to compute RFM scores:
       - Recency: Compare `orders.createdAt` to current date.
       - Frequency: Count valid orders (`status = 'completed'`).
       - Monetary: Sum `totalPrice`, normalize by AOV.
       - Weighted score: `(0.4 * recency + 0.3 * frequency + 0.3 * monetary)`.
       - Store in `customers.rfm_score` (JSONB, e.g., `{"recency": 5, "frequency": 3, "monetary": 4, "score": 4.1}`).
     - Add constraints: `CHECK (rfm_score->>'recency' IN ('1', '2', '3', '4', '5'))`, `CHECK (rfm_score->>'score' BETWEEN 1 AND 5)`.
     - Add partial index: `idx_customers_rfm_score_at_risk` on `customers` (WHERE `rfm_score->>'score' < 2`) for At-Risk nudges.
     - Handle edge cases: Zero orders (R1, F1, M1), high AOV ($10,000+ → M5), negative AOV (returns, M1), partial orders (exclude cancelled), inactive (>365 days, R1).
     - Cache scores in Redis Streams (`rfm:customer:{id}`, TTL 24h).
     - Support multilingual nudges via gRPC (`/analytics.v1/AnalyticsService/GetNudges`, `nudges.title`, `nudges.description` as JSONB) for Frontend Service.
     - Use Bull queues for async calculations, priority for Plus merchants.
     - Handle service failures: Retry gRPC calls to Points Service (`/points.v1/PointsService/RedeemCampaignDiscount`) 3 times.
     - Log errors to Sentry (`rfm_calculation_failed`).
   - *Deliverable*: RFM calculation service with constraints, caching, and edge case handling.

6. **Develop Tier Assignment Logic** (Analytics Service)
   - *Description*: Assign customers to tiers based on RFM scores.
   - *Tasks*:
     - Create NestJS service to map RFM scores to tiers (`program_settings.rfm_thresholds` via gRPC from Admin Service):
       - Example: `{"name": "Gold", "rules": {"recency": ">=4", "frequency": ">=3", "monetary": ">=4"}}`.
       - Segments: Champions (R5, F4–5, M4–5), Loyal (R3–5, F3–5, M3–5), At-Risk (R1–2, F1–2, M1–2), New (R4–5, F1, M1–2), Inactive (R1, F1, M1).
     - Update `customers.rfm_score` and `customer_segments` (JSONB).
     - Partition `customer_segments` by `merchant_id` for Plus-scale.
     - Enforce RBAC via gRPC call to Auth Service (`merchants.staff_roles` JSONB, e.g., `{"role": "admin:full"}`).
     - Notify Points Service via gRPC (`/points.v1/PointsService/RedeemCampaignDiscount`) for reward assignments (e.g., 500 points for Champions, discounts based on `bonus_campaigns.conditions`).
     - Track assignments via PostHog (`rfm_tier_assigned`).
     - Log tier changes in `audit_logs` (Admin Service, action: `tier_assigned`).
   - *Deliverable*: Tier assignment service with RBAC, partitioning, and audit logging.

7. **Set Up Adjustment Scheduling** (Admin Service)
   - *Description*: Implement scheduled and event-based tier adjustments.
   - *Tasks*:
     - Use `@nestjs/schedule` for cron jobs: Daily (`0 0 * * *`) for <10,000 customers, weekly (`0 0 * * 0`) for 10,000+ (Plus), monthly/quarterly options.
     - Subscribe to `orders/create` webhook for event-based updates, 5 retries (2s initial delay, exponential backoff).
     - Implement grace period in `program_settings.config` (JSONB, e.g., `{"grace_period_days": 30}`).
     - Handle GDPR webhooks (`customers/data_request`, `customers/redact`) with cascade deletes (`customers`, `customer_segments`) in Analytics Service.
     - Use Bull queues with priority for Plus merchants, cache schedules in Redis Streams (`rfm:schedule:{merchant_id}`, TTL 7d).
     - Notify Analytics Service via gRPC to trigger RFM calculations.
     - Track scheduling via PostHog (`rfm_schedule_triggered`).
     - Handle service downtime: Queue jobs in Bull if Analytics Service unavailable.
   - *Deliverable*: Scheduling service with retries, GDPR compliance, and caching.

8. **Integrate Notifications** (Analytics Service)
   - *Description*: Enable tier change notifications via Klaviyo and Postscript.
   - *Tasks*:
     - Create endpoint: `POST /api/v1/rfm/notifications` with input validation (e.g., regex for `nudge.title`).
     - Integrate Klaviyo API (`POST /api/v2/events`) and Postscript API (`POST /sms/messages`) for multilingual templates (`email_templates.body`, `nudges.description` as JSONB).
     - Encrypt `email_events.recipient_email` (AES-256) for GDPR/CCPA.
     - Implement retries (5 attempts, 2s initial delay, exponential backoff) via Bull queues.
     - Trigger referral-based nudges via gRPC to Referrals Service (e.g., “Invite a friend!” for At-Risk).
     - Fetch nudges via gRPC (`/analytics.v1/AnalyticsService/GetNudges`).
     - Track via PostHog (`notification_sent`, `sms_nudge_sent`).
     - Add default templates: “Welcome to {tier}!” (Klaviyo), “Stay Active!” (Postscript for At-Risk).
   - *Deliverable*: Notification service with multilingual support, retries, and GDPR compliance.

### Phase 3: Shopify Functions (Rust)
*Goal*: Optimize RFM updates for performance-critical scenarios in Analytics Service.

*Enhancements & Best Practices*:
- Add Sentry logging for Rust function errors.
- Handle Shopify API rate limits (40 req/s for Plus) with exponential backoff.
- Use feature flags (LaunchDarkly) for real-time RFM updates.

9. **Develop RFM Score Update Function** (Analytics Service)
   - *Description*: Update RFM scores in real-time via Shopify Functions.
   - *Tasks*:
     - Set up Rust project with Shopify Function CLI (`cargo shopify`).
     - Implement logic:
       ```rust
       #[shopify_function]
       fn update_rfm_score(input: Input) -> Result<Output> {
           let order = input.order;
           let score = calculate_rfm(&order, input.merchant_aov)?;
           update_customer(&score, &input.customer_id)?;
           log::info!("RFM updated for customer {}", input.customer_id);
           Ok(Output { score })
       }
       ```
     - Update `customers.rfm_score` via webhook callbacks (`orders/create`).
     - Handle edge cases: Partial orders (exclude cancelled), negative AOV (M1).
     - Log errors to Sentry (`rfm_function_failed`), handle rate limits (40 req/s Plus).
     - Cache results in Redis Streams (`rfm:customer:{id}`, TTL 24h).
     - Notify Points Service via gRPC (`/points.v1/PointsService/RedeemCampaignDiscount`) for reward updates based on `bonus_campaigns.conditions`.
   - *Deliverable*: Deployed Shopify Function with logging, caching, and gRPC integration.

10. **Optimize for Large Stores** (Analytics Service)
    - *Description*: Ensure scalability for 50,000+ customers.
    - *Tasks*:
      - Implement batch processing in Rust (1,000 customers/batch).
      - Cache batch results in Redis Streams (`rfm:batch:{merchant_id}`, TTL 1h).
      - Cache campaign discounts in Redis Streams (`campaign_discount:{campaign_id}`, TTL 24h).
      - Test with simulated data (50,000 customers, 1,000 orders/hour) using k6.
      - Optimize PostgreSQL queries with materialized views (`rfm_segment_counts`, refreshed daily via `0 1 * * *`).
      - Scale Analytics Service independently using Kubernetes for Plus merchants.
   - *Deliverable*: Optimized test report for Plus-scale performance.

### Phase 4: Frontend Development (Vite/React)
*Goal*: Build an accessible, multilingual UI for RFM configuration in Frontend Service.

*Enhancements & Best Practices*:
- Ensure WCAG 2.1 compliance and mobile responsiveness with Polaris and Tailwind CSS.
- Track UI interactions via PostHog (e.g., `rfm_config_field_changed`).
- Use i18next for multilingual support (`en`, `es`, `fr`).
- Handle service downtime gracefully with fallback messages.

11. **Design RFM Configuration UI** (Frontend Service)
    - *Description*: Create a React form using Polaris for RFM settings.
    - *Tasks*:
      - Extend React component (`RFMConfigPage.tsx`) with Polaris, TypeScript, Tailwind CSS, and i18next.
      - Add inputs:
        - RFM thresholds (sliders/text fields, e.g., Recency 5: ≤7 days, Monetary 5: $2,500+ for Plus).
        - Tiers (name, RFM criteria, rewards: discounts, free shipping via `bonus_campaigns.conditions`).
        - Adjustment frequency (dropdown: daily, weekly, monthly, quarterly, event-based).
        - Notification settings (multilingual templates, toggle for Klaviyo/Postscript).
      - Use Polaris components (`TextField`, `Select`, `FormLayout`) with ARIA labels.
      - Implement real-time validation (e.g., “Monetary 5 must be > Monetary 4”) and feedback (e.g., “Invalid Recency value”).
      - Add progress checklist (e.g., “3/5 steps completed”) and “Reset to Defaults” button (AOV-based).
      - Fetch translations via Storefront API (`shop.locales`).
      - Handle Analytics/Admin Service downtime: Display fallback message (“Configuration temporarily unavailable”).
      - Track via PostHog (`rfm_config_field_changed`, `rfm_config_saved`).
   - *Deliverable*: Accessible, multilingual RFM configuration form with validation and fallback.

12. **Add Analytics Preview** (Frontend Service)
    - *Description*: Display segment sizes and metrics (US-MD12, I24a).
    - *Tasks*:
      - Create endpoint in Analytics Service: `GET /api/v1/rfm/preview` via gRPC (`/analytics.v1/AnalyticsService/PreviewRFMSegments`) for real-time segment sizes.
      - Use Chart.js for bar chart:
        ```javascript
        {
          type: "bar",
          data: {
            labels: ["Champions", "Loyal", "At-Risk", "New", "Inactive"],
            datasets: [{
              label: "Customers per Segment",
              data: [100, 300, 600, 200, 400],
              backgroundColor: ["#FFD700", "#C0C0C0", "#FF4500", "#32CD32", "#808080"],
              borderColor: ["#DAA520", "#A9A9A9", "#B22222", "#228B22", "#696969"],
              borderWidth: 1
            }]
          },
          options: {
            scales: { y: { beginAtZero: true } }
          }
        }
        ```
      - Cache previews in Redis Streams (`rfm:preview:{merchant_id}`, TTL 1h) (J9).
      - Fetch data via REST/gRPC from Analytics Service, fallback to cached data if service unavailable.
      - Track via PostHog (`rfm_preview_viewed`).
   - *Deliverable*: Analytics preview with Chart.js, caching, and fallback.

### Phase 5: Testing and Validation
*Goal*: Ensure reliability for small, medium, and Plus merchants across microservices.

*Enhancements & Best Practices*:
- Test edge cases (zero orders, high AOV, negative AOV, GDPR scenarios, service downtime).
- Simulate Plus-scale stores (50,000+ customers) with k6.
- Conduct concurrency tests for simultaneous RFM calculations across services.

13. **Unit Test Backend Logic** (Analytics and Admin Services)
    - *Description*: Test RFM calculations and tier assignments.
    - *Tasks*:
      - Write Jest tests for Analytics Service (RFM calculations) and Admin Service (configuration, scheduling):
        - Edge cases: Zero orders (R1, F1, M1), high AOV ($10,000+ → M5), negative AOV (M1), partial orders (exclude cancelled), inactive customers (>365 days).
        - Validation: Invalid thresholds (e.g., Recency <0), duplicate tier names.
        - Service failures: Simulate Analytics Service downtime, test gRPC retries (`/points.v1/PointsService/RedeemCampaignDiscount`, `/analytics.v1/AnalyticsService/GetNudges`).
      - Mock Shopify API for edge cases (e.g., invalid emails, cancelled orders).
      - Test GDPR webhook handling (`customers/redact` with cascade deletes) in Analytics Service.
   - *Deliverable*: Test suite with 85%+ coverage across services.

14. **Test Shopify Function** (Analytics Service)
    - *Description*: Validate Rust function for real-time updates.
    - *Tasks*:
      - Use Shopify CLI to test with sample (100 customers) and Plus-scale data (50,000 customers).
      - Verify PostgreSQL updates (`customers.rfm_score`, `rfm_segment_counts`) and rate limit handling (40 req/s).
      - Test edge cases: Partial orders, negative AOV, service downtime (fallback to Bull queues).
   - *Deliverable*: Tested Shopify Function for Plus-scale.

15. **Test UI and UX** (Frontend Service)
    - *Description*: Ensure intuitive, accessible UI.
    - *Tasks*:
      - Conduct usability testing with 5–10 merchants (2–3 Plus) via surveys/calls.
      - Verify WCAG 2.1 compliance (ARIA labels, keyboard navigation) and multilingual rendering (`en`, `es`, `fr`).
      - Test form submission, validation, and API integration (`POST /api/v1/rfm/config`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`).
      - Test service downtime scenarios: Display fallback messages for Analytics/Admin Service unavailability.
   - *Deliverable*: Accessible, multilingual UI with usability feedback.

16. **End-to-End Testing** (All Services)
    - *Description*: Test full workflow across microservices.
    - *Tasks*:
      - Simulate RFM configuration (Admin Service), calculations (Analytics Service), and UI rendering (Frontend Service) for 50,000 customers.
      - Trigger `orders/create` and GDPR webhooks (`customers/redact`) in Analytics Service.
      - Verify Klaviyo/Postscript notifications, Redis caching (`rfm:preview:{merchant_id}`, `campaign_discount:{campaign_id}`), and segment accuracy (`rfm_segment_counts`).
      - Test concurrency: Simultaneous RFM calculations for 5,000+ merchants across services.
      - Test inter-service communication: gRPC calls between Analytics, Admin, Points (`/points.v1/PointsService/RedeemCampaignDiscount`), and Referrals Services.
   - *Deliverable*: End-to-end test report for Plus-scale and GDPR compliance.

### Phase 6: Deployment and Documentation
*Goal*: Launch with rollback plan and comprehensive docs across microservices.

*Enhancements & Best Practices*:
- Use feature flags (LaunchDarkly) for gradual rollout of advanced RFM, nudges, and export.
- Include GDPR/CCPA and multilingual guidance in docs.
- Monitor deployment with Sentry (errors) and Prometheus/Grafana (performance).

17. **Deploy Feature** (All Services)
    - *Description*: Release RFM configuration to production.
    - *Tasks*:
      - Deploy using Docker Compose for Analytics, Admin, Frontend Services, Redis, and PostgreSQL; use Kubernetes for Plus-scale orchestration.
      - Enable feature flags (LaunchDarkly: `rfm_advanced`, `rfm_nudges`) for phased rollout.
      - Monitor via Sentry (errors, e.g., `rfm_calculation_failed`), Prometheus/Grafana (API latency, queue performance).
      - Implement rollback plan: Revert if errors >1% or latency >5s.
      - Set up 90-day backup retention for `audit_logs`, `nudge_events` in Admin Service.
   - *Deliverable*: Live deployment with monitoring and backup.

18. **Create Documentation** (Admin Service)
    - *Description*: Provide merchant and developer guides.
    - *Tasks*:
      - Write multilingual help article (`en`, `es`, `fr`) with GDPR tips (e.g., “Ensure customer consent for exports”) and best practices (e.g., “Avoid Recency <7 days for low-frequency stores”).
      - Include screenshots, 1–2 minute videos for RFM setup, nudges, and export.
      - Generate OpenAPI specs for `/api/v1/rfm/*` (Analytics Service) and `/admin/v1/rfm/*` (Admin Service) using NestJS decorators.
      - Document gRPC proto files for Analytics ↔ Admin, Analytics ↔ Points (`/points.v1/PointsService/RedeemCampaignDiscount`), Analytics ↔ Referrals, Analytics (`/analytics.v1/AnalyticsService/GetNudges`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`).
      - Document RFM calculation logic (weighted scoring: 40% Recency, 30% Frequency, 30% Monetary; edge cases) in developer guide.
   - *Deliverable*: Multilingual help article, OpenAPI specs, gRPC proto files, and developer guide.

19. **Pilot with Merchants** (All Services)
    - *Description*: Test with real merchants.
    - *Tasks*:
      - Recruit 5–10 merchants (2–3 Plus) via Shopify Reddit/Discord.
      - Monitor metrics (segment sizes via `rfm_segment_counts`, repeat purchases, nudge interactions) via PostHog across services.
      - Collect feedback via surveys/calls, focusing on Plus usability and RFM effectiveness.
   - *Deliverable*: Beta feedback report with Plus insights.

### Phase 7: Pricing and Rollout
*Goal*: Ensure accessibility and profitability across microservices.

*Enhancements & Best Practices*:
- Prioritize Plus merchants for advanced features (real-time updates, RBAC, custom notifications).
- Use feature flags for phased rollout to minimize disruptions.
- Track adoption and support queries via PostHog and Zendesk.

20. **Define Pricing Strategy** (Admin Service)
    - *Description*: Price for small, medium, and Plus merchants.
    - *Tasks*:
      - Basic RFM (2–3 tiers, monthly updates) in free plan.
      - Advanced RFM (real-time updates, RBAC, custom notifications, export, nudges) in paid plans ($15/month for small, $29/month for medium, $49/month for Plus).
      - Compare with competitors (e.g., LoyaltyLion: $399/month for similar features).
      - Redirect to https://x.ai/grok for pricing details.
   - *Deliverable*: Pricing model with Plus tier.

21. **Roll Out to All Merchants** (Frontend and Admin Services)
    - *Description*: Launch to all users.
    - *Tasks*:
      - Announce via email, in-app banner, and Klaviyo/Postscript campaigns (Frontend Service).
      - Provide multilingual setup wizard with tooltips and AOV-based defaults (Frontend Service).
      - Monitor adoption via PostHog (`rfm_wizard_completed`, `rfm_nudge_clicked`) and support queries via Zendesk (Admin Service).
      - Prioritize Plus merchants for support and advanced feature rollout (Admin Service).
   - *Deliverable*: Phased rollout campaign with Plus prioritization.

## Timeline and Resource Estimate
*Total Duration*: ~32–37 days (1–2 developers).
- Phase 1: 5–6 days (Planning, environment setup).
- Phase 2: 14–15 days (Backend APIs, calculations, notifications).
- Phase 3: 5–6 days (Rust Shopify Functions).
- Phase 4: 6–7 days (Frontend UI, analytics preview).
- Phase 5: 9–10 days (Testing and validation).
- Phase 6: 3–4 days (Deployment, documentation).
- Phase 7: 3 days (Pricing, rollout).

*Resources*: 1 full-stack developer (NestJS/React, Rust), 1 QA tester ($2,500), Grok AI for code review and documentation.

## Considerations for Merchants
- *Simplicity*: “Quick Setup” wizard (Frontend Service) with pre-filled AOV-based thresholds (e.g., Small: Monetary 5 = $100+, Plus: $2,500+), progress checklist, and real-time validation feedback.
- *Affordability*: Basic RFM free, advanced RFM $15–$49/month, competitive with LoyaltyLion ($399/month).
- *Usability*: Polaris UI with multilingual tooltips (`en`, `es`, `fr`), WCAG 2.1 compliance, mobile responsiveness (Frontend Service).
- *Scalability*: Optimized for 100–50,000+ customers with microservices (Analytics Service for calculations, Admin Service for config), partitioned `customer_segments`, materialized views (`rfm_segment_counts`, daily refresh `0 1 * * *`), and Redis Streams (`rfm:preview:{merchant_id}`, `campaign_discount:{campaign_id}`).
- *Support*: Live chat/email via Zendesk (Admin Service) with GDPR/CCPA guidance (e.g., “Log customer consent for exports in `audit_logs`”).

## Example Merchant Workflow
*Pet Store (AOV $40, 1,000 customers)*:
- Configuration: Recency: 5 = <30 days, Frequency: 5 = 5+ orders, Monetary: 5 = $200+; Tiers: Gold (R5, F4–5, M4–5), Silver (R3–4, F2–3, M2–3), Bronze (R1–2, F1, M1); Monthly updates, 30-day grace period; Klaviyo notifications (“Welcome to Gold!”).
- Outcome: 10% in Gold, 25% repeat purchase increase, 10% nudge interaction rate.

*Electronics Retailer (AOV $500, 50,000 customers)*:
- Configuration: Recency: 5 = <60 days, Frequency: 5 = 10+ orders, Monetary: 5 = $2,500+; Tiers: Platinum (R5, F5, M5), Gold (R4–5, F4–5, M4–5); Real-time updates, RBAC for staff, Postscript SMS nudges (“Stay Active!” for At-Risk).
- Outcome: 5% in Platinum, 20% engagement increase, 90%+ query performance under 1s.

## Database Schema
- **Tables**:
  - `customers` (customer_id, email ENCRYPTED, first_name, last_name, rfm_score ENCRYPTED JSONB, vip_tier_id JSONB) [Analytics Service]
  - `customer_segments` (segment_id, merchant_id, rules JSONB, name JSONB) [Analytics Service]
  - `nudges` (nudge_id, merchant_id, type CHECK('at-risk', 'loyal', 'new', 'inactive'), title JSONB, description JSONB, is_enabled BOOLEAN) [Analytics Service]
  - `nudge_events` (event_id, customer_id, nudge_id, action CHECK('view', 'click', 'dismiss'), created_at) [Analytics Service]
  - `program_settings` (merchant_id, config JSONB, rfm_thresholds JSONB, branding JSONB) [Admin Service]
  - `email_templates` (template_id, merchant_id, type CHECK('tier_change', 'nudge'), subject JSONB, body JSONB) [Analytics Service]
  - `email_events` (event_id, merchant_id, event_type CHECK('sent', 'failed'), recipient_email ENCRYPTED) [Analytics Service]
  - `audit_logs` (id UUID, admin_user_id, action, target_table, target_id, created_at) [Admin Service]
  - `bonus_campaigns` (campaign_id, merchant_id, name, type, multiplier, conditions JSONB) [Points Service]
- **Indexes**: `customers(rfm_score)`, `customer_segments(merchant_id)`, `nudges(merchant_id)`, `nudge_events(customer_id)`, `email_templates(merchant_id)`, `audit_logs(admin_user_id)`, `bonus_campaigns(merchant_id, type)` [Analytics/Admin/Points Services]
- **Partial Indexes**: `idx_customers_rfm_score_at_risk` on `customers` (WHERE `rfm_score->>'score' < 2`) for At-Risk nudges [Analytics Service].
- **Materialized Views**: `rfm_segment_counts` (merchant_id, segment_name, customer_count, last_refreshed, INDEX `idx_rfm_segment_counts_merchant_id`) for analytics performance, refreshed daily (`0 1 * * *`) (I24a, US-MD12, US-BI5) [Analytics Service].
- **Partitioning**: `customer_segments`, `nudge_events`, `email_events`, `bonus_campaigns` by `merchant_id` [Analytics/Points Services].

## Next Steps
1. Start Phase 1: Finalize requirements (Admin Service), analyze data (Analytics Service), and set up environment with `rfm_segment_counts` initialization in `init.sql` (All Services) (5–6 days).
2. Prioritize Backend: Build GraphQL integration (`GET /api/v1/rfm/customers` in Analytics Service), RFM calculation (Analytics Service), and notification services with gRPC (`/analytics.v1/AnalyticsService/GetNudges`, `/points.v1/PointsService/RedeemCampaignDiscount`).
3. Test Early: Simulate RFM configs in Shopify sandbox with 100–50,000 customers across services.
4. Seek Feedback: Share UI prototype (`RFMConfigPage.tsx` in Frontend Service) with 5–10 merchants (2–3 Plus) via Shopify Reddit/Discord, focusing on usability and Plus-scale performance.

## Summary Table of Key Suggestions
| Area         | Suggestion                                                                 |
|--------------|---------------------------------------------------------------------------|
| Planning     | Include Plus merchants, GDPR/CCPA, multilingual support, PostHog tracking   |
| Microservices| Analytics (RFM calculations, `/analytics.v1/AnalyticsService/GetNudges`, `/analytics.v1/AnalyticsService/PreviewRFMSegments`), Admin (configuration), Frontend (UI), Points (`/points.v1/PointsService/RedeemCampaignDiscount`), gRPC communication |
| Backend      | GraphQL/REST APIs, partitioning, RBAC, input validation, Redis Streams (`rfm:preview:{merchant_id}`, `campaign_discount:{campaign_id}`), Bull queues |
| Rust         | Shopify Functions with Sentry logging, rate limit handling, batch processing |
| Frontend     | WCAG 2.1 compliance, i18next multilingual UI, Chart.js previews (US-MD12), Polaris UI, service fallback |
| Analytics    | Real-time previews (`rfm:preview:{merchant_id}`), materialized views (`rfm_segment_counts`, daily refresh `0 1 * * *`) |
| Testing      | Edge cases (zero orders, negative AOV, service downtime), Plus-scale (50,000 customers), concurrency |
| Deployment   | Docker Compose, Kubernetes for Plus, feature flags (LaunchDarkly), Sentry/Prometheus monitoring, 90-day backups |
| Docs         | Multilingual guides, GDPR tips, OpenAPI specs, gRPC proto files (`/analytics.v1/AnalyticsService/GetNudges`, `/points.v1/PointsService/RedeemCampaignDiscount`), developer guide |
| Rollout      | Phased rollout with Plus prioritization, PostHog/Zendesk tracking           |