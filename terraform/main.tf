provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. GCS Bucket
resource "google_storage_bucket" "data_lake" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true # Allows destroying bucket even if it contains objects

  role_entity = [
    "OWNER:user-${var.project_id}",
  ]
}

# 2. BigQuery Dataset
resource "google_bigquery_dataset" "analytics_dataset" {
  dataset_id                  = "esim_analytics"
  friendly_name               = "eSIM Analytics Dataset"
  description                 = "Dataset for eSIM KPIs and stats"
  location                    = var.region
  delete_contents_on_destroy  = true # CAUTION: Deletes tables on destroy
}

# 3. Dataproc Cluster
resource "google_dataproc_cluster" "spark_cluster" {
  name   = "telecom-cluster-tf"
  region = var.region

  cluster_config {
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-2"
      disk_config {
        boot_disk_size_gb = 50
      }
    }

    worker_config {
      num_instances = 0 # Single Node Cluster
    }

    software_config {
      image_version = "2.2-debian12"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
    }
  }
}
