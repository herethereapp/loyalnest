# LoyalNest Shopify App Kickstart Plan

## Objective
Launch Phase 1 of the LoyalNest Shopify app, delivering a scalable, production-ready foundation with core functionality (merchant onboarding, RFM analytics, loyalty points, Shopify integration with POS and checkout extensions), GDPR/CCPA compliance, and multilingual support for 22 languages (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ar`, `zh-CN`, etc.). This 6-week plan establishes a robust microservices architecture using an Nx monorepo, with enhancements for API aggregation, tenant isolation, and monitoring to support a 7–8 month TVP timeline.

## Scope
- **Core Features**: Merchant onboarding (Welcome Page, `US-MD1`), basic RFM analytics (`rfm_score_history`, `customer_segments`), loyalty points (`points_transactions`), Shopify integration (POS, checkout extensions via Rust/Wasm).
- **Compliance**: GDPR/CCPA support via `gdpr_requests` and `audit_logs` with tenant isolation.
- **Infrastructure**: Deploy microservices and database on a VPS (Ubuntu, Docker Compose, PostgreSQL with JSONB/range partitioning, Redis Cluster, Kafka, Loki, Grafana, Prometheus, Alertmanager) and set up a local dev environment (Nx, Docker Compose).
- **Architecture**: Define microservices (`api-gateway`, `auth`, `points`, `referrals`, `rfm_analytics`, `event_tracking`, `admin_core`, `admin_features`, `campaign`, `gamification`), APIs (REST, gRPC), and shared libraries (`grpc-clients`, `common`, `db`, `validation`).
- **Multilingual**: Support 22 languages with i18next.
- **Testing**: Jest (unit), Supertest (integration), Cypress (E2E), k6 (performance), with coverage reporting (Istanbul, Tarpaulin).
- **Monitoring/Logging**: Loki + Grafana for logs, Prometheus with Alertmanager for metrics, Sentry for error tracking.
- **Enhancements**: API Gateway, gRPC clients, secrets management, shared libraries, feature flags, rate limiting, tenant isolation.

## Project Structure
The project leverages an Nx monorepo for modularity and scalability, incorporating microservices, frontend, Shopify Functions (Rust/Wasm), shared libraries, and enhanced configurations for tenant isolation and monitoring. It aligns with `Internal_admin_module.md`, `rfm.md`, `system_architecture.md`, `user_stories.md`, and `wireframes.md`.

```
loyalnest/
├── /apps
│   ├── /api-gateway
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── gateway.controller.ts     # REST: /v1/api/*
│   │   │   ├── /services
│   │   │   │   ├── gateway.service.ts        # API aggregation, rate limiting
│   │   │   ├── /middleware
│   │   │   │   ├── tenant.middleware.ts      # Tenant isolation
│   │   │   ├── /tests
│   │   │   │   ├── gateway.test.ts           # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /auth-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── auth.controller.ts        # REST: /v1/api/auth
│   │   │   │   ├── auth.grpc.ts             # gRPC: /admin.v1/Auth
│   │   │   ├── /services
│   │   │   │   ├── auth.service.ts          # JWT, OAuth, GDPR logic
│   │   │   ├── /models
│   │   │   │   ├── auth.model.ts            # DB queries for auth
│   │   │   ├── /protos
│   │   │   │   ├── auth.proto              # gRPC definitions
│   │   │   ├── /tests
│   │   │   │   ├── auth.test.ts            # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /points-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── points.controller.ts     # REST: /v1/api/points
│   │   │   ├── /services
│   │   │   │   ├── points.service.ts        # Points earn/redeem logic
│   │   │   ├── /models
│   │   │   │   ├── points.model.ts          # DB queries for points_transactions
│   │   │   ├── /tests
│   │   │   │   ├── points.test.ts           # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /referrals-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── referrals.controller.ts  # REST: /v1/api/referrals
│   │   │   │   ├── klaviyo.controller.ts    # REST: /v1/api/integrations/klaviyo
│   │   │   │   ├── postscript.controller.ts # REST: /v1/api/integrations/postscript
│   │   │   ├── /services
│   │   │   │   ├── referrals.service.ts     # Referral logic
│   │   │   │   ├── klaviyo.service.ts       # SMS/email referral integration
│   │   │   │   ├── postscript.service.ts    # SMS referral integration
│   │   │   ├── /models
│   │   │   │   ├── referrals.model.ts       # DB queries for referrals
│   │   │   ├── /tests
│   │   │   │   ├── referrals.test.ts        # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /rfm_analytics-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── rfm.controller.ts        # REST: /v1/api/rfm
│   │   │   ├── /services
│   │   │   │   ├── rfm.service.ts           # RFM calculation logic
│   │   │   ├── /models
│   │   │   │   ├── rfm.model.ts             # DB queries for rfm_score_history
│   │   │   ├── /tests
│   │   │   │   ├── rfm.test.ts              # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /event_tracking-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── event.controller.ts      # REST: /v1/api/events
│   │   │   ├── /services
│   │   │   │   ├── event.service.ts         # Event tracking with Kafka
│   │   │   ├── /models
│   │   │   │   ├── event.model.ts           # DB queries for events
│   │   │   ├── /tests
│   │   │   │   ├── event.test.ts            # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /admin_core-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── admin.controller.ts      # REST: /v1/api/admin
│   │   │   │   ├── admin.grpc.ts            # gRPC: /admin.v1/Admin
│   │   │   ├── /services
│   │   │   │   ├── admin.service.ts         # Core admin logic
│   │   │   ├── /models
│   │   │   │   ├── admin.model.ts           # DB queries for merchants
│   │   │   ├── /protos
│   │   │   │   ├── admin.proto             # gRPC definitions
│   │   │   ├── /tests
│   │   │   │   ├── admin.test.ts           # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /admin_features-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── features.controller.ts   # REST: /v1/api/features
│   │   │   ├── /services
│   │   │   │   ├── features.service.ts      # Admin features (e.g., notification templates, feature flags)
│   │   │   ├── /models
│   │   │   │   ├── features.model.ts        # DB queries for admin features
│   │   │   ├── /tests
│   │   │   │   ├── features.test.ts         # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /campaign-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── campaign.controller.ts   # REST: /v1/api/campaigns
│   │   │   ├── /services
│   │   │   │   ├── campaign.service.ts      # Campaign discount logic
│   │   │   ├── /models
│   │   │   │   ├── campaign.model.ts        # DB queries for campaigns
│   │   │   ├── /tests
│   │   │   │   ├── campaign.test.ts         # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /gamification-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── gamification.controller.ts # REST: /v1/api/gamification
│   │   │   ├── /services
│   │   │   │   ├── gamification.service.ts  # Lightweight gamification logic
│   │   │   ├── /models
│   │   │   │   ├── gamification.model.ts    # DB queries for gamification
│   │   │   ├── /tests
│   │   │   │   ├── gamification.test.ts     # Jest/Supertest tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .env
│   ├── /frontend
│   │   ├── /src
│   │   │   ├── /components
│   │   │   │   ├── WelcomePage.jsx          # US-MD1: Merchant onboarding
│   │   │   │   ├── RFMDashboard.jsx         # RFM analytics display
│   │   │   │   ├── PointsManager.jsx        # Points configuration
│   │   │   │   ├── ReferralStatus.jsx       # Progress bar for referrals
│   │   │   │   ├── GDPRRequestForm.jsx      # GDPR/CCPA request form
│   │   │   │   ├── CampaignManager.jsx      # Campaign configuration
│   │   │   ├── /locales
│   │   │   │   ├── en.json                 # i18next translations
│   │   │   │   ├── es.json
│   │   │   │   ├── fr.json
│   │   │   │   ├── ...                     # 22 languages
│   │   │   ├── /styles
│   │   │   │   ├── tailwind.css            # Tailwind CSS
│   │   │   ├── /tests
│   │   │   │   ├── WelcomePage.test.jsx     # Jest unit tests
│   │   │   │   ├── RFMDashboard.test.jsx
│   │   │   ├── App.jsx
│   │   │   ├── index.jsx
│   │   ├── /cypress
│   │   │   ├── /e2e
│   │   │   │   ├── onboarding.cy.js         # Cypress E2E tests
│   │   │   │   ├── rfm.cy.js
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── .eslintrc.cjs
│   │   ├── .prettierrc
│   │   ├── eslint.config.json
│   │   ├── tsconfig.json
│   │   ├── tsconfig.node.json
│   │   ├── vite.config.ts
│   │   ├── .env
├── /libs
│   ├── /shopify-functions
│   │   ├── /src
│   │   │   ├── checkout.rs                 # Rust/Wasm for checkout extensions
│   │   │   ├── pos.rs                      # Rust/Wasm for POS integration
│   │   ├── /tests
│   │   │   ├── checkout.test.rs            # Rust unit tests
│   │   ├── Cargo.toml
│   ├── /grpc-clients
│   │   ├── /src
│   │   │   ├── auth.client.ts             # gRPC client for auth-service
│   │   │   ├── admin.client.ts            # gRPC client for admin_core-service
│   │   │   ├── proto
│   │   │   │   ├── auth.proto            # gRPC definitions
│   │   │   │   ├── admin.proto           # gRPC definitions
│   │   ├── package.json
│   ├── /common
│   │   ├── /src
│   │   │   ├── logger.ts                  # Winston logger with Loki
│   │   │   ├── error.handler.ts           # Centralized error handling
│   │   ├── package.json
│   ├── /db
│   │   ├── /src
│   │   │   ├── typeorm.config.ts          # Shared TypeORM setup
│   │   ├── package.json
│   ├── /validation
│   │   ├── /src
│   │   │   ├── dtos
│   │   │   │   ├── points.dto.ts         # DTOs for points
│   │   │   │   ├── referral.dto.ts       # DTOs for referrals
│   │   ├── package.json
├── /database
│   ├── /migrations
│   │   ├── core_schema.sql                 # merchants, customers, points_transactions
│   │   ├── auxiliary_schema.sql            # integrations, audit_logs, gdpr_requests, feature_flags
│   ├── /seeds
│   │   ├── mock_data.sql                   # Faker-generated mock data
│   ├── /triggers
│   │   ├── trigger_audit_log.sql           # Audit log trigger
│   │   ├── trg_updated_at.sql              # Timestamp update trigger
├── /docs
│   ├── Internal_admin_module.md             # Admin module details
│   ├── project_plan.md                      # 7–8 month TVP plan
│   ├── rfm.md                              # RFM analytics details
│   ├── system_architecture.md               # Microservices architecture
│   ├── user_stories.md                     # User stories for features
│   ├── wireframes.md                       # UI/UX wireframes
│   ├── deploy.md                           # Deployment guide
│   ├── architecture_diagram.drawio         # Microservices and data flows
├── /scripts
│   ├── dev.sh                              # Local dev setup script
│   ├── deploy.sh                           # Deployment script
├── /config
│   ├── docker-compose.yml                  # Local dev and staging
│   ├── nginx.conf                          # Nginx configuration
│   ├── openapi.yaml                        # REST API specs
│   ├── prometheus.yml                      # Prometheus config
│   ├── alertmanager.yml                    # Alertmanager config
│   ├── grafana.ini                         # Grafana config
│   ├── k6
│   │   ├── load_test.js                    # k6 performance tests
├── /.github
│   ├── /workflows
│   │   ├── ci.yml                         # CI/CD pipeline
├── /backend
│   ├── .gitignore                          # Node.js ignores
│   ├── .prettierrc                         # Formatting rules
│   ├── eslint.config.mjs                   # Linting rules
│   ├── nest-cli.json                       # NestJS CLI config
│   ├── tsconfig.json                       # TypeScript config
│   ├── tsconfig.build.json                 # Build config
│   ├── .nycrc                              # Istanbul coverage config
├── /frontend
│   ├── .gitignore                          # Node.js ignores
│   ├── .prettierrc                         # Formatting rules
│   ├── .eslintrc.cjs                       # Legacy ESLint config
│   ├── eslint.config.json                   # ESLint config
│   ├── tsconfig.base.json                  # Base TypeScript config
│   ├── tsconfig.json                       # Frontend TypeScript config
│   ├── tsconfig.node.json                  # Node-specific TypeScript config
├── nx.json                                 # Nx monorepo config
├── README.md                               # Project setup instructions
├── .gitignore                              # Root-level ignores
├── package.json                            # Root-level dependencies
```

- **Apps**: Nx monorepo organizes microservices (`api-gateway`, `auth`, `points`, `referrals`, `rfm_analytics`, `event_tracking`, `admin_core`, `admin_features`, `campaign`, `gamification`) using NestJS (TypeScript) with REST/gRPC APIs, and the frontend with React, Shopify Polaris, and Tailwind CSS.
- **Libs**: Includes Rust/Wasm for Shopify Functions, gRPC clients, shared utilities, database setup, and validation DTOs.
- **Database**: PostgreSQL schemas with JSONB, range partitioning, and `feature_flags` for A/B testing.
- **Docs**: Retains referenced documentation, updated with API Gateway and tenant isolation details.
- **Scripts**: Setup (`dev.sh`) and deployment (`deploy.sh`) scripts.
- **Config**: Includes Docker Compose, Nginx, OpenAPI, Prometheus, Alertmanager, Grafana, and k6 configurations.
- **CI/CD**: GitHub Actions for automated testing and deployment.

## Timeline: 6 Weeks (July 21, 2025 – August 31, 2025)

### Week 1: Project Setup, Local Dev Environment, and Architecture Planning
- **Tasks**:
  - **Repository Setup**:
    - Initialize GitHub repository with Nx monorepo (`nx.json`) and CI/CD pipelines (`/.github/workflows/ci.yml`).
    - Create `README.md`, contribution guidelines, and root `.gitignore` for Node.js, Rust, and Docker.
    - Configure `/backend/.nycrc` for Istanbul coverage reporting.
  - **Team Roles**:
    - Assign 1 PM, 2 backend developers (NestJS, Rust), 2 frontend developers (React, Polaris), 1 QA engineer, 1 DevOps engineer.
    - Document roles and task board (Jira/Trello).
  - **Local Dev Environment**:
    - Create `/config/docker-compose.yml` for local setup (NestJS, React, PostgreSQL 15 with JSONB/range partitioning, Redis Cluster, Kafka, Loki, Grafana, Prometheus, Alertmanager).
    - Develop `/scripts/dev.sh` for Nx setup, mock data seeding (Faker in `/database/seeds/mock_data.sql`), and database migrations.
    - Test local environment with `nx serve` for frontend and microservices.
    - Document setup in `README.md` (e.g., “Run `./scripts/dev.sh up` to start local dev”).
  - **VPS Deployment**:
    - Deploy VPS (Ubuntu) with Docker Compose, PostgreSQL 15, Redis Cluster, Kafka, Loki, Grafana, Prometheus, Alertmanager, Nginx.
    - Apply `/database/migrations/core_schema.sql` (`merchants`, `customers`, `points_transactions`, `rfm_score_history`, `customer_segments`, `program_settings`) and `/database/migrations/auxiliary_schema.sql` (`integrations`, `audit_logs`, `gdpr_requests`, `email_templates`, `referrals`, `campaigns`, `feature_flags`), ensuring `merchant_id` FK for tenant isolation.
    - Verify triggers (`trigger_audit_log`, `trg_updated_at`).
  - **Project Architecture**:
    - Define microservices: `api-gateway` (`/v1/api/*`), `auth` (`/admin.v1/Auth`), `points` (`/v1/api/points`), `referrals` (`/v1/api/referrals`), `rfm_analytics` (`/v1/api/rfm`), `event_tracking` (`/v1/api/events`), `admin_core` (`/admin.v1/Admin`), `admin_features` (`/v1/api/features`), `campaign` (`/v1/api/campaigns`), `gamification` (`/v1/api/gamification`).
    - Specify APIs: REST (`/v1/api/*` via `api-gateway`, OpenAPI in `/config/openapi.yaml`), gRPC (`/admin.v1/*` in `/apps/*/protos` and `/libs/grpc-clients`).
    - Design database schemas with JSONB and range partitioning; add `feature_flags` table for A/B testing.
    - Plan inter-service communication: Kafka for events (`points.earned`, `customer.updated`, `referral.created`), Redis Cluster/Streams for caching (`points:{customer_id}`) and Bull queues.
    - Set up shared libraries: `/libs/common` (logger, error handling), `/libs/db` (TypeORM config), `/libs/validation` (DTOs), `/libs/grpc-clients` (gRPC stubs).
    - Configure monitoring: Loki + Grafana for logs, Prometheus with Alertmanager for metrics, Sentry for errors.
    - Create architecture diagram (`/docs/architecture_diagram.drawio`) with microservices, API Gateway, and data flows.
  - **Secrets Management**:
    - Add `.env` files to each microservice (`/apps/*/`) for database URLs, API keys, etc.
    - Use `@nestjs/config` for environment variable management.
  - **Tech Stack**:
    - NestJS (TypeScript, gRPC/REST), React (Polaris, Tailwind CSS), Rust/Wasm (Shopify Functions), i18next, PostgreSQL (JSONB, range partitioning), Redis Cluster/Streams, Kafka, Bull, Loki, Grafana, Prometheus, Alertmanager, Sentry.
    - Use AI tools: Grok (architecture docs), Copilot (TypeScript/Rust, tests), Cursor (setup scripts).
- **Deliverables**:
  - Nx monorepo with `README.md`, guidelines, and CI/CD setup.
  - Local dev environment (`/config/docker-compose.yml`, `/scripts/dev.sh`) with documentation.
  - VPS with PostgreSQL, Redis Cluster, Kafka, Loki, Grafana, Prometheus, Alertmanager.
  - Architecture diagram, API specs (`/config/openapi.yaml`, gRPC protos), schemas, and shared libraries (`/libs/common`, `/libs/db`, `/libs/validation`, `/libs/grpc-clients`).
  - Team onboarding document and task board.
- **Resources**: PM, DevOps, backend developers, frontend developers.
- **AI Tools**: Grok (architecture, secrets docs), Copilot (shared libraries, TypeScript/Rust), Cursor (Docker setup).

### Week 2: Database, Microservices Foundation, and API Gateway
- **Tasks**:
  - **Database Setup**:
    - Validate `/database/migrations/core_schema.sql` and `/database/migrations/auxiliary_schema.sql`, ensuring `merchant_id` FK for tenant isolation.
    - Add indexes (e.g., `customers(email, merchant_id)`, `points_transactions(customer_id, merchant_id)`).
    - Implement range partitioning on `points_transactions` and `rfm_score_history`.
    - Test triggers (`/database/triggers/trigger_audit_log.sql`, `/database/triggers/trg_updated_at.sql`) with mock data (Faker).
  - **Microservices**:
    - API Gateway (`/apps/api-gateway`): Implement REST routing (`/v1/api/*`), rate limiting, and tenant middleware.
    - Auth Service (`/apps/auth-service`): JWT/OAuth, GDPR request processing (gRPC: `/admin.v1/Auth/Login`, REST: `/v1/api/auth/login`).
    - Points Service (`/apps/points-service`): CRUD for `points_transactions` (REST: `/v1/api/points/earn`, `/v1/api/points/redeem`).
    - Referrals Service (`/apps/referrals-service`): Manage referrals with Klaviyo/Postscript (REST: `/v1/api/referrals`, `/v1/api/integrations/klaviyo`).
    - RFM Analytics Service (`/apps/rfm_analytics-service`): Calculate RFM scores (REST: `/v1/api/rfm`).
    - Event Tracking Service (`/apps/event_tracking-service`): Log events to Kafka (REST: `/v1/api/events`).
    - Admin Core Service (`/apps/admin_core-service`): CRUD for `merchants` (gRPC: `/admin.v1/Admin/Get`, REST: `/v1/api/admin`).
    - Admin Features Service (`/apps/admin_features-service`): Notification templates, live previews (REST: `/v1/api/features`).
    - Campaign Service (`/apps/campaign-service`): Manage campaign discounts (REST: `/v1/api/campaigns`).
    - Gamification Service (`/apps/gamification-service`): Lightweight gamification (REST: `/v1/api/gamification`).
  - **API Gateway**:
    - Configure `/apps/api-gateway/src/main.ts` with `express-rate-limit` and tenant middleware:
      ```typescript
      import { NestFactory } from '@nestjs/core';
      import * as rateLimit from 'express-rate-limit';
      async function bootstrap() {
        const app = await NestFactory.create(AppModule);
        app.use((req, res, next) => {
          const merchantId = req.headers['x-merchant-id'];
          if (!merchantId) throw new UnauthorizedException('Merchant ID required');
          req.tenant = { merchantId };
          next();
        });
        app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
        await app.listen(3000);
      }
      bootstrap();
      ```
  - **gRPC Clients**:
    - Implement `/libs/grpc-clients/src/auth.client.ts` for inter-service communication:
      ```typescript
      import { ClientGrpc } from '@nestjs/microservices';
      export class AuthClient {
        private client: any;
        constructor() {
          this.client = new ClientGrpc({ url: 'auth-service:50051', package: 'admin.v1', protoPath: 'proto/auth.proto' });
        }
        getAuthService() {
          return this.client.getService('AuthService');
        }
      }
      ```
  - **Task Queue**:
    - Set up Bull queues (Redis Cluster) for async tasks (e.g., RFM calculations, referral processing) in `/apps/*/services`.
    - Create `queue_tasks` table for task tracking.
  - **Rate Limiting**:
    - Apply `express-rate-limit` in microservices (e.g., `referrals-service`, `event_tracking-service`) for Shopify API compliance.
  - **Security**:
    - Encrypt sensitive fields (`integrations.api_key`, `email_templates.recipient_email`) with AWS KMS or pgcrypto (AES-256).
  - **Monitoring**:
    - Configure Prometheus metrics (`/config/prometheus.yml`), Loki logging (`/config/grafana.ini`), Alertmanager (`/config/alertmanager.yml`), and Sentry for errors.
  - **Testing**:
    - Jest unit tests for microservices (80%+ coverage) in `/apps/*/tests`.
    - Test database migrations in local dev environment.
  - **AI Tools**: Copilot for microservice boilerplate, rate limiting, and gRPC clients; Grok for schema validation and test cases.
- **Deliverables**:
  - Deployed microservices with CRUD APIs (local and VPS).
  - API Gateway with rate limiting and tenant middleware.
  - Redis Cluster-based task queue and gRPC clients in `/libs/grpc-clients`.
  - Database migration scripts and test reports.
  - Prometheus, Loki, Grafana, Alertmanager, and Sentry setups.
- **Resources**: Backend developers, DevOps, QA engineer.
- **Dependencies**: Week 1 local dev environment, schemas, and shared libraries.

### Week 3: Welcome Page and Onboarding UI
- **Tasks**:
  - Develop Welcome Page (`US-MD1`, `/apps/frontend/src/components/WelcomePage.jsx`) in React with Polaris and Tailwind CSS:
    - Polaris `Card` for setup tasks (e.g., “Configure Points Program,” “Connect Shopify”).
    - Polaris `Banner` for congratulatory/error messages.
    - ARIA labels (`aria-label="Complete setup tasks"`) and RTL support for `ar`, `he`.
    - i18next for 22 languages (`/apps/frontend/src/locales/*.json`).
  - Integrate with `/v1/api/admin` (via API Gateway) for setup tasks.
  - Log setup task completions to `/apps/event_tracking-service` (Kafka) and PostHog (`setup_task_completed` event).
  - Test UI:
    - Jest unit tests for components (`/apps/frontend/src/tests`) and i18next fallbacks.
    - Cypress E2E tests for onboarding flow and language switching (`/apps/frontend/cypress/e2e`).
  - Run in local dev environment (`./scripts/dev.sh up`).
  - **AI Tools**: Cursor for React components, Grok for translation templates and PostHog/Kafka event definitions.
- **Deliverables**:
  - Functional Welcome Page with multilingual support.
  - Unit and E2E test suites.
  - PostHog and Kafka integration for analytics.
- **Resources**: Frontend developers, QA engineer.
- **Dependencies**: Week 2 microservices, API Gateway, and i18next setup.

### Week 4: RFM Analytics, Loyalty Basics, and Shopify Functions
- **Tasks**:
  - **RFM Analytics**:
    - Implement RFM calculation logic (NestJS) in `/apps/rfm_analytics-service/src/services/rfm.service.ts` for `rfm_score_history` and `customer_segments`.
    - Use Bull queues (Redis Cluster) for incremental updates triggered by `points_transactions`.
    - Store results in `rfm_segment_counts` (materialized view with daily refresh).
  - **Loyalty Points**:
    - Implement CRUD for `points_transactions` in `/apps/points-service` (REST: `/v1/api/points/earn`, `/v1/api/points/redeem`).
    - Validate against `program_settings` (JSONB, e.g., `points_per_dollar: 10`).
  - **Shopify Integration**:
    - Configure `integrations` table (`platform = 'shopify'`) for Shopify API, including POS and checkout extensions.
    - Implement Rust/Wasm Shopify Functions in `/libs/shopify-functions/src` for checkout extensions (`checkout.rs`) and POS (`pos.rs`).
    - Sync customer data to `customers` table via Shopify API (`customers/list`).
  - **Feature Flags**:
    - Implement `feature_flags` table and logic in `/apps/admin_features-service` for A/B testing (e.g., gamification features).
  - **Testing**:
    - Jest unit tests for RFM logic, points transactions, and Rust/Wasm functions (`/apps/*/tests`, `/libs/shopify-functions/tests`).
    - Cypress E2E tests for Shopify sync and POS integration (`/apps/frontend/cypress/e2e`).
    - k6 performance tests for RFM calculations (1,000 customers) in `/config/k6`.
  - **AI Tools**: Copilot for RFM algorithms, Rust code, and feature flag logic; Grok for test data generation.
- **Deliverables**:
  - RFM calculation microservice with async task support.
  - Loyalty points API endpoints.
  - Shopify integration with Rust/Wasm Functions.
  - Feature flag implementation for A/B testing.
  - Test reports (unit, E2E, performance).
- **Resources**: Backend developers, QA engineer.
- **Dependencies**: Week 2 microservices, database, and API Gateway.

### Week 5: Compliance, Testing, and Code Quality
- **Tasks**:
  - **GDPR/CCPA Workflows**:
    - Process `gdpr_requests` (`type = 'data_request', 'redact'`) via Bull queues in `/apps/auth-service` and `/apps/admin_core-service`, ensuring tenant isolation with `merchant_id`.
    - Log redactions to `gdpr_redaction_log` and `audit_logs` via `/apps/event_tracking-service`.
  - **Testing**:
    - Jest unit tests for microservices (`/apps/*/tests`) with 80%+ coverage (Istanbul).
    - Supertest integration tests for REST APIs (e.g., `/v1/api/points/earn`) in `/apps/*/tests`.
    - gRPC tests for inter-service communication using `/libs/grpc-clients`.
    - Cypress E2E tests for Welcome Page, Shopify sync, and GDPR workflows (`/apps/frontend/cypress/e2e`).
    - k6 performance tests for 1,000 concurrent users (`/config/k6`).
    - Validate multilingual support (e.g., `email_templates.subject`, `vip_tiers.name`) for 22 languages with i18next.
    - Run Clippy on Rust code in `/libs/shopify-functions` for code quality.
  - **Monitoring**:
    - Verify Prometheus metrics, Loki + Grafana logs, Alertmanager alerts, and Sentry error tracking.
  - **Code Quality**:
    - Configure Istanbul coverage in `/backend/.nycrc`:
      ```json
      {
        "reporter": ["html", "lcov"],
        "include": ["src/**/*.ts"],
        "exclude": ["**/*.test.ts"]
      }
      ```
    - Run Clippy: `cargo clippy --all-targets --all-features` in `/libs/shopify-functions`.
  - **Local Dev Testing**:
    - Verify all components in local dev environment (`./scripts/dev.sh up`).
  - **AI Tools**: Grok for GDPR workflow documentation, Copilot for test suites and coverage reports.
- **Deliverables**:
  - GDPR/CCPA-compliant workflows with audit logging and tenant isolation.
  - Test reports (unit, integration, E2E, performance, coverage).
  - Multilingual validation report.
  - Monitoring setup validation.
- **Resources**: Backend developers, QA engineer, frontend developers.
- **Dependencies**: Week 3 Welcome Page, Week 4 RFM, points, and feature flags.

### Week 6: Deployment and Merchant Feedback
- **Tasks**:
  - Deploy app to staging VPS (Docker Compose, PostgreSQL, Redis Cluster, Kafka, Loki, Grafana, Prometheus, Alertmanager, Nginx) using `/scripts/deploy.sh`.
  - Test deployment in local dev environment before staging push.
  - Conduct merchant beta testing with 5–10 Shopify merchants:
    - Share staging URL and collect feedback on Welcome Page, onboarding, RFM analytics, points transactions, and referral status via “LoyalNest Collective” Slack and Google Forms.
    - Target 80%+ satisfaction for onboarding flow.
  - Fix bugs and refine UI based on feedback.
  - Document setup and deployment process (`/docs/deploy.md`) for production, including API Gateway and tenant isolation.
  - **AI Tools**: Grok for feedback summarization and bug prioritization.
- **Deliverables**:
  - Staging environment on VPS.
  - Merchant feedback report and bug fixes.
  - Deployment guide (`/docs/deploy.md`).
- **Resources**: PM, DevOps, QA engineer, frontend/backend developers.
- **Dependencies**: Week 5 testing and compliance.

## Resources
- **Team**: 1 PM, 2 backend developers (NestJS, Rust), 2 frontend developers (React, Polaris), 1 QA engineer, 1 DevOps engineer.
- **Tools**:
  - Development: NestJS (TypeScript, gRPC/REST), React (Polaris, Tailwind CSS), Rust/Wasm (Shopify Functions), i18next.
  - Database: PostgreSQL 15 (JSONB, range partitioning), Redis Cluster/Streams (Bull).
  - Messaging: Kafka.
  - Testing: Jest, Supertest, Cypress, k6, Istanbul, Tarpaulin.
  - Analytics: PostHog.
  - Monitoring: Loki, Grafana, Prometheus, Alertmanager, Sentry.
  - Infrastructure: VPS (Ubuntu), Docker Compose, Nginx.
  - AI: Grok (docs, translations), Copilot (TypeScript/Rust, tests), Cursor (setup scripts).
- **Budget Estimate**: ~$30,000 (6 weeks, 7 team members, ~$100/hour).

## Success Criteria
- Functional Welcome Page (`US-MD1`) with 22-language support and Shopify integration (POS, checkout extensions).
- Deployed microservices (`api-gateway`, `auth`, `points`, `referrals`, `rfm_analytics`, `event_tracking`, `admin_core`, `admin_features`, `campaign`, `gamification`) with async task processing and tenant isolation.
- RFM analytics calculating scores for 1,000+ sample customers.
- GDPR/CCPA-compliant workflows with audit logging and tenant-specific data.
- Passing test suites (90%+ unit test coverage, 100% E2E test pass rate, k6 for 1,000 concurrent users).
- Operational monitoring with Loki, Grafana, Prometheus, Alertmanager, and Sentry.
- Positive feedback from 5+ beta merchants (80%+ satisfaction).

## Risks and Mitigation
- **Risk**: Nx monorepo setup complexity.
  - **Mitigation**: Use Nx CLI for scaffolding; document in `README.md` and `/scripts/dev.sh`.
- **Risk**: Rust/Wasm integration issues with Shopify Functions.
  - **Mitigation**: Test Rust/Wasm locally with Shopify’s Wasm SDK; use Clippy for code quality.
- **Risk**: Schema issues (e.g., missing constraints).
  - **Mitigation**: Validate schemas with range partitioning and `merchant_id` FK; test triggers with mock data.
- **Risk**: Multilingual support gaps.
  - **Mitigation**: Use i18next with `en` fallback; validate translations in Week 5 with native speakers via Slack.
- **Risk**: Shopify API rate limits.
  - **Mitigation**: Implement rate-limiting in `api-gateway` and `referrals-service`; cache in Redis Cluster.
- **Risk**: Performance bottlenecks in RFM or event tracking.
  - **Mitigation**: Use Bull queues, Kafka, and optimized queries with indexes and range partitioning.
- **Risk**: API Gateway complexity.
  - **Mitigation**: Start with simple routing in Week 2; incrementally add features like rate limiting and tenant middleware.

## Next Steps
- Approve kickstart plan and allocate resources.
- Schedule kickoff meeting for July 21, 2025.
- Begin Week 1 tasks: Nx monorepo setup, local dev environment, VPS deployment, shared libraries, and architecture planning.