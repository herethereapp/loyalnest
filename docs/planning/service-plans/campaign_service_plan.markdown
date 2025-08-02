# Campaign Service Plan

## Overview
- **Purpose**: Manages VIP tiers for loyalty campaigns, including tier definitions, rules, benefits, and customer assignments, with support for multilingual tier names and benefits.
- **Priority for TVP**: Low (Phase 4 focus).
- **Dependencies**: Core Service (customer creation events), AdminFeatures (tier updates), Auth Service (JWT validation), Points (bonus point triggers), Kafka (event transport), Consul (service discovery), Redis (caching, idempotency), Prometheus (metrics), Loki (logging).

## Database Setup
- **Database Type**: PostgreSQL (port: 5438), Redis (port: 6380).
- **Tables**: `vip_tiers`, `processed_events`.

### `vip_tiers` Schema
| Column              | Type       | Constraints                                                                 |
|---------------------|------------|-----------------------------------------------------------------------------|
| `id`                | UUID       | Primary Key                                                                 |
| `merchant_id`       | UUID       | Foreign Key → `merchants`, Indexed                                          |
| `tier_id`           | TEXT       | Unique per `merchant_id`                                                    |
| `name`              | TEXT       | Not null, localized (e.g., "Gold" for `en`, "ذهبي" for `ar`)                |
| `locale`            | TEXT       | CHECK IN ('en', 'ar', 'he', ...), DEFAULT 'en'                              |
| `min_points`        | INTEGER    | CHECK >= 0                                                                 |
| `discount_percentage`| INTEGER    | CHECK >= 0, DEFAULT 0, percentage discount for tier                         |
| `free_shipping`     | BOOLEAN    | DEFAULT false, indicates free shipping benefit                              |
| `exclusive_access`  | BOOLEAN    | DEFAULT false, indicates exclusive content access                           |
| `benefits`          | JSONB      | Optional, validated schema (e.g., `{"bonus_points": 100, "custom_perks": []}`) |
| `created_at`        | TIMESTAMP(3) | DEFAULT now()                                                             |
| `updated_at`        | TIMESTAMP(3) | Auto-updated via trigger                                                  |

### `processed_events` Schema
| Column        | Type       | Constraints                          |
|---------------|------------|--------------------------------------|
| `event_id`    | UUID       | Primary Key                          |
| `merchant_id` | UUID       | Foreign Key → `merchants`, Indexed   |
| `event_type`  | TEXT       | CHECK IN ('vip_tier.assigned', 'vip_tier.updated') |
| `created_at`  | TIMESTAMP(3) | DEFAULT now()                       |

### Constraints & Indexes
- **Unique Index**: `unique_vip_tiers_merchant_id_tier_id` (btree: `merchant_id`, `tier_id`).
- **Check**: `min_points >= 0`, `discount_percentage >= 0`.
- **Indexes**:
  - `idx_vip_tiers_merchant_id` (btree: `merchant_id`).
  - `idx_vip_tiers_min_points` (btree: `min_points`).
  - `idx_vip_tiers_benefits` (gin: `benefits` for JSONB queries).
  - `idx_processed_events_merchant_id` (btree: `merchant_id`).
- **Triggers**:
  - `trg_updated_at`: Updates `updated_at` on `vip_tiers` row changes.
  - `trg_validate_benefits`: Validates `benefits` JSONB against schema on insert/update.
- **Row-Level Security (RLS)**: Enabled on `vip_tiers` to restrict access by `merchant_id`.
- **Partitioning**: `vip_tiers` partitioned by `merchant_id` for scalability.

### Redis Keys
- `cache:{merchant_id}:{tier_id}`: Caches `GetVIPTier` results (TTL: 1h).
- `cache:{merchant_id}:tiers`: Caches `ListVIPTiers` results (TTL: 1h).
- `processed:{merchant_id}:{event_id}`: Tracks processed Kafka events for idempotency (TTL: 24h).
- **Eviction**: `volatile-lru` for caches, `noeviction` for processed events.

### GDPR/CCPA Compliance
- No PII stored in `vip_tiers` or `processed_events`.
- Tier assignment events reference `customer_id` only, with PII handled by Core Service.
- Audit logs emitted to AdminCore via Kafka, retained for 90 days in Backblaze B2.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by Campaign Service)
| Endpoint                      | Input                              | Output                        | Called By       | Purpose                           |
|-------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/campaign.v1/GetVIPTier`     | `merchant_id`, `tier_id`           | `id`, `name`, `locale`, `min_points`, `discount_percentage`, `free_shipping`, `exclusive_access`, `benefits` | Frontend        | Fetches specific tier config.     |
| `/campaign.v1/ListVIPTiers`   | `merchant_id`                      | List of VIP tiers             | Frontend        | Retrieves all tiers for a merchant. |
| `/campaign.v1/UpdateVIPTier`  | `merchant_id`, `tier_id`, `name`, `locale`, `min_points`, `discount_percentage`, `free_shipping`, `exclusive_access`, `benefits` | `success`                     | AdminFeatures   | Updates existing tier config.     |

- **Port**: 50058 (gRPC).
- **Authentication**: JWT via `/auth.v1/ValidateToken` (Auth Service).
- **Security**: mTLS for internal gRPC communication (Vault-managed certs).
- **Service Discovery**: Consul (`SERVICE_NAME=campaign-service`, `SERVICE_CHECK_HTTP=/health`).

### Asynchronous Communication
#### Events Produced (Kafka)
| Event                 | Payload                                            | Consumed By | Description                       |
|-----------------------|----------------------------------------------------|-------------|-----------------------------------|
| `vip_tier.assigned`   | `{ event_id, customer_id, merchant_id, tier_id, assigned_at }` | Points      | Triggers bonus points or perks.   |
| `vip_tier.updated`    | `{ event_id, merchant_id, tier_id, updated_fields, updated_at }` | AdminCore   | Audit logging and feedback.       |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `customer.created`    | Core Service   | `{ customer_id, merchant_id, ... }`  | Assigns default tier if applicable. |

- **Schema**: Avro, registered in Confluent Schema Registry.
- **Idempotency**: `event_id` in events, tracked in `processed:{merchant_id}:{event_id}` (Redis) or `processed_events` table.
- **Saga Patterns**:
  - Core Service → `customer.created` → Campaign → `vip_tier.assigned` → Points.
  - AdminFeatures → `UpdateVIPTier` → Campaign → `vip_tier.updated` → AdminCore.
- **Correlation IDs**: Included in gRPC requests and Kafka events for tracing.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| Core Service   | Emits `customer.created` event for default tier assignment.              |
| AdminFeatures  | Calls `/campaign.v1/UpdateVIPTier` for tier updates.                     |
| Points         | Subscribes to `vip_tier.assigned` for bonus point triggers.              |
| Auth           | Validates JWT for gRPC endpoints (`/auth.v1/ValidateToken`).             |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Kafka         | Event transport (Avro schema registry).                                  |
| PostgreSQL    | Primary data store for `vip_tiers`, `processed_events`.                  |
| Redis         | Caching for gRPC responses, idempotency for events.                      |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| Backblaze B2  | Audit log retention (via AdminCore).                                     |

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| gRPC     | `/campaign.v1/GetVIPTier`     | Get config for a specific tier.   |
| gRPC     | `/campaign.v1/ListVIPTiers`   | List all tiers for a merchant.    |
| gRPC     | `/campaign.v1/UpdateVIPTier`  | Update tier configuration.        |
| HTTP     | `/health`                     | Liveness check.                   |
| HTTP     | `/ready`                      | Readiness check.                  |
| HTTP     | `/metrics`                    | Prometheus metrics export.        |
| Kafka    | `vip_tier.assigned`, `vip_tier.updated` | Publish tier changes.            |

- **Access Patterns**: Low write (tier updates), moderate read (5,000 lookups/hour).
- **Rate Limits**: 100 req/s for gRPC endpoints, tracked in Redis (`rate_limit:{merchant_id}:campaign`, TTL: 60s).

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `vip_tiers_total` (by `merchant_id`).
  - `vip_tier_lookup_latency_seconds`.
  - `vip_tier_assignment_events_total`.
  - `vip_tier_assignment_failures_total` (by `event_type`).
  - `vip_tier_lookup_errors_by_type`.
- **Logging**: Structured JSON via Loki, tagged with `merchant_id`, `tier_id`, `event_type`, `correlation_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Lookup latency > 500ms.
  - Event failures > 5/hour.
  - Missing tier responses > 5% of requests.
- **Dashboards**: Grafana for:
  - Tier lookups per minute.
  - Assignment failure types.
  - Lookup latency trends.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `createVIPTier`, `getVIPTier`, `updateVIPTier`, schema validation.   |
| Integration    | Testcontainers  | PostgreSQL, Redis, Kafka, Core Service, Points interactions.          |
| E2E Tests      | Cypress         | gRPC endpoints (`GetVIPTier`, `ListVIPTiers`, `UpdateVIPTier`).      |
| Load Tests     | k6              | 10,000 lookups/hour, <200ms latency.                                 |
| Chaos Testing  | Chaos Mesh      | Kafka, PostgreSQL, Redis crashes; service failures.                   |
| Compliance     | Jest            | Verify no PII, audit log emission, GDPR compliance.                   |
| i18n Tests     | Jest            | Validate `name`, `benefits` for `en`, `ar`, `he` (90%+ accuracy).     |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `campaign-service:latest`.
  - Ports: `50058` (gRPC), `8080` (HTTP for `/health`, `/metrics`, `/ready`).
  - Environment Variables: `CAMPAIGN_DB_HOST`, `KAFKA_BROKER`, `REDIS_HOST`, `AUTH_HOST`.
- **Resource Limits**:
  - CPU: 0.25 cores per instance.
  - Memory: 256MiB per instance.
- **Scaling**: 2 instances for 10,000 lookups/hour.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, and OWASP ZAP for security scans.

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| Misconfigured tiers      | JSON schema validation for `benefits`, typed fields for key attributes.    |
| Data drift in benefits   | Replace `config` with typed columns, enforce `trg_validate_benefits`.      |
| Tier event duplication   | Use `event_id` in Kafka events, track in `processed_events` or Redis.      |
| High lookup latency      | Cache responses in Redis, monitor `vip_tier_lookup_latency_seconds`.       |
| Translation errors       | Validate `locale` with DeepL and native speakers for `en`, `ar`, `he`.     |

## Action Items
- [ ] Deploy `campaign_db` (PostgreSQL) and Redis by **August 5, 2025** (Owner: DB Team).
- [ ] Implement gRPC `/GetVIPTier`, `/ListVIPTiers`, `/UpdateVIPTier` by **August 10, 2025** (Owner: Dev Team).
- [ ] Emit `vip_tier.assigned`, `vip_tier.updated` Kafka events by **August 10, 2025** (Owner: Dev Team).
- [ ] Configure Prometheus `/metrics` and Loki logs by **August 12, 2025** (Owner: SRE Team).
- [ ] Conduct k6 load tests (10,000 lookups/hour) and chaos tests by **August 14, 2025** (Owner: QA Team).
- [ ] Validate translations for `en`, `ar`, `he` by **August 14, 2025** (Owner: Frontend Team).

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | July 25, 2025     |
| Database and Redis Deployment | August 5, 2025    |
| Core Functionality (gRPC, Kafka) Complete | August 10, 2025 |
| Observability Setup (Prometheus, Loki) | August 12, 2025   |
| Testing (Load, Chaos, i18n)   | August 14, 2025   |
| Completion                    | August 14, 2025   |

## Recommendations
### Architecture & Design
1. **Typed Fields**:
   - Use `discount_percentage`, `free_shipping`, `exclusive_access` instead of `config` to prevent data drift.
   - Validate `benefits` with a JSON schema (e.g., `{"bonus_points": int, "custom_perks": array}`).

2. **Event Idempotency**:
   - Include `event_id` in `vip_tier.assigned` and `vip_tier.updated` for idempotency.
   - Track processed events in Redis or `processed_events` table.

### Security
3. **gRPC Authentication**:
   - Enforce JWT validation via `/auth.v1/ValidateToken` for all gRPC endpoints.
   - Use mTLS for internal gRPC communication (Vault-managed certs).

4. **Audit Defense**:
   - Emit all tier lifecycle events (`assigned`, `updated`) to an `audit_log` Kafka topic via AdminCore.

### Observability
5. **Correlation IDs**:
   - Include `correlation_id` in gRPC requests and Kafka events for end-to-end tracing.

6. **Dashboarding**:
   - Deploy Grafana dashboards for tier lookups per minute, assignment failure types, and lookup latency trends.

### DevOps / Operability
7. **Runbooks & SLOs**:
   - Define runbooks for high lookup latency, Kafka outages, and event failures.
   - Set SLOs: 99% of lookups <200ms, <0.5% event failure rate.

8. **Queue Abstraction**:
   - Abstract event handling to support future migration to AWS SQS or RabbitMQ without contract changes.

### Platform Evolution
9. **Multi-tenant Isolation**:
   - Enable RLS on `vip_tiers` for merchant isolation.
   - Validate partitioning performance with pgbench.

10. **Translation Validation**:
    - Use DeepL for initial translations of `name` and `benefits`, validated by native speakers for `en`, `ar`, `he`.
    - Automate i18n tests with Jest to verify `locale`.