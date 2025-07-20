```mermaid
%% Sequence Diagrams for LoyalNest App
%% Aligned with schema.sql (artifact_id: 3525b638-7e8e-4252-8 Hawkins), erd.mmd (artifact_id: a6df1e75-4604-4604-bb66-1d4d7bb729cf), Flow Diagram.txt, rfm.md (artifact_id: 9eabf48a-07bb-4d69-adf0-afe26b79b266), Internal_admin_module.md, project_plan.md
%% Covers Customer Widget, Merchant Dashboard, Admin Module, Backend Integrations
%% Supports Phases 1-6, scalability (50,000+ customers, 10,000 orders/hour), GDPR/CCPA, multilingual (en, es, fr, de, pt, ja; Phase 6: ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
%% Docker services: points-service, referrals-service, analytics-service, admin-core-service, admin-features-service, auth-service, frontend-service
%% PostHog events aligned with wireframes (e.g., points_history_viewed, gdpr_request_submitted, rfm_wizard_badge_earned, admin_event_simulated)
%% Includes AWS SES fallback, Square POS sync, incremental RFM updates, circuit breakers, Loki + Grafana logging

%% Customer Widget: Points Earning (Phase 1, US-CW2)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant PointsService as points-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Shopify
    participant PostHog
    Customer->>Widget: Make Purchase
    Widget->>PointsService: gRPC /points.v1/EarnPoints (customer_id, order_id, merchant_id, Accept-Language)
    PointsService->>Shopify: Validate Order Webhook HMAC (GraphQL, 50 points/s)
    Shopify-->>PointsService: Order Confirmed (total_price)
    PointsService->>Cache: Check points:{customer_id}
    Cache-->>PointsService: Return points_balance
    alt Valid Order
        PointsService->>DB: INSERT points_transactions (customer_id, merchant_id, type="earn", points)
        DB-->>PointsService: Transaction ID
        PointsService->>DB: UPDATE customers SET points_balance = points_balance + points
        DB-->>PointsService: Updated
        PointsService->>Cache: Update points:{customer_id}
        PointsService->>PostHog: Log points_earned
        PointsService-->>Widget: Points Earned (OK)
        Widget-->>Customer: Display Updated Balance (i18next, PointsHistory.tsx, aria-label="Updated points balance")
    else Invalid Order
        PointsService-->>Widget: Error (Invalid HMAC, 400)
        Widget-->>Customer: Display Error (i18next, ErrorModal.tsx, aria-label="Invalid order error")
    else Rate Limit Exceeded
        PointsService->>Cache: Enqueue rate_limit_queue:{merchant_id} (Bull)
        PointsService-->>Widget: Error (429, Exponential Backoff, nestjs-circuit-breaker)
        Widget-->>Customer: Display Rate Limit Error (i18next, ErrorModal.tsx, aria-label="Rate limit error")
    end
    Note right of DB: Partitioned points_transactions (I3a)
    Note right of PointsService: Uses TypeORM transaction, AES-256 encryption, Loki + Grafana logging (median >1s, P95 >3s)
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP (ECL: 256)

%% Customer Widget: Points Redemption (Phase 1, US-CW3)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant PointsService as points-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Shopify
    participant PostHog
    Customer->>Widget: Select Reward (e.g., 10% Discount, Rewards.tsx, aria-label="Select reward")
    Widget->>PointsService: gRPC /points.v1/RedeemReward (customer_id, reward_id, merchant_id, Accept-Language)
    PointsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>PointsService: Token Valid
    PointsService->>Cache: Check points:{customer_id}
    Cache-->>PointsService: Return points_balance
    alt Sufficient Points
        PointsService->>DB: SELECT rewards WHERE reward_id, merchant_id
        DB-->>PointsService: Reward Details (points_cost, type, value)
        PointsService->>Shopify: Create Discount Code (Rust/Wasm)
        Shopify-->>PointsService: Discount Code
        PointsService->>DB: INSERT reward_redemptions (customer_id, reward_id, merchant_id, campaign_id, discount_code, points_spent)
        DB-->>PointsService: Redemption ID
        PointsService->>DB: UPDATE customers SET points_balance = points_balance - points_cost
        DB-->>PointsService: Updated
        PointsService->>Cache: Update points:{customer_id}
        PointsService->>PostHog: Log points_redeemed
        PointsService-->>Widget: Discount Code Issued (OK)
        Widget-->>Customer: Display Discount Code (i18next, RewardSuccess.tsx, aria-label="Discount code issued")
    else Insufficient Points
        PointsService-->>Widget: Error (Insufficient Points, 400)
        Widget-->>Customer: Display Error (i18next, ErrorModal.tsx, aria-label="Insufficient points error")
    else Rate Limit Exceeded
        PointsService->>Cache: Enqueue rate_limit_queue:{merchant_id} (Bull)
        PointsService-->>Widget: Error (429, Exponential Backoff, nestjs-circuit-breaker)
        Widget-->>Customer: Display Rate Limit Error (i18next, ErrorModal.tsx, aria-label="Rate limit error")
    end
    Note right of DB: Partitioned reward_redemptions (I6a), AES-256 discount_code
    Note right of PointsService: Uses TypeORM transaction, Loki + Grafana logging
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Customer Widget: Referral Creation and Reward (Phase 1, US-CW4, US-CW5, US-CW7)
sequenceDiagram
    participant Customer as Advocate
    participant Widget as Customer Widget (React)
    participant ReferralsService as referrals-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Klaviyo
    participant Postscript
    participant AWSSES as AWS SES
    participant PostHog
    Customer->>Widget: Share Referral Link (ReferralShare.tsx, aria-label="Share referral link")
    Widget->>ReferralsService: gRPC /referrals.v1/CreateReferral (advocate_customer_id, merchant_id, Accept-Language)
    ReferralsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>ReferralsService: Token Valid
    ReferralsService->>DB: INSERT referral_links (advocate_customer_id, merchant_id, referral_code)
    DB-->>ReferralsService: Referral Link ID
    alt Klaviyo/Postscript Available
        ReferralsService->>Klaviyo: Queue Notification (Bull, JSONB body, metadata: {"channel": "email"})
        ReferralsService->>Postscript: Queue Notification (Bull, metadata: {"channel": "sms"})
        Klaviyo-->>Customer: Referral Link Sent
        Postscript-->>Customer: Referral Link Sent
    else Fallback to AWS SES
        ReferralsService->>AWSSES: Queue Notification (Bull, JSONB body, metadata: {"channel": "email"})
        AWSSES-->>Customer: Referral Link Sent
        ReferralsService->>PostHog: Log referral_fallback_triggered
    end
    ReferralsService->>Cache: Update referral:{referral_code}
    ReferralsService->>PostHog: Log referral_created
    ReferralsService-->>Widget: Referral Code (OK)
    Widget-->>Customer: Display Referral Code (i18next, ReferralShare.tsx, aria-label="Referral code")
    Note right of API: Friend uses referral link
    participant Friend
    Friend->>Widget: Sign Up via Referral Link (ReferralSignup.tsx, aria-label="Sign up with referral")
    Widget->>ReferralsService: gRPC /referrals.v1/CompleteReferral (referral_code, friend_customer_id, merchant_id)
    ReferralsService->>DB: INSERT referrals (advocate_customer_id, friend_customer_id, referral_link_id, reward_id, merchant_id, metadata)
    DB-->>ReferralsService: Referral ID
    ReferralsService->>DB: INSERT referral_events (referral_id, event_type="signup", metadata)
    DB-->>ReferralsService: Event ID
    ReferralsService->>DB: INSERT points_transactions (advocate_customer_id, merchant_id, type="referral", points)
    DB-->>ReferralsService: Transaction ID
    ReferralsService->>DB: UPDATE customers SET points_balance = points_balance + points
    DB-->>ReferralsService: Updated
    ReferralsService->>Cache: Update points:{advocate_customer_id}
    alt Klaviyo/Postscript Available
        ReferralsService->>Klaviyo: Queue Reward Notification (Bull, JSONB body, metadata: {"channel": "email"})
        ReferralsService->>Postscript: Queue Reward Notification (Bull, metadata: {"channel": "sms"})
        Klaviyo-->>Customer: Reward Notification
        Postscript-->>Customer: Reward Notification
    else Fallback to AWS SES
        ReferralsService->>AWSSES: Queue Reward Notification (Bull, JSONB body, metadata: {"channel": "email"})
        AWSSES-->>Customer: Reward Notification
        ReferralsService->>PostHog: Log referral_fallback_triggered
    end
    ReferralsService->>PostHog: Log referral_completed
    ReferralsService-->>Widget: Referral Success (OK)
    Widget-->>Friend: Display Welcome Points (i18next, ReferralSuccess.tsx, aria-label="Welcome points")
    Note right of DB: Partitioned referrals (I4a), points_transactions (I3a), referral_events (I25a)
    Note right of ReferralsService: Uses idx_referrals_notification_status, AES-256 referral_code, Loki + Grafana logging
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Customer Widget: Viewing Referral Status (Phase 1, US-CW7, Updated)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant ReferralsService as referrals-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Customer->>Widget: View Referral Status (ReferralStatus.tsx, aria-live="polite")
    Widget->>ReferralsService: gRPC /referrals.v1/GetReferralStatus (customer_id, merchant_id, Accept-Language)
    ReferralsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>ReferralsService: Token Valid
    ReferralsService->>Cache: Check referral_status:{customer_id}
    Cache-->>ReferralsService: Return referral_data
    alt Cache Miss
        ReferralsService->>DB: SELECT referrals, referral_links, referral_events WHERE advocate_customer_id
        DB-->>ReferralsService: Referral Status (pending/completed, event_type="signup"/"purchase", metadata)
        ReferralsService->>DB: UPDATE referral_links SET last_viewed_at = CURRENT_TIMESTAMP
        DB-->>ReferralsService: Updated
    end
    ReferralsService->>Cache: Update referral_status:{customer_id}
    ReferralsService->>PostHog: Log referral_status_viewed
    ReferralsService-->>Widget: Referral Status (OK)
    Widget-->>Customer: Display Status Table (i18next, ReferralStatus.tsx, aria-label="Referral status table", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Queries referrals (I4a), referral_links (I23), referral_events (I25a), last_viewed_at
    Note right of ReferralsService: Uses idx_referrals_notification_status, Loki + Grafana logging
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP, Jest/Cypress tests

%% Customer Widget: Progressive Tier Engagement (Phase 3, US-CW16, Updated)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant PointsService as points-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Customer->>Widget: View Tier Progress (TierProgress.tsx, aria-label="View tier progress")
    Widget->>PointsService: gRPC /points.v1/GetVipTierProgress (customer_id, merchant_id, Accept-Language)
    PointsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>PointsService: Token Valid
    PointsService->>Cache: Check tier_progress:{customer_id}
    Cache-->>PointsService: Return progress_data
    alt Cache Miss
        PointsService->>DB: SELECT customers.vip_tier_id, points_balance, vip_tiers.threshold_value, program_settings.actions, setup_tasks
        DB-->>PointsService: Progress Data (current_tier, progress_to_next, actions, setup_progress)
    end
    PointsService->>Cache: Update tier_progress:{customer_id}
    PointsService->>PostHog: Log tier_progress_viewed
    PointsService-->>Widget: Progress Data, Setup Progress (OK)
    Widget-->>Customer: Display ProgressBar, Actions, Badges (i18next, TierProgress.tsx, Polaris ProgressBar, aria-label="Tier progress and badges", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Queries customers (I2), vip_tiers (I13), program_settings (I7), setup_tasks
    Note right of PointsService: Multilingual actions via JSONB, WebSocket /admin/v1/setup/stream for setup progress
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP, Jest/Cypress tests

%% Customer Widget: Save Loyalty Balance to Mobile Wallet (Phase 3, US-CW17)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant PointsService as points-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant AppleWallet as Apple Wallet API
    participant GooglePay as Google Pay API
    participant Queue as Bull Queue
    participant PostHog
    Customer->>Widget: Add to Wallet (WalletIntegration.tsx, aria-label="Add to wallet")
    Widget->>PointsService: gRPC /points.v1/GenerateWalletPass (customer_id, merchant_id, Accept-Language)
    PointsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>PointsService: Token Valid
    PointsService->>DB: SELECT customers.points_balance, vip_tier_id
    DB-->>PointsService: Balance, Tier
    PointsService->>DB: INSERT wallet_passes (customer_id, merchant_id, pass_data, qr_code)
    DB-->>PointsService: Pass ID
    PointsService->>Queue: Queue Pass Generation (Bull)
    Queue->>AppleWallet: Generate Apple Pass (pass_data, qr_code)
    Queue->>GooglePay: Generate Google Pass (pass_data, qr_code)
    AppleWallet-->>PointsService: Apple Pass URL
    GooglePay-->>PointsService: Google Pass URL
    PointsService->>Cache: Update wallet:{customer_id}
    PointsService->>PostHog: Log wallet_pass_added
    PointsService-->>Widget: Pass URL (OK)
    Widget-->>Customer: Display QR Code, Pass Link (i18next, WalletIntegration.tsx, CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Inserts wallet_passes (I26a, AES-256 pass_data)
    Note right of PointsService: Handles 429 rate limits, nestjs-circuit-breaker, Loki + Grafana logging
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP, Jest/Cypress tests

%% Customer Widget: GDPR Data Request (Phase 1, US-CW8)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant Klaviyo
    participant AWSSES as AWS SES
    participant PostHog
    Customer->>Widget: Submit GDPR Form (GDPRForm.tsx, request_type: data_request/redact, aria-label="Submit GDPR request")
    Widget->>AdminCoreService: gRPC /admin.v1/ProcessGDPRRequest (customer_id, merchant_id, request_type, Accept-Language)
    AdminCoreService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>AdminCoreService: Token Valid
    AdminCoreService->>DB: INSERT gdpr_requests (customer_id, merchant_id, request_type, retention_expires_at, metadata: {"origin": "widget"})
    DB-->>AdminCoreService: Request ID
    AdminCoreService->>DB: SELECT customers, points_transactions, reward_redemptions WHERE customer_id
    DB-->>AdminCoreService: Customer Data (AES-256 decrypted email)
    alt Klaviyo Available
        AdminCoreService->>Klaviyo: Queue Data Email (Bull, JSONB body, metadata: {"channel": "email"})
        Klaviyo-->>Customer: Data Sent/Redaction Confirmation
    else Fallback to AWS SES
        AdminCoreService->>AWSSES: Queue Data Email (Bull, JSONB body, metadata: {"channel": "email"})
        AWSSES-->>Customer: Data Sent/Redaction Confirmation
        AdminCoreService->>PostHog: Log referral_fallback_triggered
    end
    AdminCoreService->>PostHog: Log gdpr_request_submitted
    AdminCoreService-->>Widget: Request Submitted (OK)
    Widget-->>Customer: Display Confirmation (i18next, GDPRSuccess.tsx, aria-label="GDPR request confirmation", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Updates gdpr_requests (I21a, partitioned, 90-day retention)
    Note right of AdminCoreService: AES-256 encryption for email, discount_code, Loki + Grafana logging
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Customer Widget: Viewing VIP Tier Status (Phase 2, US-CW9)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant PointsService as points-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Customer->>Widget: View VIP Status (VIPTier.tsx, aria-label="View VIP tier status")
    Widget->>PointsService: gRPC /points.v1/GetVipTierStatus (customer_id, merchant_id, Accept-Language)
    PointsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>PointsService: Token Valid
    PointsService->>Cache: Check tier:{customer_id}
    Cache-->>PointsService: Return tier_data
    alt Cache Miss
        PointsService->>DB: SELECT customers.vip_tier_id, points_balance, vip_tiers (threshold_value, perks)
        DB-->>PointsService: Tier Details
    end
    PointsService->>Cache: Update tier:{customer_id}
    PointsService->>PostHog: Log vip_status_viewed
    PointsService-->>Widget: Current Tier, Progress, Perks (OK)
    Widget-->>Customer: Display VIP Tier (e.g., Silver, $100/$500, i18next, VIPTier.tsx, CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Queries customers (I2), vip_tiers (I13)
    Note right of PointsService: Multilingual perks via JSONB, Loki + Grafana logging
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP

%% Customer Widget: Gamification Interaction (Phase 3, US-CW12, Updated)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Customer->>Widget: Complete Action (e.g., Purchase, Gamification.tsx, aria-label="Complete gamification action")
    Widget->>AnalyticsService: gRPC /analytics.v1/RecordGamificationAction (customer_id, action_type, merchant_id, Accept-Language)
    AnalyticsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>AnalyticsService: Token Valid
    alt Feature Flag rfm_wizard_badge_earned Enabled
        AnalyticsService->>DB: INSERT gamification_achievements (customer_id, merchant_id, badge, setup_tasks)
        DB-->>AnalyticsService: Achievement ID
        AnalyticsService->>Cache: Update leaderboard:{merchant_id} (Sorted Set)
        AnalyticsService->>DB: SELECT customers.points_balance, gamification_achievements, setup_tasks
        DB-->>AnalyticsService: Achievements List, Setup Progress
        AnalyticsService->>Cache: Update setup_progress:{customer_id}
        AnalyticsService->>PostHog: Log badge_earned
        AnalyticsService-->>Widget: Badge Earned, Leaderboard Rank, Setup Progress (OK)
        Widget-->>Customer: Display Badge, Leaderboard, ProgressBar (i18next, Gamification.tsx, Polaris ProgressBar, aria-label="Badge earned", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Feature Flag Disabled
        AnalyticsService-->>Widget: Feature Unavailable (403)
        Widget-->>Customer: Display Error (i18next, ErrorModal.tsx, aria-label="Feature unavailable")
    end
    Note right of DB: Updates gamification_achievements (I18), setup_tasks
    Note right of AnalyticsService: Uses JSONB for badge metadata, WebSocket /admin/v1/setup/stream
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Customer Widget: Nudge Interaction (Phase 2, US-CW10)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Klaviyo
    participant Postscript
    participant AWSSES as AWS SES
    participant PostHog
    Customer->>Widget: Trigger Nudge (e.g., Click Banner, NudgeBanner.tsx, aria-label="Trigger nudge")
    Widget->>AnalyticsService: gRPC /analytics.v1/GetNudges (customer_id, nudge_id, merchant_id, Accept-Language)
    AnalyticsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>AnalyticsService: Token Valid
    AnalyticsService->>Cache: Check nudge:{customer_id}
    Cache-->>AnalyticsService: Return nudge_data
    alt Cache Miss
        AnalyticsService->>DB: SELECT nudges (type, title->>'en', description->>'en')
        DB-->>AnalyticsService: Nudge Details
    end
    AnalyticsService->>DB: INSERT nudge_events (customer_id, nudge_id, merchant_id, action)
    DB-->>AnalyticsService: Event ID
    alt Klaviyo/Postscript Available
        AnalyticsService->>Klaviyo: Queue Email Notification (Bull, JSONB body, metadata: {"channel": "email"})
        AnalyticsService->>Postscript: Queue SMS Notification (Bull, metadata: {"channel": "sms"})
        Klaviyo-->>Customer: Nudge Email
        Postscript-->>Customer: Nudge SMS
    else Fallback to AWS SES
        AnalyticsService->>AWSSES: Queue Email Notification (Bull, JSONB body, metadata: {"channel": "email"})
        AWSSES-->>Customer: Nudge Email
        AnalyticsService->>PostHog: Log referral_fallback_triggered
    end
    AnalyticsService->>Cache: Update nudge:{customer_id}
    AnalyticsService->>PostHog: Log nudge_action
    AnalyticsService-->>Widget: Action Recorded (OK)
    Widget-->>Customer: Display Confirmation (i18next, NudgeBanner.tsx, aria-label="Nudge action confirmation", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Partitioned nudge_events (I20), AES-256 customer_id
    Note right of AnalyticsService: Multilingual title, description, Loki + Grafana logging
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Customer Widget: RFM Segment Preview (Phase 2, US-MD12, Updated)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Customer->>Widget: View RFM Segment Preview (RFMPreview.tsx, aria-label="View RFM segment preview")
    Widget->>AnalyticsService: gRPC /analytics.v1/PreviewRFMSegments (customer_id, merchant_id, Accept-Language)
    AnalyticsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>AnalyticsService: Token Valid
    AnalyticsService->>Cache: Check rfm:preview:{merchant_id} (Redis Stream)
    Cache-->>AnalyticsService: Return segment_data
    alt Cache Miss
        AnalyticsService->>DB: SELECT rfm_segment_counts, rfm_segment_deltas, customers.rfm_score
        DB-->>AnalyticsService: Segment Counts, Delta Updates
    end
    AnalyticsService->>Cache: Update rfm:preview:{merchant_id}, rfm:burst:{merchant_id} (Redis Stream, TTL 1h)
    AnalyticsService->>PostHog: Log rfm_preview_viewed
    AnalyticsService-->>Widget: Segment Preview Data (OK)
    Widget-->>Customer: Display Preview (Chart.js, i18next, RFMPreview.tsx, aria-label="RFM segment preview chart", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Queries rfm_segment_counts (I24a, Materialized View), rfm_segment_deltas
    Note right of AnalyticsService: Uses idx_rfm_segment_counts_merchant_id_segment_name, nestjs-circuit-breaker
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP

%% Customer Widget: Campaign Discount Redemption (Phase 3, US-BI4)
sequenceDiagram
    participant Customer
    participant Widget as Customer Widget (React)
    participant PointsService as points-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Shopify
    participant Klaviyo
    participant Postscript
    participant AWSSES as AWS SES
    participant PostHog
    Customer->>Widget: Redeem Campaign Discount (CampaignDiscount.tsx, aria-label="Redeem campaign discount")
    Widget->>PointsService: gRPC /points.v1/RedeemReward (customer_id, campaign_id, merchant_id, Accept-Language)
    PointsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>PointsService: Token Valid
    PointsService->>Cache: Check campaign:{campaign_id}
    Cache-->>PointsService: Return campaign_data
    alt Cache Miss
        PointsService->>DB: SELECT bonus_campaigns WHERE campaign_id, merchant_id
        DB-->>PointsService: Campaign Details (multiplier, conditions, status)
    end
    PointsService->>DB: SELECT customers.rfm_score WHERE customer_id
    DB-->>PointsService: RFM Score
    alt RFM Conditions Met and Campaign Active
        PointsService->>Shopify: Create Discount Code (Rust/Wasm)
        Shopify-->>PointsService: Discount Code
        PointsService->>DB: INSERT reward_redemptions (customer_id, merchant_id, campaign_id, discount_code, points_spent)
        DB-->>PointsService: Redemption ID
        PointsService->>DB: UPDATE customers SET points_balance = points_balance - points_spent
        DB-->>PointsService: Updated
        PointsService->>Cache: Update points:{customer_id}, campaign_discount:{campaign_id} (TTL 24h)
        alt Klaviyo/Postscript Available
            PointsService->>Klaviyo: Queue Notification (Bull, JSONB body, metadata: {"channel": "email"})
            PointsService->>Postscript: Queue Notification (Bull, metadata: {"channel": "sms"})
            Klaviyo-->>Customer: Discount Notification
            Postscript-->>Customer: Discount Notification
        else Fallback to AWS SES
            PointsService->>AWSSES: Queue Notification (Bull, JSONB body, metadata: {"channel": "email"})
            AWSSES-->>Customer: Discount Notification
            PointsService->>PostHog: Log referral_fallback_triggered
        end
        PointsService->>PostHog: Log campaign_discount_redeemed
        PointsService-->>Widget: Discount Code Issued (OK)
        Widget-->>Customer: Display Discount Code (i18next, CampaignDiscount.tsx, aria-label="Campaign discount code", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Conditions Not Met
        PointsService-->>Widget: Error (Invalid RFM/Status, 400)
        Widget-->>Customer: Display Error (i18next, ErrorModal.tsx, aria-label="Campaign conditions error")
    else Rate Limit Exceeded
        PointsService->>Cache: Enqueue rate_limit_queue:{merchant_id} (Bull)
        PointsService-->>Widget: Error (429, Exponential Backoff, nestjs-circuit-breaker)
        Widget-->>Customer: Display Rate Limit Error (i18next, ErrorModal.tsx, aria-label="Rate limit error")
    end
    Note right of DB: Partitioned reward_redemptions (I6a), bonus_campaigns (I17a)
    Note right of PointsService: Uses idx_bonus_campaigns_merchant_id_type, Loki + Grafana logging
    Note right of Widget: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Merchant Dashboard: Configuring Points Program (Phase 1, US-MD2)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant FrontendService as frontend-service
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: Update Points Rules (e.g., 10 points/$, PointsConfig.tsx, aria-label="Configure points rules")
    Dashboard->>FrontendService: gRPC /frontend.v1/UpdateContent (merchant_id, config, language, Accept-Language)
    FrontendService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>FrontendService: Token Valid, Role Authorized
    FrontendService->>AdminCoreService: gRPC /admin.v1/UpdateProgramSettings (merchant_id, config)
    AdminCoreService->>DB: UPDATE program_settings SET config = jsonb_set(config, '{points_per_dollar}', $1)
    DB-->>AdminCoreService: Updated
    AdminCoreService->>DB: UPDATE merchants SET language = $1 (CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    DB-->>AdminCoreService: Updated
    AdminCoreService->>Cache: Update config:{merchant_id}
    AdminCoreService->>PostHog: Log settings_updated
    AdminCoreService-->>FrontendService: Config Saved (OK)
    FrontendService-->>Dashboard: Config Saved (OK)
    Dashboard-->>Merchant: Display Success Message (i18next, SuccessModal.tsx, aria-label="Points config saved")
    Note right of DB: Updates program_settings (I7), merchants (I1)
    Note right of AdminCoreService: Multilingual config via JSONB, Loki + Grafana logging
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Merchant Dashboard: Viewing Analytics (Phase 1, 2, US-MD5)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: View RFM Analytics (AnalyticsDashboard.tsx, aria-label="View RFM analytics")
    Dashboard->>AnalyticsService: gRPC /analytics.v1/GetAnalytics (merchant_id, start_date, end_date, Accept-Language)
    AnalyticsService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>AnalyticsService: Token Valid, Role Authorized
    AnalyticsService->>Cache: Check analytics:{merchant_id}
    Cache-->>AnalyticsService: Return analytics_data
    alt Cache Miss
        AnalyticsService->>DB: SELECT customer_segments, customers.rfm_score, rfm_segment_counts, rfm_segment_deltas
        DB-->>AnalyticsService: Segment Data (language->>'en')
    end
    AnalyticsService->>Cache: Update analytics:{merchant_id}, rfm:burst:{merchant_id} (Redis Stream, TTL 1h)
    AnalyticsService->>PostHog: Log analytics_viewed
    AnalyticsService-->>Dashboard: RFM Chart Data (OK)
    Dashboard-->>Merchant: Display Chart.js RFM Chart (i18next, AnalyticsDashboard.tsx, aria-label="RFM analytics chart", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Queries customer_segments (I9), rfm_segment_counts (I24a), rfm_segment_deltas
    Note right of AnalyticsService: Uses idx_rfm_segment_counts_merchant_id_segment_name, nestjs-circuit-breaker
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP

%% Merchant Dashboard: Managing Referrals Program (Phase 1, US-MD3)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant FrontendService as frontend-service
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: Configure Referral Settings (ReferralConfig.tsx, aria-label="Configure referral settings")
    Dashboard->>FrontendService: gRPC /frontend.v1/UpdateContent (merchant_id, sms_config, Accept-Language)
    FrontendService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>FrontendService: Token Valid, Role Authorized
    FrontendService->>AdminCoreService: gRPC /admin.v1/UpdateReferralConfig (merchant_id, sms_config)
    AdminCoreService->>DB: UPDATE program_settings SET config = jsonb_set(config, '{sms_config}', $1)
    DB-->>AdminCoreService: Updated
    AdminCoreService->>Cache: Update config:{merchant_id}
    AdminCoreService->>PostHog: Log referral_config_updated
    AdminCoreService-->>FrontendService: Config Saved (OK)
    FrontendService-->>Dashboard: Config Saved (OK)
    Dashboard-->>Merchant: Display Success Message (i18next, SuccessModal.tsx, aria-label="Referral config saved")
    Note right of DB: Updates program_settings (I7)
    Note right of AdminCoreService: Uses JSONB for config, Loki + Grafana logging
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Merchant Dashboard: Setting Up VIP Tiers (Phase 2, US-MD7)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant PostHog
    Merchant->>Dashboard: Create VIP Tier (e.g., Gold, $500, VIPTierConfig.tsx, aria-label="Create VIP tier")
    Dashboard->>AdminCoreService: gRPC /admin.v1/CreateVIPTier (merchant_id, threshold_value, perks, Accept-Language)
    AdminCoreService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>AdminCoreService: Token Valid, Role Authorized
    AdminCoreService->>DB: INSERT vip_tiers (merchant_id, name, threshold_value, perks)
    DB-->>AdminCoreService: Tier ID
    AdminCoreService->>PostHog: Log vip_tier_created
    AdminCoreService-->>Dashboard: Tier Created (OK)
    Dashboard-->>Merchant: Display Tier Details (i18next, VIPTierConfig.tsx, aria-label="VIP tier details", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Updates vip_tiers (I13)
    Note right of AdminCoreService: Multilingual perks via JSONB, Loki + Grafana logging
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Merchant Dashboard: Creating Bonus Campaigns (Phase 3, US-MD10)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: Create Campaign (e.g., Double Points, CampaignConfig.tsx, aria-label="Create bonus campaign")
    Dashboard->>AdminCoreService: gRPC /admin.v1/CreateCampaign (merchant_id, multiplier, dates, conditions, status, Accept-Language)
    AdminCoreService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>AdminCoreService: Token Valid, Role Authorized
    AdminCoreService->>DB: INSERT bonus_campaigns (merchant_id, name, type, multiplier, start_date, end_date, conditions, status)
    DB-->>AdminCoreService: Campaign ID
    AdminCoreService->>Cache: Update campaign:{campaign_id}
    AdminCoreService->>PostHog: Log campaign_created
    AdminCoreService-->>Dashboard: Campaign Created (OK)
    Dashboard-->>Merchant: Display Campaign Details (i18next, CampaignConfig.tsx, aria-label="Campaign details", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Partitioned bonus_campaigns (I17a)
    Note right of AdminCoreService: Uses idx_bonus_campaigns_merchant_id_type, Loki + Grafana logging
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Merchant Dashboard: Configuring Notification Templates (Phase 2, US-MD8)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant FrontendService as frontend-service
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: Configure Notification Template (e.g., Referral Email, TemplateConfig.tsx, aria-label="Configure notification template")
    Dashboard->>FrontendService: gRPC /frontend.v1/UpdateContent (merchant_id, template_type, body, Accept-Language)
    FrontendService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>FrontendService: Token Valid, Role Authorized
    FrontendService->>AdminCoreService: gRPC /admin.v1/UpdateEmailTemplate (merchant_id, template_type, body)
    AdminCoreService->>DB: UPDATE email_templates SET body = $1 (CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    DB-->>AdminCoreService: Updated
    AdminCoreService->>Cache: Update template:{merchant_id}:{template_type}
    AdminCoreService->>PostHog: Log template_updated
    AdminCoreService-->>FrontendService: Template Saved (OK)
    FrontendService-->>Dashboard: Template Saved (OK)
    Dashboard-->>Merchant: Display Success Message (i18next, SuccessModal.tsx, aria-label="Template saved")
    Note right of DB: Updates email_templates (I14)
    Note right of AdminCoreService: Multilingual body via JSONB, Loki + Grafana logging
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Merchant Dashboard: Customer Import (Phase 3, US-BI3)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: Upload Customer CSV (CustomerImport.tsx, aria-label="Upload customer CSV")
    Dashboard->>AdminCoreService: gRPC /admin.v1/ImportCustomers (merchant_id, csv_data, Accept-Language)
    AdminCoreService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>AdminCoreService: Token Valid, Role Authorized
    AdminCoreService->>DB: INSERT customers (merchant_id, email, points_balance)
    DB-->>AdminCoreService: Customer IDs
    AdminCoreService->>DB: INSERT points_transactions (customer_id, merchant_id, type="import", points)
    DB-->>AdminCoreService: Transaction IDs
    AdminCoreService->>DB: INSERT import_logs (merchant_id, success_count, fail_count, fail_reason)
    DB-->>AdminCoreService: Log ID
    AdminCoreService->>DB: INSERT audit_logs (admin_user_id, action="customer_import", metadata)
    DB-->>AdminCoreService: Log ID
    AdminCoreService->>Cache: Update import:{merchant_id}
    AdminCoreService->>PostHog: Log customer_import_completed
    AdminCoreService-->>Dashboard: Import Success (OK)
    Dashboard-->>Merchant: Display Import Summary (i18next, CustomerImport.tsx, aria-label="Customer import summary", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Updates customers (I2), points_transactions (I3a), import_logs (I22), audit_logs (I12)
    Note right of AdminCoreService: Uses TypeORM transaction, Loki + Grafana logging
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Merchant Dashboard: Automate Lifecycle Rewards (Phase 3, US-MD19, Updated)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant AdminCoreService as admin-core-service
    participant ShopifyFlow as Shopify Flow
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Klaviyo
    participant Postscript
    participant AWSSES as AWS SES
    participant PostHog
    Merchant->>Dashboard: Configure Lifecycle Campaign (LifecycleConfig.tsx, aria-label="Configure lifecycle campaign")
    Dashboard->>AdminCoreService: gRPC /admin.v1/CreateCampaign (merchant_id, rfm_segment, tier_change, reward_type, Accept-Language)
    AdminCoreService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>AdminCoreService: Token Valid, Role Authorized
    AdminCoreService->>DB: INSERT bonus_campaigns (merchant_id, name, rfm_segment, tier_change, reward_type, status)
    DB-->>AdminCoreService: Campaign ID
    AdminCoreService->>ShopifyFlow: Create Flow Template (RFM/Tier Trigger)
    ShopifyFlow-->>AdminCoreService: Template ID
    AdminCoreService->>DB: UPDATE bonus_campaigns SET flow_template_id = $1
    DB-->>AdminCoreService: Updated
    AdminCoreService->>Cache: Update campaign:{campaign_id}
    alt Klaviyo/Postscript Available
        AdminCoreService->>Klaviyo: Queue Notification (Bull, JSONB body, metadata: {"channel": "email"})
        AdminCoreService->>Postscript: Queue Notification (Bull, metadata: {"channel": "sms"})
        Klaviyo-->>Customer: Campaign Notification
        Postscript-->>Customer: Campaign Notification
    else Fallback to AWS SES
        AdminCoreService->>AWSSES: Queue Notification (Bull, JSONB body, metadata: {"channel": "email"})
        AWSSES-->>Customer: Campaign Notification
        AdminCoreService->>PostHog: Log referral_fallback_triggered
    end
    AdminCoreService->>PostHog: Log lifecycle_campaign_triggered
    AdminCoreService-->>Dashboard: Campaign Created (OK)
    Dashboard-->>Merchant: Display Campaign Details (i18next, LifecycleConfig.tsx, aria-label="Lifecycle campaign details", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Partitioned bonus_campaigns (I17a)
    Note right of AdminCoreService: Uses idx_bonus_campaigns_merchant_id_type, Loki + Grafana logging
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent triggers, OWASP ZAP, Jest/Cypress tests

%% Merchant Dashboard: View Segment Benchmarking (Phase 3, US-MD20)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: View Benchmarks (BenchmarkDashboard.tsx, aria-label="View segment benchmarks")
    Dashboard->>AnalyticsService: gRPC /analytics.v1/GetSegmentBenchmarks (merchant_id, segment_type, Accept-Language)
    AnalyticsService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>AnalyticsService: Token Valid, Role Authorized
    AnalyticsService->>Cache: Check benchmarks:{merchant_id}
    Cache-->>AnalyticsService: Return benchmark_data
    alt Cache Miss
        AnalyticsService->>DB: SELECT rfm_benchmarks, rfm_segment_counts, rfm_segment_deltas WHERE merchant_id
        DB-->>AnalyticsService: Benchmark Data (industry_avg, segment_counts)
    end
    AnalyticsService->>Cache: Update benchmarks:{merchant_id}, rfm:burst:{merchant_id} (Redis Stream, TTL 1h)
    AnalyticsService->>PostHog: Log benchmarks_viewed
    AnalyticsService-->>Dashboard: Benchmark Data (OK)
    Dashboard-->>Merchant: Display Chart.js Bar Chart (i18next, BenchmarkDashboard.tsx, aria-live="Segment benchmark data available", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    Note right of DB: Queries rfm_benchmarks (I27a, anonymized), rfm_segment_counts (I24a), rfm_segment_deltas
    Note right of AnalyticsService: Uses idx_rfm_benchmarks_merchant_id, nestjs-circuit-breaker
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP, Jest/Cypress tests

%% Merchant Dashboard: A/B Test Nudges (Phase 3, US-MD21)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: Configure A/B Test (NudgeABTest.tsx, aria-label="Configure nudge A/B test")
    Dashboard->>AnalyticsService: gRPC /analytics.v1/ConfigureNudgeABTest (merchant_id, variant_config, Accept-Language)
    AnalyticsService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>AnalyticsService: Token Valid, Role Authorized
    alt Feature Flag rfm_nudges Enabled
        AnalyticsService->>DB: UPDATE program_settings SET ab_tests = jsonb_set(ab_tests, '{variant_config}', $1)
        DB-->>AnalyticsService: Updated
        AnalyticsService->>DB: SELECT nudge_events WHERE merchant_id, ab_test_id
        DB-->>AnalyticsService: Test Results
        AnalyticsService->>Cache: Update nudge_ab:{merchant_id}
        AnalyticsService->>PostHog: Log nudge_ab_tested
        AnalyticsService-->>Dashboard: Test Configured, Results (OK)
        Dashboard-->>Merchant: Display Test Results (Chart.js, i18next, NudgeABTest.tsx, aria-label="Nudge A/B test results", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Feature Flag Disabled
        AnalyticsService-->>Dashboard: Feature Unavailable (403)
        Dashboard-->>Merchant: Display Error (i18next, ErrorModal.tsx, aria-label="Feature unavailable")
    end
    Note right of DB: Updates program_settings (I7), nudge_events (I20)
    Note right of AnalyticsService: Uses JSONB for variant_config, Loki + Grafana logging
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent interactions, OWASP ZAP, Jest/Cypress tests

%% Merchant Dashboard: Identify Churn Risk Customers (Phase 3, US-MD22)
sequenceDiagram
    participant Merchant
    participant Dashboard as Merchant Dashboard (React)
    participant AnalyticsService as analytics-service
    participant xAIAPI as xAI API
    participant ShopifyFlow as Shopify Flow
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Merchant->>Dashboard: View Churn Risk (ChurnRiskDashboard.tsx, aria-label="View churn risk customers")
    Dashboard->>AnalyticsService: gRPC /analytics.v1/GetChurnRisk (merchant_id, Accept-Language)
    AnalyticsService->>Shopify: Validate OAuth Token, Check staff_roles (GraphQL, 50 points/s)
    Shopify-->>AnalyticsService: Token Valid, Role Authorized
    alt Feature Flag rfm_advanced Enabled
        AnalyticsService->>DB: SELECT rfm_segment_counts, rfm_segment_deltas WHERE segment='At-Risk', monetary > 2x AOV
        DB-->>AnalyticsService: At-Risk Customers
        AnalyticsService->>xAIAPI: Predict Churn Risk (customer_ids, merchant_id)
        xAIAPI-->>AnalyticsService: Churn Probabilities
        AnalyticsService->>ShopifyFlow: Create Action Template (At-Risk Trigger)
        ShopifyFlow-->>AnalyticsService: Template ID
        AnalyticsService->>Cache: Update churn_risk:{merchant_id}, rfm:burst:{merchant_id} (Redis Stream, TTL 1h)
        AnalyticsService->>PostHog: Log churn_risk_viewed
        AnalyticsService-->>Dashboard: At-Risk List (OK)
        Dashboard-->>Merchant: Display At-Risk Customers (i18next, ChurnRiskDashboard.tsx, aria-label="Churn risk customer list", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Feature Flag Disabled
        AnalyticsService-->>Dashboard: Feature Unavailable (403)
        Dashboard-->>Merchant: Display Error (i18next, ErrorModal.tsx, aria-label="Feature unavailable")
    end
    Note right of DB: Queries rfm_segment_counts (I24a), rfm_segment_deltas
    Note right of AnalyticsService: Integrates xAI API for churn prediction, nestjs-circuit-breaker
    Note right of Dashboard: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP, Jest/Cypress tests

%% Admin Module: Viewing Merchant Overview (Phase 1, US-AM1)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant PostHog
    Admin->>AdminModule: View Overview (MerchantOverview.tsx, aria-label="View merchant overview")
    AdminModule->>AdminCoreService: gRPC /admin.v1/GetOverview (admin_id, Accept-Language)
    AdminCoreService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AdminCoreService: Role (e.g., superadmin)
    alt Role Authorized
        AdminCoreService->>DB: SELECT merchants, usage_records, points_transactions
        DB-->>AdminCoreService: Metrics (merchant_count, points_issued)
        AdminCoreService->>PostHog: Log overview_viewed
        AdminCoreService-->>AdminModule: Overview Data (OK)
        AdminModule-->>Admin: Display Metrics (i18next, MerchantOverview.tsx, aria-label="Merchant overview metrics", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AdminCoreService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    end
    Note right of DB: Queries merchants (I1), usage_records (I22), points_transactions (I3a)
    Note right of AdminCoreService: RBAC via admin_users.metadata, Loki + Grafana logging
    Note right of AdminModule: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP

%% Admin Module: Adjusting Merchant Points (Phase 1, US-AM2)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AdminCoreService as admin-core-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Admin->>AdminModule: Adjust Points (PointsAdjust.tsx, aria-label="Adjust merchant points")
    AdminModule->>AdminCoreService: gRPC /admin.v1/AdjustPoints (admin_id, customer_id, merchant_id, points, Accept-Language)
    AdminCoreService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AdminCoreService: Role (e.g., superadmin)
    alt Role Authorized
        AdminCoreService->>DB: INSERT points_transactions (customer_id, merchant_id, type="adjust", points)
        DB-->>AdminCoreService: Transaction ID
        AdminCoreService->>DB: UPDATE customers SET points_balance = points_balance + points
        DB-->>AdminCoreService: Updated
        AdminCoreService->>DB: INSERT audit_logs (admin_user_id, action="points_adjust", metadata)
        DB-->>AdminCoreService: Log ID
        AdminCoreService->>Cache: Update points:{customer_id}
        AdminCoreService->>PostHog: Log points_adjusted
        AdminCoreService-->>AdminModule: Adjustment Success (OK)
        AdminModule-->>Admin: Display Confirmation (i18next, PointsAdjust.tsx, aria-label="Points adjustment confirmation", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AdminCoreService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    end
    Note right of DB: Partitioned points_transactions (I3a), audit_logs (I12)
    Note right of AdminCoreService: Uses TypeORM transaction, Loki + Grafana logging
    Note right of AdminModule: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent requests, OWASP ZAP

%% Admin Module: Managing Integration Health (Phase 2, US-AM5)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AdminFeaturesService as admin-features-service
    participant DB as PostgreSQL
    participant Shopify
    participant PostHog
    Admin->>AdminModule: Check Integration Health (IntegrationHealth.tsx, aria-label="Check integration health")
    AdminModule->>AdminFeaturesService: gRPC /admin.v1/GetIntegrationHealth (admin_id, Accept-Language)
    AdminFeaturesService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AdminFeaturesService: Role (e.g., superadmin)
    alt Role Authorized
        AdminFeaturesService->>DB: SELECT integrations (merchant_id, type, status)
        DB-->>AdminFeaturesService: Integration Status
        AdminFeaturesService->>Shopify: Ping API (OAuth check, GraphQL, 50 points/s)
        Shopify-->>AdminFeaturesService: Status Response
        AdminFeaturesService->>PostHog: Log integration_health_checked
        AdminFeaturesService-->>AdminModule: Health Report (e.g., Shopify: OK) (OK)
        AdminModule-->>Admin: Display Integration Status (i18next, IntegrationHealth.tsx, aria-label="Integration health status", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AdminFeaturesService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    end
    Note right of DB: Queries integrations (I16)
    Note right of AdminFeaturesService: Handles 429 rate limits, nestjs-circuit-breaker, Loki + Grafana logging
    Note right of AdminModule: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP

%% Admin Module: Exporting RFM Segments (Phase 3, US-AM7)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant PostHog
    Admin->>AdminModule: Export RFM Segments (RFMExport.tsx, aria-label="Export RFM segments")
    AdminModule->>AnalyticsService: gRPC /analytics.v1/ExportAnalytics (admin_id, merchant_id, Accept-Language)
    AnalyticsService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AnalyticsService: Role (e.g., superadmin)
    alt Role Authorized
        AnalyticsService->>DB: SELECT customer_segments, customers.rfm_score, rfm_segment_counts, rfm_segment_deltas
        DB-->>AnalyticsService: Segment Data (language->>'en')
        AnalyticsService->>PostHog: Log rfm_exported
        AnalyticsService-->>AdminModule: CSV File (OK)
        AdminModule-->>Admin: Download CSV (i18next, RFMExport.tsx, aria-label="Download RFM segments CSV", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AnalyticsService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    end
    Note right of DB: Queries customer_segments (I9), rfm_segment_counts (I24a), rfm_segment_deltas
    Note right of AnalyticsService: Uses idx_rfm_segment_counts_merchant_id_segment_name, nestjs-circuit-breaker
    Note right of AdminModule: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP

%% Admin Module: Rate Limit Monitoring (Phase 2, US-AM11, Updated)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AdminFeaturesService as admin-features-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Klaviyo
    participant AWSSES as AWS SES
    participant AWSSNS as AWS SNS
    participant PostHog
    Admin->>AdminModule: Monitor Rate Limits (RateLimitMonitor.tsx, aria-label="Monitor rate limits")
    AdminModule->>AdminFeaturesService: gRPC /admin.v1/GetRateLimits (admin_id, merchant_id, Accept-Language)
    AdminFeaturesService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AdminFeaturesService: Role (e.g., superadmin)
    alt Role Authorized
        AdminFeaturesService->>DB: SELECT api_logs WHERE status_code = 429
        DB-->>AdminFeaturesService: Rate Limit Violations
        AdminFeaturesService->>DB: SELECT merchants.rate_limit_threshold WHERE merchant_id
        DB-->>AdminFeaturesService: Threshold (e.g., {"requests_per_hour": 1000})
        AdminFeaturesService->>Cache: Check rate_limit_queue:{merchant_id} (Bull)
        Cache-->>AdminFeaturesService: Queue Status
        AdminFeaturesService->>Cache: Update rate_limit:{merchant_id}
        alt Rate Limit Breached
            AdminFeaturesService->>Klaviyo: Notify Admins (Bull, JSONB body, metadata: {"channel": "email"})
            AdminFeaturesService->>AWSSES: Notify Admins (Bull, JSONB body, metadata: {"channel": "email"})
            AdminFeaturesService->>AWSSNS: Alert Admins (rate_limit_exceeded)
        end
        AdminFeaturesService->>PostHog: Log rate_limit_viewed
        AdminFeaturesService-->>AdminModule: Violations Report (OK)
        AdminModule-->>Admin: Display Report (i18next, RateLimitMonitor.tsx, aria-label="Rate limit violations report", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AdminFeaturesService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    end
    Note right of DB: Partitioned api_logs (I11a)
    Note right of AdminFeaturesService: Uses idx_api_logs_status_code, rate_limit_threshold, Loki + Grafana logging
    Note right of AdminModule: RTL support for ar, he, Lighthouse CI 90+, k6 5,000 concurrent views, OWASP ZAP

%% Admin Module: Manage Multi-Tenant Accounts (Phase 3, US-AM14)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AdminCoreService as admin-core-service
    participant AuthService as auth-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Admin->>AdminModule: Link Stores, Assign RBAC (MultiTenantConfig.tsx, aria-label="Manage multi-tenant accounts")
    AdminModule->>AdminCoreService: gRPC /admin.v1/UpdateMultiTenantConfig (admin_id, group_id, merchant_ids, rbac_roles, Accept-Language)
    AdminCoreService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AdminCoreService: Role (e.g., superadmin)
    alt Role Authorized
        AdminCoreService->>DB: UPDATE merchants SET multi_tenant_group_id = $1 WHERE merchant_id IN ($2)
        DB-->>AdminCoreService: Updated
        AdminCoreService->>AuthService: gRPC /auth.v1/UpdateMultiTenantConfig (group_id, rbac_roles)
        AuthService->>DB: UPDATE admin_users SET metadata = jsonb_set(metadata, '{rbac_scopes}', $1)
        DB-->>AuthService: Updated
        AuthService->>Cache: Update multi_tenant:group:{group_id}
        AuthService->>PostHog: Log multi_tenant_updated
        AuthService-->>AdminCoreService: Config Updated (OK)
        AdminCoreService-->>AdminModule: Config Updated (OK)
        AdminModule-->>Admin: Display Confirmation (i18next, MultiTenantConfig.tsx, aria-label="Multi-tenant config updated", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AdminCoreService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    end
    Note right of DB: Updates merchants (I1), admin_users.metadata (I10a, AES-256)
    Note right of AdminCoreService: RBAC via admin_users.metadata, Loki + Grafana logging
    Note right of AdminModule: RTL support for ar, he, Lighthouse CI 90+, k6 1,000 concurrent updates, OWASP ZAP, Jest/Cypress tests

%% Admin Module: Replay and Undo Customer Actions (Phase 3, US-AM15, Updated)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AdminFeaturesService as admin-features-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Admin->>AdminModule: Replay/Undo Actions (ActionReplay.tsx, aria-label="Replay customer journey")
    AdminModule->>AdminFeaturesService: gRPC /admin.v1/GetCustomerJourney (admin_id, customer_id, merchant_id, action_type, Accept-Language)
    AdminFeaturesService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AdminFeaturesService: Role (e.g., superadmin)
    alt Role Authorized
        AdminFeaturesService->>DB: SELECT points_transactions, reward_redemptions, audit_logs, rfm_segment_deltas WHERE customer_id, merchant_id
        DB-->>AdminFeaturesService: Journey Data (points, rewards, audit, RFM deltas)
        alt Undo Action
            AdminFeaturesService->>DB: INSERT points_transactions (customer_id, merchant_id, type="adjust", points=-points)
            DB-->>AdminFeaturesService: Transaction ID
            AdminFeaturesService->>DB: UPDATE customers SET points_balance = points_balance - points
            DB-->>AdminFeaturesService: Updated
            AdminFeaturesService->>DB: INSERT audit_logs (admin_user_id, action="undo_action", metadata)
            DB-->>AdminFeaturesService: Log ID
            AdminFeaturesService->>Cache: Update points:{customer_id}, rfm:burst:{merchant_id} (Redis Stream, TTL 1h)
            AdminFeaturesService->>PostHog: Log action_undone
        else Replay Action
            AdminFeaturesService->>DB: INSERT points_transactions (customer_id, merchant_id, type="replay", points)
            DB-->>AdminFeaturesService: Transaction ID
            AdminFeaturesService->>DB: UPDATE customers SET points_balance = points_balance + points
            DB-->>AdminFeaturesService: Updated
            AdminFeaturesService->>DB: INSERT audit_logs (admin_user_id, action="replay_action", metadata)
            DB-->>AdminFeaturesService: Log ID
            AdminFeaturesService->>Cache: Update points:{customer_id}, rfm:burst:{merchant_id} (Redis Stream, TTL 1h)
            AdminFeaturesService->>PostHog: Log action_replayed
        end
        AdminFeaturesService->>Cache: Update journey:{customer_id}
        AdminFeaturesService->>PostHog: Log journey_viewed
        AdminFeaturesService-->>AdminModule: Journey Data, Action Status (OK)
        AdminModule-->>Admin: Display Journey/Undo Confirmation (i18next, ActionReplay.tsx, aria-label="Customer journey replayed or undone", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AdminFeaturesService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    end
    Note right of DB: Queries points_transactions (I3a), reward_redemptions (I6a), audit_logs (I12), rfm_segment_deltas; AES-256 for sensitive data
    Note right of AdminFeaturesService: Uses TypeORM transaction, nestjs-circuit-breaker, Loki + Grafana logging (median >1s, P95 >3s)
    Note right of AdminModule: RTL support for ar, he; Lighthouse CI 90+; k6 5,000 concurrent requests; OWASP ZAP; Jest/Cypress tests

%% Admin Module: Simulate RFM Segment Transitions (Phase 3, US-AM16, Updated)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AdminFeaturesService as admin-features-service
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Admin->>AdminModule: Simulate RFM Transition (RFMSimulation.tsx, aria-label="Simulate RFM transition")
    AdminModule->>AdminFeaturesService: gRPC /admin.v1/SimulateRFMTransition (admin_id, merchant_id, customer_id, simulation_params, Accept-Language)
    AdminFeaturesService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AdminFeaturesService: Role (e.g., superadmin)
    alt Role Authorized and Feature Flag rfm_simulation Enabled
        AdminFeaturesService->>AnalyticsService: gRPC /analytics.v1/SimulateRFM (merchant_id, customer_id, simulation_params)
        AnalyticsService->>DB: SELECT customers.rfm_score, rfm_segment_deltas, orders WHERE customer_id, merchant_id
        DB-->>AnalyticsService: Current RFM Score, Delta Updates, Order History
        AnalyticsService->>DB: INSERT simulation_logs (merchant_id, customer_id, simulation_params, result_segment)
        DB-->>AnalyticsService: Log ID
        AnalyticsService->>Cache: Update rfm_simulation:{merchant_id}:{customer_id} (TTL 1h)
        AnalyticsService->>PostHog: Log admin_event_simulated
        AnalyticsService-->>AdminFeaturesService: Simulated Segment (OK)
        AdminFeaturesService->>DB: INSERT audit_logs (admin_user_id, action="rfm_simulation", metadata)
        DB-->>AdminFeaturesService: Log ID
        AdminFeaturesService-->>AdminModule: Simulation Results (OK)
        AdminModule-->>Admin: Display Simulated Segment (i18next, RFMSimulation.tsx, aria-label="RFM simulation results", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AdminFeaturesService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    else Feature Flag Disabled
        AdminFeaturesService-->>AdminModule: Error (403 Feature Unavailable)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Feature unavailable")
    end
    Note right of DB: Queries customers (I2), rfm_segment_deltas, orders (I5), simulation_logs (I28); AES-256 for sensitive data
    Note right of AdminFeaturesService: Uses LaunchDarkly rfm_simulation, nestjs-circuit-breaker, Loki + Grafana logging
    Note right of AdminModule: RTL support for ar, he; Lighthouse CI 90+; k6 1,000 concurrent simulations; OWASP ZAP; Jest/Cypress tests

%% Backend Integration: Shopify POS Offline Mode Sync (Phase 2, US-BI2)
sequenceDiagram
    participant POS as Shopify POS
    participant PointsService as points-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    POS->>PointsService: gRPC /points.v1/SyncOfflineTransactions (merchant_id, offline_transactions, Accept-Language)
    PointsService->>Shopify: Validate OAuth Token (GraphQL, 50 points/s)
    Shopify-->>PointsService: Token Valid
    PointsService->>DB: INSERT points_transactions (customer_id, merchant_id, type="offline_earn", points, metadata)
    DB-->>PointsService: Transaction IDs
    PointsService->>DB: UPDATE customers SET points_balance = points_balance + points
    DB-->>PointsService: Updated
    PointsService->>Cache: Update points:{customer_id}
    PointsService->>PostHog: Log offline_sync_completed
    PointsService-->>POS: Sync Success (OK)
    Note right of DB: Partitioned points_transactions (I3a); metadata stores offline_txn_id
    Note right of PointsService: Handles 429 rate limits, nestjs-circuit-breaker, Loki + Grafana logging
    Note right of POS: Supports multilingual receipts (CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))

%% Backend Integration: Square POS Sync (Phase 3, US-BI6, New)
sequenceDiagram
    participant Admin
    participant AdminModule as Admin Module (React)
    participant AdminFeaturesService as admin-features-service
    participant Square as Square POS
    participant DB as PostgreSQL
    participant Cache as Redis
    participant PostHog
    Admin->>AdminModule: Trigger Square Sync (SquareSync.tsx, aria-label="Trigger Square POS sync")
    AdminModule->>AdminFeaturesService: gRPC /admin.v1/SyncSquarePOS (admin_id, merchant_id, Accept-Language)
    AdminFeaturesService->>DB: SELECT admin_users.metadata WHERE id = admin_id
    DB-->>AdminFeaturesService: Role (e.g., superadmin)
    alt Role Authorized
        AdminFeaturesService->>Square: Fetch Transactions (/v2/orders, OAuth)
        Square-->>AdminFeaturesService: Transaction Data (order_id, total, customer_id)
        AdminFeaturesService->>DB: INSERT points_transactions (customer_id, merchant_id, type="square_earn", points, metadata)
        DB-->>AdminFeaturesService: Transaction IDs
        AdminFeaturesService->>DB: UPDATE customers SET points_balance = points_balance + points
        DB-->>AdminFeaturesService: Updated
        AdminFeaturesService->>DB: INSERT audit_logs (admin_user_id, action="square_sync", metadata)
        DB-->>AdminFeaturesService: Log ID
        AdminFeaturesService->>Cache: Update points:{customer_id}
        AdminFeaturesService->>PostHog: Log square_sync_triggered
        AdminFeaturesService-->>AdminModule: Sync Success (OK)
        AdminModule-->>Admin: Display Sync Confirmation (i18next, SquareSync.tsx, aria-label="Square sync confirmation", CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL))
    else Unauthorized
        AdminFeaturesService-->>AdminModule: Error (401 Unauthorized)
        AdminModule-->>Admin: Display Error (i18next, ErrorModal.tsx, aria-label="Unauthorized error")
    end
    Note right of DB: Partitioned points_transactions (I3a), audit_logs (I12); metadata stores square_order_id
    Note right of AdminFeaturesService: Uses /admin/integrations/square/sync endpoint, nestjs-circuit-breaker, Loki + Grafana logging
    Note right of AdminModule: RTL support for ar, he; Lighthouse CI 90+; k6 1,000 concurrent syncs; OWASP ZAP; Jest/Cypress tests

%% Backend Integration: RFM Score Update (Phase 2, US-BI5, Updated)
sequenceDiagram
    participant Cron as Cron Job (0 1 * * *)
    participant AnalyticsService as analytics-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Shopify
    participant PostHog
    Cron->>AnalyticsService: Trigger RFM Update (Bull Queue, /analytics/v1/rfm/update)
    AnalyticsService->>Shopify: Fetch Orders (GraphQL, 50 points/s, incremental: last_updated_at)
    Shopify-->>AnalyticsService: Order Data (order_id, customer_id, total_price, created_at)
    AnalyticsService->>DB: SELECT customers.rfm_score, orders, rfm_segment_deltas WHERE merchant_id
    DB-->>AnalyticsService: Current Scores, Orders, Deltas
    AnalyticsService->>DB: UPDATE customers SET rfm_score = calculate_rfm(orders, NOW() - INTERVAL '90 days')
    DB-->>AnalyticsService: Updated
    AnalyticsService->>DB: INSERT rfm_segment_deltas (merchant_id, customer_id, segment, delta_timestamp)
    DB-->>AnalyticsService: Delta IDs
    AnalyticsService->>DB: REFRESH MATERIALIZED VIEW rfm_segment_counts
    DB-->>AnalyticsService: View Refreshed
    AnalyticsService->>Cache: Update rfm:{customer_id}, rfm:burst:{merchant_id} (Redis Stream, TTL 1h)
    AnalyticsService->>PostHog: Log rfm_updated
    Note right of DB: Queries customers (I2), orders (I5), rfm_segment_deltas, rfm_segment_counts (I24a); AES-256 for customer_id
    Note right of AnalyticsService: Uses idx_customers_rfm_score, idx_rfm_segment_counts_merchant_id_segment_name, nestjs-circuit-breaker, Loki + Grafana logging
    Note right of Cron: Scheduled via @nestjs/schedule, 0 1 * * * for daily refresh

%% Backend Integration: Sending Referral Notification (Phase 1, US-BI1, Updated)
sequenceDiagram
    participant ReferralsService as referrals-service
    participant DB as PostgreSQL
    participant Cache as Redis
    participant Klaviyo
    participant Postscript
    participant AWSSES as AWS SES
    participant PostHog
    ReferralsService->>DB: SELECT referral_links, referrals WHERE notification_status = 'pending'
    DB-->>ReferralsService: Referral Data
    alt Klaviyo/Postscript Available
        ReferralsService->>Klaviyo: Queue Notification (Bull, JSONB body, metadata: {"channel": "email", "language": "en"})
        ReferralsService->>Postscript: Queue Notification (Bull, metadata: {"channel": "sms", "language": "en"})
        Klaviyo-->>ReferralsService: Notification Sent
        Postscript-->>ReferralsService: Notification Sent
    else Fallback to AWS SES
        ReferralsService->>AWSSES: Queue Notification (Bull, JSONB body, metadata: {"channel": "email", "language": "en"})
        AWSSES-->>ReferralsService: Notification Sent
        ReferralsService->>PostHog: Log referral_fallback_triggered
    end
    ReferralsService->>DB: UPDATE referral_links SET notification_status = 'sent', notification_sent_at = CURRENT_TIMESTAMP
    DB-->>ReferralsService: Updated
    ReferralsService->>Cache: Update referral:{referral_code}
    ReferralsService->>PostHog: Log referral_notification_sent
    Note right of DB: Updates referral_links (I23), referrals (I4a); AES-256 for referral_code
    Note right of ReferralsService: Uses idx_referrals_notification_status, supports CHECK: en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar(RTL), ko, uk, hu, sv, he(RTL); Loki + Grafana logging
```


