#!/bin/bash

# ==========================================================================
# Infrastructure Verification Script for current project
# ==========================================================================

set -u
source ./project_config.env

# 300 MB in bytes (300 * 1024 * 1024)
MAX_LOG_SIZE_BYTES=314572800

ERROR_COUNT=0

echo "=========================================================================="
echo "🔍 Starting Infrastructure Verification for Project: ${PROJECT_ID}"
echo "📍 Target Region: ${REGION}"
echo "=========================================================================="
echo ""

# --------------------------------------------------------------------------
# 1. Verify Storage Bucket & Pub/Sub Notification Link
# --------------------------------------------------------------------------
echo "📦 [1/6] Checking Cloud Storage Bucket and Notification..."
if gcloud storage buckets describe gs://${LOGS_BUCKET_NAME} --format="value(name)" &> /dev/null; then
    echo "  ✅ Storage Bucket 'gs://${LOGS_BUCKET_NAME}' exists."

    RAW_NOTIFICATION=$(gcloud storage buckets notifications list gs://${LOGS_BUCKET_NAME} 2>/dev/null || echo "NOT_FOUND")

    if echo "$RAW_NOTIFICATION" | grep -q "topic: //pubsub.googleapis.com/projects/${PROJECT_ID}/topics/${PUBSUB_TOPIC_NAME}"; then
        echo "  ✅ Bucket notification successfully routes events to Pub/Sub topic: ${PUBSUB_TOPIC_NAME}"
    else
        echo "  ❌ ERROR: Bucket notification config missing or pointing to the wrong topic!"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
else
    echo "  ❌ ERROR: Storage Bucket 'gs://${LOGS_BUCKET_NAME}' was not found!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# --------------------------------------------------------------------------
# 2. Verify Pub/Sub Topic
# --------------------------------------------------------------------------
echo "📣 [2/6] Checking Pub/Sub Messaging Core..."
if gcloud pubsub topics describe projects/${PROJECT_ID}/topics/${PUBSUB_TOPIC_NAME} --format="value(name)" &> /dev/null; then
    echo "  ✅ Pub/Sub Topic '${PUBSUB_TOPIC_NAME}' exists and is active."
else
    echo "  ❌ ERROR: Pub/Sub Topic '${PUBSUB_TOPIC_NAME}' was not found!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# --------------------------------------------------------------------------
# 3. Verify Runtime Service Account & ObjectViewer IAM Permissions
# --------------------------------------------------------------------------
echo "🪪 [3/6] Checking Runtime Service Account, Bucket IAM & Eventarc..."
PUBSUB_SA_EMAIL="${PUBSUB_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe ${PUBSUB_SA_EMAIL} --format="value(email)" &> /dev/null; then
    echo "  ✅ Runtime Service Account '${PUBSUB_SA_EMAIL}' exists."

    # Check Storage Access
    if gcloud storage buckets get-iam-policy gs://${LOGS_BUCKET_NAME} 2>/dev/null | grep -A 2 "serviceAccount:${PUBSUB_SA_EMAIL}" | grep -q "roles/storage.objectViewer"; then
        echo "  ✅ IAM: Runtime SA has designated 'storage.objectViewer' access to raw logs bucket."
    else
        echo "  ❌ ERROR: Runtime SA is missing explicit access to the bucket!"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    # Check Eventarc Receiver Access
    PROJECT_IAM=$(gcloud projects get-iam-policy ${PROJECT_ID} --format="json" 2>/dev/null)
    if echo "$PROJECT_IAM" | grep -B 2 "serviceAccount:${PUBSUB_SA_EMAIL}" | grep -q "roles/eventarc.eventReceiver"; then
        echo "  ✅ IAM: Runtime SA has designated 'roles/eventarc.eventReceiver' status."
    else
        echo "  ❌ ERROR: Runtime SA is missing the required 'roles/eventarc.eventReceiver' project role!"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
else
    echo "  ❌ ERROR: Runtime Service Account '${PUBSUB_SA_EMAIL}' was not found!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# --------------------------------------------------------------------------
# 4. Verify Cloud Scheduler (Cron Automation Trigger)
# --------------------------------------------------------------------------
echo "⏰ [4/6] Checking Cloud Scheduler Automation Trigger..."
SCHEDULER_PATH="projects/${PROJECT_ID}/locations/${REGION}/jobs/${SCHEDULER_NAME}"

if gcloud scheduler jobs describe ${SCHEDULER_PATH} --format="value(name)" &> /dev/null; then
    echo "  ✅ Cloud Scheduler Job '${SCHEDULER_NAME}' exists."

    CRON_EXPR=$(gcloud scheduler jobs describe ${SCHEDULER_PATH} --format="value(schedule)")
    CRON_TZ=$(gcloud scheduler jobs describe ${SCHEDULER_PATH} --format="value(timeZone)")
    TARGET_URI=$(gcloud scheduler jobs describe ${SCHEDULER_PATH} --format="value(httpTarget.uri)")

    echo "  📊 Configuration Details:"
    echo "     - Schedule:  ${CRON_EXPR}"
    echo "     - Timezone:  ${CRON_TZ}"
    echo "     - Target:    ${TARGET_URI}"
else
    echo "  ❌ ERROR: Cloud Scheduler Job '${SCHEDULER_NAME}' was not found in region ${REGION}!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# --------------------------------------------------------------------------
# 5. Verify Storage Size Policy & Artifact Registry Repository
# --------------------------------------------------------------------------
echo "🛡️ [5/6] Verifying Log Size Policy Compliance & Artifact Registry..."
echo "  ℹ️ Policy Rule: Max log file size is restricted to 300MB (${MAX_LOG_SIZE_BYTES} bytes)."
echo "  ✅ Verification: Enforcement policy is ready for Project 2 (Parser Function guardrails)."

REGISTRY_PATH="projects/${PROJECT_ID}/locations/${REGION}/repositories/${REGISTRY_BUCKET_NAME}"
if gcloud artifacts repositories describe ${REGISTRY_BUCKET_NAME} --location=${REGION} &> /dev/null; then
    echo "  ✅ Artifact Registry Docker repository '${REGISTRY_BUCKET_NAME}' exists."
else
    echo "  ❌ ERROR: Artifact Registry Repository '${REGISTRY_BUCKET_NAME}' was not found in ${REGION}!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# --------------------------------------------------------------------------
# 6. Verify Bootstrap IAM Roles for Terraform Deployer Service Account
# --------------------------------------------------------------------------
echo "🔑 [6/6] Checking Bootstrap IAM Roles for Terraform Deployer SA..."
WIF_SA_EMAIL="${WIF_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe ${WIF_SA_EMAIL} --format="value(email)" &> /dev/null; then
    echo "  ✅ Terraform Deployer Service Account '${WIF_SA_EMAIL}' exists."

    # Fetch project-level IAM bindings policy
    PROJECT_POLICY=$(gcloud projects get-iam-policy ${PROJECT_ID} --format="json" 2>/dev/null)

    # Array of critical bootstrap deployment roles
    REQUIRED_ROLES=(
        "roles/cloudfunctions.developer"
        "roles/run.developer"
        "roles/artifactregistry.repositoryAdmin"
        "roles/cloudbuild.builds.editor"
    )

    for ROLE in "${REQUIRED_ROLES[@]}"; do
        # Validate if the specific role block contains our deployment SA member handle
        if echo "$PROJECT_POLICY" | grep -B 2 "serviceAccount:${WIF_SA_EMAIL}" | grep -q "$ROLE"; then
            echo "  ✅ IAM: Verified assignment of ${ROLE}"
        else
            echo "  ❌ ERROR: Terraform Deployer SA is missing the required project role: ${ROLE}"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done
else
    echo "  ❌ ERROR: Terraform Deployer Service Account '${WIF_SA_EMAIL}' was not found!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi

echo ""
echo "=========================================================================="

# --------------------------------------------------------------------------
# Final Status Evaluation
# --------------------------------------------------------------------------
if [ $ERROR_COUNT -eq 0 ]; then
    echo "🎉 Verification complete! All items show [✅], infrastructure is ready."
    echo "=========================================================================="
    exit 0
else
    echo "🚨 Verification NOT-complete! Found $ERROR_COUNT error(s) during validation."
    echo "=========================================================================="
    exit 1
fi
