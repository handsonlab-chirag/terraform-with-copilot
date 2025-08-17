# Output values after deployment

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_machine_name" {
  description = "Name of the created virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip_address" {
  description = "Public IP address of the virtual machine"
  value       = azurerm_public_ip.main.ip_address
}

output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "key_vault_name" {
  description = "Name of the created Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the created Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "private_key_secret_name" {
  description = "Name of the private key secret in Key Vault"
  value       = azurerm_key_vault_secret.private_key.name
}

output "public_key_secret_name" {
  description = "Name of the public key secret in Key Vault"
  value       = azurerm_key_vault_secret.public_key.name
}

output "virtual_network_name" {
  description = "Name of the created virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_name" {
  description = "Name of the created subnet"
  value       = azurerm_subnet.main.name
}

# Sensitive output - private key (use with caution)
output "private_key_pem" {
  description = "Private key in PEM format (sensitive)"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}
