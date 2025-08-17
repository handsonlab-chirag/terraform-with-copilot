# Configure the Azure Provider
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "mytfsastatefiles"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Generate random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Create Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Create Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.project_name}-public-ip-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Create Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.project_name}-nsg-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Create Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.project_name}-nic-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = var.tags
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Generate SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create Azure Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "${var.project_name}-kv-${random_string.suffix.result}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update",
      "Purge",
      "Recover"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  tags = var.tags
}

# Store Private Key in Key Vault
resource "azurerm_key_vault_secret" "private_key" {
  name         = "vm-private-key"
  value        = tls_private_key.ssh_key.private_key_pem
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

# Store Public Key in Key Vault
resource "azurerm_key_vault_secret" "public_key" {
  name         = "vm-public-key"
  value        = tls_private_key.ssh_key.public_key_openssh
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.project_name}-vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # Disable password authentication
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}
