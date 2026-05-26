#!/bin/bash
set -u
source ./project_config.env

echo "Starting GitHub Workload Identity Federation setup for project $PROJECT_ID..."

# Ensure we are targeting the correct GCP project
gcloud config set project "$PROJECT_ID"

# ------------------------------------------------------------------------------
echo "Step 1: Enable the WIF IAM Credentials API..."
gcloud services enable iamcredentials.googleapis.com --project="${PROJECT_ID}"

# ------------------------------------------------------------------------------
echo "Step 2: Creating IAM Service Account for GitHub Actions..."

gcloud iam service-accounts create "$WIF_SA_NAME" \
    --description="Service account used by GitHub Actions to deploy infrastructure" \
    --display-name="GitHub Actions Deployer"

WIF_SA_EMAIL="$WIF_SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# --- Pause: Wait for GCP IAM replication ---
echo "60 sec - Waiting for Google Cloud IAM replication to complete..."
sleep 60

# Grant DevOps-engineer roles to this Service Account within the project
echo "Assigning IAM roles to $WIF_SA_EMAIL..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$WIF_SA_EMAIL" --role="roles/editor"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$WIF_SA_EMAIL" --role="roles/iam.securityAdmin"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:$WIF_SA_EMAIL" --role="roles/iam.serviceAccountUser"

# ------------------------------------------------------------------------------
echo "Step 3: Creating Workload Identity Pool and Provider..."

# 3.1. Create the Workload Identity Pool
gcloud iam workload-identity-pools create "$WIF_POOL_NAME" \
    --location="global" \
    --display-name="GitHub Actions Pool" \
    --description="Pool for authenticating GitHub repositories via OIDC"

# 3.2. Create the OIDC Provider inside the pool with security conditions
gcloud iam workload-identity-pools providers create-oidc "$WIF_PROVIDER_NAME" \
    --location="global" \
    --workload-identity-pool="$WIF_POOL_NAME" \
    --display-name="GitHub Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository == '$GITHUB_REPO'" \
    --issuer-uri="https://token.actions.githubusercontent.com"

# ------------------------------------------------------------------------------
echo "Step 4: Binding WIF Pool to the IAM Service Account (Workload Identity User)..."

# Retrieve the unique GCP Project Number needed for the principalSet identifier
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")

# Allow any workflow running in the specified GitHub repository to assume this SA role
gcloud iam service-accounts add-iam-policy-binding "$WIF_SA_EMAIL" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$WIF_POOL_NAME/attribute.repository/$GITHUB_REPO"

# ==============================================================================
# github variables - copy/save
# ==============================================================================
echo "------------------------------------------------------------------------------"
echo " CONFIGURATION COMPLETED SUCCESSFULLY!"
echo "------------------------------------------------------------------------------"
echo "Copy the values below and add them as Repository Variables in GitHub settings:"
echo ""
echo "1. Var Name:  GCP_PROJECT_ID"
echo "    Value:          $PROJECT_ID"
echo ""
echo "2. Var Name:  GCP_SERVICE_ACCOUNT"
echo "    Value:          $WIF_SA_EMAIL"
echo ""
echo "3. Var Name:  GCP_WORKLOAD_IDENTITY_PROVIDER"
echo "    Value:          projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$WIF_POOL_NAME/providers/$WIF_PROVIDER_NAME"
echo "------------------------------------------------------------------------------"
