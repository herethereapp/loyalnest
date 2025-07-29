# AdminFeatures Service Plan

## Overview
- **Purpose**: Manages email templates, events, and integrations.
- **Priority for TVP**: Low (Phase 4 focus).
- **Dependencies**: Core (customer data), Event Tracking (task queue).

## Database Setup
- **Database Type**: PostgreSQL
- **Tables**: `email_templates`, `email_events`, `shopify_flow_templates`, `integrations`.
- **Schema Details**:
  - `email_templates`: `id`, `merchant_id`, `template_id`, `content` (JSONB).
  - Indexes: `idx_email_templates_merchant_id`.
- **GDPR/CCPA Compliance**: `integrations.credentials` encrypted.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**: Exposes `/admin_features.v1/CreateEmailTemplate` (input: `merchant_id`, `content`; output: `template_id`) to Frontend.
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**: `email_event.created` (consumer: Event Tracking for task queue).
  - **Events Consumed**: `customer.created` (Core) for welcome emails.
- **Saga Patterns**: AdminFeatures → Event Tracking → AdminCore.

## Key Endpoints
- **gRPC**: `/admin_features.v1/CreateEmailTemplate`.
- **Access Patterns**: Low write/read (admin tasks).
- **Rate Limits**: None (internal).

## Testing Strategy
- **Unit Tests**: Jest for `AdminFeaturesRepository` (`createEmailTemplate`).
- **E2E Tests**: Cypress for `/admin_features.v1/CreateEmailTemplate`.
- **Load Tests**: Minimal (low volume).
- **Compliance Tests**: Verify `credentials` encryption.

## Deployment
- **Docker Compose**: PostgreSQL on port 5437.
- **Environment Variables**: `ADMIN_FEATURES_DB_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Minimal scaling.

## Risks and Mitigations
- **Risks**: Template misconfiguration.
- **Mitigations**: Schema validation.

## Action Items
- [ ] Deploy `admin_features_db` by July 29, 2025.
- [ ] Test `email_event.created` by August 3, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 7, 2025