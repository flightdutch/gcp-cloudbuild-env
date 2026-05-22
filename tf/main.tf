# ==============================================================================
# STORAGE RESOURCES
# ==============================================================================

# Google Cloud Storage bucket for incoming raw log files
resource "google_storage_bucket" "raw_logs" {
  name                        = "${var.gcp_project_id}-raw-logs"
  location                    = var.gcp_region
  force_destroy               = false
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30 # Days before archiving older logs
    }
    action {
      type = "Delete"
    }
  }
}

# ==============================================================================
# DATABASE RESOURCES (Firestore)
# ==============================================================================

# App Engine-less Firestore Database instantiation for system state and tracking
resource "google_firestore_database" "database" {
  name        = "(default)"
  location_id = var.gcp_region
  type        = "FIRESTORE_NATIVE"

  # Prevents accidental deletion of the state database during terraform destroy
  deletion_policy = "POINT_IN_TIME_RECOVERY_RESTORATION_ONLY"
}
