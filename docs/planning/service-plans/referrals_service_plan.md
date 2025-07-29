# Referrals Service Plan

## Overview
- **Purpose**: Manages referral links and conversions (7% SMS conversion).
- **Priority for TVP**: High (core TVP feature).
- **Dependencies**: Core (customer data), Points (rewards), Auth (merchant validation).

## Database Setup
- **Database Type**: PostgreSQL + Redis
- **Tables/Keys**: `referrals` (PostgreSQL), `referral:{merchant_id}:{id}` (Redis).
- **Schema Details**:
  - `referrals`: `id`, `merchant_id`, `customer_id`, `referral_link_id`, `status`.
  - Indexes: `idx_referrals_merchant_id`, `idx_referrals_referral_link_id`.
- **GDPR/CCPA Compliance**: `customer_id` linked to Core’s encrypted `email`.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - Exposes `/referrals.v1/GetReferralStatus` (input: `referral_id`, `merchant_id`; output: `status`) to Frontend.
    - Calls `/core.v1/GetCustomerRFM` (input: `customer_id`, `merchant_id`) for validation.
    - Calls `/auth.v1/ValidateMerchant` (input: `merchant_id`).
  - **REST**: Consumes Shopify `/orders/create` via API Gateway.
- **Asynchronous Communication**:
  - **Events Produced**: `referral.completed` (consumers: Points for rewards, RFM Analytics for scores, AdminCore for audit logs).
  - **Events Consumed**: None.
- **Saga Patterns**: Referrals → Points → RFM Analytics.

## Key Endpoints
- **gRPC**: `/referrals.v1/GetReferralStatus`.
- **Access Patterns**: High read/write (7% SMS conversion).
- **Rate Limits**: Shopify API (40 req/s Plus).

## Testing Strategy
- **Unit Tests**: Jest for `ReferralsRepository` (`getReferral`).
- **E2E Tests**: Cypress for `/referrals.v1/GetReferralStatus`.
- **Load Tests**: k6 for 700 conversions/hour.
- **Compliance Tests**: Audit logs via `referral.completed`.

## Deployment
- **Docker Compose**: PostgreSQL (port 5434), Redis (port 6379).
- **Environment Variables**: `REFERRALS_DB_HOST`, `REFERRALS_REDIS_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Redis for fast lookups, PostgreSQL read replicas.

## Risks and Mitigations
- **Risks**: Redis cache inconsistency.
- **Mitigations**: TTLs, PostgreSQL sync.

## Action Items
- [ ] Deploy `referrals_db` by July 28, 2025.
- [ ] Test `referral.completed` by July 31, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 10, 2025