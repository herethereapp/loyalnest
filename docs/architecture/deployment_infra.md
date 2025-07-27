# LoyalNest Deployment and Infrastructure Guide

## 1. Overview
This guide outlines the deployment process and infrastructure setup for the LoyalNest Shopify app on a VPS (Ubuntu 22.04 LTS), supporting the Merchant Dashboard, Customer Widget, Admin Module (split into AdminCore and AdminFeatures), and backend integrations. The app is built with Vite + React, Shopify Polaris, Tailwind CSS, App Bridge, NestJS, gRPC, PostgreSQL, Redis, and Docker, targeting 5,000+ merchants and 50,000+ customers (Shopify Plus). It ensures GDPR/CCPA compliance, multilingual support (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he` via i18next, RTL for `ar`, `he`), and high availability (99.9% uptime). This aligns with `technical_specifications.md` (artifact_id: `05357ac3-e4bb-4cf3-a3e4-6cac7257f9e7`), `Sequence Diagrams.txt` (artifact_id: `478975db-7432-4070-826d-f9040af8fbd0`), `RFM.markdown` (artifact_id: `b4ca549b-7ffa-42c3-9db2-9a4a74151dbf`), and updated project plan.

## 2. Infrastructure Architecture
### 2.1 Components
- **Frontend**: Vite + React, served via Nginx on VPS.
  - Minified assets (<50KB Widget, <200KB Dashboard), WebP images, lazy-loaded Chart.js.
  - Shopify App Bridge for embedded dashboard, Polaris for UI, Tailwind for responsive layouts (`sm: 320px, md: 768px`).
  - i18next for 22-language support (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`; RTL for `ar`, `he`).
- **Backend**: NestJS with gRPC services (`/points.v1/*`, `/referrals.v1/*`, `/analytics.v1/*`, `/admin.v1/*` for AdminCore, `/admin.v1/features/*` for AdminFeatures, `/auth.v1/*`).
  - Dockerized, orchestrated via Docker Compose.
- **Database**: PostgreSQL 15 (VPS-hosted, `pgx` pooling, `pgcrypto` for encryption).
  - Partitioned tables (`points_transactions`, `referrals`, `reward_redemptions`, `customer_segments`, `email_events`, `nudge_events`, `bonus_campaigns`, `gamification_achievements`, `leaderboards`, `data_imports`, `data_export_requests`, `merchant_referrals`, `slack_community`, `onboarding_tasks`, `rfm_score_history`, `analytics_reports`, `analytics_report_schedules`, `audit_logs`, `simulation_logs`, `rfm_segment_deltas`) by `merchant_id` (8 partitions).
  - Materialized view (`rfm_segment_counts`) for RFM analytics, refreshed daily (`0 1 * * *`).
  - Indexes: `idx_customers_rfm_score_at_risk`, `idx_points_transactions_customer_id`, `idx_rfm_score_history_merchant_id_customer_id`, `idx_audit_logs_action`, `idx_simulation_logs_customer_id`, `idx_rfm_segment_deltas_customer_id`.
  - AES-256 encryption for `customers.email`, `customers.phone`, `merchants.api_token`, `reward_redemptions.discount_code`, `customers.rfm_score`.
- **Cache**: Redis (VPS-hosted) for `points:{customer_id}`, `config:{merchant_id}`, `rfm:preview:{merchant_id}`, `rfm:burst:{merchant_id}`, `campaign_discount:{campaign_id}`, `leaderboard:{merchant_id}`, `template:{merchant_id}:{type}`, `rate_limit:{merchant_id}`.
- **Queue**: Bull (Redis-backed) for notifications (Klaviyo/Postscript, AWS SES fallback), customer imports, rate limit alerts, `rfm_segment_counts` refresh, Square POS sync.
- **Integrations**: Shopify (OAuth, webhooks, GraphQL Admin API, POS offline mode), Klaviyo/Postscript (notifications, AWS SES fallback), PostHog (analytics), Square POS (Phase 3), LaunchDarkly (feature flags: `rfm_simulation`, `rfm_advanced`).
- **Monitoring**: PostHog for UI events (e.g., `points_earned`, `referral_created`, `rfm_segment_deltas_updated`, `action_undone`, `square_sync_triggered`), Prometheus + Grafana for metrics (CPU, memory, API latency), Loki for logs, Sentry for errors.

### 2.2 Architecture Diagram
```mermaid
graph TD
    A[Client Browser] -->|HTTPS| B[Nginx]
    B -->|Static Assets| C[Frontend: Vite + React]
    A -->|Shopify App Bridge| D[Merchant Dashboard]
    C -->|gRPC| E[API Gateway: Nginx]
    E -->|gRPC| F[Docker Compose: NestJS Services]
    F -->|Points Service| G[PostgreSQL]
    F -->|Referrals Service| G
    F -->|Analytics Service| G
    F -->|AdminCore Service| G
    F -->|AdminFeatures Service| G
    F -->|Auth Service| G
    G -->|Connection Pool| P[pgbouncer]
    F -->|Cache| H[Redis]
    F -->|Queue| I[Bull: Redis]
    I -->|Notifications| J[Klaviyo/Postscript]
    I -->|Fallback| K[AWS SES]
    F -->|Webhooks| L[Shopify API]
    F -->|POS Sync| M[Square API]
    F -->|Logs| N[Loki]
    F -->|Metrics| O[Prometheus + Grafana]
    F -->|Events| Q[PostHog]
    F -->|Errors| R[Sentry]
    G -->|Backups| S[Local Disk + rsync]
```

## 3. Deployment Process
### 3.1 Prerequisites
- **VPS**: Ubuntu 22.04 LTS, 16GB RAM, 8 vCPUs, 200GB SSD (for 5,000+ merchants, 50,000+ customers).
- **Shopify Partner Account**: App registered, OAuth keys, webhook subscriptions (`orders/create`, `orders/cancelled`, `customers/data_request`, `customers/redact`, `pos/offline_sync`).
- **GitHub Repository**: Nx monorepo with `/apps/frontend`, `/apps/points`, `/apps/referrals`, `/apps/analytics`, `/apps/admin-core`, `/apps/admin-features`, `/apps/auth`, `/tests`, `/docs`.
- **Tools**: Docker, Docker Compose, Git, Certbot, rsync, Prometheus, Grafana, Loki, GitHub Actions.
- **Domain**: Configured DNS (e.g., `api.loyalnest.com`, `staging.loyalnest.com`) with A record to VPS IP.
- **Secrets**: Stored in `.env` files, managed via `dotenv` (e.g., Shopify OAuth, Klaviyo/Postscript keys, AWS SES credentials, LaunchDarkly SDK key).

### 3.2 Deployment Steps
1. **VPS Setup**:
   - Update system: `sudo apt update && sudo apt upgrade -y`.
   - Install dependencies: `sudo apt install docker.io docker-compose certbot python3-certbot-nginx nginx git`.
   - Configure firewall: `ufw allow 22,80,443/tcp`.

2. **Code Preparation**:
   - Clone repository: `git clone <repo_url> /opt/loyalnest`.
   - Run `nx build frontend` (Vite, minifies to <50KB for Widget, <200KB for Dashboard).
   - Run `nx build backend` (TypeScript to Node.js for Points, Referrals, Analytics, AdminCore, AdminFeatures, Auth services).

3. **Docker Image Build**:
   - Build images: 
     ```bash
     cd /opt/loyalnest
     docker build -t loyalnest-frontend:latest -f apps/frontend/Dockerfile .
     docker build -t loyalnest-points:latest -f apps/points/Dockerfile .
     docker build -t loyalnest-referrals:latest -f apps/referrals/Dockerfile .
     docker build -t loyalnest-analytics:latest -f apps/analytics/Dockerfile .
     docker build -t loyalnest-admin-core:latest -f apps/admin-core/Dockerfile .
     docker build -t loyalnest-admin-features:latest -f apps/admin-features/Dockerfile .
     docker build -t loyalnest-auth:latest -f apps/auth/Dockerfile .
     ```
   - Tag images: `docker tag loyalnest-<service>:latest localhost:5000/loyalnest-<service>:latest`.

4. **Infrastructure Setup**:
   - **PostgreSQL**:
     - Install: `sudo apt install postgresql postgresql-contrib`.
     - Initialize: `sudo -u postgres psql -f /opt/loyalnest/db/init.sql`.
     - Configure `pgbouncer` for connection pooling (`/etc/pgbouncer/pgbouncer.ini`):
       ```ini
       [databases]
       loyalnest = host=localhost port=5432 dbname=loyalnest user=user password=pass
       [pgbouncer]
       pool_mode = transaction
       max_client_conn = 1000
       ```
     - Start: `sudo systemctl start pgbouncer`.
   - **Redis**:
     - Install: `sudo apt install redis-server`.
     - Configure: `/etc/redis/redis.conf` (AOF persistence, maxmemory 2GB).
     - Start: `sudo systemctl start redis`.
   - **Nginx**:
     - Configure: `/etc/nginx/sites-available/loyalnest` (see Section 4.4).
     - Enable: `sudo ln -s /etc/nginx/sites-available/loyalnest /etc/nginx/sites-enabled/`.
     - Start: `sudo systemctl start nginx`.
   - **Certbot**:
     - Obtain SSL: `sudo certbot --nginx -d api.loyalnest.com`.
     - Auto-renew: `sudo crontab -e` with `0 0 * * * certbot renew --quiet`.

5. **Deployment**:
   - Copy frontend assets: `sudo cp -r apps/frontend/dist /var/www/loyalnest`.
   - Deploy services with Docker Compose: `docker-compose -f /opt/loyalnest/docker-compose.yml up -d`.
   - Run DB migrations: `nx run backend:migrate` (TypeORM, creates `merchant_id` partitions for `points_transactions`, `rfm_segment_deltas`, etc.).
   - Refresh materialized view: `nx run backend:migrate:refresh-rfm`.

6. **Post-Deployment**:
   - Verify services: `curl https://api.loyalnest.com/health`.
   - Check logs: `docker logs loyalnest-<service>`, `loki` at `http://localhost:3100`.
   - Validate PostHog events (e.g., `points_earned`, `rfm_segment_deltas_updated`, `square_sync_triggered`).
   - Monitor Sentry for errors and Grafana for metrics (CPU, memory, API latency).

### 3.3 Rollback Plan
- **Frontend**: Revert to previous assets: `sudo cp -r /var/www/loyalnest-backup /var/www/loyalnest`.
- **Backend**: Roll back Docker Compose services: `docker-compose -f /opt/loyalnest/docker-compose.yml up -d --force-recreate --no-build`.
- **Database**: Restore PostgreSQL backup: `sudo -u postgres pg_restore --dbname=loyalnest /backups/loyalnest-<date>.dump`, then `REFRESH MATERIALIZED VIEW CONCURRENTLY rfm_segment_counts`.

### 3.4 Database Migration for Partitioned Tables
- **Partitioned Tables**: `points_transactions`, `referrals`, `reward_redemptions`, `customer_segments`, `email_events`, `nudge_events`, `bonus_campaigns`, `gamification_achievements`, `leaderboards`, `data_imports`, `data_export_requests`, `merchant_referrals`, `slack_community`, `onboarding_tasks`, `rfm_score_history`, `analytics_reports`, `analytics_report_schedules`, `audit_logs`, `simulation_logs`, `rfm_segment_deltas` use HASH partitioning on `merchant_id` (8 partitions).
- **Materialized View**: `rfm_segment_counts` refreshed via `REFRESH MATERIALIZED VIEW CONCURRENTLY rfm_segment_counts` (Bull queue, `0 1 * * *`).
- **Migration Command**: `nx run backend:migrate --partition=create` to initialize partitions, `nx run backend:migrate:refresh-rfm` for materialized view updates.
- **Zero-Downtime**: Use `CREATE TABLE IF NOT EXISTS` and `ALTER TABLE ... ATTACH PARTITION` to avoid locking during migrations.

## 4. Infrastructure Configuration
### 4.1 Docker Compose
- **Services**: `points`, `referrals`, `analytics`, `admin-core`, `admin-features`, `auth`, `frontend`, `postgres`, `redis`, `pgbouncer`.
- **Scaling**: Configure `docker-compose.yml` with `replicas: 2` for each service, scale manually with `docker-compose scale <service>=4` for high load.
- **Networking**: Bridge network (`loyalnest-network`) for inter-service communication.

**docker-compose.yml**:
```yaml
version: '3.8'
services:
  points:
    image: localhost:5000/loyalnest-points:latest
    ports:
      - "3001:3001"
    environment:
      - DATABASE_URL=postgres://user:pass@postgres:5432/loyalnest
      - REDIS_URL=redis://redis:6379
      - LAUNCHDARKLY_SDK_KEY=${LAUNCHDARKLY_SDK_KEY}
    networks:
      - loyalnest-network
  referrals:
    image: localhost:5000/loyalnest-referrals:latest
    ports:
      - "3002:3002"
    environment:
      - AWS_SES_ACCESS_KEY=${AWS_SES_ACCESS_KEY}
      - AWS_SES_SECRET_KEY=${AWS_SES_SECRET_KEY}
    networks:
      - loyalnest-network
  analytics:
    image: localhost:5000/loyalnest-analytics:latest
    ports:
      - "3003:3003"
    environment:
      - LAUNCHDARKLY_SDK_KEY=${LAUNCHDARKLY_SDK_KEY}
    networks:
      - loyalnest-network
  admin-core:
    image: localhost:5000/loyalnest-admin-core:latest
    ports:
      - "3004:3004"
    networks:
      - loyalnest-network
  admin-features:
    image: localhost:5000/loyalnest-admin-features:latest
    ports:
      - "3006:3006"
    environment:
      - SQUARE_ACCESS_TOKEN=${SQUARE_ACCESS_TOKEN}
      - LAUNCHDARKLY_SDK_KEY=${LAUNCHDARKLY_SDK_KEY}
    networks:
      - loyalnest-network
  auth:
    image: localhost:5000/loyalnest-auth:latest
    ports:
      - "3005:3005"
    networks:
      - loyalnest-network
  frontend:
    image: localhost:5000/loyalnest-frontend:latest
    ports:
      - "3000:3000"
    networks:
      - loyalnest-network
  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=loyalnest
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - /var/lib/postgresql/data:/var/lib/postgresql/data
      - /opt/loyalnest/db/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - loyalnest-network
  redis:
    image: redis:7
    command: redis-server --appendonly yes
    volumes:
      - /var/lib/redis:/data
    networks:
      - loyalnest-network
  pgbouncer:
    image: edoburu/pgbouncer
    environment:
      - DB_HOST=postgres
      - DB_USER=user
      - DB_PASSWORD=pass
      - DB_NAME=loyalnest
      - POOL_MODE=transaction
      - MAX_CLIENT_CONN=1000
    ports:
      - "6432:6432"
    networks:
      - loyalnest-network
  prometheus:
    image: prom/prometheus
    volumes:
      - /opt/loyalnest/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    networks:
      - loyalnest-network
  grafana:
    image: grafana/grafana
    ports:
      - "3007:3000"
    networks:
      - loyalnest-network
  loki:
    image: grafana/loki
    ports:
      - "3100:3100"
    networks:
      - loyalnest-network
networks:
  loyalnest-network:
    driver: bridge
```

### 4.2 PostgreSQL
- **Instance**: PostgreSQL 15 on VPS, 100GB SSD storage.
- **Schema**: Partitioned tables by `merchant_id`, materialized view `rfm_segment_counts`, indexes for RFM and audit logs.
- **Backup**: Daily `pg_dump` to `/backups/loyalnest-<date>.dump`, rsync to offsite VPS (`rsync -avz /backups user@backup-vps:/backups`).
- **Security**: AES-256 encryption (`pgcrypto`), row-level security (RLS) for tenant isolation (`ALTER TABLE customers ENABLE ROW LEVEL SECURITY; CREATE POLICY merchant_isolation ON customers USING (merchant_id = current_setting('app.merchant_id')::UUID)`).
- **Connection Pooling**: `pgbouncer` with `pool_mode=transaction`, `max_client_conn=1000`.

### 4.3 Redis
- **Instance**: Redis 7 on VPS, AOF persistence, 2GB memory.
- **Keys**: `points:{customer_id}`, `config:{merchant_id}`, `rfm:preview:{merchant_id}`, `rfm:burst:{merchant_id}`, `campaign_discount:{campaign_id}`, `leaderboard:{merchant_id}`, `template:{merchant_id}:{type}`, `rate_limit:{merchant_id}`.
- **TTL**: 24h for points, 1h for previews, 7d for leaderboards, 60s for rate limits.

### 4.4 Nginx
- **Configuration**: `/etc/nginx/sites-available/loyalnest`:
```nginx
server {
    listen 80;
    server_name api.loyalnest.com;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    server_name api.loyalnest.com;
    ssl_certificate /etc/letsencrypt/live/api.loyalnest.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.loyalnest.com/privkey.pem;
    location / {
        root /var/www/loyalnest;
        try_files $uri $uri/ /index.html;
    }
    location /points { proxy_pass http://points:3001; }
    location /referrals { proxy_pass http://referrals:3002; }
    location /analytics { proxy_pass http://analytics:3003; }
    location /admin { proxy_pass http://admin-core:3004; }
    location /admin/features { proxy_pass http://admin-features:3006; }
    location /auth { proxy_pass http://auth:3005; }
    location /frontend { proxy_pass http://frontend:3000; }
}
```
- **SSL**: Certbot for HTTPS, auto-renew via cron (`0 0 * * * certbot renew --quiet`).

### 4.5 Monitoring and Logging
- **Prometheus**: Metrics (CPU, memory, API latency), configured in `/opt/loyalnest/prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'loyalnest'
    static_configs:
      - targets: ['points:3001', 'referrals:3002', 'analytics:3003', 'admin-core:3004', 'admin-features:3006', 'auth:3005']
```
- **Grafana**: Dashboards for API latency, DB query performance, Redis memory, Bull queue depth.
- **Loki**: Logs from all services (`docker logs` piped to Loki, accessed at `http://localhost:3100`).
- **PostHog**: Events (`points_earned`, `referral_created`, `rfm_segment_deltas_updated`, `action_undone`, `action_replayed`, `square_sync_triggered`, `offline_sync_completed`).
- **Sentry**: Runtime errors, tagged by `merchant_id`, `customer_id`.
- **Alerts**: Grafana alerts for >80% CPU, >0.1% error rate, `rfm_segment_counts` refresh failures, `gdpr_requests` with `retention_expires_at < NOW()`, notified via email/Slack.

### 4.6 Multi-Tenant Isolation
- **Schema Isolation**: HASH partitioning on `merchant_id` for tables like `points_transactions`, `rfm_segment_deltas`, `audit_logs`, `simulation_logs`.
- **Query Scoping**: NestJS services enforce `merchant_id` filters (e.g., `SELECT * FROM customers WHERE merchant_id = :merchantId`).
- **Security**: RLS policies (`CREATE POLICY merchant_isolation ON customers ...`).
- **Monitoring**: Per-tenant query performance via Prometheus (`SELECT merchant_id, AVG(query_duration_ms) FROM audit_logs GROUP BY merchant_id`).

## 5. Security and Compliance
- **Authentication**: Shopify OAuth, RBAC (`merchants.staff_roles` for `admin`, `superadmin`, `analytics` roles).
- **Encryption**: AES-256 for `customers.email`, `customers.phone`, `merchants.api_token`, `reward_redemptions.discount_code`, `customers.rfm_score` via `pgcrypto`.
- **GDPR/CCPA**: 90-day retention (`gdpr_requests.retention_expires_at`), webhooks (`customers/data_request`, `customers/redact`), encrypted backups.
- **Rate Limits**: Shopify API (50 points/s, 100 points/s Plus), Redis caching (`rate_limit:{merchant_id}`), exponential backoff (3 retries, 500ms base delay).
- **Security Testing**: OWASP ZAP for XSS, CSRF, SQL injection on `/points`, `/referrals`, `/admin` endpoints.

### 5.1 Integration Error Handling
- **Shopify Webhooks**:
  - **Retry Logic**: Bull queue with 3 retries (500ms, 1s, 2s delays) for `orders/create`, `orders/cancelled`, `pos/offline_sync`, `customers/redact`.
  - **Dead Letter Queue**: Failed webhooks to `bull:webhook:failed`, logged to Loki, alerted via email/Slack.
  - **Rate Limits**: Monitor via Redis (`shopify:rate_limit:{merchant_id}`), pause at 80% quota.
- **Klaviyo/Postscript**:
  - **Error Handling**: Retry API errors (e.g., 429) with exponential backoff (500ms base, 3 retries).
  - **Fallback**: Queue failed `email_events` in Redis (`bull:notifications:failed`), resend via AWS SES after 1h, log to PostHog (`referral_fallback_triggered`).
- **Square POS**:
  - **Sync Errors**: Queue failed syncs in `bull:square:failed`, retry after 1h, log to PostHog (`square_sync_triggered`).
- **Validation**: `webhook_idempotency_keys` table (TTL: 24h) to prevent duplicate webhook processing.

## 6. Scalability and Performance
- **Horizontal Scaling**: Scale Docker Compose services (`docker-compose scale points=4`), add VPS nodes for high load.
- **Caching**: Redis for hot data (e.g., `points:{customer_id}`, `rfm:burst:{merchant_id}`), Nginx for static assets (cache TTL: 24h).
- **Database**: Partitioning by `merchant_id`, indexes (`idx_customers_rfm_score_at_risk`, `idx_rfm_segment_deltas_customer_id`), `pgbouncer` for 1,000+ connections.
- **Performance Goals**: <1s API response, <2.5s LCP, <100ms FID, <0.1 CLS, 10,000 orders/hour (US-BI1), 50,000+ customers (US-MD4).
- **Load Testing**: k6 for 5,000 concurrent admin requests, 1,000 RFM simulations, 1,000 Square syncs.

## 7. Backup and Recovery
- **Database**: Daily `pg_dump` to `/backups/loyalnest-<date>.dump`, rsync to offsite VPS (`rsync -avz /backups user@backup-vps:/backups`).
- **Cache**: Redis AOF persistence, daily backups to `/backups/redis-<date>.rdb`.
- **Frontend**: Backup assets to `/var/www/loyalnest-backup`.
- **Recovery Time**: <1h for DB restore (`pg_restore`), <10m for Docker redeployment.
- **Schema-Specific Recovery**: Post-restore, run `REFRESH MATERIALIZED VIEW CONCURRENTLY rfm_segment_counts`, re-attach partitions for `points_transactions`, `rfm_segment_deltas`.

### 7.2 Disaster Recovery
- **Failover**: Use secondary VPS in another data center, sync PostgreSQL with `pg_basebackup`, Redis with AOF replication.
- **Failover Process**:
  1. Promote secondary PostgreSQL: `sudo -u postgres pg_ctl promote`.
  2. Update Docker Compose to use secondary DB/Redis: `docker-compose -f /opt/loyalnest/docker-compose.yml up -d`.
  3. Update DNS to point to secondary VPS IP (TTL: 300s).
- **RTO/RPO**: Recovery Time Objective <2h, Recovery Point Objective <15m.
- **Testing**: Quarterly DR drills with Chaos Monkey, validating failover and data integrity.
- **Backup Validation**: Automate snapshot checks (`pg_restore --schema-only /backups/loyalnest-<date>.dump`).

## 8. CI/CD Pipeline
- **GitHub Actions**:
  - **Build**: `nx build`, `docker build` on PRs.
  - **Test**: Jest (`jest --coverage`, 90%+ coverage), Cypress (`cypress run`, 100% critical path), k6, Lighthouse CI, OWASP ZAP.
  - **Deploy**: SSH to VPS, run `docker-compose pull && docker-compose up -d`, `nx run backend:migrate`.
  - **Secrets**: `.env` file on VPS, managed via `dotenv`, stored in GitHub Secrets for CI/CD.
- **Environments**:
  - **Staging** (`staging.loyalnest.com`): 8GB RAM, 4 vCPUs, 50GB SSD, synthetic data (1,000 merchants, 10,000 customers), 4 partitions.
  - **Production** (`api.loyalnest.com`): 16GB RAM, 8 vCPUs, 200GB SSD, real data, 8 partitions.

### 8.2 Testing Scenarios
- **Load Testing (k6)**:
  - **RFM Calculations**: 1,000 merchants querying `rfm_segment_counts` (`SELECT * FROM rfm_segment_counts WHERE merchant_id = :id`), <1s response.
  - **Points Transactions**: 1,000 `points_transactions` inserts/s (`INSERT INTO points_transactions (customer_id, merchant_id, points, type) VALUES (...)`), validate partition performance.
  - **GDPR Redaction**: 100 `customers/redact` webhooks, ensure `gdpr_requests` updates in <5s.
  - **Referral Processing**: 500 referral link clicks (`referrals.type='sms'`), Bull queue processing <200ms.
  - **Square Sync**: 1,000 Square POS transactions (`/admin.v1/SyncSquarePOS`), <1s per sync.
- **Security Testing**: OWASP ZAP for `orders/create`, `customers/redact`, `admin/replay`, `admin/rfm/simulate`.
- **E2E Testing (Cypress)**: Test Merchant Dashboard (`rfm_score_history`, `analytics_reports`, `audit_logs`, `simulation_logs`), Customer Widget (points redemption, referral status).

### 8.3 Environment Configurations
- **Staging** (`staging.loyalnest.com`):
  - VPS: 8GB RAM, 4 vCPUs, 50GB SSD.
  - Docker: 1 instance per service, scale to 2 at high load.
  - Data: Synthetic, no PII.
  - Partitions: 4 for `points_transactions`, `rfm_segment_deltas`, etc.
- **Production** (`api.loyalnest.com`):
  - VPS: 16GB RAM, 8 vCPUs, 200GB SSD.
  - Docker: 2 instances per service, scale to 4 at high load.
  - Data: Real, AES-256 encrypted.
  - Partitions: 8 for `points_transactions`, `rfm_segment_deltas`, etc.
- **Configuration Management**: `.env.staging`, `.env.prod` for environment-specific settings (e.g., `DATABASE_URL`, `REDIS_URL`).

## 9. Maintenance
- **Patching**: Weekly `sudo apt update && sudo apt upgrade`, Docker image updates (`docker-compose pull`).
- **Monitoring**: Daily Grafana checks, PostHog for usage trends, Sentry for errors, Loki for logs.
- **Scaling Adjustments**: Monitor Prometheus metrics, scale services (`docker-compose scale points=4`) as needed.
- **Cost Optimization**: Monitor VPS resource usage with `htop`, optimize PostgreSQL queries with `EXPLAIN ANALYZE`.

### 9.2 Cost Optimization
- **VPS Costs**: ~$50/month for staging (8GB RAM), ~$100/month for production (16GB RAM), ~$20/month for backup VPS.
- **Redis/PostgreSQL**: Tune memory usage (`maxmemory 2GB` for Redis, `work_mem 8MB` for PostgreSQL).
- **Cron Jobs**: Schedule `rfm_segment_counts` refresh at 2 AM UTC to avoid peak load.
- **Total Estimate**: ~$150–$200/month for 5,000 merchants, 50,000 customers.

## 10. Risks and Mitigation
- **Risk**: VPS resource limits.
  - **Mitigation**: Monitor with Prometheus/Grafana, scale services or add VPS nodes, use k6 for 5,000 concurrent requests.
- **Risk**: Database performance for 50,000+ customers.
  - **Mitigation**: Partitioning, indexes (`idx_customers_rfm_score_at_risk`, `idx_rfm_segment_deltas_customer_id`), `pgbouncer`, k6 load tests.
- **Risk**: Downtime during deployment.
  - **Mitigation**: Blue-green deployment with Docker Compose, Nginx cache for assets.
- **Risk**: GDPR non-compliance.
  - **Mitigation**: 90-day retention, encrypted backups, OWASP ZAP for webhook security.

## 11. Deliverables
- Docker Compose configuration (`/opt/loyalnest/docker-compose.yml`).
- Dockerfiles (`/apps/<service>/Dockerfile`).
- Nginx configuration (`/etc/nginx/sites-available/loyalnest`).
- PostgreSQL initialization (`/opt/loyalnest/db/init.sql`).
- GitHub Actions workflows (`/workflows/ci.yml`, `deploy.yml`).
- Monitoring setup (Prometheus, Grafana, Loki dashboards).
- Backup scripts (`/opt/loyalnest/backup.sh` for `pg_dump`, `rsync`).