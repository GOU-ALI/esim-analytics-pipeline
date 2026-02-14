variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "europe-west1-b"
}

variable "bucket_name" {
  description = "Name of the GCS bucket to create"
  type        = string
  default     = "mon-projet-telecom-123-esim-data" 
}
