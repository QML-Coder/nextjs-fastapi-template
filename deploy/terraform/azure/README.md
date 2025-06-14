# Azure Deployment for Next.js + FastAPI Template

This directory contains Terraform configurations for deploying the project to **Azure** using **Azure Kubernetes Service (AKS)**, **Azure Database for PostgreSQL Flexible Server**, and **Azure CDN** for the frontend.

## Prerequisites

1. **Azure CLI**: Install and login
   ```bash
   az login
   az account set --subscription YOUR_SUBSCRIPTION_ID
   ```
2. **Terraform** >= 1.0
3. **kubectl** for interacting with AKS

Before running Terraform ensure the providers are installed and your Azure CLI session is active.

## Setup Instructions

### 1. Configure Remote State

Create the storage account and container used for storing Terraform state:

```bash
cd ../tf-backend/azure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription and desired names
terraform init
terraform apply
```

### 2. Deploy Infrastructure

```bash
cd ../../azure
cp terraform.tfvars.example terraform.tfvars
# Update variables such as `database_password`
terraform init \
  -backend-config="resource_group_name=<backend-rg>" \
  -backend-config="storage_account_name=<backend-sa>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=terraform.tfstate"
terraform apply
```

### 3. Configure kubectl

Retrieve cluster credentials:

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw cluster_name)
```

### 4. Deploy Application

Apply the Kubernetes manifests and Azure-specific overlay:

```bash
kubectl apply -f ../../kubernetes/base/
kubectl apply -f ../../kubernetes/overlays/azure/
```

### 5. Deploy Frontend

Build the frontend and upload the static files to the storage account used by the CDN:

```bash
cd ../../../nextjs-frontend
npm run build
az storage blob upload-batch \
  --destination '$web' \
  --source out/ \
  --account-name $(terraform -chdir=../deploy/terraform/azure output -raw storage_account_name)
az cdn endpoint purge \
  --profile-name $(terraform -chdir=../deploy/terraform/azure output -raw cdn_endpoint | cut -d'.' -f1) \
  --name $(terraform -chdir=../deploy/terraform/azure output -raw cdn_endpoint | cut -d'.' -f1) \
  --resource-group $(terraform -chdir=../deploy/terraform/azure output -raw resource_group_name) \
  --content-paths "/*"
```

## Outputs

After deployment Terraform will output values such as:

- `cluster_name` – AKS cluster name
- `cdn_endpoint` – hostname of the CDN endpoint
- `database_url` – connection string for the database

Use these values to configure your application.
