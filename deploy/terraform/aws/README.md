# AWS Deployment for Next.js + FastAPI Template

This directory contains Terraform configurations for deploying the Next.js + FastAPI template to AWS using EKS (Elastic Kubernetes Service).

## Architecture

- **EKS Cluster**: Managed Kubernetes service for running the application
- **RDS PostgreSQL**: Managed database service
- **CloudFront**: CDN for frontend static assets
- **Application Load Balancer**: Traffic distribution for the API
- **VPC**: Isolated network with public/private subnets
- **S3**: Storage for frontend assets and Terraform state

## Prerequisites

1. **AWS CLI**: [Install and configure](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
   ```bash
   aws configure
   ```

2. **Terraform**: [Install Terraform](https://terraform.io/downloads) >= 1.0

3. **kubectl**: [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

4. **Docker**: For building and pushing container images

## Setup Instructions

### 1. Set up Terraform Backend

First, create the S3 bucket and DynamoDB table for remote state storage:

```bash
cd ../tf-backend/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred bucket name (must be globally unique)
terraform init
terraform apply
```

### 2. Configure Main Infrastructure

```bash
cd ../../aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

**Important**: Update the following values in `terraform.tfvars`:
- `database_password`: Use a strong, secure password
- `state_bucket_name`: Must match the bucket created in step 1
- `project_name` and `environment`: Customize as needed

### 3. Deploy Infrastructure

```bash
# Initialize with remote backend
terraform init -backend-config="bucket=your-terraform-state-bucket"

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply
```

This will create:
- VPC with public/private subnets across 3 AZs
- EKS cluster with managed node group
- RDS PostgreSQL database
- S3 bucket for frontend assets
- CloudFront distribution
- Security groups and IAM roles

### 4. Configure kubectl

After the infrastructure is deployed, configure kubectl to access your EKS cluster:

```bash
aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw cluster_name)
```

Verify connectivity:
```bash
kubectl get nodes
```

### 5. Deploy Application to Kubernetes

Deploy the application using the Kubernetes manifests:

```bash
# Apply base manifests
kubectl apply -f ../../kubernetes/base/

# Apply AWS-specific configurations
kubectl apply -f ../../kubernetes/overlays/aws/
```

### 6. Build and Push Container Images

You'll need to build and push your application images to a container registry:

```bash
# Example using Amazon ECR
aws ecr get-login-password --region $(terraform output -raw aws_region) | docker login --username AWS --password-stdin $(terraform output -raw account_id).dkr.ecr.$(terraform output -raw aws_region).amazonaws.com

# Build and push backend image
cd ../../../fastapi_backend
docker build -t your-registry/nextjs-fastapi-backend:latest .
docker push your-registry/nextjs-fastapi-backend:latest

# Build and push frontend (if using containerized frontend)
cd ../nextjs-frontend
docker build -t your-registry/nextjs-fastapi-frontend:latest .
docker push your-registry/nextjs-fastapi-frontend:latest
```

### 7. Deploy Frontend to CloudFront

Build and deploy the frontend to the S3 bucket:

```bash
cd ../nextjs-frontend
npm run build
aws s3 sync out/ s3://$(cd ../deploy/terraform/aws && terraform output -raw frontend_bucket)/
aws cloudfront create-invalidation --distribution-id $(cd ../deploy/terraform/aws && terraform output -raw cloudfront_distribution_id) --paths "/*"
```

## Configuration

### Environment Variables

Update the Kubernetes secrets in `../../kubernetes/base/secrets.yaml` with your actual values:

- Database connection details (automatically populated from Terraform outputs)
- Application secret key
- Email configuration (if using)
- Any other environment-specific configurations

### Scaling

The EKS cluster is configured with auto-scaling:
- **Node Groups**: Automatically scale between `node_group_min_size` and `node_group_max_size`
- **Pods**: Configure Horizontal Pod Autoscaler (HPA) for application scaling

### Monitoring

Consider adding monitoring and logging:
- CloudWatch for logs and metrics
- Prometheus and Grafana for Kubernetes monitoring
- AWS X-Ray for distributed tracing

## Outputs

After successful deployment, Terraform provides these outputs:

- `cluster_name`: EKS cluster name
- `cluster_endpoint`: Kubernetes API endpoint
- `database_endpoint`: RDS endpoint
- `cloudfront_domain`: Frontend CDN domain
- `frontend_bucket`: S3 bucket for frontend assets

## Costs

Estimated monthly costs for this setup:
- EKS Cluster: ~$72 (cluster management)
- EC2 Instances: ~$30-150 (depending on instance types and count)
- RDS: ~$15-50 (depending on instance class)
- CloudFront: ~$1-10 (depending on traffic)
- Other services: ~$5-20

**Total**: ~$120-300/month for a small production workload

## Security Best Practices

- Database is deployed in private subnets
- Security groups restrict access to necessary ports only
- EKS cluster uses RBAC for access control
- Secrets are stored in Kubernetes secrets (consider using AWS Secrets Manager)
- All data at rest is encrypted

## Troubleshooting

### Common Issues

1. **EKS cluster creation fails**: Check IAM permissions and service quotas
2. **Pods can't connect to RDS**: Verify security group rules and subnet configuration
3. **ALB not creating**: Ensure AWS Load Balancer Controller is installed and configured
4. **Images not pulling**: Check ECR permissions and image names in deployments

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -n production

# View logs
kubectl logs -f deployment/backend -n production

# Describe problematic resources
kubectl describe pod <pod-name> -n production

# Access RDS from a pod (for debugging)
kubectl run psql --image=postgres:15 --rm -it --restart=Never -- psql -h <rds-endpoint> -U postgres -d nextjs_fastapi
```

## Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources first
kubectl delete -f ../../kubernetes/overlays/aws/
kubectl delete -f ../../kubernetes/base/

# Destroy Terraform infrastructure
terraform destroy

# Optionally destroy the backend (this will delete the state file!)
cd ../tf-backend/aws
terraform destroy
```

**Warning**: This will permanently delete all data including the database!