output "gcs_bucket_name" {
  description = "Name of the GCS bucket for Terraform state"
  value       = google_storage_bucket.terraform_state.name
}

output "gcs_bucket_url" {
  description = "URL of the GCS bucket for Terraform state"
  value       = google_storage_bucket.terraform_state.url
}

output "kms_key_id" {
  description = "KMS key ID used for bucket encryption"
  value       = google_kms_crypto_key.terraform_state_key.id
}

output "backend_config" {
  description = "Backend configuration for use in main infrastructure"
  value = {
    bucket = google_storage_bucket.terraform_state.name
    prefix = "terraform/state"
  }
}