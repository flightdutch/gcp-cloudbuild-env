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
