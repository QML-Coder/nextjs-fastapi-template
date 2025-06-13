# Deployment Makefile for Next.js + FastAPI Template
# Usage: make <target>

.PHONY: help

# Default target
help:
	@echo "Available deployment targets:"
	@echo ""
	@echo "🏗️  Infrastructure Setup:"
	@echo "  init-aws          Initialize AWS remote state and infrastructure"
	@echo "  init-gcp          Initialize GCP remote state and infrastructure"  
	@echo "  init-azure        Initialize Azure remote state and infrastructure"
	@echo ""
	@echo "☁️  Cloud Deployments:"
	@echo "  deploy-aws        Deploy to AWS EKS + CloudFront"
	@echo "  deploy-gcp        Deploy to GCP GKE + Cloud CDN"
	@echo "  deploy-azure      Deploy to Azure AKS + Azure CDN"
	@echo "  deploy-oci        Deploy to Oracle Cloud OKE + CDN"
	@echo "  deploy-do         Deploy to DigitalOcean Kubernetes"
	@echo ""
	@echo "🐳  Container Deployments:"
	@echo "  deploy-docker     Deploy with Docker Compose"
	@echo "  deploy-k8s        Deploy to existing Kubernetes cluster"
	@echo ""
	@echo "🚀  Platform Deployments:"
	@echo "  deploy-heroku     Deploy to Heroku"
	@echo "  deploy-railway    Deploy to Railway"
	@echo "  deploy-fly        Deploy to Fly.io"
	@echo "  deploy-hetzner    Deploy to Hetzner Cloud"
	@echo ""
	@echo "🔧  Utilities:"
	@echo "  validate          Validate all configurations"
	@echo "  test              Test deployment configurations"
	@echo "  clean             Clean up temporary files"
	@echo "  destroy-aws       Destroy AWS infrastructure"
	@echo "  destroy-gcp       Destroy GCP infrastructure"
	@echo "  destroy-azure     Destroy Azure infrastructure"
	@echo "  destroy-oci       Destroy Oracle Cloud infrastructure"

# ============================================================================
# Infrastructure Initialization
# ============================================================================

.PHONY: init-aws init-gcp init-azure init-oci

init-aws:
	@echo "🏗️  Initializing AWS infrastructure..."
	cd terraform/tf-backend/aws && terraform init && terraform apply -auto-approve
	cd terraform/aws && terraform init && terraform plan

init-gcp:
	@echo "🏗️  Initializing GCP infrastructure..."
	cd terraform/tf-backend/gcp && terraform init && terraform apply -auto-approve
	cd terraform/gcp && terraform init && terraform plan

init-azure:
	@echo "🏗️  Initializing Azure infrastructure..."
	cd terraform/tf-backend/azure && terraform init && terraform apply -auto-approve
	cd terraform/azure && terraform init && terraform plan

init-oci:
	@echo "🏗️  Initializing Oracle Cloud infrastructure..."
	cd terraform/tf-backend/oci && terraform init && terraform apply -auto-approve
	cd terraform/oci && terraform init && terraform plan

# ============================================================================
# Cloud Deployments
# ============================================================================

.PHONY: deploy-aws deploy-gcp deploy-azure deploy-oci deploy-do

deploy-aws: validate-aws
	@echo "🚀 Deploying to AWS EKS + CloudFront..."
	cd terraform/aws && terraform apply -auto-approve
	$(MAKE) update-kubeconfig-aws
	$(MAKE) deploy-k8s-aws
	$(MAKE) deploy-frontend-aws
	@echo "✅ AWS deployment completed!"
	@echo "🌐 Frontend: https://$(shell cd terraform/aws && terraform output -raw cloudfront_domain)"
	@echo "🔗 Backend: https://$(shell cd terraform/aws && terraform output -raw api_domain)"

deploy-gcp: validate-gcp
	@echo "🚀 Deploying to GCP GKE + Cloud CDN..."
	cd terraform/gcp && terraform apply -auto-approve
	$(MAKE) update-kubeconfig-gcp
	$(MAKE) deploy-k8s-gcp
	$(MAKE) deploy-frontend-gcp
	@echo "✅ GCP deployment completed!"

deploy-azure: validate-azure
	@echo "🚀 Deploying to Azure AKS + Azure CDN..."
	cd terraform/azure && terraform apply -auto-approve
	$(MAKE) update-kubeconfig-azure
	$(MAKE) deploy-k8s-azure
	$(MAKE) deploy-frontend-azure
	@echo "✅ Azure deployment completed!"

deploy-oci: validate-oci
	@echo "🚀 Deploying to Oracle Cloud OKE + CDN..."
	cd terraform/oci && terraform apply -auto-approve
	$(MAKE) update-kubeconfig-oci
	$(MAKE) deploy-k8s-oci
	$(MAKE) deploy-frontend-oci
	@echo "✅ Oracle Cloud deployment completed!"

deploy-do:
	@echo "🚀 Deploying to DigitalOcean Kubernetes..."
	cd terraform/digitalocean && terraform apply -auto-approve
	$(MAKE) update-kubeconfig-do
	$(MAKE) deploy-k8s

# ============================================================================
# Kubernetes Deployments
# ============================================================================

.PHONY: deploy-k8s deploy-k8s-aws deploy-k8s-gcp deploy-k8s-azure deploy-k8s-oci

deploy-k8s:
	@echo "📦 Deploying application to Kubernetes..."
	kubectl apply -f kubernetes/base/namespace.yaml
	kubectl apply -f kubernetes/base/secrets.yaml
	kubectl apply -f kubernetes/base/configmap.yaml
	kubectl apply -f kubernetes/base/backend-deployment.yaml
	kubectl apply -f kubernetes/base/backend-service.yaml
	kubectl apply -f kubernetes/base/ingress.yaml
	kubectl rollout status deployment/backend -n production
	@echo "✅ Kubernetes deployment completed!"

deploy-k8s-aws: deploy-k8s
	@echo "🔧 Configuring AWS-specific resources..."
	kubectl apply -f kubernetes/overlays/aws/

deploy-k8s-gcp: deploy-k8s
	@echo "🔧 Configuring GCP-specific resources..."
	kubectl apply -f kubernetes/overlays/gcp/

deploy-k8s-azure: deploy-k8s
	@echo "🔧 Configuring Azure-specific resources..."
	kubectl apply -f kubernetes/overlays/azure/

deploy-k8s-oci: deploy-k8s
	@echo "🔧 Configuring Oracle Cloud-specific resources..."
	kubectl apply -f kubernetes/overlays/oci/

# ============================================================================
# Frontend Deployments
# ============================================================================

.PHONY: deploy-frontend-aws deploy-frontend-gcp deploy-frontend-azure deploy-frontend-oci

deploy-frontend-aws:
	@echo "🌐 Deploying frontend to AWS CloudFront..."
	cd ../nextjs-frontend && npm run build
	aws s3 sync ../nextjs-frontend/out/ s3://$$(cd terraform/aws && terraform output -raw frontend_bucket)/
	aws cloudfront create-invalidation --distribution-id $$(cd terraform/aws && terraform output -raw cloudfront_distribution_id) --paths "/*"

deploy-frontend-gcp:
	@echo "🌐 Deploying frontend to GCP Cloud CDN..."
	cd ../nextjs-frontend && npm run build
	gsutil -m rsync -r -d ../nextjs-frontend/out/ gs://$$(cd terraform/gcp && terraform output -raw frontend_bucket)/

deploy-frontend-azure:
	@echo "🌐 Deploying frontend to Azure CDN..."
	cd ../nextjs-frontend && npm run build
	az storage blob upload-batch --destination '$web' --source ../nextjs-frontend/out/ --account-name $$(cd terraform/azure && terraform output -raw storage_account_name)

deploy-frontend-oci:
	@echo "🌐 Deploying frontend to Oracle Cloud CDN..."
	cd ../nextjs-frontend && npm run build
	oci os object bulk-upload --bucket-name $$(cd terraform/oci && terraform output -raw frontend_bucket) --src-dir ../nextjs-frontend/out/
	oci edge purge create --distribution-id $$(cd terraform/oci && terraform output -raw cdn_distribution_id) --items '*'

# ============================================================================
# Platform Deployments
# ============================================================================

.PHONY: deploy-docker deploy-heroku deploy-railway deploy-fly deploy-hetzner

deploy-docker:
	@echo "🐳 Deploying with Docker Compose..."
	cd docker-compose/production && docker compose down
	cd docker-compose/production && docker compose pull
	cd docker-compose/production && docker compose up -d
	@echo "✅ Docker deployment completed!"
	@echo "🌐 Application: http://localhost"

deploy-heroku:
	@echo "🚀 Deploying to Heroku..."
	@if [ ! -f platform-configs/heroku/Procfile ]; then echo "❌ Heroku configuration not found!"; exit 1; fi
	heroku create $(APP_NAME) || true
	heroku addons:create heroku-postgresql:hobby-dev || true
	heroku config:set $(shell cat platform-configs/heroku/.env.example | grep -v '^#' | xargs)
	git subtree push --prefix=. heroku main || git push heroku main
	@echo "✅ Heroku deployment completed!"

deploy-railway:
	@echo "🚀 Deploying to Railway..."
	railway deploy
	@echo "✅ Railway deployment completed!"

deploy-fly:
	@echo "🚀 Deploying to Fly.io..."
	flyctl deploy
	@echo "✅ Fly.io deployment completed!"

deploy-hetzner:
	@echo "🚀 Deploying to Hetzner Cloud..."
	./scripts/deploy-hetzner.sh
	@echo "✅ Hetzner deployment completed!"

# ============================================================================
# Kubeconfig Updates
# ============================================================================

.PHONY: update-kubeconfig-aws update-kubeconfig-gcp update-kubeconfig-azure update-kubeconfig-oci update-kubeconfig-do

update-kubeconfig-aws:
	@echo "🔧 Updating kubeconfig for AWS EKS..."
	aws eks update-kubeconfig --name $$(cd terraform/aws && terraform output -raw cluster_name) --region $$(cd terraform/aws && terraform output -raw aws_region)

update-kubeconfig-gcp:
	@echo "🔧 Updating kubeconfig for GCP GKE..."
	gcloud container clusters get-credentials $$(cd terraform/gcp && terraform output -raw cluster_name) --region=$$(cd terraform/gcp && terraform output -raw gcp_region)

update-kubeconfig-azure:
	@echo "🔧 Updating kubeconfig for Azure AKS..."
	az aks get-credentials --resource-group $$(cd terraform/azure && terraform output -raw resource_group_name) --name $$(cd terraform/azure && terraform output -raw cluster_name)

update-kubeconfig-oci:
	@echo "🔧 Updating kubeconfig for Oracle Cloud OKE..."
	oci ce cluster create-kubeconfig --cluster-id $$(cd terraform/oci && terraform output -raw cluster_id) --file ~/.kube/config

update-kubeconfig-do:
	@echo "🔧 Updating kubeconfig for DigitalOcean..."
	doctl kubernetes cluster kubeconfig save $$(cd terraform/digitalocean && terraform output -raw cluster_name)

# ============================================================================
# Validation
# ============================================================================

.PHONY: validate validate-terraform validate-kubernetes validate-docker-compose validate-aws validate-gcp validate-azure validate-oci

validate: validate-terraform validate-kubernetes validate-docker-compose

validate-terraform:
	@echo "🔍 Validating Terraform configurations..."
	@for dir in terraform/*/; do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Validating $$dir..."; \
			cd "$$dir" && terraform validate || exit 1; \
			cd - > /dev/null; \
		fi \
	done
	@echo "✅ Terraform validation completed!"

validate-kubernetes:
	@echo "🔍 Validating Kubernetes manifests..."
	@for file in kubernetes/base/*.yaml kubernetes/overlays/*/*.yaml; do \
		if [ -f "$$file" ]; then \
			echo "Validating $$file..."; \
			kubectl --dry-run=client apply -f "$$file" > /dev/null || exit 1; \
		fi \
	done
	@echo "✅ Kubernetes validation completed!"

validate-docker-compose:
	@echo "🔍 Validating Docker Compose configurations..."
	cd docker-compose/production && docker compose config > /dev/null
	@echo "✅ Docker Compose validation completed!"

validate-aws:
	@echo "🔍 Validating AWS prerequisites..."
	@aws sts get-caller-identity > /dev/null || (echo "❌ AWS CLI not configured"; exit 1)
	@terraform --version > /dev/null || (echo "❌ Terraform not installed"; exit 1)
	@kubectl version --client > /dev/null || (echo "❌ kubectl not installed"; exit 1)

validate-gcp:
	@echo "🔍 Validating GCP prerequisites..."
	@gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 > /dev/null || (echo "❌ GCP CLI not configured"; exit 1)
	@terraform --version > /dev/null || (echo "❌ Terraform not installed"; exit 1)

validate-azure:
	@echo "🔍 Validating Azure prerequisites..."
	@az account show > /dev/null || (echo "❌ Azure CLI not configured"; exit 1)
	@terraform --version > /dev/null || (echo "❌ Terraform not installed"; exit 1)

validate-oci:
	@echo "🔍 Validating Oracle Cloud prerequisites..."
	@oci iam region list > /dev/null || (echo "❌ Oracle Cloud CLI not configured"; exit 1)
	@terraform --version > /dev/null || (echo "❌ Terraform not installed"; exit 1)

# ============================================================================
# Testing
# ============================================================================

.PHONY: test test-backend test-frontend test-infrastructure

test: test-backend test-frontend test-infrastructure

test-backend:
	@echo "🧪 Testing backend deployment..."
	cd ../fastapi_backend && uv run pytest

test-frontend:
	@echo "🧪 Testing frontend deployment..."
	cd ../nextjs-frontend && pnpm test

test-infrastructure:
	@echo "🧪 Testing infrastructure configurations..."
	$(MAKE) validate

# ============================================================================
# Cleanup
# ============================================================================

.PHONY: clean destroy-aws destroy-gcp destroy-azure destroy-oci destroy-do

clean:
	@echo "🧹 Cleaning up temporary files..."
	find . -name "*.tfplan" -delete
	find . -name "*.tfstate.backup" -delete
	find . -name ".terraform.lock.hcl" -delete
	docker system prune -f
	@echo "✅ Cleanup completed!"

destroy-aws:
	@echo "💥 Destroying AWS infrastructure..."
	@read -p "Are you sure you want to destroy AWS infrastructure? [y/N]: " confirm && [ "$$confirm" = "y" ]
	cd terraform/aws && terraform destroy -auto-approve
	cd terraform/tf-backend/aws && terraform destroy -auto-approve

destroy-gcp:
	@echo "💥 Destroying GCP infrastructure..."
	@read -p "Are you sure you want to destroy GCP infrastructure? [y/N]: " confirm && [ "$$confirm" = "y" ]
	cd terraform/gcp && terraform destroy -auto-approve
	cd terraform/tf-backend/gcp && terraform destroy -auto-approve

destroy-azure:
	@echo "💥 Destroying Azure infrastructure..."
	@read -p "Are you sure you want to destroy Azure infrastructure? [y/N]: " confirm && [ "$$confirm" = "y" ]
	cd terraform/azure && terraform destroy -auto-approve
	cd terraform/tf-backend/azure && terraform destroy -auto-approve

destroy-oci:
	@echo "💥 Destroying Oracle Cloud infrastructure..."
	@read -p "Are you sure you want to destroy Oracle Cloud infrastructure? [y/N]: " confirm && [ "$$confirm" = "y" ]
	cd terraform/oci && terraform destroy -auto-approve
	cd terraform/tf-backend/oci && terraform destroy -auto-approve

destroy-do:
	@echo "💥 Destroying DigitalOcean infrastructure..."
	@read -p "Are you sure you want to destroy DigitalOcean infrastructure? [y/N]: " confirm && [ "$$confirm" = "y" ]
	cd terraform/digitalocean && terraform destroy -auto-approve

# ============================================================================
# Status and Monitoring
# ============================================================================

.PHONY: status logs

status:
	@echo "📊 Deployment Status:"
	@echo ""
	@echo "🐳 Docker Compose:"
	@cd docker-compose/production && docker compose ps 2>/dev/null || echo "  Not running"
	@echo ""
	@echo "☸️  Kubernetes:"
	@kubectl get pods -n production 2>/dev/null || echo "  Not connected or deployed"
	@echo ""
	@echo "☁️  Infrastructure:"
	@echo "  AWS: $$(cd terraform/aws 2>/dev/null && terraform show -json | jq -r '.values.root_module.resources | length' 2>/dev/null || echo 'Not deployed') resources"
	@echo "  GCP: $$(cd terraform/gcp 2>/dev/null && terraform show -json | jq -r '.values.root_module.resources | length' 2>/dev/null || echo 'Not deployed') resources"
	@echo "  Azure: $$(cd terraform/azure 2>/dev/null && terraform show -json | jq -r '.values.root_module.resources | length' 2>/dev/null || echo 'Not deployed') resources"

logs:
	@echo "📋 Recent deployment logs:"
	kubectl logs -l app=backend -n production --tail=50 2>/dev/null || echo "No Kubernetes logs available"

# ============================================================================
# Development Helpers
# ============================================================================

.PHONY: dev-setup dev-teardown

dev-setup:
	@echo "🛠️  Setting up development environment..."
	$(MAKE) validate
	cd docker-compose && docker compose up -d postgres redis
	@echo "✅ Development environment ready!"

dev-teardown:
	@echo "🛠️  Tearing down development environment..."
	cd docker-compose && docker compose down
	@echo "✅ Development environment stopped!"