# API Gateway Service Plan

## Overview
- **Purpose**: Acts as the entry point for routing Shopify webhooks, gRPC, REST, and GraphQL requests to internal services (Points, Referrals, Core, AdminCore, AdminFeatures). Validates tokens, enforces rate limits, and supports debugging via AdminCore logs. Handles Shopify Plus scale (10,000 orders/hour, 50,000+ customers) with RBAC, multilingual support, and GDPR/CCPA compliance.
- **Priority for TVP**: Medium (enables Points, Referrals, AdminCore, AdminFeatures).
- **Dependencies**: Auth (token validation), Redis (rate limiting, caching), Kafka (event production), AdminCore (webhook debugging), AdminFeatures (rate limit monitoring), Frontend (real-time debugging).

## Database Setup
- **Database Type**: Redis (clustered)
- **Port**: 6380
- **Keys**:
  - `rate_limit:{merchant_id}:{endpoint}`: Tracks API calls (TTL: 60s).
  - `webhook_cache:{merchant_id}:{webhook_id}`: Deduplicates webhooks (TTL: 300s).
  - `ip_whitelist:{merchant_id}`: Stores allowed IPs (TTL: 7d).
- **Schema Details**:
  - Rate limits: `INCR` for count, `EXPIRE` for TTL, max 40 req/s for Shopify Plus, 2 req/s for standard.
  - Webhook deduplication: Hash with `webhook_id`, `timestamp`, `payload_hash` (SHA-256).
  - Eviction Policy: `volatile-lru` for rate limits, `noeviction` for webhook cache.
  - Persistence: AOF enabled, synced every 1s to Backblaze B2.
  - Clustering: 3 nodes, 1 replica per shard for 5,000 merchants.
- **GDPR/CCPA Compliance**: No direct PII storage; webhook payloads sanitized (remove `email`, `phone`) before caching, logged in `audit_logs` via AdminCore.

## Inter-Service Communication
- **Synchronous Communication**:
  - **GraphQL**:
    - Endpoint: `/graphql`
    - Routes queries/mutations to `/core.v1/*`, `/points.v1/*`, `/referrals.v1/*`, `/admincore.v1/*`, `/adminfeatures.v1/*`.
    - Validates JWT via `/auth.v1/ValidateToken`.
  - **gRPC**:
    - Calls `/auth.v1/ValidateToken` (input: `token`) for all requests.
    - Routes to:
      - `/points.v1/PointsService/*` (e.g., `AdjustPoints`, `GetBalance`).
      - `/referrals.v1/ReferralsService/*` (e.g., `CreateReferral`, `GetReferralStats`).
      - `/core.v1/CoreService/*` (e.g., `GetMerchant`, `UpdateSettings`).
      - `/admincore.v1/AdminCoreService/*` (e.g., `GetOverview`, `SearchMerchants`).
      - `/adminfeatures.v1/AdminFeaturesService/*` (e.g., `GetRateLimits`, `ConfigureIntegration`).
  - **REST**:
    - `/webhooks/orders/create`: Routes Shopify `orders/create` to Points, Referrals.
    - `/webhooks/customers/create`: Routes Shopify `customers/create` to Core, AdminFeatures.
    - `/webhooks/orders/updated`: Routes Shopify `orders/updated` to Points.
    - `/webhooks/customers/redact`: Routes GDPR requests to AdminCore.
    - Validates HMAC via Shopify’s `X-Shopify-Hmac-Sha256`.
  - **WebSocket**:
    - `/admin/v1/webhooks/stream`: Streams webhook events to AdminCore for debugging (consumed by `AdminCoreService`).
- **Asynchronous Communication**:
  - **Events Produced**:
    - `webhook.received`: `{ merchant_id: string, webhook_id: string, topic: string, payload_hash: string, received_at: timestamp }` (Kafka, consumed by AdminCore, AdminFeatures).
    - `rate_limit_breached`: `{ merchant_id: string, endpoint: string, limit: int, current: int }` (Kafka, consumed by AdminFeatures).
  - **Events Consumed**: None.
  - **Event Schema**: Registered in Confluent Schema Registry, Avro format.
  - **Saga Patterns**: None; webhooks are fire-and-forget with retries (5 attempts, exponential backoff).
- **Calls**:
  - `/auth.v1/ValidateToken` (gRPC, Auth).
  - `/admincore.v1/AdminCoreService/LogWebhook` (gRPC, AdminCore).
  - `/adminfeatures.v1/AdminFeaturesService/TrackRateLimit` (gRPC, AdminFeatures).
- **Called By**: Shopify (webhooks), Frontend (GraphQL/REST), AdminCore, AdminFeatures.

## Key Endpoints
- **GraphQL**: `/graphql` (routes to Core, Points, Referrals, AdminCore, AdminFeatures; complexity budget: 500 points).
- **gRPC**:
  - Routes to `/points.v1/*`, `/referrals.v1/*`, `/core.v1/*`, `/admincore.v1/*`, `/adminfeatures.v1/*`.
- **REST**:
  - `/webhooks/orders/create`
  - `/webhooks/customers/create`
  - `/webhooks/orders/updated`
  - `/webhooks/customers/redact`
  - `/health`
  - `/ready`
  - `/metrics`
- **WebSocket**:
  - `/admin/v1/webhooks/stream`: Streams webhook events for debugging.
- **Access Patterns**: High write (10,000 orders/hour for `orders/create`), moderate read (GraphQL queries).
- **Rate Limits**:
  - Shopify API: 40 req/s (Plus), 2 req/s (standard), 1–4 req/s (Storefront).
  - GraphQL: 500 points/query.
  - REST: 100 req/s per endpoint, tracked in Redis (`rate_limit:{merchant_id}:{endpoint}`).
  - Circuit Breaker: 3 consecutive failures to downstream services trigger 10s pause.

## Health and Readiness Checks
- **Health Endpoint**: `/health` (HTTP GET)
  - Returns `{ "status": "UP" }` if Redis, Kafka, and downstream services (Auth, Points, Referrals) are operational.
- **Readiness Endpoint**: `/ready` (HTTP GET)
  - Returns `{ "ready": true }` when Redis cluster and routes are initialized.
- **Consul Health Check**:
  - Registered via `registrator`: `SERVICE_NAME=api-gateway`, `SERVICE_CHECK_HTTP=/health`.
  - Checks every 10s (timeout: 2s).
- **Validation**: Test in CI/CD: `curl http://api-gateway:8080/health`.

## Service Discovery
- **Tool**: Consul (via `registrator`).
- **Configuration**:
  - Environment Variables: `SERVICE_NAME=api-gateway`, `SERVICE_PORT=50051` (gRPC), `8080` (HTTP/GraphQL), `SERVICE_CHECK_HTTP=/health`, `SERVICE_TAGS=api,gateway,webhooks`.
  - Network: `loyalnest`.
- **Validation**: `curl http://consul:8500/v1/catalog/service/api-gateway`.

## Monitoring and Observability
- **Metrics**:
  - Endpoint: `/metrics` (Prometheus).
  - Key Metrics:
    - `api_gateway_webhooks_received_total`: Webhook count by topic.
    - `api_gateway_graphql_queries_total`: GraphQL query count.
    - `api_gateway_grpc_requests_total`: gRPC request count by service.
    - `api_gateway_rest_requests_total`: REST request count by endpoint.
    - `api_gateway_rate_limit_breaches_total`: Rate limit breaches by merchant.
    - `webhook_latency_seconds`: Webhook processing latency (<200ms).
    - `redis_cache_hit_rate`: Cache hit rate (>95%).
  - **Logging**: Structured JSON logs via Loki, tagged with `shop_domain`, `merchant_id`, `service_name=api-gateway`, `webhook_topic`.
  - **Alerting**: Prometheus Alertmanager, AWS SNS for rate limit breaches (>80% threshold), webhook failures (>3 retries), or downstream latency (>500ms).
  - **Event Tracking**: PostHog (`webhook_received`, `rate_limit_breached`, `webhook_failed`, `webhook_stream_viewed`).

## Security Considerations
- **Authentication**:
  - GraphQL/gRPC: JWT validated via `/auth.v1/ValidateToken`.
  - REST: Shopify HMAC (`X-Shopify-Hmac-Sha256`) for webhooks; API key + HMAC for `/health`, `/metrics`.
- **Authorization**: RBAC via `/roles.v1/GetPermissions` (`admin:full`, `admin:webhooks:view` for debugging).
- **Data Protection**:
  - Webhook payloads sanitized (remove `email`, `phone`) before caching/logging.
  - Redis keys encrypted with AES-256 via `pgcrypto` for `ip_whitelist`.
  - Kafka events encrypted with TLS.
- **IP Whitelisting**: Restrict webhook access via `ip_whitelist:{merchant_id}` (TTL: 7d).
- **Anomaly Detection**: Alert on >3 webhook failures/hour or >10 rate limit breaches/hour via AWS SNS.
- **Security Testing**: OWASP ZAP (ECL: 256) for `/graphql`, `/webhooks/*`, `/admin/v1/webhooks/stream`.

## Feature Flags
- **Tool**: LaunchDarkly
- **Features Controlled**:
  - Webhook routing (`webhook_routing_enabled`)
  - Webhook streaming (`webhook_streaming_enabled`)
  - Rate limit tracking (`rate_limit_tracking_enabled`)
- **Configuration**: Flags toggled per merchant in Phases 4–5, tracked via PostHog (`feature_flag_toggled`).

## Testing Strategy
- **Unit Tests**: Jest for `ApiGatewayRepository` (`trackRateLimit`, `deduplicateWebhook`), HMAC validation, and LaunchDarkly flag logic.
- **Integration Tests**: Testcontainers for Redis, Kafka, and downstream services (Auth, Points, Referrals).
- **Contract Tests**: Pact for gRPC (`/auth.v1/*`, `/points.v1/*`, `/referrals.v1/*`), Kafka (`webhook.received`).
- **E2E Tests**: Cypress for `/webhooks/orders/create`, `/webhooks/customers/create`, `/admin/v1/webhooks/stream`, `/graphql`.
- **Load Tests**: k6 for 10,000 webhooks/hour (<200ms latency), `/graphql` (500 req/s).
- **Chaos Tests**: Chaos Mesh for Redis cluster failures, downstream service outages.
- **Compliance Tests**: Verify payload sanitization, audit logging via AdminCore.
- **i18n Tests**: Validate webhook metadata (`locale` field) for supported languages (`en`, `ar`, `he` with RTL).

## Deployment
- **Docker Compose**:
  - Image: `api-gateway:latest`.
  - Ports: `50051` (gRPC), `8080` (HTTP/GraphQL/WebSocket).
  - Environment Variables: `API_GATEWAY_REDIS_HOST`, `KAFKA_BROKER`, `AUTH_SERVICE_HOST`, `LAUNCHDARKLY_SDK_KEY`.
  - Network: `loyalnest`.
- **Resource Limits**: CPU: 0.5 cores, Memory: 256MiB.
- **Scaling**: 3 replicas for 10,000 webhooks/hour, Redis clustering with 3 nodes.
- **Orchestration**: Kubernetes (Phase 6) with liveness/readiness probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, OWASP ZAP, and LaunchDarkly validation.

## Feedback Collection
- **Method**: Typeform survey with 5–10 admin users (2–3 Shopify Plus) in Phases 4–5 to validate webhook routing and streaming usability.
- **Validation**: Engage 2–3 native speakers for `ar`, `he` webhook metadata via “LoyalNest Collective” Slack.
- **Tracking**: Log feedback in Notion, track via PostHog (`webhook_feedback_submitted`).
- **Deliverable**: Feedback report by February 1, 2026.

## Risks and Mitigations
- **Rate Limit Breaches**: Redis tracking with TTLs, Slack/email alerts at 80% threshold, fallback to Bull queues for non-critical tasks.
- **Webhook Duplication**: Deduplicate via `webhook_cache:{merchant_id}:{webhook_id}` (SHA-256 hash).
- **Downstream Latency**: Circuit breaker (3 failures, 10s pause), retry 5 times with exponential backoff.
- **Webhook Failures**: Log to `audit_logs` via AdminCore, alert on >3 failures/hour.
- **Translation Accuracy**: Validate `locale` field with native speakers.

## Documentation and Maintenance
- **API Documentation**: OpenAPI for REST (`/webhooks/*`, `/health`), gRPC proto files, GraphQL schema in `schema.graphql`.
- **Event Schema**: `webhook.received`, `rate_limit_breached` in Confluent Schema Registry (Avro).
- **Runbook**: Health check (`curl http://api-gateway:8080/health`), logs via Loki, LaunchDarkly flag management.
- **Maintenance**: Rotate HMAC keys quarterly, validate Backblaze B2 backups weekly.

## Action Items
- [ ] Deploy `api_gateway_redis` with clustering by September 15, 2025 (Owner: DB Team).
- [ ] Implement `/graphql` and webhook endpoints by October 15, 2025 (Owner: Dev Team).
- [ ] Test `webhook.received`, `rate_limit_breached` events by November 1, 2025 (Owner: Dev Team).
- [ ] Configure LaunchDarkly feature flags by November 15, 2025 (Owner: Dev Team).
- [ ] Set up Prometheus/Loki for metrics and logs by December 1, 2025 (Owner: SRE Team).
- [ ] Conduct Typeform survey and validate translations by February 1, 2026 (Owner: Frontend Team).

## Timeline
- **Start Date**: September 1, 2025 (Phase 1 for Must Have).
- **Completion Date**: February 17, 2026 (Must Have), April 30, 2026 (Should Have, TVP completion).
- **Risks to Timeline**: Webhook deduplication, rate limit tuning, translation validation.

## Dependencies
- **Internal**: Auth, Points, Referrals, Core, AdminCore, AdminFeatures, Frontend.
- **External**: Shopify APIs, LaunchDarkly.


Recommendations

Implementation: Use @nestjs/microservices for gRPC, Apollo Server for GraphQL, and ws for WebSocket streaming.
Redis: Deploy 3-node cluster with AOF persistence, validate with redis-benchmark.
Testing: Simulate 10,000 webhooks/hour with k6, test deduplication with duplicate webhook_id.
Monitoring: Set up Grafana dashboards for webhook_latency_seconds and api_gateway_rate_limit_breaches_total.
Feedback: Engage Shopify Plus merchants early (Phase 4) to validate webhook routing.

Area	Observation / Recommendation
🔍 Saga Pattern	No saga support yet; might become necessary if webhook reliability or coordination grows in complexity.
🔐 Admin RBAC	Uses /roles.v1/GetPermissions, but may need clarity on fallback or caching if Roles service is unavailable.
📄 API Gateway Protocol Extensions	Consider WebSub or GraphQL Subscriptions in the future if bidirectional merchant communication becomes essential.
📦 Event Consumption	Currently does not consume any Kafka events — if webhook replay/auditing is needed later, this could be reconsidered.
🌍 Translation Validation	Human validation mentioned, but automated consistency checking (e.g., i18n test snapshots) may be added.

You're ready to proceed with implementation and CI/CD setup for this service. Let me know if you’d like help creating:

Swagger/OpenAPI doc generation
Kubernetes Helm chart
Pact tests for gRPC and Kafka
Redis benchmark scripts
PostHog event mapping