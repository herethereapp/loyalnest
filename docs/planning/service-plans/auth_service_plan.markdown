# Auth Service Plan

## Overview
- **Purpose**: Manages merchant authentication, admin user sessions, and impersonation for the LoyalNest Shopify app. Supports Shopify OAuth for merchant login, JWT-based authentication, and RBAC for secure access. Handles Shopify Plus scale (50,000+ customers, 10,000 orders/hour) with multilingual support (22 languages, including RTL for `ar`, `he`) and GDPR/CCPA compliance.
- **Priority for TVP**: Low (supports API Gateway, AdminCore, AdminFeatures, Core, Points, Referrals).
- **Dependencies**: API Gateway (token validation), Redis (session caching, rate limiting), AdminCore (session logging), Roles (RBAC), Frontend (login UI).

## Database Setup
- **Database Type**: PostgreSQL (port: 5432), Redis (port: 6380)
- **PostgreSQL Tables**:
  - `merchants`:
    - `id`: UUID, PK, NOT NULL
    - `shop_domain`: VARCHAR(255), UNIQUE, NOT NULL
    - `api_token`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `language`: JSONB (e.g., `{"default": "en", "supported": ["en", "es", "fr", "de", "pt", "ja", "ru", "it", "nl", "pl", "tr", "fa", "zh-CN", "vi", "id", "cs", "ar", "ko", "uk", "hu", "sv", "he"], "rtl": ["ar", "he"]}`)
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `admin_users`:
    - `id`: UUID, PK, NOT NULL
    - `merchant_id`: UUID, FK → `merchants`, NOT NULL
    - `email`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `role_id`: TEXT, FK → `roles`
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `admin_sessions`:
    - `session_id`: UUID, PK, NOT NULL
    - `admin_user_id`: UUID, FK → `admin_users`, NOT NULL
    - `jwt_token`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `expires_at`: TIMESTAMP(3), NOT NULL
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
  - `impersonation_sessions`:
    - `session_id`: UUID, PK, NOT NULL
    - `admin_user_id`: UUID, FK → `admin_users`, NOT NULL
    - `merchant_id`: UUID, FK → `merchants`, NOT NULL
    - `jwt_token`: TEXT, AES-256 ENCRYPTED, NOT NULL
    - `expires_at`: TIMESTAMP(3), NOT NULL
    - `created_at`: TIMESTAMP(3), DEFAULT CURRENT_TIMESTAMP
- **Redis Keys**:
  - `session:{session_id}`: Stores JWT payload (TTL: 24h).
  - `rate_limit:{merchant_id}:{endpoint}`: Tracks API calls (TTL: 60s).
  - `ip_whitelist:{merchant_id}`: Stores allowed IPs (TTL: 7d).
- **Schema Details**:
  - Indexes: `idx_merchants_shop_domain` (btree: `shop_domain`), `idx_merchants_language` (gin: `language`), `idx_admin_users_merchant_id` (btree: `merchant_id`), `idx_admin_sessions_admin_user_id` (btree: `admin_user_id`), `idx_impersonation_sessions_merchant_id` (btree: `merchant_id`).
  - Triggers: `trg_normalize_shop_domain` (lowercase `shop_domain`), `trg_encrypt_email` (encrypt `admin_users.email`), `trg_encrypt_jwt` (encrypt `admin_sessions.jwt_token`, `impersonation_sessions.jwt_token`).
  - Encryption: `admin_users.email`, `merchants.api_token`, `admin_sessions.jwt_token`, `impersonation_sessions.jwt_token` encrypted with AES-256 via `pgcrypto`.
  - Partitioning: `admin_sessions`, `impersonation_sessions` partitioned by `merchant_id` for scalability.
  - Redis: `volatile-lru` eviction for sessions, `noeviction` for IP whitelists, AOF persistence synced every 1s to Backblaze B2.
- **GDPR/CCPA Compliance**: Encrypts PII (`email`, `api_token`, `jwt_token`), logs actions in `audit_logs` via AdminCore, 90-day retention in Backblaze B2.

## Inter-Service Communication
- **Synchronous Communication**:
  - **GraphQL**:
    - Endpoint: `/graphql`
    - Queries:
      - `getSessionStatus(session_id: ID!): SessionStatus!`
      - `getImpersonationStatus(session_id: ID!): ImpersonationStatus!`
    - Mutations:
      - `loginMerchant(shop_domain: String!, oauth_code: String!): AuthResponse!`
      - `refreshToken(refresh_token: String!): AuthResponse!`
      - `logout(session_id: ID!): Boolean!`
      - `startImpersonation(merchant_id: ID!, admin_user_id: ID!): ImpersonationStatus!`
      - `endImpersonation(session_id: ID!): Boolean!`
  - **gRPC**:
    - `/auth.v1/AuthService/ValidateToken` (input: `token`; output: `{ valid: boolean, merchant_id: string, role_id: string }`)
    - `/auth.v1/AuthService/ValidateMerchant` (input: `merchant_id`; output: `{ valid: boolean, shop_domain: string }`)
    - `/auth.v1/AuthService/CreateSession` (input: `merchant_id, admin_user_id`; output: `{ session_id: string, jwt_token: string }`)
    - `/auth.v1/AuthService/CreateImpersonationSession` (input: `merchant_id, admin_user_id`; output: `{ session_id: string, jwt_token: string }`)
  - **REST**:
    - `/auth/v1/login` (POST): Initiates Shopify OAuth flow.
    - `/auth/v1/callback` (GET): Handles OAuth callback, issues JWT.
    - `/auth/v1/refresh` (POST): Refreshes JWT.
    - `/auth/v1/logout` (POST): Invalidates session.
  - **WebSocket**:
    - `/auth/v1/sessions/stream`: Streams session status updates (e.g., `logout`, `impersonation_ended`).
- **Asynchronous Communication**:
  - **Events Produced**:
    - `merchant.created`: `{ merchant_id: string, shop_domain: string, created_at: timestamp }` (consumers: Core, AdminCore).
    - `session.created`: `{ session_id: string, merchant_id: string, admin_user_id: string, created_at: timestamp }` (consumer: AdminCore).
    - `impersonation.started`: `{ session_id: string, merchant_id: string, admin_user_id: string, created_at: timestamp }` (consumer: AdminCore).
    - `session.ended`: `{ session_id: string, merchant_id: string, reason: string }` (consumer: AdminCore).
  - **Events Consumed**: None.
  - **Event Schema**: Registered in Confluent Schema Registry, Avro format.
  - **Saga Patterns**: None; login and impersonation are atomic.
- **Calls**:
  - `/roles.v1/GetPermissions` (gRPC, Roles) for RBAC.
  - `/admincore.v1/AdminCoreService/LogAuthAction` (gRPC, AdminCore) for audit logging.
- **Called By**: API Gateway, Core, Points, Referrals, AdminCore, AdminFeatures, Frontend.

## GraphQL Schema
```graphql
type SessionStatus {
  session_id: ID!
  admin_user_id: ID!
  merchant_id: ID!
  expires_at: String!
  is_active: Boolean!
}

type ImpersonationStatus {
  session_id: ID!
  admin_user_id: ID!
  merchant_id: ID!
  expires_at: String!
  is_active: Boolean!
}

type AuthResponse {
  session_id: ID!
  jwt_token: String!
  refresh_token: String!
  expires_at: String!
}

type Query {
  getSessionStatus(session_id: ID!): SessionStatus!
  getImpersonationStatus(session_id: ID!): ImpersonationStatus!
}

type Mutation {
  loginMerchant(shop_domain: String!, oauth_code: String!): AuthResponse!
  refreshToken(refresh_token: String!): AuthResponse!
  logout(session_id: ID!): Boolean!
  startImpersonation(merchant_id: ID!, admin_user_id: ID!): ImpersonationStatus!
  endImpersonation(session_id: ID!): Boolean!
}

type Subscription {
  onSessionUpdate(merchant_id: ID!): SessionStatus!
  onImpersonationUpdate(merchant_id: ID!): ImpersonationStatus!
}
```

## Key Endpoints
- **GraphQL**: `/graphql` (queries: `getSessionStatus`, `getImpersonationStatus`; mutations: `loginMerchant`, `refreshToken`, `logout`, `startImpersonation`, `endImpersonation`; subscriptions: `onSessionUpdate`, `onImpersonationUpdate`).
- **gRPC**:
  - `/auth.v1/AuthService/ValidateToken`
  - `/auth.v1/AuthService/ValidateMerchant`
  - `/auth.v1/AuthService/CreateSession`
  - `/auth.v1/AuthService/CreateImpersonationSession`
- **REST**:
  - `/auth/v1/login` (POST)
  - `/auth/v1/callback` (GET)
  - `/auth/v1/refresh` (POST)
  - `/auth/v1/logout` (POST)
  - `/health`
  - `/ready`
  - `/metrics`
- **WebSocket**:
  - `/auth/v1/sessions/stream`: Streams session updates.
- **Access Patterns**: Low write (logins, impersonations), high read (token validation at 5,000/hour).
- **Rate Limits**:
  - Internal: 100 req/s for `/auth.v1/*` (tracked in Redis).
  - Shopify OAuth: 2 req/s, enforced via `rate_limit:{merchant_id}:oauth`.

## Health and Readiness Checks
- **Health Endpoint**: `/health` (HTTP GET)
  - Returns `{ "status": "UP" }` if PostgreSQL, Redis, and Kafka are operational.
- **Readiness Endpoint**: `/ready` (HTTP GET)
  - Returns `{ "ready": true }` when migrations and Redis are initialized.
- **Consul Health Check**:
  - Registered via `registrator`: `SERVICE_NAME=auth`, `SERVICE_CHECK_HTTP=/health`.
  - Checks every 10s (timeout: 2s).
- **Validation**: Test in CI/CD: `curl http://auth:8080/health`.

## Service Discovery
- **Tool**: Consul (via `registrator`).
- **Configuration**:
  - Environment Variables: `SERVICE_NAME=auth`, `SERVICE_PORT=50050` (gRPC), `8080` (HTTP/GraphQL), `SERVICE_CHECK_HTTP=/health`, `SERVICE_TAGS=auth,login,impersonation`.
  - Network: `loyalnest`.
- **Validation**: `curl http://consul:8500/v1/catalog/service/auth`.

## Monitoring and Observability
- **Metrics**:
  - Endpoint: `/metrics` (Prometheus).
  - Key Metrics:
    - `auth_logins_total`: Login attempts by merchant.
    - `auth_impersonations_total`: Impersonation sessions started.
    - `auth_token_validations_total`: Token validation requests.
    - `auth_oauth_requests_total`: Shopify OAuth requests.
    - `auth_session_duration_seconds`: Session duration.
    - `redis_cache_hit_rate`: Session cache hit rate (>95%).
  - **Logging**: Structured JSON logs via Loki, tagged with `shop_domain`, `merchant_id`, `service_name=auth`, `locale`.
  - **Alerting**: Prometheus Alertmanager, AWS SNS for login failures (>5/hour), token validation failures (>3/hour), or OAuth errors.
  - **Event Tracking**: PostHog (`auth_login_attempt`, `auth_impersonation_started`, `auth_session_ended`, `auth_oauth_completed`, `feature_flag_toggled`).

## Security Considerations
- **Authentication**:
  - Shopify OAuth 2.0 for merchant login (`client_id`, `client_secret`, scopes: `read_customers`, `write_loyalty`).
  - JWT: Signed with RS256, 24h expiry, refresh tokens (7d expiry), claims: `{ merchant_id, admin_user_id, role_id, iat, exp }`.
- **Authorization**: RBAC via `/roles.v1/GetPermissions` (`admin:full`, `admin:impersonate`, `admin:login`).
- **Data Protection**:
  - Encrypt `admin_users.email`, `merchants.api_token`, `admin_sessions.jwt_token`, `impersonation_sessions.jwt_token` with AES-256 via `pgcrypto`.
  - Kafka events encrypted with TLS.
- **IP Whitelisting**: Restrict access via `ip_whitelist:{merchant_id}` in Redis (TTL: 7d).
- **Anomaly Detection**: Alert on >5 failed logins/hour or >3 impersonation attempts/hour via AWS SNS.
- **Security Testing**: OWASP ZAP (ECL: 256) for `/graphql`, `/auth/v1/*`, `/auth/v1/sessions/stream`.
- **Mitigations**:
  - Token leaks: Short-lived JWTs (24h), refresh tokens (7d), revoke on logout.
  - Session hijacking: Validate `User-Agent`, IP consistency in Redis.

## Feature Flags
- **Tool**: LaunchDarkly
- **Features Controlled**:
  - Shopify OAuth login (`oauth_login_enabled`)
  - Impersonation (`impersonation_enabled`)
  - Session streaming (`session_streaming_enabled`)
- **Configuration**: Flags toggled per merchant in Phases 4–5, tracked via PostHog (`feature_flag_toggled`).

## Testing Strategy
- **Unit Tests**: Jest for `AuthRepository` (`findByShopDomain`, `createSession`, `validateToken`), JWT signing, and LaunchDarkly flag logic.
- **Integration Tests**: Testcontainers for PostgreSQL, Redis, Kafka, and Shopify OAuth mock server.
- **Contract Tests**: Pact for gRPC (`/auth.v1/*`, `/roles.v1/*`), Kafka (`merchant.created`, `session.created`).
- **E2E Tests**: Cypress for `/auth/v1/login`, `/auth/v1/callback`, `/graphql`, `/auth/v1/sessions/stream`.
- **Load Tests**: k6 for 5,000 logins/hour (<200ms latency), 10,000 token validations/hour.
- **Chaos Tests**: Chaos Mesh for PostgreSQL, Redis, and Kafka failures.
- **Compliance Tests**: Verify encryption, audit logging via AdminCore, GDPR compliance.
- **i18n Tests**: Validate error messages for all supported languages, RTL for `ar`, `he` (90%+ accuracy).

## Deployment
- **Docker Compose**:
  - Image: `auth:latest`.
  - Ports: `50050` (gRPC), `8080` (HTTP/GraphQL/WebSocket).
  - Environment Variables: `AUTH_DB_HOST`, `KAFKA_BROKER`, `REDIS_HOST`, `LAUNCHDARKLY_SDK_KEY`, `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`.
  - Network: `loyalnest`.
- **Resource Limits**: CPU: 0.3 cores, Memory: 256MiB.
- **Scaling**: 2 replicas for 5,000 merchants, 5,000 logins/hour.
- **Orchestration**: Kubernetes (Phase 6) with liveness/readiness probes.
- **CI/CD**: GitHub Actions with Jest, Cypress, k6, OWASP ZAP, and LaunchDarkly validation.

## Feedback Collection
- **Method**: Typeform survey with 5–10 admin users (2–3 Shopify Plus) in Phases 4–5 to validate login and impersonation usability.
- **Validation**: Engage 2–3 native speakers for `ar`, `he` error messages via “LoyalNest Collective” Slack.
- **Tracking**: Log feedback in Notion, track via PostHog (`auth_feedback_submitted`).
- **Deliverable**: Feedback report by February 1, 2026.

## Risks and Mitigations
- **Token Leaks**: Short-lived JWTs (24h), refresh tokens (7d), revoke on logout, monitor via PostHog (`auth_token_validation_failed`).
- **OAuth Misconfiguration**: Validate Shopify scopes, redirect URIs; test with mock server.
- **Session Hijacking**: Check `User-Agent`, IP consistency; alert on anomalies (>3 mismatches/hour).
- **Database Latency**: Partition `admin_sessions`, cache in Redis; alert on latency >500ms.
- **Translation Accuracy**: Validate error messages with native speakers.

## Documentation and Maintenance
- **API Documentation**: OpenAPI for REST (`/auth/v1/*`), gRPC proto files, GraphQL schema in `schema.graphql`.
- **Event Schema**: `merchant.created`, `session.created`, `impersonation.started`, `session.ended` in Confluent Schema Registry (Avro).
- **Runbook**: Health check (`curl http://auth:8080/health`), logs via Loki, LaunchDarkly flag management, JWT key rotation.
- **Maintenance**: Rotate JWT keys quarterly, validate Backblaze B2 backups weekly.

## Action Items
- [ ] Deploy `auth_db` and Redis by September 15, 2025 (Owner: DB Team).
- [ ] Implement `/graphql` and `/auth/v1/*` endpoints by October 15, 2025 (Owner: Dev Team).
- [ ] Test `merchant.created`, `session.created` events by November 1, 2025 (Owner: Dev Team).
- [ ] Configure LaunchDarkly feature flags by November 15, 2025 (Owner: Dev Team).
- [ ] Set up Prometheus/Loki for metrics and logs by December 1, 2025 (Owner: SRE Team).
- [ ] Conduct Typeform survey and validate translations by February 1, 2026 (Owner: Frontend Team).

## Timeline
- **Start Date**: September 1, 2025 (Phase 1 for Must Have).
- **Completion Date**: February 17, 2026 (Must Have), April 30, 2026 (Should Have, TVP completion).
- **Risks to Timeline**: OAuth integration, translation validation, JWT key rotation.

## Dependencies
- **Internal**: API Gateway, Core, Points, Referrals, AdminCore, AdminFeatures, Roles, Frontend.
- **External**: Shopify OAuth, LaunchDarkly.

Recommendations

Implementation: Use @nestjs/passport for Shopify OAuth, @nestjs/jwt for token management, and ws for WebSocket streaming.
Database: Deploy PostgreSQL with partitioning, Redis with AOF persistence; validate with pgbench.
Testing: Simulate 5,000 logins/hour with k6, test OAuth with Shopify mock server.
Monitoring: Set up Grafana dashboards for auth_logins_total and auth_session_duration_seconds.
Feedback: Engage Shopify Plus merchants early (Phase 4) to validate login usability.

Minor Observations / Recommendations
Area	Suggestion
OAuth Flow Error Handling	Ensure retry UX + informative error messages (especially for failed code exchange).
Session Hijack Mitigation	IP & User-Agent consistency is great — consider adding optional 2FA or notify on location change.
gRPC Interface Clarity	You may want to document return types (e.g., JWT structure) explicitly in .proto files for consumers.
Security Testing	OWASP ZAP and TLS across Kafka are covered. Consider adding mutation/fuzzing testing to stress session logic.
Load Forecast	You’ve assumed 5,000 logins/hr and 10k token validations/hr — consider a stress margin for BFCM traffic.
Session Termination Hooks	session.ended event exists, but also consider periodic cleanup (e.g., logout on inactivity).

Final Verdict
The Auth Service Plan is complete, scalable, secure, and fully aligned with both:
LoyalNest architecture principles
Must/Should-have feature documents
It's also forward-compatible with LaunchDarkly rollouts, impersonation UX, WebSocket streaming, and OAuth constraints.
Let me know if you’d like implementation support for:
NestJS OAuth integration (@nestjs/passport)
GraphQL + WebSocket setup
Pact test boilerplates
Redis eviction testing
Admin impersonation UX design (frontend)