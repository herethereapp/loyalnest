# RFM Service Plan

## Overview
- **Purpose**: Manages RFM (Recency, Frequency, Monetary) analytics, including segment retrieval, visualizations, churn risk identification, and simulations, replacing `RFMAnalyticsService` functionality (US-MD5, US-MD12, US-MD20–22, US-AM16, US-BI5).
- **Priority for TVP**: High, as RFM analytics drive merchant insights and customer retention.
- **Dependencies**:
  - `users-service`: Customer data for RFM scores.
  - `points-service`: Points transactions for frequency/monetary data.
  - `campaign-service`: Lifecycle campaigns based on RFM segments (US-MD19).
  - `auth-service`: JWT validation.
  - External: xAI API (https://x.ai/api) for churn prediction, Shopify API (order data).

## Database Setup
- **Database Type**: PostgreSQL (aligned with `schema.sql`).
- **Tables/Collections**:
  - `rfm_segment_counts` (I24a): Materialized view for RFM segments.
  - `rfm_benchmarks` (I27a): Anonymized industry benchmarks.
  - `analytics_metrics` (I24a): Visualization data.
  - `nudge_events` (I20): A/B test nudge interactions.
- **Schema Details**:
  - `rfm_segment_counts`:
    - `merchant_id` (UUID, foreign key).
    - `segment_name` (TEXT, e.g., `Champions`).
    - `count` (INTEGER).
    - Index: `idx_rfm_segment_counts_merchant_id_segment_name`.
  - `rfm_benchmarks`:
    - `merchant_id` (UUID, foreign key).
    - `segment_name` (TEXT).
    - `industry_avg` (JSONB, e.g., `{ "count": 600 }`).
    - Index: `idx_rfm_benchmarks_merchant_id`.
  - `analytics_metrics`:
    - `merchant_id` (UUID, foreign key).
    - `metric` (TEXT, e.g., `repeat_purchase_rate`).
    - `data` (JSONB, e.g., `{ "2025-01-01": 0.2 }`).
    - Index: `idx_analytics_metrics_merchant_id`.
  - `nudge_events`:
    - `event_id` (UUID, primary key).
    - `merchant_id` (UUID, foreign key).
    - `ab_test_id` (TEXT).
    - `data` (JSONB, e.g., `{ "variant": "A", "clicks": 50 }`).
    - Index: `idx_nudge_events_merchant_id`.
- **GDPR/CCPA Compliance**:
  - Anonymized data in `rfm_benchmarks`.
  - No PII in `rfm_segment_counts`, `analytics_metrics`, `nudge_events`.
  - `audit_logs` (via `users-service`) track RFM simulation access.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - `/rfm.v1/GetSegments`:
      - Input: `merchant_id`.
      - Output: `GetSegmentsResponse` (segments).
      - Target: `campaign-service`, `admin-service`.
    - `/rfm.v1/GetChurnRisk`:
      - Input: `merchant_id`.
      - Output: `GetChurnRiskResponse` (at-risk customers).
      - Target: `campaign-service` (US-MD22).
    - `/rfm.v1/ConfigureABTestNudges`:
      - Input: `merchant_id`, `variant_config`.
      - Output: `ConfigureABTestNudgesResponse`.
      - Target: `admin-service` (US-MD21).
  - **REST**:
    - `/api/rfm/visualizations`: Retrieve Chart.js visualization data (US-MD5).
- **Asynchronous Communication**:
  - **Events Produced**:
    - `rfm.updated`:
      - Consumers: `campaign-service`, `admin-service`.
      - Purpose: Trigger lifecycle campaigns, update dashboards.
    - `churn_risk.detected`:
      - Consumers: `campaign-service`.
      - Purpose: Initiate Shopify Flow actions (US-MD22).
  - **Events Consumed**:
    - `customer.created` (from `users-service`):
      - Action: Initialize RFM score.
    - `points.earned` (from `points-service`):
      - Action: Update frequency/monetary scores.
- **Saga Patterns**:
  - RFM Update Saga:
    - `users-service` → `points-service` → `rfm-service`: New customer, points earned, RFM score updated.

## Key Endpoints
- **gRPC/REST**:
  - `/rfm.v1/GetSegments`: Retrieve RFM segments (US-MD12).
  - `/rfm.v1/GetChurnRisk`: Identify at-risk customers (US-MD22).
  - `/rfm.v1/ConfigureABTestNudges`: Configure A/B test nudges (US-MD21).
  - `/rfm.v1/PreviewRFMSegments`: Simulate RFM segments (US-AM16).
  - `/api/rfm/visualizations` (REST): Retrieve visualizations (US-MD5).
- **Access Patterns**:
  - High-read: `GetSegments`, `GetChurnRisk` (5,000 concurrent requests).
  - Medium-write: `ConfigureABTestNudges`, `PreviewRFMSegments`.
- **Rate Limits**:
  - xAI API: 10 req/s, 3x exponential backoff retries.
  - Shopify API: 2 req/s (REST).

## Testing Strategy
- **Unit Tests**: Jest for `RFMRepository.getSegments`, `RFMService.getChurnRisk`.
- **E2E Tests**: Cypress for `/rfm.v1/GetSegments`, `/api/rfm/visualizations`.
- **Load Tests**: k6 for 5,000 concurrent `GetSegments` calls.
- **Compliance Tests**: Verify anonymized data in `rfm_benchmarks`.

## Deployment
- **Docker Compose**:
  - Service: `rfm-service`, port 50053 (gRPC), 8081 (REST).
  - Dependencies: PostgreSQL (port 5432), Kafka, Redis.
- **Environment Variables**:
  - `RFM_DB_HOST`, `RFM_DB_PORT`, `RFM_DB_NAME`.
  - `KAFKA_BROKER`, `XAI_API_KEY`.
- **Scaling Considerations**:
  - Horizontal scaling for read-heavy endpoints.
  - Materialized views for `rfm_segment_counts` to reduce query latency.

## Risks and Mitigations
- **Risks**:
  - xAI API timeouts affecting churn risk detection.
  - High query latency for `rfm_segment_counts`.
- **Mitigations**:
  - 3x exponential backoff retries for xAI API.
  - Indexes and materialized views for `rfm_segment_counts`.

## Action Items
- [ ] Define `RFMSegment.entity.ts` schema by August 10, 2025.
- [ ] Implement `/rfm.v1/GetChurnRisk` endpoint by August 18, 2025.
- [ ] Test Kafka `rfm.updated` event by August 22, 2025.
- [ ] Set up PostgreSQL materialized views by August 15, 2025.

## Timeline
- **Start Date**: August 8, 2025
- **Completion Date**: September 8, 2025
- **Milestones**:
  - Schema setup by August 15, 2025.
  - Endpoints implemented by August 25, 2025.
  - Testing completed by September 5, 2025.