# Roles Service Plan (Revised)

## Overview
- **Purpose**: Manages role-based access control (RBAC) for admin users and multi-tenant groups, supporting admin module features (e.g., US-AM14, US-AM15) with multilingual permission descriptions, robust audit logging, and replay support.
- **Priority for TVP**: Medium (critical for admin security, secondary to customer-facing features).
- **Dependencies**: `users-service` (admin user data), `auth-service` (JWT validation), `admin-service` (multi-tenant configuration), Event Tracking (role assignment tasks), Campaign (tier-based role adjustments), Kafka (event streaming), Consul (service discovery), Redis (caching, idempotency), PostgreSQL (persistent storage), Prometheus (metrics), Loki (logging), Backblaze B2 (audit log retention).

## Database Setup
- **Database Type**: PostgreSQL (port: 5432), Redis (port: 6379).
- **Tables**: `roles`, `admin_roles`, `processed_events`, `translations`, `audit_logs` (via `admin-service`).
- **Redis Keys**:
  - `role:{role_id}`: Caches `/roles.v1/GetRole` responses (TTL: 1h).
  - `processed:{merchant_id}:{event_id}`: Tracks processed Kafka events (TTL: 24h).
  - `translations:{key}:{locale}`: Caches localized messages (TTL: 24h).
  - `jwt_blacklist:{jti}`: Tracks invalidated JWTs (TTL: 1h for `/roles.v1/AssignRole`, 24h otherwise).
  - **Eviction**: `volatile-lru` for caches, `noeviction` for processed events and JWT blacklist.

### `roles` Schema
| Column           | Type       | Constraints                                                                 |
|------------------|------------|-----------------------------------------------------------------------------|
| `role_id`        | UUID       | Primary Key                                                                 |
| `merchant_id`    | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `name`           | TEXT       | e.g., `admin:full`, `superadmin`, Indexed                                  |
| `status`         | TEXT       | ENUM: ['active', 'revoked', 'pending_update', 'deprecated']                |
| `permissions`    | JSONB      | e.g., `{ "scopes": ["read:customers", "write:campaigns"], "locale": "en" }` |
| `schema_version` | TEXT       | e.g., "1.0.0", for schema evolution                                        |
| `created_at`     | TIMESTAMP(3) | DEFAULT now()                                                            |
| `updated_at`     | TIMESTAMP(3) | Auto-updated via trigger                                                  |

### `admin_roles` Schema
| Column           | Type       | Constraints                                                                 |
|------------------|------------|-----------------------------------------------------------------------------|
| `admin_user_id`  | UUID       | Foreign Key → `admin_users` (`users-service`), Indexed                      |
| `role_id`        | UUID       | Foreign Key → `roles`, Indexed                                             |
| `merchant_id`    | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `created_at`     | TIMESTAMP(3) | DEFAULT now()                                                            |

### `processed_events` Schema
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `event_id`    | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `event_type`  | TEXT       | ENUM: ['role.assigned', 'role.updated', 'role.task']                       |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (24h)                                            |

### `translations` Schema
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `id`          | UUID       | Primary Key                                                                 |
| `key`         | TEXT       | Unique, e.g., "role.permissions.read:customers"                            |
| `locale`      | TEXT       | ENUM: ['en', 'ar', 'he', ...]                                              |
| `value`       | TEXT       | Localized text, e.g., "Read customer data"                                 |
| `version`     | TEXT       | e.g., "1.0.0", for translation versioning                                  |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (90 days)                                         |

### Constraints & Indexes
- **Unique Index**: `unique_admin_roles_user_role` (btree: `admin_user_id`, `role_id`).
- **Indexes**:
  - `idx_roles_name` (btree: `name`).
  - `idx_roles_merchant_id` (btree: `merchant_id`).
  - `idx_roles_status` (btree: `status`).
  - `idx_admin_roles_admin_user_id` (btree: `admin_user_id`).
  - `idx_admin_roles_merchant_id` (btree: `merchant_id`).
  - `idx_processed_events_merchant_id` (btree: `merchant_id`).
  - `idx_translations_key_locale` (btree: `key`, `locale`).
- **Triggers**:
  - `trg_updated_at`: Updates `updated_at` on `roles` row changes.
  - `trg_validate_permissions`: Validates `permissions.locale` against `translations` on insert/update.
- **Row-Level Security (RLS)**: Enabled on `roles` and `admin_roles` to restrict access by `merchant_id`.
- **Partitioning**: `roles` and `admin_roles` partitioned by `merchant_id` for scalability.
- **TTL Index**: `processed_events.created_at` (24h), `translations.created_at` (90 days).

### GDPR/CCPA Compliance
- No PII stored; `admin_user_id` links to `users-service` (AES-256 encrypted).
- Audit logs emitted to `admin-service` via Kafka (`role.assigned`, `role.updated`), retained for 90–180 days (configurable per `merchant_id`) in Backblaze B2, with cold-tier archival after 180 days.
- Merchant-initiated purge API (`/roles.v1/PurgeAuditLogs`) for CCPA compliance.
- `permissions` JSONB sanitized to exclude PII, validated against `translations`.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by Roles Service)
| Endpoint                      | Input                              | Output                        | Called By       | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/roles.v1/GetRole`           | `role_id`, `merchant_id`, `locale` | `name`, `status`, `permissions` | `auth-service`, `admin-service` | Fetches role details.             |
| `/roles.v1/AssignRole`        | `admin_user_id`, `role_id`, `merchant_id` | `AdminRole`            | `admin-service` | Assigns role to admin user.       |
| `/roles.v1/PurgeAuditLogs`    | `merchant_id`, `jwt_token`         | `status`                      | `admin-service` | Purges audit logs for CCPA.       |

#### gRPC Calls (Made by Roles Service)
| Endpoint                      | Input                              | Output                        | Service         | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/users.v1/GetAdminUser`      | `admin_user_id`, `merchant_id`     | `email`, `status`             | `users-service` | Validates admin user.             |
| `/auth.v1/ValidateToken`      | `jwt_token`                        | `merchant_id`, `scopes`       | `auth-service`  | Validates JWT for gRPC calls.     |

- **Port**: 50052 (gRPC).
- **Authentication**: JWT via `/auth.v1/ValidateToken` with `jti` blacklisting in Redis (`jwt_blacklist:{jti}`, TTL: 1h for `/roles.v1/AssignRole`, 24h otherwise).
- **Authorization**: RBAC (`admin:roles:view`, `admin:roles:assign`) via API Gateway.
- **Security**: mTLS for internal gRPC communication (Vault-managed certs).
- **Service Discovery**: Consul (`SERVICE_NAME=roles`, `SERVICE_CHECK_HTTP=/health`).

### Asynchronous Communication
#### Events Produced (Kafka)
| Event                 | Payload                                            | Consumed By         | Description                       |
|-----------------------|----------------------------------------------------|---------------------|-----------------------------------|
| `role.assigned`       | `{ event_id, admin_user_id, role_id, merchant_id, locale, schema_version, created_at, correlation_id }` | `auth-service`, `admin-service`, Event Tracking | Signals role assignment.          |
| `role.updated`        | `{ event_id, role_id, merchant_id, permissions, status, locale, schema_version, created_at, correlation_id }` | `auth-service`, `admin-service` | Signals role permission/status updates. |
| `role.task`           | `{ event_id, admin_user_id, merchant_id, task_type, locale, created_at, correlation_id }` | Event Tracking | Triggers admin notification tasks. |
| `cache.invalidate`    | `{ key, merchant_id, type, locale, created_at }`   | `auth-service`, `admin-service` | Invalidates Redis caches (role name, translations). |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `admin_user.updated`  | `users-service`| `{ event_id, admin_user_id, merchant_id, status }` | Validates role assignments.       |
| `vip_tier.assigned`   | Campaign       | `{ event_id, customer_id, merchant_id, tier_id, assigned_at }` | Adjusts admin roles for tier-based access. |

- **Schema**: Avro, backward-compatible, registered in Confluent Schema Registry.
- **Idempotency**: `event_id` tracked in Redis (`processed:{merchant_id}:{event_id}`) or `processed_events`.
- **Dead-Letter Queue**: Failed events sent to `roles.dlq` topic, max 3 retries before DLQ.
- **Replay Support**: `roles.replay` topic with rate-controlled replays (100 events/s), filters for `merchant_id`, `event_type`, time window, and CLI (`reprocess_dlq.py`).
- **Saga Patterns**:
  - Role Assignment: `roles-service` → `auth-service` → `admin-service` → `role.assigned` → Event Tracking.
  - Role Update: `roles-service` → `role.updated` → `auth-service` → `cache.invalidate`.
  - Admin User Update: `users-service` → `admin_user.updated` → `roles-service` → `role.task`.
- **Correlation IDs**: Included in all Kafka events and gRPC calls for tracing.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| `users-service`| Validates admin users via `/users.v1/GetAdminUser`.                     |
| `auth-service` | Validates JWT via `/auth.v1/ValidateToken`, consumes `role.assigned`.    |
| `admin-service`| Consumes `role.assigned`, `role.updated` for multi-tenant config.        |
| Event Tracking | Consumes `role.task` for admin notification tasks.                       |
| Campaign       | Emits `vip_tier.assigned` for tier-based role adjustments.               |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Kafka         | Event transport, DLQ, and replay (Avro schema registry).                 |
| PostgreSQL    | Primary data store for roles, admin_roles, and translations.             |
| Redis         | Caching, idempotency, translation storage, JWT blacklisting.             |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| Backblaze B2  | Audit log retention (via `admin-service`, 90–180 days, cold-tier archival). |

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| gRPC     | `/roles.v1/GetRole`           | Fetches role details.             |
| gRPC     | `/roles.v1/AssignRole`        | Assigns role to admin user.       |
| gRPC     | `/roles.v1/PurgeAuditLogs`    | Purges audit logs for CCPA.       |
| HTTP     | `/health`                     | Liveness check.                   |
| HTTP     | `/ready`                      | Readiness check.                  |
| HTTP     | `/metrics`                    | Prometheus metrics export.        |
| Kafka    | `role.assigned`, `role.updated`, `role.task`, `cache.invalidate` | Signals role events/tasks/cache invalidation. |
| Kafka    | `roles.dlq`                   | Stores failed events for retry.    |
| Kafka    | `roles.replay`                | Stores events for replay.         |

- **Access Patterns**: High read (`GetRole`, every admin action), low write (`AssignRole`, infrequent).
- **Rate Limits**: 50 req/s per admin user, enforced via API Gateway.

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `roles_get_total` (by `merchant_id`, `locale`, `status`).
  - `roles_assign_latency_seconds` (cache hit/miss).
  - `roles_errors_total` (by `error_type`).
  - `roles_dlq_size_total` (DLQ queue size).
  - `translations_cache_hits_total`, `translations_cache_misses_total`.
- **Logging**: Structured JSON via Loki, tagged with `merchant_id`, `role_id`, `event_type`, `locale`, `correlation_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Role assignment failures > 5/hour.
  - GetRole latency > 500ms.
  - DLQ size > 100 events.
- **Dashboards**: Grafana panels (sample JSON in repo):
  - Role assignments per minute by status.
  - Latency trends (cache hit/miss).
  - DLQ size and error rates.
  - Translation cache hit/miss ratio.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `RolesRepository` (`findById`, `assignRole`), localization, linting for `permissions`. |
| Contract Tests | Pact            | `/roles.v1/GetRole`, `/roles.v1/AssignRole` compatibility with `auth-service`, `admin-service`. |
| Integration    | Testcontainers  | PostgreSQL, Redis, Kafka, `users-service`, `auth-service`, Event Tracking, Campaign. |
| E2E Tests      | Cypress         | `/roles.v1/GetRole`, `/roles.v1/AssignRole` flows.                   |
| Load Tests     | k6              | 2,000 concurrent `GetRole` calls, <200ms latency (cache hit/miss).   |
| Chaos Testing  | Chaos Mesh      | PostgreSQL, Redis, Kafka crashes; service failures.                   |
| Compliance     | Jest            | Verify no PII, audit log emission, CCPA purge functionality.          |
| i18n Tests     | Jest            | Validate `permissions.locale`, `description` for `en`, `ar`, `he` (90%+ accuracy). |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `roles-service:latest`.
  - Ports: `50052` (gRPC), `8080` (HTTP for `/health`, `/metrics`, `/ready`).
  - Environment Variables: `ROLES_DB_HOST`, `ROLES_DB_PORT`, `ROLES_DB_NAME`, `KAFKA_BROKER`, `AUTH_HOST`.
- **Resource Limits**:
  - CPU: 0.3 cores per instance.
  - Memory: 256MiB per instance.
- **Scaling**: Single instance sufficient for 2,000 concurrent `GetRole` calls; PostgreSQL read replicas for read-heavy access.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Pact, Cypress, k6, OWASP ZAP, and CLI (`reprocess_dlq.py`, `cleanup_translations.py`).

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| Incorrect role assignments| Validate via `/auth.v1/ValidateToken`, track `event_id` in `processed_events`. |
| High GetRole latency     | Cache in Redis (`role:{role_id}`), monitor `roles_get_latency_seconds`.    |
| Translation table growth | TTL index (90 days) on `translations`, CLI for version pruning.            |
| Event duplication        | Use `event_id`, track in Redis/`processed_events`.                         |
| Dependency failures      | Dead-letter queue (`roles.dlq`), mock `users-service`, `auth-service`, Campaign in CI/CD. |

## Action Items
- [ ] Deploy `roles_db` (PostgreSQL) and Redis by **August 8, 2025** (Owner: DB Team).
- [ ] Define `Role.entity.ts` schema and implement gRPC `/GetRole`, `/AssignRole`, `/PurgeAuditLogs` by **August 15, 2025** (Owner: Dev Team).
- [ ] Set up `translations` table and validate `en`, `ar`, `he` by **August 15, 2025** (Owner: Frontend Team).
- [ ] Configure Prometheus `/metrics`, Loki logs, and Grafana panels by **August 18, 2025** (Owner: SRE Team).
- [ ] Conduct k6 load tests (2,000 `GetRole` calls), Pact contract tests, chaos tests, and i18n tests by **August 20, 2025** (Owner: QA Team).
- [ ] Implement CLI (`reprocess_dlq.py`, `cleanup_translations.py`) and replay script for `roles.replay` by **August 20, 2025** (Owner: Dev Team).

## Epics and Stories
| Epic                     | Stories                                    | Owner      | Due Date       |
|--------------------------|--------------------------------------------|------------|----------------|
| Database Setup           | Deploy PostgreSQL, Redis; create tables    | DB Team    | August 8, 2025 |
| Core Functionality       | Implement gRPC, Kafka events               | Dev Team   | August 15, 2025|
| Localization             | Set up `translations`, validate `en`, `ar`, `he` | Frontend Team | August 15, 2025|
| Observability            | Configure Prometheus, Loki, Grafana panels | SRE Team   | August 18, 2025|
| Testing & Validation     | Load, contract, chaos, i18n, compliance tests | QA Team | August 20, 2025|
| Event Replay & DLQ       | Implement `reprocess_dlq.py`, replay script | Dev Team   | August 20, 2025|

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | August 5, 2025    |
| Database and Redis Deployment | August 8, 2025    |
| Core Functionality (gRPC, Kafka) Complete | August 15, 2025 |
| Observability and Localization Setup | August 18, 2025 |
| Testing (Load, Contract, Chaos, i18n) and Replay | August 20, 2025 |
| Completion                    | August 20, 2025   |

## Recommendations
### Architecture & Design
1. **Event Idempotency**:
   - Use `event_id` for `role.assigned`, `role.updated`, `role.task`, tracked in Redis/`processed_events`.
   - Validate deduplication before processing events.

2. **Caching Strategy**:
   - Cache `GetRole` in Redis (`role:{role_id}`), invalidate on `role.updated`, `cache.invalidate` (including role name changes, `translations` updates).
   - Emit `cache.invalidate` Kafka events for cross-service consistency.

3. **Schema Versioning**:
   - Use `schema_version` in `roles` and Kafka events, enforce backward-compatible schemas in Confluent Schema Registry.

4. **Replay & DLQ**:
   - Rate-controlled replays (100 events/s) with filters for `merchant_id`, `event_type`, time window.
   - CLI (`reprocess_dlq.py`) for `roles.dlq` and `roles.replay` (max 3 retries).
   - Future: UI-based replay/cleanup interface.

### Security
5. **Authentication & Authorization**:
   - Enforce JWT with `jti` blacklisting (`jwt_blacklist:{jti}`, TTL: 1h for `/roles.v1/AssignRole`) via `/auth.v1/ValidateToken`.
   - Implement RBAC (`admin:roles:view`, `admin:roles:assign`) via API Gateway.

6. **Audit Defense**:
   - Emit events to `audit_log` Kafka topic via `admin-service`, with 90–180 day retention and cold-tier archival.
   - Implement `/roles.v1/PurgeAuditLogs` for CCPA compliance.

### Observability
7. **Correlation IDs**:
   - Include `correlation_id` in gRPC and Kafka for tracing.

8. **Dashboarding**:
   - Provide sample Grafana panel JSON in repo for role assignments, latency, DLQ size, and translation cache hits.

### DevOps / Operability
9. **Runbooks & SLOs**:
   - Define runbooks for role assignment failures, cache inconsistency, PostgreSQL crashes.
   - Set SLOs: 99% requests <200ms (cache hit/miss), <0.5% failure rate.

10. **Service Discovery**:
    - Register with Consul (`SERVICE_NAME=roles`, `SERVICE_PORT=50052`, `SERVICE_CHECK_HTTP=/health`).

### Platform Evolution
11. **Multilingual Support**:
    - Centralize translations in `translations` table, validate with DeepL and Jest linting.
    - Automate i18n tests for `en`, `ar`, `he`.

12. **Dependency Management**:
    - Mock `users-service`, `auth-service`, Event Tracking, Campaign in CI/CD to avoid delays.