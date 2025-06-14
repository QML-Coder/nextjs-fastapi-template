# Azure Infrastructure for Next.js + FastAPI Template
# Provisions AKS, PostgreSQL Flexible Server, Storage Account and CDN

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

  backend "azurerm" {
    # configured during terraform init using values from tf-backend
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  prefix       = "${var.project_name}-${var.environment}"
  location     = var.location
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = local.location
  tags     = local.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${local.prefix}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${local.prefix}-k8s"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${local.prefix}-pg"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_login    = var.database_username
  administrator_password = var.database_password
  sku_name               = var.db_sku
  version                = var.postgres_version

  storage_mb            = var.db_storage_mb
  backup_retention_days = 7
  zone                  = null

  tags = local.tags
}

resource "azurerm_postgresql_flexible_database" "main" {
  name                = var.database_name
  server_id           = azurerm_postgresql_flexible_server.main.id
  collation           = "en_US.utf8"
  charset             = "UTF8"
  depends_on          = [azurerm_postgresql_flexible_server.main]
}

# Storage account for frontend
resource "random_string" "sa_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "frontend" {
  name                     = "${local.prefix}sa${random_string.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
  tags = local.tags
}

resource "azurerm_cdn_profile" "main" {
  name                = "${local.prefix}-cdn"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_Microsoft"
  tags                = local.tags
}

resource "azurerm_cdn_endpoint" "main" {
  name                = "${local.prefix}-endpoint"
  profile_name        = azurerm_cdn_profile.main.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_cdn_profile.main.location
  is_http_allowed     = true
  is_https_allowed    = true
  origin_host_header  = azurerm_storage_account.frontend.primary_web_host

  origin {
    name      = "storage"
    host_name = azurerm_storage_account.frontend.primary_web_host
  }

  tags = local.tags
}


