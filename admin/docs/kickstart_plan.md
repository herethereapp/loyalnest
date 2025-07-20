# LoyalNest Shopify App Kickstart Plan

## Objective
Launch Phase 1 of the LoyalNest Shopify app, focusing on core functionality (merchant onboarding, RFM analytics setup, loyalty points, Shopify integration), GDPR/CCPA compliance, multilingual support for 22 languages (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ar`, `zh-CN`, etc.), and a robust project architecture. This 6-week plan establishes a scalable, production-ready foundation, with a local development environment to streamline team workflows.

## Scope
- **Core Features**: Merchant onboarding (Welcome Page, `US-MD1`), basic RFM analytics (`rfm_score_history`, `customer_segments`), loyalty points (`points_transactions`), Shopify integration.
- **Compliance**: GDPR/CCPA support via `gdpr_requests` and `audit_logs`.
- **Infrastructure**: Deploy core microservices and database on a VPS (Ubuntu, Docker Compose, PostgreSQL) and set up a local dev environment (Docker Compose).
- **Architecture**: Define microservices (Merchant, Customer, Audit, Points, Integrations), APIs (REST, gRPC), and database schemas (`core_schema.sql`, `auxiliary_schema.sql`).
- **Multilingual**: Support 22 languages with i18next integration.
- **Testing**: Jest (unit), Cypress (E2E), k6 (performance) for critical flows.

## Timeline: 6 Weeks (July 21, 2025 – August 31, 2025)

### Week 1: Project Setup, Local Dev Environment, and Architecture Planning
- **Tasks**:
  - **Repository Setup**:
    - Initialize GitHub/GitLab repository with CI/CD pipelines (GitHub Actions) and change detection.
    - Create README, contribution guidelines, and `.gitignore` for Node.js/React.
  - **Team Roles**:
    - Assign 1 PM, 2 backend developers (Node.js, PostgreSQL), 2 frontend developers (React, Polaris), 1 QA engineer, 1 DevOps engineer.
    - Document roles and task board (Jira/Trello).
  - **Local Dev Environment**:
    - Create `docker-compose.yml` for local setup (Node.js, React, PostgreSQL 15, Redis, Nginx).
    - Develop `dev.sh` script for Docker setup, mock data seeding (Faker), and database migrations.
    - Test local environment with `npm run start:dev` for frontend and backend.
    - Document setup in README (e.g., “Run `./dev.sh up` to start local dev”).
  - **VPS Deployment**:
    - Deploy VPS (Ubuntu) with Docker Compose, PostgreSQL 15, Redis, and Nginx.
    - Apply `core_schema.sql` and `auxiliary_schema.sql` to PostgreSQL, verify triggers (`trigger_audit_log`, `trg_updated_at`).
  - **Project Architecture**:
    - Define microservices: Merchant (`/admin.v1/Merchant`), Customer (`/admin.v1/Customer`), Audit (`/admin.v1/Audit`), Points (`/v1/api/points`), Integrations (`/v1/api/integrations`).
    - Specify APIs: REST (`/v1/api/*` for UI, OpenAPI/Swagger), gRPC (`/admin.v1/*` for inter-service).
    - Design database schemas: `core_schema.sql` (`merchants`, `customers`, `rfm_score_history`, `points_transactions`, `customer_segments`, `program_settings`), `auxiliary_schema.sql` (`integrations`, `audit_logs`, `queue_tasks`, `gdpr_requests`, `email_templates`).
    - Plan inter-service communication: Kafka for events (`points.earned`, `customer.updated`), Redis for caching (`points:{customer_id}`).
    - Create architecture diagram (Draw.io) with microservices, APIs, and data flows.
  - **Tech Stack**:
    - Confirm Node.js (gRPC/REST), React (Polaris, Tailwind CSS), i18next, PostgreSQL (JSONB, range partitioning), Redis, Kafka.
    - Use AI tools (Grok for architecture docs, Copilot for schema/scripts, Cursor for setup scripts).
- **Deliverables**:
  - Repository with README, guidelines, and CI/CD setup.
  - Local dev environment (`docker-compose.yml`, `dev.sh`) with documentation.
  - VPS with PostgreSQL, Redis, and initial schemas.
  - Architecture diagram, API specs (OpenAPI/Swagger, gRPC), and schema files.
  - Team onboarding document and task board.
- **Resources**: PM, DevOps, backend developers, frontend developers.
- **AI Tools**: Grok (architecture docs), Copilot (schema, `dev.sh`), Cursor (Docker setup).

### Week 2: Database and Microservices Foundation
- **Tasks**:
  - **Database Setup**:
    - Validate `core_schema.sql` (`merchants`, `customers`, `rfm_score_history`, `points_transactions`, `customer_segments`, `program_settings`) and `auxiliary_schema.sql` (`integrations`, `audit_logs`, `queue_tasks`, `gdpr_requests`, `email_templates`).
    - Add indexes (e.g., `customers(email, merchant_id)`, `points_transactions(customer_id)`).
    - Test triggers (`trigger_audit_log`, `trg_updated_at`) with mock data (Faker).
  - **Microservices**:
    - Merchant Service: CRUD for `merchants` (gRPC: `/admin.v1/Merchant/Get`, `/admin.v1/Merchant/Create`).
    - Customer Service: CRUD for `customers` and `rfm_score_history` (gRPC: `/admin.v1/Customer/Get`, `/admin.v1/Customer/Update`).
    - Audit Service: Log to `audit_logs` via `trigger_audit_log` (gRPC: `/admin.v1/Audit/Log`).
    - Points Service: CRUD for `points_transactions` (REST: `/v1/api/points/earn`, `/v1/api/points/redeem`).
    - Integrations Service: Manage Shopify integration (`integrations.platform = 'shopify'`, REST: `/v1/api/integrations/shopify`).
  - **Task Queue**:
    - Set up BullMQ (Redis) for async tasks (e.g., RFM calculations, customer sync).
    - Create `queue_tasks` table for task tracking.
  - **Security**:
    - Encrypt sensitive fields (`integrations.api_key`, `email_events.recipient_email`) with AWS KMS or pgcrypto (AES-256).
  - **Testing**:
    - Jest unit tests for microservices (80%+ coverage).
    - Test database migrations in local dev environment.
  - **AI Tools**: Copilot for microservice boilerplate, Grok for schema validation and test cases.
- **Deliverables**:
  - Deployed microservices with CRUD APIs (local and VPS).
  - Redis-based task queue for async RFM calculations.
  - Database migration scripts and test reports.
- **Resources**: Backend developers, DevOps, QA engineer.
- **Dependencies**: Week 1 local dev environment and schemas.

### Week 3: Welcome Page and Onboarding UI
- **Tasks**:
  - Develop Welcome Page (`US-MD1`) in React with Polaris and Tailwind CSS:
    - Polaris `Card` for setup tasks (e.g., “Configure Points Program,” “Connect Shopify”).
    - Polaris `Banner` for congratulatory/error messages.
    - ARIA labels (`aria-label="Complete setup tasks"`) and RTL support for `ar`, `he`.
    - i18next for 22 languages (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ar`, `zh-CN`, etc.).
  - Integrate with `/admin.v1/CompleteSetupTask` gRPC endpoint (mocked for prototype).
  - Log setup task completions to PostHog (`setup_task_completed` event).
  - Test UI:
    - Jest unit tests for components and i18next fallbacks.
    - Cypress E2E tests for onboarding flow and language switching.
  - Run in local dev environment (`./dev.sh up`) to verify functionality.
  - **AI Tools**: Cursor for React components, Grok for translation templates and PostHog event definitions.
- **Deliverables**:
  - Functional Welcome Page with multilingual support.
  - Unit and E2E test suites.
  - PostHog integration for analytics.
- **Resources**: Frontend developers, QA engineer.
- **Dependencies**: Week 2 microservices and i18next setup.

### Week 4: RFM Analytics and Loyalty Basics
- **Tasks**:
  - **RFM Analytics**:
    - Implement RFM calculation logic (Node.js) for `rfm_score_history` and `customer_segments`.
    - Use async tasks (BullMQ) for incremental updates triggered by `points_transactions`.
    - Store results in `rfm_segment_counts` (materialized view with daily refresh).
  - **Loyalty Points**:
    - Implement CRUD for `points_transactions` (e.g., `/v1/api/points/earn`, `/v1/api/points/redeem`).
    - Validate against `program_settings` (JSONB, e.g., `points_per_dollar: 10`).
  - **Shopify Integration**:
    - Configure `integrations` table (`platform = 'shopify'`) for Shopify API.
    - Sync customer data to `customers` table via Shopify API (`customers/list`).
  - **Testing**:
    - Jest unit tests for RFM logic and points transactions.
    - Cypress E2E tests for Shopify sync in local dev environment.
    - k6 performance tests for RFM calculations (1,000 customers).
  - **AI Tools**: Copilot for RFM algorithms, Grok for test data generation.
- **Deliverables**:
  - RFM calculation microservice with async task support.
  - Loyalty points API endpoints.
  - Shopify integration with customer sync.
  - Test reports (unit, E2E, performance).
- **Resources**: Backend developers, QA engineer.
- **Dependencies**: Week 2 microservices and database.

### Week 5: Compliance and Testing
- **Tasks**:
  - **GDPR/CCPA Workflows**:
    - Process `gdpr_requests` (`type = 'data_request', 'redact'`) via async task queue (BullMQ).
    - Log redactions to `gdpr_redaction_log` and `audit_logs`.
  - **Testing**:
    - Jest unit tests for microservices (Merchant, Customer, Audit, Points, Integrations).
    - Cypress E2E tests for Welcome Page, Shopify sync, and GDPR workflows.
    - k6 performance tests for 1,000 concurrent users on Welcome Page and RFM calculations.
    - Validate multilingual support (e.g., `email_templates.subject`, `vip_tiers.name`) for 22 languages with i18next.
  - **Local Dev Testing**:
    - Verify all components in local dev environment (`./dev.sh up`).
  - **AI Tools**: Grok for GDPR workflow documentation, Copilot for test suites.
- **Deliverables**:
  - GDPR/CCPA-compliant workflows with audit logging.
  - Test reports (unit, E2E, performance).
  - Multilingual validation report.
- **Resources**: Backend developers, QA engineer, frontend developers.
- **Dependencies**: Week 3 Welcome Page, Week 4 RFM and points.

### Week 6: Deployment and Merchant Feedback
- **Tasks**:
  - Deploy app to staging VPS (Docker Compose, PostgreSQL, Nginx).
  - Test deployment in local dev environment before staging push.
  - Conduct merchant beta testing with 5–10 Shopify merchants:
    - Share staging URL and collect feedback on Welcome Page, onboarding, RFM analytics, and points transactions via “LoyalNest Collective” Slack and Google Forms.
    - Target 80%+ satisfaction for onboarding flow.
  - Fix bugs and refine UI based on feedback.
  - Document setup and deployment process (`deploy.md`) for production.
  - **AI Tools**: Grok for feedback summarization and bug prioritization.
- **Deliverables**:
  - Staging environment on VPS.
  - Merchant feedback report and bug fixes.
  - Deployment guide (`deploy.md`).
- **Resources**: PM, DevOps, QA engineer, frontend/backend developers.
- **Dependencies**: Week 5 testing and compliance.

## Resources
- **Team**: 1 PM, 2 backend developers, 2 frontend developers, 1 QA engineer, 1 DevOps engineer.
- **Tools**:
  - Development: Node.js, React, Shopify Polaris, Tailwind CSS, i18next.
  - Database: PostgreSQL 15, Redis (BullMQ).
  - Testing: Jest, Cypress, k6.
  - Analytics: PostHog.
  - Infrastructure: VPS (Ubuntu), Docker Compose, Nginx.
  - AI: Grok (docs, translations), Copilot (code, tests), Cursor (setup scripts).
- **Budget Estimate**: ~$30,000 (6 weeks, 7 team members, ~$100/hour).

## Success Criteria
- Functional Welcome Page (`US-MD1`) with 22-language support and Shopify integration.
- Deployed microservices (Merchant, Customer, Audit, Points, Integrations) with async task processing.
- RFM analytics calculating scores for 1,000+ sample customers.
- GDPR/CCPA-compliant workflows with audit logging.
- Passing test suites (90%+ unit test coverage, 100% E2E test pass rate, k6 for 1,000 concurrent users).
- Positive feedback from 5+ beta merchants (80%+ satisfaction).

## Risks and Mitigation
- **Risk**: Local dev environment setup issues.
  - **Mitigation**: Provide detailed `dev.sh` and README; test Docker Compose locally before VPS deployment.
- **Risk**: Schema issues (e.g., missing constraints).
  - **Mitigation**: Validate schemas in local dev environment; test triggers with mock data.
- **Risk**: Multilingual support gaps.
  - **Mitigation**: Use i18next with `en` fallback; validate translations in Week 5 with native speakers via Slack.
- **Risk**: Shopify API rate limits.
  - **Mitigation**: Implement rate-limiting and retry logic in Integrations Service; cache in Redis.
- **Risk**: Performance bottlenecks in RFM.
  - **Mitigation**: Use async tasks (BullMQ) and optimize queries with indexes.

## Next Steps
- Approve kickstart plan and allocate resources.
- Schedule kickoff meeting for July 21, 2025.
- Begin Week 1 tasks: repository setup, local dev environment, VPS deployment, architecture planning.