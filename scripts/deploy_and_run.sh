#!/bin/bash

# Configuration
# PROJECT_ID="YOUR_PROJECT_ID" # Set this env var or edit here
if [ -z "$PROJECT_ID" ]; then
    read -p "Enter your GCP Project ID: " PROJECT_ID
fi
REGION="europe-west1"
CLUSTER_NAME="telecom-cluster-tf"
BUCKET_NAME="mon-projet-telecom-123-esim-data"

echo "==================================================="
echo "🚀 Starting Deployment: eSIM Analytics Pipeline"
echo "==================================================="

# 1. Terraform Apply
echo "--- 1. Provisioning Infrastructure (Terraform) ---"
cd terraform
terraform init -input=false
terraform apply -var="project_id=$PROJECT_ID" -auto-approve
if [ $? -ne 0 ]; then
    echo "❌ Terraform Apply Failed!"
    exit 1
fi
cd ..

# 2. Upload to GCS
echo "--- 2. Uploading Data & Code to GCS ---"
gsutil cp data/*.csv gs://$BUCKET_NAME/raw/
gsutil cp target/scala-2.12/esimanalytics_2.12-0.1.jar gs://$BUCKET_NAME/code/

# 3. Submit Spark Job
echo "--- 3. Submitting Spark Job to Dataproc ---"
gcloud dataproc jobs submit spark \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --class=com.telecom.EsimKpiJob \
    --jars=gs://$BUCKET_NAME/code/esimanalytics_2.12-0.1.jar

if [ $? -eq 0 ]; then
    echo "✅ Job Completed Successfully!"
else
    echo "❌ Job Failed!"
fi

# 4. Optional Cleanup
echo "==================================================="
echo "Do you want to DESTROY the infrastructure now? (Cleanup)"
read -p "Type 'yes' to destroy: " -n 3 -r
echo
if [[ $REPLY =~ "yes" ]]
then
    echo "--- 4. Destroying Infrastructure ---"
    cd terraform
    terraform destroy -var="project_id=$PROJECT_ID" -auto-approve
    echo "✅ Cleanup Completed."
else
    echo "⚠️  Infrastructure left running. Don't forget to cleanup later!"
fi
