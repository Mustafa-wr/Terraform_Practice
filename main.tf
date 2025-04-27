provider "azurerm" {
  features {}
}
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-mine"
}

variable "location" {
  description = "The Azure location to deploy resources"
  type        = string
  default     = "westus2"
}

variable "admin_username" {
  description = "The admin username for the virtual machine"
  type        = string
  default     = "adminuser"
  
}

variable "admin_password" {
  description = "The admin password for the virtual machine"
  type        = string
  default     = "P@ssw0rd1234!"
}

variable "ssh_public_key" {
  description = "The SSH public key for the virtual machine"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_network_name" {
  description = "The name of the network interface for the virtual machine"
  type        = string
  default     = "mine-nic"
}

variable "ssh_private_key_path" {
  description = "The path to the SSH private key for the virtual machine"
  type        = string
  default     = "~/.ssh/id_rsa"
  sensitive = true
}

data "azurerm_platform_image" "mine" {
  location            = azurerm_resource_group.rg.location
  publisher           = "debian"
  offer              = "debian-11"
  sku                = "11"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "mine" {
  name                = var.vm_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "mine" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mine.name
  address_prefixes     = cidrsubnets(azurerm_virtual_network.mine.address_space[0], 8, 1)
}

resource "azurerm_public_ip" "mine" {
  name                = "mine-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}


resource "azurerm_network_interface" "mine" {
  name                = var.vm_network_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mine.id
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id         = azurerm_public_ip.mine.id
  }
}

module "vm" {
  source               = "./modules/vm"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  admin_username       = var.admin_username
  ssh_public_key       = var.ssh_public_key
  network_interface_id = azurerm_network_interface.mine.id
}

resource "null_resource" "configure_vm" {
  depends_on = [module.vm.linux_virtual_machine]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]

    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.ssh_private_key_path)
      host        = azurerm_public_ip.mine.ip_address
      timeout     = "5m"
    }
  }
}


