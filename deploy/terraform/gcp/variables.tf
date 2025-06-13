variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "nextjs-fastapi"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

# Networking Configuration
variable "gke_subnet_cidr" {
  description = "CIDR range for the GKE subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pod_ip_cidr_range" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "service_ip_cidr_range" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "master_ipv4_cidr_block" {
  description = "CIDR range for GKE master nodes"
  type        = string
  default     = "10.3.0.0/28"
}

# GKE Configuration
variable "gke_release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "STABLE"
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "node_disk_size_gb" {
  description = "Disk size for GKE nodes (GB)"
  type        = number
  default     = 50
}

variable "node_pool_size" {
  description = "Initial number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "node_pool_min_size" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "node_pool_max_size" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 5
}

variable "use_preemptible_nodes" {
  description = "Use preemptible nodes for cost savings"
  type        = bool
  default     = false
}

# Cluster Autoscaling
variable "cluster_autoscaling_min_cpu" {
  description = "Minimum CPU cores for cluster autoscaling"
  type        = number
  default     = 1
}

variable "cluster_autoscaling_max_cpu" {
  description = "Maximum CPU cores for cluster autoscaling"
  type        = number
  default     = 20
}

variable "cluster_autoscaling_min_memory" {
  description = "Minimum memory (GB) for cluster autoscaling"
  type        = number
  default     = 2
}

variable "cluster_autoscaling_max_memory" {
  description = "Maximum memory (GB) for cluster autoscaling"
  type        = number
  default     = 80
}

# Database Configuration
variable "database_version" {
  description = "PostgreSQL version for Cloud SQL"
  type        = string
  default     = "POSTGRES_15"
}

variable "database_tier" {
  description = "Cloud SQL tier/machine type"
  type        = string
  default     = "db-f1-micro"
}

variable "database_availability_type" {
  description = "Cloud SQL availability type (ZONAL, REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "database_disk_size" {
  description = "Cloud SQL disk size (GB)"
  type        = number
  default     = 20
}

variable "database_backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "nextjs_fastapi"
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Frontend Configuration
variable "frontend_bucket_location" {
  description = "Location for frontend assets bucket"
  type        = string
  default     = "US"
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "create_dns_zone" {
  description = "Whether to create a Cloud DNS zone"
  type        = bool
  default     = false
}