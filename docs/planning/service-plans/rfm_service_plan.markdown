# RFM Service Plan (Revised)

## Overview
- **Purpose**: Manages RFM (Recency, Frequency, Monetary) analytics, including segment retrieval, visualizations, churn risk identification, A/B test nudges, simulations, time-weighted recency, multi-segment support, score history, and smart nudges, replacing `RFMAnalyticsService` (US-MD5, US-MD12, US-MD20–22, US-AM16, US-BI5). Drives merchant insights and retention for small (100–1,000 customers, AOV $20), medium (1,000–10,000 customers, AOV $100), and Plus merchants (50,000+ customers, AOV $500, 10,000 orders/hour).
- **Priority for TVP**: High, critical for lifecycle campaigns and retention (US-MD19).
- **Dependencies**:
  - `users-service`: Customer data (`users.rfm_score`, `users.metadata` JSONB).
  - `points-service`: Points transactions for frequency/monetary data.
  - `campaign-service`: Lifecycle campaigns based on RFM segments.
  - `auth-service`: JWT validation (`/auth.v1/ValidateToken`).
  - `admin-core-service`: Configuration, audit logging.
  - `admin-features-service`: Scheduling, queue monitoring, event simulation.
  - `frontend-service`: RFM UI, visualizations, nudges.
  - External: Shopify API (order/customer data), xAI API (churn prediction, https://x.ai/api), Klaviyo/Postscript (notifications), AWS SES (fallback).

## Database Setup
- **Database Type**: PostgreSQL (port 5432, range partitioning), Redis Cluster (port 6382, 3 nodes, 1 replica), TimescaleDB (port 5433, time-series).
- **Tables/Collections**:
  - `users` (from `users-service`): `id`, `email` (AES-256 encrypted), `rfm_score` (JSONB, encrypted), `metadata` (JSONB, lifecycle stages).
  - `customer_segments`: Multi-segment assignments (JSONB array).
  - `rfm_segment_counts`: Materialized view for segment analytics.
  - `rfm_segment_deltas`: Incremental updates on `orders/create`.
  - `rfm_score_history`: Historical RFM scores.
  - `rfm_benchmarks`: Anonymized industry benchmarks.
  - `analytics_metrics`: Visualization data (Chart.js).
  - `nudges`: Smart nudge templates (JSONB, multilingual).
  - `nudge_events`: A/B test nudge interactions.
  - `email_templates`: Multilingual notification templates (JSONB).
  - `email_events`: Notification tracking (encrypted).
  - `audit_logs` (via `admin-core-service`): RFM actions, CCPA purges.
  - `processed_events`: Kafka event idempotency.
- **Redis Keys**:
  - `rfm:customer:{id}`: Cached RFM scores (TTL: 24h).
  - `rfm:preview:{merchant_id}`: Segment previews (TTL: 1h).
  - `rfm:burst:{merchant_id}`: Shopify API burst cache (TTL: 1h).
  - `processed:{merchant_id}:{event_id}`: Event idempotency (TTL: 24h).
  - `jwt_blacklist:{jti}`: Invalidated JWTs (TTL: 1h).
  - Eviction: `volatile-lru` for caches, `noeviction` for processed events/JWTs.
- **Schema Details**:

### `users` Table (Users Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `id`          | UUID       | Primary Key                                                                 |
| `email`       | TEXT       | AES-256 encrypted, Indexed                                                 |
| `rfm_score`   | JSONB      | AES-256 encrypted, e.g., `{"recency": 5, "frequency": 3, "monetary": 4}`   |
| `metadata`    | JSONB      | Lifecycle stages, e.g., `{"stage": "repeat_buyer"}`                        |
| `created_at`  | TIMESTAMP(3) | DEFAULT now()                                                            |

### `customer_segments` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `segment_id`  | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Partition Key, Indexed                           |
| `rules`       | JSONB      | e.g., `{"recency": ">=4", "frequency": ">=3"}`                             |
| `name`        | JSONB      | Multilingual, e.g., `{"en": "Champions", "es": "Campeones"}`               |
| `segment_ids` | JSONB      | Array, e.g., `["Champions", "VIP"]`                                        |

### `rfm_segment_counts` Table (Materialized View, RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `segment_name`| TEXT       | e.g., `Champions`, `At-Risk`                                               |
| `count`       | INTEGER    | Customer count                                                             |
| `last_refreshed` | TIMESTAMP(3) | DEFAULT now()                                                        |

### `rfm_segment_deltas` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `merchant_id` | UUID       | Foreign Key → `merchants`, Partition Key, Indexed                           |
| `customer_id` | UUID       | Foreign Key → `users`                                                      |
| `segment_change` | JSONB   | e.g., `{"from": "Loyal", "to": "At-Risk"}`                                |
| `updated_at`  | TIMESTAMP(3) | DEFAULT now(), Indexed                                                |

### `rfm_score_history` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `customer_id` | UUID       | Foreign Key → `users`, Partition Key, Indexed                               |
| `rfm_score`   | JSONB      | e.g., `{"recency": 5, "frequency": 3, "monetary": 4, "score": 4.1}`       |
| `timestamp`   | TIMESTAMP(3) | DEFAULT now(), Indexed                                                |

### `rfm_benchmarks` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `segment_name`| TEXT       | e.g., `Champions`                                                          |
| `industry_avg`| JSONB      | e.g., `{"count": 600, "avg_score": 4.2}`                                  |

### `analytics_metrics` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `metric`      | TEXT       | e.g., `repeat_purchase_rate`                                               |
| `data`        | JSONB      | e.g., `{"2025-01-01": 0.2}`                                               |

### `nudges` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `nudge_id`    | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `type`        | TEXT       | CHECK: `at-risk`, `loyal`, `new`, `inactive`, `tier_dropped`               |
| `title`       | JSONB      | Multilingual, e.g., `{"en": "Stay Active!", "es": "¡Mantente Activo!"}`    |
| `description` | JSONB      | Multilingual, e.g., `{"en": "Earn points!", "ar": "اكسب نقاطًا!"}`        |
| `is_enabled`  | BOOLEAN    | DEFAULT true                                                               |
| `variants`    | JSONB      | A/B test variants, e.g., `{"A": "Urgency", "B": "Discount"}`               |

### `nudge_events` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `event_id`    | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Partition Key, Indexed                           |
| `customer_id` | UUID       | Foreign Key → `users`                                                      |
| `nudge_id`    | UUID       | Foreign Key → `nudges`                                                     |
| `action`      | TEXT       | CHECK: `view`, `click`, `dismiss`                                          |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), Indexed                                                |

### `email_templates` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `template_id` | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `type`        | TEXT       | CHECK: `tier_change`, `nudge`                                              |
| `subject`     | JSONB      | Multilingual, e.g., `{"en": "Welcome to Gold!", "ja": "ゴールドへようこそ！"}` |
| `body`        | JSONB      | Multilingual, e.g., `{"en": "Enjoy perks!", "ar": "استمتع بالمميزات!"}`   |
| `fallback_language` | TEXT | DEFAULT `en`                                                          |

### `email_events` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `event_id`    | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Partition Key, Indexed                           |
| `event_type`  | TEXT       | CHECK: `sent`, `failed`                                                    |
| `recipient_email` | TEXT   | AES-256 encrypted, Indexed                                                 |

### `processed_events` Table (RFM Service)
| Column        | Type       | Constraints                                                                 |
|---------------|------------|-----------------------------------------------------------------------------|
| `event_id`    | UUID       | Primary Key                                                                 |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `event_type`  | TEXT       | ENUM: `rfm.updated`, `churn_risk.detected`, `rfm.task`                    |
| `created_at`  | TIMESTAMP(3) | DEFAULT now(), TTL index (24h)                                            |

- **Constraints & Indexes**:
  - Indexes: `idx_users_rfm_score` (btree: `rfm_score`), `idx_customer_segments_merchant_id` (btree: `merchant_id`), `idx_rfm_segment_counts_merchant_id_segment_name` (btree: `merchant_id`, `segment_name`), `idx_rfm_segment_deltas_merchant_id_updated_at` (btree: `merchant_id`, `updated_at`), `idx_rfm_score_history_customer_id` (btree: `customer_id`), `idx_rfm_benchmarks_merchant_id` (btree: `merchant_id`), `idx_nudges_merchant_id` (btree: `merchant_id`), `idx_nudge_events_merchant_id` (btree: `merchant_id`), `idx_email_templates_merchant_id` (btree: `merchant_id`), `idx_email_events_merchant_id` (btree: `merchant_id`), `idx_processed_events_merchant_id` (btree: `merchant_id`).
  - Partial Index: `idx_users_rfm_score_at_risk` (WHERE `rfm_score->>'score' < 2`) for At-Risk nudges.
  - Partitioning: `customer_segments`, `rfm_segment_deltas`, `nudge_events`, `email_events` by `merchant_id`.
  - Triggers: `trg_validate_nudges` (validate `title`, `description` JSONB), `trg_validate_email_templates` (validate `subject`, `body` JSONB).
- **Materialized Views**: `rfm_segment_counts` refreshed daily (`0 1 * * *`).
- **Encryption**: AES-256 via pgcrypto for `users.email`, `users.rfm_score`, `email_events.recipient_email`, quarterly key rotation via AWS KMS.
- **GDPR/CCPA Compliance**:
  - No PII in `rfm_segment_counts`, `rfm_benchmarks`, `analytics_metrics`, `nudge_events`.
  - AES-256 encryption for `users.email`, `users.rfm_score`, `email_events.recipient_email`.
  - Webhooks: `customers/data_request`, `customers/redact` (3 retries, Redis DLQ).
  - Audit logs via `admin-core-service` (`rfm_export`, `tier_assigned`, 90–180 day retention in Backblaze B2).
  - Purge API: `/rfm.v1/PurgeAuditLogs` for CCPA compliance.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by RFM Service)
| Endpoint                      | Input                              | Output                        | Called By       | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/rfm.v1/GetSegments`         | `merchant_id`, `locale`            | `segments` (JSONB)            | `campaign-service`, `admin-core-service`, `frontend-service` | Retrieve RFM segments (US-MD12). |
| `/rfm.v1/GetChurnRisk`        | `merchant_id`, `locale`            | `at_risk_customers`           | `campaign-service`, `frontend-service` | Identify at-risk customers (US-MD22). |
| `/rfm.v1/ConfigureABTestNudges` | `merchant_id`, `variant_config`, `locale` | `status`                | `admin-core-service`, `frontend-service` | Configure A/B test nudges (US-MD21). |
| `/rfm.v1/PreviewRFMSegments`  | `merchant_id`, `config`, `locale`  | `segment_sizes`               | `frontend-service`, `admin-core-service` | Simulate RFM segments (US-AM16). |
| `/rfm.v1/GetNudges`           | `merchant_id`, `locale`            | `nudges` (JSONB)              | `frontend-service`, `referrals-service` | Fetch smart nudges.               |
| `/rfm.v1/PurgeAuditLogs`      | `merchant_id`, `jwt_token`         | `status`                      | `admin-core-service` | Purge logs for CCPA.              |

#### gRPC Calls (Made by RFM Service)
| Endpoint                      | Input                              | Output                        | Service         | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/auth.v1/ValidateToken`      | `jwt_token`                        | `merchant_id`, `scopes`       | `auth-service`  | Validate JWT.                     |
| `/users.v1/GetCustomers`      | `merchant_id`, `customer_ids`      | `email`, `rfm_score`, `metadata` | `users-service` | Fetch customer data for RFM.      |
| `/points.v1/RedeemCampaignDiscount` | `merchant_id`, `customer_id`, `conditions` | `status`            | `points-service` | Assign rewards for segments.      |
| `/roles.v1/GetPermissions`    | `merchant_id`, `role_id`           | `permissions` (JSONB)         | `roles-service` | Enforce RBAC (`admin:analytics`). |

- **Port**: 50053 (gRPC), 8081 (REST).
- **Authentication**: JWT via `/auth.v1/ValidateToken`, `jti` blacklisting (`jwt_blacklist:{jti}`, TTL: 1h).
- **Authorization**: RBAC (`admin:analytics`, `admin:full`) via API Gateway.
- **Security**: mTLS (Vault-managed certs) for gRPC.
- **Service Discovery**: Consul (`SERVICE_NAME=rfm`, `SERVICE_CHECK_HTTP=/health`).
- **Rate Limits**: Internal (100 req/s per merchant for `/rfm.v1/GetSegments`), IP-based (100 req/s per IP for REST), xAI API (10 req/s, 3x backoff), Shopify API (2 req/s REST, 40 req/s Plus).

### Asynchronous Communication
#### Events Produced (Kafka)
| Event                 | Payload                                            | Consumed By         | Description                       |
|-----------------------|----------------------------------------------------|---------------------|-----------------------------------|
| `rfm.updated`         | `{ event_id, merchant_id, customer_id, segment, schema_version, locale, trace_id }` | `campaign-service`, `admin-core-service`, `frontend-service` | Signals segment update.           |
| `churn_risk.detected` | `{ event_id, merchant_id, customer_id, risk_score, locale, trace_id }` | `campaign-service`, `frontend-service` | Triggers Shopify Flow actions.    |
| `rfm.task`            | `{ event_id, merchant_id, customer_id, task_type, locale, trace_id }` | Event Tracking | Triggers Klaviyo/Postscript notifications. |
| `cache.invalidate`    | `{ key, merchant_id, type, locale, trace_id }`     | `points-service`, `admin-core-service` | Invalidates Redis caches.         |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `customer.created`    | `users-service`| `{ event_id, customer_id, merchant_id, email, language }` | Initialize RFM score.              |
| `points.earned`       | `points-service`| `{ event_id, customer_id, merchant_id, points }` | Update frequency/monetary scores.  |
| `orders.create`       | Shopify API    | `{ event_id, customer_id, merchant_id, totalPrice, createdAt }` | Trigger real-time RFM updates.     |

- **Schema**: Avro, backward-compatible, registered in Confluent Schema Registry.
- **Idempotency**: `event_id` tracked in Redis (`processed:{merchant_id}:{event_id}`, TTL: 24h) or `processed_events`.
- **Dead-Letter Queue**: `rfm.dlq` (max 3 retries), replay via `rfm.replay` (100 events/s, CLI: `reprocess_dlq.py`).
- **Saga Patterns**:
  - RFM Update: `users-service` → `customer.created` → `rfm-service` → `rfm.updated` → `rfm.task`.
  - Churn Detection: `rfm-service` → `churn_risk.detected` → `campaign-service` → Shopify Flow.
- **Traceability**: `trace_id` (OpenTelemetry) for gRPC and Kafka events.

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| gRPC     | `/rfm.v1/GetSegments`         | Retrieve RFM segments (US-MD12).  |
| gRPC     | `/rfm.v1/GetChurnRisk`        | Identify at-risk customers (US-MD22). |
| gRPC     | `/rfm.v1/ConfigureABTestNudges` | Configure A/B test nudges (US-MD21). |
| gRPC     | `/rfm.v1/PreviewRFMSegments`  | Simulate RFM segments (US-AM16).  |
| gRPC     | `/rfm.v1/GetNudges`           | Fetch smart nudges.               |
| gRPC     | `/rfm.v1/PurgeAuditLogs`      | Purge logs for CCPA.              |
| REST     | `/api/rfm/visualizations`     | Retrieve Chart.js visualizations (US-MD5). |
| REST     | `/api/rfm/export`             | Export segments (CSV/JSON/PNG).   |
| HTTP     | `/health`, `/ready`, `/metrics` | Liveness, readiness, Prometheus metrics. |
| Kafka    | `rfm.updated`, `churn_risk.detected`, `rfm.task`, `cache.invalidate` | Signals RFM updates, churn, notifications, cache invalidation. |
| Kafka    | `rfm.dlq`, `rfm.replay`       | Failed events, replays.           |

- **Access Patterns**: High-read (`GetSegments`, `GetChurnRisk`, 5,000 concurrent requests), medium-write (`ConfigureABTestNudges`, `PreviewRFMSegments`).
- **Rate Limits**: As above, with Bull queues (`rate_limit_queue:{merchant_id}`) for Shopify API bursts.

## Shopify Functions (Rust/Wasm)
- **Function**: `update_rfm_score` for real-time RFM updates on `orders/create`.
- **Logic**:
  ```rust
  #[shopify_function]
  fn update_rfm_score(input: Input) -> Result<Output> {
      let order = input.order;
      let config = input.rfm_config; // Includes recency_decay
      let score = calculate_rfm(&order, input.merchant_aov, config.recency_decay)?;
      update_customer(&score, &input.customer_id)?;
      log_history(&score, &input.customer_id)?; // rfm_score_history
      log_delta(&score, &input.customer_id, &input.merchant_id)?; // rfm_segment_deltas
      log::info!("RFM updated for customer {}", input.customer_id);
      Ok(Output { score })
  }
  ```
- **Features**: Time-weighted recency, multi-currency, edge case handling (zero orders, negative AOV).
- **Caching**: Redis Streams (`rfm:customer:{id}`, TTL: 24h).
- **Error Handling**: Log to Sentry (`rfm_function_failed`), retry 3x with Bull queues.
- **Tracking**: PostHog (`rfm_tier_assigned`, `rfm_nudge_clicked`).

## Monitoring & Observability
- **Metrics** (Prometheus):
  - `rfm_segments_total` (by `merchant_id`, `segment_name`, `locale`).
  - `rfm_churn_latency_seconds` (by `merchant_id`).
  - `rfm_dlq_size_total`, `rfm_errors_total` (by `error_type`).
  - `rfm_cache_hits_total`, `rfm_cache_misses_total`.
- **Logging**: Loki, structured JSON (tagged with `merchant_id`, `customer_id`, `locale`, `trace_id`).
- **Alerting**: Prometheus Alertmanager + AWS SNS for latency (>1s), DLQ size (>100 events), xAI API failures.
- **Dashboards**: Grafana panels for segment sizes, churn risk, nudge interactions, cache hit/miss ratio.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `RFMRepository.getSegments`, `RFMService.getChurnRisk`, nudge logic, i18n validation. |
| Contract Tests | Pact            | `/rfm.v1/GetSegments` compatibility with `campaign-service`.           |
| Integration    | Testcontainers  | PostgreSQL, Redis, Kafka, `users-service`, `points-service`, `auth-service`. |
| E2E Tests      | Cypress         | `/rfm.v1/GetSegments`, `/api/rfm/visualizations`, `/api/rfm/export`.   |
| Load Tests     | k6              | 5,000 concurrent `GetSegments` calls, <1s latency (90%+).             |
| Chaos Testing  | Chaos Mesh      | Redis, PostgreSQL, Kafka crashes; service failures.                   |
| Compliance     | Jest            | No PII, audit log emission, GDPR/CCPA webhooks, CCPA purge.           |
| i18n Tests     | Jest            | Validate `email_templates`, `nudges` for `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja` (90%+ accuracy). |
| Penetration    | OWASP ZAP       | Test `/api/rfm/*`, `/rfm.v1/*` for XSS, SQL injection (ECL: 256).     |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `rfm-service:latest`.
  - Ports: 50053 (gRPC), 8081 (REST, `/health`, `/metrics`, `/ready`).
  - Dependencies: PostgreSQL (5432), Redis (6382), Kafka, TimescaleDB (5433).
  - Environment Variables: `RFM_DB_HOST`, `RFM_DB_PORT`, `RFM_DB_NAME`, `KAFKA_BROKER`, `XAI_API_KEY`, `AUTH_HOST`.
- **Resource Limits**: CPU: 0.5 cores, Memory: 512MiB per instance.
- **Scaling**: 2 instances for 5,000 concurrent requests, Kubernetes (Phase 6) with auto-scaling.
- **Orchestration**: Liveness (`/health`), readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Pact, Cypress, k6, OWASP ZAP, CLI (`reprocess_dlq.py`).

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| xAI API timeouts         | 3x exponential backoff retries, fallback to cached `rfm_score_history`.   |
| High query latency       | Range partitioning, materialized views, Redis Streams, Bull queues.       |
| Event duplication        | `event_id` in Redis/`processed_events`, `rfm.dlq` with 3 retries.         |
| Unauthorized access      | mTLS, JWT `jti` blacklisting, RBAC (`admin:analytics`).                   |
| Translation errors       | DeepL validation, Jest i18n tests (90%+ accuracy).                        |
| Black Friday surges      | Batch processing (1,000 customers/batch), Redis Streams, Bull queues.     |

## Action Items
- [ ] Define `RFMSegment.entity.ts`, `email_templates`, `nudges` schemas by August 12, 2025 (Owner: Dev Team).
- [ ] Set up PostgreSQL partitioning, materialized views, Redis Streams by August 15, 2025 (Owner: DB Team).
- [ ] Implement `/rfm.v1/GetChurnRisk`, `/rfm.v1/GetNudges`, Rust/Wasm function by August 20, 2025 (Owner: Dev Team).
- [ ] Configure Prometheus, Loki, Grafana, and AWS SNS alerts by August 25, 2025 (Owner: SRE Team).
- [ ] Test Kafka `rfm.updated`, `rfm.task`, `rfm.dlq`, `rfm.replay` by August 28, 2025 (Owner: Dev Team).
- [ ] Conduct k6 load tests (5,000 concurrent requests), chaos tests, i18n tests by September 5, 2025 (Owner: QA Team).
- [ ] Deploy to production, enable LaunchDarkly flags (`rfm_advanced`, `rfm_nudges`) by September 10, 2025 (Owner: SRE Team).
- [ ] Complete documentation (OpenAPI, gRPC proto, multilingual guides) by September 15, 2025 (Owner: Docs Team).

## Epics and Stories
| Epic                     | Stories                                    | Owner      | Due Date       |
|--------------------------|--------------------------------------------|------------|----------------|
| Database Setup           | Partition PostgreSQL, initialize Redis Streams | DB Team    | August 15, 2025 |
| Core Functionality       | Implement gRPC, REST, Rust/Wasm, Kafka events | Dev Team   | August 20, 2025 |
| Localization             | Set up `email_templates`, `nudges`, validate languages | Frontend Team | August 22, 2025 |
| Observability            | Configure Prometheus, Loki, Grafana panels | SRE Team   | August 25, 2025 |
| Testing & Validation     | Unit, E2E, load, chaos, i18n, penetration tests | QA Team    | September 5, 2025 |
| Deployment & Docs        | Deploy, document APIs, multilingual guides | SRE/Docs Team | September 15, 2025 |

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | August 8, 2025    |
| Schema & Database Setup       | August 15, 2025   |
| Endpoints & Rust/Wasm         | August 20, 2025   |
| Observability Setup           | August 25, 2025   |
| Testing & Validation          | September 5, 2025 |
| Deployment & Documentation    | September 15, 2025|

## Recommendations
### Architecture & Design
1. **RFM Calculations**:
   - Implement time-weighted recency (`program_settings.rfm_thresholds.recency_decay`) and multi-segment support (`customer_segments.segment_ids` JSONB array).
   - Cache scores in Redis Streams (`rfm:customer:{id}`, TTL: 24h).
2. **Event Idempotency**:
   - Use `event_id` for `rfm.updated`, `churn_risk.detected`, `rfm.task`, tracked in Redis/`processed_events`.
3. **Caching Strategy**:
   - Cache previews (`rfm:preview:{merchant_id}`, TTL: 1h), bursts (`rfm:burst:{merchant_id}`, TTL: 1h), invalidate via `cache.invalidate`.

### Security
4. **Authentication & Authorization**:
   - Enforce JWT `jti` blacklisting, mTLS, RBAC (`admin:analytics`, `admin:full`).
5. **Audit Defense**:
   - Log `rfm_export`, `tier_assigned` to `audit_logs` (90–180 day retention, Backblaze B2).
   - Implement `/rfm.v1/PurgeAuditLogs` for CCPA.

### Observability
6. **Traceability**:
   - Use `trace_id` (OpenTelemetry) for gRPC and Kafka.
7. **Dashboarding**:
   - Provide Grafana panel JSON for segment sizes, churn risk, nudge interactions.

### DevOps / Operability
8. **Runbooks & SLOs**:
   - Define runbooks for latency, event failures, Redis crashes.
   - Set SLOs: 90%+ queries <1s, <0.5% failure rate.
9. **Service Discovery**:
   - Register with Consul (`SERVICE_NAME=rfm`, `SERVICE_PORT=50053`).

### Platform Evolution
10. **Multilingual Support**:
    - Validate `email_templates`, `nudges` with DeepL, Jest i18n tests.
11. **Dependency Management**:
    - Mock `users-service`, `points-service`, `auth-service` in CI/CD.