# Users Service Plan

## Overview
- **Purpose**: Manages customer and admin user data, including profiles, authentication details, and preferences for LoyalNest, supporting customer interactions (e.g., US-CW2, US-CW7, US-BI3) and admin management (e.g., US-AM14, US-AM15).
- **Priority for TVP**: High, as it handles core user data critical for authentication, points earning, and imports.
- **Dependencies**:
  - `auth-service`: JWT validation and OAuth (Shopify).
  - `points-service`: Customer points balance updates (US-CW2).
  - `admin-service`: Multi-tenant account management (US-AM14).
  - `roles-service`: RBAC role assignments (new service).
  - External: Shopify API (GraphQL for user data), Klaviyo/Postscript (notifications).

## Database Setup
- **Database Type**: PostgreSQL (aligned with `schema.sql`).
- **Tables/Collections**:
  - `customers` (I2): Stores customer profiles.
  - `admin_users` (I10a): Stores admin user data.
  - `audit_logs` (I12): Tracks user-related actions.
- **Schema Details**:
  - `customers`:
    - `customer_id` (UUID, primary key).
    - `merchant_id` (UUID, foreign key to `merchants`).
    - `email` (TEXT, AES-256 encrypted).
    - `points_balance` (INTEGER).
    - `rfm_score` (JSONB, e.g., `{ "recency": 3, "frequency": 2, "monetary": 4 }`).
    - `language` (TEXT, CHECK: `en`, `es`, `fr`, `ar`, `de`, `pt`, `ja`).
    - Indexes: `idx_customers_merchant_id`, `idx_customers_email`.
  - `admin_users`:
    - `admin_user_id` (UUID, primary key).
    - `email` (TEXT, AES-256 encrypted).
    - `metadata` (JSONB, e.g., `{ "rbac_scopes": ["admin:full"] }`).
    - Indexes: `idx_admin_users_email`.
  - `audit_logs`:
    - `log_id` (UUID, primary key).
    - `admin_user_id` (UUID, foreign key).
    - `action` (TEXT, e.g., `customer_updated`).
    - `metadata` (JSONB, e.g., `{ "customer_id": "customer_123" }`).
    - Index: `idx_audit_logs_admin_user_id`.
- **GDPR/CCPA Compliance**:
  - PII (`email`) encrypted with AES-256.
  - `audit_logs` track user data access/modification.
  - Data deletion requests handled via `DELETE FROM customers` with cascading deletes.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - `/users.v1/GetCustomer`:
      - Input: `customer_id`, `merchant_id`.
      - Output: `Customer` (email, points_balance, language).
      - Target: `points-service`, `rfm-service`.
    - `/users.v1/UpdateCustomer`:
      - Input: `customer_id`, `merchant_id`, `email`, `language`.
      - Output: `Customer`.
      - Target: `admin-service` (US-BI3).
    - `/users.v1/GetAdminUser`:
      - Input: `admin_user_id`.
      - Output: `AdminUser` (email, metadata).
      - Target: `roles-service`, `admin-service`.
  - **REST**:
    - `/api/users/import` (POST): Triggers async customer import (US-BI3).
    - `/webhooks/users/update`: Receives Shopify user updates.
- **Asynchronous Communication**:
  - **Events Produced**:
    - `customer.created`:
      - Consumers: `points-service`, `rfm-service`, `campaign-service`.
      - Purpose: Initialize points balance, RFM score, campaigns.
    - `customer.updated`:
      - Consumers: `rfm-service`, `admin-service`.
      - Purpose: Update RFM score, audit logs.
    - `admin_user.updated`:
      - Consumers: `roles-service`, `admin-service`.
      - Purpose: Update RBAC scopes, multi-tenant config.
  - **Events Consumed**:
    - `auth.token_issued` (from `auth-service`):
      - Action: Cache user session in Redis.
    - `points.earned` (from `points-service`):
      - Action: Update `customers.points_balance`.
- **Saga Patterns**:
  - Customer Import Saga:
    - `users-service` → `points-service` → `rfm-service`: Creates customer, assigns points, calculates RFM score.

## Key Endpoints
- **gRPC/REST**:
  - `/users.v1/GetCustomer`: Retrieve customer profile (US-CW2).
  - `/users.v1/UpdateCustomer`: Update customer data (US-BI3).
  - `/users.v1/GetAdminUser`: Retrieve admin user data (US-AM14).
  - `/api/users/import` (REST): Async customer import (US-BI3).
- **Access Patterns**:
  - High-read: `GetCustomer` (5,000 concurrent requests).
  - Medium-write: `UpdateCustomer`, `import` (1,000 imports/hour).
- **Rate Limits**:
  - Shopify API: 2 req/s (REST), handled via circuit breakers.
  - Internal: 100 req/s per merchant for imports.

## Testing Strategy
- **Unit Tests**: Jest for `UsersRepository.findById`, `UsersService.updateCustomer`.
- **E2E Tests**: Cypress for `/users.v1/GetCustomer`, `/api/users/import`.
- **Load Tests**: k6 for 5,000 concurrent `GetCustomer` calls, 1,000 imports/hour.
- **Compliance Tests**: Verify AES-256 encryption, audit log entries for PII access.

## Deployment
- **Docker Compose**:
  - Service: `users-service`, port 50051 (gRPC), 8080 (REST).
  - Dependencies: PostgreSQL (port 5432), Kafka, Redis.
- **Environment Variables**:
  - `USERS_DB_HOST`, `USERS_DB_PORT`, `USERS_DB_NAME`.
  - `KAFKA_BROKER`, `SHOPIFY_API_KEY`.
- **Scaling Considerations**:
  - Horizontal scaling with multiple `users-service` instances.
  - PostgreSQL partitioning for `customers` (by `merchant_id`).

## Risks and Mitigations
- **Risks**:
  - High read latency for `GetCustomer` under 5,000 concurrent requests.
  - Shopify API rate limit breaches.
- **Mitigations**:
  - Redis caching for `customer:{customer_id}`.
  - Circuit breakers and exponential backoff for Shopify API.

## Action Items
- [ ] Define `Customer.entity.ts` schema by August 5, 2025.
- [ ] Implement `/users.v1/GetCustomer` endpoint by August 10, 2025.
- [ ] Test Kafka `customer.created` event by August 15, 2025.
- [ ] Set up PostgreSQL indexes by August 12, 2025.

## Timeline
- **Start Date**: August 1, 2025
- **Completion Date**: September 1, 2025
- **Milestones**:
  - Schema setup by August 12, 2025.
  - Endpoints implemented by August 20, 2025.
  - Testing completed by August 30, 2025.