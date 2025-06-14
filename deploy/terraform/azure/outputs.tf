output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "storage_account_name" {
  description = "Storage account for frontend"
  value       = azurerm_storage_account.frontend.name
}

output "cdn_endpoint" {
  description = "Hostname of CDN endpoint"
  value       = azurerm_cdn_endpoint.main.host_name
}

output "database_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_url" {
  description = "Database connection URL"
  value       = "postgresql://${var.database_username}:${var.database_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_name}?sslmode=require"
  sensitive   = true
}
