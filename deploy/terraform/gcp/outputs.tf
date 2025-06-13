output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for GKE control plane"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.main.location
}

output "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = google_container_cluster.main.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "gcp_region" {
  description = "GCP region"
  value       = var.gcp_region
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "subnet_name" {
  description = "Name of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "database_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.main.name
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "database_private_ip" {
  description = "Cloud SQL instance private IP address"
  value       = google_sql_database_instance.main.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.main.name
}

output "database_username" {
  description = "Database username"
  value       = google_sql_user.main.name
  sensitive   = true
}

output "frontend_bucket" {
  description = "Frontend assets bucket name"
  value       = google_storage_bucket.frontend.name
}

output "frontend_bucket_url" {
  description = "Frontend assets bucket URL"
  value       = google_storage_bucket.frontend.url
}

output "load_balancer_ip" {
  description = "Global load balancer IP address"
  value       = google_compute_global_address.frontend.address
}

output "cdn_domain" {
  description = "Cloud CDN domain name"
  value       = google_compute_global_address.frontend.address
}

output "ssl_certificate_domains" {
  description = "Domains covered by the SSL certificate"
  value       = google_compute_managed_ssl_certificate.frontend.managed[0].domains
}

# Kubernetes configuration
output "kubectl_config" {
  description = "kubectl config command"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${var.gcp_region} --project ${var.project_id}"
}

# Database connection string
output "database_url" {
  description = "Database connection URL"
  value       = "postgresql://${google_sql_user.main.name}:${var.database_password}@${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.main.name}"
  sensitive   = true
}

# Service account emails
output "gke_service_account_email" {
  description = "Email of the GKE nodes service account"
  value       = google_service_account.gke_nodes.email
}

# KMS key information
output "kms_key_id" {
  description = "KMS key ID for cluster encryption"
  value       = google_kms_crypto_key.gke_key.id
}

# Network endpoints
output "api_domain" {
  description = "API domain (load balancer IP)"
  value       = "api.${google_compute_global_address.frontend.address}"
}

output "frontend_domain" {
  description = "Frontend domain (load balancer IP or custom domain)"
  value       = var.domain_name != "" ? var.domain_name : google_compute_global_address.frontend.address
}