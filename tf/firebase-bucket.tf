# tf/firebase-bucket.tf

# ==============================================================================
# FIREBASE STORAGE BUCKET (Clean naming without domain dots)
# ==============================================================================

resource "google_storage_bucket" "firebase_storage" {
  name          = "${var.gcp_project_id}-firebase-storage"
  location      = var.gcp_region
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  depends_on = [time_sleep.wait_90_seconds]
}

# Link our custom bucket to Firebase Management layer
resource "google_firebase_storage_bucket" "default" {
  provider  = google-beta
  project   = var.gcp_project_id
  bucket_id = google_storage_bucket.firebase_storage.name
}

# ==============================================================================
# FIREBASE STORAGE SECURITY RULES
# ==============================================================================

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
      allow read, write: if request.auth != null;
    }
  }
}
EOF
    }
  }

  depends_on = [google_firebase_storage_bucket.default]
}

resource "google_firebaserules_release" "storage" {
  provider = google-beta
  project  = var.gcp_project_id
  # Match the new custom bucket name format
  name         = "firebase.storage/${var.gcp_project_id}-firebase-storage"
  ruleset_name = google_firebaserules_ruleset.storage.name

  depends_on = [google_firebaserules_ruleset.storage]
}
