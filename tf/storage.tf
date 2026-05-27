# ==============================================================================
# STORAGE RESOURCES
# created exclusively for the business logic of APP
# ==============================================================================

# Google Cloud Storage bucket for incoming raw log files
resource "google_storage_bucket" "raw_logs" {
  name          = "${var.gcp_project_id}-raw-logs"
  location      = var.gcp_region
  force_destroy = true # Allows destroying bucket with files during testing; for PROD = false

  # Uniform bucket-level access for strict IAM control
  # Ignore any individual access settings within files
  # Only global IAM-policy works
  uniform_bucket_level_access = true

  # Protect critical bucket - enable protection against accidental execution of the terraform destroy command.
  # terraform can't do command: terraform destroy or change name of storage
  lifecycle {
    prevent_destroy = true
  }

  # Lifecycle rules managed dynamically via variables
  lifecycle_rule {
    condition {
      age = var.raw_logs_retention_days # Days before archiving older logs
    }
    action {
      type = "Delete"
    }
  }

  # Multi-part upload protection rule
  # auto-cleaner - remove incomplete multi-component downloads that last more than 7 days
  lifecycle_rule {
    condition {
      action_complete_days = 7
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}
