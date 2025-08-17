# setup.ps1 - PowerShell script for local Terraform setup

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-terraform-demo",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "terraform-demo"
)

Write-Host "🚀 Setting up Terraform environment..." -ForegroundColor Green

# Check if Terraform is installed
try {
    $terraformVersion = terraform version
    Write-Host "✅ Terraform is installed: $($terraformVersion.Split("`n")[0])" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform is not installed. Please install Terraform first." -ForegroundColor Red
    Write-Host "Download from: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
    exit 1
}

# Check if Azure CLI is installed
try {
    $azVersion = az version --output table
    Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI is not installed. Please install Azure CLI first." -ForegroundColor Red
    Write-Host "Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check if logged into Azure
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✅ Logged into Azure as: $($account.user.name)" -ForegroundColor Green
    Write-Host "📋 Subscription: $($account.name) ($($account.id))" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Not logged into Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Navigate to terraform directory
Set-Location "terraform"

# Create terraform.tfvars from example if it doesn't exist
if (!(Test-Path "terraform.tfvars")) {
    Write-Host "📝 Creating terraform.tfvars from example..." -ForegroundColor Yellow
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    
    # Update with provided parameters
    $tfvarsContent = Get-Content "terraform.tfvars"
    $tfvarsContent = $tfvarsContent -replace 'resource_group_name = "rg-terraform-demo"', "resource_group_name = `"$ResourceGroupName`""
    $tfvarsContent = $tfvarsContent -replace 'location           = "East US"', "location           = `"$Location`""
    $tfvarsContent = $tfvarsContent -replace 'project_name       = "terraform-demo"', "project_name       = `"$ProjectName`""
    $tfvarsContent | Set-Content "terraform.tfvars"
    
    Write-Host "✅ terraform.tfvars created with your parameters" -ForegroundColor Green
} else {
    Write-Host "✅ terraform.tfvars already exists" -ForegroundColor Green
}

# Initialize Terraform
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
try {
    terraform init
    Write-Host "✅ Terraform initialized successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
    exit 1
}

# Validate configuration
Write-Host "🔍 Validating Terraform configuration..." -ForegroundColor Yellow
try {
    terraform validate
    Write-Host "✅ Terraform configuration is valid" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform validation failed" -ForegroundColor Red
    exit 1
}

# Plan deployment
Write-Host "📋 Creating Terraform execution plan..." -ForegroundColor Yellow
try {
    terraform plan -var-file="terraform.tfvars" -out=tfplan
    Write-Host "✅ Terraform plan created successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform plan failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review the plan above to ensure it creates the expected resources" -ForegroundColor White
Write-Host "2. Run 'terraform apply tfplan' to deploy the infrastructure" -ForegroundColor White
Write-Host "3. After deployment, run 'terraform output' to see connection details" -ForegroundColor White
Write-Host ""
Write-Host "To connect to the VM after deployment:" -ForegroundColor Cyan
Write-Host "1. Get the public IP: terraform output public_ip_address" -ForegroundColor White
Write-Host "2. Get private key from Key Vault using Azure CLI" -ForegroundColor White
Write-Host "3. Use SSH to connect to the VM" -ForegroundColor White
Write-Host ""
Write-Host "To destroy resources later:" -ForegroundColor Yellow
Write-Host "terraform destroy -var-file='terraform.tfvars'" -ForegroundColor White
