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

================
update docker-compose.yml
================
Additional Steps to Ensure Functionality
To implement the revised docker-compose.yml and ensure it works with your LoyalNest project, follow these steps:
1. Create SQL Files
Create SQL initialization files for each PostgreSQL database in the sql/ directory to define schemas supporting features like US-BI6 (Custom Rewards) and Phase 6 localization.
Example: sql/core-service.sql
sqlCREATE TABLE IF NOT EXISTS rewards (
  id SERIAL PRIMARY KEY,
  reward_id VARCHAR(50) UNIQUE NOT NULL,
  type VARCHAR(50) NOT NULL,
  value DECIMAL(10, 2) NOT NULL,
  language VARCHAR(10) DEFAULT 'en',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO rewards (reward_id, type, value, language) VALUES
  ('CUSTOM123', 'gift_card', 50.00, 'en'),
  ('CUSTOM123', 'gift_card', 50.00, 'es'),
  ('CUSTOM123', 'gift_card', 50.00, 'ar');

Repeat for other services (e.g., auth-service.sql, users-service.sql, etc.), tailoring schemas to their needs (e.g., users table for users-service, roles table for roles-service).
Create the sql/ directory:
bashmkdir -p sql
touch sql/core-service.sql sql/auth-service.sql sql/users-service.sql sql/roles-service.sql sql/rfm-service.sql sql/referrals-service.sql sql/event-tracking-service.sql sql/admin-core-service.sql sql/admin-features-service.sql sql/campaign-service.sql sql/gamification-service.sql sql/products-service.sql


2. Update Service Configurations
Ensure each service’s main.ts and app.module.ts are configured to connect to their dedicated database and register with Consul.
Example: Update apps/core-service/src/main.ts
Use the existing main.ts from previous responses, ensuring it matches the new port (3002) and database (core-service-db):
typescriptimport { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import Consul from 'consul';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const globalPrefix = 'api';
  app.setGlobalPrefix(globalPrefix);

  const consul = new Consul({
    host: process.env.CONSUL_URL?.split('//')[1].split(':')[0] || 'consul',
    port: parseInt(process.env.CONSUL_URL?.split(':')[2] || '8500', 10),
  });

  const serviceName = 'core-service';
  const servicePort = parseInt(process.env.PORT || '3002', 10);
  const serviceAddress = 'core-service';

  try {
    await consul.agent.service.register({
      name: serviceName,
      address: serviceAddress,
      port: servicePort,
      check: {
        name: `${serviceName}-health`,
        http: `http://${serviceAddress}:${servicePort}/${globalPrefix}/health`,
        interval: '10s',
        timeout: '5s',
        deregistercriticalserviceafter: '30s',
      },
    });
    Logger.log(`Registered ${serviceName} with Consul at ${serviceAddress}:${servicePort}`);
  } catch (error) {
    Logger.error(`Failed to register ${serviceName} with Consul:`, error);
  }

  process.on('SIGINT', async () => {
    Logger.log(`Deregistering ${serviceName} from Consul`);
    try {
      await consul.agent.service.deregister(serviceName);
    } catch (error) {
      Logger.error(`Failed to deregister ${serviceName}:`, error);
    }
    process.exit(0);
  });

  await app.listen(servicePort);
  Logger.log(`🚀 Application is running on: http://localhost:${servicePort}/${globalPrefix}`);
}

bootstrap();
Example: Update apps/core-service/src/app/app.module.ts
typescriptimport { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HealthController } from '../health/health.controller';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.PG_HOST || 'core-service-db',
      port: parseInt(process.env.PG_PORT || '5432', 10),
      database: process.env.PG_DATABASE || 'loyalnest_core',
      username: process.env.PG_USER || 'postgres',
      password: process.env.PG_PASSWORD || 'password',
      autoLoadEntities: true,
      synchronize: true, // Set to false in production
    }),
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}

Install TypeORM (if not already installed):
bashcd <project-root>
npm install @nestjs/typeorm typeorm pg
npm install --save-dev @types/mongodb # For points-service

Repeat for other services, updating PG_HOST, PG_DATABASE, and ports to match the table (e.g., auth-service uses auth-service-db and loyalnest_auth).

3. Update points-service for MongoDB
Example: apps/points/src/app/app.module.ts
typescriptimport { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HealthController } from '../health/health.controller';

@Module({
  imports: [
    MongooseModule.forRoot(process.env.MONGO_URL || 'mongodb://points-service-db:27017/loyalnest_points'),
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}

Install Mongoose:
bashnpm install @nestjs/mongoose mongoose


4. Test the Setup

Create .env File:
bashecho "DB_PASSWORD=secure_password" > .env
echo "SHOPIFY_API_KEY=your_shopify_key" >> .env
echo "AUTH0_DOMAIN=your_auth0_domain" >> .env
echo "ENCRYPTION_KEY=your_encryption_key" >> .env
echo "KLAVIYO_API_KEY=your_klaviyo_key" >> .env
echo "POSTSCRIPT_API_KEY=your_postscript_key" >> .env
echo "AWS_SES_ACCESS_KEY=your_aws_access_key" >> .env
echo "AWS_SES_SECRET_KEY=your_aws_secret_key" >> .env
echo "POSTHOG_API_KEY=your_posthog_key" >> .env
echo "SHOPIFY_APP_BRIDGE_KEY=your_shopify_bridge_key" >> .env

Start Docker Compose:
bashcd <project-root>
docker compose up -d

Verify Database Connections:

For PostgreSQL (e.g., core-service-db):
bashpsql -h localhost -p 5437 -U postgres -d loyalnest_core
Enter password (secure_password) and verify schema:
sql\dt
SELECT * FROM rewards;

For MongoDB (points-service-db):
bashmongosh "mongodb://localhost:5445/loyalnest_points"



Test Health Checks:

For each service (e.g., core-service):
bashcurl http://localhost:3002/api/health
Expected output:
json{ "status": "ok", "service": "core-service", "database": "connected" }



Verify Consul Registration:

Open http://localhost:8500 and check for services (e.g., core-service, auth-service) with “Passing” health checks.
Query:
bashcurl http://localhost:8500/v1/catalog/service/core-service



Test Localization (Phase 6):

Store configurations in Consul’s KV store:
bashcurl -X PUT -d '{"table_name": "rewards"}' http://localhost:8500/v1/kv/loyalnest/db/core/en
curl -X PUT -d '{"table_name": "مكافآت"}' http://localhost:8500/v1/kv/loyalnest/db/core/ar

Fetch in core-service:
typescriptconst consul = new (require('consul'))({ host: 'consul', port: 8500 });
const lang = process.env.LANGUAGE || 'en';
const dbConfig = await consul.kv.get(`loyalnest/db/core/${lang}`);
Logger.log('DB Config:', JSON.parse(dbConfig.Value));




5. Notes

Security: Use a .env file for sensitive variables (DB_PASSWORD, API keys). In production, use a secrets manager or Consul KV store.
Production: Remove database port mappings (e.g., 5437:5432) for security, relying on Docker DNS (core-service-db:5432). Use Consul ACLs for access control.
Scalability: Dedicated databases support US-BI7 and US-BI8 by isolating workloads, with Redis and Kafka handling high-throughput tasks.
SQL Files: Ensure each .sql file exists in the sql/ directory with appropriate schemas. For rfm-service.sql, include TimescaleDB-specific commands (e.g., CREATE EXTENSION timescaledb).
Port Conflicts: The table’s ports (5433–5445) avoid conflicts with existing services (consul:8500, redis:6379, etc.). Double-check for conflicts if additional services are added.
Registrator: Removed registrator to align with manual Consul registration in main.ts files, avoiding duplicates.

References

: Docker Compose for microservices with dedicated databases.
: TimescaleDB setup in Docker.
: Consul service registration with NestJS.

This revised docker-compose.yml implements dedicated databases per the provided table, ensuring compatibility with LoyalNest’s Nx monorepo, Consul, and Phase 6 requirements. Let me know if you need help creating SQL files, updating main.ts for other services, or configuring Consul for database-related settings!7.8spls add registrator service back, as i dont know this service can do it, i dont want register consul manually.To address your request, I’ll revise the docker-compose.yml to add back the registrator service, which was removed in the previous response because manual Consul registration was implemented in main.ts files (e.g., for admin-core-service and core-service). The registrator service (using gliderlabs/registrator:master) automatically registers Docker containers with Consul, eliminating the need for manual registration in each service’s main.ts. This aligns with your preference to avoid manual Consul registration. The registrator service will detect containers on the loyalnest network, register them with Consul (consul:8500), and handle health checks based on exposed ports and environment variables.
I’ll update the docker-compose.yml from the previous response to include the registrator service, ensuring it works with the dedicated database setup (e.g., core-service-db on 5437:5432, auth-service-db on 5435:5432, etc.) and the specified ports for each microservice (e.g., core-service on 3002, auth-service on 3001). The configuration will maintain compatibility with your Nx monorepo, Consul integration, and LoyalNest’s requirements, including scalability (US-BI7: 10,000 tier adjustments/hour) and Phase 6 localization (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he).
Key Considerations for Adding registrator

Purpose of Registrator: gliderlabs/registrator:master monitors Docker containers and automatically registers them with Consul as services, using container metadata (e.g., ports, environment variables like SERVICE_NAME, SERVICE_TAGS) to configure service entries and health checks.
Health Checks: For registrator to register services correctly, each microservice (e.g., core-service, auth-service) must expose a health check endpoint (e.g., /api/health on port 3002 for core-service). This was implemented in previous responses (e.g., HealthController in core-service).
Port Configuration: The table specifies application ports (e.g., core-service on 3002, auth-service on 3001). registrator will use these ports for service registration and health checks (e.g., http://core-service:3002/api/health).
Environment Variables: Add SERVICE_NAME and SERVICE_TAGS to each microservice to customize Consul registration (e.g., SERVICE_NAME=core-service, SERVICE_TAGS=http,api).
Database Services: Database containers (e.g., core-service-db, auth-service-db) don’t need registration with Consul, as they’re not application services. registrator will ignore them unless explicitly configured.

Below is the revised docker-compose.yml with the registrator service added back, wrapped in the required artifact tag.docker-compose.ymlyaml•Key Changes

Added Registrator Service:

Restored the registrator service with the original configuration:
yamlregistrator:
  image: gliderlabs/registrator:master
  depends_on:
    - consul
  volumes:
    - /var/run/docker.sock:/tmp/docker.sock
  command: "consul://consul:8500"
  environment:
    - SERVICE_IGNORE=true
  networks:
    - loyalnest

Purpose: Automatically registers services (e.g., core-service, auth-service) with Consul (consul:8500) by monitoring Docker containers.
SERVICE_IGNORE=true: Prevents registrator from registering itself as a service in Consul, avoiding unnecessary entries.
Volume: Mounts /var/run/docker.sock to allow registrator to access Docker container metadata.
Command: Connects to Consul at consul:8500 for service registration.


Added Service Metadata for Registrator:

Added SERVICE_NAME and SERVICE_TAGS environment variables to each application service (e.g., core-service, auth-service, frontend) to customize Consul registration:

SERVICE_NAME: Matches the service name (e.g., core-service, auth-service).
SERVICE_TAGS: Uses http,api for backend services and http,frontend for frontend to categorize services in Consul.


Example for core-service:
yamlenvironment:
  - SERVICE_NAME=core-service
  - SERVICE_TAGS=http,api

Registrator uses these to register services with Consul, associating health checks with the primary port (e.g., 3002 for core-service) and the /health endpoint (e.g., http://core-service:3002/health).


Retained Dedicated Database Setup:

Kept all dedicated database services (e.g., core-service-db on 5437:5432, auth-service-db on 5435:5432, points-service-db on 5445:27017) as per the previous revision and provided table.
Databases are not registered with Consul by registrator unless explicitly configured (not needed here, as they’re internal dependencies).


Health Check Considerations:

Ensured each service has a health check endpoint (e.g., /api/health for backend services, /health for frontend) to work with registrator. Previous responses implemented this (e.g., HealthController in core-service, admin-core-service).
Registrator automatically detects the exposed port (e.g., 3002 for core-service) and checks the /health endpoint if SERVICE_TAGS includes http.


Preserved Other Configurations:

Maintained ports, environment variables, dependencies, and volumes for redis, kafka, zookeeper, nginx, and consul from the previous revision.
Kept database health checks (pg_isready for PostgreSQL) to ensure services wait for databases to be ready.



Additional Steps to Ensure Functionality
Since you’re using registrator instead of manual Consul registration, you need to update your application code and test the setup.
1. Remove Manual Consul Registration
Remove Consul registration code from each service’s main.ts (e.g., apps/core-service/src/main.ts, apps/admin-core/src/main.ts) to avoid duplicate registrations, as registrator handles this automatically.
Example: Revised apps/core-service/src/main.ts
typescriptimport { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const globalPrefix = 'api';
  app.setGlobalPrefix(globalPrefix);
  const port = process.env.PORT || 3002;
  await app.listen(port);
  Logger.log(`🚀 Application is running on: http://localhost:${port}/${globalPrefix}`);
}

bootstrap();

Changes: Removed Consul import, registration logic, and SIGINT handler, as registrator handles service registration and deregistration.
Repeat: Apply this change to all services (auth-service, users-service, admin-core-service, etc.), updating the port to match the table (e.g., 3001 for auth-service, 3010 for admin-core-service).
Example for admin-core-service: Update apps/admin-core/src/main.ts (from your initial request) to:
typescriptimport { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const globalPrefix = 'api';
  app.setGlobalPrefix(globalPrefix);
  const port = process.env.PORT || 3010;
  await app.listen(port);
  Logger.log(`🚀 Application is running on: http://localhost:${port}/${globalPrefix}`);
}

bootstrap();


2. Ensure Health Check Endpoints
Verify that each service has a /health endpoint for registrator to use. Previous responses provided a HealthController that checks both the application and database connection.
Example: apps/core-service/src/health/health.controller.ts
typescriptimport { Controller, Get } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

@Controller('health')
export class HealthController {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  @Get()
  async check() {
    try {
      await this.dataSource.query('SELECT NOW()');
      return { status: 'ok', service: 'core-service', database: 'connected' };
    } catch (error) {
      return { status: 'error', service: 'core-service', database: 'failed' };
    }
  }
}

For points-service (MongoDB):
typescriptimport { Controller, Get } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { Connection } from 'mongoose';

@Controller('health')
export class HealthController {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  @Get()
  async check() {
    try {
      await this.connection.db.command({ ping: 1 });
      return { status: 'ok', service: 'points-service', database: 'connected' };
    } catch (error) {
      return { status: 'error', service: 'points-service', database: 'failed' };
    }
  }
}

For frontend:
typescriptimport { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok', service: 'frontend' };
  }
}

Ensure in app.module.ts:
typescriptimport { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HealthController } from '../health/health.controller';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.PG_HOST || 'core-service-db',
      port: parseInt(process.env.PG_PORT || '5432', 10),
      database: process.env.PG_DATABASE || 'loyalnest_core',
      username: process.env.PG_USER || 'postgres',
      password: process.env.PG_PASSWORD || 'password',
      autoLoadEntities: true,
      synchronize: true, // Set to false in production
    }),
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}

Repeat: Add similar health controllers for all services (auth-service, users-service, etc.), adjusting PG_HOST and PG_DATABASE per the table. For points-service, use MongooseModule.

3. Create SQL Files
Ensure SQL initialization files exist for each PostgreSQL database, as specified in the table.
Example: sql/core-service.sql
sqlCREATE TABLE IF NOT EXISTS rewards (
  id SERIAL PRIMARY KEY,
  reward_id VARCHAR(50) UNIQUE NOT NULL,
  type VARCHAR(50) NOT NULL,
  value DECIMAL(10, 2) NOT NULL,
  language VARCHAR(10) DEFAULT 'en',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO rewards (reward_id, type, value, language) VALUES
  ('CUSTOM123', 'gift_card', 50.00, 'en'),
  ('CUSTOM123', 'gift_card', 50.00, 'es'),
  ('CUSTOM123', 'gift_card', 50.00, 'ar');

For rfm-service.sql (TimescaleDB):
sqlCREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE TABLE IF NOT EXISTS customer_rfm (
  id SERIAL PRIMARY KEY,
  customer_id VARCHAR(50) NOT NULL,
  recency INTEGER NOT NULL,
  frequency INTEGER NOT NULL,
  monetary DECIMAL(10, 2) NOT NULL,
  event_time TIMESTAMP NOT NULL,
  language VARCHAR(10) DEFAULT 'en'
);

SELECT create_hypertable('customer_rfm', 'event_time');

Create Files:
bashmkdir -p sql
touch sql/core-service.sql sql/auth-service.sql sql/users-service.sql sql/roles-service.sql sql/rfm-service.sql sql/referrals-service.sql sql/event-tracking-service.sql sql/admin-core-service.sql sql/admin-features-service.sql sql/campaign-service.sql sql/gamification-service.sql sql/products-service.sql

Add schema definitions for each service, supporting features like US-BI6 (Custom Rewards) and Phase 6 localization.

4. Test the Setup

Create .env File:
bashecho "DB_PASSWORD=secure_password" > .env
echo "SHOPIFY_API_KEY=your_shopify_key" >> .env
echo "AUTH0_DOMAIN=your_auth0_domain" >> .env
echo "ENCRYPTION_KEY=your_encryption_key" >> .env
echo "KLAVIYO_API_KEY=your_klaviyo_key" >> .env
echo "POSTSCRIPT_API_KEY=your_postscript_key" >> .env
echo "AWS_SES_ACCESS_KEY=your_aws_access_key" >> .env
echo "AWS_SES_SECRET_KEY=your_aws_secret_key" >> .env
echo "POSTHOG_API_KEY=your_posthog_key" >> .env
echo "SHOPIFY_APP_BRIDGE_KEY=your_shopify_bridge_key" >> .env

Start Docker Compose:
bashcd <project-root>
docker compose up -d

Verify Database Connections:

For PostgreSQL (e.g., core-service-db):
bashpsql -h localhost -p 5437 -U postgres -d loyalnest_core
Enter password (secure_password) and verify schema:
sql\dt
SELECT * FROM rewards;

For MongoDB (points-service-db):
bashmongosh "mongodb://localhost:5445/loyalnest_points"



Test Health Checks:

For each service (e.g., core-service):
bashcurl http://localhost:3002/api/health
Expected output:
json{ "status": "ok", "service": "core-service", "database": "connected" }



Verify Consul Registration:

Open http://localhost:8500 and check for services (e.g., core-service, auth-service, frontend) with “Passing” health checks.
Query:
bashcurl http://localhost:8500/v1/catalog/service/core-service
Expected output:
json[
  {
    "ServiceName": "core-service",
    "ServiceAddress": "core-service",
    "ServicePort": 3002,
    "ServiceTags": ["http", "api"],
    ...
  }
]



Test Localization (Phase 6):

Store configurations in Consul’s KV store:
bashcurl -X PUT -d '{"table_name": "rewards"}' http://localhost:8500/v1/kv/loyalnest/db/core/en
curl -X PUT -d '{"table_name": "مكافآت"}' http://localhost:8500/v1/kv/loyalnest/db/core/ar

Fetch in core-service (add to a controller):
typescriptimport { Controller, Get } from '@nestjs/common';
import Consul from 'consul';

@Controller('config')
export class ConfigController {
  @Get('i18n')
  async getConfig() {
    const consul = new Consul({ host: 'consul', port: 8500 });
    const lang = process.env.LANGUAGE || 'en';
    const dbConfig = await consul.kv.get(`loyalnest/db/core/${lang}`);
    return JSON.parse(dbConfig.Value);
  }
}




5. Notes

Security: Use a .env file for sensitive variables (DB_PASSWORD, API keys). In production, use a secrets manager or Consul KV store with ACLs.
Production: Remove database port mappings (e.g., 5437:5432) for security, relying on Docker DNS (core-service-db:5432). Configure Consul ACLs for access control.
Health Checks: Ensure /health endpoints return HTTP 200 for registrator to mark services as healthy. Adjust SERVICE_TAGS or add SERVICE_<PORT>_CHECK_HTTP=/api/health if needed.
Scalability: Dedicated databases and registrator support US-BI7 and US-BI8 by isolating workloads and enabling dynamic service discovery.
SQL Files: Create schema-specific .sql files for each service. For rfm-service, include TimescaleDB extensions.
Registrator Configuration: If services fail to register, add SERVICE_<PORT>_CHECK_INTERVAL=10s or SERVICE_<PORT>_CHECK_TIMEOUT=5s to environment variables for fine-tuned health checks.

References

: Gliderlabs Registrator documentation for Consul integration.
: Docker Compose with Registrator for service discovery.
: NestJS health checks for microservices.

This revised docker-compose.yml adds the registrator service, enabling automatic Consul registration for LoyalNest’s microservices while maintaining the dedicated database setup. Update your main.ts files to remove manual Consul registration, and let me know if you need help with SQL schemas, health check implementations, or further Consul configuration!



Update below documentation since audit-logs-service added and audit-logs table removed from users-service.

admincore_service_plan.markdown
project-plan.md
every service plan
loyalnest_phase3_roadmap.md
US-AM5: Access Logs - in user stories
features-must/should/could
rfm.md
microservice_design.md
system_architecture_and_specifications.md
resilience-config.md
grpc_call_flow.md
openapi_spec.md (every service)



** project-plan
** system_architecture_and_specifications
- update graphQL, dedicated database per service, new added audit-logs-service