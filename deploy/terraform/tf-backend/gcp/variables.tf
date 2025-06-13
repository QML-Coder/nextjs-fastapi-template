variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for the backend resources"
  type        = string
  default     = "us-central1"
}

variable "state_bucket_name" {
  description = "Base name of the GCS bucket for Terraform state storage (will have random suffix added)"
  type        = string
  default     = "nextjs-fastapi-terraform-state"
}

variable "bucket_location" {
  description = "Location for the GCS bucket (region or multi-region)"
  type        = string
  default     = "US"
}