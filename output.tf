

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}

output "location" {
  value = azurerm_resource_group.rg.location
  description = "Location of the resource group"
}
