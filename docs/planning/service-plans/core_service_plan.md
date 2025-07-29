# Core Service Plan

## Overview
- **Purpose**: Manages customer data, program settings, and import logs, central to loyalty operations.
- **Priority for TVP**: Medium (supports Points, Referrals, RFM Analytics).
- **Dependencies**: Auth (merchant validation), RFM Analytics (RFM scores), Shopify API (imports).

## Database Setup
- **Database Type**: PostgreSQL
- **Tables**: `customers`, `program_settings`, `customer_import_logs`.
- **Schema Details**:
  - `customers`: `id` (UUID, PK), `merchant_id` (UUID, indexed), `email` (VARCHAR, encrypted), `rfm_score` (JSONB), `metadata` (JSONB), `created_at`, `updated_at`.
  - `program_settings`: `id` (UUID, PK), `merchant_id` (UUID, unique), `rfm_thresholds` (JSONB).
  - Indexes: `idx_customers_merchant_id`, `idx_customers_rfm_score` (GIN).
  - Triggers: `trg_customers_updated_at`.
- **GDPR/CCPA Compliance**: `email` encrypted with pgcrypto; redacts PII on `gdpr_request.created`.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - Exposes `/core.v1/GetCustomerRFM` (input: `customer_id`, `merchant_id`; output: `rfm_score`) to Points, Referrals, Campaign.
    - Exposes `/core.v1/CreateCustomer` (input: `merchant_id`, `email`; output: `customer_id`) for Frontend, Shopify imports.
    - Calls `/auth.v1/ValidateMerchant` (input: `merchant_id`; output: boolean) to verify merchants.
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**:
    - `customer.created` (consumers: Campaign for VIP tier checks, AdminFeatures for welcome emails).
    - `customer.updated` (consumers: RFM Analytics for score recalculation, AdminCore for audit logs).
  - **Events Consumed**:
    - `rfm.updated` (from RFM Analytics): Updates `customers.rfm_score`.
    - `gdpr_request.created` (from AdminCore): Redacts `customers.email`.
- **Saga Patterns**: Points (`points.earned`) → RFM Analytics (`rfm.updated`) → Core (`rfm_score` update).

## Key Endpoints
- **gRPC**: `/core.v1/GetCustomerRFM`, `/core.v1/CreateCustomer`.
- **Access Patterns**: Moderate read/write; high-read for `rfm_score`.
- **Rate Limits**: Shopify API (40 req/s Plus for imports).

## Testing Strategy
- **Unit Tests**: Jest for `CoreRepository` (`findById`, `updateRFMScore`).
- **E2E Tests**: Cypress for `/core.v1/GetCustomerRFM`.
- **Load Tests**: k6 for 5,000 merchant queries.
- **Compliance Tests**: Verify `email` encryption, audit logging.

## Deployment
- **Docker Compose**: PostgreSQL on port 5433.
- **Environment Variables**: `CORE_DB_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Read replicas for `customers`.

## Risks and Mitigations
- **Risks**: High read latency for `rfm_score`; Shopify rate limits.
- **Mitigations**: GIN index, batch imports.

## Action Items
- [ ] Deploy `core_db` by July 28, 2025.
- [ ] Test `customer.created` by July 31, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 15, 2025