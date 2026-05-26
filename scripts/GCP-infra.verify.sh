#!/bin/bash
set -u

# ==========================================================================
# GCP Infrastructure Verification Script for current project
# ==========================================================================

source ./project_config.env

# Initialize Error Counter
ERROR_COUNT=0

echo "=========================================================================="
echo "🔍 Starting Infrastructure Verification for Project: ${PROJECT}"
echo "📍 Target Region: ${REGION}"
echo "=========================================================================="
echo ""

# --------------------------------------------------------------------------
# 1. Verify Storage Bucket & Pub/Sub Notification Link
# --------------------------------------------------------------------------
echo "📦 [1/4] Checking Cloud Storage Bucket and Notification..."
if gcloud storage buckets describe gs://${LOGS_BUCKET_NAME} --format="value(name)" &> /dev/null; then
    echo "  ✅ Storage Bucket 'gs://${LOGS_BUCKET_NAME}' exists."

    RAW_NOTIFICATION=$(gcloud storage buckets notifications list gs://${LOGS_BUCKET_NAME} 2>/dev/null || echo "NOT_FOUND")

    if echo "$RAW_NOTIFICATION" | grep -q "topic: //pubsub.googleapis.com/projects/${PROJECT}/topics/${PUBSUB_TOPIC_NAME}"; then
        echo "  ✅ Bucket notification successfully routes events to Pub/Sub topic: ${PUBSUB_TOPIC_NAME}"
    else
        echo "  ❌ ERROR: Bucket notification config missing or pointing to the wrong topic!"
        ERROR_COUNT=$((ERROR_COUNT + 1)) # 👇 Increment error count
    fi
else
    echo "  ❌ ERROR: Storage Bucket 'gs://${LOGS_BUCKET_NAME}' was not found!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# --------------------------------------------------------------------------
# 2. Verify Pub/Sub Topic
# --------------------------------------------------------------------------
echo "📣 [2/4] Checking Pub/Sub Messaging Core..."
if gcloud pubsub topics describe projects/${PROJECT}/topics/${PUBSUB_TOPIC_NAME} --format="value(name)" &> /dev/null; then
    echo "  ✅ Pub/Sub Topic '${PUBSUB_TOPIC_NAME}' exists and is active."
else
    echo "  ❌ ERROR: Pub/Sub Topic '${PUBSUB_TOPIC_NAME}' was not found!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# --------------------------------------------------------------------------
# 3. Verify Service Account & ObjectViewer IAM Permissions
# --------------------------------------------------------------------------
echo "🪪 [3/4] Checking Dedicated Service Account and Bucket IAM..."
SA_EMAIL="${PUBSUB_SA_NAME}@${PROJECT}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe ${SA_EMAIL} --format="value(email)" &> /dev/null; then
    echo "  ✅ Service Account '${SA_EMAIL}' exists."

    if gcloud storage buckets get-iam-policy gs://${LOGS_BUCKET_NAME} 2>/dev/null | grep -A 2 "serviceAccount:${SA_EMAIL}" | grep -q "roles/storage.objectViewer"; then
        echo "  ✅ IAM: Service Account has designated 'storage.objectViewer' access to raw logs bucket."
    else
        echo "  ❌ ERROR: Service Account is missing explicit access to the bucket!"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
else
    echo "  ❌ ERROR: Service Account '${SA_EMAIL}' was not found!"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# --------------------------------------------------------------------------
# 4. Verify Cloud Scheduler (Cron Automation Trigger)
# --------------------------------------------------------------------------
echo "⏰ [4/4] Checking Cloud Scheduler Automation Trigger..."
SCHEDULER_PATH="projects/${PROJECT}/locations/${REGION}/jobs/${SCHEDULER_NAME}"

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
    exit 1 # 👇 Forces GitHub Actions workflow or local script to fail dynamically
fi
