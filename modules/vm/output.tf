output "linux_virtual_machine" {
  description = "The created Linux VM"
  value       = azurerm_linux_virtual_machine.linux_virtual_machine
}

output "vm_id" {
  description = "The ID of the VM"
  value       = azurerm_linux_virtual_machine.linux_virtual_machine.id
}