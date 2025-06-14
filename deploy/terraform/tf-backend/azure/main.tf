# Terraform Backend for Azure - Remote State Storage
# This creates an Azure Storage Account and Blob Container for Terraform state

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Resource group for backend resources
resource "azurerm_resource_group" "backend" {
  name     = var.resource_group_name
  location = var.location
}

# Random suffix for globally unique storage account name
resource "random_string" "sa_suffix" {
  length  = 6
  upper   = false
  special = false
}

# Storage account for Terraform state
resource "azurerm_storage_account" "tf_state" {
  name                     = "${var.storage_account_name}${random_string.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.backend.name
  location                 = azurerm_resource_group.backend.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
}

# Container for state files
resource "azurerm_storage_container" "tf_state" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.tf_state.name
  container_access_type = "private"
}

output "backend_config" {
  description = "Backend configuration for use in main infrastructure"
  value = {
    resource_group_name  = azurerm_resource_group.backend.name
    storage_account_name = azurerm_storage_account.tf_state.name
    container_name       = azurerm_storage_container.tf_state.name
    key                  = "terraform.tfstate"
  }
}
