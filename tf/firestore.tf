# ==============================================================================
# PROJECT SERVICES (Enable required APIs automatically)
# ==============================================================================

# Enable Firestore API dynamically via Terraform
resource "google_project_service" "firestore" {
  project            = var.gcp_project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false # Keep API active even if resource config changes
}

# ==============================================================================
# DATABASE RESOURCES (Firestore)
# ==============================================================================

# App Engine-less Firestore Database instantiation for system state and tracking
resource "google_firestore_database" "database" {
  name        = "${var.gcp_project_id}-db"
  # name        = "(default)"
  location_id = var.gcp_region
  type        = "FIRESTORE_NATIVE"

  # Prevents accidental deletion of the state database during terraform destroy
  deletion_policy = "POINT_IN_TIME_RECOVERY_RESTORATION_ONLY"

  # CRITICAL: Wait for the API to be fully enabled before creating the DB
  depends_on = [google_project_service.firestore]
}
