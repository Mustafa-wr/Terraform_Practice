# In main.tf - Create the resource group, network, and DNS zone components

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
  description = "The admin username for the virtual machines"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "The admin password for the virtual machines"
  type        = string
  default     = "P@ssw0rd1234!"
  sensitive   = true
}

variable "ssh_public_key" {
  description = "The path to the SSH public key for the VMs"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "The path to the SSH private key for the VMs"
  type        = string
  default     = "~/.ssh/id_rsa"
  sensitive   = true
}

variable "vm_network_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "mine-vnet"
}

variable "dns_zone_name" {
  description = "The name of the private DNS zone"
  type        = string
  default     = "internal.example.com"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "mine" {
  name                = var.vm_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Define frontend subnet
resource "azurerm_subnet" "frontend" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mine.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define backend subnet
resource "azurerm_subnet" "backend" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mine.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Frontend NSG
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Frontend NSG Rules - Allow HTTP
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}

# Frontend NSG Rules - Allow HTTPS
resource "azurerm_network_security_rule" "allow_https" {
  name                        = "allow-https"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}

# Create Backend NSG
resource "azurerm_network_security_group" "backend_nsg" {
  name                = "backend-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Backend NSG Rule - Allow traffic ONLY from Frontend subnet
resource "azurerm_network_security_rule" "allow_frontend_only" {
  name                        = "allow-frontend-only"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_subnet.frontend.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
}

# Backend NSG Rule - Deny all other inbound traffic
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
}

# Associate NSGs with corresponding Subnets
resource "azurerm_subnet_network_security_group_association" "frontend_nsg_association" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "backend_nsg_association" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

# Create a Private DNS Zone
resource "azurerm_private_dns_zone" "private" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
}

# Link Private DNS Zone to Virtual Network with auto-registration enabled
resource "azurerm_private_dns_zone_virtual_network_link" "private_link" {
  name                  = "vnet-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private.name
  virtual_network_id    = azurerm_virtual_network.mine.id
  registration_enabled  = true
}

# Public IPs for VMs
resource "azurerm_public_ip" "vm1_pip" {
  name                = "vm1-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "vm2_pip" {
  name                = "vm2-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "vm1_nic" {
  name                = "vm1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1_pip.id
  }
}

resource "azurerm_network_interface" "vm2_nic" {
  name                = "vm2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2_pip.id
  }
}

module "vm1" {
  source               = "./modules/vm"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  admin_username       = var.admin_username
  ssh_public_key       = var.ssh_public_key
  network_interface_id = azurerm_network_interface.vm1_nic.id
  vm_name              = "vm1"
  computer_name        = "vm1" 
  custom_data          = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y iputils-ping dnsutils
    EOF
  )
}

module "vm2" {
  source               = "./modules/vm"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  admin_username       = var.admin_username
  ssh_public_key       = var.ssh_public_key
  network_interface_id = azurerm_network_interface.vm2_nic.id
  vm_name              = "vm2"
  computer_name        = "vm2" 
  custom_data          = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y iputils-ping dnsutils
    EOF
  )
}

output "vm1_public_ip" {
  value = azurerm_public_ip.vm1_pip.ip_address
  description = "The public IP address of VM1"
  depends_on = [module.vm1]
}

output "vm2_public_ip" {
  value = azurerm_public_ip.vm2_pip.ip_address
  description = "The public IP address of VM2"
  depends_on = [module.vm2]
}

output "test_instructions" {
  value = <<-EOT
    To test private DNS resolution:
    
    1. SSH into VM1:
       ssh ${var.admin_username}@<vm1_public_ip>
    
    2. Test DNS resolution and ping VM2:
       ping vm2.${var.dns_zone_name}
  EOT
}