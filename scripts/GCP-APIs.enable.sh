#!/bin/bash
set -u
source ./project_config.env

# Enable API
# Enable the required IAM Credentials API for Workload Identity Federation
gcloud services enable iamcredentials.googleapis.com --project="${PROJECT_ID}"

# Activater Firestore API
# Enable the Cloud Firestore API for your active project
gcloud services enable firestore.googleapis.com --project="${PROJECT_ID}"


# Add Role Datastore Owner
# Add Datastore Owner role to allow the service account to create the Firestore database
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:github-deployer@bf-analyzer.iam.gserviceaccount.com" \
    --role="roles/datastore.owner"


# Activate Cloud Resource Manager API
# Enable the Cloud Resource Manager API to allow Terraform to manage other APIs
gcloud services enable cloudresourcemanager.googleapis.com --project="${PROJECT_ID}"

echo "Show list of available services for the project"
gcloud services list --available
