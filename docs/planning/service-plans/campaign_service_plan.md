# Campaign Service Plan

## Overview
- **Purpose**: Manages VIP tiers for loyalty campaigns.
- **Priority for TVP**: Low (Phase 4 focus).
- **Dependencies**: Core (customer data).

## Database Setup
- **Database Type**: PostgreSQL
- **Tables**: `vip_tiers`.
- **Schema Details**:
  - `vip_tiers`: `id`, `merchant_id`, `tier_id`, `config` (JSONB).
  - Indexes: `idx_vip_tiers_merchant_id`.
- **GDPR/CCPA Compliance**: No PII.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**: Exposes `/campaign.v1/GetVIPTier` (input: `merchant_id`, `tier_id`; output: `config`) to Frontend.
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**: `vip_tier.assigned` (Phase 6, consumers: Points).
  - **Events Consumed**: `customer.created` (Core) for tier checks.
- **Saga Patterns**: None in Phase 3.

## Key Endpoints
- **gRPC**: `/campaign.v1/GetVIPTier`.
- **Access Patterns**: Low read/write (static configs).
- **Rate Limits**: None (internal).

## Testing Strategy
- **Unit Tests**: Jest for `CampaignRepository` (`createVIPTier`).
- **E2E Tests**: Cypress for `/campaign.v1/GetVIPTier`.
- **Load Tests**: Minimal (low volume).
- **Compliance Tests**: None.

## Deployment
- **Docker Compose**: PostgreSQL on port 5438.
- **Environment Variables**: `CAMPAIGN_DB_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Minimal scaling.

## Risks and Mitigations
- **Risks**: Misconfigured tiers.
- **Mitigations**: JSONB schema validation.

## Action Items
- [ ] Deploy `campaign_db` by July 29, 2025.
- [ ] Test `customer.created` consumption by August 3, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 7, 2025