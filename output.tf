output pupblic_ip {
  value = resource.azurerm_public_ip.mine.ip_address
  description = "Public IP address of the virtual machine"
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}