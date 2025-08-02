# Users Service Plan (Revised)

## Overview
- **Purpose**: Manages customer and admin user data, including profiles, authentication details, and preferences for LoyalNest, supporting customer interactions (e.g., US-CW2, US-CW7, US-BI3) and admin management (e.g., US-AM14, US-AM15) with multilingual support and robust audit logging.
- **Priority for TVP**: High (core for authentication, points earning, and imports).
- **Dependencies**: `auth-service` (JWT validation, OAuth), `points-service` (points updates), `admin-service` (multi-tenant config), `roles-service` (RBAC), Event Tracking (notifications), Campaign (tier-based access), Shopify API (GraphQL user data), Klaviyo/Postscript (notifications), Kafka (event streaming), Consul (service discovery), Redis (caching, idempotency), PostgreSQL (persistent storage), Prometheus (metrics), Loki (logging), Backblaze B2 (audit log retention).

## Database Setup
- **Database Type**: PostgreSQL (port: 5432), Redis (port: 6379).
- **Tables**: `customers`, `admin_users`, `processed_events`, `translations`, `audit_logs`.
- **Redis Keys**:
  - `customer:{customer_id}`: Caches `/users.v1/GetCustomer` responses (TTL: 1h).
  - `admin_user:{admin_user_id}`: Caches `/users.v1/GetAdminUser` responses (TTL: 1h).
  - `processed:{merchant_id}:{event_id}`: Tracks processed Kafka events/webhooks (TTL: 24h).
  - `translations:{key}:{locale}`: Caches localized messages (TTL: 24h).
  - `jwt_blacklist:{jti}`: Tracks invalidated JWTs (TTL: 1h for `/users.v1/UpdateCustomer`, 24h otherwise).
  - **Eviction**: `volatile-lru` for caches, `noeviction` for processed events and JWT blacklist.

### `customers` Schema
| Column           | Type       | Constraints                                                                 |
|------------------|------------|-----------------------------------------------------------------------------|
| `customer_id`    | UUID       | Primary Key                                                                 |
| `merchant_id`    | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `email`          | TEXT       | AES-256 encrypted, Indexed                                                 |
| `points_balance` | INTEGER    | DEFAULT 0                                                                  |
| `rfm_score`      | JSONB      | e.g., `{ "recency": 3, "frequency": 2, "monetary": 4 }`                   |
| `language`       | TEXT       | ENUM: ['en', 'es', 'fr', 'ar', 'de', 'pt', 'ja', ...], DEFAULT 'en'       |
| `schema_version` | TEXT       | e.g., "1.0.0", for schema evolution                                        |
| `created_at`     | TIMESTAMP(3) | DEFAULT now()                                                            |
| `updated_at`     | TIMESTAMP(3) | Auto-updated via trigger                                                  |
| `correlation_id` | UUID       | For tracing across services                                                |

### `admin_users` Schema
| Column           | Type       | Constraints                                                                 |
|------------------|------------|-----------------------------------------------------------------------------|
| `admin_user_id`  | UUID       | Primary Key                                                                 |
| `merchant_id`    | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `email`          | TEXT       | AES-256 encrypted, Indexed                                                 |
| `metadata`       | JSONB      | e.g., `{ "rbac_scopes": ["admin:full"], "locale": "en" }`                  |
| `schema_version` | TEXT       | e.g., "1.0.0", for schema evolution                                        |
| `created_at`     | TIMESTAMP(3) | DEFAULT now()                                                            |
| `updated_at`     | TIMESTAMP(3) | Auto-updated via trigger                                                  |

### `processed_events` Schema
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `event_id`    | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `event_type`  | TEXT       | ENUM: ['customer.created', 'customer.updated', 'admin_user.updated', 'customer.task'] |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (24h)                                            |

### `translations` Schema
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `id`          | UUID       | Primary Key                                                                 |
| `key`         | TEXT       | Unique, e.g., "customer.created"                                           |
| `locale`      | TEXT       | ENUM: ['en', 'es', 'fr', 'ar', 'de', 'pt', 'ja', ...]                     |
| `value`       | TEXT       | Localized text, e.g., "Customer created successfully"                      |
| `version`     | TEXT       | e.g., "1.0.0", for translation versioning                                  |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (90 days)                                         |

### `audit_logs` Schema
| Column           | Type       | Constraints                                                                 |
|------------------|------------|-----------------------------------------------------------------------------|
| `log_id`         | UUID       | Primary Key                                                                 |
| `admin_user_id`  | UUID       | Foreign Key → `admin_users`, Indexed                                       |
| `merchant_id`    | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `action`         | TEXT       | e.g., `customer_updated`, `admin_user_updated`                             |
| `metadata`       | JSONB      | e.g., `{ "customer_id": "customer_123", "locale": "en" }`                  |
| `created_at`     | TIMESTAMP(3) | DEFAULT now(), TTL index (180 days)                                        |

### Constraints & Indexes
- **Unique Index**: `unique_customers_merchant_email` (btree: `merchant_id`, `email`).
- **Indexes**:
  - `idx_customers_merchant_id` (btree: `merchant_id`).
  - `idx_customers_email` (btree: `email`).
  - `idx_admin_users_merchant_id` (btree: `merchant_id`).
  - `idx_admin_users_email` (btree: `email`).
  - `idx_audit_logs_admin_user_id` (btree: `admin_user_id`).
  - `idx_audit_logs_merchant_id` (btree: `merchant_id`).
  - `idx_processed_events_merchant_id` (btree: `merchant_id`).
  - `idx_translations_key_locale` (btree: `key`, `locale`).
- **Triggers**:
  - `trg_updated_at`: Updates `updated_at` on `customers`, `admin_users` row changes.
  - `trg_validate_metadata`: Validates `metadata.locale` against `translations` on insert/update.
- **Row-Level Security (RLS)**: Enabled on `customers`, `admin_users`, `audit_logs` to restrict access by `merchant_id`.
- **Partitioning**: `customers` and `audit_logs` partitioned by `merchant_id` for scalability.
- **TTL Index**: `processed_events.created_at` (24h), `translations.created_at` (90 days), `audit_logs.created_at` (180 days).

### GDPR/CCPA Compliance
- PII (`email`) encrypted with AES-256 in `customers` and `admin_users`.
- Audit logs emitted to Kafka (`customer.updated`, `admin_user.updated`), retained for 90–180 days (configurable per `merchant_id`) in Backblaze B2, with cold-tier archival after 180 days.
- Merchant-initiated purge API (`/users.v1/PurgeAuditLogs`) for CCPA compliance.
- `metadata` JSONB sanitized to exclude PII, validated against `translations`.
- Data deletion via `DELETE FROM customers` with cascading deletes to `audit_logs`.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by Users Service)
| Endpoint                      | Input                              | Output                        | Called By       | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/users.v1/GetCustomer`       | `customer_id`, `merchant_id`, `locale` | `email`, `points_balance`, `language` | `points-service`, `rfm-service`, `admin-service` | Fetches customer profile.         |
| `/users.v1/UpdateCustomer`    | `customer_id`, `merchant_id`, `email`, `language` | `Customer`       | `admin-service` | Updates customer data.            |
| `/users.v1/GetAdminUser`      | `admin_user_id`, `merchant_id`     | `email`, `metadata`           | `roles-service`, `admin-service` | Fetches admin user data.          |
| `/users.v1/PurgeAuditLogs`    | `merchant_id`, `jwt_token`         | `status`                      | `admin-service` | Purges audit logs for CCPA.       |

#### gRPC Calls (Made by Users Service)
| Endpoint                      | Input                              | Output                        | Service         | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/auth.v1/ValidateToken`      | `jwt_token`                        | `merchant_id`, `scopes`       | `auth-service`  | Validates JWT for gRPC/REST calls. |

#### REST Endpoints (Consumed via API Gateway)
| Endpoint               | Method | Source         | Purpose                           |
|------------------------|--------|----------------|-----------------------------------|
| `/api/users/import`    | POST   | Admin UI       | Triggers async customer import.   |
| `/webhooks/users/update` | POST   | Shopify API    | Updates customer data.            |

- **Port**: 50051 (gRPC), 8080 (REST).
- **Authentication**: JWT via `/auth.v1/ValidateToken` with `jti` blacklisting in Redis (`jwt_blacklist:{jti}`, TTL: 1h for `/users.v1/UpdateCustomer`, 24h otherwise).
- **Authorization**: RBAC (`admin:users:view`, `admin:users:edit`) via API Gateway.
- **Security**: mTLS for internal gRPC communication (Vault-managed certs).
- **Service Discovery**: Consul (`SERVICE_NAME=users`, `SERVICE_CHECK_HTTP=/health`).
- **Rate Limits**: Shopify API (2 req/s, REST), internal (100 req/s per merchant for imports), IP-based (100 req/s per IP for REST endpoints).

### Asynchronous Communication
#### Events Produced (Kafka)
| Event                 | Payload                                            | Consumed By         | Description                       |
|-----------------------|----------------------------------------------------|---------------------|-----------------------------------|
| `customer.created`    | `{ event_id, customer_id, merchant_id, email, language, schema_version, created_at, correlation_id }` | `points-service`, `rfm-service`, `campaign-service`, Event Tracking | Signals customer creation.        |
| `customer.updated`    | `{ event_id, customer_id, merchant_id, email, language, schema_version, created_at, correlation_id }` | `rfm-service`, `admin-service`, Event Tracking | Signals customer update.          |
| `admin_user.updated`  | `{ event_id, admin_user_id, merchant_id, email, metadata, schema_version, created_at, correlation_id }` | `roles-service`, `admin-service` | Signals admin user update.        |
| `customer.task`       | `{ event_id, customer_id, merchant_id, task_type, locale, created_at, correlation_id }` | Event Tracking | Triggers notification tasks.      |
| `cache.invalidate`    | `{ key, merchant_id, type, locale, created_at }`   | `points-service`, `admin-service` | Invalidates Redis caches.         |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `auth.token_issued`   | `auth-service` | `{ event_id, user_id, merchant_id, scopes }` | Caches user session in Redis.       |
| `points.earned`       | `points-service` | `{ event_id, customer_id, merchant_id, points, created_at }` | Updates `customers.points_balance`. |
| `role.assigned`       | `roles-service`| `{ event_id, admin_user_id, role_id, merchant_id, locale }` | Updates `admin_users.metadata` for RBAC. |

- **Schema**: Avro, backward-compatible, registered in Confluent Schema Registry.
- **Idempotency**: `event_id` tracked in Redis (`processed:{merchant_id}:{event_id}`) or `processed_events`.
- **Dead-Letter Queue**: Failed events sent to `users.dlq` topic, max 3 retries before DLQ.
- **Replay Support**: `users.replay` topic with rate-controlled replays (100 events/s), filters for `merchant_id`, `event_type`, time window, and CLI (`reprocess_dlq.py`).
- **Saga Patterns**:
  - Customer Import: `users-service` → `customer.created` → `points-service` → `rfm-service` → `customer.task`.
  - Customer Update: `users-service` → `customer.updated` → `rfm-service` → `admin-service` → `customer.task`.
  - Admin User Update: `users-service` → `admin_user.updated` → `roles-service` → `admin-service`.
- **Correlation IDs**: Included in all Kafka events and gRPC calls for tracing.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| `auth-service` | Validates JWT via `/auth.v1/ValidateToken`, emits `auth.token_issued`.   |
| `points-service`| Consumes `customer.created`, updates via `points.earned`.                |
| `admin-service`| Consumes `customer.updated`, `admin_user.updated` for multi-tenant config. |
| `roles-service`| Consumes `admin_user.updated`, emits `role.assigned`.                   |
| Event Tracking | Consumes `customer.task` for Klaviyo/Postscript notifications.           |
| `rfm-service`  | Consumes `customer.created`, `customer.updated` for RFM score updates.   |
| Campaign       | Consumes `customer.created` for campaign initialization.                 |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Shopify API   | Sends `/webhooks/users/update` (REST), provides GraphQL user data.       |
| Klaviyo/Postscript | Sends notifications via Event Tracking (`customer.task`).                |
| Kafka         | Event transport, DLQ, and replay (Avro schema registry).                 |
| PostgreSQL    | Primary data store for customers, admin_users, translations, audit_logs. |
| Redis         | Caching, idempotency, translation storage, JWT blacklisting.             |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| Backblaze B2  | Audit log retention (90–180 days, cold-tier archival).                   |

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| gRPC     | `/users.v1/GetCustomer`       | Fetches customer profile.         |
| gRPC     | `/users.v1/UpdateCustomer`    | Updates customer data.            |
| gRPC     | `/users.v1/GetAdminUser`      | Fetches admin user data.          |
| gRPC     | `/users.v1/PurgeAuditLogs`    | Purges audit logs for CCPA.       |
| REST     | `/api/users/import`           | Triggers async customer import.   |
| REST     | `/webhooks/users/update`      | Updates customer data from Shopify. |
| HTTP     | `/health`                     | Liveness check.                   |
| HTTP     | `/ready`                      | Readiness check.                  |
| HTTP     | `/metrics`                    | Prometheus metrics export.        |
| Kafka    | `customer.created`, `customer.updated`, `admin_user.updated`, `customer.task`, `cache.invalidate` | Signals user events/tasks/cache invalidation. |
| Kafka    | `users.dlq`                   | Stores failed events for retry.    |
| Kafka    | `users.replay`                | Stores events for replay.         |

- **Access Patterns**: High read (`GetCustomer`, 5,000 concurrent requests), medium write (`UpdateCustomer`, `import`, 1,000 imports/hour).
- **Rate Limits**: Shopify API (2 req/s, REST), internal (100 req/s per merchant), IP-based (100 req/s per IP for REST).

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `users_get_total` (by `merchant_id`, `locale`).
  - `users_import_latency_seconds` (cache hit/miss).
  - `users_errors_total` (by `error_type`).
  - `users_dlq_size_total` (DLQ queue size).
  - `translations_cache_hits_total`, `translations_cache_misses_total`.
- **Logging**: Structured JSON via Loki, tagged with `merchant_id`, `customer_id`, `event_type`, `locale`, `correlation_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Import failures > 5/hour.
  - GetCustomer latency > 500ms.
  - DLQ size > 100 events.
- **Dashboards**: Grafana panels (sample JSON in repo):
  - Imports per minute.
  - Latency trends (cache hit/miss).
  - DLQ size and error rates.
  - Translation cache hit/miss ratio.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `UsersRepository` (`findById`, `updateCustomer`), localization, linting for `metadata`. |
| Contract Tests | Pact            | `/users.v1/GetCustomer`, `/users.v1/GetAdminUser` compatibility with `points-service`, `roles-service`. |
| Integration    | Testcontainers  | PostgreSQL, Redis, Kafka, Shopify API, Klaviyo/Postscript, `auth-service`, `points-service`, `roles-service`. |
| E2E Tests      | Cypress         | `/users.v1/GetCustomer`, `/api/users/import`, `/webhooks/users/update` flows. |
| Load Tests     | k6              | 10,000 concurrent `GetCustomer` calls, 1,000 imports/hour, <200ms latency (cache hit/miss). |
| Chaos Testing  | Chaos Mesh      | PostgreSQL, Redis, Kafka crashes; service failures.                   |
| Compliance     | Jest            | Verify AES-256 encryption, audit log emission, CCPA purge functionality. |
| i18n Tests     | Jest            | Validate `metadata.locale`, `language` for `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja` (90%+ accuracy). |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `users-service:latest`.
  - Ports: `50051` (gRPC), `8080` (REST, `/health`, `/metrics`, `/ready`).
  - Environment Variables: `USERS_DB_HOST`, `USERS_DB_PORT`, `USERS_DB_NAME`, `KAFKA_BROKER`, `SHOPIFY_API_KEY`, `AUTH_HOST`.
- **Resource Limits**:
  - CPU: 0.5 cores per instance.
  - Memory: 512MiB per instance.
- **Scaling**: 2 instances for 5,000 concurrent `GetCustomer` calls, PostgreSQL read replicas, Redis for lookups.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Pact, Cypress, k6, OWASP ZAP, and CLI (`reprocess_dlq.py`, `cleanup_translations.py`).

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| High GetCustomer latency | Cache in Redis (`customer:{customer_id}`), monitor `users_get_latency_seconds`. |
| Shopify API rate limits  | Circuit breakers, exponential backoff, track in Redis (`rate_limit:{merchant_id}:shopify`, TTL: 60s). |
| Event/webhook duplication| Use `event_id`, `X-Shopify-Webhook-Id`, track in Redis/`processed_events`.  |
| Translation table growth | TTL index (90 days) on `translations`, CLI for version pruning.            |
| Dependency failures      | Dead-letter queue (`users.dlq`), mock `auth-service`, `points-service`, `roles-service` in CI/CD. |

## Action Items
- [ ] Deploy `users_db` (PostgreSQL) and Redis by **August 8, 2025** (Owner: DB Team).
- [ ] Define `Customer.entity.ts`, `AdminUser.entity.ts` schemas and implement gRPC/REST endpoints by **August 15, 2025** (Owner: Dev Team).
- [ ] Set up `translations` table and validate `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja` by **August 15, 2025** (Owner: Frontend Team).
- [ ] Configure Prometheus `/metrics`, Loki logs, and Grafana panels by **August 18, 2025** (Owner: SRE Team).
- [ ] Conduct k6 load tests (10,000 `GetCustomer` calls), Pact contract tests, chaos tests, and i18n tests by **August 20, 2025** (Owner: QA Team).
- [ ] Implement CLI (`reprocess_dlq.py`, `cleanup_translations.py`) and replay script for `users.replay` by **August 20, 2025** (Owner: Dev Team).

## Epics and Stories
| Epic                     | Stories                                    | Owner      | Due Date       |
|--------------------------|--------------------------------------------|------------|----------------|
| Database Setup           | Deploy PostgreSQL, Redis; create tables    | DB Team    | August 8, 2025 |
| Core Functionality       | Implement gRPC, REST, Kafka events         | Dev Team   | August 15, 2025|
| Localization             | Set up `translations`, validate languages  | Frontend Team | August 15, 2025|
| Observability            | Configure Prometheus, Loki, Grafana panels | SRE Team   | August 18, 2025|
| Testing & Validation     | Load, contract, chaos, i18n, compliance tests | QA Team | August 20, 2025|
| Event Replay & DLQ       | Implement `reprocess_dlq.py`, replay script | Dev Team   | August 20, 2025|

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | August 1, 2025    |
| Database and Redis Deployment | August 8, 2025    |
| Core Functionality (gRPC, REST, Kafka) Complete | August 15, 2025 |
| Observability and Localization Setup | August 18, 2025 |
| Testing (Load, Contract, Chaos, i18n) and Replay | August 20, 2025 |
| Completion                    | August 20, 2025   |

## Recommendations
### Architecture & Design
1. **Event Idempotency**:
   - Use `event_id` for `customer.created`, `customer.updated`, `admin_user.updated`, `customer.task`, tracked in Redis/`processed_events`.
   - Validate deduplication before processing events/webhooks (`X-Shopify-Webhook-Id`).

2. **Caching Strategy**:
   - Cache `GetCustomer`, `GetAdminUser` in Redis (`customer:{customer_id}`, `admin_user:{admin_user_id}`), invalidate on `customer.updated`, `admin_user.updated`, `cache.invalidate`.
   - Emit `cache.invalidate` Kafka events for cross-service consistency.

3. **Schema Versioning**:
   - Use `schema_version` in `customers`, `admin_users`, and Kafka events, enforce backward-compatible schemas in Confluent Schema Registry.

4. **Replay & DLQ**:
   - Rate-controlled replays (100 events/s) with filters for `merchant_id`, `event_type`, time window.
   - CLI (`reprocess_dlq.py`) for `users.dlq` and `users.replay` (max 3 retries).

### Security
5. **Authentication & Authorization**:
   - Enforce JWT with `jti` blacklisting (`jwt_blacklist:{jti}`, TTL: 1h for `/users.v1/UpdateCustomer`) via `/auth.v1/ValidateToken`.
   - Implement RBAC (`admin:users:view`, `admin:users:edit`) via API Gateway.

6. **Audit Defense**:
   - Emit events to `audit_log` Kafka topic, with 90–180 day retention and cold-tier archival.
   - Implement `/users.v1/PurgeAuditLogs` for CCPA compliance.

### Observability
7. **Correlation IDs**:
   - Include `correlation_id` in gRPC, REST, and Kafka for tracing.

8. **Dashboarding**:
   - Provide sample Grafana panel JSON in repo for imports, latency, DLQ size, and translation cache hits.

### DevOps / Operability
9. **Runbooks & SLOs**:
   - Define runbooks for import failures, cache inconsistency, Shopify API rate limits.
   - Set SLOs: 99% requests <200ms (cache hit/miss), <0.5% failure rate.

10. **Service Discovery**:
    - Register with Consul (`SERVICE_NAME=users`, `SERVICE_PORT=50051`, `SERVICE_CHECK_HTTP=/health`).

### Platform Evolution
11. **Multilingual Support**:
    - Centralize translations in `translations` table, validate with DeepL and Jest linting.
    - Automate i18n tests for `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja`.

12. **Dependency Management**:
    - Mock `auth-service`, `points-service`, `roles-service`, Event Tracking, Campaign in CI/CD to avoid delays.