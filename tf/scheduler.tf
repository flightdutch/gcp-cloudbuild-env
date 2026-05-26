# ==========================================================================
# Cloud Scheduler (Cron Job for Report Service)
# ==========================================================================

resource "google_cloud_scheduler_job" "report_trigger" {
  name             = "${var.gcp_project_id}-${var.scheduler_name_suffix}"
  description      = "Triggers the Report Service Cloud Run function periodically"
  schedule         = var.scheduler_cron_expression
  time_zone        = var.scheduler_timezone
  attempt_deadline = "320s"
  region           = var.gcp_region

  http_target {
    http_method = "POST"

    # Placeholder URL for the future Report Service (Project 3)
    uri = "https://report-service-placeholder-${var.gcp_region}.a.run.app/generate"

    # 👇 Fixed: Changed from weekly to a generic action name suitable for daily runs
    body = base64encode("{\"action\": \"generate_report\"}")

    headers = {
      "Content-Type" = "application/json"
    }

    # Secure HTTP call using OIDC token tied to our Service Account
    oidc_token {
      service_account_email = google_service_account.function_sa.email
    }
  }

  # Ensure the Scheduler API is enabled before creating the job
  depends_on = [google_project_service.required_apis]
}
