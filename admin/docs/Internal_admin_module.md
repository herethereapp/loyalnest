# Internal Admin Module
LoyalNest App

## Overview
This document details the internal admin module for the LoyalNest App, enabling platform-level management of merchants, points, integrations, analytics, customer data imports, GDPR/CCPA compliance, and rate limit monitoring, with RBAC for Shopify Plus multi-user access (50,000+ customers, 1,000 orders/hour). It integrates with admin, analytics, auth, and points services, using PostgreSQL, Redis Streams, and Nx monorepo management for scalability and maintainability.

## Features
- **Overview** (Admin Service):
  - Display metrics: Merchant count, points issued/redeemed, referral ROI, RFM segments (e.g., At-Risk, Champions), customer import status, rate limit usage.
  - Chart.js visualizations for trends (e.g., points issued, RFM segment counts, import success rate).
  - APIs: `GET /admin/v1/overview`, gRPC: `/admin.v1/AdminService/GetOverview`.
  - Success Metric: 90%+ query performance under 1s.
- **Merchants** (Admin Service):
  - List: `merchant_id`, `shopify_domain`, `plan_id`, `status` (active, suspended, trial), `staff_roles` (JSONB), `language` (JSONB).
  - Search: Fuzzy matching by domain, name.
  - Actions: View details, activate/suspend, adjust points, GDPR export/delete, bulk plan upgrades/downgrades, customer import.
  - APIs: `GET /admin/v1/merchants`, `POST /admin/v1/merchants/search`, `POST /admin/v1/merchants/{id}/adjust-points`, `POST /admin/v1/merchants/bulk`, gRPC: `/admin.v1/AdminService/ImportCustomers`.
  - Error Handling: `INVALID_MERCHANT_ID`, `UNAUTHORIZED`, `RATE_LIMIT_EXCEEDED` (429).
  - RBAC: `admin:full` for all actions, `admin:support` for view/search, `admin:points` for points adjustments.
  - Success Metric: 95%+ action success rate.
- **Admin Users** (Admin Service, Auth Service):
  - Add/edit/delete users in `admin_users` (username, email ENCRYPTED, password, metadata JSONB with RBAC roles: `admin:full`, `admin:analytics`, `admin:support`).
  - MFA via Auth0, session timeout (30 min), IP whitelisting (internal IPs).
  - RBAC for Plus: Multi-user access with role-based restrictions (e.g., `admin:analytics` for read-only analytics, `admin:full` for imports, campaigns, user management).
  - APIs: `POST /admin/v1/users`, `PUT /admin/v1/users/{id}`, `DELETE /admin/v1/users/{id}`, gRPC: `/auth.v1/AuthService/CreateAdminUser`.
  - Error Handling: `DUPLICATE_USERNAME`, `INVALID_EMAIL`.
  - Success Metric: 100% secure user management.
- **Logs** (Admin Service):
  - View `api_logs` (route, method, status_code, created_at), `audit_logs` (admin_user_id, action, target_table, target_id, created_at).
  - Actions Logged: `gdpr_processed`, `rfm_export`, `customer_import`, `campaign_discount_issued`, `tier_assigned`, `config_updated`, `rate_limit_viewed`.
  - Notification Status Monitoring: Track referral notification status (`sent`, `failed`) in `email_events`, linked to `email_templates`.
  - Filters: Date, route, user, action, notification status.
  - APIs: `GET /admin/v1/logs/api`, `GET /admin/v1/logs/audit`.
  - Success Metric: 90%+ query performance under 1s.
- **Integration Health** (Admin Service):
  - Monitor Shopify, Klaviyo, Postscript, Square, Lightspeed (`integrations.status`, `last_checked`, `error_details` JSONB).
  - Real-time alerts in dashboard (e.g., “Shopify API down”).
  - APIs: `GET /admin/v1/integrations/health`.
  - Success Metric: 95%+ integration uptime.
- **Rate Limit Monitoring** (Admin Service):
  - Display Shopify API and integration rate limits (2 req/s REST, 40 req/s Plus, 1–4 req/s Storefront).
  - APIs: gRPC: `/admin.v1/AdminService/GetRateLimits`.
  - Success Metric: 90%+ rate limit query performance under 1s.
- **Platform Settings** (Admin Service):
  - Configure plans, global settings, RFM thresholds, notification templates.
  - APIs: `POST /admin/v1/settings`, `GET /admin/v1/settings`.
  - RBAC: `admin:full` for updates, `admin:analytics` for read-only.
  - Success Metric: 95%+ settings update success.
- **Login as Merchant** (Admin Service):
  - Generate temporary JWT (1-hour expiry) for merchant access, restricted by RBAC.
  - APIs: `POST /admin/v1/merchants/{id}/login`.
  - RBAC: `admin:full` only.
  - Success Metric: 90%+ login success rate.
- **RFM Configuration and Export** (Admin Service):
  - Configure RFM thresholds (Recency 1–5: 7–90 days, Frequency 1–5: 1–10 orders, Monetary 1–5: $50–$2,500+).
  - Use `rfm_segment_counts` materialized view for analytics (merchant_id, segment_name, customer_count, last_refreshed).
  - Export segments as CSV/JSON, async processing via Bull queues.
  - APIs: `POST /admin/v1/rfm/config`, `POST /admin/v1/rfm/export`.
  - RBAC: `admin:full`, `admin:analytics` for configuration/export.
  - Success Metric: 80%+ config completion, 90%+ export completion under 5s.
- **Customer Data Import** (Admin Service):
  - Async CSV import with validation (email, shopify_customer_id), GDPR compliance (AES-256 encryption for PII).
  - APIs: gRPC: `/admin.v1/AdminService/ImportCustomers`.
  - RBAC: `admin:full` only.
  - Log actions in `audit_logs` (`customer_import`).
  - Success Metric: 95%+ import success rate.

## Technical Details
- **Backend** (Admin Service, Auth Service):
  - NestJS for APIs, gRPC for inter-service communication (Admin ↔ Analytics, Admin ↔ Points, Admin ↔ Auth).
  - Shopify GraphQL Admin API for merchant/customer data.
  - Bull queues for async tasks (exports, customer imports, RFM calculations), 5 retries (2s initial delay).
  - Error Handling: `UNAUTHORIZED`, `INVALID_INPUT`, `QUEUE_FULL`, `RATE_LIMIT_EXCEEDED`.
  - gRPC Endpoints:
    - `/admin.v1/AdminService/GetOverview`
    - `/admin.v1/AdminService/ImportCustomers`
    - `/admin.v1/AdminService/GetRateLimits`
    - `/auth.v1/AuthService/CreateAdminUser`
- **Frontend** (Frontend Service):
  - React components (`AdminOverview.tsx`, `MerchantsPage.tsx`, `LogsPage.tsx`, `UsersPage.tsx`, `IntegrationsPage.tsx`, `RateLimitsPage.tsx`) using Vite, Polaris, Tailwind CSS.
  - Rate limit monitoring screen with real-time Shopify API and integration limits.
  - i18next for multilingual support (`en`, `es`, `fr`), WCAG 2.1 compliant.
- **Database**:
  - `admin_users` (id, username UNIQUE, email ENCRYPTED, password, metadata JSONB with RBAC roles: `["admin:full", "admin:analytics", "admin:support"]`)
  - `api_logs` (id, merchant_id, route, method, status_code, created_at)
  - `audit_logs` (id UUID, admin_user_id, action CHECK('gdpr_processed', 'rfm_export', 'customer_import', 'campaign_discount_issued', 'tier_assigned', 'config_updated', 'rate_limit_viewed'), target_table, target_id, created_at)
  - `integrations` (integration_id, merchant_id, type CHECK('shopify', 'klaviyo', 'postscript', 'square', 'lightspeed'), status CHECK('ok', 'error'), settings, api_key ENCRYPTED)
  - `rfm_segment_counts` (merchant_id, segment_name, customer_count, last_refreshed)
  - `email_events` (event_id, merchant_id, event_type CHECK('sent', 'failed'), recipient_email ENCRYPTED)
  - Indexes: `admin_users(username, email)`, `api_logs(merchant_id, route)`, `audit_logs(admin_user_id)`, `integrations(merchant_id)`, `rfm_segment_counts(merchant_id)`
  - Partitioning: `api_logs`, `audit_logs` by `merchant_id`.
- **Caching**: Redis Streams (`admin:metrics:{period}`, TTL 6h; `admin:logs:{merchant_id}`) for overview, logs, integration health, rate limits.
- **Feature Flags**: LaunchDarkly for “Login as Merchant”, RFM export, integration health, customer import.

## Integrations
- **Shopify**: GraphQL Admin API, `customers/data_request`, `customers/redact` webhooks (5 retries).
- **Klaviyo/Postscript/Square/Lightspeed**: Monitor health via API calls (`/v2/payments`, `/api/2.0/sales`, `/sms/messages`), track notification status in `email_events`.
- **Rate Limiting**: 2 req/s (REST), 40 req/s (Plus), 1–4 req/s (Storefront).

## Performance Optimizations
- **Redis Streams**: Cache metrics, logs, integration health, rate limits (`admin:rate_limits:{merchant_id}`).
- **PostgreSQL**: Connection pooling for 10,000+ queries, partitioning for logs, materialized views for `rfm_segment_counts`.
- **Load Testing**: k6 for 5,000 merchants, 50,000 customers.

## Security and Compliance
- **GDPR/CCPA**: Encrypt `admin_users.email`, `integrations.api_key` with pgcrypto. Cascade deletes for `customers/redact`. Log `gdpr_processed` in `audit_logs`.
- **Audit Logging**: Log all admin actions (points adjustments, user management, RFM config/export, customer import, campaign discounts, rate limit views).
- **RBAC**: Enforce for all actions:
  - `admin:full`: All actions (user management, points adjustments, imports, campaigns, RFM config/export, rate limit monitoring).
  - `admin:analytics`: Read-only for analytics, RFM config/export.
  - `admin:support`: Read-only for merchants, logs, integration health.
  - `admin:points`: Points adjustments, campaign management, VIP tiers.
- **Security**: JWT (1-hour expiry), MFA (Auth0), IP whitelisting, session timeout (30 min).
- **Backup**: 90-day retention for `audit_logs`, `api_logs`.

## Testing
- **Unit**: Jest for APIs, RBAC logic, export processing, customer import, rate limit monitoring.
- **Integration**: Shopify, Klaviyo, Postscript, Square, Lightspeed APIs, customer import workflows.
- **E2E**: Admin dashboard, login as merchant, logs, exports, rate limit monitoring, customer import (Cypress).
- **Load Test**: 5,000 merchants, 50,000 customers (k6).

## Deployment
- **VPS**: Docker Compose for admin service, auth service, PostgreSQL, Redis, Nginx.
- **CI/CD**: GitHub Actions with Nx change detection.
- **Monitoring**: Grafana, Prometheus, Sentry for API latency, errors, integration health, rate limits.

## Documentation
- Multilingual admin docs (English, Spanish, French) with 1–2 minute videos for merchant management, logs, integration health, rate limit monitoring, customer import.
- OpenAPI/Swagger for `/admin/v1/*`, gRPC proto files for `/admin.v1/*`, `/auth.v1/*`, developer guide for RBAC, GDPR compliance.