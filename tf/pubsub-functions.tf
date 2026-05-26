# ==========================================================================
# 1. Dedicated Service Account for Future Cloud Run Functions
# ==========================================================================

# template Name - Dynamic combination: project-id + suffix ( ${var.gcp_project_id}-${var.suffix} )

resource "google_service_account" "function_sa" {
  account_id   = "${var.gcp_project_id}-${var.service_account_suffix}"
  display_name = "Service Account for Log Analyzer Cloud Run Functions"

  # wait until the IAM API (services.tf) is fully enabled
  depends_on = [google_project_service.required_apis]
}

# ==========================================================================
# 2. IAM Permissions (Least Privilege Principle)
# ==========================================================================

# Grant the Service Account read-only permissions to the raw logs bucket
resource "google_storage_bucket_iam_member" "viewer_live_logs" {
  bucket = "${var.gcp_project_id}-${var.log_bucket_name_suffix}"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.function_sa.email}"
}

# Grant the Service Account permissions to read/write data in Firestore
resource "google_project_iam_member" "firestore_user" {
  project = var.gcp_project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

# Service Eventarc provides a connection between Pub/Sub and Cloud Run functionality
resource "google_project_iam_member" "fn_sa_eventarc_receiver" {
  project = var.gcp_project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${var.gcp_project_id}-fn-sa@${var.gcp_project_id}.iam.gserviceaccount.com"

  depends_on = [google_project_service.required_apis]
}

# ==========================================================================
# 3. Pub/Sub Messaging Infrastructure (The Event-Driven Core)
# ==========================================================================

# Create the central Pub/Sub topic using the dynamic project-ID prefix
resource "google_pubsub_topic" "log_events" {
  name = "${var.gcp_project_id}-${var.pubsub_topic_name_suffix}"

  # wait until the IAM API (services.tf) is fully enabled
  depends_on = [google_project_service.required_apis]
}

# Allow Google Cloud Storage service to publish events into our Pub/Sub topic
data "google_storage_project_service_account" "gcs_account" {}

resource "google_pubsub_topic_iam_member" "gcs_publisher" {
  topic  = google_pubsub_topic.log_events.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# Configure the Storage Bucket to automatically send notifications on new file uploads
resource "google_storage_notification" "bucket_notification" {
  bucket         = "${var.gcp_project_id}-${var.log_bucket_name_suffix}"
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.log_events.id
  event_types    = ["OBJECT_FINALIZE"] # Triggers ONLY when a file is fully uploaded

  # Ensure the IAM role is applied before creating the notification link
  depends_on = [google_project_service.required_apis]
}
