
# ==============================================================================
# STORAGE RESOURCES
# created exclusively for the business logic of APP
# ==============================================================================

# Google Cloud Storage bucket for incoming raw log files
resource "google_storage_bucket" "raw_logs" {
  name                        = "${var.gcp_project_id}-raw-logs"
  location                    = var.gcp_region
  force_destroy               = false
  uniform_bucket_level_access = true

  # Protect critical bucket - enable protection against accidental execution of the terraform destroy command.
  lifecycle {
    prevent_destroy = true
  }

  lifecycle_rule {
    condition {
      age = 30 # Days before archiving older logs
    }
    action {
      type = "Delete"
    }
  }
}

