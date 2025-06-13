# Terraform Backend for GCP - Remote State Storage
# This creates Google Cloud Storage bucket for Terraform state management

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region

  default_labels = {
    environment = "terraform-backend"
    project     = "nextjs-fastapi-template"
    managed-by  = "terraform"
  }
}

# Generate a random suffix for bucket name (must be globally unique)
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Google Cloud Storage bucket for Terraform state
resource "google_storage_bucket" "terraform_state" {
  name          = "${var.state_bucket_name}-${random_string.bucket_suffix.result}"
  location      = var.bucket_location
  force_destroy = false

  # Enable versioning for state files
  versioning {
    enabled = true
  }

  # Lifecycle management
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  # Encryption at rest
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state_key.id
  }

  # Prevent public access
  public_access_prevention = "enforced"

  labels = {
    name        = "terraform-state-bucket"
    environment = "backend"
  }

  depends_on = [google_kms_crypto_key_iam_binding.terraform_state_key]
}

# Block public access to the bucket
resource "google_storage_bucket_iam_binding" "terraform_state_binding" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${data.google_compute_default_service_account.default.email}",
  ]
}

# Get default compute service account
data "google_compute_default_service_account" "default" {}

# KMS keyring for encryption
resource "google_kms_key_ring" "terraform_state" {
  name     = "${var.project_id}-terraform-state"
  location = var.gcp_region
}

# KMS key for bucket encryption
resource "google_kms_crypto_key" "terraform_state_key" {
  name     = "terraform-state-key"
  key_ring = google_kms_key_ring.terraform_state.id

  lifecycle {
    prevent_destroy = true
  }
}

# Grant storage service permission to use the key
resource "google_kms_crypto_key_iam_binding" "terraform_state_key" {
  crypto_key_id = google_kms_crypto_key.terraform_state_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com",
  ]
}

# Get current project information
data "google_project" "current" {}

# Optional: Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudkms.googleapis.com",
    "storage.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])

  project = var.project_id
  service = each.key

  disable_dependent_services = false
  disable_on_destroy        = false
}