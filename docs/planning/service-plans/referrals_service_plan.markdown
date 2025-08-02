# Referrals Service Plan

## Overview
- **Purpose**: Manages referral links and conversions (7% SMS conversion rate) for loyalty programs, with multilingual status messages, robust audit logging, and replay support.
- **Priority for TVP**: High (core TVP feature).
- **Dependencies**: Core Service (customer data), Points Service (rewards), Auth Service (JWT validation), Shopify API (order webhooks), Event Tracking (referral tasks), Campaign (tier-based bonuses), Kafka (event streaming), Consul (service discovery), Redis (caching, idempotency), PostgreSQL (persistent storage), Prometheus (metrics), Loki (logging), Backblaze B2 (audit log retention).

## Database Setup
- **Database Type**: PostgreSQL (port: 5434), Redis (port: 6379).
- **Tables**: `referrals`, `processed_events`, `translations`.
- **Redis Keys**:
  - `referral:{shop_id}:{referral_id}`: Caches `/referrals.v1/GetReferralStatus` responses (TTL: 1h).
  - `processed:{shop_id}:{event_id}`: Tracks processed Kafka events/webhooks (TTL: 24h).
  - `rate_limit:{shop_id}:referrals`: Limits Shopify webhook processing (TTL: 60s, max 40 req/s).
  - `translations:{key}:{locale}`: Caches localized messages (TTL: 24h).
  - `jwt_blacklist:{jti}`: Tracks invalidated JWTs (TTL: 24h).
  - **Eviction**: `volatile-lru` for caches, `noeviction` for processed events, rate limits, and JWT blacklist.

### `referrals` Schema
| Column           | Type       | Constraints                                                                 |
|------------------|------------|-----------------------------------------------------------------------------|
| `id`             | UUID       | Primary Key                                                                 |
| `merchant_id`    | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `shop_id`        | UUID       | Foreign Key → `shops`, Indexed (for Shopify rate limits)                    |
| `customer_id`    | UUID       | Foreign Key → `customers` (Core Service), Indexed                           |
| `referral_link_id`| TEXT       | Unique per `shop_id`, Indexed                                              |
| `status`         | TEXT       | ENUM: ['queued', 'pending', 'in_progress', 'completed', 'rewarded', 'failed', 'cancelled'] |
| `locale`         | TEXT       | ENUM: ['en', 'ar', 'he', ...], DEFAULT 'en'                                |
| `description`    | TEXT       | Localized, validated against `translations` (e.g., "Referral completed")    |
| `event_id`       | UUID       | Unique, for idempotency                                                    |
| `schema_version` | TEXT       | e.g., "1.0.0", for schema evolution                                        |
| `created_at`     | TIMESTAMP(3) | DEFAULT now()                                                            |
| `updated_at`     | TIMESTAMP(3) | Auto-updated via trigger                                                  |
| `correlation_id` | UUID       | For tracing across services                                                |

### `processed_events` Schema
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `event_id`    | UUID       | Primary Key                                                                 |
| `shop_id`     | UUID       | Foreign Key → `shops`, Indexed                                             |
| `event_type`  | TEXT       | ENUM: ['referral.completed', 'referral.task', 'order.created']             |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (24h)                                            |

### `translations` Schema
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `id`          | UUID       | Primary Key                                                                 |
| `key`         | TEXT       | Unique, e.g., "referral.completed"                                         |
| `locale`      | TEXT       | ENUM: ['en', 'ar', 'he', ...]                                              |
| `value`       | TEXT       | Localized text, e.g., "Referral completed for {customer}"                  |
| `version`     | TEXT       | e.g., "1.0.0", for translation versioning                                  |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (90 days)                                         |

### Constraints & Indexes
- **Unique Index**: `unique_referrals_shop_id_referral_link_id` (btree: `shop_id`, `referral_link_id`).
- **Indexes**:
  - `idx_referrals_shop_id` (btree: `shop_id`).
  - `idx_referrals_customer_id` (btree: `customer_id`).
  - `idx_referrals_event_id` (btree: `event_id`).
  - `idx_processed_events_shop_id` (btree: `shop_id`).
  - `idx_translations_key_locale` (btree: `key`, `locale`).
- **Triggers**:
  - `trg_updated_at`: Updates `updated_at` on `referrals` row changes.
  - `trg_validate_description`: Validates `description` against `translations` on insert/update.
- **Row-Level Security (RLS)**: Enabled on `referrals` to restrict access by `shop_id`.
- **Partitioning**: `referrals` partitioned by `shop_id` for scalability.
- **TTL Index**: `processed_events.created_at` (24h), `translations.created_at` (90 days).

### GDPR/CCPA Compliance
- No PII stored; `customer_id` links to Core Service’s encrypted `email`.
- Audit logs emitted to AdminCore via Kafka (`referral.completed`, `referral.task`), retained for 90–180 days (configurable per `shop_id`) in Backblaze B2, with cold-tier archival after 180 days.
- Merchant-initiated purge API (`/referrals.v1/PurgeAuditLogs`) for CCPA compliance.
- `description` sanitized to exclude PII, validated against `translations` table.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by Referrals Service)
| Endpoint                      | Input                              | Output                        | Called By       | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/referrals.v1/GetReferralStatus` | `shop_id`, `referral_id`, `locale` | `status`, `description`       | Frontend        | Fetches referral status.          |
| `/referrals.v1/PurgeAuditLogs` | `shop_id`, `jwt_token`            | `status`                      | AdminCore       | Purges audit logs for CCPA.       |

#### gRPC Calls (Made by Referrals Service)
| Endpoint                      | Input                              | Output                        | Service         | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/core.v1/GetCustomerRFM`     | `shop_id`, `customer_id`           | `recency`, `frequency`, `monetary` | Core Service | Validates customer for referrals.  |
| `/auth.v1/ValidateToken`      | `jwt_token`                        | `shop_id`, `scopes`           | Auth Service    | Validates JWT for gRPC/REST calls. |

- **Port**: 50060 (gRPC).
- **Authentication**: JWT via `/auth.v1/ValidateToken` with `jti` blacklisting in Redis (`jwt_blacklist:{jti}`, TTL: 24h).
- **Authorization**: RBAC (`merchant:referrals:view`, `customer:referrals:view`) via API Gateway.
- **Security**: mTLS for internal gRPC communication (Vault-managed certs).
- **Service Discovery**: Consul (`SERVICE_NAME=referrals`, `SERVICE_CHECK_HTTP=/health`).

#### REST Endpoints (Consumed via API Gateway)
| Endpoint               | Method | Source         | Purpose                           |
|------------------------|--------|----------------|-----------------------------------|
| `/orders/create`       | POST   | Shopify API    | Triggers referral conversion.     |

- **Idempotency**: `X-Shopify-Webhook-Id` for webhook deduplication, tracked in Redis or `processed_events`.
- **Rate Limits**: 40 req/s per shop (Shopify API Plus), tracked in Redis (`rate_limit:{shop_id}:referrals`, TTL: 60s).
- **IP Rate-Limiting**: Limit public webhook endpoint to 100 req/s per IP via API Gateway.

### Asynchronous Communication
#### Events Produced (Kafka)
| Event                 | Payload                                            | Consumed By         | Description                       |
|-----------------------|----------------------------------------------------|---------------------|-----------------------------------|
| `referral.completed`  | `{ event_id, customer_id, shop_id, referral_id, status, locale, description, schema_version, created_at, correlation_id }` | Points, RFM Analytics, AdminCore | Signals referral conversion.       |
| `referral.task`       | `{ event_id, customer_id, shop_id, task_type, locale, created_at, correlation_id }` | Event Tracking | Triggers SMS/email referral tasks. |
| `cache.invalidate`    | `{ key, shop_id, type, locale, created_at }`       | Frontend, Points    | Invalidates Redis caches.         |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `vip_tier.assigned`   | Campaign       | `{ event_id, customer_id, shop_id, tier_id, assigned_at }` | Applies tier-based referral bonuses. |

- **Schema**: Avro, backward-compatible, registered in Confluent Schema Registry.
- **Idempotency**: `event_id` tracked in Redis (`processed:{shop_id}:{event_id}`) or `processed_events`.
- **Dead-Letter Queue**: Failed events sent to `referrals.dlq` topic, max 3 retries before DLQ.
- **Replay Support**: `referrals.replay` topic with rate-controlled replays (100 events/s), filters for `shop_id`, `event_type`, time window, and CLI (`reprocess_dlq.py`).
- **Saga Patterns**:
  - Shopify → `/orders/create` → Referrals → `referral.completed` → Points → RFM Analytics.
  - Campaign → `vip_tier.assigned` → Referrals → `referral.completed` → Points.
  - Referrals → `referral.task` → Event Tracking → `task.created` → AdminCore.
- **Correlation IDs**: Included in all Kafka events and gRPC calls for tracing.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| Core Service   | Validates customers via `/core.v1/GetCustomerRFM`.                       |
| Auth Service   | Validates JWT via `/auth.v1/ValidateToken`.                              |
| Points Service | Consumes `referral.completed` for reward points.                         |
| Event Tracking | Consumes `referral.task` for SMS/email task queuing.                     |
| Campaign       | Emits `vip_tier.assigned` for referral bonuses.                         |
| RFM Analytics  | Consumes `referral.completed` for score updates.                         |
| AdminCore      | Consumes `referral.completed`, `referral.task` for audit logging.        |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Shopify API   | Sends `/orders/create` webhooks for conversions.                         |
| Kafka         | Event transport, DLQ, and replay (Avro schema registry).                 |
| PostgreSQL    | Primary data store for referrals and translations.                      |
| Redis         | Caching, idempotency, rate-limiting, translation storage, JWT blacklisting. |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| Backblaze B2  | Audit log retention (via AdminCore, 90–180 days, cold-tier archival).   |

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| gRPC     | `/referrals.v1/GetReferralStatus` | Fetches referral status.          |
| gRPC     | `/referrals.v1/PurgeAuditLogs` | Purges audit logs for CCPA.       |
| REST     | `/orders/create`              | Triggers referral conversion.     |
| HTTP     | `/health`                     | Liveness check.                   |
| HTTP     | `/ready`                      | Readiness check.                  |
| HTTP     | `/metrics`                    | Prometheus metrics export.        |
| Kafka    | `referral.completed`, `referral.task`, `cache.invalidate` | Signals referral events/tasks/cache invalidation. |
| Kafka    | `referrals.dlq`               | Stores failed events for retry.    |
| Kafka    | `referrals.replay`            | Stores events for replay.         |

- **Access Patterns**: High read/write (700 conversions/hour).
- **Rate Limits**: 40 req/s per shop, tracked in Redis (`rate_limit:{shop_id}:referrals`, TTL: 60s); 100 req/s per IP for webhooks.

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `referrals_conversions_total` (by `status`, `locale`).
  - `referrals_status_latency_seconds` (cache hit/miss).
  - `referrals_errors_total` (by `error_type`).
  - `referrals_rate_limit_exceeded_total` (Shopify API limits).
  - `referrals_dlq_size_total` (DLQ queue size).
  - `translations_cache_hits_total`, `translations_cache_misses_total`.
- **Logging**: Structured JSON via Loki, tagged with `shop_id`, `referral_id`, `event_type`, `locale`, `correlation_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Conversion failures > 5/hour.
  - Status query latency > 500ms.
  - Rate limit breaches > 10/hour.
  - DLQ size > 100 events.
- **Dashboards**: Grafana panels (sample JSON in repo):
  - Conversions per minute by status.
  - Latency trends (cache hit/miss).
  - Rate limit and DLQ trends.
  - Translation cache hit/miss ratio.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `ReferralsRepository` (`getReferral`), localization, linting for `description`. |
| Contract Tests | Pact            | `/referrals.v1/GetReferralStatus` compatibility with Frontend.        |
| Integration    | Testcontainers  | PostgreSQL, Redis, Kafka, Shopify webhooks, Event Tracking, Campaign. |
| E2E Tests      | Cypress         | `/referrals.v1/GetReferralStatus`, `/orders/create` webhook flows.    |
| Load Tests     | k6              | 1,000 conversions/hour, <200ms latency (cache hit/miss).             |
| Chaos Testing  | Chaos Mesh      | PostgreSQL, Redis, Kafka crashes; service failures.                   |
| Compliance     | Jest            | Verify no PII, audit log emission, CCPA purge functionality.          |
| i18n Tests     | Jest            | Validate `description`, `locale` for `en`, `ar`, `he` (90%+ accuracy). |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

- **Future**: Add A/B testing hooks for referral flow experimentation (post-MVP).

## Deployment
- **Docker Compose**:
  - Image: `referrals-service:latest`.
  - Ports: `50060` (gRPC), `8080` (HTTP for `/health`, `/metrics`, `/ready`).
  - Environment Variables: `REFERRALS_DB_HOST`, `REFERRALS_REDIS_HOST`, `KAFKA_BROKER`, `AUTH_HOST`.
- **Resource Limits**:
  - CPU: 0.5 cores per instance.
  - Memory: 512MiB per instance.
- **Scaling**: 2 instances for 1,000 conversions/hour, PostgreSQL read replicas, Redis for lookups.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Pact, Cypress, k6, OWASP ZAP, and CLI (`reprocess_dlq.py`, `cleanup_translations.py`).

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| Redis cache inconsistency| Invalidate `referral:{shop_id}:{referral_id}`, `translations:{key}:{locale}` on `referral.completed`, `cache.invalidate`. |
| Event/webhook duplication| Use `event_id`, track in Redis/`processed_events`, validate `X-Shopify-Webhook-Id`. |
| High status query latency| Cache in Redis, monitor `referrals_status_latency_seconds` (hit/miss).     |
| Translation table growth | TTL index (90 days) on `translations`, CLI for version pruning.            |
| Shopify webhook failures | Retry with exponential backoff, store in `referrals.dlq` (max 3 retries). |
| Dependency failures      | Dead-letter queue, mock Core, Points, Event Tracking, Campaign in CI/CD.   |

## Action Items
- [ ] Deploy `referrals_db` (PostgreSQL) and Redis by **August 5, 2025** (Owner: DB Team).
- [ ] Implement gRPC `/GetReferralStatus`, `/PurgeAuditLogs`, webhook handling, and Kafka events by **August 10, 2025** (Owner: Dev Team).
- [ ] Set up `translations` table and validate `en`, `ar`, `he` by **August 10, 2025** (Owner: Frontend Team).
- [ ] Configure Prometheus `/metrics`, Loki logs, and Grafana panels by **August 12, 2025** (Owner: SRE Team).
- [ ] Conduct k6 load tests (1,000 conversions/hour), Pact contract tests, chaos tests, and i18n tests by **August 15, 2025** (Owner: QA Team).
- [ ] Implement CLI (`reprocess_dlq.py`, `cleanup_translations.py`) and replay script for `referrals.replay` by **August 15, 2025** (Owner: Dev Team).

## Epics and Stories
| Epic                     | Stories                                    | Owner      | Due Date       |
|--------------------------|--------------------------------------------|------------|----------------|
| Database Setup           | Deploy PostgreSQL, Redis; create tables    | DB Team    | August 5, 2025 |
| Core Functionality       | Implement gRPC, webhooks, Kafka events     | Dev Team   | August 10, 2025|
| Localization             | Set up `translations`, validate `en`, `ar`, `he` | Frontend Team | August 10, 2025|
| Observability            | Configure Prometheus, Loki, Grafana panels | SRE Team   | August 12, 2025|
| Testing & Validation     | Load, contract, chaos, i18n, compliance tests | QA Team | August 15, 2025|
| Event Replay & DLQ       | Implement `reprocess_dlq.py`, replay script | Dev Team   | August 15, 2025|

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | July 25, 2025     |
| Database and Redis Deployment | August 5, 2025    |
| Core Functionality (gRPC, Webhooks, Kafka) Complete | August 10, 2025 |
| Observability and Localization Setup | August 12, 2025 |
| Testing (Load, Contract, Chaos, i18n) and Replay | August 15, 2025 |
| Completion                    | August 15, 2025   |

## Recommendations
### Architecture & Design
1. **Event Idempotency**:
   - Use `event_id` for `referral.completed`, `referral.task`, and `X-Shopify-Webhook-Id` for webhooks, tracked in Redis/`processed_events`.
   - Validate deduplication before processing conversions.

2. **Caching Strategy**:
   - Cache `GetReferralStatus` and `translations` in Redis, invalidate on `referral.completed`, `cache.invalidate`.
   - Emit `cache.invalidate` Kafka events for cross-service consistency.

3. **Schema Versioning**:
   - Use `schema_version` in `referrals` and Kafka events, enforce backward-compatible schemas in Confluent Schema Registry.

4. **Replay & DLQ**:
   - Rate-controlled replays (100 events/s) with filters for `shop_id`, `event_type`, time window.
   - CLI (`reprocess_dlq.py`) for `referrals.dlq` and `referrals.replay` (max 3 retries).

### Security
5. **Authentication & Authorization**:
   - Enforce JWT with `jti` blacklisting (`jwt_blacklist:{jti}`) via `/auth.v1/ValidateToken`.
   - Implement RBAC (`merchant:referrals:view`, `customer:referrals:view`) via API Gateway.

6. **Audit Defense**:
   - Emit events to `audit_log` Kafka topic via AdminCore, with 90–180 day retention and cold-tier archival.
   - Implement `/referrals.v1/PurgeAuditLogs` for CCPA compliance.

### Observability
7. **Correlation IDs**:
   - Include `correlation_id` in gRPC, REST, and Kafka for tracing.

8. **Dashboarding**:
   - Provide sample Grafana panel JSON in repo for conversions, latency, DLQ size, and translation cache hits.

### DevOps / Operability
9. **Runbooks & SLOs**:
   - Define runbooks for cache inconsistency, webhook failures, PostgreSQL crashes.
   - Set SLOs: 99% requests <200ms (cache hit/miss), <0.5% failure rate.

10. **Service Discovery**:
    - Register with Consul (`SERVICE_NAME=referrals`, `SERVICE_PORT=50060`, `SERVICE_CHECK_HTTP=/health`).

### Platform Evolution
11. **Multilingual Support**:
    - Centralize translations in `translations` table, validate with DeepL and Jest linting.
    - Automate i18n tests for `en`, `ar`, `he`.

12. **Dependency Management**:
    - Mock Core, Points, Event Tracking, Campaign in CI/CD to avoid delays.