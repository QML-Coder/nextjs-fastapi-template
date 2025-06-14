variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "nextjs-fastapi"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "node_count" {
  description = "Number of nodes in default node pool"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "database_username" {
  description = "Database administrator username"
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "nextjs_fastapi"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "db_sku" {
  description = "SKU for PostgreSQL flexible server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "Storage size for PostgreSQL (MB)"
  type        = number
  default     = 32768
}
