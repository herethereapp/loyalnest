# API Gateway Service Plan

## Overview
- **Purpose**: Routes Shopify webhooks and gRPC/REST requests.
- **Priority for TVP**: Medium (enables Points, Referrals).
- **Dependencies**: Auth (token validation), Redis (rate limiting).

## Database Setup
- **Database Type**: Redis
- **Keys**: `rate_limit:{merchant_id}:{endpoint}`.
- **Schema Details**: Key-value with TTL for rate limits.
- **GDPR/CCPA Compliance**: No PII.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - Calls `/auth.v1/ValidateToken` (input: `token`) for all requests.
    - Routes to `/points.v1/*`, `/referrals.v1/*`, `/core.v1/*`, etc.
  - **REST**: Exposes `/webhooks/orders/create` to route Shopify webhooks to Points, Referrals.
- **Asynchronous Communication**:
  - **Events Produced**: `webhook.received` (consumer: AdminCore for debugging, optional).
  - **Events Consumed**: None.
- **Saga Patterns**: None.

## Key Endpoints
- **REST**: `/webhooks/orders/create`.
- **Access Patterns**: High write (10,000 orders/hour).
- **Rate Limits**: Shopify API (40 req/s Plus), Redis limits.

## Testing Strategy
- **Unit Tests**: Jest for `ApiGatewayRepository` (`trackRateLimit`).
- **E2E Tests**: Cypress for webhook routing.
- **Load Tests**: k6 for 10,000 webhooks/hour.
- **Compliance Tests**: None.

## Deployment
- **Docker Compose**: Redis on port 6380.
- **Environment Variables**: `API_GATEWAY_REDIS_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Redis clustering.

## Risks and Mitigations
- **Risks**: Rate limit breaches.
- **Mitigations**: Redis TTLs, fallback queues.

## Action Items
- [ ] Deploy `api_gateway_redis` by July 28, 2025.
- [ ] Test webhook routing by July 31, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 5, 2025