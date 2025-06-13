# GCP Infrastructure for Next.js + FastAPI Template
# Creates GKE cluster, Cloud SQL database, Cloud CDN, and supporting resources

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }

  backend "gcs" {
    # This will be configured during terraform init
    # bucket = "your-terraform-state-bucket"
    # prefix = "terraform/state"
  }
}

# Data sources
data "google_project" "current" {}
data "google_client_config" "current" {}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}"
  
  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed-by  = "terraform"
  }

  # Get available zones in the region
  zones = data.google_compute_zones.available.names
}

# GCP Providers
provider "google" {
  project = var.project_id
  region  = var.gcp_region

  default_labels = local.common_labels
}

provider "google-beta" {
  project = var.project_id
  region  = var.gcp_region

  default_labels = local.common_labels
}

# Get available zones
data "google_compute_zones" "available" {
  region = var.gcp_region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "dns.googleapis.com",
    "certificatemanager.googleapis.com",
    "storage.googleapis.com"
  ])

  project = var.project_id
  service = each.key

  disable_dependent_services = false
  disable_on_destroy        = false
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${local.cluster_name}-network"
  auto_create_subnetworks = false
  routing_mode           = "GLOBAL"

  depends_on = [google_project_service.required_apis]
}

# Subnet for GKE cluster
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${local.cluster_name}-gke-subnet"
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id

  # Secondary IP ranges for pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pod_ip_cidr_range
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.service_ip_cidr_range
  }

  private_ip_google_access = true
}

# Cloud Router for NAT gateway
resource "google_compute_router" "main" {
  name    = "${local.cluster_name}-router"
  region  = var.gcp_region
  network = google_compute_network.main.id

  bgp {
    asn = 64514
  }
}

# NAT Gateway for private nodes internet access
resource "google_compute_router_nat" "main" {
  name                               = "${local.cluster_name}-nat"
  router                            = google_compute_router.main.name
  region                            = var.gcp_region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# GKE Cluster
resource "google_container_cluster" "main" {
  name     = local.cluster_name
  location = var.gcp_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  # IP allocation policy
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }

  # Workload Identity for secure pod-to-GCP communication
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network policy
  network_policy {
    enabled = true
  }

  # Release channel for automatic updates
  release_channel {
    channel = var.gke_release_channel
  }

  # Cluster autoscaling
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = var.cluster_autoscaling_min_cpu
      maximum       = var.cluster_autoscaling_max_cpu
    }
    resource_limits {
      resource_type = "memory"
      minimum       = var.cluster_autoscaling_min_memory
      maximum       = var.cluster_autoscaling_max_memory
    }
  }

  # Binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Database encryption
  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.gke_key.id
  }

  depends_on = [
    google_project_service.required_apis,
    google_compute_subnetwork.gke_subnet,
    google_kms_crypto_key_iam_binding.gke_key_binding
  ]
}

# GKE Node Pool
resource "google_container_node_pool" "main" {
  name       = "${local.cluster_name}-node-pool"
  cluster    = google_container_cluster.main.name
  location   = var.gcp_region
  node_count = var.node_pool_size

  # Auto-scaling
  autoscaling {
    min_node_count = var.node_pool_min_size
    max_node_count = var.node_pool_max_size
  }

  # Node configuration
  node_config {
    preemptible  = var.use_preemptible_nodes
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-ssd"

    # Google service account
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Security
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = local.common_labels

    tags = ["gke-node", "${local.cluster_name}-node"]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${local.cluster_name}-gke-nodes"
  display_name = "GKE Nodes Service Account"
  description  = "Service account for GKE nodes in ${local.cluster_name} cluster"
}

# IAM bindings for GKE node service account
resource "google_project_iam_member" "gke_nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# KMS keyring for cluster encryption
resource "google_kms_key_ring" "gke" {
  name     = "${local.cluster_name}-keyring"
  location = var.gcp_region
}

# KMS key for cluster encryption
resource "google_kms_crypto_key" "gke_key" {
  name     = "${local.cluster_name}-key"
  key_ring = google_kms_key_ring.gke.id

  lifecycle {
    prevent_destroy = true
  }
}

# IAM binding for GKE to use the KMS key
resource "google_kms_crypto_key_iam_binding" "gke_key_binding" {
  crypto_key_id = google_kms_crypto_key.gke_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.current.number}@container-engine-robot.iam.gserviceaccount.com",
  ]
}

# Cloud SQL instance
resource "google_sql_database_instance" "main" {
  name             = "${local.cluster_name}-db"
  database_version = var.database_version
  region           = var.gcp_region

  settings {
    tier              = var.database_tier
    availability_type = var.database_availability_type
    disk_size         = var.database_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.gcp_region
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = var.database_backup_retention_days
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
      require_ssl     = true
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    user_labels = local.common_labels
  }

  deletion_protection = var.environment == "prod" ? true : false

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database
resource "google_sql_database" "main" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
}

# Database user
resource "google_sql_user" "main" {
  name     = var.database_username
  instance = google_sql_database_instance.main.name
  password = var.database_password
}

# Private VPC connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${local.cluster_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_project_service.required_apis]
}

# Cloud Storage bucket for frontend assets
resource "google_storage_bucket" "frontend" {
  name     = "${local.cluster_name}-frontend-${random_string.frontend_suffix.result}"
  location = var.frontend_bucket_location

  # Website configuration
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # CORS configuration
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  labels = local.common_labels
}

resource "random_string" "frontend_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Make frontend bucket publicly readable
resource "google_storage_bucket_iam_member" "frontend_public_read" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Cloud CDN backend bucket
resource "google_compute_backend_bucket" "frontend" {
  name        = "${local.cluster_name}-frontend-backend"
  bucket_name = google_storage_bucket.frontend.name
  enable_cdn  = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    max_ttl                      = 86400
    client_ttl                   = 3600
    negative_caching             = true
    serve_while_stale            = 86400
    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = false
    }
  }
}

# Load balancer for frontend (Cloud CDN)
resource "google_compute_url_map" "frontend" {
  name            = "${local.cluster_name}-frontend-lb"
  default_service = google_compute_backend_bucket.frontend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.frontend.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.api.id
    }
  }
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "frontend_https" {
  name       = "${local.cluster_name}-frontend-https"
  target     = google_compute_target_https_proxy.frontend.id
  port_range = "443"
  ip_address = google_compute_global_address.frontend.id
}

# Global forwarding rule for HTTP (redirect to HTTPS)
resource "google_compute_global_forwarding_rule" "frontend_http" {
  name       = "${local.cluster_name}-frontend-http"
  target     = google_compute_target_http_proxy.frontend.id
  port_range = "80"
  ip_address = google_compute_global_address.frontend.id
}

# Global IP address
resource "google_compute_global_address" "frontend" {
  name = "${local.cluster_name}-frontend-ip"
}

# HTTPS proxy
resource "google_compute_target_https_proxy" "frontend" {
  name             = "${local.cluster_name}-https-proxy"
  url_map          = google_compute_url_map.frontend.id
  ssl_certificates = [google_compute_managed_ssl_certificate.frontend.id]
}

# HTTP proxy for redirect
resource "google_compute_target_http_proxy" "frontend" {
  name    = "${local.cluster_name}-http-proxy"
  url_map = google_compute_url_map.redirect_to_https.id
}

# URL map for HTTP to HTTPS redirect
resource "google_compute_url_map" "redirect_to_https" {
  name = "${local.cluster_name}-redirect-https"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

# Managed SSL certificate
resource "google_compute_managed_ssl_certificate" "frontend" {
  name = "${local.cluster_name}-ssl-cert"

  managed {
    domains = var.domain_name != "" ? [var.domain_name, "www.${var.domain_name}"] : ["${local.cluster_name}.example.com"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Backend service for API (placeholder - will be updated to point to GKE service)
resource "google_compute_backend_service" "api" {
  name                  = "${local.cluster_name}-api-backend"
  protocol              = "HTTP"
  timeout_sec           = 30
  enable_cdn            = false
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_health_check.api.id]

  # This will be updated to point to the actual GKE service
  # For now, create with no backends - will be configured via kubectl
}

# Health check for API backend
resource "google_compute_health_check" "api" {
  name               = "${local.cluster_name}-api-health-check"
  timeout_sec        = 5
  check_interval_sec = 10

  http_health_check {
    port         = 80
    request_path = "/health"
  }
}