# TODO List

## Architecture Enhancements

### 1. Adopt Service Discovery (Phase 1: 1–2 weeks)

- [] Choose a service discovery tool: **Consul** or **Eureka**
- [] Integrate service registration on startup in all microservices
  - [] Add registration logic in `core`, `auth`, `campaign`, etc.
- [] Add `/health` endpoints to all services (e.g., `core_service_plan.md`)
- [] Modify `API Gateway` to resolve service addresses via Consul/Eureka
- [] Update:
  - [] `microservice_design.md`
  - [] `api_gateway_service_plan.md`
  - [] Each affected `*_service_plan.md` with health check specs
- [] Simulate scale-up and test service discovery routing
- [] **Health Check Implementation:** Add `/health` endpoint in each service
- [] **Configure Grafana** to monitor Consul metrics and health check failures
- [] **Test Consul Integration:** Run `docker-compose up` with Consul and verify service registration via `curl http://localhost:8500/v1/agent/services`
- [] **Test Health Checks:** Verify `/health` endpoints for all services and confirm statuses in Consul UI
- [] **Update Related Documents:** Incorporate Consul and health check details into each service's plan

### 2. Adopt GraphQL (Phase 2: 2–3 weeks)

- [] Choose a GraphQL server: **Apollo Server** or **Hasura**
- [] Define GraphQL schema for core features (`users`, `points`, `rfm`)
- [] Implement GraphQL resolvers that call microservice APIs
- [] Integrate Shopify GraphQL Admin API where applicable
- [] Optimize using DataLoader to prevent N+1 issues
- [] Update:
  - [] `api_gateway_service_plan.md` to document GraphQL schema and resolver logic
  - [] `frontend_service_plan.md`
  - [] `features_1_must_have.md` with query examples
- [] Update frontend to use Apollo Client or similar

### 3. Adopt Event-Driven Patterns (Phase 3: 3–4 weeks)

- [] Choose a message broker: **Apache Kafka** or **RabbitMQ**
- [] Define event schemas (e.g., `points_earned`, `order_completed`)
- [] Implement event publishing in:
  - [] `core` for Shopify webhooks
  - [] `points`, `referrals`, `gamification` for actions
- [] Implement event consumers and ensure idempotency
- [] Monitor event flow and broker performance
- [] Update:
  - [] `microservice_design.md`
  - [] `event_tracking_service_plan.md` to cover publishing/consumption, not just logging
  - [] Related `*_service_plan.md` files with retry/queue logic
- [] **Add event schemas and processing logic to relevant service plans**

## Database Enhancements

### 4. Ensure Schema Consistency

- [] Normalize user data between `users.sql` and `auth.sql`
- [] Use UUIDs for consistent user IDs across services
- [] Define foreign key ownership and relationships explicitly

### 5. Improve Indexing and Performance

- [] Add composite indexes to `event_tracking.sql`
- [] Consider InfluxDB or TimescaleDB for event logs
- [] Evaluate `rfm.sql` for computed metrics vs. storage optimization

### 6. Enforce Data Integrity

- [] Add `ON DELETE CASCADE` constraints to cross-service FK
- [] Use **Flyway** or **Liquibase** for schema migration tracking
- [] **Database schema improvements:** Consul and health check-related changes

## Feature Alignment & Shopify Integration

### 7. Create Feature-to-Service Mapping

- [] Build a table like:
  | Feature Service Status |                |                |
  | ---------------------- | -------------- | -------------- |
  | Points Earning         | Points Service | ✅ Implemented  |
  | Referral Tracking      | Referrals      | 🔄 In Progress |
- [] Add this table to `project_plan.md`

### 8. Improve Shopify Integration

- [] Add webhook handlers in `core_service_plan.md`
- [] Implement exponential backoff + retry queue for Shopify rate limits
- [] Use Shopify App Bridge and GraphQL Admin API in frontend/backend

### 9. Scale Analytics

- [] Offload complex queries to:
  - [] Data warehouse (e.g., Snowflake)
  - [] Serverless batch jobs (e.g., AWS Lambda)
- [] Reflect in `rfm_service_plan.md` or `features_3_could_have.md`

## Service Plan Improvements

### 10. Add Role-Based Access Control (RBAC)

- [] Implement JWT/OIDC-based role propagation via `auth` service
- [] Document token flow in `auth_service_plan.md`
- [] Ensure RBAC is enforced in `admincore`, `campaign`, etc.

### 11. Add Health Checks and Monitoring

- [] Add `/health` endpoints to each service
- [] Integrate with Prometheus or New Relic
- [] Define SLAs (e.g., 99.9% uptime) in all `*_service_plan.md`

### 12. Define Testing Strategies

- [] Add test plan sections to all service plans
- [] Implement:
  - [] Unit tests
  - [] Integration tests
  - [] E2E tests with **Testcontainers**
- [] **Test every service**
- [] **Create plan for each service**

## Project Planning & Roadmap

### 13. Align Roadmap with Features

- [] Map roadmap milestones to features (in `project_plan.md`)
- [] Ensure alignment with `features_3_could_have.md`

### 14. Add Risk Management

- [] Cover Shopify API versioning and deprecations
- [] Add compliance strategies for GDPR/CCPA
- [] Add fallback mechanisms (e.g., circuit breakers)

## Security & Compliance

### 15. Improve Data Security

- [] Add AES-256 encryption to sensitive fields (e.g., tokens)
- [] Use **Shopify OAuth 2.0** flow and document it in `auth_service_plan.md`

### 16. Secrets Management

- [] Integrate AWS Secrets Manager or Dapr Secrets API
- [] Replace hardcoded secrets in `config` files and service plans

## Documentation Improvements

### 17. Centralize and Visualize

- [] Create an `architecture_overview.md` with:
  - [] Linked service plans, schemas, diagrams (e.g., Mermaid)
- [] Organize docs using Diátaxis (tutorials, guides, reference, explanation)
- [] Add diagram or visual microservices map to onboarding doc
- [] **Generate Mermaid diagram**
- [] **Generate the following documents:**
  - [] `openapi_spec.md`
  - [] `grpc.md`
  - [] `grpc_call_flow.md`
  - [] `resilience-config.md`
  - [] `flow_diagram.md`
  - [] `sequence_diagrams.md`
  - [] `wireframes.md`
  - [] `health_check.md`
  - [] `testing_strategy.md`


## Services List
- admin_core-service
- admin_features-service
- api-gateway
- auth-service
- campaign-service
- core-service
- event_tracking-service
- frontend
- gamification-service
- points-service
- products-service
- referrals-service
- rfm-service
- roles-service
- users-service



