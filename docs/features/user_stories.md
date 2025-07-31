# LoyalNest App User Stories

## Merchant Dashboard (Phases 1–3, 6)

### Phase 1: Core Management

**US-MD1: Complete Setup Tasks**  
As a merchant, I want to complete setup tasks on the Welcome Page, so that I can launch my loyalty program.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display tasks (e.g., "Launch Program", "Add Widget") from `program_settings` in Polaris `Checklist`.  
- Allow checking tasks via `POST /v1/api/settings/setup`, enforce RBAC (`admin:setup`).  
- Save progress to `program_settings.setup_progress` (JSONB).  
- Show congratulatory Polaris `Banner` on completion, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`setup:{merchant_id}`), handle 1,000 merchants/hour with PostgreSQL partitioning.  
- Log to PostHog (`setup_completed`, 80%+ completion).  
- **Accessibility**: ARIA label (`aria-label="Complete setup task"`), keyboard-navigable, WCAG 2.1 AA.  
- **Testing**: Jest (`SetupPage.tsx`), Cypress E2E, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Updates setup progress for a merchant.  
  - **Query**:  
    ```graphql
    mutation UpdateSetupProgress($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "setup_progress",
        "value": "{\"tasks\": {\"launch_program\": true, \"add_widget\": true}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant completes tasks, updates `program_settings.setup_progress`, caches in Redis Streams, and tracks via PostHog (`setup_completed`).

**US-MD2: Configure Points Program**  
As a merchant, I want to configure earning and redemption rules, so that I can customize the loyalty program.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form for earning (e.g., "10 points/$") and redemptions (e.g., "$5 off: 500 points") in Polaris `Form`.  
- Save to `program_settings.config` (JSONB) via `PUT /v1/api/points-program`, enforce RBAC (`admin:points`).  
- Preview rewards panel branding in real-time.  
- Toggle program status, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`points_config:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`points_configured`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Configure points"`), WCAG 2.1 AA.  
- **Testing**: Jest (`PointsPage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures points earning and redemption rules.  
  - **Query**:  
    ```graphql
    mutation ConfigurePointsProgram($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "points_config",
        "value": "{\"earning\": {\"points_per_dollar\": 10}, \"redemption\": {\"discount\": {\"amount\": 5, \"points\": 500}}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant configures points rules, updates `program_settings.config`, caches in Redis Streams, and tracks via PostHog (`points_configured`).

**US-MD3: Manage Referrals Program**  
As a merchant, I want to configure the referrals program, so that I can incentivize customer referrals.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form for SMS/email/WhatsApp config (Klaviyo/Postscript) and rewards in Polaris `Form`.  
- Save to `program_settings.config` (JSONB) via `PUT /v1/api/referrals/config`, enforce RBAC (`admin:referrals`).  
- Preview referral popup, toggle status, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`referrals_config:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`referrals_configured`, 7%+ SMS conversion).  
- **Accessibility**: ARIA label (`aria-label="Configure referrals"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`ReferralsPage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures referral program settings.  
  - **Query**:  
    ```graphql
    mutation ConfigureReferrals($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "referrals_config",
        "value": "{\"channels\": [\"sms\", \"email\"], \"reward\": {\"points\": 200}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant sets referral rewards, updates `program_settings.config`, caches in Redis Streams, and tracks via PostHog (`referrals_configured`).

**US-MD4: View Customer List**  
As a merchant, I want to view and search my customer list, so that I can manage customer data.  
**Service**: Users Service (gRPC: `/users.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display list from `users` (name, email, points, RFM) via `GET /v1/api/users`, enforce RBAC (`admin:users`), in Polaris `DataTable`.  
- Search by name/email, show details on click.  
- Handle empty list with Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`users:{merchant_id}`), handle 5,000 customers with PostgreSQL partitioning.  
- Log to PostHog (`user_list_viewed`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Search customers"`), screen reader support, WCAG 2.1 AA.  
- **Testing**: Jest (`UsersPage.tsx`), Cypress, k6 (5,000 customers).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves customer list with points and RFM data.  
  - **Query**:  
    ```graphql
    query GetCustomers($first: Int, $query: String) {
      customers(first: $first, query: $query) {
        edges {
          node {
            id
            displayName
            email
            metafield(namespace: "loyalnest", key: "points_balance") {
              value
            }
            metafield(namespace: "loyalnest", key: "rfm_score") {
              value
            }
          }
        }
      }
    }
    ```
  - **Variables**: `{ "first": 50, "query": "email:*@example.com" }`  
  - **Use Case**: Merchant views `users` data in Polaris `DataTable`, cached in Redis Streams, and tracks via PostHog (`user_list_viewed`).

**US-MD5: View Basic Analytics**  
As a merchant, I want to view basic analytics (e.g., members, points issued), so that I can monitor program performance.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display metrics from `users`, `points_transactions` via `GET /v1/api/analytics`, enforce RBAC (`admin:analytics`), in Polaris `Card`.  
- Show Chart.js bar chart for RFM segments (`rfm_score_history`), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Handle API errors with fallback Polaris `Banner`.  
- Cache in Redis Streams (`analytics:{merchant_id}`), handle 5,000 merchants with Kubernetes sharding.  
- Log to PostHog (`analytics_viewed`, 85%+ view rate).  
- **Accessibility**: ARIA label (`aria-live="Analytics data available"`), WCAG 2.1 AA.  
- **Testing**: Jest (`AnalyticsPage.tsx`), Cypress, k6 (5,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Fetches basic analytics for RFM segments.  
  - **Query**:  
    ```graphql
    query GetAnalytics($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "rfm_analytics") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Merchant views RFM segment counts from `rfm_score_history`, visualized with Chart.js, cached in Redis Streams, and tracks via PostHog (`analytics_viewed`).

**US-MD6: Configure Store Settings**  
As a merchant, I want to configure store details and billing, so that I can manage my account.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form for store name, billing plan (Free: 300 orders, $29/mo: 500 orders) in Polaris `Form`.  
- Save to `merchants` (`plan_id`) via `PUT /v1/api/settings`, enforce RBAC (`admin:settings`).  
- Validate inputs, show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`settings:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`settings_updated`, 80%+ success).  
- **Accessibility**: ARIA label (`aria-label="Configure store settings"`), WCAG 2.1 AA.  
- **Testing**: Jest (`SettingsPage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Updates store settings and billing plan.  
  - **Query**:  
    ```graphql
    mutation UpdateStoreSettings($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "store_settings",
        "value": "{\"store_name\": \"My Store\", \"plan_id\": \"premium_500\"}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant updates `merchants.plan_id`, caches in Redis Streams, and tracks via PostHog (`settings_updated`).

**US-MD7: Customize On-Site Content**  
As a merchant, I want to customize loyalty page and popups, so that I can align with my brand.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display editor for loyalty page, rewards panel, launcher button in Polaris `Form`.  
- Save to `program_settings.branding` (JSONB) via `PUT /v1/api/content`, enforce RBAC (`admin:frontend`).  
- Preview in real-time, support post-purchase popup, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`content:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`content_updated`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Customize content"`), WCAG 2.1 AA.  
- **Testing**: Jest (`ContentPage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Customizes loyalty page branding.  
  - **Query**:  
    ```graphql
    mutation CustomizeContent($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "branding",
        "value": "{\"loyalty_page\": {\"color\": \"#4CAF50\", \"logo\": \"logo.png\"}, \"popup\": {\"text\": \"Join Now\"}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant customizes `program_settings.branding`, caches in Redis Streams, and tracks via PostHog (`content_updated`).

### Phase 2: Enhanced Management

**US-MD8: Configure VIP Tiers**  
As a merchant, I want to set up VIP tiers based on spending, so that I can reward loyal customers.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form for tiers (e.g., "Gold: $500") and perks in Polaris `Form`.  
- Save to `vip_tiers` via `POST /v1/api/vip-tiers`, enforce RBAC (`admin:points`).  
- Preview tier structure, notify customers via `email_templates`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`tiers:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`vip_tiers_configured`, 60%+ engagement).  
- **Accessibility**: ARIA label (`aria-label="Configure VIP tiers"`), RTL support (`ar`, `he`, Phase 6).  
- **Testing**: Jest (`VIPTiersPage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures VIP tier settings.  
  - **Query**:  
    ```graphql
    mutation ConfigureVIPTiers($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "vip_tiers",
        "value": "{\"tiers\": [{\"name\": \"Gold\", \"spend\": 500, \"perks\": [\"free_shipping\"]}]}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant sets VIP tiers, updates `vip_tiers`, notifies via Klaviyo/Postscript, and tracks via PostHog (`vip_tiers_configured`).

**US-MD9: View Activity Logs**  
As a merchant, I want to view activity logs for points and referrals, so that I can track customer actions.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display logs from `points_transactions`, `referrals` via `GET /v1/api/logs`, enforce RBAC (`admin:logs`), in Polaris `DataTable`.  
- Filter by customer/date, show details (e.g., "John +200 points"), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Handle empty logs with Polaris `Banner`.  
- Cache in Redis Streams (`logs:{merchant_id}`), handle 5,000 logs with PostgreSQL partitioning.  
- Log to PostHog (`logs_viewed`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Filter logs"`), screen reader support, WCAG 2.1 AA.  
- **Testing**: Jest (`LogsPage.tsx`), Cypress, k6 (5,000 logs).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves activity logs for points and referrals.  
  - **Query**:  
    ```graphql
    query GetActivityLogs($first: Int, $query: String) {
      customers(first: $first, query: $query) {
        edges {
          node {
            id
            metafield(namespace: "loyalnest", key: "activity_log") {
              value
            }
          }
        }
      }
    }
    ```
  - **Variables**: `{ "first": 50, "query": "tag:points_activity" }`  
  - **Use Case**: Merchant views `points_transactions` and `referrals` logs, cached in Redis Streams, and tracks via PostHog (`logs_viewed`).

**US-MD10: Configure RFM Settings**  
As a merchant, I want to configure RFM thresholds, so that I can segment customers effectively.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display wizard for recency, frequency, monetary settings in Polaris `Form`.  
- Save to `rfm_benchmarks` (JSONB) via `PUT /v1/api/rfm/config`, enforce RBAC (`admin:analytics`).  
- Preview segment chart (Chart.js), validate thresholds, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`rfm_benchmarks:{merchant_id}`), handle 5,000 merchants/hour.  
- Log to PostHog (`rfm_configured`, 85%+ completion).  
- **Accessibility**: ARIA label (`aria-label="Configure RFM"`), WCAG 2.1 AA.  
- **Testing**: Jest (`RFMPage.tsx`), Cypress, k6 (5,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures RFM thresholds.  
  - **Query**:  
    ```graphql
    mutation ConfigureRFM($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "rfm_benchmarks",
        "value": "{\"industry\": \"Retail\", \"segment_name\": \"Champions\", \"thresholds\": {\"recency\": \"<=30\", \"frequency\": \">=5\", \"monetary\": \">500\"}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant configures `rfm_benchmarks`, visualizes with Chart.js, caches in Redis Streams, and tracks via PostHog (`rfm_configured`).

**US-MD11: Manage Checkout Extensions**  
As a merchant, I want to enable points display at checkout, so that customers can see their balance during purchase.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Toggle checkout extensions in Polaris `Form`, save to `program_settings.config` via `PUT /v1/api/content`, enforce RBAC (`admin:frontend`).  
- Preview points display, integrate with Shopify Checkout UI Extensions, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`content:{merchant_id}`), handle 5,000 checkouts/hour.  
- Log to PostHog (`checkout_extension_enabled`, 85%+ adoption).  
- **Accessibility**: ARIA label (`aria-label="Toggle checkout extensions"`), WCAG 2.1 AA.  
- **Testing**: Jest (`CheckoutPage.tsx`), Cypress, k6 (5,000 checkouts).  
- **GraphQL Query Example**:  
  - **Purpose**: Enables checkout points display.  
  - **Query**:  
    ```graphql
    mutation EnableCheckoutExtension($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "checkout_config",
        "value": "{\"points_display\": true}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant enables checkout extensions, updates `program_settings.config`, caches in Redis Streams, and tracks via PostHog (`checkout_extension_enabled`).

### Phase 3: Advanced Features

**US-MD12: Create Bonus Campaigns**  
As a merchant, I want to create time-sensitive bonus campaigns, so that I can boost engagement.  
**Service**: Campaign Service (gRPC: `/campaign.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form for campaign type (e.g., double points), dates, multiplier in Polaris `Form`.  
- Save to `bonus_campaigns` via `POST /v1/api/campaigns`, enforce RBAC (`admin:campaigns`).  
- Schedule start/end, show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)).  
- Cache in Redis Streams (`campaign:{merchant_id}`), handle 5,000 campaigns/hour.  
- Log to PostHog (`campaign_created`, 15%+ redemption).  
- **Accessibility**: ARIA label (`aria-label="Create campaign"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`CampaignsPage.tsx`), Cypress, k6 (5,000 campaigns).  
- **GraphQL Query Example**:  
  - **Purpose**: Creates a bonus campaign.  
  - **Query**:  
    ```graphql
    mutation CreateCampaign($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "bonus_campaign",
        "value": "{\"type\": \"double_points\", \"start_date\": \"2025-08-01\", \"end_date\": \"2025-08-07\", \"multiplier\": 2}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant creates campaign in `bonus_campaigns`, caches in Redis Streams, and tracks via PostHog (`campaign_created`).

**US-MD13: Export Advanced Reports**  
As a merchant, I want to export advanced analytics reports, so that I can analyze program performance.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Provide export button for RFM/revenue data via `GET /v1/api/analytics/export`, enforce RBAC (`admin:analytics`), in Polaris `Button`.  
- Download CSV from `rfm_score_history`, `points_transactions`, show progress in Polaris `ProgressBar`, localized via i18next (Phase 3 languages).  
- Cache in Redis Streams (`analytics_export:{merchant_id}`), handle 5,000 exports/hour.  
- Log to PostHog (`report_exported`, 85%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Export report"`), screen reader support, WCAG 2.1 AA.  
- **Testing**: Jest (`ReportsPage.tsx`), Cypress, k6 (5,000 exports).  
- **GraphQL Query Example**:  
  - **Purpose**: Exports RFM analytics report.  
  - **Query**:  
    ```graphql
    query ExportAnalytics($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "rfm_analytics") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Merchant exports `rfm_score_history` data, cached in Redis Streams, and tracks via PostHog (`report_exported`).

**US-MD14: Configure Sticky Bar**  
As a merchant, I want to enable a sticky bar for rewards, so that I can promote the loyalty program.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display editor for sticky bar content in Polaris `Form`.  
- Save to `program_settings.branding` via `PUT /v1/api/content`, enforce RBAC (`admin:frontend`).  
- Preview in real-time, localized via i18next (Phase 3 languages).  
- Cache in Redis Streams (`content:{merchant_id}`), handle 5,000 merchants/hour.  
- Log to PostHog (`sticky_bar_configured`, 10%+ click-through).  
- **Accessibility**: ARIA label (`aria-label="Configure sticky bar"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`StickyBarPage.tsx`), Cypress, k6 (5,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures sticky bar content.  
  - **Query**:  
    ```graphql
    mutation ConfigureStickyBar($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "sticky_bar",
        "value": "{\"text\": \"Join our loyalty program!\", \"color\": \"#4CAF50\"}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant customizes `program_settings.branding`, caches in Redis Streams, and tracks via PostHog (`sticky_bar_configured`).

**US-MD15: Use Developer Toolkit**  
As a merchant, I want to configure metafields via a developer toolkit, so that I can customize integrations.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form for metafield settings in Polaris `Form`.  
- Save to `integrations.settings` (JSONB) via `PUT /v1/api/settings/developer`, enforce RBAC (`admin:settings`).  
- Validate inputs, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`integrations:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`metafields_configured`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Configure metafields"`), WCAG 2.1 AA.  
- **Testing**: Jest (`DeveloperPage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures integration metafields.  
  - **Query**:  
    ```graphql
    mutation ConfigureMetafields($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "integration_settings",
        "value": "{\"klaviyo\": {\"enabled\": true, \"api_key\": \"xyz\"}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant configures `integrations.settings`, caches in Redis Streams, and tracks via PostHog (`metafields_configured`).

**US-MD19: Automate Lifecycle Rewards**  
As a merchant, I want to automatically send rewards or campaigns when a customer’s RFM score drops or tier changes, so that I can re-engage them before they churn.  
**Service**: Campaign Service (gRPC: `/campaign.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display automation form for RFM/tier triggers in Polaris `Form`.  
- Save to `bonus_campaigns` (JSONB) via `PUT /v1/api/campaigns/lifecycle`, enforce RBAC (`admin:campaigns`).  
- Trigger via Shopify Flow, localized via i18next (Phase 3 languages).  
- Cache in Redis Streams (`campaign:{merchant_id}`), handle 5,000 triggers/hour.  
- Log to PostHog (`lifecycle_campaign_triggered`, 15%+ redemption).  
- **Accessibility**: ARIA label (`aria-label="Configure lifecycle automation"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`LifecyclePage.tsx`), Cypress, k6 (5,000 triggers).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures lifecycle reward automation.  
  - **Query**:  
    ```graphql
    mutation ConfigureLifecycleCampaign($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "lifecycle_campaign",
        "value": "{\"trigger\": \"rfm_drop\", \"reward\": {\"points\": 100}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant sets lifecycle triggers in `bonus_campaigns`, integrates with Shopify Flow, and tracks via PostHog (`lifecycle_campaign_triggered`).

**US-MD20: View Segment Benchmarking**  
As a merchant, I want to see how my loyalty segments compare with similar businesses, so that I can evaluate performance.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display comparison from `rfm_score_history`, `rfm_benchmarks` via `GET /v1/api/rfm/benchmarks`, enforce RBAC (`admin:analytics`), in Chart.js bar chart.  
- Ensure GDPR-compliant anonymized data, localized via i18next (Phase 3 languages).  
- Cache in Redis Streams (`rfm_benchmarks:{merchant_id}`), handle 5,000 views/hour.  
- Log to PostHog (`benchmarks_viewed`, 85%+ view rate).  
- **Accessibility**: ARIA label (`aria-live="Segment benchmark data available"`), WCAG 2.1 AA.  
- **Testing**: Jest (`BenchmarkingPage.tsx`), Cypress, k6 (5,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Fetches RFM segment benchmarks.  
  - **Query**:  
    ```graphql
    query GetSegmentBenchmarks($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "rfm_benchmarks") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Merchant views `rfm_benchmarks`, visualized with Chart.js, cached in Redis Streams, and tracks via PostHog (`benchmarks_viewed`).

**US-MD21: A/B Test Nudges**  
As a merchant, I want to test different nudges with different copy or designs, so that I can optimize conversions.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form for A/B test variants in Polaris `Form`.  
- Save to `program_settings.ab_tests` (JSONB) via `PUT /v1/api/nudges/ab-test`, enforce RBAC (`admin:analytics`).  
- Show results in Chart.js, localized via i18next (Phase 3 languages).  
- Cache in Redis Streams (`nudges:{merchant_id}`), handle 5,000 nudges/hour.  
- Log to PostHog (`nudge_ab_tested`, 10%+ click-through).  
- **Accessibility**: ARIA label (`aria-label="Configure nudge A/B test"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`NudgeABTestPage.tsx`), Cypress, k6 (5,000 nudges).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures A/B test for nudges.  
  - **Query**:  
    ```graphql
    mutation ConfigureNudgeABTest($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "ab_tests",
        "value": "{\"nudge\": {\"variant_a\": \"Join Now\", \"variant_b\": \"Get Rewards\"}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant sets A/B test in `program_settings.ab_tests`, visualizes results with Chart.js, and tracks via PostHog (`nudge_ab_tested`).

**US-MD22: Identify Churn Risk Customers**  
As a merchant, I want to see a list of high-spending customers at risk of churning, so that I can take action to win them back.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display At-Risk customers (`rfm_score_history`) via `GET /v1/api/rfm/churn-risk`, enforce RBAC (`admin:analytics`), in Polaris `DataTable`.  
- Support xAI API (Phase 6, https://x.ai/api), GDPR-compliant AES-256 encryption, localized via i18next (Phase 3 languages).  
- Cache in Redis Streams (`rfm:{customer_id}`), handle 5,000 views/hour with Kubernetes sharding.  
- Log to PostHog (`churn_risk_viewed`, 85%+ view rate).  
- **Accessibility**: ARIA label (`aria-label="View churn risk customers"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`ChurnRiskPage.tsx`), Cypress, k6 (5,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves churn risk customers.  
  - **Query**:  
    ```graphql
    query GetChurnRiskCustomers($first: Int, $query: String) {
      customers(first: $first, query: $query) {
        edges {
          node {
            id
            metafield(namespace: "loyalnest", key: "churn_score") {
              value
            }
          }
        }
      }
    }
    ```
  - **Variables**: `{ "first": 50, "query": "tag:at_risk" }`  
  - **Use Case**: Merchant views churn risk from `rfm_score_history`, powered by xAI API, cached in Redis Streams, and tracks via PostHog (`churn_risk_viewed`).

**US-MD23: Customize Notification Templates**  
As a merchant, I want to create and preview notification templates in real-time, so that I can tailor customer communications.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display editor for templates in Polaris `Form` with live preview.  
- Save to `email_templates.body` (JSONB, `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja', 'ru', 'it', 'nl', 'pl', 'tr', 'fa', 'zh-CN', 'vi', 'id', 'cs', 'ar', 'ko', 'uk', 'hu', 'sv', 'he']`) via `POST /v1/api/templates`, enforce RBAC (`admin:templates`).  
- Cache in Redis Streams (`templates:{merchant_id}`), handle 1,000 templates/hour.  
- Log to PostHog (`template_edited`, 80%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Edit notification template"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`NotificationTemplatePage.tsx`), Cypress, k6 (1,000 templates).  
- **GraphQL Query Example**:  
  - **Purpose**: Customizes notification templates.  
  - **Query**:  
    ```graphql
    mutation CustomizeTemplate($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "email_template",
        "value": "{\"en\": \"Welcome to our loyalty program!\", \"es\": \"¡Bienvenido a nuestro programa de lealtad!\"}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant edits `email_templates.body`, caches in Redis Streams, and tracks via PostHog (`template_edited`).

**US-MD24: View Usage Thresholds and Upgrade Nudges**  
As a merchant, I want to see my plan’s usage (e.g., SMS referral limit) with nudges to upgrade, so that I can access more features.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display usage in Polaris `ProgressBar`, nudge via Polaris `Banner` (`GET /v1/api/plan/usage`), enforce RBAC (`admin:settings`).  
- Trigger upgrade CTA for $29/month plan, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`plan:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`plan_limit_warning`, 10%+ conversion).  
- **Accessibility**: ARIA label (`aria-label="View plan usage"`), WCAG 2.1 AA.  
- **Testing**: Jest (`UsagePage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves plan usage data.  
  - **Query**:  
    ```graphql
    query GetPlanUsage($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "plan_usage") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Merchant views `merchants.plan_usage`, receives upgrade nudge, and tracks via PostHog (`plan_limit_warning`).

**US-MD25: Receive Contextual Tips**  
As a merchant, I want to receive contextual tips during onboarding and usage, so that I can optimize my loyalty program.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display 2 tips/day in Polaris `Banner` (e.g., “Enable birthday bonus for 10%+ referral uplift”) via `GET /v1/api/tips`, enforce RBAC (`admin:tips`).  
- Cache in Redis Streams (`tips:{merchant_id}`), handle 5,000 tips/hour.  
- Log to PostHog (`tip_viewed`, 80%+ engagement), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="View contextual tip"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`TipsBanner.tsx`), Cypress, k6 (5,000 tips).  
- **GraphQL Query Example**:  
  - **Purpose**: Fetches contextual tips.  
  - **Query**:  
    ```graphql
    query GetTips($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "contextual_tips") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Merchant views tips, cached in Redis Streams, and tracks via PostHog (`tip_viewed`).

**US-MD26: Manage POS Offline Points**  
As a merchant, I want to award/redeem points via Shopify POS in offline mode, so that I can maintain loyalty during connectivity issues.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Sync points via SQLite queue, `POST /v1/api/points/pos`, enforce RBAC (`admin:points`), reconcile on reconnect.  
- Show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`points:{customer_id}`), handle 1,000 transactions/hour.  
- Log to PostHog (`pos_offline_used`, 90%+ sync success).  
- **Accessibility**: ARIA label (`aria-label="Manage POS points"`), WCAG 2.1 AA.  
- **Testing**: Jest (`POSPage.tsx`), Cypress, k6 (1,000 POS transactions).  
- **GraphQL Query Example**:  
  - **Purpose**: Syncs offline POS points.  
  - **Query**:  
    ```graphql
    mutation SyncPOSPoints($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "points_balance",
            "value": "500",
            "type": "number_integer"
          }
        ]
      }
    }
    ```
  - **Use Case**: Merchant syncs `points_transactions` offline, updates `users.points_balance`, and tracks via PostHog (`pos_offline_used`).

**US-MD27: Monitor Rate Limits**  
As a merchant, I want to view and receive alerts for Shopify API rate limit usage, so that I can avoid disruptions.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display usage in Polaris `DataTable`, AWS SNS alerts at 80% limit via `GET /v1/api/rate-limits`, enforce RBAC (`admin:settings`).  
- Cache in Redis Streams (`rate_limits:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`rate_limit_viewed`, 90%+ alert delivery), localized via i18next (Phase 3 languages).  
- **Accessibility**: ARIA label (`aria-label="View rate limits"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`RateLimitPage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves API rate limit usage.  
  - **Query**:  
    ```graphql
    query GetRateLimits($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "rate_limits") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Merchant views rate limit usage, receives SNS alerts, and tracks via PostHog (`rate_limit_viewed`).

**US-MD28: Invite Merchants via Referral Program**  
As a merchant, I want to invite other merchants and earn credits, so that I can reduce costs.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Generate referral link via `POST /v1/api/referrals/merchant`, enforce RBAC (`admin:referrals`), share via email/SMS.  
- Award $50 credit on signup, log to PostHog (`merchant_referral_created`, 10%+ conversion), localized via i18next (Phase 3 languages).  
- Cache in Redis Streams (`merchant_referral:{merchant_id}`), handle 1,000 referrals/hour.  
- **Accessibility**: ARIA label (`aria-label="Share merchant referral"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`MerchantReferralPage.tsx`), Cypress, k6 (1,000 referrals).  
- **GraphQL Query Example**:  
  - **Purpose**: Creates a merchant referral link.  
  - **Query**:  
    ```graphql
    mutation CreateMerchantReferral($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "merchant_referral",
        "value": "{\"referral_code\": \"MER123\", \"status\": \"pending\"}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant creates referral link in `merchant_referrals`, caches in Redis Streams, and tracks via PostHog (`merchant_referral_created`).

**US-MD29: Integrate Non-Shopify POS**  
As a merchant, I want to award/redeem points via Square or Lightspeed, so that I can support in-store loyalty.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Integrate via Square/Lightspeed APIs, `POST /v1/api/points/non-shopify`, enforce RBAC (`admin:points`).  
- Show confirmation in Polaris `Banner`, log to PostHog (`non_shopify_pos_used`, 90%+ sync success), localized via i18next (Phase 3 languages).  
- Cache in Redis Streams (`points:{customer_id}`), handle 1,000 transactions/hour.  
- **Accessibility**: ARIA label (`aria-label="Manage non-Shopify POS"`), WCAG 2.1 AA.  
- **Testing**: Jest (`NonShopifyPOSPage.tsx`), Cypress, k6 (1,000 transactions).  
- **GraphQL Query Example**:  
  - **Purpose**: Syncs non-Shopify POS points.  
  - **Query**:  
    ```graphql
    mutation SyncNonShopifyPoints($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "points_balance",
            "value": "300",
            "type": "number_integer"
          }
        ]
      }
    }
    ```
  - **Use Case**: Merchant syncs points via Square/Lightspeed, updates `users.points_balance`, and tracks via PostHog (`non_shopify_pos_used`).

**US-MD30: Complete 3-Step Onboarding**  
As a merchant, I want a guided 3-step onboarding flow, so that I can quickly set up RFM, referrals, and checkout extensions.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display Polaris `Checklist` for RFM wizard, referral config, checkout extensions via `POST /v1/api/setup`, enforce RBAC (`admin:setup`).  
- Cache in Redis Streams (`setup:{merchant_id}`), handle 1,000 merchants/hour.  
- Log to PostHog (`onboarding_completed`, 80%+ completion), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Complete onboarding step"`), WCAG 2.1 AA.  
- **Testing**: Jest (`OnboardingPage.tsx`), Cypress, k6 (1,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Updates onboarding progress.  
  - **Query**:  
    ```graphql
    mutation UpdateOnboarding($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "onboarding_progress",
        "value": "{\"steps\": {\"rfm\": true, \"referrals\": true, \"checkout\": true}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant completes onboarding, updates `program_settings.setup_progress`, caches in Redis Streams, and tracks via PostHog (`onboarding_completed`).

### Phase 6: Premium Features

**US-MD31: Configure Advanced RFM Analytics**  
As a merchant, I want to configure advanced RFM analytics with predictive churn models, so that I can target high-value customers.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display Polaris `Form` wizard for dynamic RFM thresholds and industry benchmarks.  
- Save to `rfm_benchmarks` via `PUT /v1/api/rfm/thresholds`, enforce RBAC (`admin:analytics`).  
- Visualize churn predictions with Chart.js (line for trends, bar for segments), integrate xAI API (https://x.ai/api).  
- Cache in Redis Streams (`rfm:{customer_id}`), handle 100,000 customers with Kubernetes sharding.  
- Log to PostHog (`rfm_advanced_configured`, 85%+ adoption), localized via i18next (Phase 6 languages).  
- **Accessibility**: ARIA label (`aria-label="Configure advanced RFM"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`AdvancedRFMPage.tsx`), Cypress, k6 (100,000 customers).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures advanced RFM thresholds.  
  - **Query**:  
    ```graphql
    mutation UpdateAdvancedRFM($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "rfm_benchmarks",
        "value": "{\"industry\": \"Pet Store\", \"segment_name\": \"Champions\", \"thresholds\": {\"recency\": \"<=14\", \"frequency\": \">=5\", \"monetary\": \">500\"}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant configures `rfm_benchmarks`, visualizes with Chart.js, caches in Redis Streams, and tracks via PostHog (`rfm_advanced_configured`).

**US-MD32: Manage Multi-Store Sync**  
As a merchant, I want to sync loyalty points and tiers across multiple Shopify stores, so that customers have a unified experience.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form to enable multi-store sync in Polaris `Form`.  
- Save to `program_settings.multi_store_config` via `POST /v1/api/points/sync`, enforce RBAC (`admin:points`).  
- Notify customers via Klaviyo/Postscript, localized via i18next (Phase 6 languages).  
- Cache in Redis Streams (`points:{customer_id}`), handle 100,000 customers with PostgreSQL partitioning.  
- Log to PostHog (`multi_store_sync_enabled`, 15%+ adoption).  
- **Accessibility**: ARIA label (`aria-label="Configure multi-store sync"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`MultiStorePage.tsx`), Cypress, k6 (100,000 customers).  
- **GraphQL Query Example**:  
  - **Purpose**: Syncs points across stores.  
  - **Query**:  
    ```graphql
    mutation SyncPointsAcrossStores($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
          metafield(namespace: "loyalnest", key: "shared_customer_id") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "points_balance",
            "value": "500",
            "type": "number_integer"
          },
          {
            "namespace": "loyalnest",
            "key": "shared_customer_id",
            "value": "SHARED_C123",
            "type": "string"
          }
        ]
      }
    }
    ```
  - **Use Case**: Merchant syncs `users.points_balance` across stores, caches in Redis Streams, and tracks via PostHog (`multi_store_sync_enabled`).

**US-MD33: Manage Merchant Referral Program**  
As a merchant, I want to enhance my referral program with rewards like free subscriptions, so that I can grow the platform.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form to generate referral links and rewards in Polaris `Form`.  
- Save to `merchant_referrals` via `POST /v1/api/merchant-referrals/create`, enforce RBAC (`admin:referrals`).  
- Visualize referral trends with Chart.js, notify via Klaviyo/Postscript, localized via i18next (Phase 6 languages).  
- Cache in Redis Streams (`merchant_referral:{referral_code}`), handle 10,000 merchants/hour.  
- Log to PostHog (`merchant_referral_enhanced`, 5%+ conversion).  
- **Accessibility**: ARIA label (`aria-label="Manage merchant referrals"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`MerchantReferralEnhancedPage.tsx`), Cypress, k6 (10,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Creates enhanced merchant referral.  
  - **Query**:  
    ```graphql
    mutation CreateEnhancedMerchantReferral($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "merchant_referral",
        "value": "{\"referral_code\": \"MER123\", \"reward_id\": \"1_month_free\", \"status\": \"pending\"}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant creates referral in `merchant_referrals`, caches in Redis Streams, and tracks via PostHog (`merchant_referral_enhanced`).

**US-MD34: Configure Advanced Gamification**  
As a merchant, I want to set up dynamic badges and team leaderboards, so that I can boost customer engagement.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display form for badges and leaderboards in Polaris `Form`.  
- Save to `gamification_achievements`, `team_leaderboards` via `POST /v1/api/gamification`, enforce RBAC (`admin:analytics`).  
- Visualize with Chart.js (line for streaks, bar for rankings), notify via Klaviyo/Postscript, localized via i18next (Phase 6 languages).  
- Cache in Redis Streams (`badge:{customer_id}`), handle 100,000 customers/hour.  
- Log to PostHog (`gamification_configured`, 20%+ engagement).  
- **Accessibility**: ARIA label (`aria-label="Configure gamification"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`GamificationPage.tsx`), Cypress, k6 (100,000 customers).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures gamification badges.  
  - **Query**:  
    ```graphql
    mutation ConfigureGamification($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "achievement_streak") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "achievement_streak",
            "value": "{\"streak_count\": 5, \"badge\": {\"en\": \"Seasonal Star\"}}",
            "type": "json"
          }
        ]
      }
    }
    ```
  - **Use Case**: Merchant configures `gamification_achievements`, caches in Redis Streams, and tracks via PostHog (`gamification_configured`).

**US-MD35: Configure Theme App Extensions**  
As a merchant, I want to embed loyalty widgets in Shopify themes, so that I can enhance storefront integration.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display editor for widget placement in Polaris `Form`.  
- Save to `program_settings.theme_extension_config` via `PUT /v1/api/theme-extensions`, enforce RBAC (`admin:frontend`).  
- Preview widgets, ensure <1s render time, localized via i18next (Phase 6 languages).  
- Cache in Redis Streams (`theme:{merchant_id}:{locale}`), handle 100,000 customers/hour with Kubernetes sharding.  
- Log to PostHog (`theme_extension_configured`, 80%+ adoption).  
- **Accessibility**: ARIA label (`aria-label="Configure theme extensions"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`ThemeExtensionPage.tsx`), Cypress, k6 (100,000 customers).  
- **GraphQL Query Example**:  
  - **Purpose**: Configures theme app extensions.  
  - **Query**:  
    ```graphql
    mutation ConfigureThemeExtension($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "theme_extension_config",
        "value": "{\"widget\": \"rewards_panel\", \"placement\": \"cart_page\"}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Merchant configures `program_settings.theme_extension_config`, caches in Redis Streams, and tracks via PostHog (`theme_extension_configured`).

## Customer Widget (Phases 1–3, 6)

### Phase 1: Core Loyalty Features

**US-CW1: View Points Balance**  
As a customer, I want to view my current points balance in the Customer Widget, so that I can track my loyalty rewards.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display balance in Polaris `Badge` via `GET /v1/api/customer/points`, enforce RBAC (`customer:points`).  
- Cache in Redis Streams (`points:customer:{customer_id}`), update within 1s, handle 10,000 customers/hour.  
- Log to PostHog (`points_balance_viewed`, 80%+ engagement), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="View points balance"`), WCAG 2.1 AA.  
- **Testing**: Jest (`PointsBalance.tsx`), Cypress, k6 (10,000 requests), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves customer points balance.  
  - **Query**:  
    ```graphql
    query GetPointsBalance($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "points_balance") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Customer views `users.points_balance`, cached in Redis Streams, and tracks via PostHog (`points_balance_viewed`).

**US-CW2: Earn Points from Purchase**  
As a customer, I want to earn points automatically when I make a purchase, so that I can accumulate rewards.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Trigger `POST /v1/api/points/earn` on Shopify `orders/create` webhook, insert into `points_transactions`, enforce RBAC (`customer:points`).  
- Show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`points:{customer_id}`), handle 10,000 orders/hour with PostgreSQL partitioning.  
- Log to PostHog (`points_earned`, 20%+ redemption rate).  
- **Accessibility**: ARIA label (`aria-label="Points earned notification"`), WCAG 2.1 AA.  
- **Testing**: Jest (`PurchaseConfirmation.tsx`), Cypress, k6 (10,000 orders/hour), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Awards points for a purchase.  
  - **Query**:  
    ```graphql
    mutation EarnPoints($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "points_balance",
            "value": "500",
            "type": "number_integer"
          }
        ]
      }
    }
    ```
  - **Use Case**: Customer earns points via `points_transactions`, updates `users.points_balance`, caches in Redis Streams, and tracks via PostHog (`points_earned`).

**US-CW3: Redeem Points for Discount**  
As a customer, I want to redeem points for a discount, so that I can save money on purchases.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- List rewards from `program_settings.config` via `GET /v1/api/customer/points`, redeem via `POST /v1/api/redeem`, enforce RBAC (`customer:points`).  
- Create Shopify discount code, show in Polaris `Modal`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`points:{customer_id}`), handle 5,000 redemptions/hour.  
- Log to PostHog (`points_redeemed`, 20%+ redemption rate).  
- **Accessibility**: ARIA label (`aria-label="Redeem points"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`RewardsRedemption.tsx`), Cypress, k6 (5,000 redemptions).  
- **GraphQL Query Example**:  
  - **Purpose**: Redeems points for a discount.  
  - **Query**:  
    ```graphql
    mutation RedeemPoints($input: DiscountCodeInput!) {
      discountCodeCreate(input: $input) {
        discountCode {
          id
          code
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "code": "LOYALNEST_5OFF",
        "discountType": "FIXED_AMOUNT",
        "value": 5.0,
        "customerSelection": {
          "customerIds": ["gid://shopify/Customer/987654321"]
        }
      }
    }
    ```
  - **Use Case**: Customer redeems points from `program_settings.config`, creates Shopify discount code, caches in Redis Streams, and tracks via PostHog (`points_redeemed`).

**US-CW4: Share Referral Link**  
As a customer, I want to share a referral link via SMS, email, or social media, so that I can invite friends and earn rewards.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Generate `referral_code` via `POST /v1/api/referrals/create`, enforce RBAC (`customer:referrals`), show in Polaris `Modal`.  
- Queue notification via Bull, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`referrals:{customer_id}`), handle 1,000 shares/hour.  
- Log to PostHog (`referral_created`, 7%+ SMS conversion).  
- **Accessibility**: ARIA label (`aria-label="Send referral invite"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`ReferralPopup.tsx`), Cypress, k6 (1,000 shares).  
- **GraphQL Query Example**:  
  - **Purpose**: Creates a referral link.  
  - **Query**:  
    ```graphql
    mutation CreateReferral($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "referral_code") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "referral_code",
            "value": "REF123",
            "type": "string"
          }
        ]
      }
    }
    ```
  - **Use Case**: Customer generates `referral_code` in `referrals`, queues notification via Bull, caches in Redis Streams, and tracks via PostHog (`referral_created`).

**US-CW5: Earn Referral Reward**  
As a customer, I want to earn points when a friend signs up using my referral link, so that I am rewarded for inviting others.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Trigger `POST /v1/api/referrals/complete`, enforce RBAC (`customer:referrals`), insert into `referrals`, update `points_transactions`.  
- Show confirmation in Polaris `Banner`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`points:{customer_id}`), handle 1,000 completions/hour.  
- Log to PostHog (`referral_completed`, 7%+ conversion).  
- **Accessibility**: ARIA label (`aria-label="Referral reward notification"`), WCAG 2.1 AA.  
- **Testing**: Jest (`ReferralConfirmation.tsx`), Cypress, k6 (1,000 completions).  
- **GraphQL Query Example**:  
  - **Purpose**: Awards points for a completed referral.  
  - **Query**:  
    ```graphql
    mutation AwardReferralPoints($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "points_balance",
            "value": "200",
            "type": "number_integer"
          }
        ]
      }
    }
    ```
  - **Use Case**: Customer earns points via `referrals` and `points_transactions`, caches in Redis Streams, and tracks via PostHog (`referral_completed`).

**US-CW6: Adjust Points for Cancelled Order**  
As a customer, I want my points balance to be adjusted if an order is cancelled, so that my balance reflects accurate purchases.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Trigger `POST /v1/api/webhooks/orders/cancelled`, enforce RBAC (`customer:points`), insert into `points_transactions`.  
- Update balance in Polaris `Badge`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`points:{customer_id}`), handle 10,000 orders/hour.  
- Log to PostHog (`points_adjusted`, 80%+ success).  
- **Accessibility**: ARIA label (`aria-label="Points adjusted notification"`), WCAG 2.1 AA.  
- **Testing**: Jest (`PointsHistory.tsx`), Cypress, k6 (10,000 orders/hour).  
- **GraphQL Query Example**:  
  - **Purpose**: Adjusts points for a cancelled order.  
  - **Query**:  
    ```graphql
    mutation AdjustPoints($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "points_balance",
            "value": "300",
            "type": "number_integer"
          }
        ]
      }
    }
    ```
  - **Use Case**: System adjusts `users.points_balance` via `points_transactions`, caches in Redis Streams, and tracks via PostHog (`points_adjusted`).

**US-CW7: View Referral Status**  
As a customer, I want to view the detailed status of my referrals, so that I can track my rewards.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display status from `referrals` via `GET /v1/api/referrals/status`, enforce RBAC (`customer:referrals`), in Polaris `DataTable`, `ProgressBar`.  
- Cache in Redis Streams (`referrals:{customer_id}`), handle 5,000 views/hour with PostgreSQL partitioning.  
- Log to PostHog (`referral_status_viewed`, 60%+ engagement), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="View referral status"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`ReferralStatus.tsx`), Cypress, k6 (5,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves referral status.  
  - **Query**:  
    ```graphql
    query GetReferralStatus($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "referral_status") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Customer views `referrals` status, cached in Redis Streams, and tracks via PostHog (`referral_status_viewed`).

**US-CW8: Request GDPR Data Access/Deletion**  
As a customer, I want to request access to or deletion of my data via the widget, so that I can exercise my privacy rights.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display GDPR form in Polaris `Modal`, submit via `POST /v1/api/gdpr`, enforce RBAC (`customer:gdpr`).  
- Insert into `gdpr_requests`, notify via Klaviyo/Postscript, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`gdpr:{customer_id}`), handle 1,000 requests/hour with AES-256 encryption.  
- Log to PostHog (`gdpr_request_submitted`, 50%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Submit GDPR request"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`GDPRForm.tsx`), Cypress, k6 (1,000 requests), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Submits a GDPR request.  
  - **Query**:  
    ```graphql
    mutation SubmitGDPRRequest($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "gdpr_request") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "gdpr_request",
            "value": "{\"type\": \"delete\", \"status\": \"pending\"}",
            "type": "json"
          }
        ]
      }
    }
    ```
  - **Use Case**: Customer submits GDPR request to `gdpr_requests`, notifies via Klaviyo/Postscript, caches in Redis Streams, and tracks via PostHog (`gdpr_request_submitted`).

### Phase 2: Enhanced Features

**US-CW9: View VIP Tier Status**  
As a customer, I want to view my VIP tier status and progress, so that I can understand my benefits.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display tier and progress via `GET /v1/api/vip-tiers/status`, enforce RBAC (`customer:points`), in Polaris `Card`.  
- Cache in Redis Streams (`tiers:{customer_id}`), handle 5,000 views/hour with PostgreSQL partitioning.  
- Log to PostHog (`vip_tier_viewed`, 60%+ engagement), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="View VIP perks"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`VIPTier.tsx`), Cypress, k6 (5,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves VIP tier status.  
  - **Query**:  
    ```graphql
    query GetVIPTierStatus($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "vip_tier") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Customer views `vip_tiers` status, cached in Redis Streams, and tracks via PostHog (`vip_tier_viewed`).

**US-CW10: Receive RFM Nudges**  
As a customer, I want to receive personalized nudges encouraging engagement, so that I remain active in the loyalty program.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display nudge from `nudges` via `GET /v1/api/nudges`, enforce RBAC (`customer:analytics`), in Polaris `Banner`/`Modal`.  
- Log interactions to `nudge_events`, PostHog (`nudge_dismissed`, 10%+ click-through), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`nudges:{customer_id}`), handle 5,000 nudges/hour.  
- **Accessibility**: ARIA label (`aria-label="Dismiss nudge"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`NudgeBanner.tsx`), Cypress, k6 (5,000 nudges).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves personalized nudges.  
  - **Query**:  
    ```graphql
    query GetNudges($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "nudge") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Customer views nudges from `nudges`, logs to `nudge_events`, caches in Redis Streams, and tracks via PostHog (`nudge_dismissed`).

**US-CW11: Earn Gamification Badges**  
As a customer, I want to earn badges for actions, so that I feel motivated to engage.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Trigger `POST /v1/api/gamification/action`, enforce RBAC (`customer:analytics`), insert into `gamification_achievements`.  
- Display badge in Polaris `Card`, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)).  
- Cache in Redis Streams (`badge:{customer_id}`), handle 5,000 actions/hour.  
- Log to PostHog (`badge_earned`, 20%+ engagement).  
- **Accessibility**: ARIA label (`aria-label="View badges"`), WCAG 2.1 AA.  
- **Testing**: Jest (`BadgesSection.tsx`), Cypress, k6 (5,000 actions).  
- **GraphQL Query Example**:  
  - **Purpose**: Awards a gamification badge.  
  - **Query**:  
    ```graphql
    mutation AwardBadge($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "badges") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "badges",
            "value": "{\"badge\": \"Loyal Customer\"}",
            "type": "json"
          }
        ]
      }
    }
    ```
  - **Use Case**: Customer earns badge in `gamification_achievements`, caches in Redis Streams, and tracks via PostHog (`badge_earned`).

**US-CW12: View Leaderboard Rank**  
As a customer, I want to view my rank on a leaderboard, so that I can compete with others.  
**Service**: Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display rank from Redis sorted set via `GET /v1/api/gamification/leaderboard`, enforce RBAC (`customer:analytics`), in Polaris `Card`.  
- Cache in Redis Streams (`leaderboard:{customer_id}`), handle 5,000 views/hour.  
- Log to PostHog (`leaderboard_viewed`, 15%+ engagement), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="View leaderboard"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`Leaderboard.tsx`), Cypress, k6 (5,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves leaderboard rank.  
  - **Query**:  
    ```graphql
    query GetLeaderboardRank($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "leaderboard_rank") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Customer views rank in `team_leaderboards`, cached in Redis Streams, and tracks via PostHog (`leaderboard_viewed`).

**US-CW13: Select Language**  
As a customer, I want to select my preferred language in the widget, so that I can interact in my native language.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display dropdown from `merchants.language` (JSONB, `en`, `es`, `fr`, `de`, `pt`, `ja` in Phases 2–5; full Phase 6 languages) via `GET /v1/api/widget/config`, enforce RBAC (`customer:frontend`).  
- Persist in `localStorage`, log to PostHog (`language_selected`, 10%+ usage), localized via i18next.  
- Cache in Redis Streams (`language:{customer_id}`), handle 5,000 selections/hour.  
- **Accessibility**: ARIA label (`aria-label="Select language"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`LanguageSelector.tsx`), Cypress, Lighthouse CI.  
- **GraphQL Query Example**:  
  - **Purpose**: Sets customer language preference.  
  - **Query**:  
    ```graphql
    mutation SetLanguage($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "language") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "language",
            "value": "es",
            "type": "string"
          }
        ]
      }
    }
    ```
  - **Use Case**: Customer selects language, updates `merchants.language`, caches in Redis Streams, and tracks via PostHog (`language_selected`).

**US-CW14: Interact with Sticky Bar**  
As a customer, I want to view and interact with a sticky bar promoting the loyalty program, so that I can join or redeem rewards.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display sticky bar from `program_settings.sticky_bar` via `GET /v1/api/widget/config`, enforce RBAC (`customer:frontend`), in Polaris `Banner`.  
- Log clicks to PostHog (`sticky_bar_clicked`, 10%+ click-through), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`sticky_bar:{customer_id}`), handle 5,000 views/hour.  
- **Accessibility**: ARIA label (`aria-label="Join loyalty program"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`StickyBar.tsx`), Cypress, k6 (5,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves sticky bar configuration.  
  - **Query**:  
    ```graphql
    query GetStickyBarConfig($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "sticky_bar") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Customer interacts with `program_settings.sticky_bar`, caches in Redis Streams, and tracks via PostHog (`sticky_bar_clicked`).

**US-CW15: View Post-Purchase Widget**  
As a customer, I want to view my points earned post-purchase with a referral CTA, so that I can engage further.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display points and CTA via `GET /v1/api/points/earn`, enforce RBAC (`customer:points`), in Polaris `Card`.  
- Log clicks to PostHog (`post_purchase_viewed`, 15%+ click-through), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`points:{customer_id}`), handle 5,000 views/hour.  
- **Accessibility**: ARIA label (`aria-label="View points earned"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`PostPurchaseWidget.tsx`), Cypress, k6 (5,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves post-purchase points data.  
  - **Query**:  
    ```graphql
    query GetPostPurchasePoints($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "points_earned") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Customer views points earned in `points_transactions`, caches in Redis Streams, and tracks via PostHog (`post_purchase_viewed`).

**US-CW16: View Progressive Tier Engagement**  
As a customer, I want to see actions needed to reach the next VIP tier, so that I stay motivated.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display progress and actions via `GET /v1/api/vip-tiers/progress`, enforce RBAC (`customer:points`), in Polaris `Card`, `ProgressBar`.  
- Cache in Redis Streams (`tiers:{customer_id}`), handle 5,000 views/hour.  
- Log to PostHog (`tier_progress_viewed`, 60%+ engagement), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="View tier progress"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`TierProgress.tsx`), Cypress, k6 (5,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves VIP tier progress.  
  - **Query**:  
    ```graphql
    query GetTierProgress($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "tier_progress") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Customer views progress in `vip_tiers`, caches in Redis Streams, and tracks via PostHog (`tier_progress_viewed`).

**US-CW17: Save Loyalty Balance to Mobile Wallet**  
As a customer, I want to save my loyalty balance to my Apple/Google Wallet, so that I can check rewards on the go.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Generate pass via `GET /v1/api/wallet/pass`, enforce RBAC (`customer:points`), store in `wallet_passes` (AES-256).  
- Log to PostHog (`wallet_pass_added`, 10%+ click-through), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, Phase 6 languages).  
- Cache in Redis Streams (`wallet:{customer_id}`), handle 5,000 requests/hour with Kubernetes sharding.  
- **Accessibility**: ARIA label (`aria-label="Add to wallet"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`WalletIntegration.tsx`), Cypress, k6 (5,000 requests).  
- **GraphQL Query Example**:  
  - **Purpose**: Generates a wallet pass.  
  - **Query**:  
    ```graphql
    query GetWalletPass($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "wallet_pass") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Customer adds `users.points_balance` to `wallet_passes`, caches in Redis Streams, and tracks via PostHog (`wallet_pass_added`).

### Phase 6: Premium Features

**US-CW18: Join Slack Community**  
As a customer, I want to join a merchant’s Slack community via the widget, so that I can engage with other loyal customers.  
**Service**: Frontend Service (gRPC: `/frontend.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display Slack invite link in Polaris `Modal` via `GET /v1/api/community/slack`, enforce RBAC (`customer:frontend`).  
- Integrate with Slack API, log to PostHog (`slack_community_joined`, 5%+ join rate), localized via i18next (Phase 6 languages).  
- Cache in Redis Streams (`community:{customer_id}`), handle 5,000 joins/hour with Kubernetes sharding.  
- **Accessibility**: ARIA label (`aria-label="Join Slack community"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`SlackCommunity.tsx`), Cypress, k6 (5,000 joins).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves Slack community invite link.  
  - **Query**:  
    ```graphql
    query GetSlackInvite($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "slack_invite") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Customer joins Slack via `program_settings.slack_invite`, caches in Redis Streams, and tracks via PostHog (`slack_community_joined`).

## Admin Module (Phases 1–3, 6)

### Phase 1: Core Admin Functions

**US-AM1: View Merchant Overview**  
As an admin, I want to view an overview of all merchants, so that I can monitor platform usage.  
**Service**: Admin Service (gRPC: `/admin.v1/MerchantService/*`, Dockerized).  
**Acceptance Criteria**:  
- Display metrics via `GET /v1/admin-overview`, enforce RBAC (`admin:overview`), in Chart.js bar chart, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`overview:{admin_id}`), handle 5,000 merchants/hour with PostgreSQL partitioning.  
- Log to PostHog (`overview_viewed`, 85%+ view rate).  
- **Accessibility**: ARIA label (`aria-live="Metrics data available"`), WCAG 2.1 AA.  
- **Testing**: Jest (`OverviewPage.tsx`), Cypress, k6 (5,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves merchant overview metrics.  
  - **Query**:  
    ```graphql
    query GetMerchantOverview($first: Int) {
      shops(first: $first) {
        edges {
          node {
            id
            metafield(namespace: "loyalnest", key: "metrics") {
              value
            }
          }
        }
      }
    }
    ```
  - **Variables**: `{ "first": 50 }`  
  - **Use Case**: Admin views `merchants` metrics, visualized with Chart.js, caches in Redis Streams, and tracks via PostHog (`overview_viewed`).

**US-AM2: Manage Merchant List**  
As an admin, I want to view and search merchants, so that I can manage their accounts.  
**Service**: Admin Service (gRPC: `/admin.v1/MerchantService/*`, Dockerized).  
**Acceptance Criteria**:  
- Display list via `GET /v1/admin/merchants`, enforce RBAC (`admin:merchants`), in Polaris `DataTable`, support undo via `POST /v1/admin/merchants/undo`.  
- Cache in Redis Streams (`merchants:{admin_id}`), handle 5,000 merchants/hour.  
- Log to PostHog (`merchant_list_viewed`, 80%+ usage), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Search merchants"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`MerchantsPage.tsx`), Cypress, k6 (5,000 merchants).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves merchant list.  
  - **Query**:  
    ```graphql
    query GetMerchants($first: Int, $query: String) {
      shops(first: $first, query: $query) {
        edges {
          node {
            id
            name
            metafield(namespace: "loyalnest", key: "plan_id") {
              value
            }
          }
        }
      }
    }
    ```
  - **Variables**: `{ "first": 50, "query": "name:*Store*" }`  
  - **Use Case**: Admin views `merchants` list, caches in Redis Streams, and tracks via PostHog (`merchant_list_viewed`).

**US-AM3: Adjust Customer Points**  
As an admin, I want to adjust a customer’s point balance, so that I can correct errors or provide bonuses.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Adjust via `POST /v1/admin/api/points`, enforce RBAC (`admin:points`), insert into `points_transactions`, support undo.  
- Cache in Redis Streams (`points:{customer_id}`), handle 1,000 adjustments/hour.  
- Log to PostHog (`points_adjusted`, 90%+ success), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Adjust customer points"`), WCAG 2.1 AA.  
- **Testing**: Jest (`PointsAdjustment.tsx`), Cypress, k6 (1,000 adjustments).  
- **GraphQL Query Example**:  
  - **Purpose**: Adjusts customer points balance.  
  - **Query**:  
    ```graphql
    mutation AdjustCustomerPoints($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "points_balance",
            "value": "600",
            "type": "number_integer"
          }
        ]
      }
    }
    ```
  - **Use Case**: Admin adjusts `users.points_balance` via `points_transactions`, caches in Redis Streams, and tracks via PostHog (`points_adjusted`).

**US-AM4: Manage Admin Users**  
As an admin, I want to add/edit/delete admin users, so that I can control platform access.  
**Service**: Auth Service (gRPC: `/auth.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Manage users via `POST/PUT/DELETE /v1/admin/users`, assign RBAC roles (e.g., `admin:full_access`), MFA via Auth0.  
- Cache in Redis Streams (`admin_users:{admin_id}`), handle 1,000 updates/hour.  
- Log to PostHog (`admin_user_updated`, 90%+ success), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Add admin user"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`AdminUsers.tsx`), Cypress, k6 (1,000 updates), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Manages admin user roles.  
  - **Query**:  
    ```graphql
    mutation UpdateAdminUser($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "admin_roles",
        "value": "{\"user_id\": \"ADMIN123\", \"roles\": [\"admin:full_access\"]}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Admin updates `admin_users` roles, caches in Redis Streams, and tracks via PostHog (`admin_user_updated`).

**US-AM5: Access Logs**  
As an admin, I want to access API and audit logs in real-time, so that I can monitor platform activity.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Stream logs via `GET /v1/admin/logs` with WebSocket, enforce RBAC (`admin:logs`), filter by date/merchant/action in Polaris `DataTable`.  
- Cache in Redis Streams (`logs:{admin_id}`), handle 5,000 log views/hour with PostgreSQL partitioning.  
- Log to PostHog (`logs_viewed`, 80%+ usage), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Filter logs"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`LogsViewer.tsx`), Cypress, k6 (5,000 log views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves audit logs.  
  - **Query**:  
    ```graphql
    query GetAuditLogs($first: Int, $query: String) {
      auditLogs(first: $first, query: $query) {
        edges {
          node {
            id
            action
            timestamp
          }
        }
      }
    }
    ```
  - **Variables**: `{ "first": 50, "query": "action:points_adjust" }`  
  - **Use Case**: Admin views `audit_logs`, caches in Redis Streams, and tracks via PostHog (`logs_viewed`).

**US-AM6: Support GDPR Requests**  
As an admin, I want to process customer GDPR requests, so that I can comply with GDPR/CCPA requirements.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Process via Shopify webhooks, insert into `gdpr_requests`, enforce RBAC (`admin:gdpr`), notify via Klaviyo/Postscript.  
- Cache in Redis Streams (`gdpr:{customer_id}`), handle 1,000 requests/hour with AES-256 encryption.  
- Log to PostHog (`gdpr_processed`, 90%+ success), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Process GDPR request"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`GDPRDashboard.tsx`), Cypress, k6 (1,000 requests), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Processes GDPR requests.  
  - **Query**:  
    ```graphql
    mutation ProcessGDPRRequest($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "gdpr_status") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "gdpr_status",
            "value": "{\"status\": \"processed\", \"type\": \"delete\"}",
            "type": "json"
          }
        ]
      }
    }
    ```
  - **Use Case**: Admin processes `gdpr_requests`, notifies via Klaviyo/Postscript, caches in Redis Streams, and tracks via PostHog (`gdpr_processed`).

### Phase 2: Enhanced Admin Functions

**US-AM7: Manage Merchant Plans**  
As an admin, I want to upgrade/downgrade merchant plans, so that I can manage their subscriptions.  
**Service**: Admin Service (gRPC: `/admin.v1/MerchantService/*`, Dockerized).  
**Acceptance Criteria**:  
- Change plan via `PUT /v1/admin/plans`, enforce RBAC (`admin:merchants`), update `merchants.plan_id`, support undo.  
- Cache in Redis Streams (`plan:{merchant_id}`), handle 1,000 updates/hour.  
- Log to PostHog (`plan_updated`, 90%+ success), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Change merchant plan"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`PlanManagement.tsx`), Cypress, k6 (1,000 updates).  
- **GraphQL Query Example**:  
  - **Purpose**: Updates merchant plan.  
  - **Query**:  
    ```graphql
    mutation UpdateMerchantPlan($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "plan_id",
        "value": "premium_500",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "string"
      }
    }
    ```
  - **Use Case**: Admin updates `merchants.plan_id`, caches in Redis Streams, and tracks via PostHog (`plan_updated`).

**US-AM8: Monitor Integration Status**  
As an admin, I want to check the health of integrations, so that I can ensure platform reliability.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Check status via `GET /v1/admin/health`, enforce RBAC (`admin:integrations`), show in Polaris `Card`, Chart.js for uptime.  
- Cache in Redis Streams (`health:{admin_id}`), handle 5,000 pings/hour.  
- Log to PostHog (`integration_health_checked`, 95%+ uptime), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Check integration status"`), WCAG 2.1 AA.  
- **Testing**: Jest (`IntegrationHealth.tsx`), Cypress, k6 (5,000 pings).  
- **GraphQL Query Example**:  
  - **Purpose**: Checks integration health.  
  - **Query**:  
    ```graphql
    query GetIntegrationHealth($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "integration_health") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Admin checks integration status, visualizes with Chart.js, caches in Redis Streams, and tracks via PostHog (`integration_health_checked`).

**US-AM9: Support RFM Configurations**  
As an admin, I want to manage RFM settings for merchants, so that I can optimize segmenting.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Edit thresholds via `GET /v1/admin/rfm`, enforce RBAC (`admin:analytics`), preview in Chart.js, localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- Cache in Redis Streams (`rfm_benchmarks:{merchant_id}`), handle 5,000 previews/hour.  
- Log to PostHog (`rfm_updated`, 85%+ usage).  
- **Accessibility**: ARIA label (`aria-label="Edit RFM config"`), RTL ambulatory, WCAG 2.1 AA.  
- **Testing**: Jest (`RFMConfigAdmin.tsx`), Cypress, k6 (5,000 previews).  
- **GraphQL Query Example**:  
  - **Purpose**: Updates merchant RFM settings.  
  - **Query**:  
    ```graphql
    mutation UpdateRFMConfig($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "rfm_benchmarks",
        "value": "{\"industry\": \"Retail\", \"segment_name\": \"Champions\", \"thresholds\": {\"recency\": \"<=30\", \"frequency\": \">=5\", \"monetary\": \">500\"}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Admin updates `rfm_benchmarks`, visualizes with Chart.js, caches in Redis Streams, and tracks via PostHog (`rfm_updated`).

**US-AM14: Manage Multi-Tenant Accounts**  
As a support engineer, I want to manage multiple stores under one admin account, so that I can assist merchants efficiently.  
**Service**: Auth Service (gRPC: `/auth.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Manage stores via `GET/PUT /v1/admin/multi-tenant`, assign RBAC roles (e.g., `admin:multi_tenant`), MFA via Auth0.  
- Cache in Redis Streams (`multi_tenant:{admin_id}`), handle 1,000 updates/hour.  
- Log to PostHog (`multi_tenant_updated`, 80%+ usage), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Manage multi-tenant stores"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`MultiTenantManagement.tsx`), Cypress, k6 (1,000 updates).  
- **GraphQL Query Example**:  
  - **Purpose**: Manages multi-tenant store assignments.  
  - **Query**:  
    ```graphql
    mutation UpdateMultiTenant($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "multi_tenant_stores",
        "value": "{\"admin_id\": \"ADMIN123\", \"stores\": [\"gid://shopify/Shop/123456789\", \"gid://shopify/Shop/987654321\"]}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Admin assigns stores to `admin_users`, caches in Redis Streams, and tracks via PostHog (`multi_tenant_updated`).

**US-AM15: Replay and Undo Customer Actions**  
As an admin, I want to replay a customer’s point journey or undo a bulk action, so that I can fix errors.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Replay via `GET /v1/admin/customer/journey`, enforce RBAC (`admin:points`), undo via `POST /v1/admin/merchants/undo`.  
- Cache in Redis Streams (`journey:{customer_id}`), handle 1,000 replays/hour with PostgreSQL partitioning.  
- Log to PostHog (`journey_replayed`, 90%+ success), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Replay customer journey"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`ActionReplay.tsx`), Cypress, k6 (1,000 replays).  
- **GraphQL Query Example**:  
  - **Purpose**: Replays customer points journey.  
  - **Query**:  
    ```graphql
    query GetCustomerJourney($id: ID!) {
      customer(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "points_history") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Customer/987654321" }`  
  - **Use Case**: Admin replays `points_transactions` journey, caches in Redis Streams, and tracks via PostHog (`journey_replayed`).

**US-AM16: Simulate RFM Segment Transitions**  
As a QA or support user, I want to simulate how a customer moves through RFM segments, so that I can debug scoring.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Simulate via `POST /v1/admin/rfm/simulate`, enforce RBAC (`admin:analytics`), show transitions in Chart.js.  
- Cache in Redis Streams (`rfm_simulation:{customer_id}`), handle 5,000 simulations/hour.  
- Log to PostHog (`rfm_simulation_run`, 85%+ usage), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Simulate RFM segments"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`RFMSimulation.tsx`), Cypress, k6 (5,000 simulations).  
- **GraphQL Query Example**:  
  - **Purpose**: Simulates RFM segment transitions.  
  - **Query**:  
    ```graphql
    mutation SimulateRFM($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "rfm_simulation") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "rfm_simulation",
            "value": "{\"segment\": \"Champions\", \"recency\": 10, \"frequency\": 5, \"monetary\": 500}",
            "type": "json"
          }
        ]
      }
    }
    ```
  - **Use Case**: Admin simulates transitions in `rfm_score_history`, visualizes with Chart.js, caches in Redis Streams, and tracks via PostHog (`rfm_simulation_run`).

**US-AM17: Monitor Notification Template Usage**  
As an admin, I want to track notification template usage, so that I can optimize merchant engagement.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display usage via `GET /v1/admin/templates/usage`, enforce RBAC (`admin:templates`), in Polaris `DataTable`.  
- Cache in Redis Streams (`templates:{merchant_id}`), handle 1,000 views/hour.  
- Log to PostHog (`template_usage_viewed`, 80%+ usage), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="View template usage"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`TemplateUsagePage.tsx`), Cypress, k6 (1,000 views).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves template usage data.  
  - **Query**:  
    ```graphql
    query GetTemplateUsage($id: ID!) {
      shop(id: $id) {
        id
        metafield(namespace: "loyalnest", key: "template_usage") {
          value
        }
      }
    }
    ```
  - **Variables**: `{ "id": "gid://shopify/Shop/123456789" }`  
  - **Use Case**: Admin views `email_templates` usage, caches in Redis Streams, and tracks via PostHog (`template_usage_viewed`).

**US-AM18: Toggle Integration Kill Switch**  
As an admin, I want to enable/disable integrations, so that I can manage platform stability.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Toggle via `PUT /v1/admin/integrations/kill-switch`, enforce RBAC (`admin:integrations`), show in Polaris `Toggle`.  
- Cache in Redis Streams (`integrations:{admin_id}`), handle 1,000 toggles/hour.  
- Log to PostHog (`kill_switch_toggled`, 95%+ uptime), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Accessibility**: ARIA label (`aria-label="Toggle integration"`), RTL support (`ar`, `he`, Phase 6), WCAG 2.1 AA.  
- **Testing**: Jest (`KillSwitchPage.tsx`), Cypress, k6 (1,000 toggles).  
- **GraphQL Query Example**:  
  - **Purpose**: Toggles integration status.  
  - **Query**:  
    ```graphql
    mutation ToggleIntegration($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "integration_status",
        "value": "{\"klaviyo\": false}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: Admin toggles `integrations.settings`, caches in Redis Streams, and tracks via PostHog (`kill_switch_toggled`).

### Phase 6: Premium Admin Features

**US-AM19: Monitor Advanced RFM Analytics**  
As an admin, I want to monitor advanced RFM analytics across merchants, so that I can optimize platform performance.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Display analytics via `GET /v1/admin/rfm/advanced`, enforce RBAC (`admin:analytics`), in Chart.js (line for trends, bar for segments).  
- Integrate xAI API (https://x.ai/api) for churn predictions, cache in Redis Streams (`rfm:{merchant_id}`), handle 100,000 customers/hour with Kubernetes sharding.  
- Log to PostHog (`rfm_advanced_viewed`, 85%+ view rate), localized via i18next (Phase 6 languages).  
- **Accessibility**: ARIA label (`aria-label="View advanced RFM analytics"`), RTL support, WCAG 2.1 AA.  
- **Testing**: Jest (`AdvancedRFMAnalytics.tsx`), Cypress, k6 (100,000 customers).  
- **GraphQL Query Example**:  
  - **Purpose**: Retrieves advanced RFM analytics.  
  - **Query**:  
    ```graphql
    query GetAdvancedRFMAnalytics($first: Int) {
      shops(first: $first) {
        edges {
          node {
            id
            metafield(namespace: "loyalnest", key: "rfm_advanced") {
              value
            }
          }
        }
      }
    }
    ```
  - **Variables**: `{ "first": 50 }`  
  - **Use Case**: Admin views `rfm_score_history` analytics, visualizes with Chart.js, caches in Redis Streams, and tracks via PostHog (`rfm_advanced_viewed`).

## Backend Integrations (Phases 1–3, 6)

### Phase 1: Backend

**US-BI1: Sync Shopify Orders**  
As a system API, I want to sync orders via Shopify webhooks, so that points can be awarded automatically.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Accept webhook `POST /v1/api/orders/points`, enforce RBAC (`system:points`), insert into `points_transactions`.  
- Cache in Redis Streams (`points:{customer_id}`), handle 10,000 orders/hour with PostgreSQL partitioning.  
- Log to PostHog (`points_earned`, 20%+ redemption rate).  
- **Testing**: Jest (webhook handler), k6 (10,000 orders/hour), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Syncs order data for points.  
  - **Query**:  
    ```graphql
    mutation SyncOrderPoints($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "points_balance",
            "value": "500",
            "type": "number_integer"
          }
        ]
      }
    }
    ```
  - **Use Case**: System syncs order to `points_transactions`, updates `users.points_balance`, caches in Redis Streams, and tracks via PostHog (`points_earned`).

**US-BI2: Send Referral Notifications**  
As a system API, I want to send referral notifications via email/Klaviyo or SMS/Postscript, so that customers are informed.  
**Service**: Referrals Service (gRPC: `/referrals.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Queue notification via Bull, fetch template from `email_templates.body` (JSONB), enforce RBAC (`system:referrals`).  
- Cache in Redis Streams (`notifications:{customer_id}`), handle 1,000 notifications/hour.  
- Log to PostHog (`notification_sent`, 7%+ SMS conversion), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Testing**: Jest (notification queue), Cypress, k6 (1,000 notifications).  
- **GraphQL Query Example**:  
  - **Purpose**: Sends referral notification.  
  - **Query**:  
    ```graphql
    mutation SendReferralNotification($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "referral_notification") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "referral_notification",
            "value": "{\"type\": \"sms\", \"status\": \"sent\"}",
            "type": "json"
          }
        ]
      }
    }
    ```
  - **Use Case**: System sends notification via `email_templates.body`, queues via Bull, caches in Redis Streams, and tracks via PostHog (`notification_sent`).

### Phase 2: Advanced Features

**US-BI3: Import Customer Data**  
As a system API, I want to import customer data via integrations, so that merchants can update existing programs.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Import via `POST /v1/api/users/import`, enforce RBAC (`system:users`), process 50,000+ records via Bull queue.  
- Cache in Redis Streams (`users:{merchant_id}`), handle 50,000 records/hour with PostgreSQL partitioning.  
- Log to PostHog (`user_import_completed`, 90%+ success), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`).  
- **Testing**: Jest (import handler), Cypress, k6 (50,000 records).  
- **GraphQL Query Example**:  
  - **Purpose**: Imports customer data.  
  - **Query**:  
    ```graphql
    mutation ImportCustomers($input: [CustomerInput!]!) {
      customersCreate(input: $input) {
        customers {
          id
          metafield(namespace: "loyalnest", key: "points_balance") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": [
        {
          "email": "customer@example.com",
          "metafields": [
            {
              "namespace": "loyalnest",
              "key": "points_balance",
              "value": "100",
              "type": "number_integer"
            }
          ]
        }
      ]
    }
    ```
  - **Use Case**: System imports `users` data, caches in Redis Streams, and tracks via PostHog (`user_import_completed`).

### Phase 3: Advanced Features

**US-BI4: Apply Campaign Discounts**  
As a system API, I want to apply discounts from bonus campaigns, so that customers receive promotional rewards.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Check `bonus_campaigns` via Rust/Wasm, enforce RBAC (`system:points`), insert into `reward_redemptions`.  
- Cache in Redis Streams (`campaign:{customer_id}`), handle 5,000 redemptions/hour with Kubernetes sharding.  
- Log to PostHog (`campaign_discount_applied`, 15%+ redemption), localized via i18next (Phase 3 languages).  
- **Testing**: Jest (campaign handler), Cypress, k6 (5,000 redemptions).  
- **GraphQL Query Example**:  
  - **Purpose**: Applies campaign discount.  
  - **Query**:  
    ```graphql
    mutation ApplyCampaignDiscount($input: DiscountCodeInput!) {
      discountCodeCreate(input: $input) {
        discountCode {
          id
          code
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "code": "CAMPAIGN_10OFF",
        "discountType": "FIXED_AMOUNT",
        "value": 10.0,
        "customerSelection": {
          "customerIds": ["gid://shopify/Customer/987654321"]
        }
      }
    }
    ```
  - **Use Case**: System applies discount from `bonus_campaigns` to `reward_redemptions`, caches in Redis Streams, and tracks via PostHog (`campaign_discount_applied`).

### Phase 6: Premium Backend Integrations

**US-BI5: Sync Multi-Store Data**  
As a system API, I want to sync customer data across multiple Shopify stores, so that loyalty programs are unified.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Sync via `POST /v1/api/points/sync-multi-store`, enforce RBAC (`system:points`), update `users.shared_customer_id`.  
- Cache in Redis Streams (`points:{shared_customer_id}`), handle 100,000 customers/hour with PostgreSQL partitioning and Kubernetes sharding.  
- Log to PostHog (`multi_store_sync`, 15%+ adoption), localized via i18next (Phase 6 languages).  
- **Testing**: Jest (sync handler), Cypress, k6 (100,000 customers).  
- **GraphQL Query Example**:  
  - **Purpose**: Syncs customer data across stores.  
  - **Query**:  
    ```graphql
    mutation SyncMultiStore($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "shared_customer_id") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "shared_customer_id",
            "value": "SHARED_C123",
            "type": "string"
          }
        ]
      }
    }
    ```
  - **Use Case**: System syncs `users.shared_customer_id`, caches in Redis Streams, and tracks via PostHog (`multi_store_sync`).

**US-BI6: Integrate Advanced API for Custom Rewards**  
As a system API, I want to integrate with external APIs to offer custom rewards, so that merchants can provide unique loyalty incentives.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Integrate via `POST /v1/api/rewards/custom`, enforce RBAC (`system:points`), fetch reward data from external APIs (e.g., xAI API at https://x.ai/api), store in `program_settings.custom_rewards` (JSONB).  
- Cache in Redis Streams (`custom_rewards:{merchant_id}`), handle 5,000 reward syncs/hour with PostgreSQL partitioning and Kubernetes sharding.  
- Log to PostHog (`custom_reward_synced`, 15%+ adoption), localized via i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)).  
- **Testing**: Jest (API handler), k6 (5,000 syncs/hour), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Syncs custom reward data from external API.  
  - **Query**:  
    ```graphql
    mutation SyncCustomReward($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "custom_rewards",
        "value": "{\"reward_id\": \"CUSTOM123\", \"type\": \"gift_card\", \"value\": 50}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: System syncs custom rewards to `program_settings.custom_rewards`, caches in Redis Streams, and tracks via PostHog (`custom_reward_synced`).

**US-BI7: Dynamic Reward Tier Adjustments**  
As a system API, I want to dynamically adjust reward tiers based on merchant performance, so that loyalty programs remain competitive.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Adjust tiers via `POST /v1/api/tiers/adjust`, enforce RBAC (`system:points`), update `vip_tiers` based on `rfm_score_history` analytics.  
- Cache in Redis Streams (`tiers:{merchant_id}`), handle 10,000 adjustments/hour with PostgreSQL partitioning and Kubernetes sharding.  
- Log to PostHog (`tier_adjusted`, 85%+ accuracy), localized via i18next (Phase 6 languages).  
- **Testing**: Jest (tier adjustment handler), k6 (10,000 adjustments/hour), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Adjusts reward tiers dynamically.  
  - **Query**:  
    ```graphql
    mutation AdjustRewardTier($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "vip_tiers",
        "value": "{\"tier_id\": \"GOLD\", \"threshold\": {\"points\": 1000, \"spend\": 500}}",
        "ownerId": "gid://shopify/Shop/123456789",
        "type": "json"
      }
    }
    ```
  - **Use Case**: System adjusts `vip_tiers` based on `rfm_score_history`, caches in Redis Streams, and tracks via PostHog (`tier_adjusted`).

**US-BI8: Customer Journey Analytics Sync**  
As a system API, I want to sync customer journey data with analytics platforms, so that merchants can track engagement trends.  
**Service**: RFM Analytics Service (gRPC: `/analytics.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Sync via `POST /v1/api/analytics/journey`, enforce RBAC (`system:analytics`), push `points_transactions` and `rfm_score_history` to external platforms (e.g., PostHog, xAI API at https://x.ai/api).  
- Cache in Redis Streams (`journey:{customer_id}`), handle 100,000 records/hour with PostgreSQL partitioning and Kubernetes sharding.  
- Log to PostHog (`journey_synced`, 85%+ success), localized via i18next (Phase 6 languages).  
- **Testing**: Jest (analytics sync handler), k6 (100,000 records/hour), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Syncs customer journey data.  
  - **Query**:  
    ```graphql
    mutation SyncCustomerJourney($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "journey_data") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "journey_data",
            "value": "{\"actions\": [\"purchase\", \"referral\"], \"timestamps\": [\"2025-07-31T13:39:00Z\"]}",
            "type": "json"
          }
        ]
      }
    }
    ```
  - **Use Case**: System syncs `points_transactions` and `rfm_score_history` to external platforms, caches in Redis Streams, and tracks via PostHog (`journey_synced`).

**US-BI9: Real-Time Fraud Detection**  
As a system API, I want to detect fraudulent loyalty activities in real-time, so that the platform remains secure.  
**Service**: Admin Service (gRPC: `/admin.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Analyze via `POST /v1/api/fraud/detect`, enforce RBAC (`system:admin`), flag suspicious `points_transactions` using xAI API (https://x.ai/api) for anomaly detection.  
- Cache in Redis Streams (`fraud:{customer_id}`), handle 10,000 transactions/hour with PostgreSQL partitioning and Kubernetes sharding.  
- Log to PostHog (`fraud_detected`, 95%+ accuracy), localized via i18next (Phase 6 languages).  
- **Testing**: Jest (fraud detection handler), k6 (10,000 transactions/hour), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Flags fraudulent transactions.  
  - **Query**:  
    ```graphql
    mutation FlagFraudulentTransaction($input: MetafieldInput!) {
      metafieldsSet(input: [$input]) {
        metafields {
          id
          namespace
          key
          value
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "namespace": "loyalnest",
        "key": "fraud_flags",
        "value": "{\"transaction_id\": \"TX123\", \"status\": \"suspicious\"}",
        "ownerId": "gid://shopify/Customer/987654321",
        "type": "json"
      }
    }
    ```
  - **Use Case**: System flags `points_transactions` as fraudulent, caches in Redis Streams, and tracks via PostHog (`fraud_detected`).

**US-BI10: Export Loyalty Data to Apple Wallet**  
As a system API, I want to export loyalty data to Apple Wallet, so that customers can access rewards offline.  
**Service**: Points Service (gRPC: `/points.v1/*`, Dockerized).  
**Acceptance Criteria**:  
- Generate pass via `POST /v1/api/wallet/export`, enforce RBAC (`system:points`), store in `wallet_passes` (AES-256 encryption).  
- Cache in Redis Streams (`wallet:{customer_id}`), handle 5,000 exports/hour with Kubernetes sharding.  
- Log to PostHog (`wallet_exported`, 10%+ adoption), localized via i18next (Phase 6 languages).  
- **Testing**: Jest (wallet export handler), k6 (5,000 exports/hour), OWASP ZAP.  
- **GraphQL Query Example**:  
  - **Purpose**: Exports loyalty data to Apple Wallet.  
  - **Query**:  
    ```graphql
    mutation ExportWalletPass($input: CustomerInput!) {
      customerUpdate(input: $input) {
        customer {
          id
          metafield(namespace: "loyalnest", key: "wallet_pass") {
            value
          }
        }
        userErrors {
          field
          message
        }
      }
    }
    ```
  - **Variables**:  
    ```json
    {
      "input": {
        "id": "gid://shopify/Customer/987654321",
        "metafields": [
          {
            "namespace": "loyalnest",
            "key": "wallet_pass",
            "value": "{\"pass_id\": \"WALLET123\", \"balance\": 500}",
            "type": "json"
          }
        ]
      }
    }
    ```
  - **Use Case**: System exports `users.points_balance` to `wallet_passes`, caches in Redis Streams, and tracks via PostHog (`wallet_exported`).