```yaml
openapi: 3.0.3
info:
  title: LoyalNest Shopify App API
  description: API for the LoyalNest Shopify app, providing loyalty and rewards functionality for merchants, including points, SMS/email referrals, RFM analytics, GDPR compliance, customer imports, campaign discounts, rate limit monitoring, usage thresholds, upgrade nudge notifications, gamification, and onboarding. Supports Shopify and Shopify Plus merchants.
  version: 1.0.0
servers:
  - url: https://api.loyalnest.com/v1
    description: Production API
  - url: http://localhost:3000/v1
    description: Local development API
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    ShopifyWebhookSignature:
      type: apiKey
      in: header
      name: X-Shopify-Hmac-Sha256
  schemas:
    Error:
      type: object
      properties:
        code:
          type: string
          example: "INVALID_REQUEST"
          enum: [INVALID_REQUEST, RATE_LIMIT_EXCEEDED, SERVER_ERROR, TIMEOUT, INVALID_REFERRAL_CODE, GDPR_RETRY_FAILED]
        message:
          type: string
          example: "Invalid request parameters"
        http_code:
          type: integer
          example: 400
          enum: [400, 403, 404, 429, 500]
        retry_after_ms:
          type: integer
          example: 1000
      required:
        - code
        - message
        - http_code
    Merchant:
      type: object
      properties:
        id:
          type: string
          example: "merchant_123"
        shop_domain:
          type: string
          example: "example.myshopify.com"
        plan:
          type: string
          enum: [free, standard, plus, enterprise]
          example: "free"
      required:
        - id
        - shop_domain
        - plan
    Customer:
      type: object
      properties:
        id:
          type: string
          example: "customer_456"
        merchant_id:
          type: string
          example: "merchant_123"
        email:
          type: string
          example: "customer@example.com"
        rfm_score:
          type: object
          properties:
            recency:
              type: integer
              minimum: 1
              maximum: 5
              example: 4
            frequency:
              type: integer
              minimum: 1
              maximum: 5
              example: 3
            monetary:
              type: integer
              minimum: 1
              maximum: 5
              example: 5
      required:
        - id
        - merchant_id
        - email
        - rfm_score
    PointsTransaction:
      type: object
      properties:
        id:
          type: string
          example: "txn_789"
        customer_id:
          type: string
          example: "customer_456"
        points:
          type: integer
          example: 100
        type:
          type: string
          enum: [earn, redeem, adjust]
          example: "earn"
        created_at:
          type: string
          format: date-time
          example: "2025-07-15T12:00:00Z"
      required:
        - id
        - customer_id
        - points
        - type
        - created_at
    PointsStream:
      type: object
      properties:
        customer_id:
          type: string
          example: "customer_456"
        points_balance:
          type: integer
          example: 500
        updated_at:
          type: string
          format: date-time
          example: "2025-07-15T12:00:00Z"
      required:
        - customer_id
        - points_balance
        - updated_at
    Referral:
      type: object
      properties:
        id:
          type: string
          example: "ref_101"
        merchant_id:
          type: string
          example: "merchant_123"
        referral_link_id:
          type: string
          example: "link_202"
        status:
          type: string
          enum: [pending, completed, expired]
          example: "pending"
        created_at:
          type: string
          format: date-time
          example: "2025-07-15T12:00:00Z"
      required:
        - id
        - merchant_id
        - referral_link_id
        - status
        - created_at
    RFMSegment:
      type: object
      properties:
        segment_id:
          type: string
          example: "seg_303"
        name:
          type: string
          example: "Churn Risk"
        count:
          type: integer
          example: 500
        conditions:
          type: object
          example: { "recency": "<=2", "frequency": "<=2", "monetary": "<=3" }
      required:
        - segment_id
        - name
        - count
        - conditions
    AnalyticsVisualization:
      type: object
      properties:
        visualization_type:
          type: string
          enum: [heatmap, line_chart]
          example: "heatmap"
        metric:
          type: string
          enum: [repeat_purchase_rate, churn_risk]
          example: "repeat_purchase_rate"
        data:
          type: object
          example: { "heatmap": [[1, 2], [3, 4]], "line_chart": [{ "x": "2025-01-01", "y": 0.2 }] }
      required:
        - visualization_type
        - metric
        - data
    NotificationTemplate:
      type: object
      properties:
        id:
          type: string
          example: "template_404"
        type:
          type: string
          enum: [points_earned, referral_invite, gdpr_request]
          example: "points_earned"
        body:
          type: string
          example: "You earned {{points}} points!"
        language:
          type: string
          example: "en"
        fallback_language:
          type: string
          example: "en"
      required:
        - id
        - type
        - body
        - language
        - fallback_language
    RateLimitStatus:
      type: object
      properties:
        merchant_id:
          type: string
          example: "merchant_123"
        api_calls_used:
          type: integer
          example: 80
        api_calls_limit:
          type: integer
          example: 100
        percentage:
          type: number
          format: float
          example: 80.0
      required:
        - merchant_id
        - api_calls_used
        - api_calls_limit
        - percentage
    PlanUsage:
      type: object
      properties:
        merchant_id:
          type: string
          example: "merchant_123"
        orders_used:
          type: integer
          example: 240
        orders_limit:
          type: integer
          example: 300
        sms_referrals_used:
          type: integer
          example: 40
        sms_referrals_limit:
          type: integer
          example: 50
      required:
        - merchant_id
        - orders_used
        - orders_limit
        - sms_referrals_used
        - sms_referrals_limit
    Campaign:
      type: object
      properties:
        campaign_id:
          type: string
          example: "campaign_707"
        campaign_type:
          type: string
          enum: [points_multiplier, discount]
          example: "points_multiplier"
        details:
          type: object
          example: { "multiplier": 2, "start_date": "2025-01-01", "end_date": "2025-01-31" }
        created_at:
          type: string
          format: date-time
          example: "2025-07-15T12:00:00Z"
      required:
        - campaign_id
        - campaign_type
        - details
        - created_at
    CurrencySettings:
      type: object
      properties:
        merchant_id:
          type: string
          example: "merchant_123"
        multi_currency_enabled:
          type: boolean
          example: true
        currencies:
          type: array
          items:
            type: string
            example: "USD"
          example: ["USD", "EUR"]
      required:
        - merchant_id
        - multi_currency_enabled
        - currencies
    SquareIntegration:
      type: object
      properties:
        merchant_id:
          type: string
          example: "merchant_123"
        api_key:
          type: string
          example: "sq0atp-abc123"
        enabled:
          type: boolean
          example: true
      required:
        - merchant_id
        - api_key
        - enabled
    Badge:
      type: object
      properties:
        badge_id:
          type: string
          example: "badge_808"
        name:
          type: string
          example: "Loyal Customer"
        awarded_at:
          type: string
          format: date-time
          example: "2025-07-15T12:00:00Z"
      required:
        - badge_id
        - name
        - awarded_at
    LeaderboardEntry:
      type: object
      properties:
        customer_id:
          type: string
          example: "customer_456"
        rank:
          type: integer
          example: 1
        points:
          type: integer
          example: 1000
      required:
        - customer_id
        - rank
        - points
    SetupTask:
      type: object
      properties:
        task_id:
          type: string
          example: "task_101"
        name:
          type: string
          example: "Configure Points"
        completed:
          type: boolean
          example: true
        updated_at:
          type: string
          format: date-time
          example: "2025-07-15T12:00:00Z"
      required:
        - task_id
        - name
        - completed
        - updated_at
    ImportProgress:
      type: object
      properties:
        job_id:
          type: string
          example: "import_606"
        processed_rows:
          type: integer
          example: 500
        total_rows:
          type: integer
          example: 1000
        progress_percentage:
          type: number
          format: float
          example: 50.0
      required:
        - job_id
        - processed_rows
        - total_rows
        - progress_percentage
paths:
  /api/auth/login:
    post:
      summary: Authenticate merchant via Shopify OAuth
      tags:
        - Auth
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                shop_domain:
                  type: string
                  example: "example.myshopify.com"
                code:
                  type: string
                  example: "auth_code_123"
              required:
                - shop_domain
                - code
      responses:
        '200':
          description: Successful authentication
          content:
            application/json:
              schema:
                type: object
                properties:
                  access_token:
                    type: string
                    example: "jwt_token_123"
                  refresh_token:
                    type: string
                    example: "refresh_token_456"
                required:
                  - access_token
                  - refresh_token
        '401':
          description: Unauthorized
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/auth/refresh:
    post:
      summary: Refresh JWT token
      tags:
        - Auth
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                refresh_token:
                  type: string
                  example: "refresh_token_456"
              required:
                - refresh_token
      responses:
        '200':
          description: Token refreshed
          content:
            application/json:
              schema:
                type: object
                properties:
                  access_token:
                    type: string
                    example: "jwt_token_789"
                required:
                  - access_token
        '401':
          description: Invalid refresh token
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/points/stream:
    get:
      summary: Stream real-time points updates (WebSocket)
      tags:
        - Points
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: customer_id
          schema:
            type: string
            example: "customer_456"
          required: true
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
      responses:
        '101':
          description: Switching protocols (WebSocket)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PointsStream'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/points/earn:
    post:
      summary: Earn points for a customer
      tags:
        - Points
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                customer_id:
                  type: string
                  example: "customer_456"
                points:
                  type: integer
                  example: 100
                reason:
                  type: string
                  example: "purchase"
              required:
                - customer_id
                - points
                - reason
      responses:
        '200':
          description: Points earned
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PointsTransaction'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/points/redeem:
    post:
      summary: Redeem points for a customer
      tags:
        - Points
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                customer_id:
                  type: string
                  example: "customer_456"
                points:
                  type: integer
                  example: 50
                campaign_id:
                  type: string
                  example: "campaign_505"
              required:
                - customer_id
                - points
                - campaign_id
      responses:
        '200':
          description: Points redeemed
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PointsTransaction'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/referrals/create:
    post:
      summary: Create a referral link
      tags:
        - Referrals
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                customer_id:
                  type: string
                  example: "customer_456"
                type:
                  type: string
                  enum: [sms, email]
                  example: "sms"
              required:
                - customer_id
                - type
      responses:
        '200':
          description: Referral created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Referral'
        '400':
          description: Invalid request (e.g., invalid referral code)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error (e.g., Klaviyo/Postscript timeout)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/referrals/progress:
    get:
      summary: Get referral progress
      tags:
        - Referrals
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: referral_link_id
          schema:
            type: string
            example: "link_202"
          required: true
      responses:
        '200':
          description: Referral progress
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Referral'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '404':
          description: Referral not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/rfm/segments:
    get:
      summary: Get RFM segments
      tags:
        - RFM Analytics
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
      responses:
        '200':
          description: RFM segments
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/RFMSegment'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/rfm/segments/preview:
    post:
      summary: Preview RFM segments
      tags:
        - RFM Analytics
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                merchant_id:
                  type: string
                  example: "merchant_123"
                thresholds:
                  type: object
                  example: { "recency": "<=30", "frequency": ">=5", "monetary": ">=250" }
              required:
                - merchant_id
                - thresholds
      responses:
        '200':
          description: Segment preview
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/RFMSegment'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/rfm/visualizations:
    get:
      summary: Get RFM analytics visualizations (heatmaps, line charts)
      tags:
        - RFM Analytics
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
        - in: query
          name: visualization_type
          schema:
            type: string
            enum: [heatmap, line_chart]
            example: "heatmap"
          required: true
        - in: query
          name: metric
          schema:
            type: string
            enum: [repeat_purchase_rate, churn_risk]
            example: "repeat_purchase_rate"
          required: true
      responses:
        '200':
          description: Analytics visualizations
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/AnalyticsVisualization'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/events:
    post:
      summary: Track event for analytics
      tags:
        - Event Tracking
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                event_name:
                  type: string
                  example: "points_earned"
                properties:
                  type: object
                  example: { "points": 100, "customer_id": "customer_456" }
              required:
                - event_name
                - properties
      responses:
        '200':
          description: Event tracked
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: "success"
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/campaigns:
    post:
      summary: Create a bonus campaign
      tags:
        - Campaigns
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                merchant_id:
                  type: string
                  example: "merchant_123"
                campaign_type:
                  type: string
                  enum: [points_multiplier, discount]
                  example: "points_multiplier"
                details:
                  type: object
                  example: { "multiplier": 2, "start_date": "2025-01-01", "end_date": "2025-01-31" }
              required:
                - merchant_id
                - campaign_type
                - details
      responses:
        '200':
          description: Campaign created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Campaign'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/campaigns/{campaign_id}:
    get:
      summary: Get campaign details
      tags:
        - Campaigns
      security:
        - BearerAuth: []
      parameters:
        - in: path
          name: campaign_id
          schema:
            type: string
            example: "campaign_707"
          required: true
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
      responses:
        '200':
          description: Campaign details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Campaign'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '404':
          description: Campaign not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/gamification/badges:
    post:
      summary: Award a badge to a customer
      tags:
        - Gamification
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                customer_id:
                  type: string
                  example: "customer_456"
                merchant_id:
                  type: string
                  example: "merchant_123"
                badge_id:
                  type: string
                  example: "badge_808"
              required:
                - customer_id
                - merchant_id
                - badge_id
      responses:
        '200':
          description: Badge awarded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Badge'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/gamification/leaderboard:
    get:
      summary: Get leaderboard rankings
      tags:
        - Gamification
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
        - in: query
          name: page
          schema:
            type: integer
            example: 1
          required: true
        - in: query
          name: page_size
          schema:
            type: integer
            example: 50
          required: true
      responses:
        '200':
          description: Leaderboard rankings
          content:
            application/json:
              schema:
                type: object
                properties:
                  entries:
                    type: array
                    items:
                      $ref: '#/components/schemas/LeaderboardEntry'
                  total_pages:
                    type: integer
                    example: 10
                required:
                  - entries
                  - total_pages
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /admin/merchants:
    get:
      summary: List merchants (admin only)
      tags:
        - Admin
      security:
        - BearerAuth: []
      responses:
        '200':
          description: List of merchants
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Merchant'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC: admin:full)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /admin/notifications/template:
    post:
      summary: Update notification template (admin only)
      tags:
        - Admin
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/NotificationTemplate'
      responses:
        '200':
          description: Template updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/NotificationTemplate'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC: admin:full)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /admin/rate-limits:
    get:
      summary: Get Shopify API rate limit status (admin only)
      tags:
        - Admin
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
      responses:
        '200':
          description: Rate limit status
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/RateLimitStatus'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC: admin:full)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /admin/customers/import:
    post:
      summary: Import customers via CSV (admin only)
      tags:
        - Admin
      security:
        - BearerAuth: []
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                file:
                  type: string
                  format: binary
                merchant_id:
                  type: string
                  example: "merchant_123"
              required:
                - file
                - merchant_id
      responses:
        '202':
          description: Import accepted (async processing)
          content:
            application/json:
              schema:
                type: object
                properties:
                  job_id:
                    type: string
                    example: "import_606"
                required:
                  - job_id
        '400':
          description: Invalid request (e.g., invalid CSV)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC: admin:full)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /admin/imports/stream:
    get:
      summary: Stream import progress (WebSocket)
      tags:
        - Admin
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: job_id
          schema:
            type: string
            example: "import_606"
          required: true
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
      responses:
        '101':
          description: Switching protocols (WebSocket)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ImportProgress'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /admin/settings/currency:
    post:
      summary: Update multi-currency settings
      tags:
        - Admin
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CurrencySettings'
      responses:
        '200':
          description: Currency settings updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/CurrencySettings'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /admin/integrations/square:
    post:
      summary: Configure Square integration
      tags:
        - Admin
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/SquareIntegration'
      responses:
        '200':
          description: Square integration configured
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/SquareIntegration'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /admin/setup/stream:
    get:
      summary: Stream onboarding checklist progress (WebSocket)
      tags:
        - Admin
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
      responses:
        '101':
          description: Switching protocols (WebSocket)
          content:
            application/json:
              schema:
                type: object
                properties:
                  tasks:
                    type: array
                    items:
                      $ref: '#/components/schemas/SetupTask'
                  progress_percentage:
                    type: number
                    format: float
                    example: 75.0
                required:
                  - tasks
                  - progress_percentage
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /api/plan/usage:
    get:
      summary: Get plan usage (orders, SMS referrals)
      tags:
        - Admin
      security:
        - BearerAuth: []
      parameters:
        - in: query
          name: merchant_id
          schema:
            type: string
            example: "merchant_123"
          required: true
      responses:
        '200':
          description: Plan usage
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PlanUsage'
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '403':
          description: Forbidden (RBAC)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /webhooks/customers/data_request:
    post:
      summary: Handle GDPR customer data request
      tags:
        - GDPR
      security:
        - ShopifyWebhookSignature: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                shop_domain:
                  type: string
                  example: "example.myshopify.com"
                customer:
                  type: object
                  properties:
                    email:
                      type: string
                      example: "customer@example.com"
              required:
                - shop_domain
                - customer
      responses:
        '200':
          description: Request processed
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: "success"
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '401':
          description: Invalid webhook signature
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error (e.g., GDPR retry failed)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
  /webhooks/customers/redact:
    post:
      summary: Handle GDPR customer data redaction
      tags:
        - GDPR
      security:
        - ShopifyWebhookSignature: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                shop_domain:
                  type: string
                  example: "example.myshopify.com"
                customer:
                  type: object
                  properties:
                    email:
                      type: string
                      example: "customer@example.com"
              required:
                - shop_domain
                - customer
      responses:
        '200':
          description: Redaction processed
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: "success"
        '400':
          description: Invalid request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '401':
          description: Invalid webhook signature
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limit exceeded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          description: Server error (e.g., GDPR retry failed)
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
security:
  - BearerAuth: []
```