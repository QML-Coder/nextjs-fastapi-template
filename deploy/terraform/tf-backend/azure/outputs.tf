output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.tf_state.name
}

output "container_name" {
  description = "Name of the blob container"
  value       = azurerm_storage_container.tf_state.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.backend.name
}

output "backend_config" {
  description = "Backend configuration block for Terraform"
  value       = {
    resource_group_name  = azurerm_resource_group.backend.name
    storage_account_name = azurerm_storage_account.tf_state.name
    container_name       = azurerm_storage_container.tf_state.name
    key                  = "terraform.tfstate"
  }
}
