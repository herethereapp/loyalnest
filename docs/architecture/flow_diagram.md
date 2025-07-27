```mermaid
graph TD
    %% Main Sections
    A[Customer] -->|Interacts with| B[Customer Widget]
    C[Merchant] -->|Manages via| D[Merchant Dashboard]
    E[Admin] -->|Manages via| F[Admin Module]
    G[Backend] -->|Supports| B[Customer Widget]
    G[Backend] -->|Supports| D[Merchant Dashboard]
    G[Backend] -->|Supports| F[Admin Module]
    H[Integrations] -->|Connects to| G[Backend]
    I[Database: PostgreSQL] -->|Stores/Retrieves| G[Backend]
    J[Cache: Redis] -->|Optimizes| G[Backend]
    K[Queue: Bull] -->|Handles Async| G[Backend]
    L[Analytics: PostHog] -->|Tracks Events| G[Backend]
    M[Logging: OpenSearch] -->|Logs| G[Backend]

    %% Customer Widget (Phases 1–3)
    subgraph Customer Widget
        B[Customer Widget] --> B0[App Bridge Auth]
        B[Customer Widget] --> B1[Points Balance]
        B[Customer Widget] --> B2[Redemption]
        B[Customer Widget] --> B3[Referral Popup]
        B[Customer Widget] --> B4[RFM Nudges]
        B[Customer Widget] --> B5[VIP Tiers]
        B[Customer Widget] --> B6[Gamification]
        B[Customer Widget] --> B7[Multilingual Support]
        B[Customer Widget] --> B8[Referral Status]
        B[Customer Widget] --> B9[GDPR Requests]
        B[Customer Widget] --> B10[Progressive Tier Engagement]
        B[Customer Widget] --> B11[Mobile Wallet]
        B[Customer Widget] --> B12[POS Offline Interface]
        B2[Redemption] --> B2a[Discounts]
        B2[Redemption] --> B2b[Free Shipping]
        B2[Redemption] --> B2c[Free Products]
        B2[Redemption] --> B2d[Coupons]
        B3[Referral Popup] --> B3a[SMS/Email Referral]
        B3[Referral Popup] --> B3b[Social Sharing]
        B4[RFM Nudges] --> B4a[Banner/Popup]
        B4[RFM Nudges] --> B4b[Dismiss Action]
        B5[VIP Tiers] --> B5a[Tier Status]
        B5[VIP Tiers] --> B5b[Perks Display]
        B6[Gamification] --> B6a[Badges]
        B6[Gamification] --> B6b[Leaderboards]
        B7[Multilingual Support] --> B7a[Language Selector]
        B7[Multilingual Support] --> B7b[JSONB Content: i18next]
        B8[Referral Status] --> B8a[Pending/Completed]
        B8[Referral Status] --> B8b[Friend Actions: Signup/Purchase]
        B9[GDPR Requests] --> B9a[Data Access]
        B9[GDPR Requests] --> B9b[Data Deletion]
        B9[GDPR Requests] --> B9c[GDPR Form UI]
        B10[Progressive Tier Engagement] --> B10a[ProgressBar]
        B10[Progressive Tier Engagement] --> B10b[Recommended Actions]
        B11[Mobile Wallet] --> B11a[Apple Wallet]
        B11[Mobile Wallet] --> B11b[Google Pay]
        B11[Mobile Wallet] --> B11c[QR Code]
        B12[POS Offline Interface] --> B12a[Award Points]
        B12[POS Offline Interface] --> B12b[Redeem Points]
        B12[POS Offline Interface] --> B12c[SQLite Queue]
    end

    %% Merchant Dashboard (Phases 1–3)
    subgraph Merchant Dashboard
        D[Merchant Dashboard] --> D0[App Bridge Auth]
        D[Merchant Dashboard] --> D1[Welcome Page]
        D[Merchant Dashboard] --> D2[Points Program]
        D[Merchant Dashboard] --> D3[Referrals Program]
        D[Merchant Dashboard] --> D4[Customers]
        D[Merchant Dashboard] --> D5[Analytics]
        D[Merchant Dashboard] --> D6[Settings]
        D[Merchant Dashboard] --> D7[On-Site Content]
        D[Merchant Dashboard] --> D8[VIP Tiers]
        D[Merchant Dashboard] --> D9[Activity Logs]
        D[Merchant Dashboard] --> D10[Bonus Campaigns]
        D[Merchant Dashboard] --> D11[Notification Templates]
        D[Merchant Dashboard] --> D12[RFM Segment Preview]
        D[Merchant Dashboard] --> D13[Customer Import]
        D[Merchant Dashboard] --> D14[Lifecycle Rewards]
        D[Merchant Dashboard] --> D15[Segment Benchmarking]
        D[Merchant Dashboard] --> D16[A/B Test Nudges]
        D[Merchant Dashboard] --> D17[Churn Risk Customers]
        D[Merchant Dashboard] --> D18[Rate Limit Dashboard]
        D[Merchant Dashboard] --> D19[Merchant Referral]
        D[Merchant Dashboard] --> D20[Non-Shopify POS Interface]
        D[Merchant Dashboard] --> D21[Onboarding Flow]
        D1[Welcome Page] --> D1a[Setup Tasks]
        D1[Welcome Page] --> D1b[Congratulatory Messages]
        D2[Points Program] --> D2a[Earn: Purchases, Signups]
        D2[Points Program] --> D2b[Redeem: Discounts, Shipping]
        D2[Points Program] --> D2c[Branding: Rewards Panel]
        D2[Points Program] --> D2d[Status: Enable/Disable]
        D3[Referrals Program] --> D3a[SMS/Email Config]
        D3[Referrals Program] --> D3b[Social Sharing Config]
        D3[Referrals Program] --> D3c[Status Toggle]
        D4[Customers] --> D4a[List: Name, Email, Points]
        D4[Customers] --> D4b[Search: Name/Email]
        D5[Analytics] --> D5a[Metrics: Members, Points]
        D5[Analytics] --> D5b[RFM Chart]
        D5[Analytics] --> D5c[Advanced Reports]
        D5[Analytics] --> D5d[CSV Export]
        D6[Settings] --> D6a[Store Details, Billing]
        D6[Settings] --> D6b[Branding]
        D6[Settings] --> D6c[RFM Config]
        D6[Settings] --> D6d[Developer Toolkit]
        D6[Settings] --> D6e[Language Config]
        D7[On-Site Content] --> D7a[Loyalty Page]
        D7[On-Site Content] --> D7b[Rewards Panel]
        D7[On-Site Content] --> D7c[Launcher Button]
        D7[On-Site Content] --> D7d[Points Display]
        D7[On-Site Content] --> D7e[Post-Purchase Widget]
        D7[On-Site Content] --> D7f[Checkout Extensions]
        D7[On-Site Content] --> D7g[Sticky Bar]
        D8[VIP Tiers] --> D8a[Thresholds: Spending]
        D8[VIP Tiers] --> D8b[Perks: Early Access]
        D9[Activity Logs] --> D9a[Points, Referrals, VIP]
        D10[Bonus Campaigns] --> D10a[Promotions]
        D10[Bonus Campaigns] --> D10b[Goal Spend]
        D10[Bonus Campaigns] --> D10c[Campaign Discounts]
        D11[Notification Templates] --> D11a[Points, Referrals]
        D11[Notification Templates] --> D11b[Template Editor UI]
        D12[RFM Segment Preview] --> D12a[Chart.js Segments]
        D13[Customer Import] --> D13a[CSV Upload UI]
        D14[Lifecycle Rewards] --> D14a[RFM/Tier Triggers]
        D14[Lifecycle Rewards] --> D14b[Shopify Flow Templates]
        D15[Segment Benchmarking] --> D15a[Industry Comparisons]
        D15[Segment Benchmarking] --> D15b[Chart.js Visualization]
        D16[A/B Test Nudges] --> D16a[Variant Config]
        D16[A/B Test Nudges] --> D16b[Results Chart]
        D17[Churn Risk Customers] --> D17a[At-Risk List]
        D17[Churn Risk Customers] --> D17b[xAI Prediction]
        D18[Rate Limit Dashboard] --> D18a[API Usage]
        D18[Rate Limit Dashboard] --> D18b[Alert Notifications]
        D19[Merchant Referral] --> D19a[Invite Link]
        D19[Merchant Referral] --> D19b[Credit Rewards]
        D20[Non-Shopify POS Interface] --> D20a[Square POS]
        D20[Non-Shopify POS Interface] --> D20b[Points Sync]
        D21[Onboarding Flow] --> D21a[3-Step Setup]
        D21[Onboarding Flow] --> D21b[Contextual Tips]
    end

    %% Admin Module (Phases 1–3)
    subgraph Admin Module
        F[Admin Module] --> F0[RBAC Auth]
        F[Admin Module] --> F1[Overview]
        F[Admin Module] --> F2[Merchants]
        F[Admin Module] --> F3[Admin Users]
        F[Admin Module] --> F4[Logs]
        F[Admin Module] --> F5[Plan Management]
        F[Admin Module] --> F6[Integration Health]
        F[Admin Module] --> F7[RFM Config Management]
        F[Admin Module] --> F8[RFM Segment Export]
        F[Admin Module] --> F9[GDPR Requests]
        F[Admin Module] --> F10[Rate Limit Monitoring]
        F[Admin Module] --> F11[Multi-Tenant Accounts]
        F[Admin Module] --> F12[Action Replay]
        F[Admin Module] --> F13[RFM Simulation]
        F[Admin Module] --> F14[Merchant Community]
        F[Admin Module] --> F15[Disaster Recovery]
        F[Admin Module] --> F16[Centralized Logging]
        F1[Overview] --> F1a[Merchant Count, Points]
        F2[Merchants] --> F2a[List: ID, Domain, Plan]
        F2[Merchants] --> F2b[Adjust Points]
        F2[Merchants] --> F2c[Suspend/Reactivate]
        F3[Admin Users] --> F3a[Add/Edit/Delete Admins]
        F4[Logs] --> F4a[API Logs, Audit Logs]
        F4[Logs] --> F4b[WebSocket Streaming]
        F9[GDPR Requests] --> F9a[Data Request]
        F9[GDPR Requests] --> F9b[Data Redaction]
        F9[GDPR Requests] --> F9c[GDPR Request Dashboard UI]
        F10[Rate Limit Monitoring] --> F10a[429 Violations]
        F10[Rate Limit Monitoring] --> F10b[Rate Limit Dashboard UI]
        F11[Multi-Tenant Accounts] --> F11a[Store Linking]
        F11[Multi-Tenant Accounts] --> F11b[Scoped RBAC]
        F12[Action Replay] --> F12a[Customer Journey Replay]
        F12[Action Replay] --> F12b[Undo Bulk Actions]
        F13[RFM Simulation] --> F13a[Mock Order Events]
        F13[RFM Simulation] --> F13b[Segment Transition Chart]
        F14[Merchant Community] --> F14a[Post Management]
        F14[Merchant Community] --> F14b[Comment System]
        F15[Disaster Recovery] --> F15a[Backup Status]
        F15[Disaster Recovery] --> F15b[Recovery Triggers]
        F16[Centralized Logging] --> F16a[Log Filtering]
        F16[Centralized Logging] --> F16b[Log Export]
    end

    %% Integrations (Phases 1–3)
    subgraph Integrations
        H[Integrations] --> H1[Shopify]
        H[Integrations] --> H2[Klaviyo]
        H[Integrations] --> H3[Twilio]
        H[Integrations] --> H4[Postscript]
        H[Integrations] --> H5[Mailchimp]
        H[Integrations] --> H6[Yotpo]
        H[Integrations] --> H7[Square]
        H[Integrations] --> H8[Lightspeed]
        H[Integrations] --> H9[Gorgias]
        H[Integrations] --> H10[Shopify Flow]
        H[Integrations] --> H11[Apple Wallet]
        H[Integrations] --> H12[Google Pay]
        H[Integrations] --> H13[xAI API]
        H1[Shopify] --> H1a[OAuth]
        H1[Shopify] --> H1b[Orders/Create Webhook]
        H1[Shopify] --> H1c[Orders/Cancelled Webhook]
        H1[Shopify] --> H1d[GDPR Webhooks]
        H1[Shopify] --> H1e[POS Points]
        H1d[GDPR Webhooks] --> H1d1[customers/data_request]
        H1d[GDPR Webhooks] --> H1d2[customers/redact]
        H2[Klaviyo] --> H2a[Email Notifications]
        H2[Klaviyo] --> H2b[AWS SES Fallback]
        H3[Twilio] --> H3a[SMS Notifications]
        H4[Postscript] --> H4a[SMS/Email Notifications]
        H4[Postscript] --> H4b[AWS SES Fallback]
        H7[Square] --> H7a[Payment Integration]
        H7[Square] --> H7b[Points Sync]
        H10[Shopify Flow] --> H10a[Lifecycle Triggers]
        H10[Shopify Flow] --> H10b[Churn Risk Actions]
        H11[Apple Wallet] --> H11a[Pass Generation]
        H12[Google Pay] --> H12a[Pass Generation]
        H13[xAI API] --> H13a[Churn Prediction]
        H13[xAI API] --> H13b[RFM Simulation]
    end

    %% Database (Phases 1–3)
    subgraph Database: PostgreSQL
        I[Database] --> I1[merchants]
        I[Database] --> I2[customers]
        I[Database] --> I3[points_transactions]
        I[Database] --> I4[referrals]
        I[Database] --> I5[rewards]
        I[Database] --> I6[reward_redemptions]
        I[Database] --> I7[program_settings]
        I[Database] --> I8[shopify_sessions]
        I[Database] --> I9[customer_segments]
        I[Database] --> I10[admin_users]
        I[Database] --> I11[api_logs]
        I[Database] --> I12[audit_logs]
        I[Database] --> I13[vip_tiers]
        I[Database] --> I14[email_templates]
        I[Database] --> I15[email_events]
        I[Database] --> I16[integrations]
        I[Database] --> I17[bonus_campaigns]
        I[Database] --> I18[gamification_achievements]
        I[Database] --> I19[nudges]
        I[Database] --> I20[nudge_events]
        I[Database] --> I21[gdpr_requests]
        I[Database] --> I22[import_logs]
        I[Database] --> I23[referral_links]
        I[Database] --> I24[rfm_segment_counts]
        I[Database] --> I25[referral_events]
        I[Database] --> I26[wallet_passes]
        I[Database] --> I27[rfm_benchmarks]
        I[Database] --> I28[rfm_segment_deltas]
        I[Database] --> I29[community_posts]
        I[Database] --> I30[backup_logs]
        I1[merchants] --> I1a[Encrypted api_token]
        I2[customers] --> I2a[Encrypted email]
        I2[customers] --> I2b[RFM Score: JSONB]
        I3[points_transactions] --> I3a[Partitioned]
        I4[referrals] --> I4a[Partitioned]
        I4[referrals] --> I4b[referral_link_id]
        I6[reward_redemptions] --> I6a[Partitioned]
        I6[reward_redemptions] --> I6b[campaign_id]
        I10[admin_users] --> I10a[Encrypted metadata]
        I11[api_logs] --> I11a[Partitioned]
        I15[email_events] --> I15a[Partitioned]
        I17[bonus_campaigns] --> I17a[Partitioned]
        I21[gdpr_requests] --> I21a[90-Day Retention]
        I24[rfm_segment_counts] --> I24a[Materialized View]
        I25[referral_events] --> I25a[Partitioned]
        I26[wallet_passes] --> I26a[Encrypted pass_data]
        I27[rfm_benchmarks] --> I27a[Anonymized Data]
        I28[rfm_segment_deltas] --> I28a[Incremental Updates]
        I29[community_posts] --> I29a[Posts and Comments]
        I30[backup_logs] --> I30a[Backup Metadata]
    end

    %% Backend (Phases 1–3)
    subgraph Backend
        G[Backend] --> G1[Points Service: Dockerized]
        G[Backend] --> G2[Referrals Service: Dockerized]
        G[Backend] --> G3[Analytics Service: Dockerized]
        G[Backend] --> G4[AdminCore Service: Dockerized]
        G[Backend] --> G5[AdminFeatures Service: Dockerized]
        G[Backend] --> G6[Auth Service: Dockerized]
        G[Backend] --> G7[Frontend Service: Dockerized]
        G[Backend] --> G8[Rust/Wasm Shopify Functions]
        G[Backend] --> G9[Error Handling]
        G1[Points Service: Dockerized] --> G1a[/points.v1/EarnPoints]
        G1[Points Service: Dockerized] --> G1b[/points.v1/RedeemReward]
        G1[Points Service: Dockerized] --> G1c[/points.v1/AdjustPoints]
        G1[Points Service: Dockerized] --> G1d[/points.v1/CreateCampaign]
        G1[Points Service: Dockerized] --> G1e[/points.v1/GetPointsBalance]
        G1[Points Service: Dockerized] --> G1f[/points.v1/GetVipTierStatus]
        G1[Points Service: Dockerized] --> G1g[/points.v1/GetVipTierProgress]
        G1[Points Service: Dockerized] --> G1h[/points.v1/GenerateWalletPass]
        G1[Points Service: Dockerized] --> G1i[/points.v1/ProcessPOSAction]
        G2[Referrals Service: Dockerized] --> G2a[/referrals.v1/CreateReferral]
        G2[Referrals Service: Dockerized] --> G2b[/referrals.v1/CompleteReferral]
        G2[Referrals Service: Dockerized] --> G2c[/referrals.v1/SendReferralNotification]
        G2[Referrals Service: Dockerized] --> G2d[/referrals.v1/GetReferralStatus]
        G2[Referrals Service: Dockerized] --> G2e[/referrals.v1/UpdateReferralConfig]
        G3[Analytics Service: Dockerized] --> G3a[/analytics.v1/GetAnalytics]
        G3[Analytics Service: Dockerized] --> G3b[/analytics.v1/UpdateRFMScores]
        G3[Analytics Service: Dockerized] --> G3c[/analytics.v1/GetNudges]
        G3[Analytics Service: Dockerized] --> G3d[/analytics.v1/GetLeaderboard]
        G3[Analytics Service: Dockerized] --> G3e[/analytics.v1/ExportAnalytics]
        G3[Analytics Service: Dockerized] --> G3f[/analytics.v1/PreviewRFMSegments]
        G3[Analytics Service: Dockerized] --> G3g[/analytics.v1/GetSegmentBenchmarks]
        G3[Analytics Service: Dockerized] --> G3h[/analytics.v1/ConfigureNudgeABTest]
        G3[Analytics Service: Dockerized] --> G3i[/analytics.v1/GetChurnRisk]
        G3[Analytics Service: Dockerized] --> G3j[/analytics.v1/RunRFMSimulation]
        G4[AdminCore Service: Dockerized] --> G4a[/admin.v1/CompleteSetupTask]
        G4[AdminCore Service: Dockerized] --> G4b[/admin.v1/UpdatePointsProgram]
        G4[AdminCore Service: Dockerized] --> G4c[/admin.v1/UpdateReferralsProgram]
        G4[AdminCore Service: Dockerized] --> G4d[/admin.v1/GetLogs]
        G4[AdminCore Service: Dockerized] --> G4e[/admin.v1/ProcessGDPRRequest]
        G4[AdminCore Service: Dockerized] --> G4f[/admin.v1/GetCustomers]
        G4[AdminCore Service: Dockerized] --> G4g[/admin.v1/UpdateSettings]
        G4[AdminCore Service: Dockerized] --> G4h[/admin.v1/UpdateRFMConfig]
        G4[AdminCore Service: Dockerized] --> G4i[/admin.v1/UpdateContent]
        G4[AdminCore Service: Dockerized] --> G4j[/admin.v1/UpdateVIPTiers]
        G4[AdminCore Service: Dockerized] --> G4k[/admin.v1/UpdateDeveloperSettings]
        G4[AdminCore Service: Dockerized] --> G4l[/admin.v1/UpdateNotificationTemplate]
        G4[AdminCore Service: Dockerized] --> G4m[/admin.v1/GetPlanUsage]
        G4[AdminCore Service: Dockerized] --> G4n[/admin.v1/GetTips]
        G4[AdminCore Service: Dockerized] --> G4o[/admin.v1/GetRateLimits]
        G4[AdminCore Service: Dockerized] --> G4p[/admin.v1/CreateMerchantReferral]
        G5[AdminFeatures Service: Dockerized] --> G5a[/admin.v1/ListAdminUsers]
        G5[AdminFeatures Service: Dockerized] --> G5b[/admin.v1/UpdateAdminUser]
        G5[AdminFeatures Service: Dockerized] --> G5c[/admin.v1/UpdateMultiTenantConfig]
        G5[AdminFeatures Service: Dockerized] --> G5d[/admin.v1/GetCustomerJourney]
        G5[AdminFeatures Service: Dockerized] --> G5e[/admin.v1/UndoAction]
        G5[AdminFeatures Service: Dockerized] --> G5f[/admin.v1/ReplayAction]
        G5[AdminFeatures Service: Dockerized] --> G5g[/admin.v1/CheckHealth]
        G5[AdminFeatures Service: Dockerized] --> G5h[/admin.v1/ManageCommunity]
        G5[AdminFeatures Service: Dockerized] --> G5i[/admin.v1/GetBackupStatus]
        G5[AdminFeatures Service: Dockerized] --> G5j[/admin.v1/InitiateRecovery]
        G5[AdminFeatures Service: Dockerized] --> G5k[/admin.v1/GetCentralizedLogs]
        G5[AdminFeatures Service: Dockerized] --> G5l[/admin.v1/ExportLogs]
        G5[AdminFeatures Service: Dockerized] --> G5m[/admin.v1/SyncSquarePOS]
        G6[Auth Service: Dockerized] --> G6a[/auth.v1/Authenticate]
        G6[Auth Service: Dockerized] --> G6b[/auth.v1/AuthorizeRBAC]
        G7[Frontend Service: Dockerized] --> G7a[/frontend.v1/UpdateContent]
        G7[Frontend Service: Dockerized] --> G7b[/frontend.v1/GetWidgetConfig]
        G7[Frontend Service: Dockerized] --> G7c[/frontend.v1/UpdateCheckoutConfig]
        G8[Rust/Wasm Shopify Functions] --> G8a[Discounts]
        G8[Rust/Wasm Shopify Functions] --> G8b[RFM Updates]
        G8[Rust/Wasm Shopify Functions] --> G8c[VIP Multipliers]
        G8[Rust/Wasm Shopify Functions] --> G8d[Campaign Discounts]
        G9[Error Handling] --> G9a[400: Invalid Input]
        G9[Error Handling] --> G9b[401: Unauthorized]
        G9[Error Handling] --> G9c[429: Rate Limit]
        G9[Error Handling] --> G9d[Exponential Backoff]
        G9[Error Handling] --> G9e[Circuit Breakers]
    end

    %% Data Flow
    A[Customer] -->|Earns/Redeems| I3[points_transactions]
    A[Customer] -->|Refers| I4[referrals]
    A[Customer] -->|Views| I23[referral_links]
    A[Customer] -->|Triggers| I20[nudge_events]
    A[Customer] -->|Views| I13[vip_tiers]
    A[Customer] -->|Earns| I18[gamification_achievements]
    A[Customer] -->|Submits| I21[gdpr_requests]
    A[Customer] -->|Views| I24[rfm_segment_counts]
    A[Customer] -->|Triggers| I25[referral_events]
    A[Customer] -->|Saves| I26[wallet_passes]
    B[Customer Widget] -->|Fetches/Saves| J[Cache: Redis]
    B[Customer Widget] -->|Authenticates| H1a[OAuth]
    B[Customer Widget] -->|Sets| J1[localStorage: Language]
    B0[App Bridge Auth] -->|Secures| G1[Points Service: Dockerized]
    B0[App Bridge Auth] -->|Secures| G2[Referrals Service: Dockerized]
    B0[App Bridge Auth] -->|Secures| G3[Analytics Service: Dockerized]
    B0[App Bridge Auth] -->|Secures| G7[Frontend Service: Dockerized]
    B8[Referral Status] -->|Queries| I4[referrals]
    B8[Referral Status] -->|Queries| I23[referral_links]
    B8[Referral Status] -->|Queries| I25[referral_events]
    B8[Referral Status] -->|Calls| G2d[/referrals.v1/GetReferralStatus]
    B9[GDPR Requests] -->|Submits| G4e[/admin.v1/ProcessGDPRRequest]
    B10[Progressive Tier Engagement] -->|Queries| I13[vip_tiers]
    B10[Progressive Tier Engagement] -->|Queries| I7[program_settings]
    B10[Progressive Tier Engagement] -->|Calls| G1g[/points.v1/GetVipTierProgress]
    B11[Mobile Wallet] -->|Saves| I26[wallet_passes]
    B11[Mobile Wallet] -->|Calls| G1h[/points.v1/GenerateWalletPass]
    B11[Mobile Wallet] -->|Integrates| H11a[Apple Wallet: Pass Generation]
    B11[Mobile Wallet] -->|Integrates| H12a[Google Pay: Pass Generation]
    B12[POS Offline Interface] -->|Syncs| I3[points_transactions]
    B12[POS Offline Interface] -->|Syncs| I6[reward_redemptions]
    B12[POS Offline Interface] -->|Calls| G1i[/points.v1/ProcessPOSAction]
    D[Merchant Dashboard] -->|Configures| I7[program_settings]
    D[Merchant Dashboard] -->|Configures| I14[email_templates]
    D[Merchant Dashboard] -->|Views| I9[customer_segments]
    D[Merchant Dashboard] -->|Views| I24[rfm_segment_counts]
    D[Merchant Dashboard] -->|Views| I27[rfm_benchmarks]
    D[Merchant Dashboard] -->|Views| I28[rfm_segment_deltas]
    D[Merchant Dashboard] -->|Authenticates| H1a[OAuth]
    D0[App Bridge Auth] -->|Secures| G1[Points Service: Dockerized]
    D0[App Bridge Auth] -->|Secures| G2[Referrals Service: Dockerized]
    D0[App Bridge Auth] -->|Secures| G3[Analytics Service: Dockerized]
    D0[App Bridge Auth] -->|Secures| G4[AdminCore Service: Dockerized]
    D0[App Bridge Auth] -->|Secures| G7[Frontend Service: Dockerized]
    D11[Notification Templates] -->|Saves| G7a[/frontend.v1/UpdateContent]
    D12[RFM Segment Preview] -->|Queries| I24[rfm_segment_counts]
    D12[RFM Segment Preview] -->|Queries| I28[rfm_segment_deltas]
    D12[RFM Segment Preview] -->|Calls| G3f[/analytics.v1/PreviewRFMSegments]
    D13[Customer Import] -->|Uploads| G4j[/admin.v1/ImportCustomers]
    D14[Lifecycle Rewards] -->|Configures| I17[bonus_campaigns]
    D14[Lifecycle Rewards] -->|Calls| H10a[Shopify Flow: Lifecycle Triggers]
    D14[Lifecycle Rewards] -->|Calls| G1d[/points.v1/CreateCampaign]
    D15[Segment Benchmarking] -->|Queries| I27[rfm_benchmarks]
    D15[Segment Benchmarking] -->|Calls| G3g[/analytics.v1/GetSegmentBenchmarks]
    D16[A/B Test Nudges] -->|Configures| I7[program_settings]
    D16[A/B Test Nudges] -->|Tracks| I20[nudge_events]
    D16[A/B Test Nudges] -->|Calls| G3h[/analytics.v1/ConfigureNudgeABTest]
    D17[Churn Risk Customers] -->|Queries| I24[rfm_segment_counts]
    D17[Churn Risk Customers] -->|Queries| I28[rfm_segment_deltas]
    D17[Churn Risk Customers] -->|Calls| G3i[/analytics.v1/GetChurnRisk]
    D17[Churn Risk Customers] -->|Integrates| H13a[xAI API: Churn Prediction]
    D17[Churn Risk Customers] -->|Calls| H10b[Shopify Flow: Churn Risk Actions]
    D18[Rate Limit Dashboard] -->|Queries| G4o[/admin.v1/GetRateLimits]
    D18[Rate Limit Dashboard] -->|Logs| I11[api_logs]
    D19[Merchant Referral] -->|Saves| I4[referrals]
    D19[Merchant Referral] -->|Calls| G4p[/admin.v1/CreateMerchantReferral]
    D20[Non-Shopify POS Interface] -->|Syncs| I3[points_transactions]
    D20[Non-Shopify POS Interface] -->|Syncs| I6[reward_redemptions]
    D20[Non-Shopify POS Interface] -->|Calls| G5m[/admin.v1/SyncSquarePOS]
    D20[Non-Shopify POS Interface] -->|Integrates| H7b[Points Sync]
    D21[Onboarding Flow] -->|Saves| I7[program_settings]
    D21[Onboarding Flow] -->|Calls| G4a[/admin.v1/CompleteSetupTask]
    D21[Onboarding Flow] -->|Calls| G4n[/admin.v1/GetTips]
    F[Admin Module] -->|Manages| I1[merchants]
    F[Admin Module] -->|Manages| I10[admin_users]
    F[Admin Module] -->|Views| I11[api_logs]
    F[Admin Module] -->|Views| I12[audit_logs]
    F[Admin Module] -->|Processes| I21[gdpr_requests]
    F[Admin Module] -->|Monitors| I11a[Partitioned: 429]
    F[Admin Module] -->|Manages| I28[rfm_segment_deltas]
    F[Admin Module] -->|Manages| I29[community_posts]
    F[Admin Module] -->|Monitors| I30[backup_logs]
    F0[RBAC Auth] -->|Secures| G4[AdminCore Service: Dockerized]
    F0[RBAC Auth] -->|Secures| G5[AdminFeatures Service: Dockerized]
    F0[RBAC Auth] -->|Secures| G6[Auth Service: Dockerized]
    F9[GDPR Requests] -->|Queries| G4e[/admin.v1/ProcessGDPRRequest]
    F10[Rate Limit Monitoring] -->|Queries| G4o[/admin.v1/GetRateLimits]
    F11[Multi-Tenant Accounts] -->|Manages| I1[merchants]
    F11[Multi-Tenant Accounts] -->|Manages| I10[admin_users]
    F11[Multi-Tenant Accounts] -->|Calls| G5c[/admin.v1/UpdateMultiTenantConfig]
    F12[Action Replay] -->|Queries| I12[audit_logs]
    F12[Action Replay] -->|Queries| I3[points_transactions]
    F12[Action Replay] -->|Queries| I6[reward_redemptions]
    F12[Action Replay] -->|Calls| G5d[/admin.v1/GetCustomerJourney]
    F12[Action Replay] -->|Calls| G5e[/admin.v1/UndoAction]
    F12[Action Replay] -->|Calls| G5f[/admin.v1/ReplayAction]
    F13[RFM Simulation] -->|Queries| I24[rfm_segment_counts]
    F13[RFM Simulation] -->|Queries| I28[rfm_segment_deltas]
    F13[RFM Simulation] -->|Calls| G3j[/analytics.v1/RunRFMSimulation]
    F13[RFM Simulation] -->|Integrates| H13b[xAI API: RFM Simulation]
    F14[Merchant Community] -->|Manages| I29[community_posts]
    F14[Merchant Community] -->|Calls| G5h[/admin.v1/ManageCommunity]
    F15[Disaster Recovery] -->|Queries| I30[backup_logs]
    F15[Disaster Recovery] -->|Calls| G5i[/admin.v1/GetBackupStatus]
    F15[Disaster Recovery] -->|Calls| G5j[/admin.v1/InitiateRecovery]
    F16[Centralized Logging] -->|Queries| M[Logging: OpenSearch]
    F16[Centralized Logging] -->|Calls| G5k[/admin.v1/GetCentralizedLogs]
    F16[Centralized Logging] -->|Calls| G5l[/admin.v1/ExportLogs]
    H[Integrations] -->|Sends Data| G[Backend]
    H1[Shopify] -->|Triggers| G1[Points Service: Dockerized]
    H1[Shopify] -->|Triggers| G2[Referrals Service: Dockerized]
    H2[Klaviyo] -->|Receives| G2c[/referrals.v1/SendReferralNotification]
    H2[Klaviyo] -->|Receives| G4e[/admin.v1/ProcessGDPRRequest]
    H2[Klaviyo] -->|Receives| G7a[/frontend.v1/UpdateContent]
    H3[Twilio] -->|Receives| G2c[/referrals.v1/SendReferralNotification]
    H4[Postscript] -->|Receives| G2c[/referrals.v1/SendReferralNotification]
    H7[Square] -->|Integrates| G5[AdminFeatures Service: Dockerized]
    H10[Shopify Flow] -->|Triggers| G1[Points Service: Dockerized]
    H10[Shopify Flow] -->|Triggers| G3[Analytics Service: Dockerized]
    I2[customers] -->|Stores RFM| I9[customer_segments]
    I2[customers] -->|Stores RFM| I24[rfm_segment_counts]
    I2[customers] -->|Stores RFM| I28[rfm_segment_deltas]
    I13[vip_tiers] -->|Stores VIP Data| I2[customers]
    I7[program_settings] -->|Stores RFM Thresholds| D6c[RFM Config]
    I7[program_settings] -->|Stores Language| D6e[Language Config]
    I14[email_templates] -->|Provides| B7b[JSONB Content: i18next]
    I14[email_templates] -->|Provides| D11a[Points, Referrals]
    I6[reward_redemptions] -->|Stores| G8d[Campaign Discounts]
    J[Cache: Redis] -->|Caches| J2[points:{customer_id}]
    J[Cache: Redis] -->|Caches| J3[referral:{referral_code}]
    J[Cache: Redis] -->|Caches| J4[nudge:{customer_id}]
    J[Cache: Redis] -->|Caches| J5[tier:{customer_id}]
    J[Cache: Redis] -->|Caches| J6[leaderboard:{merchant_id}:sorted_set]
    J[Cache: Redis] -->|Caches| J7[import:{merchant_id}]
    J[Cache: Redis] -->|Caches| J8[campaign:{campaign_id}]
    J[Cache: Redis] -->|Caches| J9[rfm:preview:{merchant_id}:stream]
    J[Cache: Redis] -->|Caches| J10[rate_limit:{merchant_id}]
    J[Cache: Redis] -->|Caches| J11[referral_status:{customer_id}]
    J[Cache: Redis] -->|Caches| J12[analytics:{merchant_id}]
    J[Cache: Redis] -->|Caches| J13[content:{merchant_id}:{locale}]
    J[Cache: Redis] -->|Caches| J14[tier_progress:{customer_id}]
    J[Cache: Redis] -->|Caches| J15[wallet:{customer_id}]
    J[Cache: Redis] -->|Caches| J16[benchmarks:{merchant_id}]
    J[Cache: Redis] -->|Caches| J17[nudge_ab:{merchant_id}]
    J[Cache: Redis] -->|Caches| J18[churn_risk:{merchant_id}]
    J[Cache: Redis] -->|Caches| J19[customer_search:{query}]
    J[Cache: Redis] -->|Caches| J20[journey:{customer_id}]
    J[Cache: Redis] -->|Caches| J21[rfm_simulation:{merchant_id}]
    K[Queue: Bull] -->|Processes| H2a[Email Notifications]
    K[Queue: Bull] -->|Processes| H3a[SMS Notifications]
    K[Queue: Bull] -->|Processes| H4a[SMS/Email Notifications]
    K[Queue: Bull] -->|Processes| H11a[Apple Wallet: Pass Generation]
    K[Queue: Bull] -->|Processes| H12a[Google Pay: Pass Generation]
    G1[Points Service: Dockerized] -->|Queries| I[Database: PostgreSQL]
    G2[Referrals Service: Dockerized] -->|Queries| I[Database: PostgreSQL]
    G3[Analytics Service: Dockerized] -->|Queries| I[Database: PostgreSQL]
    G4[AdminCore Service: Dockerized] -->|Queries| I[Database: PostgreSQL]
    G5[AdminFeatures Service: Dockerized] -->|Queries| I[Database: PostgreSQL]
    G7[Frontend Service: Dockerized] -->|Queries| I[Database: PostgreSQL]
    M[Logging: OpenSearch] -->|Stores| G9[Error Handling]
    M[Logging: OpenSearch] -->|Stores| F4[Logs]
    M[Logging: OpenSearch] -->|Stores| F16[Centralized Logging]

    %% Explanation of Flow Diagram
    **Overview**:
    - The diagram represents the LoyalNest App’s architecture, supporting points earning, redemption, referrals, VIP tiers, gamification, analytics, customer imports, campaign discounts, GDPR/CCPA compliance, referral status, RFM previews, rate limit monitoring, mobile wallet integration, lifecycle rewards, segment benchmarking, A/B testing, churn risk identification, multi-tenant accounts, action replay, RFM simulation, Square POS integration, Shopify Flow, disaster recovery, centralized logging, and merchant community across Phases 1–3 for Shopify Plus merchants (50,000+ customers, 1,000 orders/hour).
    - Aligns with `technical_specifications.md`, `Sequence Diagrams.txt`, `RFM.markdown`, `deployment_infra.md`, and `wireframes.md`.

    **Key Flows**:
    - **Points Earning (US-CW2, US-MD2)**:
      - Customer makes a $100 purchase, triggers Shopify `orders/create` webhook (H1b).
      - Points Service (G1a: /points.v1/EarnPoints, Dockerized) validates HMAC (H1a), fetches `program_settings.config.points_per_dollar` (I7), calculates points (100 * 1 = 100).
      - Inserts into `points_transactions` (I3a, partitioned), updates `customers.points_balance` (I2a, AES-256 encrypted email), caches in Redis (J2: points:{customer_id}).
      - Logs to PostHog (L, `points_earned`, `ui_action:purchase_completed`, 20%+ redemption rate), queues notification via Bull (K) to Klaviyo/Twilio/Postscript (H2a, H3a, H4a) with AWS SES fallback (H2b, H4b) using `email_templates.body` (I14, JSONB, i18next: `en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL)).
      - Handles errors (G9a: invalid webhook, G9c: 429 rate limit, G9e: circuit breakers), logs to OpenSearch (M).
    - **Points Redemption (US-CW3, US-MD2)**:
      - Customer selects discount (B2a), widget calls `/points.v1/RedeemReward` (G1b, Dockerized) with OAuth (B0).
      - Points Service checks `rewards` (I5), deducts points from `customers.points_balance` (I2) in TypeORM transaction, inserts into `reward_redemptions` (I6a, I6b: campaign_id, AES-256 encrypted).
      - Creates Shopify discount via Rust/Wasm (G8a), updates Redis (J2: points:{customer_id}), logs to PostHog (L, `points_redeemed`, `ui_action:reward_redeemed`, 15%+ redemption rate).
      - Handles errors (G9a: insufficient points, G9c: 429 rate limit, G9e: circuit breakers), logs to OpenSearch (M).
    - **Referral Rewards (US-CW4, US-CW5, US-MD3, US-MD19)**:
      - Customer shares link (B3a), Referrals Service (G2a: /referrals.v1/CreateReferral, Dockerized) inserts into `referral_links` (I23, I4b: referral_link_id), queues notification via Bull (K, H2a, H3a, H4a, H2b, H4b).
      - Friend signs up/purchases, Referrals Service (G2b: /referrals.v1/CompleteReferral) inserts into `referrals` (I4a, I4b) and `referral_events` (I25a, event_type='signup'|'purchase'), awards points via `points_transactions` (I3a), updates Redis (J3: referral:{referral_code}), logs to PostHog (L, `referral_completed`, `ui_action:referral_reward_earned`, 7%+ conversion).
      - Customer views detailed status (B8a, B8b) via `/referrals.v1/GetReferralStatus` (G2d), queries `referrals` (I4, I4b) and `referral_events` (I25a), caches in Redis (J11: referral_status:{customer_id}), logs to PostHog (L, `referral_status_viewed`, `ui_action:referral_status_viewed`, 60%+ engagement).
      - Accessibility: ARIA label (`aria-live="polite"`) for status table, RTL for `ar`, `he`, Lighthouse CI score 90+.
      - Testing: Jest for `ReferralStatus`, Cypress E2E, k6 for 5,000 concurrent views, OWASP ZAP.
    - **Progressive Tier Engagement (US-CW16, US-MD8)**:
      - Customer views tier progress (B10a, B10b) via `/points.v1/GetVipTierProgress` (G1g), queries `vip_tiers` (I13) and `program_settings.actions` (I7, JSONB), displays in Polaris `ProgressBar` (e.g., “Silver, $100/$500 to Gold”, “Refer 2 friends”).
      - Caches in Redis (J14: tier_progress:{customer_id}), logs to PostHog (L, `tier_progress_viewed`, `ui_action:tier_progress_viewed`, 60%+ engagement).
      - Handles Shopify webhook (`orders/create`, H1b) for real-time updates, supports multi-store sync.
      - Accessibility: ARIA label (`aria-label="View tier progress"`), RTL for `ar`, `he`.
      - Testing: Jest for `TierProgress`, Cypress E2E, k6 for 5,000 concurrent views.
    - **Mobile Wallet Integration (US-CW17)**:
      - Customer adds balance to wallet (B11a, B11b) via `/points.v1/GenerateWalletPass` (G1h), generates pass with `points_balance`, `vip_tier_id`, QR code (B11c), stores in `wallet_passes` (I26a, AES-256 encrypted).
      - Integrates with Apple Wallet (H11a) and Google Pay (H12a) APIs, queues via Bull (K), caches in Redis (J15: wallet:{customer_id}).
      - Logs to PostHog (L, `wallet_pass_added`, `ui_action:wallet_added`, 10%+ click-through).
      - Accessibility: ARIA label (`aria-label="Add to wallet"`), RTL for `ar`, `he`.
      - Testing: Jest for `WalletIntegration`, Cypress E2E, k6 for 5,000 concurrent requests.
    - **POS Offline Interface (US-CW18, US-MD26)**:
      - Customer/merchant awards/redeems points (B12a, B12b) via `/points.v1/ProcessPOSAction` (G1i), stores in SQLite queue (B12c) for offline sync, updates `points_transactions` (I3a) and `reward_redemptions` (I6a) when online.
      - Logs to PostHog (L, `pos_offline_used`, `offline_sync_completed`, 95%+ sync success), caches in Redis (J2: points:{customer_id}).
      - Accessibility: ARIA label (`aria-label="Manage POS points"`), WCAG 2.1 AA, RTL for `ar`, `he`.
      - Testing: Jest for `POSPage`, Cypress E2E (offline actions), k6 for 1,000 transactions.
    - **Lifecycle Rewards (US-MD19)**:
      - Merchant configures RFM/tier triggers (D14a) in `bonus_campaigns` (I17a, JSONB: `{"rfm_segment": "At-Risk", "tier_change": "Silver->Gold"}`) via Shopify Flow (H10a).
      - Points Service (G1d: /points.v1/CreateCampaign) triggers rewards, notifies via Klaviyo/Postscript (H2a, H4a, K), logs to PostHog (L, `lifecycle_campaign_triggered`, `ui_action:campaign_triggered`, 15%+ redemption).
      - Accessibility: ARIA label (`aria-label="Configure lifecycle automation"`), RTL for `ar`, `he`.
      - Testing: Jest for `LifecycleAutomation`, Cypress E2E, k6 for 5,000 concurrent triggers.
    - **Segment Benchmarking (US-MD20)**:
      - Merchant views comparisons (D15a, D15b) via `/analytics.v1/GetSegmentBenchmarks` (G3g), queries `rfm_benchmarks` (I27a, anonymized), displays in Chart.js bar chart.
      - Caches in Redis (J16: benchmarks:{merchant_id}), logs to PostHog (L, `benchmarks_viewed`, `ui_action:benchmarks_viewed`, 80%+ view rate).
      - Accessibility: ARIA label (`aria-live="Segment benchmark data available"`), RTL for `ar`, `he`.
      - Testing: Jest for `SegmentBenchmarking`, Cypress E2E, k6 for 5,000 concurrent views.
    - **A/B Test Nudges (US-MD21)**:
      - Merchant configures variants (D16a) in `program_settings.ab_tests` (I7, JSONB) via `/analytics.v1/ConfigureNudgeABTest` (G3h), tracks in `nudge_events` (I20), displays results (D16b) in Chart.js.
      - Caches in Redis (J17: nudge_ab:{merchant_id}), logs to PostHog (L, `nudge_ab_tested`, `ui_action:nudge_ab_tested`, 10%+ click-through).
      - Accessibility: ARIA label (`aria-label="Configure nudge A/B test"`), RTL for `ar`, `he`.
      - Testing: Jest for `NudgeABTest`, Cypress E2E, k6 for 5,000 concurrent interactions.
    - **Churn Risk Customers (US-MD22)**:
      - Merchant views At-Risk list (D17a) via `/analytics.v1/GetChurnRisk` (G3i), queries `rfm_segment_counts` (I24a, `segment='At-Risk'`, `monetary > 2x AOV`) and `rfm_segment_deltas` (I28a, incremental updates), integrates xAI API (H13a) for prediction.
      - Triggers actions via Shopify Flow (H10b), caches in Redis (J18: churn_risk:{merchant_id}), logs to PostHog (L, `churn_risk_viewed`, `ui_action:churn_risk_viewed`, 80%+ view rate).
      - Accessibility: ARIA label (`aria-label="View churn risk customers"`), RTL for `ar`, `he`.
      - Testing: Jest for `ChurnRiskDashboard`, Cypress E2E, k6 for 5,000 concurrent views.
    - **Rate Limit Dashboard (US-MD27)**:
      - Merchant views API usage (D18a) and alerts (D18b) via `/admin.v1/GetRateLimits` (G4o), queries `api_logs` (I11a, partitioned), caches in Redis (J10: rate_limit:{merchant_id}), logs to PostHog (L, `rate_limit_viewed`, `ui_action:rate_limit_viewed`, 90%+ view rate).
      - Alerts via email/Slack at 80% limit, logs to OpenSearch (M).
      - Accessibility: ARIA label (`aria-label="View rate limits"`), RTL for `ar`, `he`.
      - Testing: Jest for `RateLimitPage`, Cypress E2E, k6 for 1,000 views.
    - **Merchant Referral (US-MD28)**:
      - Merchant shares invite link (D19a) for credits (D19b) via `/admin.v1/CreateMerchantReferral` (G4p), stores in `referrals` (I4a, I4b), logs to PostHog (L, `merchant_referral_created`, `ui_action:merchant_referral_created`, 5%+ conversion).
      - Accessibility: ARIA label (`aria-label="Share merchant referral"`), RTL for `ar`, `he`.
      - Testing: Jest for `MerchantReferralPage`, Cypress E2E, k6 for 1,000 referrals.
    - **Non-Shopify POS Interface (US-MD29)**:
      - Merchant manages points via Square POS (D20a) using `/admin.v1/SyncSquarePOS` (G5m), syncs to `points_transactions` (I3a) and `reward_redemptions` (I6a) via Square API (H7b), logs to PostHog (L, `square_sync_triggered`, `ui_action:square_sync_triggered`, 95%+ sync success).
      - Accessibility: ARIA label (`aria-label="Manage Square POS points"`), WCAG 2.1 AA, RTL for `ar`, `he`.
      - Testing: Jest for `SquarePOSPage`, Cypress E2E, k6 for 1,000 transactions.
    - **Onboarding Flow (US-MD30)**:
      - Merchant completes 3-step setup (D21a) with tips (D21b) via `/admin.v1/CompleteSetupTask` (G4a) and `/admin.v1/GetTips` (G4n), updates `program_settings` (I7), logs to PostHog (L, `onboarding_completed`, `ui_action:onboarding_completed`, 90%+ completion).
      - Accessibility: ARIA label (`aria-label="Complete onboarding step"`), WCAG 2.1 AA, RTL for `ar`, `he`.
      - Testing: Jest for `OnboardingPage`, Cypress E2E, k6 for 1,000 merchants.
    - **Multi-Tenant Accounts (US-AM11)**:
      - Admin links stores (F11a) and assigns RBAC (F11b) in `merchants` (I1, `multi_tenant_group_id`) and `admin_users.metadata` (I10a, AES-256) via `/admin.v1/UpdateMultiTenantConfig` (G5c), logs to PostHog (L, `multi_tenant_updated`, `ui_action:multi_tenant_updated`, 80%+ usage).
      - Caches in Redis (J19: multi_tenant:group:{group_id}).
      - Accessibility: ARIA label (`aria-label="Manage multi-tenant stores"`), RTL for `ar`, `he`.
      - Testing: Jest for `MultiTenantManagement`, Cypress E2E, k6 for 1,000 concurrent updates.
    - **Action Replay (US-AM12)**:
      - Admin replays journey (F12a) or undoes actions (F12b) via `/admin.v1/GetCustomerJourney` (G5d), `/admin.v1/UndoAction` (G5e), or `/admin.v1/ReplayAction` (G5f), queries `points_transactions` (I3a), `reward_redemptions` (I6a), `audit_logs` (I12).
      - Caches in Redis (J20: journey:{customer_id}), logs to PostHog (L, `journey_replayed`, `action_undone`, `action_replayed`, 90%+ success).
      - Accessibility: ARIA label (`aria-label="Replay customer journey"`), RTL for `ar`, `he`.
      - Testing: Jest for `ActionReplay`, Cypress E2E, k6 for 1,000 concurrent replays.
    - **RFM Simulation (US-AM13)**:
      - Admin simulates transitions (F13a, F13b) via `/analytics.v1/RunRFMSimulation` (G3j), queries `rfm_segment_counts` (I24a) and `rfm_segment_deltas` (I28a), integrates xAI API (H13b), stores in `rfm_simulation_logs` (I28), displays in Chart.js.
      - Caches in Redis (J21: rfm_simulation:{merchant_id}), logs to PostHog (L, `rfm_simulation_run`, `ui_action:rfm_simulation_run`, 80%+ usage).
      - Accessibility: ARIA label (`aria-label="Simulate RFM segments"`), RTL for `ar`, `he`.
      - Testing: Jest for `RFMSimulation`, Cypress E2E, k6 for 5,000 concurrent simulations.
    - **Merchant Community (US-AM14)**:
      - Admin manages posts/comments (F14a, F14b) via `/admin.v1/ManageCommunity` (G5h), stores in `community_posts` (I29a), logs to PostHog (L, `community_post_created`, `ui_action:community_post_created`, 10%+ engagement).
      - Accessibility: ARIA label (`aria-label="Create community post"`), RTL for `ar`, `he`.
      - Testing: Jest for `CommunityDashboard`, Cypress E2E, k6 for 1,000 posts.
    - **Disaster Recovery (US-AM15)**:
      - Admin monitors backups (F15a) and triggers recovery (F15b) via `/admin.v1/GetBackupStatus` (G5i) and `/admin.v1/InitiateRecovery` (G5j), logs to `backup_logs` (I30a), logs to PostHog (L, `backup_initiated`, `ui_action:backup_initiated`, 99%+ reliability).
      - Accessibility: ARIA label (`aria-label="Manage disaster recovery"`), RTL for `ar`, `he`.
      - Testing: Jest for `DisasterRecovery`, Cypress E2E, k6 for 1,000 recovery requests.
    - **Centralized Logging (US-AM16)**:
      - Admin filters/exports logs (F16a, F16b) via `/admin.v1/GetCentralizedLogs` (G5k) and `/admin.v1/ExportLogs` (G5l), queries OpenSearch (M), logs to PostHog (L, `logs_exported`, `ui_action:logs_exported`, 90%+ success).
      - Accessibility: ARIA label (`aria-label="Filter centralized logs"`), RTL for `ar`, `he`.
      - Testing: Jest for `CentralizedLogging`, Cypress E2E, k6 for 10,000 log queries.

    **How to Use**:
    - **Render**: Copy Mermaid code into Mermaid Live Editor (https://mermaid.live/) or VS Code with Mermaid plugin. Export as SVG/PNG for documentation.
    - **Documentation**: Save to `docs/flows/system_architecture.mmd`. Include in README.md or presentations for stakeholders.
    - **Development**: Guide implementation of `WebhookController`, Dockerized microservices (G1–G7), and UI components (Vite + React, Polaris, Tailwind CSS, compiled bundle <100KB).
    - **Testing**: Map to Jest tests for APIs (e.g., `/points.v1/EarnPoints`, `/referrals.v1/GetReferralStatus`, `/admin.v1/SyncSquarePOS`), UI components (e.g., GDPR Form UI, WalletIntegration, ChurnRiskDashboard), Lighthouse CI for accessibility (90+ score), k6 for 5,000 concurrent requests, OWASP ZAP for security.
    - **Scalability**: Supports 50,000+ customers with partitioned tables (I3a, I4a, I6a, I11a, I15a, I17a, I25a), Bull queues (K), Redis sorted sets (J6: leaderboard:{merchant_id}:sorted_set), and Redis Streams (J9: rfm:preview:{merchant_id}:stream, J14–J21).
    - **VPS Deployment**: Optimized for Hetzner/Linode, with Dockerized services and OpenSearch (M) for centralized logging.
    - **Security**: Implements Shopify OAuth (H1a), RBAC (F0, G6b), AES-256 encryption via `pgcrypto` (I1a, I2a, I6a, I10a, I26a), GDPR/CCPA compliance with 90-day retention (I21a).
    - **Multilingualism**: Uses i18next, `Accept-Language` headers, and JSONB fields (`program_settings.config`, `email_templates.body`, `nudges.title`) with `CHECK ?| ARRAY['en', 'es', 'fr', 'de', 'pt', 'ja', 'ru', 'it', 'nl', 'pl', 'tr', 'fa', 'zh-CN', 'vi', 'id', 'cs', 'ar', 'ko', 'uk', 'hu', 'sv', 'he']` and RTL support for `ar`, `he`.
    - **Error Handling**: Handles 400 (invalid input), 401 (unauthorized), 429 (rate limit) with exponential backoff (G9d) and circuit breakers (G9e), logged to OpenSearch (M).
    - **Analytics**: Integrates PostHog (L) for consistent event tracking (e.g., `points_earned`, `referral_status_viewed`, `wallet_pass_added`, `lifecycle_campaign_triggered`, `churn_risk_viewed`, `square_sync_triggered`).
```