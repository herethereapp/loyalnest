```protobuf
syntax = "proto3";

package loyalnest.v1;

option ts_out = "./generated";

import "google/protobuf/timestamp.proto";
import "google/protobuf/struct.proto";

// Points Service for real-time points updates
service PointsService {
  // Stream real-time points updates for a customer
  rpc PointsStream(PointsStreamRequest) returns (stream PointsStreamResponse);
}

// RFM Analytics Service for segment retrieval, preview, and visualizations
service RFMAnalyticsService {
  // Get RFM segments for a merchant
  rpc GetSegments(GetSegmentsRequest) returns (GetSegmentsResponse);
  // Preview RFM segments based on thresholds
  rpc PreviewRFMSegments(PreviewRFMSegmentsRequest) returns (PreviewRFMSegmentsResponse);
  // Get analytics visualizations (heatmaps, line charts)
  rpc GetAnalyticsVisualizations(GetAnalyticsVisualizationsRequest) returns (GetAnalyticsVisualizationsResponse);
}

// Admin Service for merchant management, notifications, rate limits, imports, and setup
service AdminService {
  // Update notification template
  rpc UpdateNotificationTemplate(UpdateNotificationTemplateRequest) returns (UpdateNotificationTemplateResponse);
  // Get Shopify API rate limit status
  rpc GetRateLimits(GetRateLimitsRequest) returns (GetRateLimitsResponse);
  // Import customers asynchronously
  rpc ImportCustomers(ImportCustomersRequest) returns (ImportCustomersResponse);
  // Stream import progress
  rpc StreamImportProgress(StreamImportProgressRequest) returns (stream StreamImportProgressResponse);
  // Update multi-currency settings
  rpc UpdateCurrencySettings(UpdateCurrencySettingsRequest) returns (UpdateCurrencySettingsResponse);
  // Configure Square integration
  rpc ConfigureSquareIntegration(ConfigureSquareIntegrationRequest) returns (ConfigureSquareIntegrationResponse);
  // Stream setup checklist progress
  rpc StreamSetupProgress(StreamSetupProgressRequest) returns (stream StreamSetupProgressResponse);
}

// Campaign Service for bonus campaigns
service CampaignService {
  // Create a bonus campaign
  rpc CreateCampaign(CreateCampaignRequest) returns (CreateCampaignResponse);
  // Get campaign details
  rpc GetCampaign(GetCampaignRequest) returns (GetCampaignResponse);
}

// Gamification Service for badges and leaderboards
service GamificationService {
  // Award a badge to a customer
  rpc AwardBadge(AwardBadgeRequest) returns (AwardBadgeResponse);
  // Get leaderboard rankings
  rpc GetLeaderboard(GetLeaderboardRequest) returns (GetLeaderboardResponse);
}

// Points Messages
message PointsStreamRequest {
  string customer_id = 1; // e.g., "customer_123"
  string merchant_id = 2; // e.g., "merchant_123"
}

message PointsStreamResponse {
  int32 points_balance = 1; // e.g., 500
  google.protobuf.Timestamp updated_at = 2;
  Error error = 3; // Optional error
}

// RFM Analytics Messages
message GetSegmentsRequest {
  string merchant_id = 1; // e.g., "merchant_123"
}

message GetSegmentsResponse {
  repeated RFMSegment segments = 1;
  Error error = 2; // Optional error
}

message PreviewRFMSegmentsRequest {
  string merchant_id = 1; // e.g., "merchant_123"
  google.protobuf.Struct thresholds = 2; // e.g., { "recency": "<=30", "frequency": ">=5", "monetary": ">=250" }
}

message PreviewRFMSegmentsResponse {
  repeated RFMSegment segments = 1;
  Error error = 2; // Optional error
}

message GetAnalyticsVisualizationsRequest {
  string merchant_id = 1; // e.g., "merchant_123"
  string visualization_type = 2; // e.g., "heatmap", "line_chart"
  string metric = 3; // e.g., "repeat_purchase_rate", "churn_risk"
}

message GetAnalyticsVisualizationsResponse {
  google.protobuf.Struct data = 1; // e.g., { "heatmap": [[1, 2], [3, 4]], "line_chart": [{"x": "2025-01-01", "y": 0.2}] }
  Error error = 2; // Optional error
}

message RFMSegment {
  string segment_id = 1; // e.g., "seg_303"
  string name = 2; // e.g., "Churn Risk"
  int32 count = 3; // e.g., 500
  google.protobuf.Struct conditions = 4; // e.g., { "recency": "<=2", "frequency": "<=2", "monetary": "<=3" }
}

// Admin Messages
message UpdateNotificationTemplateRequest {
  string template_id = 1; // e.g., "template_404"
  string type = 2; // e.g., "points_earned"
  string body = 3; // e.g., "You earned {{points}} points!"
  string language = 4; // e.g., "en", "es", "fr", "ar"
  string fallback_language = 5; // e.g., "en" for unsupported languages or malformed JSONB
  string merchant_id = 6; // e.g., "merchant_123"
}

message UpdateNotificationTemplateResponse {
  NotificationTemplate template = 1;
  Error error = 2; // Optional error
}

message GetRateLimitsRequest {
  string merchant_id = 1; // e.g., "merchant_123"
}

message GetRateLimitsResponse {
  RateLimitStatus status = 1;
  Error error = 2; // Optional error
}

message ImportCustomersRequest {
  string merchant_id = 1; // e.g., "merchant_123"
  string file_path = 2; // Path to CSV file (e.g., "/uploads/import_606.csv")
}

message ImportCustomersResponse {
  string job_id = 1; // e.g., "import_606"
  Error error = 2; // Optional error
}

message StreamImportProgressRequest {
  string job_id = 1; // e.g., "import_606"
  string merchant_id = 2; // e.g., "merchant_123"
}

message StreamImportProgressResponse {
  int32 processed_rows = 1; // e.g., 500
  int32 total_rows = 2; // e.g., 1000
  float progress_percentage = 3; // e.g., 50.0
  Error error = 4; // Optional error
}

message UpdateCurrencySettingsRequest {
  string merchant_id = 1; // e.g., "merchant_123"
  bool multi_currency_enabled = 2; // e.g., true
  repeated string currencies = 3; // e.g., ["USD", "EUR"]
}

message UpdateCurrencySettingsResponse {
  google.protobuf.Struct settings = 1; // e.g., { "multi_currency_enabled": true, "currencies": ["USD", "EUR"] }
  Error error = 2; // Optional error
}

message ConfigureSquareIntegrationRequest {
  string merchant_id = 1; // e.g., "merchant_123"
  string api_key = 2; // e.g., "sq0atp-abc123"
}

message ConfigureSquareIntegrationResponse {
  bool success = 1; // e.g., true
  Error error = 2; // Optional error
}

message StreamSetupProgressRequest {
  string merchant_id = 1; // e.g., "merchant_123"
}

message StreamSetupProgressResponse {
  repeated SetupTask tasks = 1; // List of onboarding tasks
  float progress_percentage = 2; // e.g., 75.0
  Error error = 3; // Optional error
}

message NotificationTemplate {
  string id = 1; // e.g., "template_404"
  string type = 2; // e.g., "points_earned"
  string body = 3; // e.g., "You earned {{points}} points!"
  string language = 4; // e.g., "en", "es", "fr", "ar"
  string fallback_language = 5; // e.g., "en"
}

message RateLimitStatus {
  string merchant_id = 1; // e.g., "merchant_123"
  int32 api_calls_used = 2; // e.g., 80
  int32 api_calls_limit = 3; // e.g., 100
  float percentage = 4; // e.g., 80.0
}

message SetupTask {
  string task_id = 1; // e.g., "task_101"
  string name = 2; // e.g., "Configure Points"
  bool completed = 3; // e.g., true
  google.protobuf.Timestamp updated_at = 4;
}

// Campaign Messages
message CreateCampaignRequest {
  string merchant_id = 1; // e.g., "merchant_123"
  string campaign_type = 2; // e.g., "points_multiplier"
  google.protobuf.Struct details = 3; // e.g., { "multiplier": 2, "start_date": "2025-01-01", "end_date": "2025-01-31" }
}

message CreateCampaignResponse {
  string campaign_id = 1; // e.g., "campaign_707"
  Error error = 2; // Optional error
}

message GetCampaignRequest {
  string campaign_id = 1; // e.g., "campaign_707"
  string merchant_id = 2; // e.g., "merchant_123"
}

message GetCampaignResponse {
  Campaign campaign = 1;
  Error error = 2; // Optional error
}

message Campaign {
  string campaign_id = 1; // e.g., "campaign_707"
  string campaign_type = 2; // e.g., "points_multiplier"
  google.protobuf.Struct details = 3; // e.g., { "multiplier": 2, "start_date": "2025-01-01", "end_date": "2025-01-31" }
  google.protobuf.Timestamp created_at = 4;
}

// Gamification Messages
message AwardBadgeRequest {
  string customer_id = 1; // e.g., "customer_123"
  string merchant_id = 2; // e.g., "merchant_123"
  string badge_id = 3; // e.g., "badge_808"
}

message AwardBadgeResponse {
  Badge badge = 1;
  Error error = 2; // Optional error
}

message GetLeaderboardRequest {
  string merchant_id = 1; // e.g., "merchant_123"
  int32 page = 2; // e.g., 1
  int32 page_size = 3; // e.g., 50
}

message GetLeaderboardResponse {
  repeated LeaderboardEntry entries = 1;
  int32 total_pages = 2; // e.g., 10
  Error error = 3; // Optional error
}

message Badge {
  string badge_id = 1; // e.g., "badge_808"
  string name = 2; // e.g., "Loyal Customer"
  google.protobuf.Timestamp awarded_at = 3;
}

message LeaderboardEntry {
  string customer_id = 1; // e.g., "customer_123"
  int32 rank = 2; // e.g., 1
  int32 points = 3; // e.g., 1000
}

// Enhanced Error Message
message Error {
  string code = 1; // e.g., "INVALID_REQUEST", "RATE_LIMIT_EXCEEDED", "SERVER_ERROR"
  string message = 2; // e.g., "Invalid merchant ID"
  int32 http_code = 3; // e.g., 400, 429, 500
  int32 retry_after_ms = 4; // e.g., 1000 for rate limits or server errors
}
```