variable "location" {
  description = "Azure region where VM will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name where VM will be deployed"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH Public Key for authentication"
  type        = string
}

variable "network_interface_id" {
  description = "The ID of the NIC to attach to the VM"
  type        = string
}

resource "azurerm_linux_virtual_machine" "mine" {
  name                = "mine-machine"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_A2_v2"
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
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
