# Products Service Plan

## Overview
- **Purpose**: Manages product search/recommendations (Phase 6 prep).
- **Priority for TVP**: Low (Phase 3 prep only).
- **Dependencies**: Core (customer data).

## Database Setup
- **Database Type**: Elasticsearch
- **Index**: `products` (`id`, `merchant_id`, `name`, `rfm_score`).
- **Schema Details**: Text fields for search, keyword for `merchant_id`.
- **GDPR/CCPA Compliance**: No PII.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**: Exposes `/products.v1/SearchProducts` (Phase 6, input: `merchant_id`, `query`; output: products) to Frontend.
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**: `product.updated` (Phase 6, consumer: RFM Analytics).
  - **Events Consumed**: None in Phase 3.
- **Saga Patterns**: None in Phase 3.

## Key Endpoints
- **gRPC**: `/products.v1/SearchProducts` (Phase 6).
- **Access Patterns**: None in Phase 3.
- **Rate Limits**: None.

## Testing Strategy
- **Unit Tests**: Jest for `ProductsRepository` (`searchProducts`).
- **E2E Tests**: None in Phase 3.
- **Load Tests**: None in Phase 3.
- **Compliance Tests**: None.

## Deployment
- **Docker Compose**: Elasticsearch on port 9200.
- **Environment Variables**: `PRODUCTS_DB_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Elasticsearch sharding (Phase 6).

## Risks and Mitigations
- **Risks**: Premature indexing.
- **Mitigations**: Defer logic to Phase 6.

## Action Items
- [ ] Deploy `products_db` by July 30, 2025.
- [ ] Test index creation by August 3, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 5, 2025