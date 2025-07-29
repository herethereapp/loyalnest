# Frontend Service Plan

## Overview
- **Purpose**: Provides UI for merchants and customers.
- **Priority for TVP**: Medium (displays Points, Referrals, RFM data).
- **Dependencies**: API Gateway, Core, Points, Referrals, RFM Analytics.

## Database Setup
- **Database Type**: None (queries via API Gateway).
- **Tables/Collections**: N/A.
- **Schema Details**: N/A.
- **GDPR/CCPA Compliance**: No PII storage; relies on Core.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - Calls `/points.v1/GetPointsBalance` (input: `customer_id`, `merchant_id`) for points display.
    - Calls `/referrals.v1/GetReferralStatus` (input: `referral_id`, `merchant_id`) for referral status.
    - Calls `/core.v1/GetCustomerRFM` (input: `customer_id`, `merchant_id`) for RFM data.
    - Calls `/rfm.v1/GetSegmentCounts` (input: `merchant_id`) for analytics.
  - **REST**: Exposes `/frontend/points`, `/frontend/referrals` (proxied via API Gateway).
- **Asynchronous Communication**:
  - **Events Produced**: None.
  - **Events Consumed**: None.
- **Saga Patterns**: None.

## Key Endpoints
- **REST**: `/frontend/points`, `/frontend/referrals`.
- **Access Patterns**: High read (merchant dashboards).
- **Rate Limits**: Shopify API (40 req/s Plus).

## Testing Strategy
- **Unit Tests**: Jest for UI components.
- **E2E Tests**: Cypress for dashboard flows.
- **Load Tests**: k6 for 5,000 merchant views/hour.
- **Compliance Tests**: Verify no PII exposure.

## Deployment
- **Docker Compose**: Node.js server for SSR (port 3000).
- **Environment Variables**: `API_GATEWAY_URL`.
- **Scaling Considerations**: CDN for static assets.

## Risks and Mitigations
- **Risks**: UI latency.
- **Mitigations**: API Gateway caching, CDN.

## Action Items
- [ ] Deploy frontend by July 30, 2025.
- [ ] Test dashboard flows by August 5, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 10, 2025