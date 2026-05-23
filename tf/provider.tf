# tf/provider.tf

terraform {
  required_version = ">= 1.8.0" # Сумісно з нашою версією 1.15.4

  # 1. Визначаємо необхідні провайдери
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # Adding google-beta provider required for Firebase management
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    # Adding time provider for handling propagation delays
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }

  # 2. connect to the tfstate-bucket by default
  # backend "gcs" {
  #   bucket = "bf-analyzer-tfstate"
  #   prefix = "terraform/state"
  # }

  # 2. Left empty inside the repository code to allow dynamic injection
  backend "gcs" {}
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Configuring the beta provider (Firebase-config)
provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
