# LoyalNest Phase 3 Roadmap (October 2025–February 2026)

## Overview
This roadmap outlines the development, testing, and deployment of LoyalNest’s 15 microservices to meet the TVP deadline (February 2026) for Shopify App Store submission. It prioritizes Points, Referrals, Users, Roles, and RFM for core loyalty and user management features, ensures GDPR/CCPA compliance, and supports scalability (10,000 orders/hour). The roadmap is structured in four phases, leveraging Nx monorepo, gRPC/Kafka, and Docker Compose on a VPS (Ubuntu, 32GB RAM, 8 vCPUs). Email delivery relies on third-party providers (Klaviyo, Postscript, AWS SES) via Referrals and AdminFeatures.

## Goals
- **TVP Compliance**: Deliver Points, Referrals, RFM, Users, Roles, and Frontend for Shopify App Store.
- **Scalability**: Handle 10,000 orders/hour with MongoDB sharding, Redis clustering, and TimescaleDB hypertables.
- **GDPR/CCPA**: Encrypt PII (`email`, `credentials`), log audits via AdminCore.
- **Solo Efficiency**: Use AI tools (Grok, Copilot, Cursor) for 30–40% productivity boost.

## Phase 1: Infrastructure Setup (July 28–August 10, 2025)
**Objective**: Establish foundational services and infrastructure for secure onboarding and request routing.

**Services**: Auth, API Gateway  
**Milestones**:
- **July 28–August 1**: Nx monorepo setup
  - Configure `libs/database` (TypeORM, Mongoose, ioredis, TimescaleDB, Elasticsearch).
  - Configure `libs/kafka` (producer/consumer for `points.earned`, `referral.completed`, `user.created`).
  - Set up `docker-compose.yml` with PostgreSQL, MongoDB, Redis, TimescaleDB, Elasticsearch, Kafka, Zookeeper (ports: 5432 Auth, 27017 Points, 5440 Users, 5441 Roles, 5435 RFM).
- **August 2–5**: Auth service
  - Implement `merchants`, `admin_users`, `admin_sessions` (PostgreSQL, port 5432).
  - Develop `/auth.v1/ValidateToken`, `/auth.v1/ValidateMerchant` (gRPC).
  - Produce `merchant.created` (Kafka) for Core.
  - Jest tests for `AuthRepository` (`findByShopDomain`).
- **August 6–10**: API Gateway
  - Implement Redis rate limiting (`rate_limit:{merchant_id}:{endpoint}`, port 6380).
  - Route Shopify `/webhooks/orders/create` to Points, Referrals, RFM.
  - Call `/auth.v1/ValidateToken` (gRPC) for all requests.
  - Produce `webhook.received` (Kafka, optional).
  - Jest tests for `ApiGatewayRepository` (`trackRateLimit`).
  - k6 load tests for 10,000 webhooks/hour.

**Deliverables**:
- Nx monorepo with `libs/database`, `libs/kafka`.
- Docker Compose with all databases and Kafka.
- Auth service with Shopify OAuth and gRPC endpoints.
- API Gateway routing webhooks and gRPC requests.
- Jest tests for Auth, API Gateway (80% coverage).

**Action Items**:
- [ ] Finalize `docker-compose.yml` by July 30, 2025.
- [ ] Deploy Auth database and test `/auth.v1/ValidateToken` by August 5, 2025.
- [ ] Test API Gateway webhook routing by August 10, 2025.

## Phase 2: Core Business Logic (August 11–September 5, 2025)
**Objective**: Build and integrate core TVP features (Points, Referrals, Users, Roles, RFM, Core).

**Services**: Core, Points, Referrals, Users, Roles, RFM  
**Milestones**:
- **August 11–14**: Core service
  - Implement `program_settings`, `customer_import_logs` (PostgreSQL, port 5433).
  - Develop `/core.v1/CreateCustomer` (gRPC).
  - Produce `customer.created`, `customer.updated` (Kafka); consume `rfm.updated`, `gdpr_request.created`.
  - Jest tests for `CoreRepository` (`updateSettings`).
  - Cypress tests for gRPC endpoints.
- **August 15–17**: Users service
  - Implement `users` table (user_id, email, merchant_id, role_id, AES-256 PII, PostgreSQL, port 5440).
  - Add indexes (`user_id`, `email`, `merchant_id`).
  - Implement audit logging triggers (`audit_logs`).
  - Validate with test data (`test/factories/user.ts`, Faker).
  - Jest tests for schema operations.
- **August 18–20**: Roles service
  - Implement `roles` table (role_id, permissions JSONB, merchant_id, PostgreSQL, port 5441).
  - Add indexes (`role_id`, `merchant_id`).
  - Implement audit logging triggers (`audit_logs`).
  - Validate with test data (`test/factories/role.ts`, Faker).
  - Jest tests for schema operations.
- **August 21–25**: Points service
  - Implement `points_transactions`, `reward_redemptions` (MongoDB, port 27017).
  - Develop `/points.v1/GetPointsBalance` (gRPC); call `/users.v1/GetUser`, `/auth.v1/ValidateMerchant`.
  - Produce `points.earned` (Kafka).
  - Jest tests for `PointsRepository` (`createTransaction`).
  - k6 load tests for 10,000 transactions/hour.
- **August 26–30**: Referrals service
  - Implement `referrals` (PostgreSQL, port 5434), `referral:{merchant_id}:{id}` (Redis, port 6379).
  - Develop `/referrals.v1/GetReferralStatus` (gRPC); call `/users.v1/GetUser`, `/auth.v1/ValidateMerchant`.
  - Produce `referral.completed` (Kafka).
  - Integrate with Klaviyo/Postscript/AWS SES for email/SMS delivery.
  - Jest tests for `ReferralsRepository` (`getReferral`).
  - k6 load tests for 700 conversions/hour.
- **August 31–September 5**: RFM service
  - Implement `rfm_segment_deltas`, `rfm_segment_counts`, `rfm_score_history`, `customer_segments` (TimescaleDB, port 5435).
  - Configure hypertable (`created_at`).
  - Add triggers for `orders/create`, `points.earned`.
  - Develop `/rfm.v1/GetSegmentCounts`, `/rfm.v1/GetCustomerRFM` (gRPC).
  - Produce `rfm.updated` (Kafka); consume `points.earned`, `referral.completed`, `customer.updated`.
  - Jest tests for `RFMRepository` (`getSegmentCounts`).
  - k6 load tests for daily refresh (`0 1 * * *`).

**Deliverables**:
- Core service with program settings and GDPR-compliant workflows.
- Users and Roles services with PII encryption and RBAC.
- Points, Referrals, RFM with gRPC and Kafka integration.
- Jest tests (80% coverage), Cypress E2E tests, k6 load tests.
- Saga pattern: Points → RFM → Users → Core.

**Action Items**:
- [ ] Deploy Core database and test `customer.created` by August 14, 2025.
- [ ] Deploy Users database and test schema by August 17, 2025.
- [ ] Deploy Roles database and test schema by August 20, 2025.
- [ ] Test Points `points.earned` flow by August 25, 2025.
- [ ] Test Referrals `referral.completed` with Klaviyo/Postscript by August 30, 2025.
- [ ] Test RFM `rfm.updated` by September 5, 2025.

## Phase 3: Compliance and UI (September 6–October 15, 2025)
**Objective**: Implement compliance features, UI, and integrations for new services.

**Services**: AdminCore, Tasks, Frontend, Users, Roles  
**Tasks**:
- **September 15–20**: AdminCore service
  - Implement `audit_logs`, `gdpr_requests` (WebSQL, PostgreSQL, port 5436).
  - Develop `/admin_core.v1/GetAuditLogs`, `/admin_core.v1/GetGDPRById` (gRPC).
  - Produce `gdpr_request.created` (Kafka); consume `audit_log`, `customer.updated`, `task_completed`.
  - Jest tests for `AdminCoreRepository` (`createAuditLog`, `createAuditLogs`).
  - Cypress tests for GDPR compliance workflows.
- **September 20–25**: Tasks service
  - Implement `tasks` (PostgreSQL, port 5439).
  - Develop `/tasks/` (gRPC).
  - Produce `task.created`, `task.completed` (Kafka); consume `email_event.created`.
  - Jest tests for `TaskRepository` (`createTask`).
  - k6 tests for task queue throughput (500 tasks/second).
- **September 26–October 5**: Frontend service
  - Implement React UI with gRPC calls to `/points.v1/GetPointsBalance`, `/referrals.v1/GetReferralStatus`, `/rfm.v1/GetSegmentCounts`, `/users.v1/GetUser`, `/roles.v1/GetRole`.
  - Add `UsersPage.tsx`, `RolesPage.tsx` for user/role management.
  - Proxy via API Gateway (`/frontend/points`, `/frontend/referrals`, `/frontend/users`).
  - Support i18n (`en`, `es`, `fr`, `de`, `pt`, `ja`).
  - Jest tests for UI components; Cypress tests for dashboard flows, user/role management.
  - k6 load tests for 5,000 merchant views/hour.
  - Track engagement with PostHog (`user.created`, `role.assigned`, `rfm.event`).
- **October 6–10**: Users service APIs
  - Implement REST (`/v1/api/users/create`, `/v1/api/users/update`, `/v1/api/users/get`) and gRPC (`/users.v1/GetUser`, `/users.v1/UpdateUser`).
  - Integrate with `Auth` (JWT), `AdminCore` (`admin:full`).
  - Use Redis (`user:{user_id}`).
  - Produce `user.created`, `user.updated` (Kafka).
  - Jest tests for APIs; Cypress tests for integration.
- **October 11–12**: Roles service APIs
  - Implement REST (`/v1/api/roles/create`, `/v1/api/roles/update`, `/v1/api/roles/get`) and gRPC (`/roles.v1/GetRole`, `/roles.v1/UpdateRole`).
  - Integrate with `Auth` (RBAC), `AdminCore` (`admin:full`).
  - Use Redis (`role:{user_id}`).
  - Produce `role.created`, `role.updated` (Kafka).
  - Jest tests for APIs; Cypress tests for integration.
- **October 13–15**: RFM service APIs
  - Implement REST (`/v1/api/rfm/segments`, `/v1/api/rfm/segments/preview`) and gRPC (`/rfm.v1/GetSegments`, `/rfm.v1/GetCustomerRFM`).
  - Consume `orders/create`, `points.earned`, `referral.completed` (Kafka).
  - Integrate with `Frontend` (`AnalyticsPage.tsx`), `AdminFeatures` (exports).
  - Use Redis (`rfm:{customer_id}`).
  - Jest tests for APIs; Cypress tests for integration.

**Deliverables**:
- AdminCore with audit logging and GDPR/CCPA compliance.
- Tasks for async task queue.
- Frontend with user/role management and RFM dashboards.
- Users and Roles APIs with RBAC.
- RFM APIs with analytics integration.
- Jest, Cypress, k6 tests (80% coverage).

**Action Items**:
- [ ] Deploy AdminCore database and test `gdpr_request.created` by September 20, 2025.
- [ ] Test Event Tracking `task.created` by September 25, 2025.
- [ ] Deploy Frontend and test `UsersPage.tsx`, `RolesPage.tsx` by October 5, 2025.
- [ ] Test Users APIs by October 10, 2025.
- [ ] Test Roles APIs by October 12, 2025.
- [ ] Test RFM APIs and `AnalyticsPage.tsx` by October 15, 2025.

## Phase 4: Advanced Features and Prep (October 16–November 15, 2025)
**Objective**: Complete remaining services and prepare for Phase 6.

**Services**: AdminFeatures, Campaign, Gamification, Products  
**Tasks**:
- **October 16–25**: AdminFeatures service
  - Implement `email_templates`, `shopify_flow_templates`, `integrations` (PostgreSQL, port 5437).
  - Develop `/admin_features.v1/CreateEmailTemplate` (gRPC).
  - Produce `email_event.created` (Kafka); consume `customer.created`.
  - Integrate with `users-service`, `roles-service` for admin access.
  - Use Klaviyo/Postscript/AWS SES for email delivery.
  - Jest tests for `AdminFeaturesRepository` (`createEmailTemplate`).
- **October 26–November 5**: Campaign service
  - Implement `vip_tiers` (PostgreSQL, port 5438).
  - Develop `/campaign.v1/GetVIPTier` (gRPC); consume `customer.created`.
  - Jest tests for `CampaignRepository` (`createVIPTier`).
- **November 6–10**: Gamification service
  - Set up Redis (`badge:{merchant_id}:{customer_id}`, port 6381).
  - Prepare `/gamification.v1/AwardBadge` (gRPC, Phase 6).
  - Jest tests for `GamificationRepository` (`awardBadge`).
- **November 11–15**: Products service
  - Set up Elasticsearch (`products` index, port 9200).
  - Prepare `/products.v1/SearchProducts` (gRPC, Phase 6).
  - Jest tests for `ProductsRepository` (`searchProducts`).

**Deliverables**:
- AdminFeatures with email templates and third-party email integration.
- Campaign for VIP tier management.
- Gamification and Products with database setup for Phase 6.
- Jest tests (80% coverage).

**Action Items**:
- [ ] Deploy AdminFeatures database and test `email_event.created` with Klaviyo/Postscript by October 25, 2025.
- [ ] Deploy Campaign database and test `/campaign.v1/GetVIPTier` by November 5, 2025.
- [ ] Set up Gamification and Products databases by November 15, 2025.

## Post-Phase: Testing and Deployment (November 16, 2025–February 28, 2026)
**Objective**: Finalize testing, deployment, and TVP submission.

**Tasks**:
- **November 16–30**: Integration testing
  - Cypress E2E tests for all gRPC/REST endpoints (e.g., `/points.v1/GetPointsBalance`, `/users.v1/GetUser`, `/rfm.v1/GetSegmentCounts`).
  - k6 load tests for 10,000 orders/hour (Points, Referrals, Users, Roles, RFM).
  - Compliance tests for GDPR/CCPA (AdminCore, Core, Users).
- **December 1–15**: Deployment
  - Deploy all 15 services on VPS via Docker Compose.
  - Configure CI/CD with GitHub Actions (`nx test`, `nx build`).
  - Monitor with Prometheus/Grafana (Kafka lag, DB latency).
- **December 16, 2025–January 31, 2026**: Beta testing
  - Test with 10–15 Shopify merchants (use free tiers: MongoDB Atlas, Redis Labs).
  - Validate 7% SMS conversion (Referrals), daily RFM refresh, 95% user setup success, 100% role assignment accuracy.
- **February 1–28, 2026**: TVP submission
  - Finalize documentation (`docs/plans/`).
  - Submit to Shopify App Store with Points, Referrals, RFM, Users, Roles, Frontend.

**Deliverables**:
- Fully tested and deployed app.
- TVP-compliant submission with core features.

**Action Items**:
- [ ] Complete integration tests by November 30, 2025.
- [ ] Deploy all services on VPS by December 15, 2025.
- [ ] Submit to Shopify App Store by February 15, 2026.

## Risks and Mitigations
- **Risk**: Solo developer burnout.
  - **Mitigation**: Use AI tools (Grok, Copilot, Cursor) for 30–40% efficiency; prioritize TVP services.
- **Risk**: Scalability issues (10,000 orders/hour).
  - **Mitigation**: MongoDB sharding (Points), Redis clustering (Referrals, Users, Roles), TimescaleDB hypertables (RFM).
- **Risk**: GDPR/CCPA non-compliance.
  - **Mitigation**: Encrypt PII (`email`, `credentials`) in Users, Core, AdminFeatures; log audits via AdminCore.
- **Risk**: Budget overrun ($97,012.50).
  - **Mitigation**: Use free tiers for testing, optimize VPS usage.
- **Risk**: Email deliverability issues.
  - **Mitigation**: Rely on Klaviyo/Postscript/AWS SES, configure webhooks, monitor with PostHog (`email.bounced`).

## Dependencies
- **External**: Shopify API (`@shopify/shopify-api`, 40 req/s Plus), Klaviyo/Postscript/AWS SES (Referrals, AdminFeatures).
- **Internal**: `libs/database` (TypeORM, Mongoose, ioredis), `libs/kafka` (Confluent Kafka).
- **Inter-Service**:
  - Auth: Validates tokens for API Gateway, Core, Points, Referrals, Users, Roles, RFM.
  - API Gateway: Routes webhooks to Points, Referrals, RFM.
  - Users: Provides user data to Core, Points, Referrals, RFM, Frontend.
  - Roles: Provides RBAC to Auth, AdminCore, Frontend.
  - RFM: Provides analytics to Core, Frontend, AdminFeatures.
  - Points/Referrals: Trigger RFM via Kafka.
  - AdminCore: Logs audits for Users, Points, Referrals, Core.
  - Frontend: Queries Points, Referrals, RFM, Users, Roles via API Gateway.

## Timeline Summary
- **Phase 1**: July 28–August 10, 2025 (Infrastructure)
- **Phase 2**: August 11–September 5, 2025 (Core Business Logic)
- **Phase 3**: September 6–October 15, 2025 (Compliance, UI)
- **Phase 4**: October 16–November 15, 2025 (Advanced Features)
- **Post-Phase**: November 16, 2025–February 28, 2026 (Testing, Deployment, TVP)