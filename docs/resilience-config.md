
# resilience-config.md

This document defines resilience standards across all services in the `loyalnest` monorepo to ensure system reliability, fault isolation, and graceful degradation under high load or failure conditions.

---

## 🌐 Shared Resilience Principles (Applies to All Services)

| Concern | Strategy |
|--------|----------|
| **Process Isolation** | Each service runs in its own container, separate memory/process space |
| **Health Checks** | Implement `/health` endpoint (HTTP 200 OK), integrated with Kubernetes readiness/liveness probes |
| **Rate Limiting** | Use `@nestjs/throttler` or custom middleware; global + per-route limits |
| **Circuit Breaker** | Use [Opossum](https://nodeshift.dev/opossum/) or fallback patterns for external calls |
| **Retry Logic** | Retry external calls (DB, APIs, queues) with exponential backoff (`@nestjs/axios` interceptor or `rxjs` retryWhen) |
| **Timeouts** | Set explicit timeouts (e.g., HTTP, DB, Redis) to prevent hanging processes |
| **Bulkheads** | Worker pools (e.g., Bull queue concurrency) per domain or feature |
| **Fallbacks** | Return cached values, default responses, or stubbed values on failure |
| **Metrics** | Use Prometheus + Grafana, capture latency, throughput, error rates |
| **Logs** | Centralized structured logs via Winston + Loki or Fluentd |
| **Graceful Shutdown** | Implement `onModuleDestroy` and `onApplicationShutdown` in every service |
| **Secrets Management** | Use `.env`, but mount secrets via Kubernetes secrets in production |
| **Security Hardening** | Input validation, auth guards, rate limiters, audit logging |
| **Testing** | Unit, integration, and chaos testing (e.g., Gremlin/Fault injection tools) |

---

## 📦 Service-Specific Notes

---

### `admin_core-service`

- **Scope**: Admin accounts, roles, login audit, merchant management
- **Resilience Notes**:
  - Strong input validation on all admin routes
  - Fail-closed auth policies; if Redis cache fails, deny access
  - Audit logs must be written asynchronously to avoid blocking admin UI

---

### `admin_features-service`

- **Scope**: Feature flag management for merchants
- **Resilience Notes**:
  - Use cached flags with Redis fallback
  - Ensure flag updates are propagated with retry-capable event queue
  - Default to safe values if feature status unknown

---

### `api-gateway`

- **Scope**: Routes and proxies requests to internal services
- **Resilience Notes**:
  - Global timeout (e.g., 3s) and retry logic
  - Circuit breakers per downstream service
  - Input validation before forwarding
  - Rate limit based on IP + Merchant ID

---

### `auth-service`

- **Scope**: Merchant authentication, JWT issuing, session validation
- **Resilience Notes**:
  - Stateless JWTs preferred (fallback cache if session store down)
  - Rate limit login attempts
  - Fallback CAPTCHA if abuse detected

---

### `campaign-service`

- **Scope**: Managing marketing and loyalty campaigns
- **Resilience Notes**:
  - Queue-based processing with retries (e.g., Bull)
  - If email or SMS provider fails, retry with backoff and log permanently failed
  - Use transactional logs to recover incomplete campaign states

---

### `core-service`

- **Scope**: Merchant account data, subscription plans, integrations
- **Resilience Notes**:
  - Strong schema constraints at DB level (PostgreSQL)
  - Mirror data to Redis cache to reduce DB load
  - Prevent cross-service failures from affecting merchant login

---

### `event_tracking-service`

- **Scope**: Logs frontend and backend merchant/customer events
- **Resilience Notes**:
  - Fire-and-forget write queue to avoid impacting main flow
  - Fallback to local buffer (e.g., memory or tmp file) if DB down
  - Deduplicate to avoid double-tracking during retries

---

### `frontend`

- **Scope**: React-based UI (merchant and customer)
- **Resilience Notes**:
  - Use SWR or React Query for automatic retries and caching
  - Display fallback UIs (e.g., skeletons, error banners)
  - Integrate with backend health check APIs for graceful fallback

---

### `gamification-service`

- **Scope**: Badges, achievements, engagement scoring
- **Resilience Notes**:
  - Timeouts on reward evaluation logic
  - Graceful degradation: skip badge if logic fails (do not crash rewards flow)
  - Daily cron jobs with retry-on-failure strategies

---

### `points-service`

- **Scope**: Points issuance, spending, balance tracking
- **Resilience Notes**:
  - Use DB-level transaction + event sourcing pattern
  - Retryable queue for all point mutations
  - Circuit break SMS/email notifications if external provider fails

---

### `products-service`

- **Scope**: Flower packages and subscription product definitions
- **Resilience Notes**:
  - Strong input validation (SKU, pricing)
  - Redis cache for product catalog
  - Gracefully degrade to minimal product info if API fails

---

### `referrals-service`

- **Scope**: Invite tracking, referral rewards, SMS links
- **Resilience Notes**:
  - Queue referral events and retries (SMS can fail silently)
  - Monitor delivery and confirmation (e.g., Twilio webhook)
  - Defer reward issuance until confirmation succeeds

---

### `rfm_analytics-service`

- **Scope**: Recency-Frequency-Monetary scoring and segmentation
- **Resilience Notes**:
  - Asynchronous jobs with backoff retry on failure
  - Daily or hourly batch jobs (not real-time)
  - If analytics DB is unavailable, skip segmenting with fallback logic

---

## 🧪 Bonus: Chaos Testing (Recommended)

- Use [`chaos-mesh`](https://chaos-mesh.org/) or `gremlin.com` to simulate:
  - Service crash
  - High latency
  - Network partition
  - Message queue drops
- Ensure that:
  - Retry/circuit breakers kick in
  - Metrics + alerts are triggered
  - Downstream services remain unaffected

---

Let me know if you'd like this exported as `.md` or want per-service config boilerplate (e.g., NestJS modules, Bull queues, retry wrappers).
