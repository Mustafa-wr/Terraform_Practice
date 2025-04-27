variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-mine"
}

data "azurerm_platform_image" "mine" {
  location            = azurerm_resource_group.rg.location
  publisher           = "debian"
  offer              = "debian-11"
  sku                = "11"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "westus2"
}

resource "azurerm_virtual_network" "mine" {
  name                = "mine-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
  name                = "mine-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mine.id
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id         = azurerm_public_ip.mine.id
  }
}

resource "azurerm_linux_virtual_machine" "mine" {
  name                = "mine-machine"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_A2_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.mine.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = data.azurerm_platform_image.mine.publisher
	offer     = data.azurerm_platform_image.mine.offer
	sku       = data.azurerm_platform_image.mine.sku
	version   = data.azurerm_platform_image.mine.version
  }
}

provider "azurerm" {
  features {}
}
