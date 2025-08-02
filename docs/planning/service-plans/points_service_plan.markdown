# Points Service Plan (Revised)

## Overview
- **Purpose**: Manages points transactions (earning, spending, bonuses) and reward redemptions for loyalty programs, with multilingual transaction messages and robust audit logging.
- **Priority for TVP**: High (core TVP feature).
- **Dependencies**: Core Service (customer data), Auth Service (JWT and merchant validation), Shopify API (order webhooks), Event Tracking (redemption tasks), Campaign (tier-based bonuses), Kafka (event streaming), Consul (service discovery), Redis (caching, idempotency), Prometheus (metrics), Loki (logging), Backblaze B2 (audit log retention).

## Database Setup
- **Database Type**: MongoDB (port: 27017), Redis (port: 6380).
- **Collections**: `points_transactions`, `reward_redemptions`, `pos_offline_queue`, `processed_events`, `translations`.

### `points_transactions` Schema
| Field           | Type       | Constraints                                                                 |
|-----------------|------------|-----------------------------------------------------------------------------|
| `_id`           | ObjectId   | Primary Key                                                                 |
| `customer_id`   | UUID       | Indexed, Foreign Key → `customers` (Core Service)                           |
| `merchant_id`   | UUID       | Indexed, Foreign Key → `merchants`                                          |
| `points`        | Integer    | CHECK >= 0                                                                 |
| `type`          | String     | ENUM: ['earn', 'spend', 'expire', 'bonus']                                 |
| `locale`        | String     | ENUM: ['en', 'ar', 'he', ...], DEFAULT 'en'                                |
| `description`   | String     | Localized, validated against `translations` (e.g., "Earned {points} points") |
| `event_id`      | UUID       | Unique, for idempotency                                                    |
| `schema_version`| String     | e.g., "1.0.0", for schema evolution                                        |
| `created_at`    | Timestamp  | DEFAULT now()                                                              |
| `correlation_id`| UUID       | For tracing across services                                                |

### `reward_redemptions` Schema
| Field           | Type       | Constraints                                                                 |
|-----------------|------------|-----------------------------------------------------------------------------|
| `_id`           | ObjectId   | Primary Key                                                                 |
| `customer_id`   | UUID       | Indexed, Foreign Key → `customers`                                          |
| `merchant_id`   | UUID       | Indexed, Foreign Key → `merchants`                                          |
| `reward_id`     | UUID       | Unique per redemption                                                      |
| `idempotency_token` | UUID   | Unique, for redemption deduplication                                       |
| `points`        | Integer    | CHECK > 0                                                                  |
| `status`        | String     | ENUM: ['pending', 'completed', 'failed']                                   |
| `locale`        | String     | ENUM: ['en', 'ar', 'he', ...], DEFAULT 'en'                                |
| `task_id`       | UUID       | Foreign Key → `queue_tasks` (Event Tracking), Nullable                     |
| `schema_version`| String     | e.g., "1.0.0", for schema evolution                                        |
| `created_at`    | Timestamp  | DEFAULT now()                                                              |
| `correlation_id`| UUID       | For tracing across services                                                |

### `pos_offline_queue` Schema
| Field           | Type       | Constraints                                                                 |
|-----------------|------------|-----------------------------------------------------------------------------|
| `_id`           | ObjectId   | Primary Key                                                                 |
| `customer_id`   | UUID       | Indexed, Foreign Key → `customers`                                          |
| `merchant_id`   | UUID       | Indexed, Foreign Key → `merchants`                                          |
| `points`        | Integer    | CHECK != 0                                                                 |
| `type`          | String     | ENUM: ['earn', 'spend']                                                    |
| `locale`        | String     | ENUM: ['en', 'ar', 'he', ...], DEFAULT 'en'                                |
| `idempotency_token` | UUID   | Unique, for deduplication                                                  |
| `created_at`    | Timestamp  | DEFAULT now(), TTL index (24h)                                             |

### `processed_events` Schema
| Field           | Type       | Constraints                                                                 |
|-----------------|------------|-----------------------------------------------------------------------------|
| `_id`           | ObjectId   | Primary Key                                                                 |
| `event_id`      | UUID       | Unique, for idempotency                                                    |
| `merchant_id`   | UUID       | Indexed, Foreign Key → `merchants`                                          |
| `event_type`    | String     | ENUM: ['points.earned', 'reward.redemption', 'order.created']              |
| `created_at`    | Timestamp  | DEFAULT now(), TTL index (24h)                                             |

### `translations` Schema
| Field           | Type       | Constraints                                                                 |
|-----------------|------------|-----------------------------------------------------------------------------|
| `_id`           | ObjectId   | Primary Key                                                                 |
| `key`           | String     | Unique, e.g., "points.earned.order"                                        |
| `locale`        | String     | ENUM: ['en', 'ar', 'he', ...]                                              |
| `value`         | String     | Localized text, e.g., "Earned {points} points"                             |
| `version`       | String     | e.g., "1.0.0", for translation versioning                                  |
| `created_at`    | Timestamp  | DEFAULT now()                                                              |

### Indexes
- `points_transactions`:
  - `idx_customer_id_merchant_id` (compound: `customer_id`, `merchant_id`).
  - `idx_created_at` (btree: `created_at`).
  - `idx_event_id` (unique: `event_id`).
- `reward_redemptions`:
  - `idx_customer_id_merchant_id` (compound: `customer_id`, `merchant_id`).
  - `idx_reward_id` (unique: `reward_id`).
  - `idx_idempotency_token` (unique: `idempotency_token`).
  - `idx_task_id` (btree: `task_id`, sparse).
- `pos_offline_queue`:
  - `idx_customer_id_merchant_id` (compound: `customer_id`, `merchant_id`).
  - `idx_idempotency_token` (unique: `idempotency_token`).
  - `idx_created_at` (TTL: 24h).
- `processed_events`:
  - `idx_event_id` (unique: `event_id`).
  - `idx_merchant_id` (btree: `merchant_id`).
  - `idx_created_at` (TTL: 24h).
- `translations`:
  - `idx_key_locale` (compound: `key`, `locale`).

### Redis Keys
- `cache:{merchant_id}:{customer_id}:points`: Caches `/points.v1/GetPointsBalance` responses (TTL: 1h).
- `processed:{merchant_id}:{event_id}`: Tracks processed Kafka events/webhooks (TTL: 24h).
- `rate_limit:{merchant_id}:points`: Limits Shopify webhook processing (TTL: 60s, max 40 req/s).
- `translations:{key}:{locale}`: Caches localized messages (TTL: 24h).
- **Eviction**: `volatile-lru` for caches, `noeviction` for processed events and rate limits.

### GDPR/CCPA Compliance
- No PII stored; `customer_id` references Core Service for PII.
- Audit logs emitted to AdminCore via Kafka (`points.earned`, `reward.redemption`), retained for 90–180 days (configurable per `merchant_id`) in Backblaze B2.
- `description` sanitized to exclude PII, validated against `translations` collection.

### Schema Details
- **Sharding**: `points_transactions`, `reward_redemptions` sharded by `merchant_id`.
- **Validation**: JSON schema for `description`, enforced by MongoDB validator.
- **TTL Index**: `pos_offline_queue.created_at` (24h), `processed_events.created_at` (24h).
- **Write Retries**: Exponential backoff (1s, 2s, 4s) for MongoDB write contention.
- **Batch Writes**: Max 1,000 transactions/batch for Shopify sale events.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by Points Service)
| Endpoint                      | Input                              | Output                        | Called By       | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/points.v1/GetPointsBalance` | `merchant_id`, `customer_id`, `locale` | `balance`, `description`      | Frontend        | Fetches customer points balance.  |

#### gRPC Calls (Made by Points Service)
| Endpoint                      | Input                              | Output                        | Service         | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/core.v1/GetCustomerRFM`     | `merchant_id`, `customer_id`       | `recency`, `frequency`, `monetary` | Core Service | Validates customer for transactions. |
| `/auth.v1/ValidateToken`      | `jwt_token`                        | `merchant_id`, `scopes`       | Auth Service    | Validates JWT for gRPC/REST calls. |

- **Port**: 50059 (gRPC).
- **Authentication**: JWT via `/auth.v1/ValidateToken` for all gRPC endpoints.
- **Authorization**: RBAC (`merchant:points:view`, `customer:points:view`) via API Gateway.
- **Security**: mTLS for internal gRPC communication (Vault-managed certs).
- **Service Discovery**: Consul (`SERVICE_NAME=points`, `SERVICE_CHECK_HTTP=/health`).

#### REST Endpoints (Consumed via API Gateway)
| Endpoint               | Method | Source         | Purpose                           |
|------------------------|--------|----------------|-----------------------------------|
| `/orders/create`       | POST   | Shopify API    | Triggers points earning from orders. |

- **Idempotency**: `X-Shopify-Webhook-Id` for webhook deduplication, tracked in Redis or `processed_events`.
- **Rate Limits**: 40 req/s (Shopify API Plus), tracked in Redis (`rate_limit:{merchant_id}:points`, TTL: 60s).

### Asynchronous Communication
#### Events Produced (Kafka)
| Event                 | Payload                                            | Consumed By         | Description                       |
|-----------------------|----------------------------------------------------|---------------------|-----------------------------------|
| `points.earned`       | `{ event_id, customer_id, merchant_id, points, type, locale, description, schema_version, created_at, correlation_id }` | RFM Analytics, AdminCore | Signals points earned.            |
| `reward.redemption`   | `{ event_id, customer_id, merchant_id, reward_id, idempotency_token, points, task_id, locale, schema_version, created_at, correlation_id }` | Event Tracking, AdminCore | Triggers redemption task.         |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `vip_tier.assigned`   | Campaign       | `{ event_id, customer_id, merchant_id, tier_id, assigned_at }` | Applies tier-based bonus points. |

- **Schema**: Avro, registered in Confluent Schema Registry.
- **Idempotency**: `event_id` or `idempotency_token` tracked in Redis (`processed:{merchant_id}:{event_id}`) or `processed_events`.
- **Dead-Letter Queue**: Failed events sent to `points.dlq` topic for retry/replay.
- **Replay Support**: `points.replay` topic for missed/redelivered events, with replay script in CI/CD.
- **Saga Patterns**:
  - Shopify → `/orders/create` → Points → `points.earned` → RFM Analytics → Core.
  - Campaign → `vip_tier.assigned` → Points → `points.earned` → AdminCore.
  - Points → `reward.redemption` → Event Tracking → `task.created` → AdminCore.
- **Correlation IDs**: Included in all Kafka events and gRPC calls for tracing.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| Core Service   | Validates customers via `/core.v1/GetCustomerRFM`.                       |
| Auth Service   | Validates JWT via `/auth.v1/ValidateToken`.                              |
| Event Tracking | Consumes `reward.redemption` for task queuing.                           |
| Campaign       | Emits `vip_tier.assigned` for bonus points.                             |
| RFM Analytics  | Consumes `points.earned` for score updates.                              |
| AdminCore      | Consumes `points.earned`, `reward.redemption` for audit logging.         |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Shopify API   | Sends `/orders/create` webhooks for points accrual.                      |
| Kafka         | Event transport, DLQ, and replay (Avro schema registry).                 |
| MongoDB       | Primary data store for transactions, redemptions, translations.          |
| Redis         | Caching, idempotency, rate-limiting, translation storage.                |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| Backblaze B2  | Audit log retention (via AdminCore, 90–180 days).                       |

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| gRPC     | `/points.v1/GetPointsBalance` | Fetches customer points balance.  |
| REST     | `/orders/create`              | Triggers points from Shopify orders. |
| HTTP     | `/health`                     | Liveness check.                   |
| HTTP     | `/ready`                      | Readiness check.                  |
| HTTP     | `/metrics`                    | Prometheus metrics export.        |
| Kafka    | `points.earned`, `reward.redemption` | Signals points/redemption events. |
| Kafka    | `points.dlq`                  | Stores failed events for retry.    |
| Kafka    | `points.replay`               | Stores events for replay.         |

- **Access Patterns**: High write (10,000 transactions/hour), moderate read (balance queries).
- **Rate Limits**: 40 req/s for Shopify API, tracked in Redis (`rate_limit:{merchant_id}:points`, TTL: 60s).

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `points_transactions_total` (by `type`, `locale`).
  - `points_balance_latency_seconds` (includes cache miss scenarios).
  - `points_errors_total` (by `error_type`).
  - `points_redemptions_total` (by `status`).
  - `points_rate_limit_exceeded_total` (Shopify API limits).
- **Logging**: Structured JSON via Loki, tagged with `merchant_id`, `customer_id`, `event_type`, `locale`, `correlation_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Transaction failures > 5/hour.
  - Balance query latency > 500ms.
  - Redemption failures > 5/hour.
  - Rate limit breaches > 10/hour.
- **Dashboards**: Grafana panels (sample JSON in repo):
  - Transactions per minute by type.
  - Error types and rates.
  - Latency trends (cache hit/miss).
  - Rate limit breach trends.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `PointsRepository` (`createTransaction`, `getBalance`), localization, linting for `description`. |
| Integration    | Testcontainers  | MongoDB, Redis, Kafka, Shopify webhooks, Event Tracking, Campaign.    |
| E2E Tests      | Cypress         | `/points.v1/GetPointsBalance`, `/orders/create` webhook flows.        |
| Load Tests     | k6              | 15,000 transactions/hour, <200ms latency (cache hit/miss).           |
| Chaos Testing  | Chaos Mesh      | MongoDB, Redis, Kafka crashes; service failures.                      |
| Compliance     | Jest            | Verify no PII, audit log emission, GDPR compliance.                   |
| i18n Tests     | Jest            | Validate `description`, `locale` for `en`, `ar`, `he` (90%+ accuracy). |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `points-service:latest`.
  - Ports: `50059` (gRPC), `8080` (HTTP for `/health`, `/metrics`, `/ready`).
  - Environment Variables: `POINTS_DB_HOST`, `KAFKA_BROKER`, `REDIS_HOST`, `AUTH_HOST`.
- **Resource Limits**:
  - CPU: 0.5 cores per instance.
  - Memory: 512MiB per instance.
- **Scaling**: 3 instances for 15,000 transactions/hour, MongoDB sharding by `merchant_id`.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, OWASP ZAP, and replay script for `points.replay`.

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| Write bottlenecks        | Shard `points_transactions` by `merchant_id`, batch writes (max 1,000/batch), exponential backoff retries. |
| Event/webhook duplication| Use `event_id`, `idempotency_token`, track in Redis/`processed_events`.     |
| High balance query latency | Cache in Redis, monitor `points_balance_latency_seconds` (hit/miss).       |
| Translation errors       | Centralized `translations` collection, Jest linting, DeepL validation.      |
| Shopify webhook failures | Buffer in `pos_offline_queue` (TTL: 24h, max 10,000 entries), retry with backoff. |
| Dependency failures      | Dead-letter queue (`points.dlq`), mock dependencies in CI/CD.              |

## Action Items
- [ ] Deploy `points_db` (MongoDB) and Redis by **August 5, 2025** (Owner: DB Team).
- [ ] Implement gRPC `/GetPointsBalance`, Shopify webhook handling, and Kafka events by **August 10, 2025** (Owner: Dev Team).
- [ ] Set up `translations` collection and validate `en`, `ar`, `he` by **August 10, 2025** (Owner: Frontend Team).
- [ ] Configure Prometheus `/metrics`, Loki logs, and Grafana panels by **August 12, 2025** (Owner: SRE Team).
- [ ] Conduct k6 load tests (15,000 transactions/hour), chaos tests, and i18n tests by **August 15, 2025** (Owner: QA Team).
- [ ] Implement replay script for `points.replay` topic by **August 15, 2025** (Owner: Dev Team).

## Epics and Stories
| Epic                     | Stories                                    | Owner      | Due Date       |
|--------------------------|--------------------------------------------|------------|----------------|
| Database Setup           | Deploy MongoDB, Redis; create collections  | DB Team    | August 5, 2025 |
| Core Functionality       | Implement gRPC, webhooks, Kafka events     | Dev Team   | August 10, 2025|
| Localization             | Set up `translations`, validate `en`, `ar`, `he` | Frontend Team | August 10, 2025|
| Observability            | Configure Prometheus, Loki, Grafana panels | SRE Team   | August 12, 2025|
| Testing & Validation     | Load, chaos, i18n, compliance tests        | QA Team    | August 15, 2025|
| Event Replay             | Implement `points.replay` script           | Dev Team   | August 15, 2025|

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | July 25, 2025     |
| Database and Redis Deployment | August 5, 2025    |
| Core Functionality (gRPC, Webhooks, Kafka) Complete | August 10, 2025 |
| Observability and Localization Setup | August 12, 2025 |
| Testing (Load, Chaos, i18n) and Replay | August 15, 2025 |
| Completion                    | August 15, 2025   |

## Recommendations
### Architecture & Design
1. **Event Idempotency**:
   - Use `event_id` for `points.earned`, `idempotency_token` for `reward.redemption` and webhooks, tracked in Redis/`processed_events`.
   - Validate `X-Shopify-Webhook-Id` for webhook deduplication.

2. **Caching Strategy**:
   - Cache `GetPointsBalance` in Redis, invalidate on `points.earned` or `reward.redemption`.
   - Cache translations in Redis (`translations:{key}:{locale}`).

3. **Schema Versioning**:
   - Add `schema_version` to collections and Kafka events for evolution.

4. **Replay Support**:
   - Use `points.replay` topic and CI/CD script for missed event replays.

### Security
5. **Authentication & Authorization**:
   - Enforce JWT via `/auth.v1/ValidateToken` for gRPC/REST.
   - Implement RBAC (`merchant:points:view`, `customer:points:view`) via API Gateway.

6. **Audit Defense**:
   - Emit all events to `audit_log` Kafka topic via AdminCore, configurable retention (90–180 days).

### Observability
7. **Correlation IDs**:
   - Include `correlation_id` in gRPC, REST, and Kafka for tracing.

8. **Dashboarding**:
   - Provide sample Grafana panel JSON in repo for transactions, latency, and rate limits.

### DevOps / Operability
9. **Runbooks & SLOs**:
   - Define runbooks for write bottlenecks, webhook failures, MongoDB crashes.
   - Set SLOs: 99% transactions <200ms (cache hit/miss), <0.5% failure rate.

10. **Service Discovery**:
    - Register with Consul (`SERVICE_NAME=points`, `SERVICE_PORT=50059`, `SERVICE_CHECK_HTTP=/health`).

### Platform Evolution
11. **Multilingual Support**:
    - Centralize translations in `translations` collection, validate with DeepL and Jest linting.
    - Automate i18n tests for `en`, `ar`, `he`.

12. **Dependency Management**:
    - Mock Core, Auth, Event Tracking, Campaign in CI/CD to avoid delays.