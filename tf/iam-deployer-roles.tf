# ==========================================================================
# IAM Roles for Terraform Deployer Service Account (github-deployer)
# ==========================================================================

locals {
  # The 5 bootstrap roles required to manage infrastructure and deploy Cloud Run functions
  deployer_roles = [
    "roles/cloudfunctions.developer",
    "roles/run.developer",
    "roles/artifactregistry.admin", # SA has the right to create repositories at the project level
    "roles/cloudbuild.builds.editor",
    "roles/storage.admin" #  Added to manage raw-logs, tfstate, and staging deployment buckets
  ]
}

# Assign the roles to the GitHub Deployer Service Account
resource "google_project_iam_member" "deployer_bootstrap_roles" {
  for_each = toset(local.deployer_roles)

  project = var.gcp_project_id
  role    = each.key
  member  = "serviceAccount:${var.terraform_sa_name}@${var.gcp_project_id}.iam.gserviceaccount.com"

  depends_on = [google_project_service.required_apis]
}

# ==============================================================================
# IAM ROLES FOR RUNTIME SERVICE ACCOUNT: "${var.gcp_project_id}-${var.service_account_suffix}"
#                                        "${var.gcp_project_id}-fn-sa
# add perms to take logs from in-car app
# ==============================================================================

# Allow service account to create objects (required for PUT Signed URLs generation)
resource "google_storage_bucket_iam_member" "sa_storage_creator" {
  bucket = google_storage_bucket.raw_logs.name # Auto-dependency on bucket-name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.function_sa.email}" # Auto-dependency on SA-name
}

# Allow service account to sign tokens and URLs on behalf of itself
resource "google_service_account_iam_member" "sa_token_creator" {
  service_account_id = google_service_account.function_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.function_sa.email}"
}
