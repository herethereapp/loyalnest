# AdminCore Service Plan

## Overview
- **Purpose**: Handles audit logs and GDPR/CCPA compliance.
- **Priority for TVP**: Medium (supports compliance).
- **Dependencies**: Points, Referrals, Core (audit logs).

## Database Setup
- **Database Type**: PostgreSQL
- **Tables**: `audit_logs`, `gdpr_requests`, `gdpr_redaction_log`, `webhook_idempotency_keys`.
- **Schema Details**:
  - `audit_logs`: `id`, `merchant_id`, `entity_type`, `action`.
  - Indexes: `idx_audit_logs_merchant_id`.
- **GDPR/CCPA Compliance**: Logs GDPR requests, redacts PII.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**: Exposes `/admin_core.v1/GetAuditLogs` (input: `merchant_id`; output: logs) to Frontend.
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**: `gdpr_request.created` (consumers: Core for PII redaction).
  - **Events Consumed**: `audit_log` (Points, Referrals), `customer.updated` (Core), `task.completed` (Event Tracking).
- **Saga Patterns**: AdminCore → Core (PII redaction).

## Key Endpoints
- **gRPC**: `/admin_core.v1/GetAuditLogs`.
- **Access Patterns**: Low write, moderate read.
- **Rate Limits**: None (internal).

## Testing Strategy
- **Unit Tests**: Jest for `AdminCoreRepository` (`createAuditLog`).
- **E2E Tests**: Cypress for `/admin_core.v1/GetAuditLogs`.
- **Load Tests**: k6 for audit log queries.
- **Compliance Tests**: Verify GDPR request logging.

## Deployment
- **Docker Compose**: PostgreSQL on port 5436.
- **Environment Variables**: `ADMIN_CORE_DB_HOST`, `KAFKA_BROKER`.
- **Scaling Considerations**: Minimal scaling.

## Risks and Mitigations
- **Risks**: Missing audit logs.
- **Mitigations**: Kafka retries, DB triggers.

## Action Items
- [ ] Deploy `admin_core_db` by July 29, 2025.
- [ ] Test `gdpr_request.created` by August 2, 2025.

## Timeline
- **Start Date**: July 25, 2025
- **Completion Date**: August 8, 2025