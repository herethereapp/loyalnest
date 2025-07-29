# Roles Service Plan

## Overview
- **Purpose**: Manages role-based access control (RBAC) for admin users and multi-tenant groups, supporting admin module features (e.g., US-AM14, US-AM15).
- **Priority for TVP**: Medium, critical for admin security but secondary to customer-facing features.
- **Dependencies**:
  - `users-service`: Admin user data retrieval.
  - `auth-service`: JWT validation and RBAC enforcement.
  - `admin-service`: Multi-tenant configuration (US-AM14).
  - External: None.

## Database Setup
- **Database Type**: PostgreSQL (aligned with `schema.sql`).
- **Tables/Collections**:
  - `roles` (new): Defines RBAC roles.
  - `admin_roles` (new): Maps admin users to roles.
  - `audit_logs` (I12): Tracks role-related actions.
- **Schema Details**:
  - `roles`:
    - `role_id` (UUID, primary key).
    - `name` (TEXT, e.g., `admin:full`, `superadmin`).
    - `permissions` (JSONB, e.g., `{ "scopes": ["read:customers", "write:campaigns"] }`).
    - Index: `idx_roles_name`.
  - `admin_roles`:
    - `admin_user_id` (UUID, foreign key to `admin_users`).
    - `role_id` (UUID, foreign key to `roles`).
    - Index: `idx_admin_roles_admin_user_id`.
  - `audit_logs`:
    - As defined in `users-service`, with actions like `role_assigned`.
- **GDPR/CCPA Compliance**:
  - No direct PII storage; `admin_user_id` links to `admin_users` (AES-256 encrypted).
  - `audit_logs` track role assignments for compliance.

## Inter-Service Communication
- **Synchronous Communication**:
  - **gRPC**:
    - `/roles.v1/GetRole`:
      - Input: `role_id`.
      - Output: `Role` (name, permissions).
      - Target: `auth-service`, `admin-service`.
    - `/roles.v1/AssignRole`:
      - Input: `admin_user_id`, `role_id`.
      - Output: `AdminRole`.
      - Target: `admin-service` (US-AM14).
  - **REST**: None.
- **Asynchronous Communication**:
  - **Events Produced**:
    - `role.assigned`:
      - Consumers: `auth-service`, `admin-service`.
      - Purpose: Update JWT scopes, multi-tenant config.
    - `role.updated`:
      - Consumers: `auth-service`.
      - Purpose: Refresh cached permissions.
  - **Events Consumed**:
    - `admin_user.updated` (from `users-service`):
      - Action: Validate role assignments.
- **Saga Patterns**:
  - Role Assignment Saga:
    - `roles-service` → `auth-service` → `admin-service`: Assigns role, updates JWT, syncs multi-tenant group.

## Key Endpoints
- **gRPC/REST**:
  - `/roles.v1/GetRole`: Retrieve role details.
  - `/roles.v1/AssignRole`: Assign role to admin user (US-AM14).
- **Access Patterns**:
  - High-read: `GetRole` (every admin action).
  - Low-write: `AssignRole` (infrequent updates).
- **Rate Limits**:
  - Internal: 50 req/s per admin user.

## Testing Strategy
- **Unit Tests**: Jest for `RolesRepository.findById`, `RolesService.assignRole`.
- **E2E Tests**: Cypress for `/roles.v1/AssignRole`.
- **Load Tests**: k6 for 1,000 concurrent `GetRole` calls.
- **Compliance Tests**: Verify `audit_logs` for role assignments.

## Deployment
- **Docker Compose**:
  - Service: `roles-service`, port 50052 (gRPC).
  - Dependencies: PostgreSQL (port 5432), Kafka.
- **Environment Variables**:
  - `ROLES_DB_HOST`, `ROLES_DB_PORT`, `ROLES_DB_NAME`.
  - `KAFKA_BROKER`.
- **Scaling Considerations**:
  - Lightweight service; single instance sufficient initially.
  - PostgreSQL indexes optimize read-heavy access.

## Risks and Mitigations
- **Risks**:
  - Incorrect role assignments causing unauthorized access.
  - High read latency for `GetRole`.
- **Mitigations**:
  - RBAC validation in `auth-service`.
  - Redis caching for `role:{role_id}`.

## Action Items
- [ ] Define `Role.entity.ts` schema by August 8, 2025.
- [ ] Implement `/roles.v1/AssignRole` endpoint by August 15, 2025.
- [ ] Test Kafka `role.assigned` event by August 20, 2025.
- [ ] Set up PostgreSQL indexes by August 10, 2025.

## Timeline
- **Start Date**: August 5, 2025
- **Completion Date**: September 5, 2025
- **Milestones**:
  - Schema setup by August 10, 2025.
  - Endpoints implemented by August 18, 2025.
  - Testing completed by September 3, 2025.