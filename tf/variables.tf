variable "gcp_project_id" {
  type        = string
  description = "The ID of the Google Cloud Project"
}

variable "gcp_region" {
  type        = string
  description = "The default region for GCP resources"
  default     = "europe-west3" # Ваш дефолтний регіон Франкфурт
}

# tfstate-bucket name - standard-name
# initial bucket for terrafoem - workflow step 4. Terraform Init
#       backend-config="bucket=${{ vars.GCP_PROJECT_ID }}-tfstate"
variable "tfstate_bucket_name" {
  type        = string
  description = "The name of the S3/GCS bucket used for storing Terraform state"
  default     = "bf-analyzer-tfstate"
}
