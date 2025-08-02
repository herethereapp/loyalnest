# Gamification Service Plan (Revised)

## Overview
- **Purpose**: Prepares Redis for badges and leaderboards in Phase 3, supporting gamification features (badges, leaderboards) for Phase 6.
- **Priority for TVP**: Low (Phase 3 prep), high for Phase 6 (gamification features).
- **Dependencies**: `users-service` (customer data), `points-service` (badge triggers), `campaign-service` (gamification campaigns), Event Tracking (notifications), `auth-service` (JWT validation), Kafka (event streaming), Consul (service discovery), Redis (badges/leaderboards, idempotency), PostgreSQL (translations, processed events), Prometheus (metrics), Loki (logging), Backblaze B2 (audit log retention).

## Database Setup
- **Database Type**: Redis (port: 6381), PostgreSQL (port: 5432, for `processed_events`, `translations`).
- **Redis Keys**:
  - `badge:{merchant_id}:{customer_id}:{badge}`: Stores badge status (TTL: 1h).
  - `leaderboard:{merchant_id}`: Sorted set for leaderboard rankings (TTL: none).
  - `processed:{merchant_id}:{event_id}`: Tracks processed Kafka events (TTL: 24h).
  - `translations:{key}:{locale}`: Caches localized badge names (TTL: 24h).
  - `jwt_blacklist:{jti}`: Tracks invalidated JWTs (TTL: 1h).
  - **Eviction**: `volatile-lru` for caches, `noeviction` for processed events and JWT blacklist.
- **Tables**: `processed_events`, `translations`, `audit_logs` (via Kafka to `admin-service`).

### `processed_events` Table (PostgreSQL)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `event_id`    | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `event_type`  | TEXT       | ENUM: ['badge.awarded', 'badge.task']                                     |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (24h)                                            |

### `translations` Table (PostgreSQL)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `id`          | UUID       | Primary Key                                                                 |
| `key`         | TEXT       | Unique, e.g., "badge.achievement.123"                                      |
| `locale`      | TEXT       | ENUM: ['en', 'es', 'fr', 'ar', 'de', 'pt', 'ja', ...]                     |
| `value`       | TEXT       | Localized badge name, e.g., "Gold Achiever"                                |
| `version`     | TEXT       | e.g., "1.0.0", for translation versioning                                  |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (90 days)                                         |

### Constraints & Indexes
- **PostgreSQL Indexes**:
  - `idx_processed_events_merchant_id` (btree: `merchant_id`).
  - `idx_translations_key_locale` (btree: `key`, `locale`).
- **Redis Settings**:
  - Clustering: 3 nodes, 1 replica for Phase 6 scalability.
  - TTL: 1h for `badge:{merchant_id}:{customer_id}:{badge}`, 24h for `processed:{merchant_id}:{event_id}` and `translations:{key}:{locale}`.
- **Triggers**:
  - `trg_validate_translations`: Validates badge names against `translations` for `locale`.

### GDPR/CCPA Compliance
- No PII stored in Redis keys or `translations` table.
- Audit logs emitted to Kafka (`badge.awarded`) via `admin-service`, retained for 90–180 days (configurable per `merchant_id`) in Backblaze B2, with cold-tier archival after 180 days.
- Merchant-initiated purge API (`/gamification.v1/PurgeAuditLogs`) for CCPA compliance.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by Gamification Service)
| Endpoint                      | Input                              | Output                        | Called By       | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/gamification.v1/AwardBadge` | `merchant_id`, `customer_id`, `badge`, `locale` | `status`        | Frontend, `points-service` | Awards badge (Phase 6).           |
| `/gamification.v1/PurgeAuditLogs` | `merchant_id`, `jwt_token`     | `status`                      | `admin-service` | Purges audit logs for CCPA.       |

#### gRPC Calls (Made by Gamification Service)
| Endpoint                      | Input                              | Output                        | Service         | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/auth.v1/ValidateToken`      | `jwt_token`                        | `merchant_id`, `scopes`       | `auth-service`  | Validates JWT for gRPC calls.     |
| `/users.v1/GetCustomer`       | `customer_id`, `merchant_id`       | `email`, `points_balance`     | `users-service` | Fetches customer data for badges. |

- **Port**: 50054 (gRPC), 8080 (REST).
- **Authentication**: JWT via `/auth.v1/ValidateToken` with `jti` blacklisting in Redis (`jwt_blacklist:{jti}`, TTL: 1h).
- **Authorization**: RBAC (`admin:gamification:edit`) via API Gateway.
- **Security**: mTLS for internal gRPC communication (Vault-managed certs).
- **Service Discovery**: Consul (`SERVICE_NAME=gamification`, `SERVICE_CHECK_HTTP=/health`).
- **Rate Limits**: Internal (100 req/s per merchant for `/gamification.v1/AwardBadge`), IP-based (100 req/s per IP for REST).

### Asynchronous Communication
#### Events Produced (Kafka)
| Event                 | Payload                                            | Consumed By         | Description                       |
|-----------------------|----------------------------------------------------|---------------------|-----------------------------------|
| `badge.awarded`       | `{ event_id, merchant_id, customer_id, badge, schema_version, locale, created_at, trace_id }` | `points-service`, `campaign-service`, `admin-service` | Signals badge award.              |
| `badge.task`          | `{ event_id, merchant_id, customer_id, task_type, locale, created_at, trace_id }` | Event Tracking | Triggers notification tasks.      |
| `cache.invalidate`    | `{ key, merchant_id, type, locale, created_at }`   | `points-service`, `admin-service` | Invalidates Redis caches.         |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `points.earned`       | `points-service`| `{ event_id, customer_id, merchant_id, points }` | Triggers badge award logic.        |
| `customer.updated`     | `users-service`| `{ event_id, customer_id, merchant_id, email, language }` | Updates badge eligibility.         |

- **Schema**: Avro, backward-compatible, registered in Confluent Schema Registry.
- **Idempotency**: `event_id` tracked in Redis (`processed:{merchant_id}:{event_id}`) or `processed_events`.
- **Dead-Letter Queue**: Failed events sent to `gamification.dlq` topic, max 3 retries before DLQ.
- **Replay Support**: `gamification.replay` topic with rate-controlled replays (100 events/s), filters for `merchant_id`, `event_type`, time window, and CLI (`reprocess_dlq.py`).
- **Saga Patterns** (Phase 6):
  - Badge Award: `points-service` → `points.earned` → `gamification-service` → `badge.awarded` → `badge.task`.
- **Traceability**: `trace_id` (OpenTelemetry) in all Kafka events and gRPC calls for distributed tracing.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| `users-service`| Provides customer data via `/users.v1/GetCustomer`.                     |
| `auth-service` | Validates JWT via `/auth.v1/ValidateToken`.                             |
| `points-service`| Consumes `badge.awarded`, emits `points.earned` for badge triggers.     |
| `campaign-service` | Consumes `badge.awarded` for gamification campaigns.                    |
| `admin-service`| Consumes `badge.awarded` for audit logging.                             |
| Event Tracking | Consumes `badge.task` for Klaviyo/Postscript notifications.              |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Kafka         | Event transport, DLQ, and replay (Avro schema registry).                 |
| Redis         | Primary store for badges/leaderboards, idempotency, translations.        |
| PostgreSQL    | Stores `processed_events`, `translations` tables.                        |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| Backblaze B2  | Audit log retention (via `admin-service`, 90–180 days, cold-tier archival). |

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| gRPC     | `/gamification.v1/AwardBadge` | Awards badge (Phase 6).           |
| gRPC     | `/gamification.v1/PurgeAuditLogs` | Purges audit logs for CCPA.       |
| HTTP     | `/health`                     | Liveness check.                   |
| HTTP     | `/ready`                      | Readiness check.                  |
| HTTP     | `/metrics`                    | Prometheus metrics export.        |
| Kafka    | `badge.awarded`, `badge.task`, `cache.invalidate` | Signals badge events/tasks/cache invalidation. |
| Kafka    | `gamification.dlq`            | Stores failed events for retry.    |
| Kafka    | `gamification.replay`         | Stores events for replay.         |

- **Access Patterns**: High write (`AwardBadge`, 1,000 concurrent requests in Phase 6), low read (`leaderboard:{merchant_id}`).
- **Rate Limits**: Internal (100 req/s per merchant for `/gamification.v1/AwardBadge`), IP-based (100 req/s per IP for REST).

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `gamification_badge_total` (by `merchant_id`, `badge`, `locale`).
  - `gamification_leaderboard_latency_seconds` (cache hit/miss).
  - `gamification_errors_total` (by `error_type`).
  - `gamification_dlq_size_total` (DLQ queue size).
  - `translations_cache_hits_total`, `translations_cache_misses_total`.
- **Logging**: Structured JSON via Loki, tagged with `merchant_id`, `customer_id`, `event_type`, `locale`, `trace_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Badge awarding latency > 500ms.
  - DLQ size > 100 events.
  - Event processing failures > 5/hour.
- **Dashboards**: Grafana panels (sample JSON in repo):
  - Badge awards per minute.
  - Leaderboard latency trends.
  - DLQ size and error rates.
  - Translation cache hit/miss ratio.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `GamificationRepository` (`awardBadge`), localization, linting for badge names. |
| Contract Tests | Pact            | `/gamification.v1/AwardBadge` compatibility with `points-service`.     |
| Integration    | Testcontainers  | Redis, PostgreSQL, Kafka, `users-service`, `auth-service`, `points-service`. |
| E2E Tests      | Cypress         | `/gamification.v1/AwardBadge` flows (Phase 6 prep).                   |
| Load Tests     | k6              | 1,000 concurrent `AwardBadge` calls, <200ms latency (cache hit/miss).  |
| Chaos Testing  | Chaos Mesh      | Redis, Kafka crashes; service failures.                               |
| Compliance     | Jest            | Verify no PII, audit log emission, CCPA purge functionality.          |
| i18n Tests     | Jest            | Validate badge names for `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja` (90%+ accuracy). |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `gamification-service:latest`.
  - Ports: `50054` (gRPC), `8080` (REST, `/health`, `/metrics`, `/ready`).
  - Dependencies: Redis (port 6381), Kafka, PostgreSQL (port 5432).
  - Environment Variables: `GAMIFICATION_REDIS_HOST`, `GAMIFICATION_REDIS_PORT`, `KAFKA_BROKER`, `AUTH_HOST`.
- **Resource Limits**:
  - CPU: 0.3 cores per instance.
  - Memory: 256MiB per instance.
- **Scaling**: Single instance for Phase 3, 2 instances for 1,000 concurrent badge awards in Phase 6; Redis with 3 nodes, 1 replica.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Pact, Cypress, k6, OWASP ZAP, and CLI (`reprocess_dlq.py`, `cleanup_translations.py`).

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| Premature implementation | Defer badge/leaderboard logic to Phase 6, focus on Redis setup in Phase 3. |
| High badge award latency | Cache in Redis (`badge:{merchant_id}:{customer_id}`), monitor `gamification_badge_latency_seconds`. |
| Event duplication       | Use `event_id`, track in Redis/`processed_events`.                        |
| Translation table growth | TTL index (90 days) on `translations`, CLI for version pruning.           |
| Dependency failures      | Dead-letter queue (`gamification.dlq`), mock `users-service`, `auth-service`, `points-service` in CI/CD. |

## Action Items
- [ ] Deploy `gamification_redis` and PostgreSQL by **August 5, 2025** (Owner: DB Team).
- [ ] Create `badge:{merchant_id}:{customer_id}:{badge}`, `leaderboard:{merchant_id}`, and `translations` table by **August 7, 2025** (Owner: DB Team).
- [ ] Implement `/gamification.v1/AwardBadge` and Kafka events by **August 8, 2025** (Owner: Dev Team).
- [ ] Configure Prometheus `/metrics`, Loki logs, and Grafana panels by **August 9, 2025** (Owner: SRE Team).
- [ ] Conduct Jest, Pact, k6 (1,000 badge awards), chaos, and i18n tests by **August 10, 2025** (Owner: QA Team).
- [ ] Implement CLI (`reprocess_dlq.py`, `cleanup_translations.py`) and replay script for `gamification.replay` by **August 10, 2025** (Owner: Dev Team).

## Epics and Stories
| Epic                     | Stories                                    | Owner      | Due Date       |
|--------------------------|--------------------------------------------|------------|----------------|
| Database Setup           | Deploy Redis, PostgreSQL; create keys/tables | DB Team    | August 7, 2025 |
| Core Functionality       | Implement gRPC, Kafka events               | Dev Team   | August 8, 2025 |
| Localization             | Set up `translations`, validate languages  | Frontend Team | August 8, 2025 |
| Observability            | Configure Prometheus, Loki, Grafana panels | SRE Team   | August 9, 2025 |
| Testing & Validation     | Unit, contract, load, chaos, i18n tests    | QA Team    | August 10, 2025|
| Event Replay & DLQ       | Implement `reprocess_dlq.py`, replay script | Dev Team   | August 10, 2025|

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | July 25, 2025     |
| Database and Redis Deployment | August 5, 2025    |
| Keys and Translations Setup   | August 7, 2025    |
| Core Functionality (gRPC, Kafka) Complete | August 8, 2025 |
| Observability Setup           | August 9, 2025    |
| Testing and Replay            | August 10, 2025   |
| Completion                    | August 10, 2025   |

## Recommendations
### Architecture & Design
1. **Event Idempotency**:
   - Use `event_id` for `badge.awarded`, `badge.task`, tracked in Redis/`processed_events`.
   - Validate deduplication before processing events.

2. **Caching Strategy**:
   - Cache `AwardBadge` in Redis (`badge:{merchant_id}:{customer_id}`, TTL: 1h), invalidate on `badge.awarded`, `cache.invalidate`.
   - Emit `cache.invalidate` Kafka events for cross-service consistency.

3. **Schema Versioning**:
   - Use `schema_version` in Redis keys and Kafka events, enforce backward-compatible schemas in Confluent Schema Registry.

4. **Replay & DLQ**:
   - Rate-controlled replays (100 events/s) with filters for `merchant_id`, `event_type`, time window.
   - CLI (`reprocess_dlq.py`) for `gamification.dlq` and `gamification.replay` (max 3 retries).

### Security
5. **Authentication & Authorization**:
   - Enforce JWT with `jti` blacklisting (`jwt_blacklist:{jti}`, TTL: 1h) via `/auth.v1/ValidateToken`.
   - Implement RBAC (`admin:gamification:edit`) via API Gateway.

6. **Audit Defense**:
   - Emit `badge.awarded` to `audit_log` Kafka topic via `admin-service`, with 90–180 day retention and cold-tier archival.
   - Implement `/gamification.v1/PurgeAuditLogs` for CCPA compliance.

### Observability
7. **Traceability**:
   - Use `trace_id` (OpenTelemetry) in gRPC and Kafka for distributed tracing.

8. **Dashboarding**:
   - Provide sample Grafana panel JSON in repo for badge awards, leaderboard latency, DLQ size, and translation cache hits.

### DevOps / Operability
9. **Runbooks & SLOs**:
   - Define runbooks for badge latency, event failures, Redis crashes.
   - Set SLOs: 99% requests <200ms (cache hit/miss), <0.5% failure rate.

10. **Service Discovery**:
    - Register with Consul (`SERVICE_NAME=gamification`, `SERVICE_PORT=50054`, `SERVICE_CHECK_HTTP=/health`).

### Platform Evolution
11. **Multilingual Support**:
    - Centralize translations in `translations` table, validate with DeepL and Jest linting.
    - Automate i18n tests for `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja`.

12. **Dependency Management**:
    - Mock `users-service`, `auth-service`, `points-service`, `campaign-service` in CI/CD to avoid delays.