# GCP Deployment for Next.js + FastAPI Template

This directory contains Terraform configurations for deploying the Next.js + FastAPI template to Google Cloud Platform using GKE (Google Kubernetes Engine).

## Architecture

- **GKE Cluster**: Managed Kubernetes service with Workload Identity and auto-scaling
- **Cloud SQL**: Managed PostgreSQL database with private IP and encryption
- **Cloud CDN**: Global content delivery network for frontend assets
- **Cloud Load Balancer**: Global HTTP(S) load balancer with SSL termination
- **VPC**: Custom network with private subnets and Cloud NAT
- **Cloud Storage**: Bucket for frontend assets with CDN integration
- **Cloud KMS**: Encryption keys for cluster and storage security

## Prerequisites

1. **Google Cloud CLI**: [Install gcloud](https://cloud.google.com/sdk/docs/install)
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Terraform**: [Install Terraform](https://terraform.io/downloads) >= 1.0

3. **kubectl**: [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

4. **Docker**: For building and pushing container images

5. **Enable Required APIs**:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   gcloud services enable sqladmin.googleapis.com
   gcloud services enable cloudresourcemanager.googleapis.com
   gcloud services enable servicenetworking.googleapis.com
   gcloud services enable dns.googleapis.com
   gcloud services enable certificatemanager.googleapis.com
   gcloud services enable storage.googleapis.com
   gcloud services enable cloudkms.googleapis.com
   ```

## Setup Instructions

### 1. Set up Terraform Backend

First, create the GCS bucket for remote state storage:

```bash
cd ../tf-backend/gcp
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID and preferences
terraform init
terraform apply
```

### 2. Configure Main Infrastructure

```bash
cd ../../gcp
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

**Important**: Update the following values in `terraform.tfvars`:
- `project_id`: Your GCP project ID
- `database_password`: Use a strong, secure password
- `domain_name`: Your domain (optional, for SSL certificate)
- `environment`: Set to "prod" for production deployment

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
- GKE cluster with node auto-scaling and Workload Identity
- Cloud SQL PostgreSQL instance with private IP
- VPC with private subnets and Cloud NAT
- Cloud Storage bucket for frontend assets
- Global load balancer with Cloud CDN
- KMS keys for encryption
- IAM service accounts and bindings

### 4. Configure kubectl

After the infrastructure is deployed, configure kubectl to access your GKE cluster:

```bash
gcloud container clusters get-credentials $(terraform output -raw cluster_name) --region $(terraform output -raw gcp_region) --project $(terraform output -raw project_id)
```

Verify connectivity:
```bash
kubectl get nodes
```

### 5. Set up Workload Identity (Recommended)

Create GCP service accounts for secure pod-to-GCP communication:

```bash
# Create service account for backend pods
gcloud iam service-accounts create backend-service \
    --display-name="Backend Service Account"

# Bind Kubernetes service account to GCP service account
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$(terraform output -raw project_id).svc.id.goog[production/backend-workload-identity]" \
    backend-service@$(terraform output -raw project_id).iam.gserviceaccount.com

# Grant necessary permissions
gcloud projects add-iam-policy-binding $(terraform output -raw project_id) \
    --member="serviceAccount:backend-service@$(terraform output -raw project_id).iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"
```

### 6. Deploy Application to Kubernetes

Deploy the application using the Kubernetes manifests:

```bash
# Apply base manifests
kubectl apply -f ../../kubernetes/base/

# Apply GCP-specific configurations
kubectl apply -f ../../kubernetes/overlays/gcp/
```

### 7. Build and Push Container Images

You'll need to build and push your application images to Google Container Registry or Artifact Registry:

```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Build and push backend image
cd ../../../fastapi_backend
docker build -t gcr.io/$(terraform output -raw project_id)/nextjs-fastapi-backend:latest .
docker push gcr.io/$(terraform output -raw project_id)/nextjs-fastapi-backend:latest

# Update deployment with correct image
kubectl patch deployment backend -n production -p='{"spec":{"template":{"spec":{"containers":[{"name":"backend","image":"gcr.io/'$(terraform output -raw project_id)'/nextjs-fastapi-backend:latest"}]}}}}'
```

### 8. Deploy Frontend to Cloud CDN

Build and deploy the frontend to the Cloud Storage bucket:

```bash
cd ../nextjs-frontend
npm run build
gsutil -m rsync -r -d out/ gs://$(cd ../deploy/terraform/gcp && terraform output -raw frontend_bucket)/
```

## Configuration

### Environment Variables

Update the Kubernetes secrets in `../../kubernetes/base/secrets.yaml` with your actual values:

- Database connection details (use private IP from Terraform outputs)
- Application secret key
- Email configuration (if using)
- Any other environment-specific configurations

### Custom Domain Setup

If you have a custom domain:

1. **Update DNS**: Point your domain to the load balancer IP:
   ```bash
   terraform output load_balancer_ip
   ```

2. **Update SSL Certificate**: Edit the ManagedCertificate in `../../kubernetes/overlays/gcp/gcp-load-balancer-controller.yaml`

3. **Cloud DNS (Optional)**: Create a Cloud DNS zone:
   ```bash
   gcloud dns managed-zones create your-domain-zone \
       --dns-name=your-domain.com. \
       --description="Your domain zone"
   ```

### Scaling

The GKE cluster is configured with multiple scaling mechanisms:
- **Node Auto-scaling**: Automatically adds/removes nodes based on demand
- **Cluster Autoscaling**: Resource-based scaling with CPU/memory limits
- **Horizontal Pod Autoscaler**: Scales pods based on CPU/memory usage
- **Vertical Pod Autoscaler**: Automatically adjusts resource requests/limits

### Monitoring and Logging

GCP provides built-in monitoring:
- **Cloud Monitoring**: Metrics and alerting
- **Cloud Logging**: Centralized log management
- **Cloud Trace**: Distributed tracing
- **Cloud Profiler**: Application performance profiling

Access through the GCP Console or set up custom dashboards.

## Outputs

After successful deployment, Terraform provides these outputs:

- `cluster_name`: GKE cluster name
- `cluster_endpoint`: Kubernetes API endpoint
- `database_connection_name`: Cloud SQL connection name
- `load_balancer_ip`: Global load balancer IP address
- `frontend_bucket`: Cloud Storage bucket for frontend assets

## Costs

Estimated monthly costs for this setup:
- GKE Cluster: ~$72 (cluster management fee)
- Compute Engine: ~$30-150 (depending on node types and count)
- Cloud SQL: ~$20-60 (depending on instance size)
- Cloud Storage: ~$1-5 (depending on usage)
- Load Balancer: ~$18 (global load balancer)
- Other services: ~$5-15

**Total**: ~$120-250/month for a small production workload

### Cost Optimization Tips

- Use **preemptible nodes** for non-critical workloads (set `use_preemptible_nodes = true`)
- Enable **auto-scaling** to scale down during low usage
- Use **regional persistent disks** only when high availability is required
- Set up **budget alerts** to monitor spending
- Use **committed use discounts** for predictable workloads

## Security Best Practices

### What's Already Configured
- **Private GKE cluster** with private nodes
- **Workload Identity** for secure GCP API access
- **Network isolation** with custom VPC and private subnets
- **Encryption at rest** with Cloud KMS
- **Managed SSL certificates** for HTTPS
- **Cloud SQL with private IP** and SSL enforcement
- **Shielded GKE nodes** with secure boot and integrity monitoring

### Additional Security Measures
- **Binary Authorization**: Control which container images can be deployed
- **Pod Security Standards**: Enforce security policies
- **VPC Security Groups**: Network-level access control
- **Cloud Armor**: Web application firewall and DDoS protection
- **Identity-Aware Proxy**: Add authentication layer

## Troubleshooting

### Common Issues

1. **API not enabled**: Ensure all required APIs are enabled
   ```bash
   gcloud services list --enabled
   ```

2. **Insufficient quotas**: Check and request quota increases
   ```bash
   gcloud compute regions describe us-central1
   ```

3. **Workload Identity issues**: Verify service account bindings
   ```bash
   gcloud iam service-accounts get-iam-policy backend-service@PROJECT_ID.iam.gserviceaccount.com
   ```

4. **Cloud SQL connectivity**: Check private service connection
   ```bash
   gcloud services vpc-peerings list --network=NETWORK_NAME
   ```

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -n production

# View logs
kubectl logs -f deployment/backend -n production

# Describe problematic resources
kubectl describe pod <pod-name> -n production

# Connect to Cloud SQL from a pod (for debugging)
kubectl run psql --image=postgres:15 --rm -it --restart=Never -n production -- psql -h <cloud-sql-private-ip> -U postgres -d nextjs_fastapi

# Check Cloud SQL status
gcloud sql instances describe <instance-name>

# View load balancer status
gcloud compute backend-services list
gcloud compute forwarding-rules list
```

### Performance Optimization

1. **Enable Cloud CDN** for API responses (if appropriate)
2. **Use regional persistent disks** for better I/O performance
3. **Configure resource requests and limits** appropriately
4. **Use node pools with different machine types** for different workloads
5. **Enable cluster autoscaling** with appropriate resource limits

## Backup and Disaster Recovery

### Automated Backups
- **Cloud SQL**: Automatic daily backups with point-in-time recovery
- **Persistent Disks**: Volume snapshots for application data
- **Cluster Configuration**: Store manifests in version control

### Manual Backup Commands
```bash
# Create volume snapshot
kubectl apply -f ../../kubernetes/overlays/gcp/gcp-persistent-disk.yaml

# Export cluster configuration
kubectl get all -n production -o yaml > backup-$(date +%Y%m%d).yaml

# Backup Cloud SQL
gcloud sql backups create --instance=<instance-name>
```

## Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources first
kubectl delete -f ../../kubernetes/overlays/gcp/
kubectl delete -f ../../kubernetes/base/

# Destroy Terraform infrastructure
terraform destroy

# Optionally destroy the backend (this will delete the state file!)
cd ../tf-backend/gcp
terraform destroy
```

**Warning**: This will permanently delete all data including the database!

## Advanced Configuration

### Multi-Region Deployment
For high availability across regions, consider:
- Regional GKE clusters
- Multi-region Cloud SQL replicas
- Global load balancer with multiple backends

### CI/CD Integration
Integrate with Cloud Build for automated deployments:
```yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/$PROJECT_ID/app:$COMMIT_SHA', '.']
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', 'gcr.io/$PROJECT_ID/app:$COMMIT_SHA']
- name: 'gcr.io/cloud-builders/kubectl'
  args: ['set', 'image', 'deployment/backend', 'backend=gcr.io/$PROJECT_ID/app:$COMMIT_SHA']
```

### Monitoring Alerts
Set up alerting policies:
```bash
gcloud alpha monitoring policies create --policy-from-file=alerting-policy.yaml
```

This GCP deployment provides a robust, scalable, and secure foundation for running your Next.js + FastAPI application in production.