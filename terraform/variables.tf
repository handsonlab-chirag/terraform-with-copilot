# Variables for the Terraform configuration

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-terraform-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "uksouth"
}

variable "project_name" {
  description = "Base name for all resources"
  type        = string
  default     = "terraform-demo"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_B1s" # Smallest VM size (1 vCPU, 1 GB RAM)
}

variable "admin_username" {
  description = "Admin username for the Virtual Machine"
  type        = string
  default     = "azureuser"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Terraform-Demo"
    ManagedBy   = "Terraform"
  }
}
