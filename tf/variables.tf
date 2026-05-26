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
