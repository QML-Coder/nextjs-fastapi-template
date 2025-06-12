# Deployment Guide

This directory contains deployment configurations for the Next.js + FastAPI template across multiple platforms and cloud providers.

## All Deployment Options

### Infrastructure as Code (Terraform)
- **AWS**: EKS + CloudFront + RDS (`make deploy-aws`, `make destroy-aws`)
- **GCP**: GKE + Cloud CDN + Cloud SQL (`make deploy-gcp`, `make destroy-gcp`)
- **Azure**: AKS + Azure CDN + Azure Database (`make deploy-azure`, `make destroy-azure`)
- **DigitalOcean**: Managed Kubernetes + Spaces CDN (`make deploy-digitalocean`, `make destroy-digitalocean`)

### Platform as a Service
- **Heroku**: Managed platform with buildpacks (`make deploy-heroku`, `make destroy-heroku`)
- **Railway**: Modern PaaS with Git integration (`make deploy-railway`, `make destroy-railway`)
- **Fly.io**: Global application platform (`make deploy-flyio`, `make destroy-flyio`)
- **Hetzner Cloud**: European cloud provider (`make deploy-hetzner`, `make destroy-hetzner`)

### Container Orchestration
- **Docker Compose**: Local/small production deployments (`make deploy-docker`, `make destroy-docker`)
- **Kubernetes**: Manual cluster deployment (`make deploy-k8s-manual`, `make destroy-k8s-manual`)

## Quick Start

```bash
# Infrastructure deployments
make deploy-aws           # Deploy to AWS EKS + CloudFront
make deploy-gcp           # Deploy to GCP GKE + Cloud CDN  
make deploy-azure         # Deploy to Azure AKS + Azure CDN
make deploy-digitalocean  # Deploy to DigitalOcean Kubernetes

# Platform deployments
make deploy-heroku        # Deploy to Heroku
make deploy-railway       # Deploy to Railway
make deploy-flyio         # Deploy to Fly.io
make deploy-hetzner       # Deploy to Hetzner Cloud

# Container deployments
make deploy-docker        # Deploy with Docker Compose

# Tear down any deployment
make destroy-<platform>   # Replace <platform> with aws, gcp, azure, etc.
```

## Architecture Overview

This template follows a **hybrid deployment strategy**:

- **Backend (FastAPI)**: Deployed to Kubernetes clusters for auto-scaling, health checks, and orchestration
- **Frontend (Next.js)**: Deployed to CDN/edge networks for optimal performance and global distribution
- **Database**: Managed database services (RDS, Cloud SQL, Azure Database)

## Deployment Methods

### 🏗️ Infrastructure as Code (Terraform)

**Supported Providers**: AWS, GCP, Azure, DigitalOcean

#### Prerequisites
1. **Install Terraform**: [Terraform](https://terraform.io) >= 1.0
2. **Configure Provider CLI Tools** (see [Provider CLI Configuration](#provider-cli-configuration)):
   - AWS: `aws configure`
   - GCP: `gcloud auth login`
   - Azure: `az login`
   - DigitalOcean: `doctl auth init`
3. **Set up Remote State Storage**: See [tf-backend explanation](#terraform-remote-state-tf-backend)

#### What is `terraform init`?
`terraform init` initializes a Terraform working directory by:
- Downloading required provider plugins (AWS, GCP, Azure, etc.)
- Setting up backend configuration for remote state storage
- Installing any required modules
- Creating necessary local files and directories

Run this command once when setting up a new Terraform project or when changing providers/backends.

#### Terraform Example Workflow (AWS as example - same pattern for GCP/Azure/DigitalOcean)
```bash
# 1. Set up remote state storage
cd terraform/tf-backend/aws
terraform init    # Initialize and download AWS provider
terraform apply   # Create S3 bucket + DynamoDB for state

# 2. Deploy infrastructure
cd ../../aws
terraform init    # Initialize with remote backend
terraform apply   # Create EKS cluster, RDS, networking

# 3. Deploy application to Kubernetes
# Why is this separate? Terraform creates infrastructure,
# but application deployment uses Kubernetes manifests
make deploy-k8s-aws
```

#### Why `make deploy-k8s-aws` After `terraform apply`?
- **Terraform**: Creates infrastructure (EKS cluster, networking, databases)
- **Kubernetes Deployment**: Deploys your application containers to the cluster
- **Separation of Concerns**: Infrastructure vs Application deployment
- **Different Tools**: Terraform for infrastructure, kubectl for application manifests

#### Terraform Remote State (tf-backend)

**Purpose**: Terraform stores infrastructure state in files. For production deployments, this state must be shared between team members and stored safely.

**What tf-backend creates**:
- **AWS**: S3 bucket + DynamoDB table for state locking
- **GCP**: Google Cloud Storage bucket
- **Azure**: Azure Storage Account + Container
- **DigitalOcean**: Spaces bucket for state storage

**Why it's needed**:
- **Team Collaboration**: Multiple developers can work on same infrastructure
- **State Locking**: Prevents concurrent modifications that could corrupt state
- **Backup & Recovery**: State is safely stored in cloud, not local machine
- **Audit Trail**: Cloud storage provides versioning and access logs

#### Folder Structure
- `terraform/tf-backend/`: Creates remote state storage (S3, GCS, Azure Storage, Spaces)
- `terraform/{aws,gcp,azure,digitalocean}/`: Cloud-specific infrastructure definitions  
- `terraform/modules/k8s-cluster/`: Shared Kubernetes cluster logic
- `kubernetes/`: Application manifests and configurations (see [Kubernetes Folder Purpose](#kubernetes-folder-purpose))

### 🐳 Docker Compose Deployment

**Best for**: Local development, small deployments, staging environments, quick prototypes

#### How Docker Compose Deployment Works

1. **Container Orchestration**: Docker Compose manages multiple containers as a single application
2. **Service Definition**: All services (frontend, backend, database) defined in `docker-compose.yml`
3. **Network Isolation**: Containers communicate via internal Docker networks
4. **Volume Management**: Persistent data storage for database and files
5. **Environment Configuration**: Environment variables and secrets management

#### Deployment Process
```bash
# Navigate to production Docker Compose configuration
cd docker-compose/production

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your domain, database passwords, SMTP settings

# Start all services in background
docker-compose up -d

# View running services
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove all data (destructive)
docker-compose down -v
```

#### Included Services
- **Frontend Container**: Next.js application server
- **Backend Container**: FastAPI application server
- **PostgreSQL Database**: Persistent data storage
- **Redis Cache**: Session storage and caching
- **Traefik Reverse Proxy**: Load balancing and SSL termination
- **Automatic SSL**: Let's Encrypt certificate provisioning
- **Monitoring Stack**: Prometheus, Grafana (optional)

#### Why Traefik Over Nginx?
We use **Traefik** as the reverse proxy because:
- **Automatic Service Discovery**: Detects new containers automatically
- **Built-in Let's Encrypt**: SSL certificates without manual configuration
- **Docker Integration**: Native Docker label-based configuration
- **Modern Architecture**: Cloud-native design with better observability
- **Simpler Configuration**: Less manual setup compared to Nginx
- **Dynamic Updates**: No restart required when adding/removing services

### ☁️ Platform as a Service

All PaaS deployments now use consistent Makefile commands and include both deployment and teardown scripts.

#### Heroku
```bash
make deploy-heroku   # Deploy to Heroku
make destroy-heroku  # Remove Heroku deployment
```
**Features**:
- Automatic buildpack detection
- Managed PostgreSQL addon
- Free tier available
- Git-based deployment

#### Railway
```bash
make deploy-railway   # Deploy to Railway
make destroy-railway  # Remove Railway deployment
```
**Features**:
- Modern PaaS with GitHub integration
- Automatic environment provisioning
- Built-in databases and Redis
- Usage-based pricing

#### Fly.io
```bash
make deploy-flyio   # Deploy to Fly.io
make destroy-flyio  # Remove Fly.io deployment
```
**Features**:
- Global edge deployment
- Container-based platform
- Built-in load balancing
- Pay-per-use pricing

#### Hetzner Cloud
```bash
make deploy-hetzner   # Deploy to Hetzner Cloud
make destroy-hetzner  # Remove Hetzner deployment
```
**Features**:
- European cloud provider
- Cost-effective pricing
- GDPR compliant
- Managed Kubernetes option

#### Kubernetes Folder Purpose

The `kubernetes/` directory contains application deployment manifests separate from infrastructure:

**Why Separate from Terraform?**
- **Infrastructure vs Application**: Terraform manages cloud resources, Kubernetes manages application containers
- **Different Lifecycles**: Infrastructure changes rarely, applications deploy frequently
- **Tool Specialization**: Terraform for cloud APIs, Kubernetes for container orchestration
- **Team Separation**: Platform team manages infrastructure, development team manages applications

**Contents**:
- `base/`: Core application manifests (deployments, services, ingress)
- `overlays/`: Environment-specific configurations (staging, production)
- `secrets/`: Encrypted secret configurations
- `monitoring/`: Observability stack manifests

#### Provider CLI Configuration

Terraform uses cloud provider CLI tools for authentication and resource management:

**AWS CLI**:
```bash
# Install: https://aws.amazon.com/cli/
aws configure
# Terraform uses ~/.aws/credentials and AWS environment variables
```

**Google Cloud CLI**:
```bash
# Install: https://cloud.google.com/sdk/docs/install
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
# Terraform uses Application Default Credentials
```

**Azure CLI**:
```bash
# Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
az login
# Terraform uses Azure CLI authentication
```

**DigitalOcean CLI**:
```bash
# Install: https://docs.digitalocean.com/reference/doctl/
doctl auth init
# Terraform uses DIGITALOCEAN_TOKEN environment variable
```

## Detailed Setup Guides

### AWS Deployment

#### Infrastructure Components
- **EKS Cluster**: Managed Kubernetes service
- **CloudFront**: CDN for frontend assets
- **RDS PostgreSQL**: Managed database
- **Application Load Balancer**: Traffic distribution
- **Route53**: DNS management
- **ACM**: SSL certificates

#### Step-by-step Setup

1. **Configure AWS CLI**
   ```bash
   aws configure
   ```

2. **Set up Remote State**
   ```bash
   cd terraform/tf-backend/aws
   terraform init
   terraform apply
   ```

3. **Deploy Infrastructure**
   ```bash
   cd ../../aws
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   terraform apply
   ```

4. **Deploy Application**
   ```bash
   # Connect to EKS cluster
   aws eks update-kubeconfig --name your-cluster-name
   
   # Deploy application
   kubectl apply -f kubernetes/base/
   ```

5. **Deploy Frontend to CloudFront**
   ```bash
   # Build and deploy frontend
   cd ../../nextjs-frontend
   npm run build
   aws s3 sync out/ s3://your-frontend-bucket/
   aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
   ```

### GCP Deployment

#### Infrastructure Components
- **GKE Cluster**: Google Kubernetes Engine
- **Cloud CDN**: Global content delivery
- **Cloud SQL**: Managed PostgreSQL
- **Load Balancer**: Global load balancing
- **Cloud DNS**: DNS management
- **Certificate Manager**: SSL certificates

#### Step-by-step Setup

1. **Configure GCP CLI**
   ```bash
   # Install Google Cloud CLI
   # https://cloud.google.com/sdk/docs/install
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   
   # Enable required APIs
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   gcloud services enable sqladmin.googleapis.com
   ```

2. **Set up Remote State**
   ```bash
   cd terraform/tf-backend/gcp
   terraform init
   terraform apply
   ```

3. **Deploy Infrastructure**
   ```bash
   cd ../../gcp
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   terraform apply
   ```

4. **Deploy Application**
   ```bash
   # Connect to GKE cluster
   gcloud container clusters get-credentials your-cluster-name --region=us-central1
   
   # Deploy application
   kubectl apply -f kubernetes/base/
   ```

5. **Deploy Frontend to Cloud CDN**
   ```bash
   # Build and deploy frontend
   cd ../../nextjs-frontend
   npm run build
   gsutil -m cp -r out/* gs://your-frontend-bucket/
   gcloud compute url-maps invalidate-cdn-cache your-load-balancer --path="/*"
   ```

### Azure Deployment

#### Infrastructure Components
- **AKS Cluster**: Azure Kubernetes Service
- **Azure CDN**: Content delivery network
- **Azure Database**: Managed PostgreSQL
- **Application Gateway**: Load balancing
- **Azure DNS**: DNS management
- **Key Vault**: SSL certificate management

#### Step-by-step Setup

1. **Configure Azure CLI**
   ```bash
   # Install Azure CLI
   # https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
   az login
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   
   # Register required providers
   az provider register --namespace Microsoft.ContainerService
   az provider register --namespace Microsoft.Compute
   az provider register --namespace Microsoft.DBforPostgreSQL
   ```

2. **Set up Remote State**
   ```bash
   cd terraform/tf-backend/azure
   terraform init
   terraform apply
   ```

3. **Deploy Infrastructure**
   ```bash
   cd ../../azure
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   terraform apply
   ```

4. **Deploy Application**
   ```bash
   # Connect to AKS cluster
   az aks get-credentials --resource-group your-resource-group --name your-cluster-name
   
   # Deploy application
   kubectl apply -f kubernetes/base/
   ```

5. **Deploy Frontend to Azure CDN**
   ```bash
   # Build and deploy frontend
   cd ../../nextjs-frontend
   npm run build
   az storage blob upload-batch --destination '$web' --source out/ --account-name your-storage-account
   az cdn endpoint purge --content-paths "/*" --profile-name your-cdn-profile --name your-endpoint --resource-group your-resource-group
   ```

### DigitalOcean Deployment

#### Infrastructure Components
- **DOKS Cluster**: DigitalOcean Kubernetes Service
- **Spaces CDN**: Content delivery network
- **Managed Database**: PostgreSQL cluster
- **Load Balancer**: Regional load balancing
- **DNS**: Domain management
- **Certificate Manager**: SSL certificates

#### Step-by-step Setup

1. **Configure DigitalOcean CLI**
   ```bash
   # Install doctl CLI
   # https://docs.digitalocean.com/reference/doctl/
   doctl auth init
   
   # Verify authentication
   doctl account get
   ```

2. **Set up Remote State**
   ```bash
   cd terraform/tf-backend/digitalocean
   terraform init
   terraform apply
   ```

3. **Deploy Infrastructure**
   ```bash
   cd ../../digitalocean
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   terraform apply
   ```

4. **Deploy Application**
   ```bash
   # Connect to DOKS cluster
   doctl kubernetes cluster kubeconfig save your-cluster-name
   
   # Deploy application
   kubectl apply -f kubernetes/base/
   ```

5. **Deploy Frontend to Spaces CDN**
   ```bash
   # Build and deploy frontend
   cd ../../nextjs-frontend
   npm run build
   doctl compute cdn flush your-cdn-id --files "*"
   ```

## Deployment Scripts Implementation

All deployment commands are implemented as bash scripts in the `deploy/scripts/` directory and called through the Makefile:

**Structure**:
```
deploy/scripts/
├── aws/
│   ├── deploy.sh      # AWS deployment logic
│   └── destroy.sh     # AWS teardown logic
├── gcp/
│   ├── deploy.sh      # GCP deployment logic
│   └── destroy.sh     # GCP teardown logic
├── azure/
│   ├── deploy.sh      # Azure deployment logic
│   └── destroy.sh     # Azure teardown logic
└── ...
```

**Makefile Integration**:
```makefile
deploy-aws:
	@bash deploy/scripts/aws/deploy.sh

destroy-aws:
	@bash deploy/scripts/aws/destroy.sh
```

**Benefits**:
- **Consistency**: Same deployment logic across environments
- **Maintainability**: Script logic separate from Makefile
- **Error Handling**: Robust error checking and rollback
- **Logging**: Detailed deployment logs
- **Modularity**: Reusable functions across scripts

## Teardown Commands

Every deployment method includes corresponding teardown commands:

```bash
# Infrastructure teardowns
make destroy-aws           # Remove AWS infrastructure
make destroy-gcp           # Remove GCP infrastructure
make destroy-azure         # Remove Azure infrastructure
make destroy-digitalocean  # Remove DigitalOcean infrastructure

# Platform teardowns
make destroy-heroku        # Remove Heroku deployment
make destroy-railway       # Remove Railway deployment
make destroy-flyio         # Remove Fly.io deployment
make destroy-hetzner       # Remove Hetzner deployment

# Container teardowns
make destroy-docker        # Stop and remove Docker Compose stack
make destroy-k8s-manual    # Remove manual Kubernetes deployment
```

**Important**: Teardown commands will:
- Remove all infrastructure resources
- Delete databases and data (irreversible)
- Remove DNS records and SSL certificates
- Stop all running services

## Environment Configuration

### Required Environment Variables

#### Backend (.env)
```bash
DATABASE_URL=postgresql://user:pass@host:port/db
REDIS_URL=redis://localhost:6379
SECRET_KEY=your-secret-key
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

#### Frontend (.env.local)
```bash
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
NEXT_PUBLIC_ENVIRONMENT=production
```

## Monitoring and Observability

### Included Components
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **Jaeger**: Distributed tracing
- **ELK Stack**: Centralized logging

### Health Checks
- Backend: `/health` endpoint
- Frontend: Built-in Next.js health checks
- Database: Connection pooling with health monitoring

## Security Best Practices

### Network Security
- Private subnets for databases
- Security groups/firewall rules
- VPC/VNet isolation
- WAF protection for public endpoints

### Secrets Management
- Cloud-native secret stores (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault)
- Kubernetes secrets for sensitive data
- Automated secret rotation

### SSL/TLS
- Automatic certificate provisioning
- HTTPS enforcement
- HTTP/2 support

## Cost Optimization

### Infrastructure Costs
- **AWS**: ~$150-300/month for small production workload
- **GCP**: ~$120-250/month for similar workload  
- **Azure**: ~$140-280/month for comparable setup
- **DigitalOcean**: ~$50-120/month for managed Kubernetes

### Cost-Saving Tips
- Use spot/preemptible instances for non-critical workloads
- Implement auto-scaling policies
- Set up budget alerts
- Use reserved instances for predictable workloads

## Troubleshooting

### Common Issues

#### Terraform
```bash
# State lock issues
terraform force-unlock LOCK_ID

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0
```

#### Kubernetes
```bash
# Check pod status
kubectl get pods -n your-namespace

# View logs
kubectl logs -f deployment/backend -n your-namespace

# Debug networking
kubectl exec -it pod-name -- curl http://service-name:port/health
```

#### DNS/SSL Issues
- Verify domain ownership
- Check certificate status
- Validate DNS propagation

### Support Resources
- [Terraform Documentation](https://terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Cloud Provider Documentation](#cloud-providers)

## Migration Guide

### From Vercel to Self-Hosted
1. Export environment variables
2. Set up CDN for frontend deployment
3. Configure custom domains
4. Update DNS records
5. Test deployment thoroughly

### Between Cloud Providers
1. Export data from current provider
2. Set up new infrastructure
3. Migrate application configurations  
4. Update DNS records
5. Verify functionality

## Contributing

When adding new deployment options:
1. Create provider-specific folder
2. Add configuration files
3. Update this README
4. Add Makefile targets
5. Test deployment process

## Next Steps

After successful deployment:
1. Set up monitoring dashboards
2. Configure backup strategies
3. Implement CI/CD pipelines
4. Set up alerting rules
5. Plan disaster recovery procedures