# ==============================================================================
# FIREBASE STORAGE BUCKET (Physical Initialization)
# ==============================================================================

# Explicitly provisions the default Firebase Storage bucket to avoid lazy-init issues
resource "google_firebase_storage_bucket" "default" {
  provider  = google-beta
  project   = var.gcp_project_id
  bucket_id = "${var.gcp_project_id}.firebasestorage.app"

  # Ensure this happens after the main Firebase project framework is ready
  # Links directly to the project definition in firebase.tf
  # and GCS-storage will be activated
  # CRITICAL: Force the bucket to wait for the 90-second propagation delay
  depends_on = [
    google_firebase_project.default,
    google_project_service.firebase_storage,
    time_sleep.wait_90_seconds # Adds cross-file dependency to ensure APIs and internal service accounts are ready
  ]
}

# ==============================================================================
# FIREBASE STORAGE SECURITY RULES
# ==============================================================================

# Defines the actual security rule logic for file access control
resource "google_firebaserules_ruleset" "storage" {
  provider = google-beta
  project  = var.gcp_project_id

  source {
    files {
      name    = "storage.rules"
      content = <<EOF
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      // Allows read/write access only to authenticated users
      allow read, write: if request.auth != null;
    }
  }
}
EOF
    }
  }

  # Wait for the physical bucket to exist before defining rules for it
  depends_on = [google_firebase_storage_bucket.default]
}

# Releases and binds the defined ruleset specifically to the Firebase Storage service
resource "google_firebaserules_release" "storage" {
  provider     = google-beta
  project      = var.gcp_project_id
  name         = "firebase.storage/${var.gcp_project_id}.firebasestorage.app"
  ruleset_name = google_firebaserules_ruleset.storage.name

  # Ensure the ruleset object is fully created before releasing it
  depends_on = [google_firebaserules_ruleset.storage]
}
