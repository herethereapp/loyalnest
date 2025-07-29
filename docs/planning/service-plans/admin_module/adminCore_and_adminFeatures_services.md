# Internal Admin Module
LoyalNest App

## Overview
This document details the internal admin module for the LoyalNest Shopify app, enabling platform-level management of merchants, points, integrations, analytics, customer data imports, GDPR/CCPA compliance, rate limit monitoring, and queue monitoring. It supports Shopify Plus multi-user access (50,000+ customers, 10,000 orders/hour during Black Friday surges) with RBAC, including scoped roles for granular control. The module integrates with `AdminCore`, `AdminFeatures`, `Analytics`, `Auth`, `Points`, `Referrals`, `Users`, `Roles`, and `RFM` services, leveraging NestJS, Rust/Wasm, PostgreSQL (JSONB, range partitioning), TimescaleDB, Redis Cluster/Streams, Bull queues, Kafka, and Loki + Grafana for scalability and maintainability within an Nx monorepo. Enhancements include scoped RBAC, real-time alerting, merchant timelines, undo actions, additional KPIs, predictive suggestions, queue monitoring, and QA APIs, aligning with the 39.5-week TVP timeline (ending February 17, 2026) and ensuring reliability, usability, and compliance with GDPR/CCPA, Shopify APIs (2025-01), and multilingual support (`en`, `es`, `fr`, `de`, `pt`, `ja` in Phases 2–5; `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL) in Phase 6).

## Features
- **Overview** (AdminCore Service):
  - Display metrics: Merchant count, points issued/redeemed, referral ROI (7%+ SMS conversion target), RFM segments (e.g., High-Value Loyal, At-Risk, New Customers via `rfm-service`), customer import status, rate limit usage (Shopify API: 2 req/s standard, 40 req/s Plus), queue backlog (`/admin/rate-limits/queue`), median points adjustment latency, RFM config-to-export rate, import retry success rate, integration health (Shopify, Klaviyo/Postscript, Square).
  - Chart.js visualizations: Trends for points issued/redeemed, RFM segment counts (via `rfm-service` gRPC `/rfm.v1/RFMService/GetSegmentCounts`), import success rate, points adjustment latency, rate limit usage, and queue metrics, with drag-and-drop customization in `AdminOverview.tsx`.
  - Predictive analytics: Merchant churn prediction via gRPC `/analytics.v1/AnalyticsService/PredictChurn` using `orders`, `rfm_segment_counts`, and `rfm_segment_deltas` (incremental updates on `orders/create`).
  - Rule-based suggestions: e.g., “Plan limit will be exceeded in 7 days” or “Increase SMS referral limit for 10% uplift” based on PostHog usage data (`plan_limit_warning`, `referral_fallback_triggered`), displayed in `AdminOverview.tsx` with Polaris `Banner`.
  - APIs: `GET /admin/v1/overview`, gRPC: `/admin.v1/AdminCoreService/GetOverview`.
  - Success Metrics: 90%+ query performance under 1s, 20%+ dashboard customization rate, 80%+ suggestion engagement rate (tracked via PostHog: `admin_suggestion_clicked`).

- **Merchants** (AdminCore Service):
  - List: `merchant_id`, `shopify_domain`, `plan_id` (Free: 300 orders, Plus: 500 orders at $29/month, Enterprise: custom), `status` (active, suspended, trial), `staff_roles` (via `roles-service` gRPC `/roles.v1/RolesService/GetRoles`), `language` (JSONB: `en`, `es`, `fr`, `de`, `pt`, `ja`).
  - Search: Fuzzy matching by domain, name using PostgreSQL `tsvector` (via `users-service` gRPC `/users.v1/UsersService/SearchMerchants`).
  - Actions: View details, activate/suspend, adjust points (via `points-service`), GDPR export/delete (`customers/data_request`, `customers/redact` via `users-service`), bulk plan upgrades/downgrades, customer import (via `users-service`), undo bulk plan changes/points adjustments (stored in `audit_logs` with `reverted` flag).
  - Timeline: Chronological view of merchant actions (e.g., imports, config changes, points adjustments, rate limit breaches, Square syncs) in `MerchantsPage.tsx` using Chart.js/Polaris.
  - Per-merchant rate limit tracking: Shopify API (2 req/s standard, 40 req/s Plus) and integration usage (Klaviyo/Postscript, Square), cached in Redis Streams (`admin:rate_limits:{merchant_id}`, `admin:endpoint_limits:{merchant_id}:{endpoint}`, TTL 1h), visualized with Chart.js in `RateLimitsPage.tsx`.
  - APIs: `GET /admin/v1/merchants`, `POST /admin/v1/merchants/search`, `POST /admin/v1/merchants/{id}/adjust-points`, `POST /admin/v1/merchants/bulk`, `POST /admin/v1/merchants/{id}/undo`, gRPC: `/users.v1/UsersService/ImportCustomers`.
  - Error Handling: `INVALID_MERCHANT_ID`, `UNAUTHORIZED`, `RATE_LIMIT_EXCEEDED` (429), `UNDO_NOT_PERMITTED`.
  - RBAC: `admin:full` for all actions, `admin:support` for view/search, `admin:points` for points adjustments, scoped roles (`admin:merchants:view:shopify_plus`, `admin:merchants:edit:plan`) via `roles-service`.
  - Success Metrics: 95%+ action success rate, 80%+ timeline usage rate (tracked via PostHog: `merchant_timeline_viewed`).

- **Admin Users** (AdminCore Service, Users Service, Roles Service):
  - Manage users in `users-service` (`users` table: id, username UNIQUE, email ENCRYPTED with AES-256 via pgcrypto, password, created_at) with RBAC roles in `roles-service` (`roles` table: role_name, permissions JSONB with `["admin:full", "admin:analytics", "admin:support", "admin:points", "admin:merchants:view:shopify_plus", "admin:merchants:edit:plan"]`).
  - MFA via Auth0, session timeout (30 min), IP whitelisting (internal IPs cached in Redis: `admin:ip_whitelist:{merchant_id}`, TTL 7d).
  - Anomaly detection: Flag unusual actions (e.g., >100 points adjustments/hour, >3 rate limit breaches/hour), log to PostHog (`admin_action_anomaly`), notify `admin:full` via Slack/PagerDuty (AWS SNS webhook).
  - RBAC for Plus: Multi-user access with role-based restrictions (e.g., `admin:analytics` for read-only RFM, `admin:full` for imports, campaigns, user management) via `roles-service` gRPC `/roles.v1/RolesService/GetPermissions`.
  - APIs: `POST /admin/v1/users`, `PUT /admin/v1/users/{id}`, `DELETE /admin/v1/users/{id}`, gRPC: `/users.v1/UsersService/CreateAdminUser`, `/roles.v1/RolesService/AssignRole`.
  - Error Handling: `DUPLICATE_USERNAME`, `INVALID_EMAIL`, `UNAUTHORIZED`, `INVALID_ROLE`.
  - Success Metrics: 100% secure user management, 95%+ MFA adoption (tracked via PostHog: `admin_mfa_enabled`).

- **Logs** (AdminCore Service):
  - View `api_logs` (route, method, status_code, created_at), `audit_logs` (admin_user_id, action CHECK: `gdpr_processed`, `rfm_export`, `customer_import`, `customer_import_completed`, `campaign_discount_issued`, `tier_assigned`, `config_updated`, `rate_limit_viewed`, `undo_action`, `referral_fallback_triggered`, `square_sync_triggered`, target_table, target_id, created_at, reverted BOOLEAN).
  - Real-time streaming via WebSocket (`/admin/v1/logs/stream`), cached in Redis Streams (`admin:logs:stream:{merchant_id}`, TTL 30m).
  - Notification Status Monitoring: Track referral notification status (`sent`, `failed`) in `email_events`, linked to `email_templates` (JSONB, `fallback_language: en`).
  - Filters: Date, route, user, action, notification status (real-time support via WebSocket).
  - Log Replay: Reprocess logs for QA via `POST /admin/v1/logs/replay` (RBAC: `admin:full`), supported by `replay-audit.ts` script.
  - APIs: `GET /admin/v1/logs/api`, `GET /admin/v1/logs/audit`, `GET /admin/v1/logs/stream`, `POST /admin/v1/logs/replay`.
  - Success Metrics: 90%+ query performance under 1s, 95%+ log replay success rate (tracked via PostHog: `admin_log_replay`).

- **Integration Health** (AdminFeatures Service):
  - Monitor Shopify, Klaviyo/Postscript (with AWS SES fallback), Square (with manual sync: `/admin/integrations/square/sync`), Yotpo/Judge.me, Klaviyo/Mailchimp (`integrations.status`, `last_checked`, `error_details` JSONB).
  - Real-time alerts in dashboard (e.g., “Square POS sync failed”) and proactive Slack/Email/PagerDuty alerts via AWS SNS, tracked via PostHog (`admin_integration_alert_sent`, `referral_fallback_triggered`, `square_sync_triggered`).
  - Health checks: `/admin/v1/integrations/health`, `/admin/integrations/square`, `/admin/integrations/square/sync`.
  - Kill Switch: Disable integrations (`US-AM15`) if errors persist (e.g., >3 timeouts in 5s).
  - Success Metrics: 95%+ integration uptime, 90%+ alert resolution within 1 hour.

- **Rate Limit Monitoring** (AdminFeatures Service):
  - Display Shopify API (2 req/s standard, 40 req/s Plus, 1–4 req/s Storefront) and integration rate limits per merchant and endpoint, cached in Redis Streams (`admin:rate_limits:{merchant_id}`, `admin:endpoint_limits:{merchant_id}:{endpoint}`, TTL 1h).
  - Queue monitoring for non-critical tasks (e.g., customer imports, RFM exports) via Bull queues (`/admin/rate-limits/queue`), visualized in `RateLimitsPage.tsx` with Chart.js.
  - Alerts for breaches (>3/hour) via Slack/PagerDuty (AWS SNS webhook), tracked via PostHog (`rate_limit_viewed`, `rate_limit_breach`).
  - APIs: `GET /admin/v1/rate-limits`, `GET /admin/v1/rate-limits/queue`, gRPC: `/admin.v1/AdminFeaturesService/GetRateLimits`.
  - Success Metrics: 90%+ rate limit query performance under 1s, 95%+ queue operation success rate.

- **Platform Settings** (AdminFeatures Service):
  - Configure plans (Free: 300 orders, Plus: 500 orders at $29/month, Enterprise: custom), global settings, RFM thresholds (via `rfm-service` gRPC `/rfm.v1/RFMService/UpdateThresholds`), notification templates (JSONB, `fallback_language: en`, RTL for `ar`, `he`), multi-currency settings (`merchant_settings.currencies: JSONB`).
  - APIs: `POST /admin/v1/settings`, `GET /admin/v1/settings`, gRPC: `/admin.v1/AdminFeaturesService/UpdateCurrencySettings`, `/rfm.v1/RFMService/UpdateThresholds`.
  - RBAC: `admin:full` for updates, `admin:analytics` for read-only, via `roles-service`.
  - Success Metrics: 95%+ settings update success, 90%+ notification template usage.

- **Login as Merchant** (AdminCore Service):
  - Generate temporary JWT (1-hour expiry) for merchant access, restricted by RBAC via `roles-service`.
  - APIs: `POST /admin/v1/merchants/{id}/login`, gRPC: `/users.v1/UsersService/LoginAsMerchant`.
  - RBAC: `admin:full` only.
  - Success Metrics: 90%+ login success rate (tracked via PostHog: `admin_login_as_merchant`).

- **RFM Configuration and Export** (AdminFeatures Service, RFM Service):
  - Configure RFM thresholds (Recency: 7–90 days, Frequency: 1–10 orders, Monetary: $50–$2,500+) via `rfm-service` gRPC `/rfm.v1/RFMService/UpdateThresholds`, stored in `program_settings.rfm_thresholds: JSONB`.
  - Incremental updates via `rfm_segment_deltas` on `orders/create`, daily refresh of `rfm_segment_counts` materialized view (`0 1 * * *`) via `rfm-service`.
  - Export segments as CSV/JSON, async processing via Bull queues, tracked in `audit_logs` (`rfm_export`) via `rfm-service` gRPC `/rfm.v1/RFMService/ExportSegments`.
  - APIs: `POST /admin/v1/rfm/config`, `POST /admin/v1/rfm/export`, `/admin/v1/rfm/visualizations`, gRPC: `/rfm.v1/RFMService/GetSegmentCounts`, `/rfm.v1/RFMService/ExportSegments`, `/rfm.v1/RFMService/GetVisualizations`.
  - Visualizations: Chart.js scatter plot (Recency vs. Monetary) in `AnalyticsPage.tsx`.
  - RBAC: `admin:full`, `admin:analytics` for configuration/export, via `roles-service`.
  - Error Handling: `RFM_CONFIG_INVALID`, `EXPORT_FAILED`.
  - Success Metrics: 80%+ config completion, 90%+ export completion under 5s, 80%+ visualization usage (tracked via PostHog: `rfm_preview_viewed`, `visualization_viewed`).

- **Customer Data Import** (AdminFeatures Service, Users Service):
  - Async CSV import with validation (email, shopify_customer_id) via `users-service` gRPC `/users.v1/UsersService/ImportCustomers`, GDPR-compliant AES-256 encryption (pgcrypto).
  - Real-time progress tracking via WebSocket (`/admin/v1/imports/stream`) in `MerchantsPage.tsx` using Polaris `ProgressBar`, logged in `audit_logs` (`customer_import`, `customer_import_completed`).
  - APIs: `POST /admin/v1/customers/import`, gRPC: `/users.v1/UsersService/ImportCustomers`.
  - RBAC: `admin:full` only, via `roles-service`.
  - Success Metrics: 95%+ import success rate, 90%+ import completion under 10s (tracked via PostHog: `customer_import_completed`).

- **Queue Monitoring** (AdminFeatures Service):
  - Monitor Bull queues (retry count, DLQ status, time-in-queue) for RFM exports (via `rfm-service`), customer imports (via `users-service`), and rate limit throttling (`rate_limit_queue:{merchant_id}`).
  - UI in `QueuesPage.tsx` with Polaris components, showing queue metrics (jobs in queue, retry count, DLQ status), visualized with Chart.js.
  - APIs: `GET /admin/v1/queues`, gRPC: `/admin.v1/AdminFeaturesService/GetQueueMetrics`.
  - Success Metrics: 95%+ queue operation success rate, 90%+ queue monitoring usage (tracked via PostHog: `queue_metrics_viewed`).

- **Event Simulation** (AdminFeatures Service):
  - Simulate campaign/referral events for QA via `POST /admin/v1/events/simulate` (e.g., `campaign_discount_issued`, `referral_sent`, `referral_fallback_triggered`, `square_sync_triggered`).
  - APIs: `POST /admin/v1/events/simulate`, gRPC: `/admin.v1/AdminFeaturesService/SimulateEvent`.
  - RBAC: `admin:full` only, via `roles-service`.
  - Success Metrics: 95%+ simulation success rate (tracked via PostHog: `admin_event_simulated`).

- **Onboarding Progress** (AdminFeatures Service):
  - Track merchant setup tasks (RFM setup, referrals, checkout extensions) in `setup_tasks` table, visualized in `AdminPage.tsx` with Polaris `ProgressBar`.
  - Real-time updates via WebSocket (`/admin/v1/setup/stream`), cached in Redis (`setup_tasks:{merchant_id}`, TTL 7d).
  - APIs: `GET /admin/v1/setup/stream`, gRPC: `/admin.v1/AdminFeaturesService/StreamSetupProgress`.
  - Success Metrics: 80%+ onboarding completion rate (tracked via PostHog: `setup_progress_viewed`).

## Technical Details
- **Backend** (AdminCore Service, AdminFeatures Service, Users Service, Roles Service, RFM Service, Auth Service):
  - NestJS for REST APIs (`/admin/v1/*`), gRPC for inter-service communication (`/admin.v1/*`, `/users.v1/*`, `/roles.v1/*`, `/rfm.v1/*`, `/auth.v1/*`, `/analytics.v1/*`).
  - Shopify GraphQL Admin API (2025-01) for merchant/customer data, webhooks (`customers/data_request`, `customers/redact`, 3 retries).
  - Bull queues for async tasks (RFM exports via `rfm-service`, customer imports via `users-service`, rate limit throttling), 5 retries (2s initial delay), with DLQ and `/admin/v1/queues/reprocess` endpoint (RBAC: `admin:full`).
  - Circuit breakers (`nestjs-circuit-breaker`) for gRPC calls (`/admin.v1/AdminCoreService/GetOverview`, `/users.v1/UsersService/ImportCustomers`, `/roles.v1/RolesService/AssignRole`, `/rfm.v1/RFMService/GetSegmentCounts`, `/auth.v1/AuthService/CreateAdminUser`, `/analytics.v1/AnalyticsService/PredictChurn`).
  - Error Handling: `UNAUTHORIZED`, `INVALID_INPUT`, `QUEUE_FULL`, `RATE_LIMIT_EXCEEDED` (429), `UNDO_NOT_PERMITTED`, `INVALID_MERCHANT_ID`, `DUPLICATE_USERNAME`, `INVALID_EMAIL`, `INVALID_ROLE`, `RFM_CONFIG_INVALID`, `EXPORT_FAILED`.
  - gRPC Endpoints:
    - `/admin.v1/AdminCoreService/GetOverview`
    - `/admin.v1/AdminCoreService/GetAuditLogs`
    - `/admin.v1/AdminCoreService/HandleGDPRRequest`
    - `/admin.v1/AdminFeaturesService/GetRateLimits`
    - `/admin.v1/AdminFeaturesService/GetQueueMetrics`
    - `/admin.v1/AdminFeaturesService/SimulateEvent`
    - `/admin.v1/AdminFeaturesService/UpdateNotificationTemplate`
    - `/admin.v1/AdminFeaturesService/UpdateCurrencySettings`
    - `/admin.v1/AdminFeaturesService/StreamSetupProgress`
    - `/users.v1/UsersService/CreateAdminUser`
    - `/users.v1/UsersService/ImportCustomers`
    - `/users.v1/UsersService/SearchMerchants`
    - `/users.v1/UsersService/LoginAsMerchant`
    - `/roles.v1/RolesService/AssignRole`
    - `/roles.v1/RolesService/GetRoles`
    - `/roles.v1/RolesService/GetPermissions`
    - `/rfm.v1/RFMService/UpdateThresholds`
    - `/rfm.v1/RFMService/GetSegmentCounts`
    - `/rfm.v1/RFMService/ExportSegments`
    - `/rfm.v1/RFMService/GetVisualizations`
    - `/auth.v1/AuthService/CreateAdminUser`

- **Frontend** (Frontend Service):
  - React components (`AdminOverview.tsx`, `MerchantsPage.tsx`, `LogsPage.tsx`, `UsersPage.tsx`, `IntegrationsPage.tsx`, `RateLimitsPage.tsx`, `QueuesPage.tsx`, `AnalyticsPage.tsx`) using Vite, Polaris, Tailwind CSS, App Bridge.
  - Rate limit monitoring in `RateLimitsPage.tsx` with real-time Shopify API and per-endpoint limits, visualized with Chart.js.
  - Queue monitoring in `QueuesPage.tsx` with Polaris components for Bull queue metrics (jobs, retries, DLQ status).
  - Merchant timeline in `MerchantsPage.tsx` using Chart.js/Polaris for action history (imports, config changes, points adjustments, Square syncs).
  - Onboarding progress in `AdminPage.tsx` with Polaris `ProgressBar` and WebSocket updates.
  - Dynamic locale detection (`navigator.language`) with Polaris `Select` override, cached in Redis (`admin:locale:{user_id}`, TTL 7d).
  - i18next for multilingual support (`en`, `es`, `fr`, `de`, `pt`, `ja` in Phases 2–5; `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL) in Phase 6), validated with 2–3 native speakers per language for 90%+ accuracy, WCAG 2.1 AA compliant.

- **Database** (PostgreSQL, TimescaleDB):
  - Tables (via `users-service`, `roles-service`, `rfm-service`, and others):
    - `users` (id, username UNIQUE, email ENCRYPTED with AES-256, password, created_at)
    - `roles` (role_id, role_name UNIQUE, permissions JSONB with `["admin:full", "admin:analytics", "admin:support", "admin:points", "admin:merchants:view:shopify_plus", "admin:merchants:edit:plan"]`, created_at)
    - `api_logs` (id, merchant_id, route, method, status_code, created_at)
    - `audit_logs` (id UUID, admin_user_id, action CHECK: `gdpr_processed`, `rfm_export`, `customer_import`, `customer_import_completed`, `campaign_discount_issued`, `tier_assigned`, `config_updated`, `rate_limit_viewed`, `undo_action`, `referral_fallback_triggered`, `square_sync_triggered`, target_table, target_id, created_at, reverted BOOLEAN)
    - `integrations` (integration_id, merchant_id, type CHECK: `shopify`, `klaviyo`, `postscript`, `square`, `yotpo`, `judge.me`, `mailchimp`, status CHECK: `ok`, `error`, settings JSONB, api_key ENCRYPTED with AES-256)
    - `rfm_segment_counts` (merchant_id, segment_name, customer_count, last_refreshed)
    - `rfm_segment_deltas` (merchant_id, customer_id, segment_change, updated_at)
    - `customer_segments` (customer_id, merchant_id, segment_name, updated_at)
    - `email_events` (event_id, merchant_id, event_type CHECK: `sent`, `failed`, recipient_email ENCRYPTED with AES-256)
    - `setup_tasks` (merchant_id, task_name, status, completed_at)
    - `merchant_settings` (merchant_id, currencies JSONB)
  - Indexes: `users(username, email)`, `roles(role_name)`, `api_logs(merchant_id, route)`, `audit_logs(admin_user_id)`, `integrations(merchant_id)`, `rfm_segment_counts(merchant_id)`, `rfm_segment_deltas(merchant_id)`, `customer_segments(merchant_id)`, `email_events(merchant_id)`, `setup_tasks(merchant_id)`, `tsvector` for merchant search (`merchants.name`, `merchants.shopify_domain`).
  - Partitioning: `api_logs`, `audit_logs` by `merchant_id`; `rfm_segment_deltas` by `updated_at`.
  - Encryption: AES-256 via pgcrypto for `users.email`, `integrations.api_key`, `email_events.recipient_email`, quarterly key rotation via AWS KMS.

- **Caching** (Redis Cluster):
  - Streams: `admin:metrics:{period}` (TTL 6h), `admin:logs:{merchant_id}` (TTL 30m), `admin:logs:stream:{merchant_id}` (TTL 30m), `admin:rate_limits:{merchant_id}` (TTL 1h), `admin:endpoint_limits:{merchant_id}:{endpoint}` (TTL 1h), `admin:locale:{user_id}` (TTL 7d), `setup_tasks:{merchant_id}` (TTL 7d), `admin:ip_whitelist:{merchant_id}` (TTL 7d).
  - Dead-letter queue for GDPR webhook retries (3 retries) and customer imports (5 retries).

- **Event Processing** (Kafka, PostHog):
  - Events: `admin_action_anomaly`, `admin_suggestion_clicked`, `merchant_timeline_viewed`, `admin_mfa_enabled`, `admin_log_replay`, `admin_integration_alert_sent`, `referral_fallback_triggered`, `square_sync_triggered`, `rate_limit_viewed`, `rate_limit_breach`, `customer_import_completed`, `rfm_preview_viewed`, `visualization_viewed`, `queue_metrics_viewed`, `admin_event_simulated`, `admin_login_as_merchant`, `setup_progress_viewed`.

- **Feature Flags**: LaunchDarkly for “Login as Merchant”, RFM export, integration health, customer import, queue monitoring, event simulation, onboarding progress, and undo actions.

## Integrations
- **Shopify**: GraphQL Admin API (2025-01), `customers/data_request`, `customers/redact` webhooks (3 retries, Redis dead-letter queue).
- **Klaviyo/Postscript**: Monitor health via API calls (`/v2/campaigns`, `/sms/messages`), track notification status in `email_events`, AWS SES fallback for referral notifications (`referral_fallback_triggered`), proactive alerts via AWS SNS (Slack, Email, PagerDuty).
- **Square**: POS integration with health checks (`/admin/v1/integrations/square`), manual sync (`/admin/integrations/square/sync`), alerts for sync failures (`square_sync_triggered`).
- **Yotpo/Judge.me**: Points-for-reviews integration, health checks.
- **Klaviyo/Mailchimp**: Automated loyalty email flows, health checks.
- **Rate Limiting**: Shopify API (2 req/s standard, 40 req/s Plus, 1–4 req/s Storefront), Klaviyo/Postscript (5s timeout, 3 retries), Bull queues for non-critical tasks (`rate_limit_queue:{merchant_id}`).

## Performance Optimizations
- **Redis Streams**: Cache metrics, logs, integration health, rate limits, queue metrics, onboarding progress (`admin:rate_limits:{merchant_id}`, `admin:endpoint_limits:{merchant_id}:{endpoint}`, `setup_tasks:{merchant_id}`).
- **PostgreSQL/TimescaleDB**: Connection pooling for 10,000+ queries, range partitioning for `api_logs`, `audit_logs`, `rfm_segment_deltas`, materialized views for `rfm_segment_counts` with incremental updates.
- **Load Testing**: k6 for 5,000 merchants, 50,000 customers, Black Friday surges (10,000 orders/hour, 100 concurrent admin actions).
- **Circuit Breakers**: `nestjs-circuit-breaker` for gRPC calls to prevent cascading failures.
- **Incremental RFM Updates**: Real-time updates via `rfm_segment_deltas` on `orders/create`, reducing daily batch processing load (`0 1 * * *`).

## Security and Compliance
- **GDPR/CCPA**: Encrypt `users.email`, `integrations.api_key`, `email_events.recipient_email` with AES-256 (pgcrypto). Cascade deletes for `customers/redact` webhooks. Log `gdpr_processed` in `audit_logs`. 90-day backup retention for `audit_logs`, `api_logs` in Backblaze B2.
- **Disaster Recovery**: PostgreSQL/TimescaleDB point-in-time recovery (RTO: 4 hours, RPO: 1 hour), Redis AOF persistence with daily Backblaze B2 backups, validated weekly via `restore.sh`.
- **Audit Logging**: Log all admin actions (points adjustments, user management, RFM config/export, customer import, campaign discounts, rate limit views, queue monitoring, event simulation, undo actions, Square syncs, referral fallbacks) in `audit_logs`.
- **RBAC**: Enforce via `roles-service` for all actions:
  - `admin:full`: All actions (user management, points adjustments, imports, campaigns, RFM config/export, rate limit/queue monitoring, event simulation, onboarding, Square sync).
  - `admin:analytics`: Read-only for RFM config/export, visualizations, queue metrics.
  - `admin:support`: Read-only for merchants, logs, integration health.
  - `admin:points`: Points adjustments, campaign management, VIP tiers.
  - `admin:merchants:view:shopify_plus`: View Shopify Plus merchant details.
  - `admin:merchants:edit:plan`: Bulk plan upgrades/downgrades, undo actions.
- **Security**: JWT (1-hour expiry), MFA (Auth0), IP whitelisting (`admin:ip_whitelist:{merchant_id}`), session timeout (30 min), anomaly detection (>100 points adjustments/hour, >3 rate limit breaches/hour), rate-limiting for `/admin/v1/*` (100 req/min per user), OWASP ZAP (ECL: 256) for XSS, SQL injection, and API vulnerabilities.

## Testing
- **Unit**: Jest for APIs, RBAC logic (via `roles-service`), export processing (via `rfm-service`), customer import (via `users-service`), rate limit/queue monitoring, anomaly detection, event simulation, undo actions, onboarding progress, i18next translation fallbacks (`en`, `es`, `fr`, `de`, `pt`, `ja`).
- **Integration**: Shopify, Klaviyo/Postscript (with AWS SES fallback), Square (with manual sync), Yotpo/Judge.me, Klaviyo/Mailchimp APIs, customer import workflows (via `users-service`), RFM processing (via `rfm-service`), queue monitoring, event simulation.
- **E2E**: Cypress for admin dashboard, login as merchant, logs, RFM exports, rate limit/queue monitoring, customer import, event simulation, merchant timeline, undo actions, onboarding progress, RTL rendering (`ar`, `he`).
- **Load Test**: k6 for 5,000 merchants, 50,000 customers, Black Friday surges (10,000 orders/hour, 100 concurrent admin actions), including `users-service`, `roles-service`, `rfm-service` endpoints.
- **Penetration Test**: OWASP ZAP for `/admin/v1/*`, `/users.v1/*`, `/roles.v1/*`, `/rfm.v1/*` and gRPC endpoints, validating RBAC, encryption, and GDPR webhook handling.
- **Chaos Test**: Chaos Mesh in VPS (Kubernetes in Phase 6) to simulate AdminCore, AdminFeatures, Users, Roles, RFM, Redis, and PostgreSQL/TimescaleDB failures, validating circuit breakers, DLQs, and fallback UI.
- **Multilingual Test**: Jest/Cypress for i18next translation accuracy (90%+ for `en`, `es`, `fr`, `de`, `pt`, `ja`), RTL rendering (`ar`, `he`), validated with 2–3 native speakers per language via “LoyalNest Collective” Slack.

## Deployment
- **VPS**: Docker Compose for AdminCore, AdminFeatures, Users, Roles, RFM, Auth, PostgreSQL, TimescaleDB, Redis Cluster, Kafka, Nginx (reverse proxy, gRPC proxy, IP whitelisting, HMAC signatures).
- **CI/CD**: GitHub Actions with Nx change detection, blue-green deployment via Docker Compose (Kubernetes in Phase 6), nightly Chaos Mesh tests, weekly backup validation (`restore.sh`).
- **Monitoring**: Loki + Grafana (API latency <1s, error rate <1%, queue latency <2s), Prometheus (metrics), PostHog (events: `admin_action_anomaly`, `merchant_timeline_viewed`, `rate_limit_viewed`, etc.), Sentry (errors), AWS SNS (alerts for rate limit breaches, integration failures, anomalies).
- **Disaster Recovery**: Backblaze B2 backups (90-day retention, RTO: 4 hours, RPO: 1 hour), validated weekly via `restore.sh`.

## Documentation
- Multilingual admin docs (`en`, `es`, `fr`, `de`, `pt`, `ja` in Phases 2–5; `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL) in Phase 6) with 1–2 minute YouTube videos for merchant management, logs, integration health, rate limit/queue monitoring, customer import, event simulation, onboarding progress.
- OpenAPI/Swagger for `/admin/v1/*`, `/users.v1/*`, `/roles.v1/*`, `/rfm.v1/*`, gRPC proto files for `/admin.v1/*`, `/users.v1/*`, `/roles.v1/*`, `/rfm.v1/*`, `/auth.v1/*`, `/analytics.v1/*`.
- Developer guide for RBAC (via `roles-service`), GDPR/CCPA compliance, disaster recovery (RTO: 4 hours, RPO: 1 hour), queue monitoring, event simulation, and i18n setup.

## Feedback Collection
- Conduct Typeform survey with 5–10 admin users (2–3 Shopify Plus) on dashboard usability, merchant management, rate limit/queue monitoring, timeline/undo features, onboarding progress, and i18n accuracy in Phases 4–5.
- Engage 2–3 native speakers per language (`en`, `es`, `fr`, `de`, `pt`, `ja`) via “LoyalNest Collective” Slack for translation validation (90%+ accuracy).
- Log feedback in Notion, iterate in Phase 6, and track via PostHog (`merchant_feedback_submitted`).
- Deliverable: Feedback report with Shopify Plus-scale insights.

## Future Enhancements (Phase 6)
- **Kafka/NATS JetStream**: Replace Redis Streams for log monitoring, rate limit tracking, and queue metrics, enabling longer retention and replay support.
- **Versioned Configuration Management**: Track global settings and RFM config as versioned deltas in `rfm_config_history` table, with rollback via `POST /admin/v1/rfm/rollback` (RBAC: `admin:full`).
- **Multi-Tenancy**: Support sub-RBAC groups (e.g., per brand for Shopify Plus) and multi-tenant isolation for agencies, stored in `merchant_settings` (JSONB).
- **AI-Powered Suggestions**: Extend predictive suggestions (e.g., “Segment X has low ROI. Archive it?”) using xAI API (https://x.ai/api), integrated with `/analytics.v1/AnalyticsService/PredictChurn`.
- **Advanced Visualizations**: Add heatmaps and line charts for RFM analytics, queue metrics, and integration health in `AnalyticsPage.tsx`.
- **Zero-Downtime Deployments**: Implement in Kubernetes with Envoy sidecars.
- **WCAG 2.1 AA Full Compliance**: Enhance accessibility for all admin components.