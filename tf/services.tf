# ==========================================================================
# Enable Required Google Cloud APIs
# ==========================================================================

# 1. Enable IAM API (required to create Service Accounts)
resource "google_project_service" "iam_api" {
  project            = var.gcp_project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false # Prevent accidental disabling on destroy
}

# 2. Enable Pub/Sub API (required for our messaging system)
resource "google_project_service" "pubsub_api" {
  project            = var.gcp_project_id
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}
