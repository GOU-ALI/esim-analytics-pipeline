#!/bin/bash

# Configuration
PROJECT_ID="mon-projet-telecom-123"
REGION="europe-west1"
CLUSTER_NAME="telecom-cluster"
BUCKET_NAME="mon-projet-telecom-123-esim-data"
DATASET_NAME="esim_analytics"

echo "⚠️  ATTENTION : This script will DELETE all project resources."
echo "resources: Cluster '$CLUSTER_NAME', Dataset '$DATASET_NAME', Bucket '$BUCKET_NAME'"
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "--- Deleting Dataproc Cluster ---"
gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID --quiet

echo "--- Deleting BigQuery Dataset ---"
bq rm -r -f -d $PROJECT_ID:$DATASET_NAME

echo "--- Deleting GCS Bucket ---"
gcloud storage rm -r gs://$BUCKET_NAME

echo "✅ Cleanup Completed. No more billing for these resources."
