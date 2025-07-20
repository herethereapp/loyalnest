# UI/UX Requirements Document: LoyalNest Shopify App

## 1. Overview
The LoyalNest Shopify App provides a loyalty and rewards platform for Shopify merchants (100–50,000+ customers), built with Vite + React, Shopify Polaris, Tailwind CSS, and App Bridge. The UI/UX is intuitive, accessible (WCAG 2.1 AA, 90+ Lighthouse score), performant (LCP <2.5s, FID <100ms, CLS <0.1), and GDPR/CCPA-compliant, targeting Must Have features in Phase 2 (Weeks 5–11, August–September 2025): points, SMS/email referrals, basic RFM analytics, Shopify POS, checkout extensions, GDPR request form, referral status, notification templates, customer import, campaign discounts, rate limit monitoring, usage thresholds, and upgrade nudges. The UI includes Merchant Dashboard, Customer Widget, Admin Module, and On-Site Content, developed by a solo developer with in-house UI/UX and QA, using AI tools (GitHub Copilot, Cursor, Grok).

## 2. Objectives
- **Usability**: 80%+ onboarding checklist and RFM wizard completion.
- **Shopify Compliance**: Polaris and App Bridge for Built for Shopify certification.
- **Accessibility**: 90+ Lighthouse accessibility score, WCAG 2.1 AA.
- **Performance**: LCP <2.5s, FID <100ms, CLS <0.1.
- **Scalability**: Support 5,000+ merchants, 50,000+ customers.
- **GDPR/CCPA Compliance**: GDPR form with 90-day retention tracking.
- **Engagement**: 7%+ SMS referral conversion, 3%+ email referral conversion, 85%+ checkout extension adoption, 20%+ redemption rate, 60%+ referral status engagement, 80%+ notification template usage, 90%+ customer import success rate, 10%+ campaign discount redemption.

## 4. Design Requirements
- **Polaris Compliance**: Use Polaris `Card`, `Form`, `ProgressBar`, `Banner`, `DataTable`, `Stepper`, `RangeSlider`, `Badge`, `CalloutCard`, `Modal`.
- **Tailwind CSS**: Utility classes for responsive layouts (sm: 320px, md: 768px, lg: 1024px), high-contrast text (4.5:1), 8px spacing grid, 16px margins.
- **Visual Hierarchy**:
  - **Spacing**: 8px grid for components, 16px margins for `Card`/`Form`.
  - **Animations**: 300ms `ease-in-out` for modals/popups, 200ms for hover states (e.g., `Button` scale 1.05), 300ms fade-in for `Banner`.
  - **Layouts**: `sm: single-column DataTable`, `md: 2-column Form`, `lg: 3-column grid` for rewards.
- **App Bridge**: Integrate for Shopify admin embedding, navigation, OAuth.
- **Chart.js**: Bar charts for RFM segments, line charts for redemption trends, ARIA labels (aria-live: "Chart data available").
- **Color Scheme**: Primary (#2CB1A5), secondary (#FFFFFF), accents (#FF5733).
- **Typography**: Helvetica Neue, 16px base, 1.5 line height, bold headings.
- **Localization**:
  - i18next for English (`en`), hooks for  `es`, `de`, `ja`, `fr`, `pt`, `ru`, `it`, `nl`, `pl`, `tr`, `fa`, `zh-CN`, `vi`, `id`, `cs`, `ar`(RTL), `ko`, `uk`, `hu`, `sv`, `he`(RTL) (Phase 6).
  - JSONB parsing: Fallback to `en` for malformed `program_settings.settings->>'ar'` or `email_templates.body->>'en'`.
  - Test RTL layouts with Jest (component rendering) and Cypress (E2E).

## 7. Performance Requirements
- **Lighthouse Scores**: LCP <2.5s, FID <100ms, CLS <0.1.
- **Optimization**:
  - Minify JavaScript/CSS (<50KB Widget, <200KB Dashboard).
  - WebP images, lazy-load popups/charts.
  - Cache API responses in Redis (`points:{customer_id}`, `rfm:preview:{merchant_id}`).
  - Paginate tables (50 rows/page).
  - WebSocket optimization: Rate-limit `/points.v1/PointsStream` to 1/s per user, fallback to polling for 429 errors, load balance Redis Cluster/Streams.
- **Load Testing**: k6 for 5,000 customers (Shopify), 50,000 customers (Plus), 10,000 concurrent WebSocket connections.

## 8. Testing Requirements
- **Unit Tests**: Jest for components (`WelcomePage.tsx`, `Widget.tsx`).
- **E2E Tests**: Cypress for onboarding, RFM wizard, referral popup, GDPR form, customer import, sticky bar, edge cases (429 retries, Klaviyo timeouts, invalid CSV).
- **Accessibility Tests**: Lighthouse CI for ARIA, keyboard navigation, contrast (90+ score).
- **Mock Data**: Faker for merchants, customers, RFM scores.
- **Edge Cases**:
  - Partial data loads: Render cached data in `DataTable` with Polaris `Banner` warning (PostHog: `partial_data_loaded`).
  - Offline POS: Cache points in localStorage, sync on reconnect (PostHog: `pos_offline_sync`).
  - Rate limit alerts (80%+ usage), invalid imports, GDPR webhook retries, duplicate referral codes, network errors (429, 500).

## 9. Mockups and Wireframes
- **Tools**: Figma (Polaris UI kit), Mermaid, Grok/Cursor for AI-assisted design.
- **Phase 2 Deliverables** (Weeks 5–11, aligned with `phase_2_implementation_plan.md`):
  - **Merchant Dashboard**:
    - `WelcomePage.tsx`: Metrics, gamified checklist, upgrade nudge, rate limits (`US-MD1`, `US-MD6`, `US-MD11`).
    - `PointsProgramPage.tsx`: Earning/redemption rules, branding (`US-MD2`).
    - `ReferralsProgramPage.tsx`: Referral config, codes table (`US-MD3`).
    - `CustomersPage.tsx`: Customer list, CSV import (`US-MD4`).
    - `AnalyticsPage.tsx`: Metrics, basic RFM bar charts (`US-MD5`).
    - `SettingsPage.tsx`: Store details, RFM wizard, checkout extensions (`US-MD6`, `US-MD11`).
    - `OnSiteContentPage.tsx`: Loyalty page, rewards panel, launcher, popups, post-purchase widget (`US-MD7`).
    - `NotificationTemplatesPage.tsx`: Template editor with preview (`US-MD8`).
    - `RateLimitMonitoringPage.tsx`: API status (`US-MD11`).
  - **Customer Widget**:
    - `Widget.tsx`: Points balance, redemptions, referral popup, GDPR form, RFM nudges, language config, post-purchase widget (`US-CW1–CW5`, `US-CW8`, `US-CW10`, `US-CW13`, `US-CW15`).
    - `ReferralProgress.tsx`: Referral status with progress bar (`US-CW7`).
  - **Admin Module**:
    - `OverviewPage.tsx`: Metrics, RFM charts (`US-AM1`).
    - `MerchantsPage.tsx`: Merchant list, plan management, points adjustment (`US-AM2`, `US-AM7`, `US-AM10`).
    - `AdminUsersPage.tsx`: User management (`US-AM4`).
    - `LogsPage.tsx`: API/audit logs (`US-AM5`).
    - `IntegrationHealthPage.tsx`: Integration status (`US-AM8`).
    - `RFMConfigPage.tsx`: Thresholds with Chart.js preview (`US-AM9`).
    - `RFMSegmentExportPage.tsx`: CSV export (`US-AM12`).
    - `GDPRRequestsPage.tsx`: Request processing (`US-AM6`).
    - `RateLimitMonitoringPage.tsx`: API limits (`US-AM11`).
- **Feedback Integration**:
  - Conduct usability tests with 5–10 merchants (2–3 Shopify Plus) via Shopify Partners.
  - Test RFM wizard completion (80%+ target), referral popup CTAs (A/B testing), GDPR form usability.
  - Iterate wireframes/prototypes based on feedback (e.g., simplify `RangeSlider` in RFM wizard).
  - Target 90%+ merchant satisfaction in surveys (Google Forms/Typeform).
- **Mermaid Layout Example** (RFM Wizard):
  ```mermaid
  graph TD
      A[RFMConfigPage] --> B[Form: Stepper, RangeSlider for thresholds]
      A --> C[Chart.js: Bar chart preview]
      A --> D[Banner: Confirmation/Error]
      B --> E[Save Button: aria-label="Save RFM config"]
      C --> F[Preview: aria-live="RFM segment data available"]
      D --> G[Error: aria-label="Resolve RFM config error"]
  ```

## 11. Assumptions and Constraints
- **Assumptions**:
  - Merchants expect Polaris-compliant UI and App Bridge integration.
  - AI tools (Grok: wireframe suggestions, Copilot: React scaffolding, Cursor: code reviews) reduce design effort by 30–40%.
  - Shopify Plus merchants require white-glove onboarding for RFM and checkout extensions.
- **Constraints**:
  - Solo developer with in-house UI/UX and QA, $74,750 budget.
  - Timeline: Phase 2 (Weeks 5–11) for design, Phase 3 (Weeks 12–30) for implementation.
  - **Risk Mitigation**:
    - Prioritize Must Have features (`US-MD1–MD12`, `US-CW1–CW10`, `US-CW13–CW15`, `US-AM1–AM13`).
    - Use AI tools for 30–40% of wireframe/prototype work (e.g., Grok for layout suggestions).
    - Outsource QA for accessibility testing if Lighthouse scores <90.
    - Monitor developer bandwidth weekly to avoid delays.