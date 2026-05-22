variable "gcp_project_id" {
  type        = string
  description = "The ID of the Google Cloud Project"
}

variable "gcp_region" {
  type        = string
  description = "The default region for GCP resources"
  default     = "europe-west3" # Ваш дефолтний регіон Франкфурт
}

