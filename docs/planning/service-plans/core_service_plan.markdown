# Core Service Plan

## Overview
- **Purpose**: Manages customer data, loyalty program settings, and import logs for the LoyalNest Shopify app, serving as the central hub for loyalty operations. Integrates with RFM Analytics for customer segmentation, Shopify APIs for imports, and AdminFeatures for advanced configurations. Supports Shopify Plus scale (50,000+ customers, 10,000 orders/hour) with RBAC, multilingual support (22 languages, including RTL for `ar`, `he`), and GDPR/CCPA compliance.
- **Priority for TVP**: Medium (Phase 1 for Must Have, Phase 3 for Should Have; supports Points, Referrals, RFM Analytics, Campaign).
- **Dependencies**: Auth (merchant validation), RFM Analytics (RFM scores), AdminFeatures (import logs, RFM configs), Points (rewards), Referrals (referral data), API Gateway (routing), AdminCore (audit logging), Frontend (customer management UI), Shopify API (scopes: `read_customers`, `write_customers`, `read_orders`).

## Database Setup
- **Database Type**: PostgreSQL (port: 5433), Redis (port: 6380)
- **PostgreSQL Tables**:
  - `customers`:
    - `id`: UUID, PK, NOT NULL
    - `merchant_id`: UUID, FK → `merchants`, NOT NULL
    - `email`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `rfm_score`: JSONB (e.g., `{"recency": 90, "frequency": 5, "monetary": 1000}`)
    - `metadata`: JSONB (e.g., `{"first_name": "John", "last_purchase": "2025-07-01"}`, sanitized for PII)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
    - `updated_at`: TIMESTAMP(3)
  - `program_settings`:
    - `id`: UUID, PK, NOT NULL
    - `merchant_id`: UUID, FK → `merchants`, UNIQUE, NOT NULL
    - `rfm_thresholds`: JSONB (e.g., `{"recency": {"min": 7, "max": 90}, "frequency": {"min": 1, "max": 10}, "monetary": {"min": 50, "max": 2500}}`)
    - `loyalty_config`: JSONB (e.g., `{"points_per_dollar": 10, "languages": ["en", "ar"]}`)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `customer_import_logs`:
    - `import_id`: UUID, PK, NOT NULL
    - `merchant_id`: UUID, FK → `merchants`, NOT NULL
    - `source`: TEXT, CHECK IN ('shopify', 'smile_io', 'loyaltylion', 'custom')
    - `status`: TEXT, CHECK IN ('pending', 'processing', 'completed', 'failed')
    - `record_count`: INTEGER, CHECK >= 0
    - `error_log`: JSONB (e.g., `{"row": 10, "error": "Duplicate email"}`)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
- **Redis Keys**:
  - `customer:{merchant_id}:{customer_id}`: Caches `rfm_score`, `metadata` (TTL: 24h).
  - `settings:{merchant_id}`: Caches `program_settings` (TTL: 7d).
  - `rate_limit:{merchant_id}:{endpoint}`: Tracks API calls (TTL: 60s).
- **Schema Details**:
  - Indexes: `idx_customers_merchant_id` (btree: `merchant_id`), `idx_customers_rfm_score` (gin: `rfm_score`), `idx_program_settings_merchant_id` (btree: `merchant_id`), `idx_customer_import_logs_merchant_id_status` (btree: `merchant_id`, `status`), `idx_customers_metadata` (gin: `metadata`).
  - Triggers: `trg_customers_updated_at` (update `updated_at` on change), `trg_encrypt_email` (encrypt `email`), `trg_sanitize_metadata` (remove PII from `metadata`).
  - Encryption: `customers.email`, `customer_import_logs.error_log` (if PII) encrypted with AES-256 via `pgcrypto`.
  - Partitioning: `customers`, `customer_import_logs` partitioned by `merchant_id` for scalability.
  - Redis: `volatile-lru` eviction for caches, AOF persistence synced every 1s to Backblaze B2.
- **GDPR/CCPA Compliance**: Encrypts `email`, sanitizes `metadata` (remove `first_name`, `phone`), logs GDPR actions in `audit_logs` via AdminCore, 90-day retention in Backblaze B2.

## Inter-Service Communication
- **Synchronous Communication**:
  - **GraphQL**:
    - Endpoint: `/graphql`
    - Queries:
      - `getCustomer(merchant_id: ID!, customer_id: ID!): Customer!`
      - `getCustomerRFM(merchant_id: ID!, customer_id: ID!): RFMScore!`
      - `getProgramSettings(merchant_id: ID!): ProgramSettings!`
      - `getImportLogs(merchant_id: ID!, status: String): [ImportLog!]!`
    - Mutations:
      - `createCustomer(merchant_id: ID!, input: CustomerInput!): Customer!`
      - `updateCustomer(merchant_id: ID!, customer_id: ID!, input: CustomerInput!): Customer!`
      - `updateProgramSettings(merchant_id: ID!, input: SettingsInput!): ProgramSettings!`
      - `importCustomers(merchant_id: ID!, source: String!, file_url: String!): ImportLog!`
    - Subscriptions:
      - `onCustomerUpdate(merchant_id: ID!): Customer!`
      - `onImportProgress(merchant_id: ID!, import_id: ID!): ImportLog!`
  - **gRPC**:
    - `/core.v1/CoreService/GetCustomer` (input: `merchant_id, customer_id`; output: `email, rfm_score, metadata`)
    - `/core.v1/CoreService/GetCustomerRFM` (input: `merchant_id, customer_id`; output: `rfm_score`)
    - `/core.v1/CoreService/CreateCustomer` (input: `merchant_id, email, metadata`; output: `customer_id`)
    - `/core.v1/CoreService/UpdateCustomer` (input: `merchant_id, customer_id, metadata`; output: `customer_id`)
    - `/core.v1/CoreService/UpdateProgramSettings` (input: `merchant_id, rfm_thresholds, loyalty_config`; output: `settings_id`)
    - `/core.v1/CoreService/ImportCustomers` (input: `merchant_id, source, file_url`; output: `import_id`)
    - Calls `/auth.v1/ValidateMerchant` (Auth)
    - Calls `/adminfeatures.v1/GetRFMSegmentCounts` (AdminFeatures)
  - **REST**:
    - `/core/v1/customers` (POST, GET): Create/retrieve customers.
    - `/core/v1/settings` (POST, GET): Update/retrieve program settings.
    - `/core/v1/imports` (POST, GET): Initiate/retrieve import logs.
    - `/health`, `/ready`, `/metrics`
  - **WebSocket**:
    - `/core/v1/updates/stream`: Streams customer and import updates.
- **Asynchronous Communication**:
  - **Events Produced**:
    - `customer.created`: `{ customer_id: string, merchant_id: string, email: string, created_at: timestamp }` (consumers: Campaign, AdminFeatures, Points)
    - `customer.updated`: `{ customer_id: string, merchant_id: string, rfm_score: object, metadata: object, updated_at: timestamp }` (consumers: RFM Analytics, AdminCore)
    - `import.initiated`: `{ import_id: string, merchant_id: string, source: string, created_at: timestamp }` (consumer: AdminFeatures)
  - **Events Consumed**:
    - `rfm.updated` (RFM Analytics): Updates `customers.rfm_score`.
    - `gdpr_request.created` (AdminCore): Redacts `customers.email`, `metadata`.
    - `points.updated` (Points): Updates `customers.metadata`.
    - `referral.created` (Referrals): Updates `customers.metadata`.
  - **Event Schema**: Registered in Confluent Schema Registry, Avro format.
  - **Saga Patterns**: Points (`points.earned`) → RFM Analytics (`rfm.updated`) → Core (`rfm_score` update); Core → AdminFeatures → Users for customer imports.
- **Calls**:
  - `/auth.v1/ValidateMerchant` (gRPC, Auth)
  - `/adminfeatures.v1/GetRFMSegmentCounts` (gRPC, AdminFeatures)
  - `/roles.v1/GetPermissions` (gRPC, Roles)
- **Called By**: Frontend, AdminFeatures, Points, Referrals, Campaign, API Gateway, AdminCore.

## GraphQL Schema
```graphql
type Customer {
  id: ID!
  merchant_id: ID!
  email: String!
  rfm_score: JSON!
  metadata: JSON!
  created_at: String!
  updated_at: String
}

type RFMScore {
  recency: Int!
  frequency: Int!
  monetary: Int!
}

type ProgramSettings {
  id: ID!
  merchant_id: ID!
  rfm_thresholds: JSON!
  loyalty_config: JSON!
  created_at: String!
}

type ImportLog {
  import_id: ID!
  merchant_id: ID!
  source: String!
  status: String!
  record_count: Int!
  error_log: JSON
  created_at: String!
}

input CustomerInput {
  email: String!
  metadata: JSON!
}

input SettingsInput {
  rfm_thresholds: JSON!
  loyalty_config: JSON!
}

type Query {
  getCustomer(merchant_id: ID!, customer_id: ID!): Customer!
  getCustomerRFM(merchant_id: ID!, customer_id: ID!): RFMScore!
  getProgramSettings(merchant_id: ID!): ProgramSettings!
  getImportLogs(merchant_id: ID!, status: String): [ImportLog!]!
}

type Mutation {
  createCustomer(merchant_id: ID!, input: CustomerInput!): Customer!
  updateCustomer(merchant_id: ID!, customer_id: ID!, input: CustomerInput!): Customer!
  updateProgramSettings(merchant_id: ID!, input: SettingsInput!): ProgramSettings!
  importCustomers(merchant_id: ID!, source: String!, file_url: String!): ImportLog!
}

type Subscription {
  onCustomerUpdate(merchant_id: ID!): Customer!
  onImportProgress(merchant_id: ID!, import_id: ID!): ImportLog!
}
```

## Key Endpoints
- **GraphQL**: `/graphql` (queries: `getCustomer`, `getCustomerRFM`, `getProgramSettings`, `getImportLogs`; mutations: `createCustomer`, `updateCustomer`, `updateProgramSettings`, `importCustomers`; subscriptions: `onCustomerUpdate`, `onImportProgress`).
- **gRPC**:
  - `/core.v1/CoreService/GetCustomer`
  - `/core.v1/CoreService/GetCustomerRFM`
  - `/core.v1/CoreService/CreateCustomer`
  - `/core.v1/CoreService/UpdateCustomer`
  - `/core.v1/CoreService/UpdateProgramSettings`
  - `/core.v1/CoreService/ImportCustomers`
- **REST**:
  - `/core/v1/customers` (POST, GET)
  - `/core/v1/settings` (POST, GET)
  - `/core/v1/imports` (POST, GET)
  - `/health`, `/ready`, `/metrics`
- **WebSocket**:
  - `/core/v1/updates/stream`: Streams customer/import updates.
- **Access Patterns**: High read (`rfm_score`, `program_settings`), moderate write (customer imports, settings updates).
- **Rate Limits**:
  - Shopify API: 40 req/s (Plus), 2 req/s (standard), 1–4 req/s (Storefront).
  - Internal: 100 req/s for `/core/v1/*`, tracked in Redis (`rate_limit:{merchant_id}:core`).

## Health and Readiness Checks
- **Health Endpoint**: `/health` (HTTP GET)
  - Returns `{ "status": "UP" }` if PostgreSQL, Redis, and Kafka are operational.
- **Readiness Endpoint**: `/ready` (HTTP GET)
  - Returns `{ "ready": true }` when migrations and Redis are initialized.
- **Consul Health Check**:
  - Registered via `registrator`: `SERVICE_NAME=core`, `SERVICE_CHECK_HTTP=/health`.
  - Checks every 10s (timeout: 2s).
- **Validation**: Test in CI/CD: `curl http://core:8080/health`.

## Service Discovery
- **Tool**: Consul (via `registrator`).
- **Configuration**:
  - Environment Variables: `SERVICE_NAME=core`, `SERVICE_PORT=50051` (gRPC), `8080` (HTTP/GraphQL), `SERVICE_CHECK_HTTP=/health`, `SERVICE_TAGS=core,customers,settings`.
  - Network: `loyalnest`.
- **Validation**: `curl http://consul:8500/v1/catalog/service/core`.

## Monitoring and Observability
- **Metrics**:
  - Endpoint: `/metrics` (Prometheus).
  - Key Metrics:
    - `core_customers_created_total`: Customers created by merchant.
    - `core_imports_initiated_total`: Imports initiated.
    - `core_rfm_reads_total`: RFM score reads.
    - `graphql_query_duration_seconds`: GraphQL query latency.
    - `redis_cache_hit_rate`: Cache hit rate (>95%).
  - **Logging**: Structured JSON logs via Loki, tagged with `shop_domain`, `merchant_id`, `service_name=core`, `locale`.
  - **Alerting**: Prometheus Alertmanager, AWS SNS for import failures (>3/hour), high read latency (>500ms), or GDPR redaction errors.
  - **Event Tracking**: PostHog (`customer_created`, `customer_updated`, `import_initiated`, `rfm_score_updated`, `feature_flag_toggled`).

## Security Considerations
- **Authentication**: GraphQL/gRPC: JWT via `/auth.v1/ValidateToken`; REST: API key + HMAC (Nginx).
- **Authorization**: RBAC via `/roles.v1/GetPermissions` (`admin:full`, `admin:customers:edit`, `admin:customers:view`).
- **Data Protection**:
  - Encrypt `customers.email`, `customer_import_logs.error_log` (if PII) with AES-256 via `pgcrypto`.
  - Sanitize `customers.metadata` to remove PII (`first_name`, `phone`).
  - Kafka events encrypted with TLS.
- **IP Whitelisting**: Restrict access via `ip_whitelist:{merchant_id}` in Redis (TTL: 7d).
- **Anomaly Detection**: Alert on >5 import failures/hour or >10 unauthorized accesses/hour via AWS SNS.
- **Security Testing**: OWASP ZAP (ECL: 256) for `/graphql`, `/core/v1/*`, `/core/v1/updates/stream`.

## Feature Flags
- **Tool**: LaunchDarkly
- **Features Controlled**:
  - Customer import (`customer_import_enabled`)
  - RFM score retrieval (`rfm_score_enabled`)
  - Program settings update (`settings_update_enabled`)
- **Configuration**: Flags toggled per merchant in Phases 4–5, tracked via PostHog (`feature_flag_toggled`).

## Testing Strategy
- **Unit Tests**: Jest for `CoreRepository` (`findById`, `updateRFMScore`, `createCustomer`, `importCustomers`), JSONB validation, and LaunchDarkly flag logic.
- **Integration Tests**: Testcontainers for PostgreSQL, Redis, Kafka, and Shopify API mock server.
- **Contract Tests**: Pact for gRPC (`/core.v1/*`, `/auth.v1/*`), Kafka (`customer.created`, `customer.updated`).
- **E2E Tests**: Cypress for `/graphql`, `/core/v1/customers`, `/core/v1/imports`, `/core/v1/updates/stream`.
- **Load Tests**: k6 for 5,000 customer reads/hour, 1,000 imports/hour (<200ms latency).
- **Chaos Tests**: Chaos Mesh for PostgreSQL, Redis, and Kafka failures.
- **Compliance Tests**: Verify encryption, PII sanitization, audit logging via AdminCore.
- **i18n Tests**: Validate `loyalty_config` languages, RTL for `ar`, `he` (90%+ accuracy).

## Deployment
- **Docker Compose**:
  - Image: `core:latest`.
  - Ports: `50051` (gRPC), `8080` (HTTP/GraphQL/WebSocket).
  - Environment Variables: `CORE_DB_HOST`, `KAFKA_BROKER`, `REDIS_HOST`, `LAUNCHDARKLY_SDK_KEY`, `SHOPIFY_API_KEY`, `SHOPIFY_API_SECRET`.
  - Network: `loyalnest`.
- **Resource Limits**: CPU: 0.5 cores, Memory: 512MiB.
- **Scaling**: 3 replicas, 2 read replicas for `customers` for 5,000 merchants.
- **Orchestration**: Kubernetes (Phase 6) with liveness/readiness probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, OWASP ZAP, and LaunchDarkly validation.

## Feedback Collection
- **Method**: Typeform survey with 5–10 admin users (2–3 Shopify Plus) in Phases 4–5 to validate customer management and import usability.
- **Validation**: Engage 2–3 native speakers for `ar`, `he` settings via “LoyalNest Collective” Slack.
- **Tracking**: Log feedback in Notion, track via PostHog (`core_feedback_submitted`).
- **Deliverable**: Feedback report by February 1, 2026.

## Risks and Mitigations
- **High Read Latency**: Cache `rfm_score`, `program_settings` in Redis; GIN index on `rfm_score`.
- **Shopify Rate Limits**: Batch imports (500 customers/request), track in Redis, alert at 80% limit.
- **Import Failures**: Log errors in `customer_import_logs`, retry 5 times with exponential backoff.
- **Data Consistency**: Use transactions for `customers` updates, validate with `trg_sanitize_metadata`.
- **Translation Accuracy**: Validate `loyalty_config` with native speakers.

## Documentation and Maintenance
- **API Documentation**: OpenAPI for REST (`/core/v1/*`), gRPC proto files, GraphQL schema in `schema.graphql`.
- **Event Schema**: `customer.created`, `customer.updated`, `import.initiated` in Confluent Schema Registry (Avro).
- **Runbook**: Health check (`curl http://core:8080/health`), logs via Loki, LaunchDarkly flag management.
- **Maintenance**: Rotate API keys quarterly, validate Backblaze B2 backups weekly.

## Action Items
- [ ] Deploy `core_db` and Redis by September 15, 2025 (Owner: DB Team).
- [ ] Implement `/graphql` and `/core/v1/*` endpoints by October 15, 2025 (Owner: Dev Team).
- [ ] Test `customer.created`, `customer.updated`, `import.initiated` events by November 1, 2025 (Owner: Dev Team).
- [ ] Configure LaunchDarkly feature flags by November 15, 2025 (Owner: Dev Team).
- [ ] Set up Prometheus/Loki for metrics and logs by December 1, 2025 (Owner: SRE Team).
- [ ] Conduct Typeform survey and validate translations by February 1, 2026 (Owner: Frontend Team).

## Timeline
- **Start Date**: September 1, 2025 (Phase 1 for Must Have).
- **Completion Date**: February 17, 2026 (Must Have), April 30, 2026 (Should Have, TVP completion).
- **Risks to Timeline**: Shopify API integration, RFM score scalability, translation validation.

## Dependencies
- **Internal**: Auth, RFM Analytics, AdminFeatures, Points, Referrals, AdminCore, API Gateway, Roles, Frontend.
- **External**: Shopify APIs, LaunchDarkly.

Recommendations

Implementation: Use @nestjs/graphql for GraphQL, @nestjs/microservices for gRPC, and ws for WebSocket streaming.
Database: Deploy PostgreSQL with partitioning and Redis for caching; validate with pgbench.
Testing: Simulate 5,000 customer reads/hour with k6, test Shopify imports with mock server.
Monitoring: Set up Grafana dashboards for core_customers_created_total and core_rfm_reads_total.
Feedback: Engage Shopify Plus merchants early (Phase 4) to validate import usability.

Minor Improvement Suggestions
Area	Suggestion
WebSocket Scale	Add backoff or pub/sub queuing (e.g., Redis streams) if WebSocket broadcast volume increases significantly.
Retry Strategy	Retry logic for importCustomers is mentioned — consider exponential jitter backoff details in runbook.
Schema Governance	rfm_score and metadata fields are flexible; ensure schema validation at ingress to prevent inconsistencies.
Redundancy	Enable replication on Redis and Postgres for 5k+ merchants—ensure HA for GDPR hooks.

✅ Conclusion
The Core Service Plan is highly robust and well-aligned with LoyalNest's:

🧱 Architecture documents

📋 Feature roadmaps (Must-Have + Should-Have)

🔐 Security & GDPR requirements

🧪 Testing + CI/CD maturity

You’re well-positioned to proceed with implementation. Would you like help scaffolding the service using NestJS (e.g., GraphQL module, gRPC handlers, Redis service), or generating test templates for the GraphQL API?