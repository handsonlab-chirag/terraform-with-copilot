# Terraform with Azure DevOps

This repository contains Terraform configuration files to deploy Azure infrastructure along with an Azure DevOps pipeline for automated deployment.

## Architecture Overview

The Terraform configuration deploys the following Azure resources:

- **Resource Group**: Container for all resources
- **Virtual Network**: Network infrastructure with subnet
- **Ubuntu 22.04 VM**: Standard_B1s (smallest VM size) 
- **Public IP**: Static IP for external access
- **Network Security Group**: Firewall rules allowing SSH access
- **Key Vault**: Secure storage for SSH keys
- **SSH Key Pair**: Generated and stored in Key Vault

## Prerequisites

1. **Azure Subscription**: Active Azure subscription
2. **Azure DevOps Project**: With appropriate permissions
3. **Service Connection**: Azure Resource Manager service connection in Azure DevOps
4. **Terraform State Storage**: Already configured with:
   - Resource Group: `terraform-state-rg`
   - Storage Account: `mytfsastatefiles`
   - Container: `tfstate`

## Repository Structure

```
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output values
│   └── terraform.tfvars.example  # Example variable values
├── azure-pipelines.yml      # Azure DevOps pipeline
└── README.md               # This file
```

## Terraform Configuration Details

### Key Features

- **Latest Terraform**: Uses Terraform >= 1.9.0
- **Latest AzureRM Provider**: Uses azurerm provider ~> 4.0
- **Smallest VM Size**: Standard_B1s (1 vCPU, 1 GB RAM)
- **Ubuntu 22.04 LTS**: Latest LTS version
- **Automated SSH Key Generation**: Keys stored securely in Key Vault
- **Network Security**: NSG allows SSH access on port 22
- **Remote State**: Configured for your existing state storage

### Resources Created

1. **azurerm_resource_group**: Main resource container
2. **azurerm_virtual_network**: VNet with 10.0.0.0/16 address space
3. **azurerm_subnet**: Subnet with 10.0.1.0/24 address space
4. **azurerm_public_ip**: Static public IP for VM access
5. **azurerm_network_security_group**: Security rules for SSH
6. **azurerm_network_interface**: VM network interface
7. **azurerm_key_vault**: Secure key storage
8. **azurerm_linux_virtual_machine**: Ubuntu 22.04 VM
9. **tls_private_key**: Generated SSH key pair
10. **azurerm_key_vault_secret**: Stores private and public keys

## Setup Instructions

### 1. Configure Variables

Copy the example variables file and customize:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform.tfvars` with your desired values:

```hcl
resource_group_name = "your-rg-name"
location           = "East US"
project_name       = "your-project"
vm_size           = "Standard_B1s"
admin_username    = "azureuser"
```

### 2. Azure DevOps Pipeline Setup

1. **Create Service Connection**:
   - Go to Project Settings → Service Connections
   - Create new Azure Resource Manager connection
   - Use Service Principal (automatic) or Manual
   - Name it (update `azureServiceConnection` in pipeline)

2. **Update Pipeline Variables**:
   - Edit `azure-pipelines.yml`
   - Update `azureServiceConnection` with your service connection name


3. **Create Pipeline**:
   - In Azure DevOps, go to Pipelines → New Pipeline
   - Select your repository
   - Use existing Azure Pipelines YAML file
   - Point to `azure-pipelines.yml`

### 3. Environment Setup

Create an environment named `production` in Azure DevOps:
- Go to Pipelines → Environments
- Create new environment: `production`
- Add approval gates if needed

## Pipeline Workflow

The Azure DevOps pipeline has three stages:

### 1. Plan Stage
- Installs Terraform
- Runs `terraform init` with remote state
- Validates configuration
- Creates execution plan
- Publishes plan as artifact

### 2. Apply Stage (Automatic on main branch)
- Downloads plan artifact
- Applies infrastructure changes
- Deploys to production environment

### 3. Destroy Stage (Manual only)
- Destroys all infrastructure
- Runs only when manually triggered

## Usage

### Local Development

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Create execution plan
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"

# Get outputs
terraform output
```

### Connecting to VM

After deployment, get the connection details:

```bash
# Get public IP
terraform output public_ip_address

# Get SSH command
terraform output ssh_connection_command

# Retrieve private key from Key Vault (using Azure CLI)
az keyvault secret show --vault-name <key-vault-name> --name vm-private-key --query value -o tsv > private_key.pem
chmod 600 private_key.pem

# Connect via SSH
ssh -i private_key.pem azureuser@<public-ip>
```

## Security Considerations

1. **SSH Keys**: Generated automatically and stored in Key Vault
2. **Network Security**: NSG restricts access to SSH port only
3. **Key Vault Access**: Uses current Azure context for access
4. **No Password Authentication**: VM uses SSH keys only
5. **Private Key Storage**: Securely stored in Azure Key Vault

## Customization

### VM Size Options

To use a different VM size, update the `vm_size` variable:

```hcl
# Standard_B1s  - 1 vCPU, 1 GB RAM (smallest)
# Standard_B1ms - 1 vCPU, 2 GB RAM
# Standard_B2s  - 2 vCPU, 4 GB RAM
vm_size = "Standard_B1s"
```

### Network Configuration

Modify network settings in `main.tf`:

```hcl
# Virtual Network CIDR
address_space = ["10.0.0.0/16"]

# Subnet CIDR
address_prefixes = ["10.0.1.0/24"]
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   - Verify Azure DevOps service connection
   - Check Azure permissions

2. **State File Issues**:
   - Ensure storage account exists
   - Verify container and access permissions

3. **VM Size Availability**:
   - Check VM size availability in your region
   - Use `az vm list-sizes --location "East US"`

4. **Key Vault Access**:
   - Verify current user/service principal has access
   - Check Key Vault access policies

## Cleanup

To destroy all resources:

1. **Via Pipeline**: Manually trigger the Destroy stage
2. **Via Local CLI**:
   ```bash
   cd terraform
   terraform destroy -var-file="terraform.tfvars"
   ```

## Cost Optimization

- **VM Size**: Standard_B1s is the smallest/cheapest option
- **Storage**: Premium LRS for OS disk (better performance)
- **Public IP**: Static IP may incur small charges
- **Key Vault**: Standard tier (no additional cost for basic usage)

Estimated monthly cost: ~$15-25 USD (varies by region)

---

**Note**: This configuration is designed for development/testing. For production use, consider additional security measures, backup strategies, and monitoring solutions.
