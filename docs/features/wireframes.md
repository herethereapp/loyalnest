# LoyalNest App Wireframes

This document outlines the wireframes for the LoyalNest Shopify App’s UI components, aligning with `technical_specifications.md` (artifact_id: `05357ac3-e4bb-4cf3-a3e4-6cac7257f9e7`), `Sequence Diagrams.txt` (artifact_id: `478975db-7432-4070-826d-f9040af8fbd0`), `RFM.markdown` (artifact_id: `b4ca549b-7ffa-42c3-9db2-9a4a74151bdf`), and `deployment_infra.md` (artifact_id: `14f50504-d8f4-4de8-85fd-486716afc90b`). It covers the Customer Widget, Merchant Dashboard, and Admin Module (split into `AdminCore` and `AdminFeatures`) for Phases 1–3, supporting Shopify Plus merchants (50,000+ customers, 1,000 orders/hour). Wireframes use Shopify Polaris components, Tailwind CSS, i18next for 22-language support (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`; RTL for `ar`, `he`), and ensure accessibility (ARIA labels, Lighthouse CI score 90+). Each wireframe references user stories (`user_stories.md`, artifact_id: `81a2ee82-2fa7-4cf7-9709-04c793810b63`) and sequence diagram flows.

## Customer Widget Wireframes (Phases 1–3)

### Points Balance (US-CW1)
**Description**: Displays customer’s current points balance.  
**Components**:  
- **Polaris `Badge`**: Shows points (e.g., “500 Stars”), Tailwind `text-lg font-bold text-green-600`.  
- **Polaris `Banner`**: Errors (e.g., “Unable to load balance”), `status="critical"`.  
- **Container**: Tailwind `p-4 bg-white rounded-lg shadow-md`.  
**Layout**:  
- Centered `Badge` with points balance.  
- Error `Banner` below if API fails (401/429).  
**Accessibility**: ARIA (`aria-label="View points balance"`, `aria-live="polite"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Queries `/points.v1/GetPointsBalance` (G1e), updates via Shopify webhook (`orders/create`, H1b), caches in Redis (`points:{customer_id}`, J2). PostHog event (`points_balance_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`PointsBalance.tsx`), Cypress E2E, k6 (10,000 requests), Lighthouse CI (90+ score), OWASP ZAP.  

### Purchase Confirmation (US-CW2)
**Description**: Shows points earned post-purchase.  
**Components**:  
- **Polaris `Banner`**: Confirmation (e.g., “You earned 100 points!”), `status="success"`, Tailwind `animate-fade-in duration-300`.  
- **Polaris `Button`**: “View Balance”, Tailwind `bg-blue-500 hover:bg-blue-600`.  
- **Container**: Tailwind `p-4 bg-gray-50 rounded-lg`.  
**Layout**:  
- Top `Banner` with confirmation.  
- Bottom `Button` linking to Points Balance.  
**Accessibility**: ARIA (`aria-label="Points earned notification"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Triggered by `/points.v1/EarnPoints` (G1a) via Shopify webhook (`orders/create`, H1b), logs to PostHog (`points_earned`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`PurchaseConfirmation.tsx`), Cypress E2E, k6 (10,000 orders/hour).  

### Rewards Redemption (US-CW3)
**Description**: Allows customers to redeem points for rewards (discounts, free shipping).  
**Components**:  
- **Polaris `Card`**: Lists rewards from `rewards` table, Tailwind `grid搜

System: I notice you want me to update the `wireframes.md` document to reflect changes in major project documents, including `technical_specifications.md`, `Sequence Diagrams.txt`, `RFM.markdown`, and the revised `deployment_infra.md`. The updates involve incorporating the split Admin Module (`AdminCore`, `AdminFeatures`), enhanced RFM features (incremental updates, simulation logs, `rfm_segment_deltas`), Square POS integration, 22-language support, and VPS deployment considerations. Below is the updated `wireframes.md`, retaining the original structure and aligning with the provided project documents. The artifact uses a new UUID (`a2b3c4d5-e6f7-4a8b-9c0d-e1f2a3b4c5d6`) as it’s a distinct revision, ensuring compatibility with the VPS environment, updated project plan, and Phase 3 features.

<xaiArtifact artifact_id="c9815740-583b-4de5-b508-58344c0bf4a6" artifact_version_id="909ac005-04da-47be-84f7-b1984fc94a6c" title="wireframes.md" contentType="text/markdown">

# LoyalNest App Wireframes

This document outlines the wireframes for the LoyalNest Shopify App’s UI components, aligning with `technical_specifications.md` (artifact_id: `05357ac3-e4bb-4cf3-a3e4-6cac7257f9e7`), `Sequence Diagrams.txt` (artifact_id: `478975db-7432-4070-826d-f9040af8fbd0`), `RFM.markdown` (artifact_id: `b4ca549b-7ffa-42c3-9db2-9a4a74151bdf`), and `deployment_infra.md` (artifact_id: `14f50504-d8f4-4de8-85fd-486716afc90b`). It covers the Customer Widget, Merchant Dashboard, and Admin Module (split into `AdminCore` and `AdminFeatures`) for Phases 1–3, supporting Shopify Plus merchants (50,000+ customers, 1,000 orders/hour). Wireframes use Shopify Polaris components, Tailwind CSS, i18next for 22-language support (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`; RTL for `ar`, `he`), and ensure accessibility (ARIA labels, Lighthouse CI score 90+). Each wireframe references user stories (`user_stories.md`, artifact_id: `81a2ee82-2fa7-4cf7-9709-04c793810b63`) and sequence diagram flows.

## Customer Widget Wireframes (Phases 1–3)

### Points Balance (US-CW1)
**Description**: Displays customer’s current points balance.  
**Components**:  
- **Polaris `Badge`**: Shows points (e.g., “500 Stars”), Tailwind `text-lg font-bold text-green-600`.  
- **Polaris `Banner`**: Errors (e.g., “Unable to load balance”), `status="critical"`.  
- **Container**: Tailwind `p-4 bg-white rounded-lg shadow-md`.  
**Layout**:  
- Centered `Badge` with points balance.  
- Error `Banner` below if API fails (401/429).  
**Accessibility**: ARIA (`aria-label="View points balance"`, `aria-live="polite"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Queries `/points.v1/GetPointsBalance` (G1e), updates via Shopify webhook (`orders/create`, H1b), caches in Redis (`points:{customer_id}`, J2). PostHog event (`points_balance_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`PointsBalance.tsx`), Cypress E2E, k6 (10,000 requests), Lighthouse CI (90+ score), OWASP ZAP.  

### Purchase Confirmation (US-CW2)
**Description**: Shows points earned post-purchase.  
**Components**:  
- **Polaris `Banner`**: Confirmation (e.g., “You earned 100 points!”), `status="success"`, Tailwind `animate-fade-in duration-300`.  
- **Polaris `Button`**: “View Balance”, Tailwind `bg-blue-500 hover:bg-blue-600`.  
- **Container**: Tailwind `p-4 bg-gray-50 rounded-lg`.  
**Layout**:  
- Top `Banner` with confirmation.  
- Bottom `Button` linking to Points Balance.  
**Accessibility**: ARIA (`aria-label="Points earned notification"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Triggered by `/points.v1/EarnPoints` (G1a) via Shopify webhook (`orders/create`, H1b), logs to PostHog (`points_earned`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`PurchaseConfirmation.tsx`), Cypress E2E, k6 (10,000 orders/hour).  

### Rewards Redemption (US-CW3)
**Description**: Allows customers to redeem points for rewards (discounts, free shipping).  
**Components**:  
- **Polaris `Card`**: Lists rewards from `rewards` table, Tailwind `grid grid-cols-2 gap-4`.  
- **Polaris `Modal`**: Shows discount code post-redemption.  
- **Polaris `Banner`**: Errors (e.g., “Insufficient points”).  
- **Polaris `Button`**: “Redeem”, Tailwind `bg-blue-500 hover:bg-blue-600`.  
**Layout**:  
- Grid of `Card` components for rewards (title, points cost, description).  
- `Modal` for confirmation with copyable discount code.  
- Error `Banner` at top if redemption fails.  
**Accessibility**: ARIA (`aria-label="Redeem points"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Calls `/points.v1/RedeemReward` (G1b), updates `reward_redemptions` (I6), logs to PostHog (`points_redeemed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`RewardsRedemption.tsx`), Cypress E2E, k6 (5,000 redemptions).  

### Referral Popup (US-CW4, US-CW5)
**Description**: Enables customers to share referral links and view rewards confirmation.  
**Components**:  
- **Polaris `Modal`**: Sharing options (SMS, email, social), Tailwind `p-4`.  
- **Polaris `Button`**: “Share via SMS/Email/Social” (social in Phase 2), Tailwind `bg-green-500`.  
- **Polaris `Banner`**: Confirmation (e.g., “Referral sent!”) or errors.  
**Layout**:  
- `Modal` with sharing buttons and copyable referral link.  
- `Banner` for confirmation or errors at top.  
**Accessibility**: ARIA (`aria-label="Send referral invite"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Calls `/referrals.v1/CreateReferral` (G2a), `/referrals.v1/CompleteReferral` (G2b), logs to PostHog (`referral_created`, `referral_completed`, L). Fallback to AWS SES if Klaviyo/Postscript fails (H2c).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`ReferralPopup.tsx`), Cypress E2E, k6 (1,000 shares).  

### Referral Status Page (US-CW7)
**Description**: Shows detailed referral status (pending, completed).  
**Components**:  
- **Polaris `DataTable`**: Lists referrals (friend name, status, action), Tailwind `table-auto`.  
- **Polaris `ProgressBar`**: Visualizes referral progress.  
- **Polaris `Banner`**: Errors (e.g., “No referrals found”).  
**Layout**:  
- `DataTable` with columns: Name, Status, Action (e.g., “Signed Up”).  
- `ProgressBar` for visual status.  
- Error `Banner` at top if no data.  
**Accessibility**: ARIA (`aria-label="View referral status"`, `aria-live="polite"`), RTL for `ar`, `he`.  
**Interactions**: Queries `/referrals.v1/GetReferralStatus` (G2d), caches in Redis (`referral_status:{customer_id}`, J11), logs to PostHog (`referral_status_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`ReferralStatus.tsx`), Cypress E2E, k6 (5,000 views).  

### GDPR Request Form (US-CW8)
**Description**: Allows customers to submit GDPR/CCPA data access/deletion requests.  
**Components**:  
- **Polaris `Modal`**: Contains `Form` with `Select` (request type), `TextField` (details).  
- **Polaris `Button`**: “Submit Request”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Modal` with form fields and submit button.  
- `Banner` for confirmation (e.g., “Request submitted”) or errors.  
**Accessibility**: ARIA (`aria-label="Submit GDPR request"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Submits to `/admin.v1/ProcessGDPRRequest` (G4e), logs to `gdpr_requests` (I21), PostHog (`gdpr_request_submitted`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`GDPRForm.tsx`), Cypress E2E, k6 (1,000 requests), OWASP ZAP.  

### VIP Tier Dashboard (US-CW9)
**Description**: Displays VIP tier status and perks.  
**Components**:  
- **Polaris `Card`**: Shows tier (e.g., “Silver”), perks, Tailwind `p-4 bg-gray-50`.  
- **Polaris `Banner`**: Errors (e.g., “Tier data unavailable”).  
**Layout**:  
- `Card` with tier name, perks list, progress to next tier.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-label="View VIP perks"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/points.v1/GetVipTierStatus` (G1f), caches in Redis (`tier:{customer_id}`, J5), logs to PostHog (`vip_tier_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`VIPTier.tsx`), Cypress E2E, k6 (5,000 views).  

### Nudge Popup/Banner (US-CW10)
**Description**: Shows personalized RFM nudges (e.g., “Invite a friend!”).  
**Components**:  
- **Polaris `Banner` or `Modal`**: Nudge content, Tailwind `animate-fade-in duration-300`.  
- **Polaris `Button`**: “Dismiss” or action (e.g., “Shop Now”), Tailwind `bg-blue-500`.  
**Layout**:  
- `Banner` or `Modal` with nudge message and action/dismiss buttons.  
**Accessibility**: ARIA (`aria-label="Dismiss nudge"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/analytics.v1/GetNudges` (G3c), logs to `nudge_events` (I20), PostHog (`nudge_dismissed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`NudgeBanner.tsx`), Cypress E2E, k6 (5,000 nudges).  

### Badges Section (US-CW11)
**Description**: Displays earned gamification badges.  
**Components**:  
- **Polaris `Card`**: Lists badges, Tailwind `grid grid-cols-3 gap-4`.  
- **Polaris `Banner`**: Errors (e.g., “Action not eligible”).  
**Layout**:  
- Grid of `Card` components for badges (icon, title).  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-label="View badges"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/analytics.v1/AwardBadge`, logs to `gamification_achievements` (I18), PostHog (`badge_earned`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`BadgesSection.tsx`), Cypress E2E, k6 (5,000 actions).  

### Leaderboard Page (US-CW12)
**Description**: Shows customer’s rank on the leaderboard.  
**Components**:  
- **Polaris `Card`**: Displays rank (e.g., “#5 of 100”), Tailwind `p-4`.  
- **Polaris `Banner`**: Errors (e.g., “Leaderboard unavailable”).  
**Layout**:  
- `Card` with rank and leaderboard summary.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-label="View leaderboard"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/analytics.v1/GetLeaderboard` (G3d), caches in Redis (`leaderboard:{merchant_id}`, J6), logs to PostHog (`leaderboard_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`Leaderboard.tsx`), Cypress E2E, k6 (5,000 views).  

### Settings Panel (US-CW13)
**Description**: Allows language selection.  
**Components**:  
- **Polaris `Select`**: Language dropdown, Tailwind `w-full`.  
- **Polaris `Banner`**: Errors (e.g., “Language not supported”).  
**Layout**:  
- `Select` dropdown for language.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-label="Select language"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Queries `/frontend.v1/GetWidgetConfig` (G6b), persists in `localStorage` (J1), logs to PostHog (`language_selected`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`LanguageSelector.tsx`), Cypress E2E, Lighthouse CI (90+ score).  

### Sticky Bar (US-CW14)
**Description**: Promotes loyalty program with a CTA.  
**Components**:  
- **Polaris `Banner`**: Fixed top bar with CTA (e.g., “Earn 1 point/$!”), Tailwind `sm:hidden md:block fixed top-0`.  
- **Polaris `Button`**: “Join Now” or “Redeem”.  
**Layout**:  
- Fixed `Banner` at top with CTA and button.  
**Accessibility**: ARIA (`aria-label="Join loyalty program"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Queries `/frontend.v1/GetWidgetConfig` (G6b), logs to PostHog (`sticky_bar_clicked`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`StickyBar.tsx`), Cypress E2E, Lighthouse CI (90+ score).  

### Post-Purchase Widget (US-CW15)
**Description**: Shows points earned and referral CTA post-purchase.  
**Components**:  
- **Polaris `Card`**: Displays points and CTA, Tailwind `p-4 bg-gray-50`.  
- **Polaris `Button`**: “Share Referral”, Tailwind `bg-green-500`.  
- **Polaris `Banner`**: Errors (e.g., “Failed to load points”).  
**Layout**:  
- `Card` with points earned and referral CTA.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-label="View points earned"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/points.v1/GetEarnedPoints`, logs to PostHog (`post_purchase_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`PostPurchaseWidget.tsx`), Cypress E2E, k6 (5,000 views).  

### VIP Tier Progress (US-CW16)
**Description**: Shows progress to next VIP tier with recommended actions.  
**Components**:  
- **Polaris `Card`**: Displays tier, progress, actions, Tailwind `p-4`.  
- **Polaris `ProgressBar`**: Visualizes progress (e.g., “$100/$500”).  
- **Polaris `Banner`**: Errors (e.g., “Tier progress unavailable”).  
**Layout**:  
- `Card` with tier name, `ProgressBar`, and action list.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-label="View tier progress"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/points.v1/GetVipTierProgress` (G1g), caches in Redis (`tier_progress:{customer_id}`, J14), logs to PostHog (`tier_progress_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`TierProgress.tsx`), Cypress E2E, k6 (5,000 views).  

### Wallet Integration (US-CW17)
**Description**: Allows adding loyalty balance to Apple/Google Wallet.  
**Components**:  
- **Polaris `Button`**: “Add to Wallet”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Confirmation or errors (e.g., “Failed to add to wallet”).  
**Layout**:  
- `Button` for wallet pass generation.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Add to wallet"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Calls `/points.v1/GenerateWalletPass` (G1h), logs to `wallet_passes` (I26), PostHog (`wallet_pass_added`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`WalletIntegration.tsx`), Cypress E2E, k6 (5,000 requests).  

### POS Offline Interface (US-CW18, US-MD26)
**Description**: Allows customers/merchants to award/redeem points via Shopify POS in offline mode.  
**Components**:  
- **Polaris `Card`**: Displays points balance, actions, Tailwind `p-4`.  
- **Polaris `Button`**: “Award Points” or “Redeem Points”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Sync status (e.g., “Offline: Sync pending”), Tailwind `animate-fade-in`.  
**Layout**:  
- `Card` with balance and action buttons.  
- Top `Banner` for sync status.  
**Accessibility**: ARIA (`aria-label="Manage POS points"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Syncs via SQLite queue, calls `/points.v1/ProcessPOSAction` (G1i), logs to PostHog (`pos_offline_used`, `offline_sync_completed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`POSPage.tsx`), Cypress E2E (offline actions), k6 (1,000 transactions).  

## Merchant Dashboard Wireframes (Phases 1–3)

### Welcome Page (US-MD1)
**Description**: Guides merchants through setup tasks and displays congratulatory messages.  
**Components**:  
- **Polaris `Checklist`**: Lists setup tasks (e.g., “Configure RFM”), Tailwind `p-4`.  
- **Polaris `Banner`**: Congratulatory messages or errors.  
**Layout**:  
- `Checklist` with task list.  
- `Banner` at top for messages or errors.  
**Accessibility**: ARIA (`aria-label="Complete setup tasks"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/CompleteSetupTask` (G4a), logs to `onboarding_tasks` (I15), PostHog (`setup_task_completed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`WelcomePage.tsx`), Cypress E2E, k6 (1,000 views).  

### Points Program (US-MD2)
**Description**: Configures points earning and redemption settings.  
**Components**:  
- **Polaris `Form`**: Fields for points per dollar, redemption options, Tailwind `grid grid-cols-2`.  
- **Polaris `Button`**: “Save” or “Toggle Status”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with input fields and toggle switch.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure points program"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Updates `program_settings` (I7) via `/admin.v1/UpdatePointsProgram` (G4b), logs to PostHog (`points_configured`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`PointsProgram.tsx`), Cypress E2E, k6 (1,000 updates).  

### Referral Program (US-MD3)
**Description**: Configures referral program settings (SMS/email).  
**Components**:  
- **Polaris `Form`**: Fields for referral rewards, channels, Tailwind `grid grid-cols-2`.  
- **Polaris `Button`**: “Save” or “Toggle Status”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with input fields and toggle switch.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure referrals"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Updates `program_settings.config` (I7) via `/admin.v1/UpdateReferralsProgram` (G4c), logs to PostHog (`referrals_configured`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`ReferralsPage.tsx`), Cypress E2E, k6 (1,000 updates).  

### Customer List (US-MD4)
**Description**: Displays and searches customer data with RFM segments.  
**Components**:  
- **Polaris `TextField`**: Search by name/email, Tailwind `w-full`.  
- **Polaris `DataTable`**: Customer details (name, email, points, RFM segment), Tailwind `table-auto`.  
- **Polaris `Banner`**: Errors (e.g., “No customers found”).  
**Layout**:  
- `TextField` for search at top.  
- `DataTable` with customer list, including RFM segment.  
- Error `Banner` at top if no data.  
**Accessibility**: ARIA (`aria-label="Search customers"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/GetCustomers` (G4f), caches in Redis (`customers:page:{page}`, J3), logs to PostHog (`customer_list_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`CustomersPage.tsx`), Cypress E2E, k6 (5,000 customers).  

### Basic Analytics (US-MD5)
**Description**: Shows program metrics (members, points issued, RFM segments).  
**Components**:  
- **Polaris `Card`**: Chart.js bar chart for `rfm_segment_counts`, Tailwind `p-4`.  
- **Polaris `Badge`**: Metrics (e.g., “1,000 Members”), Tailwind `text-lg`.  
- **Polaris `Banner`**: Errors (e.g., “No analytics data”).  
**Layout**:  
- Grid of `Badge` components for metrics.  
- `Card` with RFM segment chart.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-live="Analytics data available"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Queries `/analytics.v1/GetAnalytics` (G3a), caches in Redis (`analytics:{merchant_id}`, J4), logs to PostHog (`analytics_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`AnalyticsPage.tsx`), Cypress E2E, k6 (5,000 views).  

### Store Settings (US-MD6)
**Description**: Configures store details and billing.  
**Components**:  
- **Polaris `Form`**: Fields for store name, billing plan, Tailwind `grid grid-cols-2`.  
- **Polaris `Button`**: “Save Settings”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with input fields and save button.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure store settings"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Updates `merchants` (I1) via `/admin.v1/UpdateSettings` (G4g), logs to PostHog (`settings_updated`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`SettingsPage.tsx`), Cypress E2E, k6 (1,000 updates).  

### On-Site Content (US-MD7)
**Description**: Customizes loyalty page and popups.  
**Components**:  
- **Polaris `Form`**: Fields for page content, popup settings, Tailwind `grid grid-cols-2`.  
- **Polaris `Card`**: Live preview of content.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` for content editing, `Card` for preview.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Customize content"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Updates `program_settings.branding` (I7) via `/admin.v1/UpdateContent` (G4i), logs to PostHog (`content_updated`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`ContentPage.tsx`), Cypress E2E, k6 (1,000 updates).  

### VIP Tiers (US-MD8)
**Description**: Configures VIP tier settings.  
**Components**:  
- **Polaris `Form`**: Fields for tiers, perks, Tailwind `grid grid-cols-2`.  
- **Polaris `Card`**: Preview of tier structure.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with tier settings, `Card` for preview.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure VIP tiers"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Updates `vip_tiers` (I9) via `/admin.v1/UpdateVIPTiers` (G4j), logs to PostHog (`vip_tiers_configured`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`VIPTiersPage.tsx`), Cypress E2E, k6 (1,000 updates).  

### Activity Logs (US-MD9)
**Description**: Displays points and referral activity logs.  
**Components**:  
- **Polaris `TextField` & `Select`**: Filters for customer/date, Tailwind `w-full`.  
- **Polaris `DataTable`**: Log entries from `audit_logs`, Tailwind `table-auto`.  
- **Polaris `Banner`**: Errors (e.g., “No logs found”).  
**Layout**:  
- Filters at top, `DataTable` with logs.  
- Error `Banner` at top if no data.  
**Accessibility**: ARIA (`aria-label="Filter logs"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/GetLogs` (G4d), caches in Redis (`logs:{merchant_id}`, J10), logs to PostHog (`logs_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`LogsPage.tsx`), Cypress E2E, k6 (5,000 views).  

### RFM Settings (US-MD10)
**Description**: Configures RFM thresholds with real-time preview.  
**Components**:  
- **Polaris `Form`**: Fields for recency, frequency, monetary thresholds, Tailwind `grid grid-cols-2`.  
- **Polaris `RangeSlider`**: Adjusts weights for RFM scoring.  
- **Polaris `Card`**: Chart.js bar chart for `rfm_segment_counts` preview.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with threshold inputs and sliders, `Card` for preview.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure RFM"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Updates `program_settings.config` (I7) via `/admin.v1/UpdateRFMConfig` (G4h), caches in Redis (`rfm:preview:{merchant_id}`, J9), logs to PostHog (`rfm_configured`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`RFMPage.tsx`), Cypress E2E, k6 (5,000 previews).  

### Checkout Extensions (US-MD11)
**Description**: Enables points display at checkout.  
**Components**:  
- **Polaris `Form`**: Toggle for checkout extensions, Tailwind `p-4`.  
- **Polaris `Card`**: Preview of checkout UI.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with toggle, `Card` for preview.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Toggle checkout extensions"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Updates `program_settings.config` (I7) via `/admin.v1/UpdateContent` (G4i), logs to PostHog (`checkout_extension_enabled`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`CheckoutPage.tsx`), Cypress E2E, k6 (5,000 updates).  

### Bonus Campaigns (US-MD12)
**Description**: Creates time-sensitive bonus campaigns.  
**Components**:  
- **Polaris `Form`**: Fields for campaign type, dates, multiplier, Tailwind `grid grid-cols-2`.  
- **Polaris `Button`**: “Create Campaign”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with campaign settings, `Button` to save.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Create campaign"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Saves to `bonus_campaigns` (I17) via `/points.v1/CreateCampaign` (G1d), logs to PostHog (`campaign_created`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`CampaignsPage.tsx`), Cypress E2E, k6 (5,000 campaigns).  

### Advanced Reports (US-MD13)
**Description**: Exports advanced analytics reports with RFM insights.  
**Components**:  
- **Polaris `Button`**: “Export CSV”, Tailwind `bg-blue-500`.  
- **Polaris `ProgressBar`**: Export progress.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Button` for export, `ProgressBar` for status.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Export report"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/analytics.v1/ExportAnalytics` (G3e), logs to `analytics_reports` (I16), PostHog (`report_exported`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`ReportsPage.tsx`), Cypress E2E, k6 (5,000 exports).  

### Sticky Bar Configuration (US-MD14)
**Description**: Configures sticky bar content.  
**Components**:  
- **Polaris `Form`**: Fields for bar content, Tailwind `grid grid-cols-2`.  
- **Polaris `Card`**: Live preview of bar.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` for content, `Card` for preview.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure sticky bar"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Updates `program_settings.sticky_bar` (I7) via `/admin.v1/UpdateContent` (G4i), logs to PostHog (`sticky_bar_configured`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`StickyBarPage.tsx`), Cypress E2E, k6 (5,000 updates).  

### Developer Toolkit (US-MD15)
**Description**: Configures metafields for integrations (e.g., Shopify, Square).  
**Components**:  
- **Polaris `Form`**: Fields for metafield settings, Tailwind `grid grid-cols-2`.  
- **Polaris `Button`**: “Save Settings”.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with metafield inputs, `Button` to save.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure metafields"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Updates `integrations.settings` (I10) via `/admin.v1/UpdateDeveloperSettings` (G4k), logs to PostHog (`metafields_configured`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`DeveloperPage.tsx`), Cypress E2E, k6 (1,000 updates).  

### Lifecycle Automation (US-MD19)
**Description**: Configures RFM/tier-based reward triggers.  
**Components**:  
- **Polaris `Form`**: Fields for triggers (e.g., “At-Risk → 100 points”), Tailwind `grid grid-cols-2`.  
- **Polaris `Select`**: RFM/tier options.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with trigger conditions and save button.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure lifecycle automation"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Saves to `bonus_campaigns` (I17) via `/points.v1/CreateCampaign` (G1d), logs to PostHog (`lifecycle_campaign_triggered`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`LifecycleAutomation.tsx`), Cypress E2E, k6 (5,000 triggers).  

### Segment Benchmarking (US-MD20)
**Description**: Shows RFM segment comparisons with industry benchmarks.  
**Components**:  
- **Polaris `Card`**: Chart.js bar chart for `rfm_segment_counts` vs. benchmarks, Tailwind `p-4`.  
- **Polaris `Banner`**: Errors (e.g., “No benchmark data”).  
**Layout**:  
- `Card` with Chart.js bar chart comparing segments.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-live="Segment benchmark data available"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/analytics.v1/GetSegmentBenchmarks` (G3g), caches in Redis (`benchmarks:{merchant_id}`, J16), logs to PostHog (`benchmarks_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`SegmentBenchmarking.tsx`), Cypress E2E, k6 (5,000 views).  

### Nudge A/B Testing (US-MD21)
**Description**: Configures and views A/B test results for nudges.  
**Components**:  
- **Polaris `Form`**: Fields for nudge variants, Tailwind `grid grid-cols-2`.  
- **Polaris `Card`**: Chart.js bar chart for results.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` for variant configuration.  
- `Card` with results chart.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Configure nudge A/B test"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Configures `program_settings.ab_tests` (I7) via `/analytics.v1/ConfigureNudgeABTest` (G3h), logs to PostHog (`nudge_ab_tested`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`NudgeABTest.tsx`), Cypress E2E, k6 (5,000 interactions).  

### Churn Risk Dashboard (US-MD22)
**Description**: Lists high-spending At-Risk customers based on RFM scores.  
**Components**:  
- **Polaris `DataTable`**: Customer details (ID, email, last order, RFM score), Tailwind `table-auto`.  
- **Polaris `Banner`**: Errors (e.g., “No at-risk customers”).  
**Layout**:  
- `DataTable` with customer list.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-label="View churn risk customers"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/analytics.v1/GetChurnRisk` (G3i), caches in Redis (`churn_risk:{merchant_id}`, J18), logs to PostHog (`churn_risk_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`ChurnRiskDashboard.tsx`), Cypress E2E, k6 (5,000 views).  

### Notification Templates (US-MD23)
**Description**: Allows merchants to create and preview notification templates in real-time.  
**Components**:  
- **Polaris `Form`**: Fields for subject, body, Tailwind `grid grid-cols-2 p-4`.  
- **Polaris `Card`**: Live preview of template with i18next support.  
- **Polaris `Button`**: “Save Template”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- Left `Form` for template editing, right `Card` for preview.  
- Top `Banner` for feedback.  
**Accessibility**: ARIA (`aria-label="Edit notification template"`), RTL for `ar`, `he`.  
**Interactions**: Calls `/admin.v1/UpdateNotificationTemplate` (G4l), saves to `email_templates` (I8), caches in Redis (`template:{merchant_id}:{type}`, J24), logs to PostHog (`template_edited`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`NotificationTemplatePage.tsx`), Cypress E2E, k6 (1,000 templates).  

### Usage Dashboard (US-MD24)
**Description**: Shows plan usage (e.g., SMS referrals, orders) with upgrade nudges.  
**Components**:  
- **Polaris `ProgressBar`**: Usage metrics (e.g., “450/500 orders”), Tailwind `p-4`.  
- **Polaris `Banner`**: Upgrade CTA (e.g., “Upgrade for more!”).  
- **Polaris `Button`**: “Upgrade Now”, Tailwind `bg-blue-500`.  
**Layout**:  
- Top `Banner` with upgrade nudge.  
- `ProgressBar` for usage metrics.  
- Bottom `Button` for upgrade.  
**Accessibility**: ARIA (`aria-label="View plan usage"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/GetPlanUsage` (G4m), logs to PostHog (`plan_limit_warning`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`UsagePage.tsx`), Cypress E2E, k6 (1,000 views).  

### Contextual Tips (US-MD25)
**Description**: Displays contextual tips (2/day) for onboarding and optimization.  
**Components**:  
- **Polaris `Banner`**: Tip content (e.g., “Enable birthday bonus”), Tailwind `animate-fade-in p-4`.  
- **Polaris `Button`**: “Dismiss” or “Act Now”, Tailwind `bg-blue-500`.  
**Layout**:  
- Floating `Banner` (dismissible) on dashboard pages.  
- Optional `Button` for actions.  
**Accessibility**: ARIA (`aria-label="View contextual tip"`), RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/GetTips` (G4n), logs to PostHog (`tip_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`TipsBanner.tsx`), Cypress E2E, k6 (5,000 tips).  

### POS Offline Interface (US-MD26)
**Description**: Manages points via Shopify POS in offline mode.  
**Components**:  
- **Polaris `Card`**: Displays points balance, actions, Tailwind `p-4`.  
- **Polaris `Button`**: “Award Points” or “Redeem Points”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Sync status (e.g., “Offline: Sync pending”), Tailwind `animate-fade-in`.  
**Layout**:  
- `Card` with balance and action buttons.  
- Top `Banner` for sync status.  
**Accessibility**: ARIA (`aria-label="Manage POS points"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Syncs via SQLite queue, calls `/points.v1/ProcessPOSAction` (G1i), logs to PostHog (`pos_offline_used`, `offline_sync_completed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`POSPage.tsx`), Cypress E2E, k6 (1,000 transactions).  

### Rate Limit Dashboard (US-MD27)
**Description**: Monitors Shopify API rate limit usage with alerts.  
**Components**:  
- **Polaris `DataTable`**: API usage (e.g., “REST: 1.8/2 req/s”), Tailwind `table-auto p-4`.  
- **Polaris `Banner`**: Alerts at 80% limit, Tailwind `animate-pulse`.  
- **Polaris `Button`**: “View Details”, Tailwind `bg-blue-500`.  
**Layout**:  
- `DataTable` for usage, top `Banner` for alerts.  
- `Button` for drill-down.  
**Accessibility**: ARIA (`aria-label="View rate limits"`), RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/GetRateLimits` (G4o), alerts via email/Slack, logs to PostHog (`rate_limit_viewed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`RateLimitPage.tsx`), Cypress E2E, k6 (1,000 views).  

### Merchant Referral (US-MD28)
**Description**: Allows merchants to invite others and earn credits.  
**Components**:  
- **Polaris `Modal`**: Referral link, sharing options, Tailwind `p-4`.  
- **Polaris `Button`**: “Share via Email/SMS”, Tailwind `bg-green-500`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Modal` with link and sharing buttons.  
- Top `Banner` for feedback.  
**Accessibility**: ARIA (`aria-label="Share merchant referral"`), RTL for `ar`, `he`.  
**Interactions**: Calls `/admin.v1/CreateMerchantReferral` (G4p), logs to `merchant_referrals` (I14), PostHog (`merchant_referral_created`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`MerchantReferralPage.tsx`), Cypress E2E, k6 (1,000 referrals).  

### Non-Shopify POS Interface (US-MD29)
**Description**: Manages points via Square POS (Phase 3).  
**Components**:  
- **Polaris `Card`**: Points balance, actions, Tailwind `p-4`.  
- **Polaris `Button`**: “Award Points” or “Redeem Points”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Sync status (e.g., “Sync pending”), Tailwind `animate-fade-in`.  
**Layout**:  
- `Card` with balance and action buttons.  
- Top `Banner` for sync status.  
**Accessibility**: ARIA (`aria-label="Manage Square POS points"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Calls `/admin.v1/SyncSquarePOS` (G4q), logs to `audit_logs` (I25), PostHog (`square_sync_triggered`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`SquarePOSPage.tsx`), Cypress E2E, k6 (1,000 transactions).  

### 3-Step Onboarding (US-MD30)
**Description**: Guides merchants through RFM, referrals, and checkout extensions setup.  
**Components**:  
- **Polaris `Checklist`**: Steps (RFM, referrals, checkout), Tailwind `p-4`.  
- **Polaris `Button`**: “Next/Save”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Progress or errors.  
**Layout**:  
- `Checklist` with step-by-step tasks.  
- Top `Banner` for progress, `Button` for navigation.  
**Accessibility**: ARIA (`aria-label="Complete onboarding step"`), WCAG 2.1 AA, RTL for `ar`, `he`.  
**Interactions**: Calls `/admin.v1/CompleteOnboarding` (G4r), logs to `onboarding_tasks` (I15), PostHog (`onboarding_completed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`OnboardingPage.tsx`), Cypress E2E, k6 (1,000 merchants).  

## Admin Module Wireframes (Phases 1–3)

### User Management (US-AM4)
**Description**: Manages admin users with RBAC roles (`admin`, `superadmin`, `analytics`).  
**Components**:  
- **Polaris `DataTable`**: Lists admins (username, roles), Tailwind `table-auto`.  
- **Polaris `Form`**: CRUD forms for users, Tailwind `grid grid-cols-2`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `DataTable` for admin list.  
- `Form` for adding/editing users.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Add admin user"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/auth.v1/ListAdminUsers` (G5a), updates via `/auth.v1/UpdateAdminUser` (G5b), logs to `audit_logs` (I25), PostHog (`admin_user_updated`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`AdminUsers.tsx`), Cypress E2E (user CRUD), k6 (1,000 updates), OWASP ZAP.  

### Log Viewer (US-AM5)
**Description**: Streams API and audit logs in real-time with undo/replay options.  
**Components**:  
- **Polaris `Select` & `TextField`**: Filters for date/merchant/action, Tailwind `w-full`.  
- **Polaris `DataTable`**: Log entries from `audit_logs`, Tailwind `table-auto`.  
- **Polaris `Button`**: “Undo” or “Replay” for reversible actions, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Errors (e.g., “No logs found”).  
**Layout**:  
- Filters at top.  
- `DataTable` with log details and undo/replay buttons.  
- Error `Banner` at top if no data.  
**Accessibility**: ARIA (`aria-label="Filter logs"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/GetLogs` (G4d) via WebSocket, caches in Redis (`logs:{merchant_id}`, J15), calls `/admin.v1/UndoAction` (G4s) or `/admin.v1/ReplayAction` (G4t), logs to PostHog (`logs_viewed`, `action_undone`, `action_replayed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`LogsViewer.tsx`), Cypress E2E (filtering/streaming/undo/replay), k6 (5,000 views).  

### GDPR Request Dashboard (US-AM6)
**Description**: Processes customer GDPR/CCPA requests.  
**Components**:  
- **Polaris `DataTable`**: Lists requests (type, status, `retention_expires_at`), Tailwind `table-auto`.  
- **Polaris `Button`**: “Process Request”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `DataTable` with request details.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Process GDPR request"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/ProcessGDPRRequest` (G4e), logs to `gdpr_requests` (I21), PostHog (`gdpr_processed`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`GDPRDashboard.tsx`), Cypress E2E (request processing), k6 (1,000 requests), OWASP ZAP.  

### Plan Management (US-AM7)
**Description**: Manages merchant plans (e.g., Free, $29/mo).  
**Components**:  
- **Polaris `Select`**: Plan options, Tailwind `w-full`.  
- **Polaris `Button`**: “Update Plan”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Select` for plan selection.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Change merchant plan"`), keyboard-navigable, RTL for `ar`, `he`.  
**Interactions**: Calls `/admin.v1/UpdatePlan` (G4u), updates `merchants.plan` (I1), logs to PostHog (`plan_updated`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`PlanManagement.tsx`), Cypress E2E (plan changes), k6 (1,000 updates).  

### Integration Health Dashboard (US-AM8)
**Description**: Monitors integration status (e.g., Shopify, Klaviyo, Square).  
**Components**:  
- **Polaris `Card`**: Chart.js line chart for uptime trends, Tailwind `p-4`.  
- **Polaris `Button`**: “Ping Service”, Tailwind `bg-blue-500`.  
- **Polaris `Banner`**: Errors (e.g., “Klaviyo API down”).  
**Layout**:  
- `Card` with status and chart.  
- `Button` for manual pings.  
- Error `Banner` at top if API fails.  
**Accessibility**: ARIA (`aria-label="Check integration status"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/CheckHealth` (G4v), logs to PostHog (`integration_health_checked`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`IntegrationHealth.tsx`), Cypress E2E (health checks), k6 (5,000 pings).  

### RFM Configuration Admin (US-AM9)
**Description**: Manages RFM settings for merchants with incremental updates.  
**Components**:  
- **Polaris `Form`**: Fields for thresholds, Tailwind `grid grid-cols-2`.  
- **Polaris `RangeSlider`**: Adjusts weights (recency, frequency, monetary).  
- **Polaris `Card`**: Chart.js bar chart for `rfm_segment_counts` preview.  
- **Polaris `Banner`**: Confirmation or errors.  
**Layout**:  
- `Form` with sliders and fields.  
- `Card` with preview chart.  
- `Banner` for confirmation or errors.  
**Accessibility**: ARIA (`aria-label="Edit RFM config"`), screen reader support, RTL for `ar`, `he`.  
**Interactions**: Queries `/admin.v1/GetRFMConfig` (G4h), updates `rfm_segment_deltas` (I27), caches in Redis (`rfm:preview:{merchant_id}`, J9), logs to PostHog (`rfm_updated`, L).  
**Multilingual**: i18next (`en`, `es`, `fr`, `de`, `pt`, `ja`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`, `ko`, `uk`, `hu`, `sv`, `he`).  
**Testing**: Jest (`RFMConfigAdmin.tsx`), Cypress E2E (config update), k6 (5,000 previews).  

### Customer Lookup (US-AM10)
**Description**: Searches and views customer details across merchants with detailed RFM segment data.
**Components**:
- **Polaris TextField**: Search by customer ID, email, or name, Tailwind w-full p-2.
- **Polaris DataTable**: Displays customer details (name, email, points, RFM segment, last order date), Tailwind table-auto.
- **Polaris Banner**: Errors (e.g., “No customers found”) or success messages, Tailwind animate-fade-in.
- **Polaris Button**: “View Details” for drill-down, Tailwind bg-blue-500 hover:bg-blue-600.
**Layout**:
Top TextField for search input.
- DataTable below with customer details, sortable by column.
- Error/success Banner above table if applicable.
**Accessibility**: ARIA (aria-label="Search customers across merchants", aria-live="polite"), keyboard-navigable, RTL support for ar, he.
**Interactions**: Queries /admin.v1/SearchCustomers (G4w), fetches data from customers and rfm_segment_deltas (I2, I27), caches in Redis (customer_search:{query}, J19), logs to PostHog (customer_lookup_performed, L). Supports pagination for 50,000+ customers.
**Multilingual**: i18next (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he).
**Testing**: Jest (CustomerLookup.tsx), Cypress E2E (search and pagination), k6 (10,000 searches/hour), OWASP ZAP for security.

### RFM Simulation Dashboard (US-AM11)
**Description**: Allows admins to simulate RFM segment changes and view logs.
**Components**:
- **Polaris Form: Fields for simulation parameters (e.g., recency threshold, order volume), Tailwind grid grid-cols-2 p-4.
- **Polaris Card**: Chart.js bar chart for simulated rfm_segment_deltas, Tailwind p-4.
- **Polaris DataTable**: Simulation logs from rfm_simulation_logs (I28), Tailwind table-auto.
- **Polaris Button**: “Run Simulation” and “Export Logs”, Tailwind bg-blue-500.
- **Polaris Banner**: Confirmation or errors (e.g., “Invalid parameters”).
**Layout**:
- Left Form for simulation inputs.
- Right Card with Chart.js bar chart for segment distribution.
- Bottom DataTable for simulation logs.
- Top Banner for feedback.
**Accessibility**: ARIA (aria-label="Run RFM simulation"), screen reader support, RTL for ar, he.
**Interactions**: Calls /analytics.v1/RunRFMSimulation (G3j), stores results in rfm_simulation_logs (I28), caches in Redis (rfm_simulation:{merchant_id}:{simulation_id}, J20), logs to PostHog (rfm_simulation_run, L).
**Multilingual**: i18next (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he).
**Testing**: Jest (RFMSimulation.tsx), Cypress E2E (simulation and export), k6 (1,000 simulations), OWASP ZAP.

### Merchant Community Dashboard (US-AM12)
**Description**: Displays merchant community posts and interactions.
**Components**:
- **Polaris Card**: Lists community posts, Tailwind p-4.
- **Polaris TextField**: Input for new posts/comments, Tailwind w-full.
- **Polaris Button**: “Submit Post/Comment”, Tailwind bg-blue-500.
- **Polaris Banner**: Confirmation or errors (e.g., “Post failed”).
**Layout**:
- Card with post list and comment threads.
- TextField and Button for new posts/comments.
- Top Banner for feedback.
**Accessibility**: ARIA (aria-label="Create community post"), screen reader support, RTL for ar, he.
**Interactions**: Calls /admin.v1/ManageCommunity (G4x), stores in community_posts (I29), logs to PostHog (community_post_created, L).
**Multilingual**: i18next (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he).
**Testing**: Jest (CommunityDashboard.tsx), Cypress E2E (post/comment), k6 (1,000 posts).

### Shopify Flow Integration (US-AM13)
**Description**: Configures Shopify Flow triggers for loyalty actions.
**Components**:
- **Polaris Form**: Fields for trigger conditions (e.g., “Points > 1000 → VIP Tier”), Tailwind grid grid-cols-2 p-4.
- **Polaris Button**: “Save Trigger”, Tailwind bg-blue-500.
- **Polaris Banner**: Confirmation or errors.
**Layout**:
- Form with trigger conditions and save button.
- Top Banner for feedback.
**Accessibility**: ARIA (aria-label="Configure Shopify Flow trigger"), keyboard-navigable, RTL for ar, he.
**Interactions**: Calls /admin.v1/ConfigureFlowTrigger (G4y), updates integrations.flow (I10), logs to PostHog (flow_trigger_configured, L).
**Multilingual**: i18next (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he).
**Testing**: Jest (FlowIntegration.tsx), Cypress E2E (trigger setup), k6 (1,000 triggers).

### Disaster Recovery Dashboard (US-AM14)
**Description**: Monitors and manages disaster recovery processes.
**Components**:
- **Polaris DataTable**: Backup status (e.g., last backup, size), Tailwind table-auto.
- **Polaris Button**: “Initiate Recovery” or “Schedule Backup”, Tailwind bg-blue-500.
- **Polaris Banner**: Alerts for backup failures, Tailwind animate-pulse.
**Layout**:
- DataTable with backup details.
- Button for recovery/backup actions.
- Top Banner for alerts.
**Accessibility**: ARIA (aria-label="Manage disaster recovery"), screen reader support, RTL for ar, he.
**Interactions**: Queries /admin.v1/GetBackupStatus (G4z), triggers /admin.v1/InitiateRecovery (G4aa), logs to backup_logs (I30), PostHog (backup_initiated, L).
**Multilingual**: i18next (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he).
**Testing**: Jest (DisasterRecovery.tsx), Cypress E2E (backup/restore), k6 (1,000 recovery requests).

### Centralized Logging Dashboard (US-AM15)
**Description**: Displays centralized logs with filtering and export.
**Components**:
- **Polaris TextField & Select**: Filters for log type/severity/date, Tailwind w-full.
- **Polaris DataTable**: Logs from OpenSearch, Tailwind table-auto.
- **Polaris Button**: “Export Logs”, Tailwind bg-blue-500.
- **Polaris Banner**: Errors (e.g., “No logs found”).
**Layout**:
- Filters at top.
- DataTable with log entries.
- Button for export, Banner for errors.
**Accessibility**: ARIA (aria-label="Filter centralized logs"), screen reader support, RTL for ar, he.
**Interactions**: Queries /admin.v1/GetCentralizedLogs (G4ab), exports via /admin.v1/ExportLogs (G4ac), logs to PostHog (logs_exported, L).
**Multilingual**: i18next (en, es, fr, de, pt, ja, ru, it, nl, pl, tr, fa, zh-CN, vi, id, cs, ar, ko, uk, hu, sv, he).
**Testing**: Jest (CentralizedLogging.tsx), Cypress E2E (filter/export), k6 (10,000 log queries).

## Notes
**VPS Deployment**: Wireframes are optimized for low-latency rendering on VPS infrastructure (Hetzner, Linode), with Tailwind CSS compiled to minimize bundle size (<100KB).
**Scalability**: Supports Shopify Plus merchants with 50,000+ customers and 1,000 orders/hour via Redis caching and microservices (points.v1, referrals.v1, analytics.v1, admin.v1).
**Phase 3 Features**: Includes Square POS integration (US-MD29), RFM simulation logs (US-AM11), Shopify Flow (US-AM13), disaster recovery (US-AM14), and centralized logging (US-AM15).
**Testing**: Automated with Jest (unit), Cypress (E2E), k6 (load), Lighthouse CI (90+ score), and OWASP ZAP (security).
**AI-Driven Development**: Leverages GitHub Copilot, Cursor, and Grok for UI component generation and QA.
**GDPR/CCPA Compliance**: Ensures data retention (retention_expires_at in gdpr_requests, I21) and secure request handling.