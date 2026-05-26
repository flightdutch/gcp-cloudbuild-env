
# Run Functions - Artifact Registry repository

resource "google_artifact_registry_repository" "functions_repo" {
  project       = var.gcp_project_id
  location      = var.gcp_region
  repository_id = "${var.gcp_project_id}-functions"
  description   = "Docker repository for Cloud Run functions compiled images"
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis]
}
