# Temporary validation file without backend
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

# Local values for resource naming
locals {
  # Clean project name for Key Vault (alphanumeric and dashes only, max 24 chars)
  # Keep base name short to accommodate random suffix
  kv_name_base   = substr(replace(replace(lower(var.project_name), "_", "-"), "/[^a-z0-9-]/", ""), 0, 8)
  key_vault_name = "${local.kv_name_base}-kv-${random_string.suffix.result}"
}

# Generate random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Test the Key Vault name validation
output "test_key_vault_name" {
  value = local.key_vault_name
}

variable "project_name" {
  description = "Base name for all resources"
  type        = string
  default     = "terraform-demo"
}
