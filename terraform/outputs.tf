output "bucket_name" {
  value = google_storage_bucket.data_lake.name
}

output "dataset_id" {
  value = google_bigquery_dataset.analytics_dataset.dataset_id
}

output "cluster_name" {
  value = google_dataproc_cluster.spark_cluster.name
}
