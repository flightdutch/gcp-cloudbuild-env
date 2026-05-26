variable "gcp_project_id" {
  type        = string
  description = "The ID of the Google Cloud Project"
}

variable "gcp_region" {
  type        = string
  description = "The default region for GCP resources"
  default     = "europe-west3"
}

variable "log_bucket_name_suffix" {
  type        = string
  description = "Suffix for the raw logs storage bucket"
  default     = "raw-logs"
}

variable "pubsub_topic_name_suffix" {
  type        = string
  description = "Suffix for the Pub/Sub topic for log events"
  default     = "log-events"
}

variable "service_account_suffix" {
  type        = string
  description = "Suffix for the dedicated service account name"
  default     = "fn-sa"
}

variable "scheduler_name_suffix" {
  type        = string
  description = "Suffix for the Cloud Scheduler job"
  default     = "report-cron"
}

variable "scheduler_timezone" {
  type        = string
  description = "The timezone for the Cloud Scheduler job (e.g., Europe/Kyiv, America/New_York)"
  default     = "Europe/Kyiv"
}

variable "scheduler_cron_expression" {
  type        = string
  description = "The CRON expression for the Cloud Scheduler job (e.g., '0 1 * * *' for daily at 01:00 AM)"
  default     = "0 1 * * *"
}

variable "artifact_registry_suffix" {
  type        = string
  default     = "functions"
  description = "Suffix for the Artifact Registry repository holding function images"
}

variable "terraform_sa_name" {
  type        = string
  default     = "github-deployer"
  description = "The name of the service account used by GitHub Actions for deployment"
}

variable "artifact_registry_retention_count" {
  type        = number
  default     = 10
  description = "The maximum number of recent container image versions to keep in Artifact Registry"
}
