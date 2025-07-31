# TODO List

## Architecture Enhancements

### 1. Adopt Service Discovery (Phase 1: 1–2 weeks)

- [done] Choose a service discovery tool: Consul 
- [] Integrate service registration on startup in all microservices
  - [] Add registration logic in `core`, `auth`, `campaign`, etc.
- [] Add `/health` endpoints to all services (e.g., `core_service_plan.md`)
- [] Modify `API Gateway` to resolve service addresses via Consul/Eureka
- [] Update:
  - [done] `microservice_design.md`
  - [] `api_gateway_service_plan.md`
  - [] Each affected `*_service_plan.md` with health check specs
- [] Simulate scale-up and test service discovery routing
- [] Health Check Implementation: Add `/health` endpoint in each service
- [] Configure Grafana to monitor Consul metrics and health check failures
- [] Test Consul Integration: Run `docker-compose up` with Consul and verify service registration via `curl http://localhost:8500/v1/agent/services`
- [] Test Health Checks: Verify `/health` endpoints for all services and confirm statuses in Consul UI
- [] Update Related Documents: Incorporate Consul and health check details into each service's plan

### 2. Adopt GraphQL (Phase 2: 2–3 weeks)

- [] Choose a GraphQL server: **Apollo Server** or **Hasura**
- [] Define GraphQL schema for core features (`users`, `points`, `rfm`)
- [] Implement GraphQL resolvers that call microservice APIs
- [] Integrate Shopify GraphQL Admin API where applicable
- [] Optimize using DataLoader to prevent N+1 issues
- [] Update:
  - [] `api_gateway_service_plan.md` to document GraphQL schema and resolver logic
  - [] `frontend_service_plan.md`
  - [done] `features_1_must_have.md` with query examples
  - [done] `features_2_should_have.md` with query examples
  - [done] `features_3_could_have.md` with query examples
- [] Update frontend to use Apollo Client or similar

### 3. Adopt Event-Driven Patterns (Phase 3: 3–4 weeks)

- [done] Choose a message broker: **Apache Kafka** or **RabbitMQ**
- [] Define event schemas (e.g., `points_earned`, `order_completed`)
- [] Implement event publishing in:
  - [] `core` for Shopify webhooks
  - [] `points`, `referrals`, `gamification` for actions
- [] Implement event consumers and ensure idempotency
- [] Monitor event flow and broker performance
- [] Update:
  - [done] `microservice_design.md`
  - [] `event_tracking_service_plan.md` to cover publishing/consumption, not just logging
  - [] Related `*_service_plan.md` files with retry/queue logic
- [] Add event schemas and processing logic to relevant service plans

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
- [] Use Flyway or Liquibase for schema migration tracking
- [] Database schema improvements: Consul and health check-related changes

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
  - [] E2E tests with Testcontainers
- [] Test every service
- [] Create plan for each service

## Project Planning & Roadmap

### 13. Align Roadmap with Features

- [] Map roadmap milestones to features (in `project_plan.md`)

### 14. Add Risk Management

- [] Cover Shopify API versioning and deprecations
- [] Add compliance strategies for GDPR/CCPA
- [] Add fallback mechanisms (e.g., circuit breakers)

## Security & Compliance

### 15. Improve Data Security

- [] Add AES-256 encryption to sensitive fields (e.g., tokens)
- [] Use Shopify OAuth 2.0 flow and document it in `auth_service_plan.md`

### 16. Secrets Management

- [] Integrate AWS Secrets Manager or Dapr Secrets API
- [] Replace hardcoded secrets in `config` files and service plans

## Documentation Improvements

### 17. Centralize and Visualize

- [] Create an `architecture_overview.md` with:
  - [] Linked service plans, schemas, diagrams (e.g., Mermaid)
- [] Organize docs using Diátaxis (tutorials, guides, reference, explanation)
- [] Add diagram or visual microservices map to onboarding doc
- [] Generate Mermaid diagram
- [] Generate the following documents:
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


do below after configured each service:
----------------------------------------
=========================
core-service
=========================
Additional Steps to Ensure Functionality
To ensure the updated main.ts works in your Nx monorepo and LoyalNest setup, complete these steps:
1. Verify consul Dependency
Ensure consul and @types/consul are installed in the root package.json:
json{
  "dependencies": {
    "consul": "^1.2.0",
    ...
  },
  "devDependencies": {
    "@types/consul": "^0.5.0",
    ...
  }
}
If not installed, run:
bashcd <project-root>
npm install consul
npm install --save-dev @types/consul
2. Implement Health Check Endpoint
Consul’s health check requires a /health endpoint at http://core:3000/api/health (due to globalPrefix: 'api'). If not already implemented, add a health controller.
Example: apps/core-service/src/health/health.controller.ts
typescriptimport { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok', service: 'core-service' };
  }
}
Update apps/core-service/src/app/app.module.ts
typescriptimport { Module } from '@nestjs/common';
import { HealthController } from '../health/health.controller';

@Module({
  imports: [],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
Alternatively, use a shared Nx library (e.g., @loyalnest/common) for the health controller, as described in previous responses.
3. Update Dockerfile
Ensure the core service’s Dockerfile (apps/core-service/Dockerfile) includes the root package.json and builds the Nx project:
dockerfileFROM node:18
WORKDIR /app
COPY package*.json ./
COPY nx.json ./
COPY tsconfig.json ./
RUN npm install
COPY apps/core-service ./apps/core-service
COPY libs ./libs
RUN npx nx build core-service
EXPOSE 3000
CMD ["npx", "nx", "serve", "core-service"]
4. Test the Setup

Start Docker Compose:
bashcd <project-root>
docker compose up -d

Verify Consul Registration:

Open the Consul UI at http://localhost:8500 (per docker-compose.yml).
Check the “Services” tab for core-service with a “Passing” health check named core-service-health.
Query via API:
bashcurl http://localhost:8500/v1/catalog/service/core-service
Expected output:
json[
  {
    "ID": "core-service",
    "Service": "core-service",
    "Address": "core",
    "Port": 3000,
    ...
  }
]

Verify health check:
bashcurl http://localhost:8500/v1/health/checks/core-service
Expected output includes a check with Name: core-service-health.


Test Health Check:
bashcurl http://localhost:3000/api/health
Expected output:
json{ "status": "ok", "service": "core-service" }

Test KV Store (for US-BI6):

Store a reward configuration:
bashcurl -X PUT -d '{"reward_id": "CUSTOM123", "type": "gift_card", "value": 50}' http://localhost:8500/v1/kv/loyalnest/custom_rewards

Fetch in a controller (e.g., in core service):
typescriptconst reward = await consul.kv.get('loyalnest/custom_rewards');
Logger.log('Reward:', JSON.parse(reward.Value));




5. Localization Support
For Phase 6 languages (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he), store configurations in Consul’s KV store:
bashcurl -X PUT -d '{"title": "Welcome"}' http://localhost:8500/v1/kv/loyalnest/i18n/en
curl -X PUT -d '{"title": "ברוכים הבאים"}' http://localhost:8500/v1/kv/loyalnest/i18n/he
Access in core or frontend service:
typescriptconst lang = process.env.LANGUAGE || 'en';
const i18n = await consul.kv.get(`loyalnest/i18n/${lang}`);
6. Notes

Consul Version: The error suggests you’re using @types/consul@0.5.0 with consul@1.2.0. If issues persist, update to the latest versions:
bashnpm install consul@latest @types/consul@latest

Registrator Conflict: If using manual registration, consider removing the registrator service from docker-compose.yml to avoid duplicates:
yaml# Comment out or remove
# registrator:
#   image: gliderlabs/registrator:master
#   ...

Scalability: The updated registration supports LoyalNest’s scalability (e.g., 10,000 tier adjustments/hour for US-BI7) via Consul’s service discovery.
Testing: Add Jest tests in apps/core-service/src:
typescriptdescribe('Consul Registration', () => {
  it('registers core-service', async () => {
    const Consul = require('consul');
    const consul = new Consul({ host: 'consul', port: 8500 });
    await consul.agent.service.register({
      name: 'core-service',
      address: 'core',
      port: 3000,
      check: { name: 'core-service-health', http: 'http://core:3000/api/health', interval: '10s' },
    });
    const services = await consul.catalog.service.nodes('core-service');
    expect(services).toHaveLength(1);
  });
});


==============================
admin_core-service
==============================
Additional Steps to Ensure Functionality
To ensure the updated main.ts works in your Nx monorepo and LoyalNest setup, complete these steps:
1. Verify consul Dependency
Ensure consul and @types/consul are installed in the root package.json:
json{
  "dependencies": {
    "consul": "^1.2.0",
    ...
  },
  "devDependencies": {
    "@types/consul": "^0.5.0",
    ...
  }
}
If not installed, run:
bashcd <project-root>
npm install consul
npm install --save-dev @types/consul
2. Implement Health Check Endpoint
Consul’s health check requires a /health endpoint at http://admin-core:3008/api/health (due to globalPrefix: 'api'). Add a health controller if not already present.
Example: apps/admin-core-service/src/health/health.controller.ts
typescriptimport { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok', service: 'admin-core-service' };
  }
}
Update apps/admin-core-service/src/app/app.module.ts
typescriptimport { Module } from '@nestjs/common';
import { HealthController } from '../health/health.controller';

@Module({
  imports: [],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
Alternatively, use a shared Nx library (e.g., @loyalnest/common) for the health controller, as described in previous responses:
typescriptimport { Module } from '@nestjs/common';
import { HealthController } from '@loyalnest/common';

@Module({
  imports: [],
  controllers: [HealthController.bind(null, 'admin-core-service')],
  providers: [],
})
export class AppModule {}
3. Update Dockerfile
Ensure the admin-core service’s Dockerfile (apps/admin-core-service/Dockerfile) includes the root package.json and builds the Nx project:
dockerfileFROM node:18
WORKDIR /app
COPY package*.json ./
COPY nx.json ./
COPY tsconfig.json ./
RUN npm install
COPY apps/admin-core-service ./apps/admin-core-service
COPY libs ./libs
RUN npx nx build admin-core-service
EXPOSE 3008
CMD ["npx", "nx", "serve", "admin-core-service"]

Port Update: Changed EXPOSE 3000 to EXPOSE 3008 to match the 3008:3008 port mapping in docker-compose.yml.

4. Test the Setup

Start Docker Compose:
bashcd <project-root>
docker compose up -d

Verify Consul Registration:

Open the Consul UI at http://localhost:8500 (per docker-compose.yml).
Check the “Services” tab for admin-core-service with a “Passing” health check named admin-core-service-health.
Query via API:
bashcurl http://localhost:8500/v1/catalog/service/admin-core-service
Expected output:
json[
  {
    "ID": "admin-core-service",
    "Service": "admin-core-service",
    "Address": "admin-core",
    "Port": 3008,
    ...
  }
]

Verify health check:
bashcurl http://localhost:8500/v1/health/checks/admin-core-service
Expected output includes a check with Name: admin-core-service-health.


Test Health Check:
bashcurl http://localhost:3008/api/health
Expected output:
json{ "status": "ok", "service": "admin-core-service" }

Test KV Store (for US-BI6):

Store a reward configuration:
bashcurl -X PUT -d '{"reward_id": "CUSTOM123", "type": "gift_card", "value": 50}' http://localhost:8500/v1/kv/loyalnest/custom_rewards

Fetch in a controller (e.g., in admin-core service):
typescriptconst consul = new Consul({ host: 'consul', port: 8500 });
const reward = await consul.kv.get('loyalnest/custom_rewards');
Logger.log('Reward:', JSON.parse(reward.Value));




5. Localization Support
For Phase 6 languages (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he), store configurations in Consul’s KV store:
bashcurl -X PUT -d '{"title": "Admin Dashboard"}' http://localhost:8500/v1/kv/loyalnest/i18n/en
curl -X PUT -d '{"title": "لوحة الإدارة"}' http://localhost:8500/v1/kv/loyalnest/i18n/ar
Access in admin-core or frontend service:
typescriptconst lang = process.env.LANGUAGE || 'en';
const consul = new Consul({ host: 'consul', port: 8500 });
const i18n = await consul.kv.get(`loyalnest/i18n/${lang}`);
Logger.log('i18n:', JSON.parse(i18n.Value));
6. Notes

Consul Version: The update assumes consul@1.2.0 and @types/consul@0.5.0. If issues persist, update to the latest versions:
bashnpm install consul@latest @types/consul@latest

Registrator Conflict: If using manual registration, consider removing the registrator service from docker-compose.yml to avoid duplicates:
yaml# Comment out or remove
# registrator:
#   image: gliderlabs/registrator:master
#   ...

Scalability: Consul registration supports LoyalNest’s scalability (e.g., 10,000 tier adjustments/hour for US-BI7) via dynamic service discovery, complementing Redis Streams and Kafka.
Testing: Add Jest tests in apps/admin-core-service/src:
typescriptdescribe('Consul Registration', () => {
  it('registers admin-core-service', async () => {
    const Consul = require('consul');
    const consul = new Consul({ host: 'consul', port: 8500 });
    await consul.agent.service.register({
      name: 'admin-core-service',
      address: 'admin-core',
      port: 3008,
      check: { name: 'admin-core-service-health', http: 'http://admin-core:3008/api/health', interval: '10s' },
    });
    const services = await consul.catalog.service.nodes('admin-core-service');
    expect(services).toHaveLength(1);
  });
});

Localization: The admin-core service, which likely manages admin dashboards, can use Consul’s KV store for language-specific configurations, with RTL support for ar and he handled in the frontend service via i18next.