# Event Tracking Service Plan

## Overview
- **Purpose**: Manages asynchronous task queue operations, including email sends, SMS sends, reminders, reward triggers, and custom tasks, supporting AdminFeatures and other campaign/event-based workloads.
- **Priority for TVP**: Medium (supports AdminFeatures, scales to support Campaign, Rewards, and other event-driven workloads).
- **Dependencies**: AdminFeatures (email and campaign events), AdminCore (audit logs), Kafka (event streaming), Consul (service discovery), Redis (deduplication and rate-limiting), Auth (JWT validation).

## Database Setup
- **Database Type**: PostgreSQL (port: 5439), Redis (port: 6380).
- **Tables**: `queue_tasks`.

### `queue_tasks` Schema
| Column          | Type          | Constraints                                                                 |
|-----------------|---------------|-----------------------------------------------------------------------------|
| `id`            | UUID          | Primary Key                                                                 |
| `merchant_id`   | UUID          | Foreign Key → `merchants`, Indexed                                          |
| `task_type`     | TEXT          | CHECK IN ('email_send', 'sms_send', 'reminder', 'reward_trigger', 'custom') |
| `status`        | TEXT          | CHECK IN ('pending', 'processing', 'completed', 'failed', 'cancelled')      |
| `payload`       | JSONB         | Required, e.g., `{"template_id": "welcome_email", "to": "customer_id", "locale": "en"}` |
| `retry_count`   | INTEGER       | DEFAULT 0, CHECK >= 0                                                      |
| `max_retries`   | INTEGER       | DEFAULT 5, CHECK >= 0                                                      |
| `next_retry_at` | TIMESTAMP(3)  | Nullable, for scheduled retries                                             |
| `error_log`     | JSONB         | Nullable, e.g., `{"attempt": 1, "error": "SMTP timeout"}`                  |
| `created_at`    | TIMESTAMP(3)  | DEFAULT now()                                                              |
| `updated_at`    | TIMESTAMP(3)  | Auto-updated via trigger                                                   |
| `locale`        | TEXT          | CHECK IN ('en', 'ar', 'he', ...), DEFAULT 'en'                             |

### Indexes
- `idx_queue_tasks_merchant_id_status` (btree: `merchant_id`, `status`).
- `idx_queue_tasks_created_at` (btree: `created_at`).
- `idx_queue_tasks_payload` (gin: `payload` for JSONB queries).

### Triggers
- `trg_updated_at`: Updates `updated_at` timestamp on row changes.
- `trg_sanitize_payload`: Removes PII (e.g., `email`, `phone`) from `payload` before insert/update.
- `trg_retry_limit`: Prevents retries if `retry_count` >= `max_retries` (sets `status` to 'failed').

### Redis Keys
- `dedupe:{merchant_id}:{task_hash}`: Deduplicates tasks (TTL: 24h).
- `rate_limit:{merchant_id}:{task_type}`: Limits task submission rate (TTL: 60s, max 50 tasks/s).
- Eviction: `volatile-lru` for deduplication, `noeviction` for rate-limiting.

### GDPR/CCPA Compliance
- PII sanitized in `payload` via `trg_sanitize_payload` (removes `email`, `phone`).
- Audit logs emitted to AdminCore via Kafka.
- 90-day retention for audit logs in Backblaze B2 (via AdminCore).

### Schema Details
- Partitioning: `queue_tasks` partitioned by `merchant_id` for scalability.
- Encryption: `payload` encrypted with AES-256 via `pgcrypto` if PII detected post-sanitization.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Endpoints (Exposed by Event Tracking)
| Endpoint                              | Input                                      | Output                        | Called By       | Purpose                           |
|---------------------------------------|--------------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/event_tracking.v1/CreateTask`       | `merchant_id`, `task_type`, `payload`, `locale` | `task_id`                     | AdminFeatures   | Queues a new asynchronous task.   |
| `/event_tracking.v1/CancelTask`       | `merchant_id`, `task_id`                   | `success`                     | AdminFeatures   | Cancels a pending task.           |
| `/event_tracking.v1/GetTaskStatus`    | `merchant_id`, `task_id`                   | `status`, `retry_count`, `error_log` | AdminFeatures   | Polls task status.                |

- **Port**: 50057 (gRPC).
- **Authentication**: JWT via `/auth.v1/ValidateToken` (Auth service).
- **Security**: mTLS for internal gRPC communication (shared certs via Vault).
- **Service Discovery**: Consul (`SERVICE_NAME=event-tracking`, `SERVICE_CHECK_HTTP=/health`).

### Asynchronous Communication
#### Events Produced (Kafka)
| Event             | Payload                                            | Consumed By | Description                       |
|-------------------|----------------------------------------------------|-------------|-----------------------------------|
| `task.created`    | `{ task_id, merchant_id, task_type, created_at }`  | AdminCore   | Signals new task enqueued.        |
| `task.completed`  | `{ task_id, merchant_id, completed_at }`           | AdminCore   | Indicates successful completion.  |
| `task.failed`     | `{ task_id, merchant_id, retry_count, error_log }` | AdminCore   | Logged when task fails after retries. |

#### Events Consumed (Kafka)
| Event                 | Source         | Payload                                          | Triggers                     |
|-----------------------|----------------|--------------------------------------------------|------------------------------|
| `email_event.created` | AdminFeatures  | `{ merchant_id, email_template_id, to, subject, context, locale }` | Creates `email_send` task.   |
| `reward.earned`       | Campaign       | `{ merchant_id, customer_id, reward_id, locale }` | Creates `reward_trigger` task. |

- **Schema**: Avro, registered in Confluent Schema Registry.
- **Saga Patterns**:
  - AdminFeatures → `email_event.created` → Event Tracking → `task.created` → AdminCore.
  - Campaign → `reward.earned` → Event Tracking → `task.created` → AdminCore.
- **Correlation IDs**: Included in all Kafka messages and gRPC calls for tracing.

## Service Discovery
- **Tool**: Consul (via `registrator`).
- **Configuration**:
  - `SERVICE_NAME=event-tracking`.
  - `SERVICE_PORT=50057` (gRPC), `8080` (HTTP for `/health`, `/metrics`, `/ready`).
  - `SERVICE_CHECK_HTTP=/health` (checked every 10s, timeout: 2s).
  - `SERVICE_TAGS=event,task,queue`.
- **Validation**: `curl http://consul:8500/v1/catalog/service/event-tracking`.

## Key Endpoints
| Protocol | Endpoint                              | Purpose                           |
|----------|---------------------------------------|-----------------------------------|
| gRPC     | `/event_tracking.v1/CreateTask`       | Enqueue new task.                 |
| gRPC     | `/event_tracking.v1/CancelTask`       | Cancel pending task.              |
| gRPC     | `/event_tracking.v1/GetTaskStatus`    | Retrieve task status.             |
| HTTP     | `/health`                             | Liveness check.                   |
| HTTP     | `/ready`                              | Readiness check.                  |
| HTTP     | `/metrics`                            | Prometheus metrics export.        |
| Kafka    | `task.created`, `task.completed`, `task.failed` | Track task lifecycle. |

- **Access Patterns**: High write (10,000 tasks/hour), moderate read (status checks).
- **Rate Limits**: 50 tasks/s per `task_type` per `merchant_id`, tracked in Redis (`rate_limit:{merchant_id}:{task_type}`).

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `event_tracking_tasks_created_total` (by `task_type`).
  - `event_tracking_tasks_completed_total`.
  - `event_tracking_tasks_failed_total` (by `task_type`).
  - `event_tracking_task_queue_depth`.
  - `event_tracking_task_processing_duration_seconds`.
  - `event_tracking_retry_count_histogram`.
- **Logging**: Structured JSON logs via Loki, tagged with `merchant_id`, `task_type`, `task_id`, `status`, `correlation_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Queue depth > 5,000 tasks.
  - Task failures > 10/hour.
  - Retry spikes > 10/hour.
- **Dashboards**: Grafana for:
  - Tasks queued per minute (by `task_type`).
  - Top failure types.
  - Average latency from queue to completion.
  - Retry count heatmaps.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| AdminFeatures  | Publishes `email_event.created`, `reward.earned`; calls gRPC endpoints.  |
| AdminCore      | Subscribes to `task.created`, `task.completed`, `task.failed` for audit logging. |
| Auth           | Validates JWT for gRPC endpoints (`/auth.v1/ValidateToken`).             |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Kafka         | Event transport (Avro schema registry).                                  |
| PostgreSQL    | Primary data store for `queue_tasks`.                                    |
| Redis         | Deduplication and rate-limiting.                                         |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| Backblaze B2  | Audit log retention (via AdminCore).                                     |

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | `createTask`, `cancelTask`, `getTaskStatus`, DB, Kafka, sanitization logic. |
| Integration    | Testcontainers  | PostgreSQL, Redis, Kafka, AdminFeatures, AdminCore interactions.      |
| E2E Tests      | Cypress         | gRPC endpoints (`CreateTask`, `CancelTask`, `GetTaskStatus`).         |
| Load Tests     | k6              | 15,000 tasks/hour, <200ms latency for status checks.                  |
| Chaos Testing  | Chaos Mesh      | Kafka, PostgreSQL, Redis crashes; worker failures.                    |
| Compliance     | Jest            | Verify PII sanitization, audit log emission, GDPR compliance.         |
| i18n Tests     | Jest            | Validate `payload.locale` for `en`, `ar`, `he` (90%+ accuracy).       |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `event-tracking:latest`.
  - Ports: `50057` (gRPC), `8080` (HTTP for `/health`, `/metrics`, `/ready`).
  - Environment Variables: `EVENT_TRACKING_DB_HOST`, `KAFKA_BROKER`, `REDIS_HOST`, `AUTH_HOST`.
- **Resource Limits**:
  - CPU: 0.25 cores per worker.
  - Memory: 256MiB per worker.
- **Scaling**: 3 workers per replica, 2 replicas for 15,000 tasks/hour.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, and OWASP ZAP for security scans.

## Risks and Mitigations
| Risk                  | Mitigation                                                                 |
|-----------------------|---------------------------------------------------------------------------|
| Task backlog buildup  | Monitor `event_tracking_task_queue_depth`, scale workers, alert at >5,000 tasks. |
| Retry storm           | Exponential backoff with jitter (1s, 2s, 4s), cap at `max_retries=5`.     |
| Faulty input payloads | Validate `payload` schema on enqueue; sanitize PII via `trg_sanitize_payload`. |
| Kafka unavailability  | Buffer tasks in PostgreSQL, re-publish on recovery.                       |
| Translation errors    | Validate `locale` with DeepL and native speakers for `en`, `ar`, `he`.     |

## Action Items
- [ ] Deploy `event_tracking_db` (PostgreSQL) and Redis by **August 5, 2025** (Owner: DB Team).
- [ ] Implement gRPC `/CreateTask`, `/CancelTask`, `/GetTaskStatus` by **August 10, 2025** (Owner: Dev Team).
- [ ] Emit `task.created`, `task.completed`, `task.failed` Kafka events by **August 10, 2025** (Owner: Dev Team).
- [ ] Configure Prometheus `/metrics` and Loki logs by **August 12, 2025** (Owner: SRE Team).
- [ ] Conduct k6 load tests (15,000 tasks/hour) and chaos tests by **August 15, 2025** (Owner: QA Team).
- [ ] Validate translations for `en`, `ar`, `he` by **August 15, 2025** (Owner: Frontend Team).

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | July 25, 2025     |
| Database and Redis Deployment | August 5, 2025    |
| Core Functionality (gRPC, Kafka) Complete | August 10, 2025 |
| Observability Setup (Prometheus, Loki) | August 12, 2025   |
| Testing (Load, Chaos, i18n)   | August 15, 2025   |
| Completion                    | August 15, 2025   |

## Recommendations
### Architecture & Design
1. **Task Retry Strategy**:
   - Use exponential backoff with jitter (1s, 2s, 4s) for retries.
   - Store failed tasks in a dead-letter queue (PostgreSQL table or Kafka topic) after `max_retries`.
   - Use `next_retry_at` for scheduled retries via cron/worker.

2. **Task Scheduling Support**:
   - Support delayed tasks via `next_retry_at` or a `scheduled_at` column.
   - Allow AdminFeatures to enqueue future-dated tasks (e.g., for campaigns).

### Security
3. **gRPC Authentication**:
   - Enforce JWT validation via `/auth.v1/ValidateToken` for all gRPC endpoints.
   - Use mTLS for internal gRPC communication (Vault-managed certs).

4. **Audit Defense**:
   - Emit all task lifecycle events (`created`, `completed`, `failed`, `cancelled`) to an `audit_log` Kafka topic via AdminCore.

### Observability
5. **Correlation IDs**:
   - Include `correlation_id` in gRPC requests and Kafka events for end-to-end tracing.

6. **Dashboarding**:
   - Deploy Grafana dashboards for tasks queued per minute, failure types, latency, and retry count heatmaps.

### DevOps / Operability
7. **Runbooks & SLOs**:
   - Define runbooks for retry spikes, Kafka outages, and stuck tasks.
   - Set SLOs: 99% of tasks processed <3s, <0.5% failure rate.

8. **Queue Abstraction**:
   - Abstract queue logic to support future migration to Redis Streams, AWS SQS, or RabbitMQ without contract changes.

### Platform Evolution
9. **Multi-tenant Isolation**:
   - Enable row-level security (RLS) on `queue_tasks` for merchant isolation.
   - Validate partitioning performance with pgbench.

10. **Translation Validation**:
    - Use DeepL for initial translations, validated by native speakers for `en`, `ar`, `he`.
    - Automate i18n tests with Jest to verify `locale` in `payload`.