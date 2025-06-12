# ToDo

## Deployment Infrastructure Setup

### Phase 1: Project Structure & Documentation
- [x] Create deploy/ folder structure
- [x] Create comprehensive deploy/README.md explaining all deployment options
- [x] Add deploy/Makefile for streamlined deployment commands

### Phase 2: Terraform Backend Setup
- [ ] Create tf-backend scripts for AWS (S3 + DynamoDB)
- [ ] Create tf-backend scripts for GCP (GCS bucket)
- [ ] Create tf-backend scripts for Azure (Storage Account + Container)

### Phase 3: Kubernetes Infrastructure (Terraform)
- [ ] Create shared k8s-cluster module with cloud-agnostic logic
- [ ] Implement AWS EKS deployment with terraform
- [ ] Implement GCP GKE deployment with terraform  
- [ ] Implement Azure AKS deployment with terraform
- [ ] Add DigitalOcean Kubernetes support

### Phase 4: Application Deployment
- [ ] Create Kubernetes manifests for FastAPI backend
- [ ] Set up ingress controller, SSL certificates, load balancing
- [ ] Configure CDN deployment for Next.js frontend (CloudFront/Cloud CDN/Azure CDN)
- [ ] Create docker-compose setup for simple deployments

### Phase 5: Alternative Platform Support
- [ ] Add Heroku deployment configs (Procfile, app.json)
- [ ] Add Hetzner deployment scripts
- [ ] Add Railway deployment config
- [ ] Add Fly.io deployment config

```
deploy/
├── README.md              # Comprehensive deployment guide
├── Makefile               # Simplified deployment commands
├── terraform/             # IaC for major cloud providers
│   ├── tf-backend/        # Creates backend storage
│   │   ├── aws/
│   │   ├── gcp/
│   │   └── azure/
│   ├── aws/
│   ├── gcp/
│   ├── azure/
│   ├── digitalocean/
│   └── modules/
│       └── k8s-cluster/
├── docker-compose/        # Simple container deployments
├── kubernetes/            # Raw K8s manifests
├── platform-configs/      # Platform-specific configs
└── scripts/               # Deployment automation
```

## Other Tasks
- [ ] Make a Stripe account