# tf/outputs.tf

# ==============================================================================
# FIREBASE FRONTEND CONFIGURATION OUTPUTS
# ==============================================================================

# Firestore DB was created by google_firestore_database.your_db_name
# so - can get db-name directly from the resource

output "firebase_config" {
  description = "Firebase frontend configuration keys for developers"
  sensitive   = true
  value = {
    apiKey            = data.google_firebase_web_app_config.frontend_config.api_key
    authDomain        = data.google_firebase_web_app_config.frontend_config.auth_domain
    projectId         = var.gcp_project_id
    storageBucket     = google_storage_bucket.firebase_storage.name
    messagingSenderId = data.google_firebase_web_app_config.frontend_config.messaging_sender_id
    appId             = google_firebase_web_app.frontend.app_id
    # Dynamic reference to the actual Firestore database resource name
    firestoreDbId = google_firestore_database.database.name
  }
}
