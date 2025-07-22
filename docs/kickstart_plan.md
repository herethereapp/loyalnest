# LoyalNest Shopify App Kickstart Plan

## Objective
Launch Phase 1 of the LoyalNest Shopify app, focusing on core functionality (merchant onboarding, RFM analytics setup, loyalty points, Shopify integration with POS and checkout extensions), GDPR/CCPA compliance, multilingual support for 22 languages (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ar`, `zh-CN`, etc.), and a robust project architecture. This 6-week plan establishes a scalable, production-ready foundation using an Nx monorepo, with a local development environment to streamline team workflows.

## Scope
- **Core Features**: Merchant onboarding (Welcome Page, `US-MD1`), basic RFM analytics (`rfm_score_history`, `customer_segments`), loyalty points (`points_transactions`), Shopify integration (POS, checkout extensions via Rust/Wasm).
- **Compliance**: GDPR/CCPA support via `gdpr_requests` and `audit_logs`.
- **Infrastructure**: Deploy core microservices and database on a VPS (Ubuntu, Docker Compose, PostgreSQL with JSONB and range partitioning, Redis Cluster) and set up a local dev environment (Nx, Docker Compose).
- **Architecture**: Define microservices (`auth`, `points`, `referrals`, `rfm_analytics`, `event_tracking`, `admin_core`, `admin_features`, `campaign`, `gamification`), APIs (REST, gRPC), and database schemas (`core_schema.sql`, `auxiliary_schema.sql`).
- **Multilingual**: Support 22 languages with i18next integration.
- **Testing**: Jest (unit), Cypress (E2E), k6 (performance) for critical flows.
- **Monitoring/Logging**: Loki + Grafana for logs, Prometheus for metrics, Sentry for error tracking.

## Project Structure
The project structure leverages an Nx monorepo for modularity and scalability, organizing microservices, frontend, Shopify Functions (Rust/Wasm), and supporting configurations. It aligns with `Internal_admin_module.md`, `rfm.md`, `system_architecture.md`, `user_stories.md`, and `wireframes.md`.

```
loyalnest/
├── /apps
│   ├── /auth-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── auth.controller.ts        # REST: /v1/api/auth
│   │   │   │   ├── auth.grpc.ts             # gRPC: /admin.v1/Auth
│   │   │   ├── /services
│   │   │   │   ├── auth.service.ts          # JWT, OAuth logic
│   │   │   ├── /models
│   │   │   │   ├── auth.model.ts            # DB queries for auth
│   │   │   ├── /protos
│   │   │   │   ├── auth.proto              # gRPC definitions
│   │   │   ├── /tests
│   │   │   │   ├── auth.test.ts            # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   ├── /points-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── points.controller.ts     # REST: /v1/api/points
│   │   │   ├── /services
│   │   │   │   ├── points.service.ts        # Points earn/redeem logic
│   │   │   ├── /models
│   │   │   │   ├── points.model.ts          # DB queries for points_transactions
│   │   │   ├── /tests
│   │   │   │   ├── points.test.ts           # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
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
│   │   │   │   ├── referrals.test.ts        # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   ├── /rfm_analytics-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── rfm.controller.ts        # REST: /v1/api/rfm
│   │   │   ├── /services
│   │   │   │   ├── rfm.service.ts           # RFM calculation logic
│   │   │   ├── /models
│   │   │   │   ├── rfm.model.ts             # DB queries for rfm_score_history
│   │   │   ├── /tests
│   │   │   │   ├── rfm.test.ts              # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   ├── /event_tracking-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── event.controller.ts      # REST: /v1/api/events
│   │   │   ├── /services
│   │   │   │   ├── event.service.ts         # Event tracking with Kafka
│   │   │   ├── /models
│   │   │   │   ├── event.model.ts           # DB queries for events
│   │   │   ├── /tests
│   │   │   │   ├── event.test.ts            # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
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
│   │   │   │   ├── admin.test.ts           # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   ├── /admin_features-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── features.controller.ts   # REST: /v1/api/features
│   │   │   ├── /services
│   │   │   │   ├── features.service.ts      # Admin features (e.g., notification templates)
│   │   │   ├── /models
│   │   │   │   ├── features.model.ts        # DB queries for admin features
│   │   │   ├── /tests
│   │   │   │   ├── features.test.ts         # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   ├── /campaign-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── campaign.controller.ts   # REST: /v1/api/campaigns
│   │   │   ├── /services
│   │   │   │   ├── campaign.service.ts      # Campaign discount logic
│   │   │   ├── /models
│   │   │   │   ├── campaign.model.ts        # DB queries for campaigns
│   │   │   ├── /tests
│   │   │   │   ├── campaign.test.ts         # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
│   ├── /gamification-service
│   │   ├── /src
│   │   │   ├── /controllers
│   │   │   │   ├── gamification.controller.ts # REST: /v1/api/gamification
│   │   │   ├── /services
│   │   │   │   ├── gamification.service.ts  # Lightweight gamification logic
│   │   │   ├── /models
│   │   │   │   ├── gamification.model.ts    # DB queries for gamification
│   │   │   ├── /tests
│   │   │   │   ├── gamification.test.ts     # Jest unit tests
│   │   ├── Dockerfile
│   │   ├── package.json
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
├── /libs
│   ├── /shopify-functions
│   │   ├── /src
│   │   │   ├── checkout.rs                 # Rust/Wasm for checkout extensions
│   │   │   ├── pos.rs                      # Rust/Wasm for POS integration
│   │   ├── /tests
│   │   │   ├── checkout.test.rs            # Rust unit tests
│   │   ├── Cargo.toml                      # Rust dependencies
├── /database
│   ├── /migrations
│   │   ├── core_schema.sql                 # merchants, customers, points_transactions
│   │   ├── auxiliary_schema.sql            # integrations, audit_logs, gdpr_requests
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
│   ├── grafana.ini                         # Grafana config
│   ├── k6
│   │   ├── load_test.js                    # k6 performance tests
├── /.github
│   ├── /workflows
│   │   ├── ci.yml                         # CI/CD pipeline
├── nx.json                                 # Nx monorepo config
├── README.md                               # Project setup instructions
├── .gitignore                              # Node.js, Rust, Docker ignores
├── package.json                            # Root-level dependencies
```

- **Apps**: Nx monorepo organizes microservices (`auth`, `points`, `referrals`, `rfm_analytics`, `event_tracking`, `admin_core`, `admin_features`, `campaign`, `gamification`) using NestJS (TypeScript) with REST/gRPC APIs, and the frontend with React, Shopify Polaris, and Tailwind CSS.
- **Libs**: Contains Rust/Wasm code for Shopify Functions (e.g., checkout extensions, POS integration) in `/libs/shopify-functions`.
- **Database**: Includes PostgreSQL schemas with JSONB and range partitioning, plus triggers and mock data.
- **Docs**: Retains referenced documentation files, with a deployment guide and architecture diagram.
- **Scripts**: Setup (`dev.sh`) and deployment (`deploy.sh`) scripts for streamlined workflows.
- **Config**: Centralizes Docker Compose, Nginx, OpenAPI, Prometheus, Grafana, and k6 configurations.
- **CI/CD**: GitHub Actions for automated testing and deployment.

## Timeline: 6 Weeks (July 21, 2025 – August 31, 2025)

### Week 1: Project Setup, Local Dev Environment, and Architecture Planning
- **Tasks**:
  - **Repository Setup**:
    - Initialize GitHub repository with Nx monorepo (`nx.json`) and CI/CD pipelines (`/.github/workflows/ci.yml`).
    - Create `README.md`, contribution guidelines, and `.gitignore` for Node.js, Rust, and Docker.
  - **Team Roles**:
    - Assign 1 PM, 2 backend developers (NestJS, Rust), 2 frontend developers (React, Polaris), 1 QA engineer, 1 DevOps engineer.
    - Document roles and task board (Jira/Trello).
  - **Local Dev Environment**:
    - Create `/config/docker-compose.yml` for local setup (NestJS, React, PostgreSQL 15 with JSONB/range partitioning, Redis Cluster, Kafka, Loki, Grafana, Prometheus).
    - Develop `/scripts/dev.sh` for Nx setup, mock data seeding (Faker in `/database/seeds/mock_data.sql`), and database migrations.
    - Test local environment with `nx serve` for frontend and microservices.
    - Document setup in `README.md` (e.g., “Run `./scripts/dev.sh up` to start local dev”).
  - **VPS Deployment**:
    - Deploy VPS (Ubuntu) with Docker Compose, PostgreSQL 15, Redis Cluster, Kafka, Loki, Grafana, Prometheus, Nginx.
    - Apply `/database/migrations/core_schema.sql` and `/database/migrations/auxiliary_schema.sql`, verify triggers (`trigger_audit_log`, `trg_updated_at`).
  - **Project Architecture**:
    - Define microservices: `auth` (`/admin.v1/Auth`), `points` (`/v1/api/points`), `referrals` (`/v1/api/referrals`), `rfm_analytics` (`/v1/api/rfm`), `event_tracking` (`/v1/api/events`), `admin_core` (`/admin.v1/Admin`), `admin_features` (`/v1/api/features`), `campaign` (`/v1/api/campaigns`), `gamification` (`/v1/api/gamification`).
    - Specify APIs: REST (`/v1/api/*` for UI, OpenAPI in `/config/openapi.yaml`), gRPC (`/admin.v1/*` for inter-service in `/apps/*/protos`).
    - Design database schemas: `core_schema.sql` (`merchants`, `customers`, `points_transactions`, `rfm_score_history`, `customer_segments`, `program_settings`), `auxiliary_schema.sql` (`integrations`, `audit_logs`, `gdpr_requests`, `email_templates`, `referrals`, `campaigns`).
    - Plan inter-service communication: Kafka for events (`points.earned`, `customer.updated`, `referral.created`), Redis Cluster/Streams for caching (`points:{customer_id}`) and task queues (Bull).
    - Set up monitoring: Loki + Grafana for logs, Prometheus for metrics, Sentry for errors.
    - Create architecture diagram (`/docs/architecture_diagram.drawio`) with microservices, APIs, and data flows.
  - **Tech Stack**:
    - Confirm NestJS (TypeScript, gRPC/REST), React (Polaris, Tailwind CSS), Rust/Wasm (Shopify Functions), i18next, PostgreSQL (JSONB, range partitioning), Redis Cluster/Streams, Kafka, Bull, Loki, Grafana, Prometheus, Sentry.
    - Use AI tools (Grok for architecture docs, Copilot for TypeScript/Rust code, Cursor for setup scripts).
- **Deliverables**:
  - Nx monorepo with `README.md`, guidelines, and CI/CD setup.
  - Local dev environment (`/config/docker-compose.yml`, `/scripts/dev.sh`) with documentation.
  - VPS with PostgreSQL, Redis Cluster, Kafka, Loki, Grafana, Prometheus.
  - Architecture diagram, API specs (`/config/openapi.yaml`, gRPC protos), and schema files (`/database/migrations`).
  - Team onboarding document and task board.
- **Resources**: PM, DevOps, backend developers, frontend developers.
- **AI Tools**: Grok (architecture docs), Copilot (TypeScript/Rust, tests), Cursor (Docker setup).

### Week 2: Database and Microservices Foundation
- **Tasks**:
  - **Database Setup**:
    - Validate `/database/migrations/core_schema.sql` (`merchants`, `customers`, `points_transactions`, `rfm_score_history`, `customer_segments`, `program_settings`) and `/database/migrations/auxiliary_schema.sql` (`integrations`, `audit_logs`, `gdpr_requests`, `email_templates`, `referrals`, `campaigns`).
    - Add indexes (e.g., `customers(email, merchant_id)`, `points_transactions(customer_id)`, `rfm_score_history(customer_id)`).
    - Implement range partitioning on `points_transactions` and `rfm_score_history`.
    - Test triggers (`/database/triggers/trigger_audit_log.sql`, `/database/triggers/trg_updated_at.sql`) with mock data (Faker).
  - **Microservices**:
    - Auth Service (`/apps/auth-service`): Implement JWT/OAuth (gRPC: `/admin.v1/Auth/Login`, REST: `/v1/api/auth/login`).
    - Points Service (`/apps/points-service`): CRUD for `points_transactions` (REST: `/v1/api/points/earn`, `/v1/api/points/redeem`).
    - Referrals Service (`/apps/referrals-service`): Manage referrals with Klaviyo/Postscript integration (REST: `/v1/api/referrals`, `/v1/api/integrations/klaviyo`).
    - RFM Analytics Service (`/apps/rfm_analytics-service`): Calculate RFM scores (REST: `/v1/api/rfm`).
    - Event Tracking Service (`/apps/event_tracking-service`): Log events to Kafka (REST: `/v1/api/events`).
    - Admin Core Service (`/apps/admin_core-service`): CRUD for `merchants` (gRPC: `/admin.v1/Admin/Get`, REST: `/v1/api/admin`).
    - Admin Features Service (`/apps/admin_features-service`): Notification templates, live previews (REST: `/v1/api/features`).
    - Campaign Service (`/apps/campaign-service`): Manage campaign discounts (REST: `/v1/api/campaigns`).
    - Gamification Service (`/apps/gamification-service`): Lightweight gamification logic (REST: `/v1/api/gamification`).
  - **Task Queue**:
    - Set up Bull queues (Redis Cluster) for async tasks (e.g., RFM calculations, referral processing) in `/apps/*/services`.
    - Create `queue_tasks` table for task tracking.
  - **Security**:
    - Encrypt sensitive fields (`integrations.api_key`, `email_templates.recipient_email`) with AWS KMS or pgcrypto (AES-256).
  - **Monitoring**:
    - Configure Prometheus metrics (`/config/prometheus.yml`) for API performance.
    - Set up Loki + Grafana for logs (`/config/grafana.ini`).
    - Integrate Sentry for error tracking.
  - **Testing**:
    - Jest unit tests for microservices (80%+ coverage) in `/apps/*/tests`.
    - Test database migrations in local dev environment.
  - **AI Tools**: Copilot for NestJS/Rust boilerplate, Grok for schema validation and test cases.
- **Deliverables**:
  - Deployed microservices with CRUD APIs (local and VPS).
  - Redis Cluster-based task queue for async tasks.
  - Database migration scripts and test reports.
  - Initial Prometheus, Loki, Grafana, and Sentry setups.
- **Resources**: Backend developers, DevOps, QA engineer.
- **Dependencies**: Week 1 local dev environment and schemas.

### Week 3: Welcome Page and Onboarding UI
- **Tasks**:
  - Develop Welcome Page (`US-MD1`, `/apps/frontend/src/components/WelcomePage.jsx`) in React with Polaris and Tailwind CSS:
    - Polaris `Card` for setup tasks (e.g., “Configure Points Program,” “Connect Shopify”).
    - Polaris `Banner` for congratulatory/error messages.