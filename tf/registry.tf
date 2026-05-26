
# Run Functions - Artifact Registry repository

resource "google_artifact_registry_repository" "functions_repo" {
  project       = var.gcp_project_id
  location      = var.gcp_region
  repository_id = "${var.gcp_project_id}-functions"
  description   = "Docker repository for Cloud Run functions compiled images"
  format        = "DOCKER"

  # 1. Dynamically keep the most recent versions of any image
  cleanup_policies {
    id     = "keep-latest-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.artifact_registry_retention_count # Dynamic variable reference
    }
  }

  # 2. Automatically delete any older images that don't match Rule 1
  cleanup_policies {
    id     = "delete-old-versions"
    action = "DELETE"
    condition {
      tag_state = "ANY"
    }
  }

  depends_on = [google_project_service.required_apis]
}
