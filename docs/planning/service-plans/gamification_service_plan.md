# Gamification Service Plan

## Overview
- **Purpose**: Prepares Redis for badges/leaderboards (Phase 6).
- **Priority for TVP**: Low (Phase 3 prep only).
- **Dependencies**: Core (customer data).

## Database Setup
- **Database Type**: Redis
- **Keys**: `badge:{merchant_id}:{customer_id}:{badge}`, `leaderboard:{merchant_id}`.
- **Schema Details**: Key-value, sorted sets.
- **GDPR/CCPA Compliance**: No PII.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**: Exposes `/gamification.v1/AwardBadge` (Phase 6) to Frontend.
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**: `badge.awarded` (Phase 6, consumers: Points, AdminCore).
  - **Events Consumed**: None in Phase 3.
- **Saga Patterns**: None in Phase 3.

## Key Endpoints
- **gRPC**: `/gamification.v1/AwardBadge` (Phase 6).
- **Access Patterns**: None in Phase 3.
- **Rate Limits**: None.

## Testing Strategy
- **Unit Tests**: Jest for `GamificationRepository` (`awardBadge`).
- **E2E Tests**: None in Phase 3.
- **Load Tests**: None in Phase 3.
- **Compliance Tests**: None.

## Deployment
- **Docker Compose**: Redis on port 6381.
- **Environment Variables**: `GAMIFICATION_REDIS_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Redis clustering (Phase 6).

## Risks and Mitigations
- **Risks**: Premature implementation.
- **Mitigations**: Defer logic to Phase 6.

## Action Items
- [ ] Deploy `gamification_redis` by July 30, 2025.
- [ ] Test Redis keys by August 3, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 5, 2025