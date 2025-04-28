variable "location" {
  description = "The Azure location to deploy the VM"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
}

variable "ssh_public_key" {
  description = "The path to the SSH public key"
  type        = string
}

variable "network_interface_id" {
  description = "The ID of the network interface to attach to the VM"
  type        = string
}

variable "vm_name" {
  description = "The name of the VM"
  type        = string
}

variable "computer_name" {
  description = "The computer name of the VM"
  type        = string
}

variable "custom_data" {
  description = "Base64-encoded custom data for the VM"
  type        = string
  default     = null
}

resource "azurerm_linux_virtual_machine" "linux_virtual_machine" {
  name                = var.vm_name
  computer_name       = var.computer_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  network_interface_ids = [
    var.network_interface_id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = var.custom_data
}