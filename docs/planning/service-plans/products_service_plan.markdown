# Products Service Plan (Revised)

## Overview
- **Purpose**: Manages product search and recommendations in preparation for Phase 6, with Phase 3 setup for Elasticsearch indexing, Shopify sync, and foundational observability/localization.
- **Priority for TVP**: Low (Phase 3 prep), high for Phase 6 (search/recommendations).
- **Dependencies**: `users-service` (customer data), `rfm-service` (RFM score updates), `campaign-service` (product campaigns), Event Tracking (notifications), `auth-service` (JWT validation), Shopify API (product data sync), Kafka (event streaming), Consul (service discovery), Redis (caching, idempotency), Elasticsearch (product indexing), Prometheus (metrics), Loki (logging), Backblaze B2 (audit log retention).

## Database Setup
- **Database Type**: Elasticsearch (port: 9200), Redis (port: 6379), PostgreSQL (port: 5432, for `processed_events`, `translations`).
- **Index**: `products`.
- **Tables**: `processed_events`, `translations`, `audit_logs` (via Kafka to `admin-service`).
- **Redis Keys**:
  - `product:{id}`: Caches `/products.v1/SearchProducts` responses (TTL: 1h).
  - `processed:{merchant_id}:{event_id}`: Tracks processed Kafka events/webhooks (TTL: 24h).
  - `translations:{key}:{locale}`: Caches localized product names (TTL: 24h).
  - `jwt_blacklist:{jti}`: Tracks invalidated JWTs (TTL: 1h).
  - **Eviction**: `volatile-lru` for caches, `noeviction` for processed events and JWT blacklist.

### `products` Index (Elasticsearch)
| Field            | Type       | Description                                                                |
|------------------|------------|---------------------------------------------------------------------------|
| `id`             | keyword    | Product ID (UUID)                                                         |
| `merchant_id`    | keyword    | Foreign Key → `merchants`, Indexed                                        |
| `name`           | text       | Product name, supports synonyms, stemming, fuzzy matching, multilingual via `translations` |
| `rfm_score`      | object     | e.g., `{ "recency": 3, "frequency": 2, "monetary": 4 }`                  |
| `reviews`        | object     | e.g., `{ "rating": 4.5, "count": 10 }` (Phase 6 prep for UGC)            |
| `schema_version` | keyword    | e.g., "1.0.0", for index evolution                                        |
| `created_at`     | date       | Creation timestamp                                                        |
| `updated_at`     | date       | Last update timestamp                                                     |
| `trace_id`       | keyword    | For distributed tracing (OpenTelemetry)                                   |

#### Elasticsearch Mappings
- **Analyzers**: Language-specific (e.g., `english`, `arabic`, `japanese`), synonym filter, stemming, fuzzy matching (max 2 edits).
- **Sharding**: 3 shards, 1 replica for `products` index.
- **ILM**: Hot tier (30 days), warm tier (150 days), delete after 180 days.

### `processed_events` Table (PostgreSQL)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `event_id`    | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `event_type`  | TEXT       | ENUM: ['product.updated', 'product.searched', 'product.task']              |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (24h)                                            |

### `translations` Table (PostgreSQL)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `id`          | UUID       | Primary Key                                                                 |
| `key`         | TEXT       | Unique, e.g., "product.name.123"                                           |
| `locale`      | TEXT       | ENUM: ['en', 'es', 'fr', 'ar', 'de', 'pt', 'ja', ...]                     |
| `value`       | TEXT       | Localized product name, e.g., "Blue Shirt"                                 |
| `version`     | TEXT       | e.g., "1.0.0", for translation versioning                                  |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (90 days)                                         |

### Constraints & Indexes
- **PostgreSQL Indexes**:
  - `idx_processed_events_merchant_id` (btree: `merchant_id`).
  - `idx_translations_key_locale` (btree: `key`, `locale`).
- **Triggers**:
  - `trg_updated_at`: Updates `updated_at` on `products` index changes.
  - `trg_validate_translations`: Validates `name` against `translations` for `locale`.

### GDPR/CCPA Compliance
- No PII stored in `products` index or `translations` table.
- Audit logs emitted to Kafka (`product.updated`) via `admin-service`, retained for 90–180 days (configurable per `merchant_id`) in Backblaze B2, with cold-tier archival after 180 days.
- Merchant-initiated purge API (`/products.v1/PurgeAuditLogs`) for CCPA compliance.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by Products Service)
| Endpoint                      | Input                              | Output                        | Called By       | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/products.v1/SearchProducts` | `merchant_id`, `query`, `locale`   | List of products              | Frontend, `campaign-service` | Searches products (Phase 6).      |
| `/products.v1/PurgeAuditLogs` | `merchant_id`, `jwt_token`         | `status`                      | `admin-service` | Purges audit logs for CCPA.       |

#### gRPC Calls (Made by Products Service)
| Endpoint                      | Input                              | Output                        | Service         | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/auth.v1/ValidateToken`      | `jwt_token`                        | `merchant_id`, `scopes`       | `auth-service`  | Validates JWT for gRPC calls.     |
| `/users.v1/GetCustomer`       | `customer_id`, `merchant_id`       | `email`, `points_balance`     | `users-service` | Fetches customer data for RFM.    |

#### REST Endpoints (Consumed via API Gateway)
| Endpoint               | Method | Source         | Purpose                           |
|------------------------|--------|----------------|-----------------------------------|
| `/webhooks/products/update` | POST   | Shopify API    | Updates product data.             |

- **Port**: 50053 (gRPC), 8080 (REST).
- **Authentication**: JWT via `/auth.v1/ValidateToken` with `jti` blacklisting in Redis (`jwt_blacklist:{jti}`, TTL: 1h).
- **Authorization**: RBAC (`admin:products:view`) via API Gateway.
- **Security**: mTLS for internal gRPC communication (Vault-managed certs).
- **Service Discovery**: Consul (`SERVICE_NAME=products`, `SERVICE_CHECK_HTTP=/health`).
- **Rate Limits**: Internal (100 req/s per merchant for `/products.v1/SearchProducts`), IP-based (100 req/s per IP for REST).

### Asynchronous Communication
#### Events Produced (Kafka)
| Event                 | Payload                                            | Consumed By         | Description                       |
|-----------------------|----------------------------------------------------|---------------------|-----------------------------------|
| `product.updated`     | `{ event_id, id, merchant_id, name, rfm_score, reviews, locale, schema_version, created_at, trace_id }` | `rfm-service`, `campaign-service`, `admin-service` | Signals product update.           |
| `product.searched`    | `{ event_id, merchant_id, query, locale, created_at, trace_id }` | `campaign-service` | Tracks search popularity.         |
| `product.task`        | `{ event_id, id, merchant_id, task_type, locale, created_at, trace_id }` | Event Tracking | Triggers notification tasks.      |
| `cache.invalidate`    | `{ key, merchant_id, type, locale, created_at }`   | `campaign-service`, `admin-service` | Invalidates Redis caches.         |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `customer.updated`    | `users-service`| `{ event_id, customer_id, merchant_id, email, language }` | Updates `rfm_score` in `products`. |

#### Webhooks Consumed
| Webhook               | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `products/update`     | Shopify API    | `{ id, merchant_id, name, updated_at, X-Shopify-Webhook-Id }` | Updates `products` index, emits `product.updated`. |

- **Schema**: Avro, backward-compatible, registered in Confluent Schema Registry.
- **Idempotency**: `event_id` for Kafka events, `X-Shopify-Webhook-Id` for webhooks, tracked in Redis (`processed:{merchant_id}:{event_id}`) or `processed_events`.
- **Dead-Letter Queue**: Failed events sent to `products.dlq` topic, max 3 retries before DLQ.
- **Replay Support**: `products.replay` topic with rate-controlled replays (100 events/s), filters for `merchant_id`, `event_type`, time window, and CLI (`reprocess_dlq.py`).
- **Saga Patterns** (Phase 6):
  - Product Update: `products-service` → `product.updated` → `rfm-service` → `campaign-service` → `product.task`.
- **Traceability**: `trace_id` (OpenTelemetry) in all Kafka events, gRPC calls, and webhooks for distributed tracing.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| `users-service`| Provides customer data via `/users.v1/GetCustomer`.                     |
| `auth-service` | Validates JWT via `/auth.v1/ValidateToken`.                             |
| `rfm-service`  | Consumes `product.updated`, updates `rfm_score`.                        |
| `campaign-service` | Consumes `product.updated`, `product.searched` for campaign updates.    |
| `admin-service`| Consumes `product.updated` for audit logging.                           |
| Event Tracking | Consumes `product.task` for Klaviyo/Postscript notifications.            |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Shopify API   | Sends `/webhooks/products/update` (REST) for product data sync.          |
| Klaviyo/Postscript | Sends notifications via Event Tracking (`product.task`).                 |
| Kafka         | Event transport, DLQ, and replay (Avro schema registry).                 |
| Elasticsearch | Primary data store for `products` index.                                 |
| Redis         | Caching, idempotency, translation storage, JWT blacklisting.             |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| Backblaze B2  | Audit log retention (via `admin-service`, 90–180 days, cold-tier archival). |

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| gRPC     | `/products.v1/SearchProducts` | Searches products (Phase 6).      |
| gRPC     | `/products.v1/PurgeAuditLogs` | Purges audit logs for CCPA.       |
| REST     | `/webhooks/products/update`   | Updates product data from Shopify. |
| HTTP     | `/health`                     | Liveness check.                   |
| HTTP     | `/ready`                      | Readiness check.                  |
| HTTP     | `/metrics`                    | Prometheus metrics export.        |
| Kafka    | `product.updated`, `product.searched`, `product.task`, `cache.invalidate` | Signals product events/tasks/cache invalidation. |
| Kafka    | `products.dlq`                | Stores failed events for retry.    |
| Kafka    | `products.replay`             | Stores events for replay.         |

- **Access Patterns**: High read (`SearchProducts`, 1,000 concurrent requests in Phase 6), low write (`products/update`).
- **Rate Limits**: Internal (100 req/s per merchant for `/products.v1/SearchProducts`), IP-based (100 req/s per IP for REST).

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `products_search_total` (by `merchant_id`, `locale`).
  - `products_search_latency_seconds` (cache hit/miss).
  - `products_sync_latency_seconds` (Shopify webhook sync).
  - `products_indexing_throughput_total` (documents indexed per second).
  - `products_sync_errors_total` (by `error_type`).
  - `products_shard_health_total` (active shards vs. total).
  - `products_indexing_errors_total` (failed indexing attempts).
  - `products_dlq_size_total` (DLQ queue size).
  - `translations_cache_hits_total`, `translations_cache_misses_total`.
- **Logging**: Structured JSON via Loki, tagged with `merchant_id`, `product_id`, `event_type`, `locale`, `trace_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Search latency > 500ms.
  - Sync latency > 5s.
  - DLQ size > 100 events.
  - Webhook/indexing failures > 5/hour.
- **Dashboards**: Grafana panels (sample JSON in repo):
  - Search volume and query popularity per minute.
  - Sync and indexing latency trends.
  - Shard health and DLQ size.
  - Translation cache hit/miss ratio.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `ProductsRepository` (`searchProducts`), localization, linting for `name`. |
| Contract Tests | Pact            | `/products.v1/SearchProducts` compatibility with `campaign-service`.   |
| Integration    | Testcontainers  | Elasticsearch, Redis, Kafka, Shopify API, `users-service`, `auth-service`. |
| E2E Tests      | Cypress         | `/products.v1/SearchProducts`, `/webhooks/products/update` flows (Phase 6 prep). |
| Load Tests     | k6              | 1,000 concurrent `SearchProducts` calls, <200ms latency (cache hit/miss). |
| Chaos Testing  | Chaos Mesh      | Elasticsearch, Redis, Kafka crashes; service failures.                |
| Compliance     | Jest            | Verify no PII, audit log emission, CCPA purge functionality.          |
| i18n Tests     | Jest            | Validate `name` for `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja` (90%+ accuracy). |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `products-service:latest`.
  - Ports: `50053` (gRPC), `8080` (REST, `/health`, `/metrics`, `/ready`).
  - Dependencies: Elasticsearch (port 9200), Kafka, Redis, PostgreSQL (port 5432).
  - Environment Variables: `PRODUCTS_DB_HOST`, `PRODUCTS_DB_PORT`, `KAFKA_BROKER`, `AUTH_HOST`, `SHOPIFY_API_KEY`.
- **Resource Limits**:
  - CPU: 0.3 cores per instance.
  - Memory: 256MiB per instance.
- **Scaling**: Single instance for Phase 3, 2 instances for 1,000 concurrent searches in Phase 6; Elasticsearch with 3 shards, 1 replica.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Pact, Cypress, k6, OWASP ZAP, and CLI (`reprocess_dlq.py`, `cleanup_translations.py`).

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| Premature indexing       | Defer search logic to Phase 6, focus on index creation in Phase 3.        |
| High search/sync latency | Cache in Redis (`product:{id}`), monitor `products_search_latency_seconds`, `products_sync_latency_seconds`. |
| Event/webhook duplication| Use `event_id`, `X-Shopify-Webhook-Id`, track in Redis/`processed_events`. |
| Translation table growth | TTL index (90 days) on `translations`, CLI for version pruning.           |
| Dependency failures      | Dead-letter queue (`products.dlq`), mock `users-service`, `auth-service` in CI/CD. |
| Stale index content      | SLO: 95% updates reflected within 5 minutes, monitor `products_sync_latency_seconds`. |

## Action Items
- [ ] Deploy `products_db` (Elasticsearch), Redis, and PostgreSQL by **August 5, 2025** (Owner: DB Team).
- [ ] Create `products` index with synonym/stemming mappings and `translations` table by **August 7, 2025** (Owner: DB Team).
- [ ] Implement `/products.v1/SearchProducts`, `/webhooks/products/update`, and Kafka events by **August 8, 2025** (Owner: Dev Team).
- [ ] Configure Prometheus `/metrics`, Loki logs, and Grafana panels by **August 9, 2025** (Owner: SRE Team).
- [ ] Conduct Jest, Pact, k6 (1,000 searches), chaos, and i18n tests by **August 10, 2025** (Owner: QA Team).
- [ ] Implement CLI (`reprocess_dlq.py`, `cleanup_translations.py`) and replay script for `products.replay` by **August 10, 2025** (Owner: Dev Team).

## Epics and Stories
| Epic                     | Stories                                    | Owner      | Due Date       |
|--------------------------|--------------------------------------------|------------|----------------|
| Database Setup           | Deploy Elasticsearch, Redis, PostgreSQL; create index/tables | DB Team    | August 7, 2025 |
| Core Functionality       | Implement gRPC, REST, Kafka events         | Dev Team   | August 8, 2025 |
| Localization             | Set up `translations`, validate languages  | Frontend Team | August 8, 2025 |
| Observability            | Configure Prometheus, Loki, Grafana panels | SRE Team   | August 9, 2025 |
| Testing & Validation     | Unit, contract, load, chaos, i18n tests    | QA Team    | August 10, 2025|
| Event Replay & DLQ       | Implement `reprocess_dlq.py`, replay script | Dev Team   | August 10, 2025|
| AI Personalization       | Plan Phase 6 AI-driven search with RFM/behavior signals | Dev Team   | August 10, 2025|

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | July 25, 2025     |
| Database and Redis Deployment | August 5, 2025    |
| Index and Translations Setup  | August 7, 2025    |
| Core Functionality (gRPC, REST, Kafka) Complete | August 8, 2025 |
| Observability Setup           | August 9, 2025    |
| Testing and Replay            | August 10, 2025   |
| Completion                    | August 10, 2025   |

## Recommendations
### Architecture & Design
1. **Event Idempotency**:
   - Use `event_id` for `product.updated`, `product.searched`, `product.task`, tracked in Redis/`processed_events`.
   - Validate deduplication for events and webhooks (`X-Shopify-Webhook-Id`).

2. **Caching Strategy**:
   - Cache `SearchProducts` in Redis (`product:{id}`, TTL: 1h), invalidate on `product.updated`, `cache.invalidate`.
   - Emit `cache.invalidate` Kafka events for cross-service consistency.

3. **Schema Versioning**:
   - Use `schema_version` in `products` index and Kafka events, enforce backward-compatible schemas in Confluent Schema Registry.

4. **Replay & DLQ**:
   - Rate-controlled replays (100 events/s) with filters for `merchant_id`, `event_type`, time window.
   - CLI (`reprocess_dlq.py`) for `products.dlq` and `products.replay` (max 3 retries).

5. **AI Personalization** (Phase 6):
   - Plan machine learning models using RFM and behavior signals from `users-service` (e.g., purchase history).

### Security
6. **Authentication & Authorization**:
   - Enforce JWT with `jti` blacklisting (`jwt_blacklist:{jti}`, TTL: 1h) via `/auth.v1/ValidateToken`.
   - Implement RBAC (`admin:products:view`) via API Gateway.

7. **Audit Defense**:
   - Emit `product.updated` to `audit_log` Kafka topic via `admin-service`, with 90–180 day retention and cold-tier archival.
   - Implement `/products.v1/PurgeAuditLogs` for CCPA compliance.

### Observability
8. **Traceability**:
   - Use `trace_id` (OpenTelemetry) in gRPC, REST, and Kafka for distributed tracing.

9. **Dashboarding**:
   - Provide sample Grafana panel JSON in repo for search volume, sync/indexing latency, shard health, and translation cache hits.

### DevOps / Operability
10. **Runbooks & SLOs**:
    - Define runbooks for search latency, webhook failures, Elasticsearch crashes, stale content.
    - Set SLOs: 99% requests <200ms (cache hit/miss), <0.5% failure rate, 95% updates reflected within 5 minutes.

11. **Service Discovery**:
    - Register with Consul (`SERVICE_NAME=products`, `SERVICE_PORT=50053`, `SERVICE_CHECK_HTTP=/health`).

### Platform Evolution
12. **Multilingual Support**:
    - Centralize translations in `translations` table, validate with DeepL and Jest linting.
    - Automate i18n tests for `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja`.

13. **Dependency Management**:
    - Mock `users-service`, `auth-service`, `rfm-service`, `campaign-service` in CI/CD to avoid delays.

14. **UGC Ingestion** (Phase 6):
    - Prepare `reviews` field for future review/UGC ingestion (e.g., Yotpo integration).