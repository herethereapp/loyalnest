# Frontend Service Plan (Updated)

## Overview
- **Purpose**: Provides UI for merchants (dashboards for Points, Referrals, RFM Analytics, VIP tiers, task status) and customers (Points, Referrals, tier status), with multilingual support.
- **Priority for TVP**: Medium (displays Points, Referrals, RFM data, VIP tiers, task status).
- **Dependencies**: API Gateway (routing), Core Service (customer data), Points (balance), Referrals (status), RFM Analytics (segments), Event Tracking (task status), Campaign (VIP tiers), Auth (JWT validation), Kafka (event streaming), Consul (service discovery), Redis (caching), Prometheus (metrics), Loki (logging).

## Database Setup
- **Database Type**: None (queries via API Gateway).
- **Tables/Collections**: N/A.
- **Redis Keys**:
  - `cache:{merchant_id}:points:{customer_id}`: Caches `/points.v1/GetPointsBalance` responses (TTL: 1h).
  - `cache:{merchant_id}:referrals:{referral_id}`: Caches `/referrals.v1/GetReferralStatus` responses (TTL: 1h).
  - `cache:{merchant_id}:rfm:{customer_id}`: Caches `/core.v1/GetCustomerRFM` responses (TTL: 1h).
  - `cache:{merchant_id}:rfm_segments`: Caches `/rfm.v1/GetSegmentCounts` responses (TTL: 1h).
  - `cache:{merchant_id}:tiers`: Caches `/campaign.v1/ListVIPTiers` responses (TTL: 1h).
  - `cache:{merchant_id}:task:{task_id}`: Caches `/event_tracking.v1/GetTaskStatus` responses (TTL: 1h).
  - **Eviction**: `volatile-lru` for caches.
- **GDPR/CCPA Compliance**: No PII storage; PII (e.g., `email`, `name`) fetched via Core Service and sanitized by API Gateway.

## Inter-Service Communication
### Synchronous Communication
#### gRPC Calls (Made by Frontend)
| Endpoint                              | Input                              | Output                        | Service         | Purpose                           |
|---------------------------------------|------------------------------------|-------------------------------|-----------------|-----------------------------------|
| `/points.v1/GetPointsBalance`         | `merchant_id`, `customer_id`, `locale` | `balance`                     | Points          | Fetches customer points balance.  |
| `/referrals.v1/GetReferralStatus`     | `merchant_id`, `referral_id`, `locale` | `status`, `referred_count`    | Referrals       | Fetches referral status.          |
| `/core.v1/GetCustomerRFM`             | `merchant_id`, `customer_id`, `locale` | `recency`, `frequency`, `monetary` | Core Service | Fetches RFM data for customer.    |
| `/rfm.v1/GetSegmentCounts`            | `merchant_id`, `locale`            | `segment_counts`              | RFM Analytics   | Fetches RFM segment analytics.    |
| `/event_tracking.v1/GetTaskStatus`    | `merchant_id`, `task_id`, `locale` | `status`, `retry_count`, `error_log` | Event Tracking | Fetches task status (e.g., email send). |
| `/campaign.v1/ListVIPTiers`           | `merchant_id`, `locale`            | List of VIP tiers             | Campaign        | Fetches VIP tiers for display.    |

- **Port**: Varies by service (e.g., 50057 for Event Tracking, 50058 for Campaign).
- **Authentication**: JWT via `/auth.v1/ValidateToken` (Auth Service) for all gRPC calls.
- **Authorization**: RBAC (`merchant:dashboard:view`, `customer:points:view`) enforced by API Gateway.
- **Security**: mTLS for internal gRPC communication (Vault-managed certs).
- **Service Discovery**: Consul (`SERVICE_NAME=frontend`, `SERVICE_CHECK_HTTP=/health`).

#### REST Endpoints (Exposed by Frontend)
| Endpoint               | Method | Purpose                           |
|------------------------|--------|-----------------------------------|
| `/frontend/points`     | GET    | Displays customer points balance. |
| `/frontend/referrals`  | GET    | Displays referral status.         |
| `/frontend/rfm`        | GET    | Displays RFM data and segments.   |
| `/frontend/tiers`      | GET    | Displays VIP tiers.               |
| `/frontend/task-status`| GET    | Displays task status (e.g., email send). |

- **Proxied**: Via API Gateway.
- **Rate Limits**: 40 req/s (Shopify API Plus limit), tracked in Redis (`rate_limit:{merchant_id}:frontend`, TTL: 60s).

### Asynchronous Communication
#### Events Consumed (Kafka)
| Event                 | Source         | Payload                              | Action                              |
|-----------------------|----------------|--------------------------------------|-------------------------------------|
| `task.created`        | Event Tracking | `{ task_id, merchant_id, task_type, created_at }` | Updates task status via WebSocket. |
| `task.completed`      | Event Tracking | `{ task_id, merchant_id, completed_at }` | Updates task status via WebSocket. |
| `task.failed`         | Event Tracking | `{ task_id, merchant_id, retry_count, error_log }` | Updates task status via WebSocket. |
| `vip_tier.assigned`   | Campaign       | `{ event_id, customer_id, merchant_id, tier_id, assigned_at }` | Updates tier display via WebSocket. |

- **WebSocket**: `/frontend/stream` for real-time updates (task status, tier assignments).
- **Schema**: Avro, registered in Confluent Schema Registry.
- **Correlation IDs**: Included in Kafka events and WebSocket messages for tracing.

#### Events Produced
- None.

## Dependencies
### Internal Services
| Service        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| API Gateway    | Proxies REST and gRPC requests, enforces rate limits and RBAC.           |
| Core Service   | Provides customer data and RFM via `/core.v1/GetCustomerRFM`.            |
| Points         | Provides points balance via `/points.v1/GetPointsBalance`.               |
| Referrals      | Provides referral status via `/referrals.v1/GetReferralStatus`.          |
| RFM Analytics  | Provides segment analytics via `/rfm.v1/GetSegmentCounts`.               |
| Event Tracking | Provides task status via `/event_tracking.v1/GetTaskStatus`.             |
| Campaign       | Provides VIP tiers via `/campaign.v1/ListVIPTiers`.                      |
| Auth           | Validates JWT for gRPC and REST endpoints (`/auth.v1/ValidateToken`).    |

### External Systems
| System        | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| Kafka         | Event transport for real-time updates (Avro schema registry).             |
| Redis         | Caching for gRPC responses, rate-limiting for REST endpoints.             |
| Consul        | Service discovery for gRPC endpoints.                                    |
| Prometheus    | Metrics scraping via `/metrics`.                                         |
| Loki          | Log aggregation with structured JSON.                                    |
| CDN           | Serves static assets (e.g., CSS, JS, images).                             |

## Key Endpoints
| Protocol | Endpoint                      | Purpose                           |
|----------|-------------------------------|-----------------------------------|
| REST     | `/frontend/points`            | Displays customer points balance. |
| REST     | `/frontend/referrals`         | Displays referral status.         |
| REST     | `/frontend/rfm`               | Displays RFM data and segments.   |
| REST     | `/frontend/tiers`             | Displays VIP tiers.               |
| REST     | `/frontend/task-status`       | Displays task status.             |
| WebSocket| `/frontend/stream`            | Streams task and tier updates.    |
| HTTP     | `/health`                     | Liveness check.                   |
| HTTP     | `/ready`                      | Readiness check.                  |
| HTTP     | `/metrics`                    | Prometheus metrics export.        |

- **Access Patterns**: High read (5,000 merchant views/hour), low write.
- **Rate Limits**: 40 req/s (Shopify API Plus limit), tracked in Redis (`rate_limit:{merchant_id}:frontend`, TTL: 60s).

## Monitoring & Observability
- **Metrics** (via Prometheus):
  - `frontend_request_latency_seconds` (by `endpoint`, `locale`).
  - `frontend_requests_total` (by `endpoint`, `locale`).
  - `frontend_errors_total` (by `endpoint`, `error_type`).
  - `frontend_websocket_connections_total`.
- **Logging**: Structured JSON via Loki, tagged with `merchant_id`, `endpoint`, `locale`, `correlation_id`.
- **Alerting**: Prometheus Alertmanager + AWS SNS for:
  - Request latency > 500ms.
  - Error rates > 5%.
  - WebSocket connection drops > 10/hour.
- **Dashboards**: Grafana for:
  - Requests per minute by endpoint.
  - Error types and rates.
  - Latency trends by endpoint and locale.

## Testing Strategy
| Type           | Tool            | Scope                                                                 |
|----------------|-----------------|----------------------------------------------------------------------|
| Unit Tests     | Jest            | UI components, localization logic, WebSocket handling.                |
| Integration    | Testcontainers  | gRPC calls to Points, Referrals, RFM, Event Tracking, Campaign; Kafka event consumption. |
| E2E Tests      | Cypress         | Dashboard flows (points, referrals, RFM, tiers, task status).         |
| Load Tests     | k6              | 10,000 views/hour, <200ms latency for REST/gRPC responses.            |
| Chaos Testing  | Chaos Mesh      | API Gateway, Kafka, Redis crashes; service failures.                  |
| Compliance     | Jest            | Verify no PII exposure in UI responses.                               |
| i18n Tests     | Jest            | Validate UI translations for `en`, `ar`, `he` (90%+ accuracy).        |
| Observability  | Prometheus      | Verify metrics correctness via query simulation.                     |

## Deployment
- **Docker Compose**:
  - Image: `frontend-service:latest` (Node.js for SSR).
  - Ports: `3000` (HTTP for REST, WebSocket, `/health`, `/metrics`, `/ready`).
  - Environment Variables: `API_GATEWAY_URL`, `AUTH_HOST`, `REDIS_HOST`, `KAFKA_BROKER`.
- **Resource Limits**:
  - CPU: 0.5 cores per instance.
  - Memory: 512MiB per instance.
- **Scaling**: 2 instances for 10,000 views/hour, CDN for static assets.
- **Orchestration**: Kubernetes (Phase 6) with liveness (`/health`) and readiness (`/ready`) probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, and OWASP ZAP for security scans.

## Risks and Mitigations
| Risk                     | Mitigation                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| UI latency               | Cache gRPC responses in Redis, use CDN for static assets, monitor latency. |
| Security vulnerabilities  | Enforce JWT and RBAC, scan with OWASP ZAP, use mTLS for gRPC.             |
| Translation errors       | Validate `locale` with DeepL and native speakers for `en`, `ar`, `he`.     |
| Event loss (WebSocket)   | Buffer Kafka events in Redis, retry WebSocket connections.                 |
| Dependency delays        | Mock Points, Referrals, RFM, Event Tracking, Campaign for testing.         |

## Action Items
- [ ] Deploy `frontend-service` with Redis by **August 5, 2025** (Owner: Dev Team).
- [ ] Implement gRPC calls and REST endpoints by **August 10, 2025** (Owner: Dev Team).
- [ ] Set up WebSocket `/frontend/stream` for task and tier updates by **August 10, 2025** (Owner: Dev Team).
- [ ] Configure Prometheus `/metrics` and Loki logs by **August 12, 2025** (Owner: SRE Team).
- [ ] Conduct k6 load tests (10,000 views/hour) and chaos tests by **August 15, 2025** (Owner: QA Team).
- [ ] Validate UI translations for `en`, `ar`, `he` by **August 15, 2025** (Owner: Frontend Team).

## Timeline
| Milestone                     | Date              |
|-------------------------------|-------------------|
| Start                         | July 25, 2025     |
| Deployment and Redis Setup    | August 5, 2025    |
| Core Functionality (gRPC, REST, WebSocket) Complete | August 10, 2025 |
| Observability Setup (Prometheus, Loki) | August 12, 2025   |
| Testing (Load, Chaos, i18n)   | August 15, 2025   |
| Completion                    | August 15, 2025   |

## Recommendations

1. **Real-Time Updates**:
   - Use WebSocket (`/frontend/stream`) to stream `task.created`, `task.completed`, `task.failed`, and `vip_tier.assigned` events.
   - Buffer events in Redis during WebSocket downtime.

2. **Caching Strategy**:
   - Cache gRPC responses in Redis to reduce API Gateway load.
   - Invalidate caches on `vip_tier.updated` or Points/Referrals updates.

3. **Authentication & Authorization**:
   - Enforce JWT validation via `/auth.v1/ValidateToken` for all gRPC and REST endpoints.
   - Implement RBAC (`merchant:dashboard:view`, `customer:points:view`) via API Gateway.

4. **Audit Defense**:
   - Log all UI requests to Loki with `correlation_id` for tracing to backend services.

5. **Correlation IDs**:
   - Include `correlation_id` in gRPC, REST, and WebSocket interactions for end-to-end tracing.

6. **Dashboarding**:
   - Deploy Grafana dashboards for request latency, error rates, and WebSocket connection trends.

7. **Runbooks & SLOs**:
   - Define runbooks for high latency, WebSocket drops, and dependency outages.
   - Set SLOs: 99% of requests <200ms, <0.5% error rate.

8. **Service Discovery**:
   - Register with Consul (`SERVICE_NAME=frontend`, `SERVICE_PORT=3000`, `SERVICE_CHECK_HTTP=/health`).

9. **Multilingual UI**:
   - Support `locale` in gRPC/REST requests, validate translations with DeepL and native speakers.
   - Automate i18n tests with Jest for `en`, `ar`, `he`.

10. **Dependency Management**:
    - Mock dependencies (Points, Referrals, RFM, Event Tracking, Campaign) in CI/CD to avoid delays.

11. **Cache Invalidation**: 
    - You mentioned invalidation on vip_tier.updated or Points/Referrals updates — ensure these events are reliably published and consumed, and consider edge cases for eventual consistency.

12. **WebSocket Buffering**: 
    - Buffering Kafka events in Redis during WebSocket downtime is great — consider maximum buffer sizes and eviction to avoid memory blowup.

13. **Localization Testing**: 
    - For Arabic and Hebrew, ensure UI handles RTL (right-to-left) layout adjustments as well as translation text accuracy.

14. **API Gateway Rate Limits**: 
    - 40 req/s per merchant is good, but monitor closely for peak traffic spikes, especially during campaigns.

15. **Security Audits**: 
    - Incorporating OWASP ZAP scans is excellent — periodic penetration testing beyond automated scans is recommended as you scale.

16. **SLO Definitions**: 
    - Consider formalizing SLOs and SLA reporting dashboards for transparency to stakeholders.