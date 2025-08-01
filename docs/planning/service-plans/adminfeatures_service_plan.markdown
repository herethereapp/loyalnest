# AdminFeatures Service Plan

## Overview
- **Purpose**: Manages advanced administrative functions for the LoyalNest Shopify app, including integration health, rate limit and queue monitoring, platform settings, RFM configuration and exports, customer data imports, event simulation, onboarding progress, and log management with visualizations. Supports Shopify Plus scale (50,000+ customers, 10,000 orders/hour during Black Friday surges) with RBAC, multilingual support, and GDPR/CCPA compliance.
- **Priority for TVP**: High (Phase 1 for Must Have, Phase 3 for Should Have).
- **Dependencies**: Core (settings, customer data), Users (user management), Roles (RBAC), RFM (analytics), Points (points balance), Referrals (referral codes), Analytics (ROI, churn), Auth (validation), Event Tracking (task queue), Frontend (widget localization).

## Database Setup
- **Database Type**: PostgreSQL, TimescaleDB
- **Port**: 5437
- **Tables**:
  - `merchants`:
    - `merchant_id`: TEXT, PK, NOT NULL
    - `shopify_domain`: TEXT, UNIQUE, NOT NULL
    - `api_token`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `ip_whitelist`: JSONB (e.g., `["192.168.1.1"]`)
    - `plan_id`: TEXT, CHECK IN ('free', 'plus', 'enterprise')
    - `language`: JSONB (e.g., `{"default": "en", "supported": ["en", "es", "fr", "de", "pt", "ja", "ru", "it", "nl", "pl", "tr", "fa", "zh-CN", "vi", "id", "cs", "ar", "ko", "uk", "hu", "sv", "he"], "rtl": ["ar", "he"]}`)
  - `setup_tasks`:
    - `task_id`: TEXT, PK, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `task_name`: TEXT (e.g., `rfm_config`, `referrals_config`, `checkout_extensions`)
    - `status`: TEXT, CHECK IN ('pending', 'completed')
    - `completed_at`: TIMESTAMP(3)
  - `program_settings`:
    - `merchant_id`: TEXT, PK, FK → `merchants`, NOT NULL
    - `rfm_thresholds`: JSONB (e.g., `{"recency": {"min": 7, "max": 90}, "frequency": {"min": 1, "max": 10}, "monetary": {"min": 50, "max": 2500}}`)
    - `dynamic_multipliers`: JSONB (e.g., `{"first_purchase_24h": 2.0, "rfm_champion": 1.5}`)
    - `multi_currency_config`: JSONB (e.g., `{"supported_currencies": ["USD", "EUR", "CAD"]}`)
    - `referral_config`: JSONB (e.g., `{"tiers": [{"level": 1, "points": 100}, {"level": 2, "points": 200}]}`)
    - `branding`: JSONB (e.g., `{"sticky_bar": {"en": {...}, "ar": {...}}, "post_purchase": {...}}`)
  - `email_templates`:
    - `template_id`: TEXT, PK, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `template_name`: TEXT
    - `content`: JSONB (e.g., `{"en": {"subject": "Welcome"}, "ar": {"subject": "مرحبا"}}`)
    - `fallback_language`: TEXT, DEFAULT 'en'
  - `integrations`:
    - `integration_id`: TEXT, PK, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `platform`: TEXT, CHECK IN ('shopify', 'klaviyo', 'mailchimp', 'yotpo', 'judge.me', 'postscript', 'square')
    - `settings`: JSONB (e.g., `{"api_key": "encrypted_key", "enabled": true}`)
    - `status`: TEXT, CHECK IN ('ok', 'error')
    - `error_details`: JSONB
    - `last_checked_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
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
    - `action`: TEXT, CHECK IN ('gdpr_processed', 'rfm_export', 'customer_import', 'customer_import_completed', 'campaign_discount_issued', 'tier_assigned', 'config_updated', 'rate_limit_viewed', 'undo_action', 'referral_fallback_triggered', 'square_sync_triggered')
    - `target_table`: TEXT
    - `target_id`: TEXT
    - `reverted`: BOOLEAN, DEFAULT FALSE
    - `metadata`: JSONB (e.g., `{"endpoint": "orders/create", "locale": "ar"}`)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `data_imports`:
    - `import_id`: TEXT, PK, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `source`: TEXT, CHECK IN ('smile_io', 'loyaltylion', 'shopify', 'custom')
    - `status`: TEXT, CHECK IN ('pending', 'processing', 'completed', 'failed')
    - `record_count`: INTEGER, CHECK >= 0
    - `error_log`: JSONB (e.g., `{"row": 10, "error": "Duplicate email"}`)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `rfm_segment_counts`:
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `segment_name`: TEXT
    - `customer_count`: INTEGER
    - `last_refreshed`: TIMESTAMP(3)
  - `rfm_segment_deltas`:
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `customer_id`: TEXT
    - `segment_change`: TEXT
    - `updated_at`: TIMESTAMP(3)
  - `customer_segments`:
    - `customer_id`: TEXT, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `segment_name`: TEXT
    - `updated_at`: TIMESTAMP(3)
  - `email_events`:
    - `event_id`: TEXT, PK, NOT NULL
    - `merchant_id`: TEXT, FK → `merchants`, NOT NULL
    - `event_type`: TEXT, CHECK IN ('sent', 'failed')
    - `recipient_email`: TEXT, AES-256 ENCRYPTED
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
- **Schema Details**:
  - Indexes: `idx_merchants_shopify_domain` (btree: `shopify_domain`), `idx_setup_tasks_merchant_id` (btree: `merchant_id`), `idx_program_settings_merchant_id` (btree: `merchant_id`), `idx_email_templates_merchant_id` (btree: `merchant_id`), `idx_integrations_merchant_id_platform` (btree: `merchant_id`, `platform`), `idx_api_logs_merchant_id_route` (btree: `merchant_id`, `route`), `idx_audit_logs_admin_user_id_action` (btree: `admin_user_id`, `action`), `idx_data_imports_merchant_id_status` (btree: `merchant_id`, `status`), `idx_rfm_segment_counts_merchant_id` (btree: `merchant_id`), `idx_rfm_segment_deltas_merchant_id_updated_at` (btree: `merchant_id`, `updated_at`), `idx_customer_segments_merchant_id` (btree: `merchant_id`), `idx_email_events_merchant_id` (btree: `merchant_id`), `idx_merchants_language` (gin: `language`).
  - Encryption: `merchants.api_token`, `email_events.recipient_email`, `data_imports.email` encrypted with AES-256 via `pgcrypto`.
  - Partitioning: `api_logs`, `audit_logs`, `data_imports`, `rfm_segment_deltas`, `email_events` partitioned by `merchant_id`; `rfm_segment_deltas` by `updated_at`.
- **GDPR/CCPA Compliance**: Encrypts PII, logs actions in `audit_logs`, 90-day retention in Backblaze B2.

## Inter-Service Communication
- **Synchronous Communication**:
  - **GraphQL**:
    - Endpoint: `/graphql`
    - Queries:
      - `getIntegrationHealth(merchant_id: ID!, platform: String!): IntegrationStatus!`
      - `getRateLimits(merchant_id: ID!): RateLimitStatus!`
      - `getQueueMetrics(merchant_id: ID!): QueueMetrics!`
      - `getRFMSegmentCounts(merchant_id: ID!): [RFMSegment!]!`
      - `getApiLogs(merchant_id: ID!, route: String, status_code: Int): [ApiLog!]!`
      - `getAuditLogs(merchant_id: ID!, action: String): [AuditLog!]!`
      - `getImportStatus(merchant_id: ID!, import_id: ID!): ImportStatus!`
      - `getMerchantLanguage(merchant_id: ID!): LanguageSettings!`
      - `getSetupProgress(merchant_id: ID!): [SetupTask!]!`
    - Mutations:
      - `configureIntegration(merchant_id: ID!, platform: String!, settings: JSON!): IntegrationStatus!`
      - `syncSquare(merchant_id: ID!): IntegrationStatus!`
      - `disableIntegration(merchant_id: ID!, platform: String!): IntegrationStatus!`
      - `updatePlatformSettings(merchant_id: ID!, settings: JSON!): PlatformSettings!`
      - `updateNotificationTemplate(merchant_id: ID!, template_id: ID!, content: JSON!): EmailTemplate!`
      - `updateRFMThresholds(merchant_id: ID!, thresholds: JSON!): RFMConfig!`
      - `exportRFMSegments(merchant_id: ID!, format: String!): ExportStatus!`
      - `importCustomers(merchant_id: ID!, source: String!, file_url: String!): ImportStatus!`
      - `simulateEvent(merchant_id: ID!, event_type: String!, payload: JSON!): EventStatus!`
      - `replayLog(log_id: ID!): AuditLog!`
    - Subscriptions:
      - `onIntegrationHealth(merchant_id: ID!, platforms: [String!]): IntegrationStatus!`
      - `onImportProgress(merchant_id: ID!, import_id: ID!): ImportStatus!`
      - `onSetupProgress(merchant_id: ID!): [SetupTask!]!`
      - `onLogs(merchant_id: ID!, actions: [String!]): AuditLog!`
  - **gRPC**:
    - `/adminfeatures.v1/AdminFeaturesService/GetRateLimits`
    - `/adminfeatures.v1/AdminFeaturesService/GetQueueMetrics`
    - `/adminfeatures.v1/AdminFeaturesService/ConfigureIntegration`
    - `/adminfeatures.v1/AdminFeaturesService/SyncSquare`
    - `/adminfeatures.v1/AdminFeaturesService/DisableIntegration`
    - `/adminfeatures.v1/AdminFeaturesService/UpdatePlatformSettings`
    - `/adminfeatures.v1/AdminFeaturesService/UpdateNotificationTemplate`
    - `/adminfeatures.v1/AdminFeaturesService/SimulateEvent`
    - `/adminfeatures.v1/AdminFeaturesService/StreamSetupProgress`
    - `/rfm.v1/RFMService/UpdateThresholds`
    - `/rfm.v1/RFMService/GetSegmentCounts`
    - `/rfm.v1/RFMService/ExportSegments`
    - `/rfm.v1/RFMService/GetVisualizations`
    - `/users.v1/UsersService/ImportCustomers`
  - **REST**:
    - `/admin/v1/integrations/health`
    - `/admin/v1/integrations/square`
    - `/admin/v1/integrations/square/sync`
    - `/admin/v1/rate-limits`
    - `/admin/v1/rate-limits/queue`
    - `/admin/v1/settings`
    - `/admin/v1/rfm/config`
    - `/admin/v1/rfm/export`
    - `/admin/v1/rfm/visualizations`
    - `/admin/v1/customers/import`
    - `/admin/v1/events/simulate`
    - `/admin/v1/setup/stream`
    - `/admin/v1/logs/api`
    - `/admin/v1/logs/audit`
    - `/admin/v1/logs/stream`
    - `/admin/v1/logs/replay`
    - `/health`, `/ready`, `/metrics`
  - **WebSocket**:
    - `/admin/v1/imports/stream`: Streams import progress.
    - `/admin/v1/setup/stream`: Streams setup progress.
    - `/admin/v1/logs/stream`: Streams `api_logs`, `audit_logs`.
- **Asynchronous Communication**:
  - **Events Produced**: `integration.configured`, `integration.disabled`, `rfm_export.initiated`, `customer_import.initiated`, `customer_import.completed`, `event.simulated`, `referral_fallback_triggered`, `square_sync_triggered`, `undo.action`, `log.replayed` (Kafka, consumed by Event Tracking, AdminCore).
  - **Events Consumed**:
    - `merchant.created`, `merchant.updated` (AdminCore).
    - `user.created`, `user.updated` (Users).
    - `rfm.updated` (RFM).
    - `points.updated` (Points).
    - `referral.created` (Referrals).
  - **Saga Patterns**: AdminFeatures → Event Tracking → Users for imports; AdminFeatures → RFM for exports.
- **Calls**:
  - `/users.v1/ImportCustomers` (gRPC, Users).
  - `/rfm.v1/UpdateThresholds`, `/rfm.v1/GetSegmentCounts`, `/rfm.v1/ExportSegments`, `/rfm.v1/GetVisualizations` (gRPC, RFM).
  - `/roles.v1/GetPermissions` (gRPC, Roles).
  - `/analytics.v1/GetROI` (gRPC, Analytics).
- **Called By**: Frontend, AdminCore, Users, RFM.

## GraphQL Schema
```graphql
type IntegrationStatus {
  integration_id: ID!
  merchant_id: ID!
  platform: String!
  status: String!
  error_details: JSON
  last_checked_at: String!
}

type RateLimitStatus {
  merchant_id: ID!
  shopify_api: JSON!
  integrations: JSON!
  endpoint_limits: JSON!
}

type QueueMetrics {
  merchant_id: ID!
  queue_name: String!
  jobs_in_queue: Int!
  retry_count: Int!
  dlq_status: String!
}

type RFMSegment {
  segment_name: String!
  customer_count: Int!
  last_refreshed: String!
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

type PlatformSettings {
  merchant_id: ID!
  rfm_thresholds: JSON!
  multi_currency_config: JSON!
  referral_config: JSON!
}

type EmailTemplate {
  template_id: ID!
  merchant_id: ID!
  template_name: String!
  content: JSON!
  fallback_language: String!
}

type RFMConfig {
  merchant_id: ID!
  thresholds: JSON!
}

type ExportStatus {
  export_id: ID!
  merchant_id: ID!
  format: String!
  status: String!
}

type EventStatus {
  event_id: ID!
  merchant_id: ID!
  event_type: String!
  status: String!
}

type SetupTask {
  task_id: ID!
  merchant_id: ID!
  task_name: String!
  status: String!
  completed_at: String
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

type LanguageSettings {
  default: String!
  supported: [String!]!
  rtl: [String!]!
}

type Query {
  getIntegrationHealth(merchant_id: ID!, platform: String!): IntegrationStatus!
  getRateLimits(merchant_id: ID!): RateLimitStatus!
  getQueueMetrics(merchant_id: ID!): QueueMetrics!
  getRFMSegmentCounts(merchant_id: ID!): [RFMSegment!]!
  getApiLogs(merchant_id: ID!, route: String, status_code: Int): [ApiLog!]!
  getAuditLogs(merchant_id: ID!, action: String): [AuditLog!]!
  getImportStatus(merchant_id: ID!, import_id: ID!): ImportStatus!
  getMerchantLanguage(merchant_id: ID!): LanguageSettings!
  getSetupProgress(merchant_id: ID!): [SetupTask!]!
}

type Mutation {
  configureIntegration(merchant_id: ID!, platform: String!, settings: JSON!): IntegrationStatus!
  syncSquare(merchant_id: ID!): IntegrationStatus!
  disableIntegration(merchant_id: ID!, platform: String!): IntegrationStatus!
  updatePlatformSettings(merchant_id: ID!, settings: JSON!): PlatformSettings!
  updateNotificationTemplate(merchant_id: ID!, template_id: ID!, content: JSON!): EmailTemplate!
  updateRFMThresholds(merchant_id: ID!, thresholds: JSON!): RFMConfig!
  exportRFMSegments(merchant_id: ID!, format: String!): ExportStatus!
  importCustomers(merchant_id: ID!, source: String!, file_url: String!): ImportStatus!
  simulateEvent(merchant_id: ID!, event_type: String!, payload: JSON!): EventStatus!
  replayLog(log_id: ID!): AuditLog!
}

type Subscription {
  onIntegrationHealth(merchant_id: ID!, platforms: [String!]): IntegrationStatus!
  onImportProgress(merchant_id: ID!, import_id: ID!): ImportStatus!
  onSetupProgress(merchant_id: ID!): [SetupTask!]!
  onLogs(merchant_id: ID!, actions: [String!]): AuditLog!
}
```

## Visualizations
- **Chart.js Integration**:
  - **RFM Visualizations**: Scatter plot (Recency vs. Monetary) in `AnalyticsPage.tsx` using Chart.js, sourced from `/rfm.v1/RFMService/GetVisualizations`.
  - **Queue Metrics**: Bar chart for jobs in queue, retry count, and DLQ status in `QueuesPage.tsx`, sourced from `getQueueMetrics`.
  - **Configuration**: Uses Chart.js with `scatter` and `bar` types, distinctive colors (e.g., `#1E90FF`, `#FF6347` for light/dark themes), non-log scale.
- **Frontend**: Rendered in `AnalyticsPage.tsx` and `QueuesPage.tsx` with Polaris components for drag-and-drop customization.

## Feature Flags
- **Tool**: LaunchDarkly
- **Features Controlled**:
  - RFM export (`rfm_export_enabled`)
  - Customer import (`customer_import_enabled`)
  - Event simulation (`event_simulation_enabled`)
  - Queue monitoring (`queue_monitoring_enabled`)
  - Onboarding progress (`onboarding_progress_enabled`)
  - Integration health (`integration_health_enabled`)
- **Configuration**: Flags toggled per merchant in Phases 4–5, tracked via PostHog (`feature_flag_toggled`).

## Key Endpoints
- **GraphQL**: `/graphql` (queries: `getIntegrationHealth`, `getRateLimits`, `getQueueMetrics`, `getRFMSegmentCounts`, `getApiLogs`, `getAuditLogs`, `getImportStatus`, `getMerchantLanguage`, `getSetupProgress`; mutations: `configureIntegration`, `syncSquare`, `disableIntegration`, `updatePlatformSettings`, `updateNotificationTemplate`, `updateRFMThresholds`, `exportRFMSegments`, `importCustomers`, `simulateEvent`, `replayLog`; subscriptions: `onIntegrationHealth`, `onImportProgress`, `onSetupProgress`, `onLogs`).
- **gRPC**:
  - `/adminfeatures.v1/AdminFeaturesService/GetRateLimits`
  - `/adminfeatures.v1/AdminFeaturesService/GetQueueMetrics`
  - `/adminfeatures.v1/AdminFeaturesService/ConfigureIntegration`
  - `/adminfeatures.v1/AdminFeaturesService/SyncSquare`
  - `/adminfeatures.v1/AdminFeaturesService/DisableIntegration`
  - `/adminfeatures.v1/AdminFeaturesService/UpdatePlatformSettings`
  - `/adminfeatures.v1/AdminFeaturesService/UpdateNotificationTemplate`
  - `/adminfeatures.v1/AdminFeaturesService/SimulateEvent`
  - `/adminfeatures.v1/AdminFeaturesService/StreamSetupProgress`
  - `/rfm.v1/RFMService/UpdateThresholds`
  - `/rfm.v1/RFMService/GetSegmentCounts`
  - `/rfm.v1/RFMService/ExportSegments`
  - `/rfm.v1/RFMService/GetVisualizations`
  - `/users.v1/UsersService/ImportCustomers`
- **REST**:
  - `/admin/v1/integrations/health`
  - `/admin/v1/integrations/square`
  - `/admin/v1/integrations/square/sync`
  - `/admin/v1/rate-limits`
  - `/admin/v1/rate-limits/queue`
  - `/admin/v1/settings`
  - `/admin/v1/rfm/config`
  - `/admin/v1/rfm/export`
  - `/admin/v1/rfm/visualizations`
  - `/admin/v1/customers/import`
  - `/admin/v1/events/simulate`
  - `/admin/v1/setup/stream`
  - `/admin/v1/logs/api`
  - `/admin/v1/logs/audit`
  - `/admin/v1/logs/stream`
  - `/admin/v1/logs/replay`
  - `/health`, `/ready`, `/metrics`
- **Access Patterns**: High read (integrations, rate limits, queue metrics), moderate write (imports, RFM exports).
- **Rate Limits**: Shopify API (2 req/s standard, 40 req/s Plus, 1–4 req/s Storefront), GraphQL queries limited to 500 points.

## Health and Readiness Checks
- **Health Endpoint**: `/health` (HTTP GET)
  - Returns `{ "status": "UP" }` if PostgreSQL, TimescaleDB, Kafka, Redis, and GraphQL server are operational.
- **Readiness Endpoint**: `/ready` (HTTP GET)
  - Returns `{ "ready": true }` when migrations and servers are initialized.
- **Consul Health Check**:
  - Registered via `registrator`: `SERVICE_NAME=admin-features`, `SERVICE_CHECK_HTTP=/health`.
  - Checks every 10s (timeout: 2s).
- **Validation**: Test in CI/CD: `curl http://admin-features:8080/health`.

## Service Discovery
- **Tool**: Consul (via `registrator`).
- **Configuration**:
  - Environment Variables: `SERVICE_NAME=admin-features`, `SERVICE_PORT=50052` (gRPC), `8080` (HTTP/GraphQL), `SERVICE_CHECK_HTTP=/health`, `SERVICE_TAGS=admin,features,integrations,rfm,imports`.
  - Network: `loyalnest`.
- **Validation**: `curl http://consul:8500/v1/catalog/service/admin-features`.

## Monitoring and Observability
- **Metrics**:
  - Endpoint: `/metrics` (Prometheus).
  - Key Metrics:
    - `admin_features_graphql_queries_total`: GraphQL query count.
    - `admin_features_integrations_configured_total`: Integrations configured.
    - `admin_features_rfm_exports_total`: RFM exports initiated.
    - `admin_features_imports_initiated_total`: Customer imports initiated.
    - `admin_features_events_simulated_total`: Simulated events.
    - `admin_features_log_replays_total`: Log replays.
    - `graphql_query_duration_seconds`: GraphQL query latency.
    - `redis_cache_hit_rate`: Cache hit rate (>95%).
    - `queue_latency_seconds`: Queue processing latency (<2s).
  - **Logging**: Structured JSON logs via Loki, tagged with `shop_domain`, `merchant_id`, `service_name=admin-features`, `locale`.
  - **Alerting**: Prometheus Alertmanager, AWS SNS for rate limits (80% threshold), integration failures (>3 timeouts in 5s), queue failures.
  - **Event Tracking**: PostHog (`admin_integration_alert_sent`, `referral_fallback_triggered`, `square_sync_triggered`, `rate_limit_viewed`, `queue_metrics_viewed`, `customer_import_completed`, `rfm_preview_viewed`, `visualization_viewed`, `admin_event_simulated`, `setup_progress_viewed`, `admin_log_replay`, `feature_flag_toggled`).

## Security Considerations
- **Authentication**: GraphQL/gRPC: JWT via Auth service; REST: API key + HMAC (Nginx).
- **Authorization**: RBAC via `/roles.v1/GetPermissions` (`admin:full`, `admin:analytics`, `admin:support`, `admin:points`, `admin:merchants:view:shopify_plus`, `admin:merchants:edit:plan`).
- **Data Protection**:
  - `merchants.api_token`, `email_events.recipient_email`, `data_imports.email` encrypted with AES-256 via `pgcrypto`.
  - Kafka events encrypted with TLS.
- **IP Whitelisting**: Restrict access via `merchants.ip_whitelist` (Redis: `admin:ip_whitelist:{merchant_id}`, TTL 7d).
- **Anomaly Detection**: Alert on >3 rate limit breaches/hour or >50 import failures/hour via AWS SNS.
- **Security Testing**: OWASP ZAP (ECL: 256) for `/graphql`, `/admin/v1/*`, `/admin/v1/logs/*`.

## Testing Strategy
- **Unit Tests**: Jest for `AdminFeaturesRepository`, GraphQL resolvers (`getIntegrationHealth`, `getRateLimits`, `updateRFMThresholds`, `importCustomers`, `simulateEvent`, `replayLog`), and LaunchDarkly feature flag logic.
- **Integration Tests**: Testcontainers for PostgreSQL, TimescaleDB, Kafka, Redis, GraphQL server, Bull queues, and Yotpo/Judge.me integrations.
- **Contract Tests**: Pact for gRPC, Kafka, GraphQL schema.
- **E2E Tests**: Cypress for `/graphql`, `/admin/v1/integrations/*`, `/admin/v1/rfm/*`, `/admin/v1/customers/import`, `/admin/v1/setup/stream`, `/admin/v1/logs/*`, and Chart.js visualizations.
- **Load Tests**: k6 for `/graphql` (500 req/s, <200ms latency), `/admin/v1/rfm/export` (<5s for 50,000 customers).
- **Chaos Tests**: Chaos Mesh for PostgreSQL, TimescaleDB, Kafka, Redis, Bull queue failures.
- **Compliance Tests**: Verify encryption, audit logging, GDPR compliance.
- **i18n Tests**: Validate all supported languages, RTL for `ar`, `he` (90%+ accuracy) with 2–3 native speakers via “LoyalNest Collective” Slack.

## Deployment
- **Docker Compose**:
  - Image: `admin-features:latest`.
  - Ports: `50052` (gRPC), `8080` (HTTP/GraphQL).
  - Environment Variables: `ADMIN_FEATURES_DB_HOST`, `KAFKA_BROKER`, `REDIS_HOST`, `GRAPHQL_PORT=8080`, `LAUNCHDARKLY_SDK_KEY`.
  - Network: `loyalnest`.
- **Resource Limits**: CPU: 0.5 cores, Memory: 512MiB.
- **Scaling**: 2 replicas for 5,000 merchants, 50,000 customers, 100 concurrent admin actions.
- **Orchestration**: Kubernetes (Phase 6) with liveness/readiness probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, OWASP ZAP, and LaunchDarkly flag validation.

## Feedback Collection
- **Method**: Typeform survey with 5–10 admin users (2–3 Shopify Plus) in Phases 4–5 to validate usability, RFM visualizations, queue monitoring, and i18n accuracy.
- **Validation**: Engage 2–3 native speakers per language via “LoyalNest Collective” Slack for translation accuracy (90%+).
- **Tracking**: Log feedback in Notion, track via PostHog (`merchant_feedback_submitted`).
- **Deliverable**: Feedback report with Shopify Plus insights by February 1, 2026.

## Risks and Mitigations
- **GraphQL Complexity**: Query depth limit (8), complexity budget (500 points).
- **Integration Failures**: AWS SES fallback, kill switch for persistent errors (>3 timeouts in 5s).
- **Import Failures**: Log errors in `data_imports.error_log`, 5 retries via Bull queues.
- **Rate Limit Breaches**: Redis tracking, Slack/email alerts at 80% limit.
- **Translation Accuracy**: Validate with 2–3 native speakers per language via “LoyalNest Collective” Slack.
- **Visualization Rendering**: Ensure Chart.js compatibility with light/dark themes, test with Cypress.

## Documentation and Maintenance
- **API Documentation**: GraphQL schema in `schema.graphql`, OpenAPI for REST, gRPC proto files.
- **Event Schema**: `integration.configured`, `rfm_export.initiated`, `customer_import.initiated`, `event.simulated`, `referral_fallback_triggered`, `square_sync_triggered`, `log.replayed` in Confluent Schema Registry.
- **Runbook**: Health check (`curl http://admin-features:8080/health`), logs via Loki, LaunchDarkly flag management.
- **Maintenance**: Rotate credentials quarterly, validate Backblaze B2 backups weekly.

## Action Items
- [ ] Deploy `admin_features_db` with new tables by September 15, 2025 (Owner: DB Team).
- [ ] Implement `/graphql` (new queries/mutations) by October 15, 2025 (Owner: Dev Team).
- [ ] Test `rfm_export.initiated`, `customer_import.completed`, `event.simulated` by November 1, 2025 (Owner: Dev Team).
- [ ] Implement integration health, queue monitoring, and Chart.js visualizations by December 1, 2025 (Owner: Dev Team).
- [ ] Configure LaunchDarkly feature flags by December 15, 2025 (Owner: Dev Team).
- [ ] Set up Prometheus/Loki for new metrics by January 15, 2026 (Owner: SRE Team).
- [ ] Conduct Typeform survey and validate translations by February 1, 2026 (Owner: Frontend Team).

## Timeline
- **Start Date**: September 1, 2025 (Phase 1 for Must Have).
- **Completion Date**: February 17, 2026 (Must Have), April 30, 2026 (Should Have, TVP completion).
- **Risks to Timeline**: RFM export complexity, integration testing, translation validation, visualization rendering.

## Dependencies
- **Internal**: Core, Users, Roles, RFM, Points, Referrals, Analytics, Auth, Event Tracking, Frontend.
- **External**: Shopify APIs, Klaviyo, Postscript, Square, Yotpo, Judge.me, Mailchimp, LaunchDarkly.

Recommendations:

GraphQL Setup:
Use @nestjs/graphql with Apollo Server for /graphql.
Enforce query depth limit (8) and complexity budget (500 points).
Host GraphiQL for testing new endpoints.

Database:
Deploy rfm_segment_counts, rfm_segment_deltas, customer_segments, email_templates with partitioning and encryption.
Validate tsvector for merchant search and RTL support in merchants.language.

Integrations:
Implement Yotpo/Judge.me with health checks (/admin/v1/integrations/health).
Add kill switch logic for disableIntegration with AWS SNS alerts.

Monitoring:
Configure Prometheus for new metrics (admin_features_rfm_exports_total, queue_latency_seconds).
Set up Loki for logs with locale tags and PostHog for events.

Testing:
Use Cypress for E2E tests on /admin/v1/rfm/visualizations and /admin/v1/setup/stream.
Validate RTL rendering with native speakers via “LoyalNest Collective” Slack.

Feedback:
Conduct Typeform survey with 5–10 admin users in Phases 4–5 to validate usability and i18n accuracy.