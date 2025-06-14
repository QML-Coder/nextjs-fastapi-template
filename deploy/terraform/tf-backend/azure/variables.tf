variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for backend resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "tf-backend-rg"
}

variable "storage_account_name" {
  description = "Base name of the storage account (will have random suffix added)"
  type        = string
  default     = "tftstate"
}

variable "container_name" {
  description = "Name of the blob container"
  type        = string
  default     = "tfstate"
}
