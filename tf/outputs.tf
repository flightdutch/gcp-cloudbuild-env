# tf/outputs.tf

# ==============================================================================
# FIREBASE FRONTEND CONFIGURATION OUTPUTS
# ==============================================================================

output "firebase_config" {
  description = "Frontend application config credentials for Firebase SDK connection"
  sensitive   = true # Marks output as sensitive to prevent plain-text exposure in logs
  value       = {
    api_key            = data.google_firebase_web_app_config.frontend_config.api_key
    auth_domain        = data.google_firebase_web_app_config.frontend_config.auth_domain
    database_url       = data.google_firebase_web_app_config.frontend_config.database_url
    storage_bucket     = data.google_firebase_web_app_config.frontend_config.storage_bucket
    messaging_sender_id = data.google_firebase_web_app_config.frontend_config.messaging_sender_id
    measurement_id     = data.google_firebase_web_app_config.frontend_config.measurement_id
  }
}
