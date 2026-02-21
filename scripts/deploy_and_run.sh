#!/bin/bash

# Configuration
# PROJECT_ID="YOUR_PROJECT_ID" # Set this env var or edit here
if [ -z "$PROJECT_ID" ]; then
    read -p "Enter your GCP Project ID: " PROJECT_ID
fi
REGION="europe-west1"
CLUSTER_NAME="telecom-cluster"
BUCKET_NAME="mon-projet-telecom-123-esim-data"

echo "==================================================="
echo "🚀 Starting Deployment: eSIM Analytics Pipeline"
echo "==================================================="

# 1. Provisioning Infrastructure (Manual)
echo "--- 1. Provisioning Infrastructure (Manual) ---"

echo "Creating GCS Bucket: $BUCKET_NAME"
gcloud storage buckets create gs://$BUCKET_NAME --location=$REGION --project=$PROJECT_ID || echo "Bucket might already exist"

echo "Creating BigQuery Dataset: esim_analytics"
bq mk --location=$REGION -d $PROJECT_ID:esim_analytics || echo "Dataset might already exist"

echo "Creating Dataproc Cluster: $CLUSTER_NAME"
gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --project=$PROJECT_ID \
    --master-machine-type=n1-standard-4 \
    --master-boot-disk-size=50 \
    --single-node \
    --image-version=2.2-debian12 || echo "Cluster might already exist"

# 2. Build Scala Project
echo "--- 2. Building Scala Project ---"
sbt clean package
if [ $? -ne 0 ]; then
    echo "❌ Build Failed! Exiting."
    exit 1
fi

# 3. Upload to GCS
echo "--- 3. Uploading Data & Code to GCS ---"
gsutil cp data/*.csv gs://$BUCKET_NAME/raw/
gsutil cp target/scala-2.12/esimanalytics_2.12-0.1.jar gs://$BUCKET_NAME/code/

# 4. Submit Spark Job
echo "--- 4. Submitting Spark Job to Dataproc ---"
gcloud dataproc jobs submit spark \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --project=$PROJECT_ID \
    --class=com.telecom.EsimKpiJob \
    --jars=gs://$BUCKET_NAME/code/esimanalytics_2.12-0.1.jar \
    -- $PROJECT_ID $BUCKET_NAME esim_analytics

if [ $? -eq 0 ]; then
    echo "✅ Job Completed Successfully!"
else
    echo "❌ Job Failed!"
fi

# 5. Optional Cleanup
echo "==================================================="
echo "Do you want to DESTROY the infrastructure now? (Cleanup)"
read -p "Type 'yes' to destroy: " -n 3 -r
echo
if [[ $REPLY =~ "yes" ]]
then
    echo "--- 4. Destroying Infrastructure ---"
    export PROJECT_ID
    sh scripts/cleanup.sh
    echo "✅ Cleanup Completed."
else
    echo "⚠️  Infrastructure left running. Don't forget to run scripts/cleanup.sh later!"
fi
