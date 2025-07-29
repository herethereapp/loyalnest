# Event Tracking Service Plan

## Overview
- **Purpose**: Manages async task queue (e.g., email sends).
- **Priority for TVP**: Medium (supports AdminFeatures).
- **Dependencies**: AdminFeatures (email events), AdminCore (audit logs).

## Database Setup
- **Database Type**: PostgreSQL
- **Tables**: `queue_tasks`.
- **Schema Details**:
  - `queue_tasks`: `id`, `merchant_id`, `task_type`, `status`, `payload` (JSONB).
  - Indexes: `idx_queue_tasks_merchant_id`, `idx_queue_tasks_status`.
- **GDPR/CCPA Compliance**: No PII; audit logs via Kafka.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**: Exposes `/event_tracking.v1/CreateTask` (input: `merchant_id`, `task_type`; output: `task_id`) to AdminFeatures.
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**: `task.created`, `task.completed` (consumer: AdminCore for audit logs).
  - **Events Consumed**: `email_event.created` (AdminFeatures) for task queuing.
- **Saga Patterns**: AdminFeatures → Event Tracking → AdminCore.

## Key Endpoints
- **gRPC**: `/event_tracking.v1/CreateTask`.
- **Access Patterns**: Moderate write/read (task queue).
- **Rate Limits**: None (internal).

## Testing Strategy
- **Unit Tests**: Jest for `EventTrackingRepository` (`createTask`).
- **E2E Tests**: Cypress for `/event_tracking.v1/CreateTask`.
- **Load Tests**: k6 for task queue throughput.
- **Compliance Tests**: Audit log creation.

## Deployment
- **Docker Compose**: PostgreSQL on port 5439.
- **Environment Variables**: `EVENT_TRACKING_DB_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Worker processes for tasks.

## Risks and Mitigations
- **Risks**: Task queue backlog.
- **Mitigations**: Status indexing, worker scaling.

## Action Items
- [ ] Deploy `event_tracking_db` by July 29, 2025.
- [ ] Test `task.created` by August 2, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 8, 2025