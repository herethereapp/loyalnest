# Auth Service Plan

## Overview
- **Purpose**: Manages merchant authentication, sessions, and impersonation.
- **Priority for TVP**: Low (supports other services).
- **Dependencies**: API Gateway (token validation).

## Database Setup
- **Database Type**: PostgreSQL
- **Tables**: `merchants`, `admin_users`, `admin_sessions`, `impersonation_sessions`.
- **Schema Details**:
  - `merchants`: `id` (UUID, PK), `shop_domain` (VARCHAR, unique), `language` (JSONB).
  - Indexes: `idx_merchants_shop_domain`, `idx_merchants_language` (GIN).
  - Triggers: `trg_normalize_shop_domain`.
- **GDPR/CCPA Compliance**: `admin_users.email` encrypted.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - Exposes `/auth.v1/ValidateToken` (input: `token`; output: boolean) to API Gateway.
    - Exposes `/auth.v1/ValidateMerchant` (input: `merchant_id`; output: boolean) to Core, Points, Referrals.
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**: `merchant.created` (consumers: Core for customer setup).
  - **Events Consumed**: None.
- **Saga Patterns**: None.

## Key Endpoints
- **gRPC**: `/auth.v1/ValidateToken`.
- **Access Patterns**: Low write, moderate read (session validation).
- **Rate Limits**: None (internal).

## Testing Strategy
- **Unit Tests**: Jest for `AuthRepository` (`findByShopDomain`).
- **E2E Tests**: Cypress for `/auth.v1/ValidateToken`.
- **Load Tests**: k6 for 5,000 logins/hour.
- **Compliance Tests**: Verify `email` encryption.

## Deployment
- **Docker Compose**: PostgreSQL on port 5432.
- **Environment Variables**: `AUTH_DB_HOST`.
- **Scaling Considerations**: Minimal scaling.

## Risks and Mitigations
- **Risks**: Session token leaks.
- **Mitigations**: Short-lived tokens, Redis caching.

## Action Items
- [ ] Deploy `auth_db` by July 28, 2025.
- [ ] Test `merchant.created` by July 30, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 5, 2025