# AdminCore Service Plan

## Overview
- **Purpose**: Manages core administrative functions for the LoyalNest Shopify app, including merchant authentication, core settings, overview dashboard with predictive analytics, merchant timelines, undo actions, and log management. Supports Shopify Plus multi-user access (50,000+ customers, 10,000 orders/hour) with RBAC and multilingual support.
- **Priority for TVP**: High (Phase 1 for Must Have, Phase 3 for Should Have).
- **Dependencies**: Auth (authentication), Core (customer/shop data), Users (user management), Roles (RBAC), Analytics (merchant activity), Event Tracking (task queue), AdminFeatures (advanced configurations), Frontend (UI localization).

## Database Setup
- **Database Type**: PostgreSQL, TimescaleDB
- **Port**: 5436
- **Tables**:
  - `merchants`:
    - `merchant_id`: TEXT, PK, NOT NULL
    - `shopify_domain`: TEXT, UNIQUE, NOT NULL
    - `name`: TEXT
    - `api_token`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `billing_plan`: TEXT, CHECK IN ('free', 'plus', 'enterprise')
    - `status`: TEXT, CHECK IN ('active', 'suspended', 'trial')
    - `staff_roles`: JSONB (e.g., `["admin:full", "admin:support"]`)
    - `language`: JSONB (e.g., `{"default": "en", "supported": ["en", "es", "fr", "de", "pt", "ja", "ru", "it", "nl", "pl", "tr", "fa", "zh-CN", "vi", "id", "cs", "ar", "ko", "uk", "hu", "sv", "he"], "rtl": ["ar", "he"]}`)
    - `settings`: JSONB (e.g., `{"shop_name": "Example Store", "timezone": "UTC"}`)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `auth_tokens`:
    - `token_id`: TEXT, PK, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `token`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `expires_at`: TIMESTAMP(3)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `api_logs`:
    - `id`: TEXT, PK, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `route`: TEXT
    - `method`: TEXT
    - `status_code`: INTEGER
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `audit_logs`:
    - `id`: UUID, PK, NOT NULL
    - `admin_user_id`: TEXT, FK → `users` | NULL
    - `action`: TEXT, CHECK IN ('merchant_added', 'merchant_updated', 'auth_token_issued', 'settings_updated', 'integration_configured', 'data_import_initiated', 'points_adjusted', 'plan_changed', 'undo_action', 'gdpr_processed')
    - `target_table`: TEXT
    - `target_id`: TEXT
    - `reverted`: BOOLEAN, DEFAULT FALSE
    - `metadata`: JSONB (e.g., `{"shop_domain": "example.myshopify.com", "locale": "en"}`)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `users`:
    - `id`: TEXT, PK, NOT NULL
    - `username`: TEXT, UNIQUE, NOT NULL
    - `email`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `password`: TEXT, NOT NULL
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `roles`:
    - `role_id`: TEXT, PK, NOT NULL
    - `role_name`: TEXT, UNIQUE, NOT NULL
    - `permissions`: JSONB (e.g., `["admin:full", "admin:analytics", "admin:support", "admin:points", "admin:merchants:view:shopify_plus", "admin:merchants:edit:plan"]`)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `email_events`:
    - `event_id`: TEXT, PK, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `event_type`: TEXT, CHECK IN ('sent', 'failed')
    - `recipient_email`: TEXT, AES-256 ENCRYPTED
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
- **Schema Details**:
  - Indexes: `idx_merchants_shopify_domain` (btree: `shopify_domain`), `idx_merchants_name_domain` (tsvector: `name`, `shopify_domain`), `idx_auth_tokens_merchant_id` (btree: `merchant_id`), `idx_api_logs_merchant_id_route` (btree: `merchant_id`, `route`), `idx_audit_logs_admin_user_id_action` (btree: `admin_user_id`, `action`), `idx_users_username_email` (btree: `username`, `email`), `idx_roles_role_name` (btree: `role_name`), `idx_email_events_merchant_id` (btree: `merchant_id`), `idx_merchants_language` (gin: `language`).
  - Encryption: `merchants.api_token`, `auth_tokens.token`, `users.email`, `email_events.recipient_email` encrypted with AES-256 via `pgcrypto`.
  - Partitioning: `api_logs`, `audit_logs`, `email_events` partitioned by `merchant_id`.
- **GDPR/CCPA Compliance**: Encrypts PII, logs actions in `audit_logs`, 90-day retention in Backblaze B2.

## Inter-Service Communication
- **Synchronous Communication**:
  - **GraphQL**:
    - Endpoint: `/graphql`
    - Queries:
      - `getMerchant(merchant_id: ID!): Merchant!`
      - `getAuthTokens(merchant_id: ID!): [AuthToken!]!`
      - `getOverview: Overview!`
      - `getMerchantTimeline(merchant_id: ID!): [TimelineEvent!]!`
      - `getMerchantLanguage(merchant_id: ID!): LanguageSettings!`
      - `getMerchantActivity(merchant_id: ID!, time_range: String): MerchantActivity!`
      - `getApiLogs(merchant_id: ID!, route: String, status_code: Int): [ApiLog!]!`
      - `getAuditLogs(merchant_id: ID!, action: String): [AuditLog!]!`
    - Mutations:
      - `updateMerchantSettings(merchant_id: ID!, settings: JSON!): Merchant!`
      - `issueAuthToken(merchant_id: ID!): AuthToken!`
      - `revokeAuthToken(token_id: ID!): AuthToken!`
      - `loginAsMerchant(merchant_id: ID!): AuthToken!`
      - `searchMerchants(query: String!): [Merchant!]!`
      - `adjustPoints(merchant_id: ID!, customer_id: ID!, amount: Int!): PointsAdjustment!`
      - `updateMerchantPlan(merchant_id: ID!, plan_id: String!): Merchant!`
      - `bulkUpdateMerchantPlans(merchant_ids: [ID!]!, plan_id: String!): [Merchant!]!`
      - `undoAction(audit_log_id: ID!): AuditLog!`
      - `replayLog(log_id: ID!): AuditLog!`
    - Subscriptions:
      - `onMerchantActivity(merchant_id: ID!): MerchantActivity!`
      - `onLogs(merchant_id: ID!, actions: [String!]): AuditLog!`
  - **gRPC**:
    - `/admincore.v1/AdminCoreService/GetOverview`
    - `/admincore.v1/AdminCoreService/GetMerchant`
    - `/admincore.v1/AdminCoreService/IssueAuthToken`
    - `/admincore.v1/AdminCoreService/RevokeAuthToken`
    - `/admincore.v1/AdminCoreService/LoginAsMerchant`
    - `/admincore.v1/AdminCoreService/SearchMerchants`
    - `/admincore.v1/AdminCoreService/AdjustPoints`
    - `/admincore.v1/AdminCoreService/UpdateMerchantPlan`
    - `/admincore.v1/AdminCoreService/BulkUpdateMerchantPlans`
    - `/admincore.v1/AdminCoreService/UndoAction`
    - `/admincore.v1/AdminCoreService/GetAuditLogs`
    - `/admincore.v1/AdminCoreService/ReplayLog`
    - `/users.v1/UsersService/CreateAdminUser`
    - `/roles.v1/RolesService/AssignRole`
  - **REST**:
    - `/admin/v1/core/merchants`
    - `/admin/v1/core/merchants/search`
    - `/admin/v1/core/merchants/{id}/adjust-points`
    - `/admin/v1/core/merchants/bulk`
    - `/admin/v1/core/merchants/{id}/undo`
    - `/admin/v1/core/merchants/{id}/login`
    - `/admin/v1/core/auth/tokens`
    - `/admin/v1/logs/api`
    - `/admin/v1/logs/audit`
    - `/admin/v1/logs/stream`
    - `/admin/v1/logs/replay`
    - `/admin/v1/overview`
    - `/health`, `/ready`, `/metrics`
  - **WebSocket**:
    - `/admin/v1/core/logs/stream`: Streams `api_logs`, `audit_logs`.
- **Asynchronous Communication**:
  - **Events Produced**: `merchant.created`, `merchant.updated`, `auth_token.issued`, `points.adjusted`, `plan.changed`, `undo.action`, `log.replayed` (Kafka, consumed by Event Tracking, AdminFeatures).
  - **Events Consumed**:
    - `user.created`, `user.updated` (Users).
    - `rfm.updated` (RFM).
    - `points.updated` (Points).
    - `referral.created` (Referrals).
    - `customer_import.completed` (AdminFeatures).
  - **Saga Patterns**: AdminCore → Event Tracking → AdminFeatures for points adjustments, plan changes, imports.
- **Calls**:
  - `/auth.v1/ValidateMerchant` (gRPC, Auth).
  - `/users.v1/GetUser` (gRPC, Users).
  - `/roles.v1/GetRole`, `/roles.v1/GetPermissions` (gRPC, Roles).
  - `/analytics.v1/PredictChurn` (gRPC, Analytics).
  - `/adminfeatures.v1/ImportCustomerData` (gRPC, AdminFeatures).
- **Called By**: Frontend, AdminFeatures, Auth, Analytics.

## GraphQL Schema
```graphql
type Merchant {
  merchant_id: ID!
  shopify_domain: String!
  name: String
  billing_plan: String!
  status: String!
  staff_roles: [String!]!
  language: LanguageSettings!
  settings: JSON!
  created_at: String!
}

type LanguageSettings {
  default: String!
  supported: [String!]!
  rtl: [String!]!
}

type AuthToken {
  token_id: ID!
  merchant_id: ID!
  token: String!
  expires_at: String
  created_at: String!
}

type ApiLog {
  id: ID!
  merchant_id: ID!
  route: String!
  method: String!
  status_code: Int!
  created_at: String!
}

type AuditLog {
  id: ID!
  admin_user_id: ID
  action: String!
  target_table: String
  target_id: ID
  reverted: Boolean!
  metadata: JSON!
  created_at: String!
}

type Overview {
  merchant_count: Int!
  points_issued: Int!
  points_redeemed: Int!
  referral_roi: Float!
  rfm_segments: [RFMSegment!]!
  import_status: [ImportStatus!]!
  rate_limit_usage: JSON!
  queue_backlog: Int!
  points_adjustment_latency: Float!
  integration_health: [IntegrationHealth!]!
  churn_prediction: JSON!
  suggestions: [Suggestion!]!
}

type RFMSegment {
  segment_name: String!
  customer_count: Int!
}

type ImportStatus {
  import_id: ID!
  merchant_id: ID!
  source: String!
  status: String!
  record_count: Int!
  error_log: JSON
  created_at: String!
}

type IntegrationHealth {
  platform: String!
  status: String!
  error_details: JSON
}

type Suggestion {
  message: String!
  action: String!
}

type MerchantActivity {
  merchant_id: ID!
  time_range: String!
  login_count: Int!
  settings_updates: Int!
  import_initiations: Int!
}

type PointsAdjustment {
  customer_id: ID!
  amount: Int!
  status: String!
}

type TimelineEvent {
  action: String!
  target_table: String
  target_id: ID
  metadata: JSON!
  created_at: String!
}

type Query {
  getMerchant(merchant_id: ID!): Merchant!
  getAuthTokens(merchant_id: ID!): [AuthToken!]!
  getOverview: Overview!
  getMerchantTimeline(merchant_id: ID!): [TimelineEvent!]!
  getMerchantLanguage(merchant_id: ID!): LanguageSettings!
  getMerchantActivity(merchant_id: ID!, time_range: String): MerchantActivity!
  getApiLogs(merchant_id: ID!, route: String, status_code: Int): [ApiLog!]!
  getAuditLogs(merchant_id: ID!, action: String): [AuditLog!]!
  searchMerchants(query: String!): [Merchant!]!
}

type Mutation {
  updateMerchantSettings(merchant_id: ID!, settings: JSON!): Merchant!
  issueAuthToken(merchant_id: ID!): AuthToken!
  revokeAuthToken(token_id: ID!): AuthToken!
  loginAsMerchant(merchant_id: ID!): AuthToken!
  adjustPoints(merchant_id: ID!, customer_id: ID!, amount: Int!): PointsAdjustment!
  updateMerchantPlan(merchant_id: ID!, plan_id: String!): Merchant!
  bulkUpdateMerchantPlans(merchant_ids: [ID!]!, plan_id: String!): [Merchant!]!
  undoAction(audit_log_id: ID!): AuditLog!
  replayLog(log_id: ID!): AuditLog!
}

type Subscription {
  onMerchantActivity(merchant_id: ID!): MerchantActivity!
  onLogs(merchant_id: ID!, actions: [String!]): AuditLog!
}
```

## Key Endpoints
- **GraphQL**: `/graphql` (queries: `getMerchant`, `getAuthTokens`, `getOverview`, `getMerchantTimeline`, `getMerchantLanguage`, `getMerchantActivity`, `getApiLogs`, `getAuditLogs`, `searchMerchants`; mutations: `updateMerchantSettings`, `issueAuthToken`, `revokeAuthToken`, `loginAsMerchant`, `adjustPoints`, `updateMerchantPlan`, `bulkUpdateMerchantPlans`, `undoAction`, `replayLog`; subscriptions: `onMerchantActivity`, `onLogs`).
- **gRPC**:
  - `/admincore.v1/AdminCoreService/GetOverview`
  - `/admincore.v1/AdminCoreService/GetMerchant`
  - `/admincore.v1/AdminCoreService/IssueAuthToken`
  - `/admincore.v1/AdminCoreService/RevokeAuthToken`
  - `/admincore.v1/AdminCoreService/LoginAsMerchant`
  - `/admincore.v1/AdminCoreService/SearchMerchants`
  - `/admincore.v1/AdminCoreService/AdjustPoints`
  - `/admincore.v1/AdminCoreService/UpdateMerchantPlan`
  - `/admincore.v1/AdminCoreService/BulkUpdateMerchantPlans`
  - `/admincore.v1/AdminCoreService/UndoAction`
  - `/admincore.v1/AdminCoreService/GetAuditLogs`
  - `/admincore.v1/AdminCoreService/ReplayLog`
  - `/users.v1/UsersService/CreateAdminUser`
  - `/roles.v1/RolesService/AssignRole`
- **REST**:
  - `/admin/v1/core/merchants`
  - `/admin/v1/core/merchants/search`
  - `/admin/v1/core/merchants/{id}/adjust-points`
  - `/admin/v1/core/merchants/bulk`
  - `/admin/v1/core/merchants/{id}/undo`
  - `/admin/v1/core/merchants/{id}/login`
  - `/admin/v1/core/auth/tokens`
  - `/admin/v1/logs/api`
  - `/admin/v1/logs/audit`
  - `/admin/v1/logs/stream`
  - `/admin/v1/logs/replay`
  - `/admin/v1/overview`
  - `/health`, `/ready`, `/metrics`
- **Access Patterns**: High read (merchant data, logs, overview), moderate write (settings, points adjustments, plan changes).
- **Rate Limits**: Shopify API (2 req/s standard, 40 req/s Plus), GraphQL queries limited to 500 points.

## Health and Readiness Checks
- **Health Endpoint**: `/health` (HTTP GET)
  - Returns `{ "status": "UP" }` if PostgreSQL, TimescaleDB, Kafka, Redis, and GraphQL server are operational.
- **Readiness Endpoint**: `/ready` (HTTP GET)
  - Returns `{ "ready": true }` when migrations and servers are initialized.
- **Consul Health Check**:
  - Registered via `registrator`: `SERVICE_NAME=admin-core`, `SERVICE_CHECK_HTTP=/health`.
  - Checks every 10s (timeout: 2s).
- **Validation**: Test in CI/CD: `curl http://admin-core:8080/health`.

## Service Discovery
- **Tool**: Consul (via `registrator`).
- **Configuration**:
  - Environment Variables: `SERVICE_NAME=admin-core`, `SERVICE_PORT=50051` (gRPC), `8080` (HTTP/GraphQL), `SERVICE_CHECK_HTTP=/health`, `SERVICE_TAGS=admin,core,auth,logs,overview`.
  - Network: `loyalnest`.
- **Validation**: `curl http://consul:8500/v1/catalog/service/admin-core`.

## Monitoring and Observability
- **Metrics**:
  - Endpoint: `/metrics` (Prometheus).
  - Key Metrics:
    - `admin_core_graphql_queries_total`: GraphQL query count.
    - `admin_core_auth_tokens_issued_total`: Auth tokens issued.
    - `admin_core_points_adjusted_total`: Points adjustments.
    - `admin_core_plan_changes_total`: Plan changes.
    - `admin_core_undo_actions_total`: Undo actions.
    - `admin_core_log_replays_total`: Log replays.
    - `graphql_query_duration_seconds`: GraphQL query latency.
    - `redis_cache_hit_rate`: Cache hit rate (>95%).
  - **Logging**: Structured JSON logs via Loki, tagged with `shop_domain`, `merchant_id`, `service_name=admin-core`, `locale`.
  - **Alerting**: Prometheus Alertmanager, AWS SNS for rate limits (80% threshold), anomalies (>100 points adjustments/hour, >3 rate limit breaches/hour).
  - **Event Tracking**: PostHog (`admin_suggestion_clicked`, `merchant_timeline_viewed`, `admin_mfa_enabled`, `admin_log_replay`, `admin_login_as_merchant`).

## Security Considerations
- **Authentication**: GraphQL/gRPC: JWT via Auth service; REST: API key + HMAC (Nginx).
- **Authorization**: RBAC via `/roles.v1/GetRole` (`admin:full`, `admin:analytics`, `admin:support`, `admin:points`, `admin:merchants:view:shopify_plus`, `admin:merchants:edit:plan`).
- **Data Protection**:
  - `merchants.api_token`, `auth_tokens.token`, `users.email`, `email_events.recipient_email` encrypted with AES-256 via `pgcrypto`.
  - Kafka events encrypted with TLS.
- **IP Whitelisting**: Restrict access via `merchants.ip_whitelist` (Redis: `admin:ip_whitelist:{merchant_id}`, TTL 7d).
- **Anomaly Detection**: Alert on >100 points adjustments/hour or >3 rate limit breaches/hour via AWS SNS.
- **Security Testing**: OWASP ZAP (ECL: 256) for `/graphql`, `/admin/v1/core/*`, `/admin/v1/logs/*`.

## Testing Strategy
- **Unit Tests**: Jest for `AdminCoreRepository`, GraphQL resolvers (`getMerchant`, `getOverview`, `searchMerchants`, `adjustPoints`, `undoAction`, `replayLog`).
- **Integration Tests**: Testcontainers for PostgreSQL, TimescaleDB, Kafka, Redis, GraphQL server.
- **Contract Tests**: Pact for gRPC, Kafka, GraphQL schema.
- **E2E Tests**: Cypress for `/graphql`, `/admin/v1/core/merchants`, `/admin/v1/logs/*`, `/admin/v1/overview`.
- **Load Tests**: k6 for `/graphql` (500 req/s, <200ms latency), `/admin/v1/core/merchants/bulk` (<5s for 100 merchants).
- **Chaos Tests**: Chaos Mesh for PostgreSQL, TimescaleDB, Kafka, Redis failures.
- **Compliance Tests**: Verify encryption, audit logging, GDPR compliance.
- **i18n Tests**: Validate all supported languages, RTL for `ar`, `he` (90%+ accuracy).

## Deployment
- **Docker Compose**:
  - Image: `admin-core:latest`.
  - Ports: `50051` (gRPC), `8080` (HTTP/GraphQL).
  - Environment Variables: `ADMIN_CORE_DB_HOST`, `KAFKA_BROKER`, `REDIS_HOST`, `GRAPHQL_PORT=8080`.
  - Network: `loyalnest`.
- **Resource Limits**: CPU: 0.5 cores, Memory: 512MiB.
- **Scaling**: 2 replicas for 5,000 merchants, 50,000 customers, 100 concurrent admin actions.
- **Orchestration**: Kubernetes (Phase 6) with liveness/readiness probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, OWASP ZAP.

## Risks and Mitigations
- **GraphQL Complexity**: Query depth limit (8), complexity budget (500 points).
- **Rate Limit Breaches**: Redis tracking, Slack/email alerts at 80% limit.
- **Undo Failures**: Store reversible actions in `audit_logs` with `reverted` flag.
- **Translation Accuracy**: Validate with 2–3 native speakers per language via “LoyalNest Collective” Slack.

## Documentation and Maintenance
- **API Documentation**: GraphQL schema in `schema.graphql`, OpenAPI for REST, gRPC proto files.
- **Event Schema**: `merchant.created`, `merchant.updated`, `auth_token.issued`, `points.adjusted`, `plan.changed`, `undo.action`, `log.replayed` in Confluent Schema Registry.
- **Runbook**: Health check (`curl http://admin-core:8080/health`), logs via Loki.
- **Maintenance**: Rotate credentials quarterly, validate Backblaze B2 backups weekly.

## Action Items
- [ ] Deploy `admin_core_db` with new tables by September 15, 2025 (Owner: DB Team).
- [ ] Implement `/graphql` (new queries/mutations) by October 15, 2025 (Owner: Dev Team).
- [ ] Test `merchant.created`, `points.adjusted`, `undo.action`, `log.replayed` by November 1, 2025 (Owner: Dev Team).
- [ ] Implement overview dashboard and timeline by December 1, 2025 (Owner: Frontend Team).
- [ ] Set up Prometheus/Loki for new metrics by January 15, 2026 (Owner: SRE Team).
- [ ] Validate multilingual support by February 1, 2026 (Owner: Frontend Team).

## Timeline
- **Start Date**: September 1, 2025 (Phase 1 for Must Have).
- **Completion Date**: February 17, 2026 (Must Have), April 30, 2026 (Should Have, TVP completion).
- **Risks to Timeline**: GraphQL complexity, timeline rendering, translation validation.

## Dependencies
- **Internal**: Auth, Core, Users, Roles, Analytics, Event Tracking, AdminFeatures, Frontend.
- **External**: Shopify APIs, Klaviyo, Mailchimp.