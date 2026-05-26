#!/bin/bash
set -u
source ./project_config.env

echo " Create terraform tfstate-bucket for project $PROJECT_ID..."

# 1. Create bucket
gcloud storage buckets create gs://$TFSTATE_BUCKET_NAME \
    --project=$PROJECT_ID \
    --location=$REGION \
    --uniform-bucket-level-access

# 2. Configure State Bucket - Versioning
gcloud storage buckets update gs://$TFSTATE_BUCKET_NAME --versioning

# 3. Configure State Bucket - Lifecycle
# 3.1 Create a temporary lifecycle rule file (store 10 versions)

cat <<EOF > lifecycle-policy.json
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {
        "numNewerVersions": ${TFSTATE_RETENTION_VERSIONS},
        "isLive": false
      }
    }
  ]
}
EOF

# 3.2 Applying the policy to the bucket
gcloud storage buckets update gs://$TFSTATE_BUCKET_NAME --lifecycle-file=lifecycle-policy.json

# 4. Check Configure
gcloud storage buckets describe gs://$TFSTATE_BUCKET_NAME --format="yaml" | grep -i version


# 5. Remove tmp-file: lifecycle-policy.json
#rm lifecycle-policy.json
