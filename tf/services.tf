# ==========================================================================
# GCP APIs: Enable by list
# ==========================================================================

locals {
  # Complete list of core APIs required for the bf-analyzer project infrastructure
  gcp_services = [
    # Core Platform & Access
    "iam.googleapis.com",                  # 1. Required to manage Service Accounts & IAM roles
    "storage.googleapis.com",              # 2. Required for raw logs bucket & state components
    "pubsub.googleapis.com",               # 3. Required for event routing and log-events topic
    "cloudscheduler.googleapis.com",       # 4. Required for cron automation (report daily trigger)
    "firestore.googleapis.com",            # 5. Required for the NoSQL database tier

    # Cloud Run Functions & Deployment Engine
    "cloudfunctions.googleapis.com",       # 6. Required for Cloud Run functions management
    "run.googleapis.com",                  # 7. Required as the underlying compute runtime for functions
    "artifactregistry.googleapis.com",     # 8. Required to store compiled function container images
    "cloudbuild.googleapis.com"            # 9. Required by GCP to build source code into containers
  ]
}

# Programmatically enable each API from the list above using a loop
resource "google_project_service" "required_apis" {
  for_each = toset(local.gcp_services)

  project            = var.gcp_project_id
  service            = each.key
  disable_on_destroy = false # Prevent accidental disabling on terraform destroy
}
