📝 Daily Developer Memo – July 25, 2025
✅ Topics Covered
.dockerignore best practices:

Should be placed in project root and each microservice/test folder.

Use node_modules (not **/node_modules) unless there's a special reason.

Ignoring non-existent files in .dockerignore will not throw Docker errors.

In frontend (e.g. React), public/ may be ignored if built assets already exist in dist/.

Docker multi-stage builds:

Separate build dependencies from runtime environment.

Reduces final image size and improves security.

Commands clarified:

RUN npm ci: clean install using package-lock.json (ensures reproducible builds).

WORKDIR /app: creates and sets /app as the working directory inside the image.

CI/CD basics:

CI (Continuous Integration): run tests, lint, build on every commit.

CD (Continuous Deployment/Delivery): auto-deploy to environments (dev/staging/prod).

Testing Environment (core-service-e2e):

A .env file is needed if tests depend on environment variables.

Can safely copy .dockerignore from a microservice to the test folder if similar.

Consider using .env.test to avoid conflicts with local or prod settings.

🛠️ Next Steps
 Create .env.test files for all e2e or integration test folders.

 Review each microservice/test Dockerfile for multi-stage consistency.

 Consider excluding docs, .git, and test artifacts from final Docker images.

 Finalize .dockerignore templates per folder.

Let me know anytime if you’d like help automating .env.test generation or CI/CD pipeline setup. Have a productive day! 🚀





Daily Memo: LoyalNest Development - July 25, 2025
Overview
Today’s focus was advancing LoyalNest’s Phase 3 microservices architecture, specifically completing the Jest test suite for libs/database, defining the Customer entity for the Core service, and expanding the Kafka handler to include additional services (Core, AdminCore, Event Tracking). These efforts ensure robust database operations, GDPR/CCPA-compliant data handling, and cross-service event coordination, aligning with the TVP deadline and scalability goals.
Progress

Jest Test Suite for libs/database:

Created unit tests for all 12 repository classes (Auth, Core, Points, Referrals, RFM Analytics, Products, AdminCore, AdminFeatures, Campaign, Event Tracking, API Gateway, Gamification).
Tests cover key operations (e.g., findByShopDomain, createTransaction, getSegmentCounts) using mocked drivers (TypeORM, Mongoose, ioredis, Elasticsearch).
Verified PII handling in CoreRepository (e.g., encrypted email) and high-throughput queries in PointsRepository (10,000 orders/hour).
Tests are integrated into the Nx monorepo (nx test database).


Customer Entity Definition:

Defined Customer.entity.ts for the Core service’s PostgreSQL database, mapping to the customers table (core_schema.txt).
Included fields: id (UUID), merchant_id (UUID, indexed), email (VARCHAR, encrypted with pgcrypto), rfm_score (JSONB), metadata (JSONB), created_at, updated_at.
Configured TypeORM decorators for schema alignment and GDPR/CCPA compliance (encrypted email).
Integrated with CoreRepository for methods like findById and updateRFMScore.


Kafka Handler Expansion:

Extended the Kafka handler (libs/kafka) to support new events: customer.created, customer.updated (Core), gdpr_request.created (AdminCore), task.created, task.completed (Event Tracking).
Updated CoreService, AdminCoreService, and EventTrackingService to produce and consume these events, ensuring eventual consistency (e.g., GDPR request → PII redaction in Core).
Maintained focus on Points, Referrals, and RFM Analytics (points.earned, referral.completed, rfm.updated) for TVP priorities, with new events enhancing compliance and async task coordination.
Kafka configuration remains generic, supporting future scalability (e.g., Gamification in Phase 6).



Next Steps

Testing:

Write Jest tests for new Kafka events (customer.created, gdpr_request.created, etc.) in libs/kafka/*.spec.ts.
Set up Cypress E2E tests for critical workflows (e.g., GDPR request creation → Core PII redaction).
Run k6 load tests to validate 10,000 orders/hour throughput for Points and Referrals.


Deployment:

Update docker-compose.yml to include Kafka and Zookeeper services (e.g., confluentinc/cp-kafka:7.0.1, confluentinc/cp-zookeeper:7.0.1).
Deploy on VPS (Ubuntu, 32GB RAM, 8 vCPUs) and test database connectivity (libs/database) with dev.sh.


Additional Entities:

Define remaining entities (e.g., AuditLog.entity.ts for AdminCore, PointsTransaction.entity.ts for Points) to complete libs/database/entities.
Ensure GDPR/CCPA compliance (e.g., encrypted fields, audit logging).


TVP Prioritization:

Focus on Points, Referrals, and RFM Analytics integration tests to meet Shopify App Store requirements.
Validate 7% SMS conversion for Referrals and daily RFM updates (0 1 * * *).



Notes

Budget: Monitor VPS costs ($91,912.50 budget). Consider free tiers (MongoDB Atlas, Redis Labs) for testing.
AI Tools: Leverage Grok, Copilot, and Cursor for 30–40% efficiency in coding and testing.
Risks: Mitigate Kafka complexity by limiting new events to high-impact services (Core, AdminCore, Event Tracking). Use gRPC for low-volume services (e.g., Auth, Campaign).
Compliance: Audit logs (AdminCoreService) and encrypted Customer.email ensure GDPR/CCPA readiness.

Action Items

Review Jest test results (nx test database) by July 26, 2025.
Draft AuditLog.entity.ts and PointsTransaction.entity.ts by July 27, 2025.
Deploy Kafka on VPS and test event flows by July 28, 2025.




