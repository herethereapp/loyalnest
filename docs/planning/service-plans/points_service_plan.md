# Points Service Plan

## Overview
- **Purpose**: Manages points transactions and reward redemptions.
- **Priority for TVP**: High (core TVP feature).
- **Dependencies**: Core (customer data), Auth (merchant validation), Shopify API.

## Database Setup
- **Database Type**: MongoDB
- **Collections**: `points_transactions`, `reward_redemptions`, `pos_offline_queue`.
- **Schema Details**:
  - `points_transactions`: `id`, `customer_id`, `merchant_id`, `points`, `type`.
  - Indexes: `customer_id`, `merchant_id`, `created_at`.
- **GDPR/CCPA Compliance**: No PII; audit logs via Kafka.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - Exposes `/points.v1/GetPointsBalance` (input: `customer_id`, `merchant_id`; output: `balance`) to Frontend.
    - Calls `/core.v1/GetCustomerRFM` (input: `customer_id`, `merchant_id`) for validation.
    - Calls `/auth.v1/ValidateMerchant` (input: `merchant_id`) for security.
  - **REST**: Consumes Shopify `/orders/create` webhooks via API Gateway.
- **Asynchronous Communication**:
  - **Events Produced**: `points.earned` (consumers: RFM Analytics for score updates, AdminCore for audit logs).
  - **Events Consumed**: None.
- **Saga Patterns**: Points → RFM Analytics → Core.

## Key Endpoints
- **gRPC**: `/points.v1/GetPointsBalance`.
- **Access Patterns**: High write (10,000 orders/hour).
- **Rate Limits**: Shopify API (40 req/s Plus).

## Testing Strategy
- **Unit Tests**: Jest for `PointsRepository` (`createTransaction`).
- **E2E Tests**: Cypress for `/points.v1/GetPointsBalance`.
- **Load Tests**: k6 for 10,000 transactions/hour.
- **Compliance Tests**: Audit log creation.

## Deployment
- **Docker Compose**: MongoDB on port 27017.
- **Environment Variables**: `POINTS_DB_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Sharding for writes.

## Risks and Mitigations
- **Risks**: Write bottlenecks.
- **Mitigations**: MongoDB sharding, batch writes.

## Action Items
- [ ] Deploy `points_db` by July 28, 2025.
- [ ] Test `points.earned` by July 31, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 10, 2025