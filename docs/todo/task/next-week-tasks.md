Table-to-Service Mapping and Database Setup

Auth	
merchants, admin_users, admin_sessions, impersonation_sessions	
PostgreSQL	Structured data, PII encryption (AES-256).

Core	
customers, program_settings, customer_import_logs	
PostgreSQL	Central customer data, PII encryption.

Points	
points_transactions, reward_redemptions, pos_offline_queue	
MongoDB	High-write (10,000 orders/hour), JSONB-like flexibility.

Referrals	
referrals	
Redis + PostgreSQL	Fast lookups (referral_link_id), persistent PostgreSQL for compliance.

RFM Analytics	
rfm_segment_deltas, rfm_segment_counts, rfm_score_history, customer_segments	
TimescaleDB	Time-series for RFM scores, analytical queries.

AdminCore	
audit_logs, gdpr_requests, gdpr_redaction_log, webhook_idempotency_keys	
PostgreSQL	Compliance and audit, PII encryption.

AdminFeatures	
email_templates, email_events, shopify_flow_templates, integrations	
PostgreSQL	Admin configs, multilingual support.

Campaign	
vip_tiers	
PostgreSQL	Structured campaign data, low write frequency.

Gamification	
None (Phase 6)	
Redis	Key-value for badges/leaderboards (prep).

Products	
products	
Elasticsearch	Search/recommendation queries (Phase 6 prep).

Event Tracking	
queue_tasks	
PostgreSQL	Async task queue.

API Gateway	
rate_limit_tracking	
Redis	Fast in-memory for Shopify API rate limits.

Frontend	
None	N/A	Queries via API Gateway.

Implementation Steps
Deploy Databases with Docker Compose:
Configure Docker Compose to run all databases on the VPS:
text

Collapse

Wrap

Copy
version: '3.8'
     services:
       auth_db:
         image: postgres:16
         environment:
           POSTGRES_DB: auth_db
           POSTGRES_USER: user
           POSTGRES_PASSWORD: password
         volumes:
           - auth_data:/var/lib/postgresql/data
         ports:
           - "5432:5432"
       core_db:
         image: postgres:16
         environment:
           POSTGRES_DB: core_db
           POSTGRES_USER: user
           POSTGRES_PASSWORD: password
         volumes:
           - core_data:/var/lib/postgresql/data
         ports:
           - "5433:5432"
       points_db:
         image: mongo:5
         volumes:
           - points_data:/data/db
         ports:
           - "27017:27017"
       referrals_redis:
         image: redis:7
         volumes:
           - referrals_redis_data:/data
         ports:
           - "6379:6379"
       referrals_db:
         image: postgres:16
         environment:
           POSTGRES_DB: referrals_db
           POSTGRES_USER: user
           POSTGRES_PASSWORD: password
         volumes:
           - referrals_data:/var/lib/postgresql/data
         ports:
           - "5434:5432"
       rfm_analytics_db:
         image: timescale/timescaledb:latest-pg16
         environment:
           POSTGRES_DB: rfm_db
           POSTGRES_USER: user
           POSTGRES_PASSWORD: password
         volumes:
           - rfm_data:/var/lib/postgresql/data
         ports:
           - "5435:5432"
       products_db:
         image: elasticsearch:8.8
         environment:
           - discovery.type=single-node
           - xpack.security.enabled=false
         volumes:
           - products_data:/usr/share/elasticsearch/data
         ports:
           - "9200:9200"
       admin_core_db:
         image: postgres:16
         environment:
           POSTGRES_DB: admin_core_db
           POSTGRES_USER: user
           POSTGRES_PASSWORD: password
         volumes:
           - admin_core_data:/var/lib/postgresql/data
         ports:
           - "5436:5432"
       admin_features_db:
         image: postgres:16
         environment:
           POSTGRES_DB: admin_features_db
           POSTGRES_USER: user
           POSTGRES_PASSWORD: password
         volumes:
           - admin_features_data:/var/lib/postgresql/data
         ports:
           - "5437:5432"
       campaign_db:
         image: postgres:16
         environment:
           POSTGRES_DB: campaign_db
           POSTGRES_USER: user
           POSTGRES_PASSWORD: password
         volumes:
           - campaign_data:/var/lib/postgresql/data
         ports:
           - "5438:5432"
       event_tracking_db:
         image: postgres:16
         environment:
           POSTGRES_DB: event_tracking_db
           POSTGRES_USER: user
           POSTGRES_PASSWORD: password
         volumes:
           - event_tracking_data:/var/lib/postgresql/data
         ports:
           - "5439:5432"
       api_gateway_redis:
         image: redis:7
         volumes:
           - api_gateway_redis_data:/data
         ports:
           - "6380:6379"
       gamification_redis:
         image: redis:7
         volumes:
           - gamification_redis_data:/data
         ports:
           - "6381:6379"
     volumes:
       auth_data:
       core_data:
       points_data:
       referrals_redis_data:
       referrals_data:
       rfm_data:
       products_data:
       admin_core_data:
       admin_features_data:
       campaign_data:
       event_tracking_data:
       api_gateway_redis_data:
       gamification_redis_data:

Show in sidebar
Deploy: docker-compose up -d on VPS.

Initialize Database Schemas:
Auth (PostgreSQL):
text

Collapse

Wrap

Copy

CREATE EXTENSION IF NOT EXISTS pgcrypto;
     CREATE TABLE merchants (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         shop_domain VARCHAR(255) NOT NULL UNIQUE,
         language JSONB NOT NULL,
         multi_tenant_group_id UUID,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
         updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE admin_users (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID REFERENCES merchants(id),
         email VARCHAR(255) NOT NULL,
         password_hash VARCHAR(255) NOT NULL,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE admin_sessions (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         admin_user_id UUID REFERENCES admin_users(id),
         token VARCHAR(255) NOT NULL,
         expires_at TIMESTAMP WITH TIME ZONE NOT NULL
     );
     CREATE TABLE impersonation_sessions (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         admin_user_id UUID REFERENCES admin_users(id),
         customer_id UUID,
         expires_at TIMESTAMP WITH TIME ZONE NOT NULL
     );
     CREATE OR REPLACE FUNCTION normalize_shop_domain()
     RETURNS TRIGGER AS $$
     BEGIN
         NEW.shop_domain = LOWER(NEW.shop_domain);
         RETURN NEW;
     END;
     $$ LANGUAGE plpgsql;
     CREATE TRIGGER trg_normalize_shop_domain
     BEFORE INSERT OR UPDATE ON merchants
     FOR EACH ROW EXECUTE FUNCTION normalize_shop_domain();
     CREATE OR REPLACE FUNCTION update_updated_at_column()
     RETURNS TRIGGER AS $$
     BEGIN
         NEW.updated_at = CURRENT_TIMESTAMP;
         RETURN NEW;
     END;
     $$ LANGUAGE plpgsql;
     CREATE TRIGGER trg_merchants_updated_at
     BEFORE UPDATE ON merchants
     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
     CREATE INDEX idx_merchants_shop_domain ON merchants(shop_domain);
     CREATE INDEX idx_merchants_language ON merchants USING GIN (language);
     CREATE INDEX idx_merchants_multi_tenant_group_id ON merchants(multi_tenant_group_id);
     CREATE INDEX idx_admin_users_merchant_id ON admin_users(merchant_id);
Show in sidebar
Run: psql -h localhost -p 5432 -d auth_db -f auth_schema.sql.
Core (PostgreSQL):
text

Collapse

Wrap

Copy

CREATE EXTENSION IF NOT EXISTS pgcrypto;
     CREATE TABLE customers (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         email VARCHAR(255) ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = 'key', ENCRYPTION_TYPE = AES_256_GCM),
         rfm_score JSONB,
         metadata JSONB,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
         updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE program_settings (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL UNIQUE,
         rfm_thresholds JSONB,
         config JSONB,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE customer_import_logs (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         status VARCHAR(50) NOT NULL,
         error_message TEXT,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TRIGGER trg_customers_updated_at
     BEFORE UPDATE ON customers
     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
     CREATE INDEX idx_customers_merchant_id ON customers(merchant_id);
     CREATE INDEX idx_customers_rfm_score ON customers USING GIN (rfm_score);
     CREATE INDEX idx_program_settings_merchant_id ON program_settings(merchant_id);
Show in sidebar
Run: psql -h localhost -p 5433 -d core_db -f core_schema.sql.
Points (MongoDB):
text

Collapse

Wrap

Copy

db.createCollection("points_transactions", {
       validator: {
         $jsonSchema: {
           bsonType: "object",
           required: ["id", "customer_id", "merchant_id", "points", "type"],
           properties: {
             id: { bsonType: "string" },
             customer_id: { bsonType: "string" },
             merchant_id: { bsonType: "string" },
             points: { bsonType: "int" },
             type: { enum: ["earn", "redeem", "adjust"] },
             reason: { bsonType: "string" },
             source: { enum: ["shopify", "klaviyo", "zapier", "shopify_flow", "manual"] },
             created_at: { bsonType: "date" }
           }
         }
       }
     });
     db.points_transactions.createIndex({ customer_id: 1 });
     db.points_transactions.createIndex({ merchant_id: 1 });
     db.points_transactions.createIndex({ created_at: 1 });
     db.createCollection("reward_redemptions", {
       validator: {
         $jsonSchema: {
           bsonType: "object",
           required: ["id", "customer_id", "merchant_id", "campaign_id", "points"],
           properties: {
             id: { bsonType: "string" },
             customer_id: { bsonType: "string" },
             merchant_id: { bsonType: "string" },
             campaign_id: { bsonType: "string" },
             points: { bsonType: "int" },
             created_at: { bsonType: "date" }
           }
         }
       }
     });
     db.reward_redemptions.createIndex({ customer_id: 1 });
     db.reward_redemptions.createIndex({ merchant_id: 1 });
     db.reward_redemptions.createIndex({ campaign_id: 1 });
     db.createCollection("pos_offline_queue", {
       validator: {
         $jsonSchema: {
           bsonType: "object",
           required: ["id", "merchant_id", "status"],
           properties: {
             id: { bsonType: "string" },
             merchant_id: { bsonType: "string" },
             status: { bsonType: "string" },
             created_at: { bsonType: "date" }
           }
         }
       }
     });
     db.points_transactions.createIndex({ id: 1 });
     </xai>
     - Run: `mongo --host localhost:27017 points_db < points_schema.js`.
   - **Referrals (PostgreSQL + Redis)**:
     - **PostgreSQL**:
       <xaiArtifact artifact_id="c2900e97-5878-4fe4-b9a5-ba64d40d5165" artifact_version_id="4805cc6a-ab83-4455-9366-975c73869efc" title="referrals_schema.sql" contentType="text/plain">
       CREATE TABLE referrals (
           id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
           merchant_id UUID NOT NULL,
           customer_id UUID NOT NULL,
           referral_link_id VARCHAR(255) NOT NULL UNIQUE,
           status VARCHAR(50) NOT NULL,
           created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
           updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
       );
       CREATE TRIGGER trg_referrals_updated_at
       BEFORE UPDATE ON referrals
       FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
       CREATE INDEX idx_referrals_merchant_id ON referrals(merchant_id);
       CREATE INDEX idx_referrals_referral_link_id ON referrals(referral_link_id);
Show in sidebar
Run: psql -h localhost -p 5434 -d referrals_db -f referrals_schema.sql.
Redis: No schema; use keys (referral:{merchant_id}:{id}) and Streams (status:{id}) in application logic.
RFM Analytics (TimescaleDB):
text

Collapse

Wrap

Copy

CREATE TABLE rfm_segment_deltas (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         customer_id UUID NOT NULL,
         rfm_score JSONB,
         metadata JSONB,
         operation VARCHAR(10) NOT NULL,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     SELECT create_hypertable('rfm_segment_deltas', 'created_at');
     CREATE TABLE rfm_segment_counts (
         merchant_id UUID NOT NULL,
         segment_id VARCHAR(255) NOT NULL,
         report_id UUID NOT NULL,
         name JSONB,
         count BIGINT NOT NULL,
         conditions JSONB,
         last_refreshed TIMESTAMP WITH TIME ZONE,
         PRIMARY KEY (merchant_id, segment_id)
     );
     CREATE MATERIALIZED VIEW rfm_segment_counts_view
     WITH (timescaledb.continuous) AS
     SELECT
         merchant_id,
         'seg_' || (rfm_score->>'recency') || (rfm_score->>'frequency') || (rfm_score->>'monetary') AS segment_id,
         gen_random_uuid() AS report_id,
         jsonb_build_object('en', 'Segment') AS name,
         COUNT(*) AS count,
         jsonb_build_object('rfm', rfm_score) AS conditions,
         time_bucket('1 day', created_at) AS last_refreshed
     FROM rfm_segment_deltas
     GROUP BY merchant_id, segment_id, time_bucket('1 day', created_at)
     WITH DATA;
     CREATE TABLE rfm_score_history (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         customer_id UUID NOT NULL,
         rfm_score JSONB,
         metadata JSONB,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE customer_segments (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         customer_id UUID NOT NULL,
         segment_id VARCHAR(255) NOT NULL,
         name JSONB,
         rules JSONB,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE INDEX idx_rfm_segment_deltas_merchant_id ON rfm_segment_deltas(merchant_id);
     CREATE INDEX idx_rfm_segment_deltas_customer_id ON rfm_segment_deltas(customer_id);
     CREATE INDEX idx_rfm_score_history_merchant_id ON rfm_score_history(merchant_id);
     CREATE INDEX idx_customer_segments_merchant_id ON customer_segments(merchant_id);
Show in sidebar
Run: psql -h localhost -p 5435 -d rfm_db -f rfm_schema.sql.
Products (Elasticsearch):
application

Collapse

Wrap

Copy
{
       "mappings": {
         "properties": {
           "id": { "type": "keyword" },
           "merchant_id": { "type": "keyword" },
           "name": { "type": "text" },
           "rfm_score": { "type": "object" },
           "created_at": { "type": "date" }
         }
       }
     }
Show in sidebar
Run: curl -X PUT "http://localhost:9200/products" -H 'Content-Type: application/json' -d @products_mapping.json.
AdminCore (PostgreSQL):
text

Collapse

Wrap

Copy
CREATE TABLE audit_logs (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID,
         actor_id UUID,
         entity_type VARCHAR(255) NOT NULL,
         entity_id UUID NOT NULL,
         action VARCHAR(255) NOT NULL,
         severity VARCHAR(50) NOT NULL,
         metadata JSONB,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE gdpr_requests (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         customer_id UUID NOT NULL,
         request_type VARCHAR(50) NOT NULL,
         status VARCHAR(50) NOT NULL,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE gdpr_redaction_log (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         customer_id UUID NOT NULL,
         redacted_fields JSONB,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE webhook_idempotency_keys (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         event_id VARCHAR(255) NOT NULL UNIQUE,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE INDEX idx_audit_logs_merchant_id ON audit_logs(merchant_id);
     CREATE INDEX idx_gdpr_requests_merchant_id ON gdpr_requests(merchant_id);
     CREATE INDEX idx_webhook_idempotency_keys_merchant_id ON webhook_idempotency_keys(merchant_id);
Show in sidebar
Run: psql -h localhost -p 5436 -d admin_core_db -f admin_core_schema.sql.
AdminFeatures (PostgreSQL):
text

Collapse

Wrap

Copy
CREATE TABLE email_templates (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         template_id VARCHAR(255) NOT NULL,
         content JSONB NOT NULL,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
         updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE email_events (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         customer_id UUID,
         event_type VARCHAR(255) NOT NULL,
         status VARCHAR(50) NOT NULL,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE shopify_flow_templates (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         template_id VARCHAR(255) NOT NULL,
         config JSONB NOT NULL,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TABLE integrations (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         provider VARCHAR(255) NOT NULL,
         credentials JSONB ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = 'key', ENCRYPTION_TYPE = AES_256_GCM),
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TRIGGER trg_email_templates_updated_at
     BEFORE UPDATE ON email_templates
     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
     CREATE INDEX idx_email_templates_merchant_id ON email_templates(merchant_id);
     CREATE INDEX idx_email_events_merchant_id ON email_events(merchant_id);
     CREATE INDEX idx_shopify_flow_templates_merchant_id ON shopify_flow_templates(merchant_id);
     CREATE INDEX idx_integrations_merchant_id ON integrations(merchant_id);
Show in sidebar
Run: psql -h localhost -p 5437 -d admin_features_db -f admin_features_schema.sql.
Campaign (PostgreSQL):
text

Collapse

Wrap

Copy
CREATE TABLE vip_tiers (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         tier_id VARCHAR(255) NOT NULL,
         config JSONB NOT NULL,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
         updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE TRIGGER trg_vip_tiers_updated_at
     BEFORE UPDATE ON vip_tiers
     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
     CREATE INDEX idx_vip_tiers_merchant_id ON vip_tiers(merchant_id);
Show in sidebar
Run: psql -h localhost -p 5438 -d campaign_db -f campaign_schema.sql.
Event Tracking (PostgreSQL):
text

Collapse

Wrap

Copy
CREATE TABLE queue_tasks (
         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
         merchant_id UUID NOT NULL,
         task_type VARCHAR(255) NOT NULL,
         status VARCHAR(50) NOT NULL,
         payload JSONB,
         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     CREATE INDEX idx_queue_tasks_merchant_id ON queue_tasks(merchant_id);
     CREATE INDEX idx_queue_tasks_status ON queue_tasks(status);
Show in sidebar
Run: psql -h localhost -p 5439 -d event_tracking_db -f event_tracking_schema.sql.
API Gateway (Redis):
No schema; use keys (rate_limit:{merchant_id}:{endpoint}) with TTL.
Gamification (Redis):
No schema; prep for Phase 6 with keys (leaderboard:{merchant_id}).
Cross-Service Integration:
Kafka:
Points: Emit points.earned to trigger RFM Analytics.
Referrals: Emit referral.completed for Points and RFM updates.
RFM Analytics: Consume events to run calculate_rfm_score (application logic).
gRPC:
Core: Expose /core.v1/GetCustomerRFM for Points and Referrals.
AdminCore: Query all services for audit logs.
API Gateway:
Route Shopify webhooks (orders/create) to Points and Referrals with Redis idempotency.
Update Nx Monorepo:
libs/database:
Add Mongoose (points.repository.ts), ioredis (referrals.repository.ts, api-gateway.repository.ts, gamification.repository.ts), TimescaleDB driver (rfm-analytics.repository.ts), Elasticsearch client (products.repository.ts).
Configure TypeORM for PostgreSQL services (auth.repository.ts, core.repository.ts, etc.).
apps/:
Update endpoints (e.g., /points.v1/GetPointsBalance) to use new databases.
Add Kafka producers/consumers.
Testing:
Unit Tests: Jest for database queries in libs/database.
E2E Tests: Cypress for GDPR, referrals, RFM UI.
Load Tests: k6 for 10,000 orders/hour, 7% SMS conversion.
Compliance: Verify PII encryption (core.customers, admin_features.integrations).
Deliverables:
Deployed databases (Docker Compose).
Schema scripts for all services.
Updated libs/database.
Test reports (Jest, Cypress, k6).
Risks and Mitigations
Complexity: Use Nx libs/database for unified access; test with dev.sh.
Consistency: Saga patterns via Kafka for critical workflows.
Timeline: Parallelize setup with AI tools; focus on Points, Referrals, RFM for TVP.
Cost: Free tiers (MongoDB Atlas, Redis Labs) for testing; VPS for production.
Would you like a TypeScript configuration for libs/database, a Kafka handler, or a specific database setup script?







yes, i need a TypeScript config for libs/database, and a Kafka handler


To support LoyalNest’s transition to service-dedicated databases in Phase 3 (October 2025–February 2026) with a true microservices architecture, I’ll provide a TypeScript configuration for the libs/database in your Nx monorepo and a Kafka handler to manage cross-service events. The libs/database configuration will include repositories for each service’s database (PostgreSQL for Auth, Core, AdminCore, AdminFeatures, Campaign, Event Tracking, Referrals; MongoDB for Points; Redis for Referrals, API Gateway, Gamification; TimescaleDB for RFM Analytics; Elasticsearch for Products), ensuring unified access across your 13 services. The Kafka handler will facilitate eventual consistency for events like points.earned, referral.completed, and rfm.updated, aligning with your requirements for GDPR/CCPA compliance, Shopify Plus scalability (10,000 orders/hour), and the TVP deadline.

TypeScript Configuration for libs/database
The libs/database library will contain repository classes for each service’s database, using appropriate drivers (TypeORM for PostgreSQL, Mongoose for MongoDB, ioredis for Redis, TimescaleDB driver for RFM Analytics, Elasticsearch client for Products). Each repository abstracts database operations, supporting your Nx monorepo’s modularity and Jest testing. Configuration includes connection setup, schemas, and dependency injection for scalability and maintainability.

text

Collapse

Wrap

Copy
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MongooseModule } from '@nestjs/mongoose';
import { RedisModule } from '@nestjs-modules/ioredis';
import { AuthRepository } from './auth.repository';
import { CoreRepository } from './core.repository';
import { PointsRepository, PointsTransactionSchema, RewardRedemptionSchema } from './points.repository';
import { ReferralsRepository } from './referrals.repository';
import { RFMAnalyticsRepository } from './rfm-analytics.repository';
import { ProductsRepository } from './products.repository';
import { AdminCoreRepository } from './admin-core.repository';
import { AdminFeaturesRepository } from './admin-features.repository';
import { CampaignRepository } from './campaign.repository';
import { EventTrackingRepository } from './event-tracking.repository';
import { ApiGatewayRepository } from './api-gateway.repository';
import { GamificationRepository } from './gamification.repository';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.AUTH_DB_HOST || 'localhost',
      port: parseInt(process.env.AUTH_DB_PORT) || 5432,
      username: process.env.AUTH_DB_USER || 'user',
      password: process.env.AUTH_DB_PASSWORD || 'password',
      database: process.env.AUTH_DB_NAME || 'auth_db',
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    TypeOrmModule.forRoot({
      name: 'core',
      type: 'postgres',
      host: process.env.CORE_DB_HOST || 'localhost',
      port: parseInt(process.env.CORE_DB_PORT) || 5433,
      username: process.env.CORE_DB_USER || 'user',
      password: process.env.CORE_DB_PASSWORD || 'password',
      database: process.env.CORE_DB_NAME || 'core_db',
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    TypeOrmModule.forRoot({
      name: 'referrals',
      type: 'postgres',
      host: process.env.REFERRALS_DB_HOST || 'localhost',
      port: parseInt(process.env.REFERRALS_DB_PORT) || 5434,
      username: process.env.REFERRALS_DB_USER || 'user',
      password: process.env.REFERRALS_DB_PASSWORD || 'password',
      database: process.env.REFERRALS_DB_NAME || 'referrals_db',
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    TypeOrmModule.forRoot({
      name: 'admin_core',
      type: 'postgres',
      host: process.env.ADMIN_CORE_DB_HOST || 'localhost',
      port: parseInt(process.env.ADMIN_CORE_DB_PORT) || 5436,
      username: process.env.ADMIN_CORE_DB_USER || 'user',
      password: process.env.ADMIN_CORE_DB_PASSWORD || 'password',
      database: process.env.ADMIN_CORE_DB_NAME || 'admin_core_db',
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    TypeOrmModule.forRoot({
      name: 'admin_features',
      type: 'postgres',
      host: process.env.ADMIN_FEATURES_DB_HOST || 'localhost',
      port: parseInt(process.env.ADMIN_FEATURES_DB_PORT) || 5437,
      username: process.env.ADMIN_FEATURES_DB_USER || 'user',
      password: process.env.ADMIN_FEATURES_DB_PASSWORD || 'password',
      database: process.env.ADMIN_FEATURES_DB_NAME || 'admin_features_db',
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    TypeOrmModule.forRoot({
      name: 'campaign',
      type: 'postgres',
      host: process.env.CAMPAIGN_DB_HOST || 'localhost',
      port: parseInt(process.env.CAMPAIGN_DB_PORT) || 5438,
      username: process.env.CAMPAIGN_DB_USER || 'user',
      password: process.env.CAMPAIGN_DB_PASSWORD || 'password',
      database: process.env.CAMPAIGN_DB_NAME || 'campaign_db',
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    TypeOrmModule.forRoot({
      name: 'event_tracking',
      type: 'postgres',
      host: process.env.EVENT_TRACKING_DB_HOST || 'localhost',
      port: parseInt(process.env.EVENT_TRACKING_DB_PORT) || 5439,
      username: process.env.EVENT_TRACKING_DB_USER || 'user',
      password: process.env.EVENT_TRACKING_DB_PASSWORD || 'password',
      database: process.env.EVENT_TRACKING_DB_NAME || 'event_tracking_db',
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
    MongooseModule.forRoot(`mongodb://${process.env.POINTS_DB_HOST || 'localhost'}:${process.env.POINTS_DB_PORT || 27017}/points_db`),
    MongooseModule.forFeature([
      { name: 'PointsTransaction', schema: PointsTransactionSchema },
      { name: 'RewardRedemption', schema: RewardRedemptionSchema },
    ]),
    RedisModule.forRoot({
      config: [
        {
          namespace: 'referrals',
          host: process.env.REFERRALS_REDIS_HOST || 'localhost',
          port: parseInt(process.env.REFERRALS_REDIS_PORT) || 6379,
        },
        {
          namespace: 'api_gateway',
          host: process.env.API_GATEWAY_REDIS_HOST || 'localhost',
          port: parseInt(process.env.API_GATEWAY_REDIS_PORT) || 6380,
        },
        {
          namespace: 'gamification',
          host: process.env.GAMIFICATION_REDIS_HOST || 'localhost',
          port: parseInt(process.env.GAMIFICATION_REDIS_PORT) || 6381,
        },
      ],
    }),
    TypeOrmModule.forRoot({
      name: 'rfm_analytics',
      type: 'postgres',
      host: process.env.RFM_ANALYTICS_DB_HOST || 'localhost',
      port: parseInt(process.env.RFM_ANALYTICS_DB_PORT) || 5435,
      username: process.env.RFM_ANALYTICS_DB_USER || 'user',
      password: process.env.RFM_ANALYTICS_DB_PASSWORD || 'password',
      database: process.env.RFM_ANALYTICS_DB_NAME || 'rfm_db',
      autoLoadEntities: true,
      synchronize: process.env.NODE_ENV !== 'production',
    }),
  ],
  providers: [
    AuthRepository,
    CoreRepository,
    PointsRepository,
    ReferralsRepository,
    RFMAnalyticsRepository,
    ProductsRepository,
    AdminCoreRepository,
    AdminFeaturesRepository,
    CampaignRepository,
    EventTrackingRepository,
    ApiGatewayRepository,
    GamificationRepository,
  ],
  exports: [
    AuthRepository,
    CoreRepository,
    PointsRepository,
    ReferralsRepository,
    RFMAnalyticsRepository,
    ProductsRepository,
    AdminCoreRepository,
    AdminFeaturesRepository,
    CampaignRepository,
    EventTrackingRepository,
    ApiGatewayRepository,
    GamificationRepository,
  ],
})
export class DatabaseModule {}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Merchant } from './entities/auth.entity';

@Injectable()
export class AuthRepository {
  constructor(
    @InjectRepository(Merchant)
    private readonly merchantRepo: Repository<Merchant>,
  ) {}

  async findByShopDomain(shopDomain: string): Promise<Merchant | null> {
    return this.merchantRepo.findOne({ where: { shop_domain: shopDomain } });
  }

  async createMerchant(merchant: Partial<Merchant>): Promise<Merchant> {
    return this.merchantRepo.save(merchant);
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Customer } from './entities/customer.entity';

@Injectable()
export class CustomerRepository {
  constructor(
    @InjectRepository(Customer, 'Customer')
    private readonly customerRepo: Repository<Customer>,
  ) {}

  async findById(id: string, merchantId: string): Promise<Customer | null> {
    return this.customerRepo.findOne({ where: { id, merchant_id: merchantId } });
  }

  async updateRFMScore(id: string, merchantId: string, rfmScore: any): Promise<void> {
    await this.customerRepo.update({ id, merchant_id: merchantId }, { rfm_score: rfmScore });
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Schema } from 'mongoose';
import { PointsTransaction } from './entities/points-transaction.entity';

export const PointsTransactionSchema = new Schema({
  id: { type: String, required: true },
  customer_id: { type: String, required: true },
  merchant_id: { type: String, required: true },
  points: { type: Number, required: true },
  type: { type: String, enum: ['earn', 'redeem', 'adjust'], required: true },
  reason: String,
  source: { type: String, enum: ['shopify', 'klaviyo', 'zapier', 'shopify_flow', 'manual'] },
  created_at: { type: Date, default: Date.now },
}, { collection: 'points_transactions' });

export const RewardRedemptionSchema = new Schema({
  id: { type: String, required: true },
  customer_id: { type: String, required: true },
  merchant_id: { type: String, required: true },
  campaign_id: { type: String, required: true },
  points: { type: Number, required: true },
  created_at: { type: Date, default: Date.now },
}, { collection: 'reward_redemptions' });

@Injectable()
export class PointsRepository {
  constructor(
    @InjectModel('PointsTransaction') private readonly transactionModel: Model<PointsTransaction>,
  ) {}

  async createTransaction(transaction: Partial<PointsTransaction>): Promise<PointsTransaction> {
    return this.transactionModel.create(transaction);
  }

  async getBalance(customerId: string, merchantId: string): Promise<number> {
    const result = await this.transactionModel.aggregate([
      { $match: { customer_id: customerId, merchant_id: merchantId } },
      { $group: { _id: null, total: { $sum: '$points' } } },
    ]);
    return result[0]?.total || 0;
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectRedis } from '@nestjs-modules/ioredis';
import { Redis } from 'ioredis';
import { Referral } from './entities/referral.entity';

@Injectable()
export class ReferralsRepository {
  constructor(
    @InjectRedis('referrals') private readonly redis: Redis,
    @InjectRepository(Referral, 'referrals') private readonly referralRepo: Repository<Referral>,
  ) {}

  async getReferral(id: string, merchantId: string): Promise<Referral | null> {
    const key = `referral:${merchantId}:${id}`;
    const cached = await this.redis.hgetall(key);
    if (cached.id) return cached as Referral;
    const referral = await this.referralRepo.findOne({ where: { id, merchant_id: merchantId } });
    if (referral) {
      await this.redis.hset(key, referral);
      await this.redis.expire(key, 3600);
    }
    return referral;
  }

  async createReferral(referral: Partial<Referral>): Promise<Referral> {
    const saved = await this.referralRepo.save(referral);
    const key = `referral:${saved.merchant_id}:${saved.id}`;
    await this.redis.hset(key, saved);
    await this.redis.xadd(`status:${saved.id}`, '*', { status: saved.status, timestamp: new Date().toISOString() });
    return saved;
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { RFMSegmentDelta } from './entities/rfm-segment-delta.entity';

@Injectable()
export class RFMAnalyticsRepository {
  constructor(
    @InjectDataSource('rfm_analytics') private readonly dataSource: DataSource,
  ) {}

  async createDelta(delta: Partial<RFMSegmentDelta>): Promise<void> {
    await this.dataSource.query(
      `INSERT INTO rfm_segment_deltas (id, merchant_id, customer_id, rfm_score, metadata, operation, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
      [delta.id, delta.merchant_id, delta.customer_id, delta.rfm_score, delta.metadata, delta.operation],
    );
  }

  async getSegmentCounts(merchantId: string): Promise<any[]> {
    return this.dataSource.query(
      `SELECT segment_id, name, count, conditions FROM rfm_segment_counts WHERE merchant_id = $1`,
      [merchantId],
    );
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { ElasticsearchService } from '@nestjs/elasticsearch';

@Injectable()
export class ProductsRepository {
  constructor(private readonly elasticsearch: ElasticsearchService) {}

  async searchProducts(merchantId: string, query: string): Promise<any[]> {
    const { hits } = await this.elasticsearch.search({
      index: 'products',
      body: {
        query: {
          bool: {
            filter: { term: { merchant_id: merchantId } },
            must: { multi_match: { query, fields: ['name'] } },
          },
        },
      },
    });
    return hits.hits.map(hit => hit._source);
  }

  async createProduct(product: any): Promise<void> {
    await this.elasticsearch.index({
      index: 'products',
      id: product.id,
      body: product,
    });
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from './entities/audit-log.entity';

@Injectable()
export class AdminCoreRepository {
  constructor(
    @InjectRepository(AuditLog, 'admin_core') private readonly auditLogRepo: Repository<AuditLog>,
  ) {}

  async createAuditLog(log: Partial<AuditLog>): Promise<AuditLog> {
    return this.auditLogRepo.save(log);
  }

  async getAuditLogs(merchantId: string): Promise<AuditLog[]> {
    return this.auditLogRepo.find({ where: { merchant_id: merchantId } });
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmailTemplate } from './entities/email-template.entity';

@Injectable()
export class AdminFeaturesRepository {
  constructor(
    @InjectRepository(EmailTemplate, 'admin_features') private readonly emailTemplateRepo: Repository<EmailTemplate>,
  ) {}

  async createEmailTemplate(template: Partial<EmailTemplate>): Promise<EmailTemplate> {
    return this.emailTemplateRepo.save(template);
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { VIPTier } from './entities/vip-tier.entity';

@Injectable()
export class CampaignRepository {
  constructor(
    @InjectRepository(VIPTier, 'campaign') private readonly vipTierRepo: Repository<VIPTier>,
  ) {}

  async createVIPTier(tier: Partial<VIPTier>): Promise<VIPTier> {
    return this.vipTierRepo.save(tier);
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { QueueTask } from './entities/queue-task.entity';

@Injectable()
export class EventTrackingRepository {
  constructor(
    @InjectRepository(QueueTask, 'event_tracking') private readonly queueTaskRepo: Repository<QueueTask>,
  ) {}

  async createTask(task: Partial<QueueTask>): Promise<QueueTask> {
    return this.queueTaskRepo.save(task);
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRedis } from '@nestjs-modules/ioredis';
import { Redis } from 'ioredis';

@Injectable()
export class ApiGatewayRepository {
  constructor(@InjectRedis('api_gateway') private readonly redis: Redis) {}

  async trackRateLimit(merchantId: string, endpoint: string): Promise<number> {
    const key = `rate_limit:${merchantId}:${endpoint}`;
    const count = await this.redis.incr(key);
    if (count === 1) await this.redis.expire(key, 3600);
    return count;
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { InjectRedis } from '@nestjs-modules/ioredis';
import { Redis } from 'ioredis';

@Injectable()
export class GamificationRepository {
  constructor(@InjectRedis('gamification') private readonly redis: Redis) {}

  async awardBadge(merchantId: string, customerId: string, badge: string): Promise<void> {
    const key = `badge:${merchantId}:${customerId}:${badge}`;
    await this.redis.set(key, 1);
    await this.redis.zincrby(`leaderboard:${merchantId}`, 1, customerId);
  }
}
Show in sidebar
Kafka Handler
The Kafka handler ensures cross-service eventual consistency by producing and consuming events like points.earned, referral.completed, and rfm.updated. It’s implemented as a shared library (libs/kafka) and used in service-specific event handlers (e.g., apps/points/src/points.service.ts). The handler supports your requirement for saga patterns to coordinate updates across services (e.g., Points → RFM Analytics → Core).

text

Collapse

Wrap

Copy
import { Module } from '@nestjs/common';
import { KafkaModule as NestKafkaModule } from '@nestjs/microservices';
import { KafkaProducer } from './kafka.producer';
import { KafkaConsumer } from './kafka.consumer';

@Module({
  imports: [
    NestKafkaModule.forRoot({
      client: {
        clientId: 'loyalnest',
        brokers: [process.env.KAFKA_BROKER || 'localhost:9092'],
      },
      consumer: {
        groupId: 'loyalnest-group',
      },
    }),
  ],
  providers: [KafkaProducer, KafkaConsumer],
  exports: [KafkaProducer, KafkaConsumer],
})
export class KafkaModule {}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { Kafka } from '@nestjs/microservices';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class KafkaProducer {
  constructor(private readonly kafka: Kafka) {}

  async send(topic: string, message: any): Promise<void> {
    await this.kafka.emit(topic, {
      key: uuidv4(),
      value: JSON.stringify(message),
    });
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { Kafka, Consumer } from '@nestjs/microservices';

@Injectable()
export class KafkaConsumer {
  private consumer: Consumer;

  constructor(private readonly kafka: Kafka) {
    this.consumer = this.kafka.createConsumer({
      groupId: 'loyalnest-group',
    });
  }

  async subscribe(topic: string, callback: (message: any) => Promise<void>): Promise<void> {
    await this.consumer.subscribe({ topic });
    this.consumer.on('message', async ({ value }) => {
      try {
        const message = JSON.parse(value.toString());
        await callback(message);
      } catch (error) {
        console.error(`Error processing ${topic}:`, error);
      }
    });
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { PointsRepository } from '@loyalnest/database';
import { KafkaProducer } from '@loyalnest/kafka';

@Injectable()
export class PointsService {
  constructor(
    private readonly pointsRepo: PointsRepository,
    private readonly kafkaProducer: KafkaProducer,
  ) {}

  async createTransaction(dto: { customerId: string; merchantId: string; points: number; type: string }) {
    const transaction = await this.pointsRepo.createTransaction({
      id: uuidv4(),
      customer_id: dto.customerId,
      merchant_id: dto.merchantId,
      points: dto.points,
      type: dto.type,
      source: 'shopify',
    });
    await this.kafkaProducer.send('points.earned', {
      customer_id: dto.customerId,
      merchant_id: dto.merchantId,
      points: dto.points,
      transaction_id: transaction.id,
    });
    await this.kafkaProducer.send('audit_log', {
      merchant_id: dto.merchantId,
      entity_type: 'points_transactions',
      entity_id: transaction.id,
      action: 'created',
      severity: 'info',
    });
    return transaction;
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { ReferralsRepository } from '@loyalnest/database';
import { KafkaProducer } from '@loyalnest/kafka';

@Injectable()
export class ReferralsService {
  constructor(
    private readonly referralsRepo: ReferralsRepository,
    private readonly kafkaProducer: KafkaProducer,
  ) {}

  async createReferral(dto: { customerId: string; merchantId: string; referralLinkId: string }) {
    const referral = await this.referralsRepo.createReferral({
      id: uuidv4(),
      customer_id: dto.customerId,
      merchant_id: dto.merchantId,
      referral_link_id: dto.referralLinkId,
      status: 'pending',
    });
    await this.kafkaProducer.send('referral.created', {
      customer_id: dto.customerId,
      merchant_id: dto.merchantId,
      referral_id: referral.id,
    });
    return referral;
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable, OnModuleInit } from '@nestjs/common';
import { RFMAnalyticsRepository, CoreRepository } from '@loyalnest/database';
import { KafkaConsumer } from '@loyalnest/kafka';

@Injectable()
export class RFMAnalyticsService implements OnModuleInit {
  constructor(
    private readonly rfmRepo: RFMAnalyticsRepository,
    private readonly coreRepo: CoreRepository,
    private readonly kafkaConsumer: KafkaConsumer,
  ) {}

  async onModuleInit() {
    await this.kafkaConsumer.subscribe('points.earned', async (message) => {
      await this.calculateRFMScore(message.merchant_id, message.customer_id, message.points);
    });
    await this.kafkaConsumer.subscribe('referral.created', async (message) => {
      await this.calculateRFMScore(message.merchant_id, message.customer_id, 0);
    });
  }

  async calculateRFMScore(merchantId: string, customerId: string, points: number) {
    // Simplified RFM calculation
    const rfmScore = { recency: '1', frequency: '1', monetary: '1', score: 1.0 };
    await this.rfmRepo.createDelta({
      id: uuidv4(),
      merchant_id: merchantId,
      customer_id: customerId,
      rfm_score: rfmScore,
      operation: 'insert',
      metadata: { lifecycle_stage: 'active' },
    });
    await this.coreRepo.updateRFMScore(customerId, merchantId, rfmScore);
    await this.kafkaConsumer.send('rfm.updated', { merchant_id: merchantId, customer_id: customerId, rfm_score: rfmScore });
  }
}
Show in sidebar
Implementation Notes
Database Config:
Use environment variables for connection settings (e.g., .env.local for development).
synchronize: true is disabled in production to prevent schema drift.
Entities (entities/*.entity.ts) are assumed to match schemas from core_schema.txt and auxiliary_schema.txt.
Kafka Handler:
Deploy Kafka on the VPS with Docker Compose (add kafka service to docker-compose.yml).
Topics: points.earned, referral.created, rfm.updated, audit_log.
Saga pattern: Points → RFM Analytics → Core ensures eventual consistency.
Testing:
Jest: Mock database drivers and Kafka in libs/database/*.spec.ts and libs/kafka/*.spec.ts.
Cypress: Test endpoints (/points.v1/GetPointsBalance, /referrals.v1/GetReferralStatus).
k6: Validate 10,000 orders/hour.
GDPR/CCPA:
PII encryption in core.customers.email and admin_features.integrations.credentials.
Audit logs via Kafka to admin_core.audit_logs.
Would you like a Jest test suite for libs/database, a Docker Compose update including Kafka, or a specific entity definition (e.g., Customer.entity.ts)?







pls provide a jest test suite for libs/database


To support LoyalNest’s microservices architecture with service-dedicated databases in Phase 3 (October 2025–February 2026), I’ll provide a Jest test suite for the libs/database library in your Nx monorepo. The test suite will cover the repository classes defined in the previous TypeScript configuration for libs/database (Auth, Core, Points, Referrals, RFM Analytics, Products, AdminCore, AdminFeatures, Campaign, Event Tracking, API Gateway, Gamification). Each test mocks the respective database driver (TypeORM for PostgreSQL, Mongoose for MongoDB, ioredis for Redis, TimescaleDB driver for RFM Analytics, Elasticsearch client for Products) to ensure unit tests are fast and isolated. The suite aligns with your requirements for scalability (10,000 orders/hour), GDPR/CCPA compliance, and the TVP deadline, and it integrates with your Nx monorepo’s testing setup.

Jest Test Suite for libs/database
The test suite is organized by repository, with mocks for database interactions. Tests verify key operations (e.g., CRUD, queries) while avoiding real database connections. The suite uses Jest’s mocking capabilities and assumes the libs/database structure from the provided TypeScript configuration.

text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuthRepository } from './auth.repository';
import { Merchant } from './entities/auth.entity';

describe('AuthRepository', () => {
  let repository: AuthRepository;
  let mockRepo: jest.Mocked<Repository<Merchant>>;

  beforeEach(async () => {
    mockRepo = {
      findOne: jest.fn(),
      save: jest.fn(),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthRepository,
        {
          provide: getRepositoryToken(Merchant),
          useValue: mockRepo,
        },
      ],
    }).compile();

    repository = module.get<AuthRepository>(AuthRepository);
  });

  it('should find merchant by shop domain', async () => {
    const shopDomain = 'test-shop.myshopify.com';
    const merchant = { id: 'uuid1', shop_domain: shopDomain };
    mockRepo.findOne.mockResolvedValue(merchant as Merchant);

    const result = await repository.findByShopDomain(shopDomain);
    expect(result).toEqual(merchant);
    expect(mockRepo.findOne).toHaveBeenCalledWith({ where: { shop_domain: shopDomain } });
  });

  it('should create a merchant', async () => {
    const merchant = { shop_domain: 'new-shop.myshopify.com' };
    const savedMerchant = { id: 'uuid2', ...merchant };
    mockRepo.save.mockResolvedValue(savedMerchant as Merchant);

    const result = await repository.createMerchant(merchant);
    expect(result).toEqual(savedMerchant);
    expect(mockRepo.save).toHaveBeenCalledWith(merchant);
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CoreRepository } from './core.repository';
import { Customer } from './entities/customer.entity';

describe('CoreRepository', () => {
  let repository: CoreRepository;
  let mockRepo: jest.Mocked<Repository<Customer>>;

  beforeEach(async () => {
    mockRepo = {
      findOne: jest.fn(),
      update: jest.fn(),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CoreRepository,
        {
          provide: getRepositoryToken(Customer, 'core'),
          useValue: mockRepo,
        },
      ],
    }).compile();

    repository = module.get<CoreRepository>(CoreRepository);
  });

  it('should find customer by id and merchant id', async () => {
    const customer = { id: 'uuid1', merchant_id: 'uuid2', email: 'test@example.com' };
    mockRepo.findOne.mockResolvedValue(customer as Customer);

    const result = await repository.findById('uuid1', 'uuid2');
    expect(result).toEqual(customer);
    expect(mockRepo.findOne).toHaveBeenCalledWith({ where: { id: 'uuid1', merchant_id: 'uuid2' } });
  });

  it('should update RFM score', async () => {
    const rfmScore = { recency: '1', frequency: '1', monetary: '1' };
    mockRepo.update.mockResolvedValue({ affected: 1 } as any);

    await repository.updateRFMScore('uuid1', 'uuid2', rfmScore);
    expect(mockRepo.update).toHaveBeenCalledWith(
      { id: 'uuid1', merchant_id: 'uuid2' },
      { rfm_score: rfmScore },
    );
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PointsRepository } from './points.repository';
import { PointsTransaction } from './entities/points-transaction.entity';

describe('PointsRepository', () => {
  let repository: PointsRepository;
  let mockModel: jest.Mocked<Model<PointsTransaction>>;

  beforeEach(async () => {
    mockModel = {
      create: jest.fn(),
      aggregate: jest.fn(),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PointsRepository,
        {
          provide: getModelToken('PointsTransaction'),
          useValue: mockModel,
        },
      ],
    }).compile();

    repository = module.get<PointsRepository>(PointsRepository);
  });

  it('should create a points transaction', async () => {
    const transaction = { id: 'uuid1', customer_id: 'uuid2', merchant_id: 'uuid3', points: 100, type: 'earn' };
    mockModel.create.mockResolvedValue(transaction as any);

    const result = await repository.createTransaction(transaction);
    expect(result).toEqual(transaction);
    expect(mockModel.create).toHaveBeenCalledWith(transaction);
  });

  it('should get points balance', async () => {
    mockModel.aggregate.mockReturnValue({
      exec: jest.fn().mockResolvedValue([{ total: 500 }]),
    } as any);

    const result = await repository.getBalance('uuid2', 'uuid3');
    expect(result).toBe(500);
    expect(mockModel.aggregate).toHaveBeenCalledWith([
      { $match: { customer_id: 'uuid2', merchant_id: 'uuid3' } },
      { $group: { _id: null, total: { $sum: '$points' } } },
    ]);
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Redis } from 'ioredis';
import { ReferralsRepository } from './referrals.repository';
import { Referral } from './entities/referral.entity';

describe('ReferralsRepository', () => {
  let repository: ReferralsRepository;
  let mockRepo: jest.Mocked<Repository<Referral>>;
  let mockRedis: jest.Mocked<Redis>;

  beforeEach(async () => {
    mockRepo = { findOne: jest.fn(), save: jest.fn() } as any;
    mockRedis = {
      hgetall: jest.fn(),
      hset: jest.fn(),
      xadd: jest.fn(),
      expire: jest.fn(),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReferralsRepository,
        { provide: getRepositoryToken(Referral, 'referrals'), useValue: mockRepo },
        { provide: 'REDIS_CONNECTION_referrals', useValue: mockRedis },
      ],
    }).compile();

    repository = module.get<ReferralsRepository>(ReferralsRepository);
  });

  it('should get referral from cache', async () => {
    const referral = { id: 'uuid1', merchant_id: 'uuid2', referral_link_id: 'link1' };
    mockRedis.hgetall.mockResolvedValue(referral);

    const result = await repository.getReferral('uuid1', 'uuid2');
    expect(result).toEqual(referral);
    expect(mockRedis.hgetall).toContain(`referral:uuid2:uuid1`);
  });

  it('should create a referral', async () => {
    const referral = await repository.createReferral({
      customer_id: 'uuid3',
      merchant_id: 'uuid2',
      referral_link_id: 'link2',
      status: 'pending',
    });
    expect(mockRepo.create).toHaveBeenCalledWith(referral});
    expect(mockRedis.hset).toHaveBeenCalledWith(`referral:${referral.merchant_id}:${referral.id}`, referral);
    expect(mockRedis.xadd).toHaveBeenCalledWith(
      `status:${referral.id}`,
      '*',
      { status: 'pending', timestamp: expect.any(String) },
    );
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getDataSourceToken } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { RFMAnalyticsRepository } from './rfm-analytics.repository';

describe('RFMAnalyticsRepository', () => {
  let repository: RFMAnalyticsRepository;
  let mockDataSource: jest.Mocked<DataSource>;

  beforeEach(async () => {
    mockDataSource = { query: jest.fn() } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RFMAnalyticsRepository,
        { provide: getDataSourceToken('rfm_analytics'), useValue: mockDataSource },
      ],
    }).compile();

    repository = module.get<RFMAnalyticsRepository>(RFMAnalyticsRepository);
  });

  it('should create RFM segment delta', async () => {
    const delta = {
      id: 'uuid1',
      merchant_id: 'uuid2',
      customer_id: 'uuid3',
      rfm_score: { recency: '1' },
      metadata: { lifecycle_stage: 'active' },
      operation: 'insert',
    };
    mockDataSource.query.mockResolvedValue(undefined);

    await repository.createDelta(delta);
    expect(mockDataSource.query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO rfm_segment_deltas'),
      [delta.id, delta.merchant_id, delta.customer_id, delta.rfm_score, delta.metadata, delta.operation],
    );
  });

  it('should get segment counts', async () => {
    const counts = [{ segment_id: 'seg_111', count: 100 }];
    mockDataSource.query.mockResolvedValue(counts);

    const result = await repository.getSegmentCounts('uuid2');
    expect(result).toEqual(counts);
    expect(mockDataSource.query).toHaveBeenCalledWith(
      expect.stringContaining('SELECT segment_id'),
      ['uuid2'],
    );
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { ElasticsearchService } from '@nestjs/elasticsearch';
import { ProductsRepository } from './products.repository';

describe('ProductsRepository', () => {
  let repository: ProductsRepository;
  let mockElasticsearch: jest.Mocked<ElasticsearchService>;

  beforeEach(async () => {
    mockElasticsearch = { search: jest.fn(), index: jest.fn() } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProductsRepository,
        { provide: ElasticsearchService, useValue: mockElasticsearch },
      ],
    }).compile();

    repository = module.get<ProductsRepository>(ProductsRepository);
  });

  it('should search products', async () => {
    const hits = [{ _source: { id: 'uuid1', name: 'Product1' } }];
    mockElasticsearch.search.mockResolvedValue({ body: { hits: { hits } } } as any);

    const result = await repository.searchProducts('uuid2', 'Product1');
    expect(result).toEqual(hits.map(h => h._source));
    expect(mockElasticsearch.search).toHaveBeenCalledWith({
      index: 'products',
      body: expect.any(Object),
    });
  });

  it('should create a product', async () => {
    const product = { id: 'uuid1', name: 'Product1' };
    mockElasticsearch.index.mockResolvedValue(undefined);

    await repository.createProduct(product);
    expect(mockElasticsearch.index).toHaveBeenCalledWith({
      index: 'products',
      id: product.id,
      body: product,
    });
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AdminCoreRepository } from './admin-core.repository';
import { AuditLog } from './entities/audit-log.entity';

describe('AdminCoreRepository', () => {
  let repository: AdminCoreRepository;
  let mockRepo: jest.Mocked<Repository<AuditLog>>;

  beforeEach(async () => {
    mockRepo = { save: jest.fn(), find: jest.fn() } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminCoreRepository,
        { provide: getRepositoryToken(AuditLog, 'admin_core'), useValue: mockRepo },
      ],
    }).compile();

    repository = module.get<AdminCoreRepository>(AdminCoreRepository);
  });

  it('should create an audit log', async () => {
    const log = { merchant_id: 'uuid1', entity_type: 'points', action: 'created' };
    mockRepo.save.mockResolvedValue(log as AuditLog);

    const result = await repository.createAuditLog(log);
    expect(result).toEqual(log);
    expect(mockRepo.save).toHaveBeenCalledWith(log);
  });

  it('should get audit logs', async () => {
    const logs = [{ id: 'uuid1', merchant_id: 'uuid2' }];
    mockRepo.find.mockResolvedValue(logs as AuditLog[]);

    const result = await repository.getAuditLogs('uuid2');
    expect(result).toEqual(logs);
    expect(mockRepo.find).toHaveBeenCalledWith({ where: { merchant_id: 'uuid2' } });
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AdminFeaturesRepository } from './admin-features.repository';
import { EmailTemplate } from './entities/email-template.entity';

describe('AdminFeaturesRepository', () => {
  let repository: AdminFeaturesRepository;
  let mockRepo: jest.Mocked<Repository<EmailTemplate>>;

  beforeEach(async () => {
    mockRepo = { save: jest.fn() } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminFeaturesRepository,
        { provide: getRepositoryToken(EmailTemplate, 'admin_features'), useValue: mockRepo },
      ],
    }).compile();

    repository = module.get<AdminFeaturesRepository>(AdminFeaturesRepository);
  });

  it('should create an email template', async () => {
    const template = { merchant_id: 'uuid1', template_id: 'welcome', content: {} };
    mockRepo.save.mockResolvedValue(template as EmailTemplate);

    const result = await repository.createEmailTemplate(template);
    expect(result).toEqual(template);
    expect(mockRepo.save).toHaveBeenCalledWith(template);
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CampaignRepository } from './campaign.repository';
import { VIPTier } from './entities/vip-tier.entity';

describe('CampaignRepository', () => {
  let repository: CampaignRepository;
  let mockRepo: jest.Mocked<Repository<VIPTier>>;

  beforeEach(async () => {
    mockRepo = { save: jest.fn() } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CampaignRepository,
        { provide: getRepositoryToken(VIPTier, 'campaign'), useValue: mockRepo },
      ],
    }).compile();

    repository = module.get<CampaignRepository>(CampaignRepository);
  });

  it('should create a VIP tier', async () => {
    const tier = { merchant_id: 'uuid1', tier_id: 'gold', config: {} };
    mockRepo.save.mockResolvedValue(tier as VIPTier);

    const result = await repository.createVIPTier(tier);
    expect(result).toEqual(tier);
    expect(mockRepo.save).toHaveBeenCalledWith(tier);
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EventTrackingRepository } from './event-tracking.repository';
import { QueueTask } from './entities/queue-task.entity';

describe('EventTrackingRepository', () => {
  let repository: EventTrackingRepository;
  let mockRepo: jest.Mocked<Repository<QueueTask>>;

  beforeEach(async () => {
    mockRepo = { save: jest.fn() } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EventTrackingRepository,
        { provide: getRepositoryToken(QueueTask, 'event_tracking'), useValue: mockRepo },
      ],
    }).compile();

    repository = module.get<EventTrackingRepository>(EventTrackingRepository);
  });

  it('should create a queue task', async () => {
    const task = { merchant_id: 'uuid1', task_type: 'send_email', status: 'pending' };
    mockRepo.save.mockResolvedValue(task as QueueTask);

    const result = await repository.createTask(task);
    expect(result).toEqual(task);
    expect(mockRepo.save).toHaveBeenCalledWith(task);
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { Redis } from 'ioredis';
import { ApiGatewayRepository } from './api-gateway.repository';

describe('ApiGatewayRepository', () => {
  let repository: ApiGatewayRepository;
  let mockRedis: jest.Mocked<Redis>;

  beforeEach(async () => {
    mockRedis = { incr: jest.fn(), expire: jest.fn() } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ApiGatewayRepository,
        { provide: 'REDIS_CONNECTION_api_gateway', useValue: mockRedis },
      ],
    }).compile();

    repository = module.get<ApiGatewayRepository>(ApiGatewayRepository);
  });

  it('should track rate limit', async () => {
    mockRedis.incr.mockResolvedValue(1);
    mockRedis.expire.mockResolvedValue(1);

    const result = await repository.trackRateLimit('uuid1', '/orders');
    expect(result).toBe(1);
    expect(mockRedis.incr).toHaveBeenCalledWith('rate_limit:uuid1:/orders');
    expect(mockRedis.expire).toHaveBeenCalledWith('rate_limit:uuid1:/orders', 3600);
  });
});
Show in sidebar
text

Collapse

Wrap

Copy
import { Test, TestingModule } from '@nestjs/testing';
import { Redis } from 'ioredis';
import { GamificationRepository } from './gamification.repository';

describe('GamificationRepository', () => {
  let repository: GamificationRepository;
  let mockRedis: jest.Mocked<Redis>;

  beforeEach(async () => {
    mockRedis = { set: jest.fn(), zincrby: jest.fn() } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GamificationRepository,
        { provide: 'REDIS_CONNECTION_gamification', useValue: mockRedis },
      ],
    }).compile();

    repository = module.get<GamificationRepository>(GamificationRepository);
  });

  it('should award a badge', async () => {
    mockRedis.set.mockResolvedValue('OK');
    mockRedis.zincrby.mockResolvedValue('1');

    await repository.awardBadge('uuid1', 'uuid2', 'loyal_customer');
    expect(mockRedis.set).toHaveBeenCalledWith('badge:uuid1:uuid2:loyal_customer', 1);
    expect(mockRedis.zincrby).toHaveBeenCalledWith('leaderboard:uuid1', 1, 'uuid2');
  });
});
Show in sidebar
Implementation Notes
Setup:
Place test files in libs/database/test/ within your Nx monorepo.
Run tests: nx test database.
Ensure dependencies (@nestjs/testing, @nestjs/typeorm, @nestjs/mongoose, @nestjs-modules/ioredis, @nestjs/elasticsearch) are in package.json.
Mocks:
TypeORM: Mock Repository with getRepositoryToken.
Mongoose: Mock Model with getModelToken.
Redis: Mock ioredis with REDIS_CONNECTION_{namespace}.
TimescaleDB: Mock DataSource with getDataSourceToken.
Elasticsearch: Mock ElasticsearchService.
Entities:
Assumes entity files (entities/*.entity.ts) exist, matching schemas from core_schema.txt and auxiliary_schema.txt.
Example: Customer.entity.ts defines id, merchant_id, email, rfm_score.
Coverage:
Tests cover primary methods (e.g., create, find, update) for each repository.
Add edge cases (e.g., null results, errors) as needed.
Integration:
Combine with Cypress E2E tests for endpoints (/points.v1/GetPointsBalance).
Use k6 for load testing (10,000 orders/hour).
GDPR/CCPA:
Tests verify PII handling (e.g., CoreRepository for customers.email).
Audit logs tested in AdminCoreRepository.
Would you like a sample entity definition (e.g., Customer.entity.ts), a Docker Compose update with Kafka, or additional test cases for edge scenarios?








yes, i need a entity definition for customer




To support LoyalNest’s microservices architecture with dedicated databases in Phase 3 (October 2025–February 2026), I’ll provide a TypeScript entity definition for the Customer entity in the libs/database library of your Nx monorepo. This entity corresponds to the customers table in the Core service’s PostgreSQL database, as defined in core_schema.txt. The entity will work with TypeORM, include GDPR/CCPA-compliant PII encryption for the email field, and align with your requirements for scalability (10,000 orders/hour) and the TVP deadline. The definition includes fields like id, merchant_id, email, rfm_score, metadata, created_at, and updated_at, with appropriate TypeORM decorators for schema mapping and triggers.

Customer Entity Definition
The Customer entity is defined in libs/database/entities/customer.entity.ts and integrates with the CoreRepository from the previous libs/database configuration. It uses TypeORM decorators to map to the customers table, enables encryption for email, and includes JSONB fields for rfm_score and metadata.

text

Collapse

Wrap

Copy
import { Entity, Column, PrimaryGeneratedColumn, Index, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('customers')
export class Customer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid', nullable: false })
  merchant_id: string;

  @Column({
    type: 'varchar',
    length: 255,
    transformer: {
      to: (value: string) => value, // Encryption handled by pgcrypto in DB
      from: (value: string) => value, // Decryption handled by pgcrypto in DB
    },
  })
  email: string;

  @Column({ type: 'jsonb', nullable: true })
  rfm_score: Record<string, any>;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;
}
Show in sidebar
Implementation Notes
Schema Mapping:
Matches core_schema.sql from the Core service’s PostgreSQL database.
id: UUID primary key, auto-generated.
merchant_id: UUID, indexed for fast lookups by merchant.
email: VARCHAR(255), encrypted with pgcrypto (AES-256-GCM) for GDPR/CCPA compliance.
rfm_score: JSONB for flexible RFM data (e.g., { recency: '1', frequency: '1', monetary: '1' }).
metadata: JSONB for additional customer data.
created_at, updated_at: Timestamps managed by TypeORM’s @CreateDateColumn and @UpdateDateColumn.
Triggers:
Relies on the database’s trg_customers_updated_at trigger (from core_schema.sql) to update updated_at via the update_updated_at_column function.
Indexes:
merchant_id: Index for efficient filtering by merchant.
Additional indexes (idx_customers_email, idx_customers_rfm_score) are defined in the database schema but not repeated here, as TypeORM uses database-level indexes.
GDPR/CCPA Compliance:
email uses a TypeORM transformer placeholder; actual encryption is handled by PostgreSQL’s pgcrypto (ENCRYPTED WITH clause in core_schema.sql).
Queries involving email (e.g., in CoreRepository) must use pgcrypto functions (decrypt, encrypt) in raw SQL if needed.
Usage in CoreRepository:
Integrates with CoreRepository methods like findById and updateRFMScore from the previous libs/database configuration.
Example:
typescript

Collapse

Wrap

Run

Copy
async findById(id: string, merchantId: string): Promise<Customer | null> {
  return this.customerRepo.findOne({ where: { id, merchant_id: merchantId } });
}
Testing:
Covered by core.repository.spec.ts (e.g., findById, updateRFMScore tests).
Add Jest tests for edge cases (e.g., missing rfm_score) if needed.
Nx Monorepo:
Place in libs/database/entities/customer.entity.ts.
Ensure TypeORM loads the entity via autoLoadEntities: true in DatabaseModule (from libs_database_index.ts).
Dependencies:
Requires typeorm and @nestjs/typeorm in package.json.
Update tsconfig.json to include experimentalDecorators and emitDecoratorMetadata.
Would you like additional entity definitions (e.g., Merchant.entity.ts or PointsTransaction.entity.ts), a Jest test suite specifically for the Customer entity, or a Docker Compose update including Kafka to complement the Kafka handler from the previous response?








why kafka handler only applied to events like points.earned, referral.completed and rfm.updated, are other service do not need kafka?




The Kafka handler in the previous response was tailored to events like points.earned, referral.completed, and rfm.updated because these events are critical for cross-service coordination in LoyalNest’s Phase 3 microservices architecture (October 2025–February 2026), particularly for the high-priority Points, Referrals, and RFM Analytics services needed for the TVP deadline. These events drive eventual consistency across services (e.g., Points updating RFM scores in Core via RFM Analytics) and align with your scalability requirements (10,000 orders/hour). However, other services (e.g., Auth, Core, AdminCore, AdminFeatures, Campaign, Event Tracking, API Gateway, Gamification, Products) may also benefit from Kafka for specific use cases. Below, I’ll explain why the handler focused on those events, assess whether other services need Kafka, and propose a broader Kafka integration where applicable.

Why Kafka Handler Focused on points.earned, referral.completed, and rfm.updated
Critical Cross-Service Dependencies:
Points Service: Emits points.earned when a customer earns points (e.g., via Shopify orders/create webhook). This triggers RFM Analytics to recalculate rfm_score and Core to update customers.rfm_score, ensuring loyalty metrics stay consistent.
Referrals Service: Emits referral.completed when a referral converts (e.g., 7% SMS conversion). This triggers Points to award points and RFM Analytics to update scores, linking referral success to loyalty metrics.
RFM Analytics: Emits rfm.updated after recalculating scores, notifying Core to persist changes in customers.rfm_score and potentially other services (e.g., Campaign for VIP tier updates).
These events form a saga pattern (Points → RFM Analytics → Core), ensuring eventual consistency across services without tight coupling.
High-Volume and Real-Time Needs:
Points and Referrals handle high-throughput workloads (10,000 orders/hour, 7% SMS conversion), requiring asynchronous event-driven updates to avoid bottlenecks.
RFM Analytics processes time-series data daily (0 1 * * *), but real-time events like points.earned trigger incremental updates for accuracy.
Kafka’s pub-sub model supports this by decoupling producers (e.g., Points) from consumers (e.g., RFM Analytics), enabling parallel processing and fault tolerance.
TVP Prioritization:
Your TVP deadline (February 2026) prioritizes Points, Referrals, and RFM Analytics for Shopify App Store listing. The Kafka handler focuses on these services to ensure their core workflows (points tracking, referral conversions, customer segmentation) are robust and scalable.
Other services (e.g., AdminCore, Campaign) are secondary for TVP, with lower real-time or cross-service demands in Phase 3.
Audit Logging:
The handler also includes audit_log events (e.g., from Points’ createTransaction) to log actions in admin_core.audit_logs for GDPR/CCPA compliance, covering critical state changes across prioritized services.
Do Other Services Need Kafka?
To determine whether other services (Auth, Core, AdminCore, AdminFeatures, Campaign, Event Tracking, API Gateway, Gamification, Products) need Kafka, I’ll evaluate their access patterns, cross-service interactions, and Phase 3 requirements based on your core_schema.txt, auxiliary_schema.txt, and microservices design.

Services and Kafka Applicability

Service	Kafka Need	Rationale and Potential Events
Auth	Low	Manages merchants, admin_users, sessions. Minimal cross-service interaction; mostly synchronous gRPC queries (e.g., /auth.v1/ValidateToken for API Gateway). Potential event: merchant.created to notify Core for customers setup, but low priority for Phase 3.
Core	Medium	Stores customers, program_settings. Consumes rfm.updated to update customers.rfm_score. Could emit customer.created or customer.updated for Campaign (VIP tiers) or AdminFeatures (email triggers), but synchronous gRPC (/core.v1/GetCustomerRFM) suffices for now.
AdminCore	Medium	Handles audit_logs, gdpr_requests. Consumes audit_log events from Points, Referrals for compliance. Could emit gdpr_request.created to notify services (e.g., Core for PII redaction), but low volume makes direct DB writes or gRPC viable.
AdminFeatures	Low	Manages email_templates, email_events. Could emit email_event.created for Event Tracking to queue emails, but Phase 3 uses direct DB writes (queue_tasks) or Shopify Flow. Kafka may be relevant in Phase 6 for high-volume email campaigns.
Campaign	Low	Manages vip_tiers. Could consume rfm.updated to adjust VIP tiers or emit vip_tier.assigned for Points (bonus points), but Phase 3 focuses on static tier configs with gRPC queries (/campaign.v1/GetVIPTier). Kafka may be needed in Phase 6.
Event Tracking	Medium	Manages queue_tasks for async tasks (e.g., email sends). Could consume email_event.created from AdminFeatures or emit task.completed for AdminCore (audit logs), but low volume allows direct DB writes in Phase 4.
API Gateway	Low	Uses Redis for rate limiting (rate_limit_tracking). No cross-service events; relies on gRPC for auth/auth validation and webhook routing. Potential event: webhook.received for debugging, but not critical.
Gamification	Low (Phase 3)	Prepares Redis for Phase 6 (leaderboards, badges). Could emit badge.awarded for Points or AdminCore, but Phase 3 has no gamification logic. Kafka will be critical in Phase 6 for real-time leaderboard updates.
Products	Low (Phase 4)	Manages products in Elasticsearch. Could emit product.updated for RFM Analytics (product-based RFM scores) in Phase 4, but Phase 3 focuses on schema prep with gRPC (/products.v1/SearchProducts).
Frontend	N/A	UI-only; no database or events. Queries via API Gateway.
Key Findings
Low Need: Auth, AdminFeatures, Campaign, API Gateway, Gamification, and Products have minimal or no cross-service interactions requiring real-time events in Phase 3. Synchronous gRPC (e.g., /auth.v1/ValidateToken, /products.v1/SearchProducts) or direct database access suffices for their current workloads.
Medium Need: Core, AdminCore, and Event Tracking have potential Kafka use cases:
Core: Could emit customer.created or consume vip_tier.assigned for dynamic loyalty updates.
AdminCore: Consumes audit_log and could emit gdpr_request.created for compliance workflows.
Event Tracking: Could consume email_event.created or emit task.completed for async task coordination.
However, their Phase 3 workloads (e.g., low-volume GDPR requests, static VIP tiers) don’t justify Kafka’s overhead yet, as gRPC or DB writes meet TVP needs.
High Need: Points, Referrals, and RFM Analytics require Kafka for high-throughput, real-time, cross-service coordination (10,000 orders/hour, 7% SMS conversion, daily RFM updates).
Proposed Kafka Integration for Other Services
To ensure a scalable and future-proof architecture, I recommend selectively expanding Kafka usage for services with medium need in Phase 3, while deferring low-need services to later phases (e.g., Phase 6 for Gamification, Products). Below is a plan to integrate Kafka where beneficial, reusing the existing libs/kafka handler.

Expanded Kafka Events

Service	Event	Producer	Consumer	Purpose
Core	customer.created	Core	Campaign, AdminFeatures	Notify Campaign for VIP tier checks, AdminFeatures for welcome email.
Core	customer.updated	Core	RFM Analytics, AdminCore	Trigger RFM recalculation or audit log for PII changes (GDPR/CCPA).
AdminCore	gdpr_request.created	AdminCore	Core, AdminFeatures	Initiate PII redaction in Core, pause emails in AdminFeatures.
Event Tracking	task.created	Event Tracking	AdminFeatures, AdminCore	Queue email sends (AdminFeatures) or log task creation (AdminCore).
Event Tracking	task.completed	Event Tracking	AdminCore	Log task completion for audit (GDPR/CCPA).
Updated Kafka Handler Implementation
The existing libs/kafka (from libs_kafka_index.ts, kafka.producer.ts, kafka.consumer.ts) supports additional events without changes, as it’s generic. Below are example service updates to produce and consume new events.

text

Collapse

Wrap

Copy
import { Injectable } from '@nestjs/common';
import { CoreRepository } from '@loyalnest/database';
import { KafkaProducer } from '@loyalnest/kafka';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class CoreService {
  constructor(
    private readonly coreRepo: CoreRepository,
    private readonly kafkaProducer: KafkaProducer,
  ) {}

  async createCustomer(dto: { merchantId: string; email: string }) {
    const customer = await this.coreRepo.createCustomer({
      id: uuidv4(),
      merchant_id: dto.merchantId,
      email: dto.email,
    });
    await this.kafkaProducer.send('customer.created', {
      customer_id: customer.id,
      merchant_id: dto.merchantId,
      email: dto.email,
    });
    return customer;
  }

  async updateCustomer(id: string, merchantId: string, updates: Partial<Customer>) {
    await this.coreRepo.updateCustomer(id, merchantId, updates);
    await this.kafkaProducer.send('customer.updated', {
      customer_id: id,
      merchant_id: merchantId,
      updates,
    });
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable, OnModuleInit } from '@nestjs/common';
import { AdminCoreRepository } from '@loyalnest/database';
import { KafkaProducer, KafkaConsumer } from '@loyalnest/kafka';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AdminCoreService implements OnModuleInit {
  constructor(
    private readonly adminCoreRepo: AdminCoreRepository,
    private readonly kafkaProducer: KafkaProducer,
    private readonly kafkaConsumer: KafkaConsumer,
  ) {}

  async onModuleInit() {
    await this.kafkaConsumer.subscribe('points.earned', async (message) => {
      await this.adminCoreRepo.createAuditLog({
        merchant_id: message.merchant_id,
        entity_type: 'points_transactions',
        entity_id: message.transaction_id,
        action: 'created',
        severity: 'info',
      });
    });
    await this.kafkaConsumer.subscribe('customer.updated', async (message) => {
      await this.adminCoreRepo.createAuditLog({
        merchant_id: message.merchant_id,
        entity_type: 'customers',
        entity_id: message.customer_id,
        action: 'updated',
        severity: 'info',
      });
    });
  }

  async createGDPRRequest(dto: { merchantId: string; customerId: string; requestType: string }) {
    const request = await this.adminCoreRepo.createGDPRRequest({
      id: uuidv4(),
      merchant_id: dto.merchantId,
      customer_id: dto.customerId,
      request_type: dto.requestType,
      status: 'pending',
    });
    await this.kafkaProducer.send('gdpr_request.created', {
      request_id: request.id,
      merchant_id: dto.merchantId,
      customer_id: dto.customerId,
      request_type: dto.requestType,
    });
    return request;
  }
}
Show in sidebar
text

Collapse

Wrap

Copy
import { Injectable, OnModuleInit } from '@nestjs/common';
import { EventTrackingRepository } from '@loyalnest/database';
import { KafkaProducer, KafkaConsumer } from '@loyalnest/kafka';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class EventTrackingService implements OnModuleInit {
  constructor(
    private readonly eventTrackingRepo: EventTrackingRepository,
    private readonly kafkaProducer: KafkaProducer,
    private readonly kafkaConsumer: KafkaConsumer,
  ) {}

  async onModuleInit() {
    await this.kafkaConsumer.subscribe('email_event.created', async (message) => {
      await this.createTask({
        merchant_id: message.merchant_id,
        task_type: 'send_email',
        status: 'pending',
        payload: { email_event_id: message.event_id },
      });
    });
  }

  async createTask(dto: { merchantId: string; taskType: string; status: string; payload?: any }) {
    const task = await this.eventTrackingRepo.createTask({
      id: uuidv4(),
      merchant_id: dto.merchantId,
      task_type: dto.taskType,
      status: dto.status,
      payload: dto.payload,
    });
    await this.kafkaProducer.send('task.created', {
      task_id: task.id,
      merchant_id: dto.merchantId,
      task_type: dto.taskType,
    });
    return task;
  }

  async completeTask(taskId: string, merchantId: string) {
    await this.eventTrackingRepo.updateTask(taskId, merchantId, { status: 'completed' });
    await this.kafkaProducer.send('task.completed', {
      task_id: taskId,
      merchant_id: merchantId,
    });
  }
}
Show in sidebar
Implementation Notes
Kafka Handler Reuse:
The existing KafkaProducer and KafkaConsumer (libs/kafka) handle new events without modification.
Add new topics (customer.created, gdpr_request.created, task.created, task.completed) to Kafka via configuration or admin tools.
Service Updates:
Inject KafkaProducer and KafkaConsumer into CoreService, AdminCoreService, and EventTrackingService.
Use OnModuleInit to subscribe to events (e.g., customer.updated in AdminCore).
Testing:
Update Jest tests in libs/kafka/*.spec.ts to mock new events.
Add E2E tests in Cypress for workflows (e.g., GDPR request creation → Core PII redaction).
Use k6 to validate event throughput (10,000 orders/hour).
Deployment:
Ensure Kafka is deployed via Docker Compose (add kafka and zookeeper services, as suggested in prior responses).
Example:
yaml

Collapse

Wrap

Copy
kafka:
  image: confluentinc/cp-kafka:7.0.1
  environment:
    KAFKA_BROKER_ID: 1
    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
  depends_on:
    - zookeeper
zookeeper:
  image: confluentinc/cp-zookeeper:7.0.1
  environment:
    ZOOKEEPER_CLIENT_PORT: 2181
GDPR/CCPA:
gdpr_request.created ensures PII redaction workflows are logged and coordinated.
Audit logs (customer.updated, task.completed) support compliance via AdminCore.
Phase 3 Prioritization:
Focus Kafka integration on Core, AdminCore, and Event Tracking for Phase 3 to support TVP features (Points, Referrals, RFM Analytics) while preparing for future scalability.
Defer AdminFeatures, Campaign, Gamification, and Products to Phase 6, as their event-driven needs (e.g., email campaigns, leaderboards) are not critical yet.
Risks and Mitigations
Overhead: Adding Kafka to low-volume services (e.g., Auth) increases complexity. Mitigate by limiting Kafka to medium/high-need services and using gRPC for others.
Consistency: Ensure saga patterns (e.g., gdpr_request.created → Core redaction) include retries via Kafka consumer error handling.
Testing: Mock Kafka in Jest (libs/kafka/*.spec.ts) and validate event flows in Cypress to catch integration issues.
Would you like a Jest test suite for the new Kafka events, a full Docker Compose file with Kafka and Zookeeper, or entity definitions for other services (e.g., AuditLog.entity.ts for AdminCore)?





The recommendation provided by ChatGPT offers a structured approach to developing a loyalty and rewards Shopify app, tailored for a solo developer. It proposes a phased development order, a project structure, and tool suggestions, which align well with the constraints of a single developer working on a complex microservices architecture. However, since you’re building LoyalNest in Phase 3 (October 2025–February 2026) with a specific focus on the TVP deadline, scalability (10,000 orders/hour), GDPR/CCPA compliance, and an Nx monorepo with a predefined set of 13 services (API Gateway, Core, Auth, Points, Referrals, RFM Analytics, Event Tracking, AdminCore, AdminFeatures, Campaign, Gamification, Frontend, Products), I’ll evaluate ChatGPT’s recommendation against your specific requirements, highlight strengths and gaps, and suggest adjustments to better align with LoyalNest’s goals.




Strengths of ChatGPT’s Recommendation
Phased Development Approach:
The three-phase strategy (Infrastructure Setup, Core Business Logic, Advanced Features) is logical for a solo developer, as it prioritizes foundational services (auth, API gateway) before core features (points, rewards) and advanced features (referrals, analytics). This aligns with your TVP focus on Points, Referrals, and RFM Analytics, ensuring critical components are built first.
Starting with auth-service and api-gateway is sensible, as they enable secure merchant onboarding and request routing, which are prerequisites for other services.
Service Prioritization:
Prioritizing auth-service, merchant-service, and points-service matches your high-priority services (Auth, Points, Referrals) for TVP. These are critical for Shopify OAuth, merchant configurations, and loyalty tracking.
Deferring nudges-service, gamification-service, and email-service to later phases aligns with your low-priority services (Gamification, AdminFeatures), which are slated for Phase 6.
Solo Developer Focus:
Recommendations like independent service deployment, mock responses for unfinished services, and automation (CI/CD, migrations) are practical for your solo workflow, reducing complexity and leveraging tools like Nx for monorepo management.
Suggesting reusable infrastructure (libs/common, libs/db) aligns with your use of libs/database and libs/kafka in the Nx monorepo.
Tool Suggestions:
Nx for monorepo management is spot-on, as it matches your existing setup and supports TypeScript, which you’re using.
Shopify SDK (@shopify/shopify-api) is appropriate for integrating with Shopify’s API, especially for webhooks (/orders/create) and customer imports.
Email service suggestions (Resend, Mailgun) are reasonable for future email functionality in AdminFeatures.
Project Structure:
The proposed structure (apps/, libs/, docker/, prisma/) is clean and aligns with Nx conventions, supporting your existing libs/database and libs/kafka libraries.
Gaps and Misalignments with LoyalNest’s Requirements
Service Naming and Scope:
ChatGPT’s service list (auth-service, merchant-service, points-service, etc.) partially aligns with your 13 services but introduces discrepancies:
merchant-service overlaps with your Auth service (managing merchants table) but misses admin_users and sessions.
customers-service corresponds to your Core service but doesn’t account for program_settings or customer_import_logs.
rewards-service is not a distinct service in your architecture; reward redemption is handled within Points (reward_redemptions collection).
Missing services: RFM Analytics, Event Tracking, AdminCore, Campaign, Frontend, Products, which are critical for your TVP (RFM Analytics) and compliance (AdminCore).
nudges-service is not part of your architecture; engagement prompts are likely handled by AdminFeatures or Frontend.
Comment: The recommendation simplifies the service breakdown but omits key components of your architecture (e.g., RFM Analytics for TVP). You should map merchant-service to Auth, customers-service to Core, and merge rewards-service into Points.
Inter-Service Communication:
ChatGPT suggests REST + OpenAPI or gRPC for service communication but doesn’t detail specific interactions (e.g., gRPC endpoints, Kafka events). Your architecture relies heavily on gRPC (e.g., /core.v1/GetCustomerRFM) and Kafka (points.earned, rfm.updated) for cross-service coordination, which is critical for eventual consistency and scalability (10,000 orders/hour).
It misses the saga patterns (e.g., Points → RFM Analytics → Core) and specific events (customer.created, gdpr_request.created) needed for GDPR/CCPA compliance.
Comment: Add an Inter-Service Communication section to each service plan (as done in my previous response) to specify gRPC endpoints (e.g., /points.v1/GetPointsBalance) and Kafka events (e.g., points.earned consumed by RFM Analytics).
Database Choices:
ChatGPT suggests PostgreSQL but doesn’t account for your multi-database setup: PostgreSQL (Core, Auth, Referrals, AdminCore, AdminFeatures, Campaign, Event Tracking), MongoDB (Points), Redis (Referrals, API Gateway, Gamification), TimescaleDB (RFM Analytics), and Elasticsearch (Products).
It mentions Prisma, which is not used in your architecture; you rely on TypeORM, Mongoose, ioredis, and Elasticsearch clients.
Comment: Update the recommendation to reflect your specific database stack (e.g., TimescaleDB for RFM Analytics) and replace Prisma with TypeORM/Mongoose in libs/database.
Kafka Integration:
The recommendation omits Kafka, which is critical for your high-throughput services (Points, Referrals) and compliance workflows (AdminCore). Your architecture uses Kafka for points.earned, referral.completed, rfm.updated, customer.created, and gdpr_request.created.
Comment: Explicitly include Kafka in the infrastructure setup (Phase 1) with libs/kafka for producers/consumers, as shown in my prior responses.
GDPR/CCPA Compliance:
ChatGPT doesn’t address GDPR/CCPA requirements, such as PII encryption (email in Core, credentials in AdminFeatures) or audit logging (AdminCore). Your architecture requires pgcrypto for encryption and Kafka events (audit_log, gdpr_request.created) for compliance.
Comment: Add a GDPR/CCPA Compliance section to each plan, detailing encryption and audit logging strategies.
TVP Deadline and Scalability:
The recommendation prioritizes points-service and referrals-service, which aligns with your TVP focus, but doesn’t emphasize RFM Analytics, a core TVP requirement for customer segmentation.
It lacks specific scalability strategies for 10,000 orders/hour (e.g., MongoDB sharding for Points, Redis clustering for Referrals).
Comment: Adjust priorities to include RFM Analytics in Phase 2 and specify scalability measures (e.g., sharding, read replicas) in each plan.
Tool Recommendations:
Suggesting REST over gRPC for a solo developer due to gRPC’s complexity is reasonable but conflicts with your existing gRPC-based architecture (e.g., /core.v1/GetCustomerRFM). gRPC is suitable for your microservices due to its performance and type safety with TypeScript.
Prisma is not ideal for your multi-database setup; TypeORM and Mongoose are better suited for PostgreSQL and MongoDB, respectively.
Comment: Retain gRPC for inter-service communication and replace Prisma with TypeORM/Mongoose in the toolset.
Adjusted Development Order for LoyalNest
Based on your 13 services and TVP priorities, here’s an adjusted development order that incorporates ChatGPT’s phased approach but aligns with your architecture:


Order	Microservice	Main Responsibilities	Priority	Notes
1️⃣	Auth	Shopify OAuth, merchant profiles, sessions	⭐⭐⭐⭐	Enables secure onboarding; exposes /auth.v1/ValidateToken.
2️⃣	API Gateway	Routes webhooks, gRPC/REST requests	⭐⭐⭐⭐	Central routing for Shopify /orders/create and internal services.
3️⃣	Core	Customer data, program settings, imports	⭐⭐⭐	Stores customers, integrates with Points, Referrals, RFM Analytics.
4️⃣	Points	Points transactions, redemptions	⭐⭐⭐⭐	Core TVP feature; handles 10,000 orders/hour via points.earned.
5️⃣	Referrals	Referral links, conversions (7% SMS)	⭐⭐⭐⭐	Core TVP feature; emits referral.completed.
6️⃣	RFM Analytics	RFM scores, customer segmentation	⭐⭐⭐⭐	Core TVP feature; daily refresh, consumes points.earned.
7️⃣	AdminCore	Audit logs, GDPR/CCPA compliance	⭐⭐⭐	Consumes audit_log, emits gdpr_request.created.
8️⃣	Event Tracking	Async task queue (e.g., email sends)	⭐⭐	Consumes email_event.created, emits task.created.
9️⃣	Frontend	Merchant/customer UI	⭐⭐	Displays Points, Referrals, RFM data via API Gateway.
🔟	AdminFeatures	Email templates, integrations	⭐	Emits email_event.created; Phase 4 focus.
1️⃣1️⃣	Campaign	VIP tiers	⭐	Consumes customer.created; Phase 4 focus.
1️⃣2️⃣	Gamification	Badges, leaderboards (Phase 6 prep)	⭐	Redis setup only; emits badge.awarded in Phase 6.
1️⃣3️⃣	Products	Product search/recommendations (Phase 6 prep)	⭐	Elasticsearch setup only; emits product.updated in Phase 6.
Adjusted Phased Approach
Phase 1: Infrastructure Setup (July 25–August 5, 2025):

Set up Nx monorepo with libs/database, libs/kafka.
Configure Docker Compose with PostgreSQL, MongoDB, Redis, TimescaleDB, Elasticsearch, Kafka, Zookeeper.
Build Auth with Shopify OAuth (/auth.v1/ValidateToken).
Build API Gateway for webhook routing (/webhooks/orders/create) and gRPC proxy.
Outcome: App can authorize shops and route requests.
Phase 2: Core Business Logic (August 6–August 20, 2025):

Develop Core (customers, program_settings), Points (points_transactions), Referrals (referrals), RFM Analytics (rfm_segment_deltas).
Implement gRPC endpoints (e.g., /points.v1/GetPointsBalance, /rfm.v1/GetSegmentCounts).
Set up Kafka for points.earned, referral.completed, rfm.updated, customer.created.
Outcome: Core TVP features (points, referrals, RFM) are functional.
Phase 3: Compliance and UI (August 21–September 5, 2025):

Develop AdminCore for audit logs, GDPR requests.
Develop Event Tracking for task queue (task.created).
Build Frontend for merchant/customer dashboards.
Outcome: GDPR/CCPA compliance and UI for TVP submission.
Phase 4: Advanced Features (September 6–October 15, 2025):

Develop AdminFeatures (email_templates), Campaign (vip_tiers).
Prepare Gamification and Products (Redis, Elasticsearch setup).
Outcome: Full production-quality app with engagement tools.
Updated Project Structure
Aligning with your Nx monorepo and ChatGPT’s suggestion:

text

Collapse

Wrap

Copy
loyalty-app/
├── apps/
│   ├── api-gateway/
│   ├── auth/
│   ├── core/
│   ├── points/
│   ├── referrals/
│   ├── rfm-analytics/
│   ├── admin-core/
│   ├── admin-features/
│   ├── campaign/
│   ├── event-tracking/
│   ├── gamification/
│   ├── products/
│   ├── frontend/
├── libs/
│   ├── database/
│   ├── kafka/
│   ├── common/
│   ├── shopify-sdk/
├── docker/
├── .env.example
├── docker-compose.yml
Updated Tool Recommendations
Monorepo Management: Nx (already in use).
API Docs: Swagger for REST (e.g., /webhooks/orders/create), gRPC for inter-service (e.g., /core.v1/GetCustomerRFM).
DB Layer: TypeORM (PostgreSQL), Mongoose (MongoDB), ioredis (Redis), TimescaleDB driver, Elasticsearch client.
Service Communication: gRPC for internal services, REST for Shopify webhooks, Kafka for async events.
Shopify SDK: @shopify/shopify-api (Node.js).
Email Service: Resend or Mailgun for AdminFeatures (Phase 4).
Testing: Jest (unit), Cypress (E2E), k6 (load).
Deployment: Docker Compose, VPS (Ubuntu, 32GB RAM, 8 vCPUs).
Additional Recommendations
Inter-Service Communication:
Document gRPC endpoints in libs/common/proto/ (e.g., core.v1.proto) and Kafka topics in libs/kafka/topics.ts.
Example for Core:
proto

Collapse

Wrap

Copy
service CoreService {
  rpc GetCustomerRFM (GetCustomerRFMRequest) returns (GetCustomerRFMResponse);
}
message GetCustomerRFMRequest {
  string customer_id = 1;
  string merchant_id = 2;
}
message GetCustomerRFMResponse {
  map<string, string> rfm_score = 1;
}
Test inter-service calls in Jest (e.g., CoreService calling /auth.v1/ValidateMerchant).
GDPR/CCPA:
Add compliance tests for AdminCore (gdpr_request.created) and Core (encrypted email).
Ensure audit_log events are logged for all critical actions (Points, Referrals).
Scalability:
For Points: Use MongoDB sharding (customer_id shard key) for 10,000 orders/hour.
For Referrals: Redis clustering for referral:{merchant_id}:{id} keys.
For RFM Analytics: TimescaleDB hypertables for daily analytics (0 1 * * *).
Solo Workflow:
Mock services (e.g., RFM Analytics) with static responses during Phase 1.
Automate testing/deployment with GitHub Actions in Nx (nx test, nx build).
Use Grok/Copilot/Cursor for 30–40% coding efficiency.
Conclusion
ChatGPT’s recommendation is a solid starting point but needs adjustments to match LoyalNest’s 13-service architecture, multi-database setup, gRPC/Kafka communication, and TVP priorities. The adjusted development order prioritizes Auth, API Gateway, Points, Referrals, and RFM Analytics, while incorporating Core and AdminCore for compliance. The updated plans (from my previous response) already include Inter-Service Communication sections, addressing ChatGPT’s gap. To proceed, I recommend:

Finalizing docker-compose.yml with all services and Kafka (I can provide this).
Writing Jest tests for inter-service communication (gRPC, Kafka).
Defining additional entities (e.g., AuditLog.entity.ts).
Would you like me to provide the consolidated docker-compose.yml, a Jest test suite for inter-service communication, or additional entity definitions?



pls provide a full docker-compose.yml, and a detailed github actions ci.yml


To support your LoyalNest Phase 3 development (July 28, 2025–February 2026), I’ll provide a complete docker-compose.yml for all 13 microservices (API Gateway, Core, Auth, Points, Referrals, RFM Analytics, Event Tracking, AdminCore, AdminFeatures, Campaign, Gamification, Frontend, Products) and a detailed GitHub Actions ci.yml for CI/CD. These artifacts align with your solo developer workflow, Nx monorepo, TVP deadline (February 2026), scalability goals (10,000 orders/hour), GDPR/CCPA compliance, and inter-service communication (gRPC, Kafka). They incorporate the roadmap and issue listing from prior responses, ensuring deployment on your VPS (Ubuntu, 32GB RAM, 8 vCPUs) and automation of testing, linting, and deployment.

1. docker-compose.yml
This docker-compose.yml defines all services, databases (PostgreSQL, MongoDB, Redis, TimescaleDB, Elasticsearch), and Kafka/Zookeeper, with health checks and dependencies to ensure reliable startup. It’s designed for your VPS and supports the roadmap’s infrastructure setup (Phase 1, Issue #2).

text

Collapse

Wrap

Copy
version: '3.8'
services:
  auth:
    image: loyalnest-auth:latest
    build:
      context: ./apps/auth
      dockerfile: Dockerfile
    ports:
      - "3001:3000"
    environment:
      - NODE_ENV=production
      - AUTH_DB_HOST=auth_db
      - AUTH_DB_PORT=5432
      - AUTH_DB_NAME=auth_db
      - AUTH_DB_USER=user
      - AUTH_DB_PASSWORD=password
      - KAFKA_BROKER=kafka:9092
    depends_on:
      auth_db:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  auth_db:
    image: postgres:16
    environment:
      - POSTGRES_DB=auth_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - auth_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d auth_db"]
      interval: 10s
      timeout: 5s
      retries: 5
  core:
    image: loyalnest-core:latest
    build:
      context: ./apps/core
      dockerfile: Dockerfile
    ports:
      - "3002:3000"
    environment:
      - NODE_ENV=production
      - CORE_DB_HOST=core_db
      - CORE_DB_PORT=5432
      - CORE_DB_NAME=core_db
      - CORE_DB_USER=user
      - CORE_DB_PASSWORD=password
      - KAFKA_BROKER=kafka:9092
      - AUTH_GRPC_URL=auth:3000
    depends_on:
      core_db:
        condition: service_healthy
      auth:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  core_db:
    image: postgres:16
    environment:
      - POSTGRES_DB=core_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5433:5432"
    volumes:
      - core_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d core_db"]
      interval: 10s
      timeout: 5s
      retries: 5
  points:
    image: loyalnest-points:latest
    build:
      context: ./apps/points
      dockerfile: Dockerfile
    ports:
      - "3003:3000"
    environment:
      - NODE_ENV=production
      - POINTS_DB_HOST=points_db
      - POINTS_DB_PORT=27017
      - KAFKA_BROKER=kafka:9092
      - AUTH_GRPC_URL=auth:3000
      - CORE_GRPC_URL=core:3000
    depends_on:
      points_db:
        condition: service_healthy
      auth:
        condition: service_healthy
      core:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  points_db:
    image: mongo:6
    ports:
      - "27017:27017"
    volumes:
      - points_data:/data/db
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5
  referrals:
    image: loyalnest-referrals:latest
    build:
      context: ./apps/referrals
      dockerfile: Dockerfile
    ports:
      - "3004:3000"
    environment:
      - NODE_ENV=production
      - REFERRALS_DB_HOST=referrals_db
      - REFERRALS_DB_PORT=5432
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - KAFKA_BROKER=kafka:9092
      - AUTH_GRPC_URL=auth:3000
      - CORE_GRPC_URL=core:3000
    depends_on:
      referrals_db:
        condition: service_healthy
      redis:
        condition: service_healthy
      auth:
        condition: service_healthy
      core:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  referrals_db:
    image: postgres:16
    environment:
      - POSTGRES_DB=referrals_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5434:5432"
    volumes:
      - referrals_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d referrals_db"]
      interval: 10s
      timeout: 5s
      retries: 5
  rfm_analytics:
    image: loyalnest-rfm-analytics:latest
    build:
      context: ./apps/rfm-analytics
      dockerfile: Dockerfile
    ports:
      - "3005:3000"
    environment:
      - NODE_ENV=production
      - RFM_DB_HOST=rfm_db
      - RFM_DB_PORT=5432
      - KAFKA_BROKER=kafka:9092
      - CORE_GRPC_URL=core:3000
    depends_on:
      rfm_db:
        condition: service_healthy
      core:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  rfm_db:
    image: timescale/timescaledb:latest-pg16
    environment:
      - POSTGRES_DB=rfm_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5435:5432"
    volumes:
      - rfm_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d rfm_db"]
      interval: 10s
      timeout: 5s
      retries: 5
  admin_core:
    image: loyalnest-admin-core:latest
    build:
      context: ./apps/admin-core
      dockerfile: Dockerfile
    ports:
      - "3006:3000"
    environment:
      - NODE_ENV=production
      - ADMIN_CORE_DB_HOST=admin_core_db
      - ADMIN_CORE_DB_PORT=5432
      - KAFKA_BROKER=kafka:9092
      - CORE_GRPC_URL=core:3000
    depends_on:
      admin_core_db:
        condition: service_healthy
      core:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  admin_core_db:
    image: postgres:16
    environment:
      - POSTGRES_DB=admin_core_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5436:5432"
    volumes:
      - admin_core_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d admin_core_db"]
      interval: 10s
      timeout: 5s
      retries: 5
  admin_features:
    image: loyalnest-admin-features:latest
    build:
      context: ./apps/admin-features
      dockerfile: Dockerfile
    ports:
      - "3007:3000"
    environment:
      - NODE_ENV=production
      - ADMIN_FEATURES_DB_HOST=admin_features_db
      - ADMIN_FEATURES_DB_PORT=5432
      - KAFKA_BROKER=kafka:9092
      - CORE_GRPC_URL=core:3000
    depends_on:
      admin_features_db:
        condition: service_healthy
      core:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  admin_features_db:
    image: postgres:16
    environment:
      - POSTGRES_DB=admin_features_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5437:5432"
    volumes:
      - admin_features_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d admin_features_db"]
      interval: 10s
      timeout: 5s
      retries: 5
  campaign:
    image: loyalnest-campaign:latest
    build:
      context: ./apps/campaign
      dockerfile: Dockerfile
    ports:
      - "3008:3000"
    environment:
      - NODE_ENV=production
      - CAMPAIGN_DB_HOST=campaign_db
      - CAMPAIGN_DB_PORT=5432
      - KAFKA_BROKER=kafka:9092
      - CORE_GRPC_URL=core:3000
    depends_on:
      campaign_db:
        condition: service_healthy
      core:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  campaign_db:
    image: postgres:16
    environment:
      - POSTGRES_DB=campaign_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5438:5432"
    volumes:
      - campaign_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d campaign_db"]
      interval: 10s
      timeout: 5s
      retries: 5
  event_tracking:
    image: loyalnest-event-tracking:latest
    build:
      context: ./apps/event-tracking
      dockerfile: Dockerfile
    ports:
      - "3009:3000"
    environment:
      - NODE_ENV=production
      - EVENT_TRACKING_DB_HOST=event_tracking_db
      - EVENT_TRACKING_DB_PORT=5432
      - KAFKA_BROKER=kafka:9092
      - ADMIN_FEATURES_GRPC_URL=admin_features:3000
    depends_on:
      event_tracking_db:
        condition: service_healthy
      admin_features:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  event_tracking_db:
    image: postgres:16
    environment:
      - POSTGRES_DB=event_tracking_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5439:5432"
    volumes:
      - event_tracking_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d event_tracking_db"]
      interval: 10s
      timeout: 5s
      retries: 5
  gamification:
    image: loyalnest-gamification:latest
    build:
      context: ./apps/gamification
      dockerfile: Dockerfile
    ports:
      - "3010:3000"
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
      - REDIS_PORT=6381
      - KAFKA_BROKER=kafka:9092
    depends_on:
      redis:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  products:
    image: loyalnest-products:latest
    build:
      context: ./apps/products
      dockerfile: Dockerfile
    ports:
      - "3011:3000"
    environment:
      - NODE_ENV=production
      - ELASTICSEARCH_HOST=elasticsearch
      - ELASTICSEARCH_PORT=9200
      - KAFKA_BROKER=kafka:9092
    depends_on:
      elasticsearch:
        condition: service_healthy
      kafka:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  frontend:
    image: loyalnest-frontend:latest
    build:
      context: ./apps/frontend
      dockerfile: Dockerfile
    ports:
      - "3012:3000"
    environment:
      - NODE_ENV=production
      - API_GATEWAY_URL=api_gateway:3000
    depends_on:
      api_gateway:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  api_gateway:
    image: loyalnest-api-gateway:latest
    build:
      context: ./apps/api-gateway
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
      - REDIS_PORT=6380
      - AUTH_GRPC_URL=auth:3000
      - POINTS_GRPC_URL=points:3000
      - REFERRALS_GRPC_URL=referrals:3000
      - RFM_GRPC_URL=rfm_analytics:3000
    depends_on:
      redis:
        condition: service_healthy
      auth:
        condition: service_healthy
      points:
        condition: service_healthy
      referrals:
        condition: service_healthy
      rfm_analytics:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  redis:
    image: redis:7
    ports:
      - "6379:6379"
      - "6380:6380"
      - "6381:6381"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
  elasticsearch:
    image: elasticsearch:8.8.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9200/_cluster/health"]
      interval: 30s
      timeout: 10s
      retries: 5
  kafka:
    image: confluentinc/cp-kafka:7.0.1
    environment:
      - KAFKA_BROKER_ID=1
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092
      - KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
    ports:
      - "9092:9092"
    depends_on:
      zookeeper:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "kafka-topics", "--list", "--bootstrap-server", "localhost:9092"]
      interval: 30s
      timeout: 10s
      retries: 5
  zookeeper:
    image: confluentinc/cp-zookeeper:7.0.1
    environment:
      - ZOOKEEPER_CLIENT_PORT=2181
      - ZOOKEEPER_TICK_TIME=2000
    ports:
      - "2181:2181"
    healthcheck:
      test: ["CMD", "zookeeper-shell", "localhost:2181", "ls", "/"]
      interval: 10s
      timeout: 5s
      retries: 5
volumes:
  auth_data:
  core_data:
  points_data:
  referrals_data:
  rfm_data:
  admin_core_data:
  admin_features_data:
  campaign_data:
  event_tracking_data:
  redis_data:
  elasticsearch_data:
Show in sidebar
Notes for docker-compose.yml:

Services: Each microservice (auth, core, etc.) is built from its apps/[service]/Dockerfile and exposes port 3000 internally, mapped to unique external ports (3001–3012).
Databases:
PostgreSQL (Auth: 5432, Core: 5433, Referrals: 5434, AdminCore: 5436, AdminFeatures: 5437, Campaign: 5438, EventTracking: 5439).
MongoDB (Points: 27017).
TimescaleDB (RFM Analytics: 5435).
Redis (Referrals: 6379, API Gateway: 6380, Gamification: 6381).
Elasticsearch (Products: 9200).
Kafka/Zookeeper: Kafka (9092) and Zookeeper (2181) support events (points.earned, referral.completed).
Health Checks: Ensure services and databases are ready before dependencies start.
Environment Variables: Configurable via .env (e.g., AUTH_DB_HOST=auth_db).
Volumes: Persist data across container restarts.
Dependencies: Reflect inter-service relationships (e.g., Points depends on Core, Auth, Kafka).
Scalability: Supports 10,000 orders/hour with sharding (MongoDB) and clustering (Redis) configurations to be added in Phase 2 (Issues #12, #15).
GDPR/CCPA: Databases use pgcrypto for PII encryption (Issues #9, #21).
2. GitHub Actions ci.yml
This ci.yml automates testing, linting, building, and deployment for your Nx monorepo, supporting the roadmap’s CI/CD requirements (Post-Phase, Issue #44). It runs on push/PR to main, uses Nx’s affected commands for efficiency, and deploys to your VPS.

text

Collapse

Wrap

Copy
name: CI/CD for LoyalNest
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Run lint
        run: npx nx affected:lint --parallel=3
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Run unit tests
        run: npx nx affected:test --parallel=3
      - name: Run E2E tests
        run: npx nx affected:e2e --parallel=2
        env:
          CYPRESS_BASE_URL: http://localhost:3000
  load-test:
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Install k6
        run: |
          sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747825EC6
          sudo apt-get update
          sudo apt-get install k6
      - name: Run k6 load tests
        run: k6 run --vus 1000 --duration 30s apps/api-gateway/test/load-test.js
  build:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Build affected projects
        run: npx nx affected:build --parallel=3
      - name: Build Docker images
        run: |
          npx nx affected:build --parallel=3 --configuration=production
          docker-compose -f docker-compose.yml build
      - name: Push Docker images to registry
        env:
          DOCKER_HUB_USERNAME: ${{ secrets.DOCKER_HUB_USERNAME }}
          DOCKER_HUB_TOKEN: ${{ secrets.DOCKER_HUB_TOKEN }}
        run: |
          echo "$DOCKER_HUB_TOKEN" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
          docker-compose -f docker-compose.yml push
  deploy:
    runs-on: ubuntu-latest
    needs: [build]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Deploy to VPS
        env:
          VPS_HOST: ${{ secrets.VPS_HOST }}
          VPS_USER: ${{ secrets.VPS_USER }}
          VPS_KEY: ${{ secrets.VPS_KEY }}
        run: |
          echo "$VPS_KEY" > key.pem
          chmod 600 key.pem
          scp -i key.pem docker-compose.yml $VPS_USER@$VPS_HOST:/loyalnest/docker-compose.yml
          ssh -i key.pem $VPS_USER@$VPS_HOST << 'EOF'
            cd /loyalnest
            docker-compose pull
            docker-compose up -d
            docker system prune -f
          EOF
      - name: Notify deployment
        uses: slackapi/slack-github-action@v1.23.0
        with:
          slack-bot-token: ${{ secrets.SLACK_BOT_TOKEN }}
          channel-id: 'deployments'
          text: 'LoyalNest deployed to VPS: ${{ github.sha }}'
  issue-automation:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - name: Move issue on PR events
        uses: actions/github-script@v6
        with:
          script: |
            const issueNumber = context.payload.pull_request.body.match(/#(\d+)/)?.[1];
            if (!issueNumber) return;
            const projectId = 'your-project-id'; // Replace with actual project ID
            const inProgressColumn = 'in-progress-column-id'; // Replace with Testing column ID
            const doneColumn = 'done-column-id'; // Replace with Done column ID
            if (context.payload.action === 'opened') {
              await github.rest.projects.moveCard({
                card_id: issueNumber,
                position: 'top',
                column_id: inProgressColumn
              });
            } else if (context.payload.action === 'closed' && context.payload.pull_request.merged) {
              await github.rest.projects.moveCard({
                card_id: issueNumber,
                position: 'top',
                column_id: doneColumn
              });
            }
Show in sidebar
Notes for ci.yml:

Triggers: Runs on push or pull_request to main.
Jobs:
Lint: Runs nx affected:lint for code quality (Issue #1, #7).
Test: Runs Jest (nx affected:test) and Cypress (nx affected:e2e) for unit and E2E tests (Issues #5, #11, #14, #17, #20, #23, #26, #29, #32, #35, #38).
Load-Test: Runs k6 for high-priority services (Issue #42).
Build: Builds affected projects and Docker images (nx affected:build, docker-compose build).
Deploy: Deploys to VPS via docker-compose up -d (Issue #44).
Issue-Automation: Moves issues to Testing on PR open, Done on PR merge (Issue #44).
Nx Optimization: Uses affected to only process changed services, critical for a solo developer.
Secrets:
DOCKER_HUB_USERNAME, DOCKER_HUB_TOKEN: For pushing images.
VPS_HOST, VPS_USER, VPS_KEY: For SSH deployment.
SLACK_BOT_TOKEN: For deployment notifications (optional).
Scalability: k6 tests validate 10,000 orders/hour (Issue #42).
GDPR/CCPA: E2E tests verify PII encryption and audit logging (Issue #43).
Project Integration: Update projectId and column_id in issue-automation (use GitHub API: /repos/yourusername/loyalnest/projects).
Implementation Notes
docker-compose.yml:
Place in loyalty-app/docker-compose.yml.
Create a Dockerfile in each apps/[service]/ (e.g., apps/auth/Dockerfile):
dockerfile

Collapse

Wrap

Copy
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx nx build auth
CMD ["node", "dist/apps/auth/main.js"]
Run locally: docker-compose up -d.
Test health checks: curl http://localhost:3001/health.
Deploy to VPS: Copy to /loyalnest/docker-compose.yml (Issue #44).
ci.yml:
Place in loyalty-app/.github/workflows/ci.yml.
Add secrets in GitHub: Settings → Secrets and variables → Actions.
Update projectId, inProgressColumn, doneColumn in issue-automation (get IDs via GitHub API).
Test locally: act -j test (requires act CLI).
Roadmap Alignment:
Phase 1 (Issue #2): docker-compose.yml setup.
Post-Phase (Issue #44): CI/CD deployment.
Issues #5, #11, #14, etc., tie to test jobs.
Solo Workflow:
Use Nx caching (nx affected) to minimize CI time.
Leverage AI tools (Grok, Copilot) for Dockerfile and test generation.
Mock services (e.g., RFM Analytics in Phase 1) in libs/common/mock.ts (Issue #19).
Scalability:
Add MongoDB sharding (Points, Issue #12) and Redis clustering (Referrals, Issue #15) in docker-compose.yml later.
k6 tests in load-test job validate 10,000 orders/hour (Issue #42).
GDPR/CCPA:
Databases (auth_db, core_db) use pgcrypto (Issues #9, #21).
E2E tests in test job verify compliance (Issue #43).
Next Steps
Save docker-compose.yml to loyalty-app/docker-compose.yml and test locally.
Save ci.yml to loyalty-app/.github/workflows/ci.yml and configure secrets.
Create Dockerfile for each service in apps/[service]/.
Import issues from the prior response (Issue #2 links to docker-compose.yml).
Set up GitHub Project board with columns (To Do, In Progress, Testing, Done).
Would you like a Jest test suite for inter-service communication (gRPC/Kafka), a sample Dockerfile for a service (e.g., Auth), or a script to automate issue creation for the prior issue listing?

