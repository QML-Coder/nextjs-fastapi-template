# Kubernetes Configuration Guide

This directory contains **Kubernetes** configurations for deploying and running the Next.js + FastAPI application in a cloud environment.

## What is Kubernetes?

**Kubernetes** (often abbreviated as **K8s**) is an open-source platform that automates deploying, scaling, and managing containerized applications. Think of it as an operating system for your cloud infrastructure that:

- **Runs your applications** in containers (like Docker containers)
- **Automatically scales** your application up or down based on demand
- **Heals itself** by restarting failed containers
- **Distributes traffic** between multiple copies of your application
- **Manages secrets** like passwords and API keys securely

## Directory Structure

```
kubernetes/
├── base/                    # Core application configurations
│   ├── namespace.yaml       # Isolated environment for our app
│   ├── secrets.yaml         # Passwords and sensitive configuration
│   ├── backend-deployment.yaml  # How to run the FastAPI backend
│   ├── backend-service.yaml     # How to expose the backend to traffic
│   └── ingress.yaml         # How external traffic reaches the app
└── overlays/                # Cloud-specific additional configurations
    └── aws/                 # Amazon Web Services specific settings
        ├── aws-load-balancer-controller.yaml
        ├── cluster-autoscaler.yaml
        └── ebs-csi-driver.yaml
```

## Core Kubernetes Concepts Explained

### Pods
A **Pod** is the smallest unit in Kubernetes. It contains one or more containers that work together. Think of it as a "wrapper" around your application container.

### Deployments
A **Deployment** tells Kubernetes how many copies (replicas) of your application to run and how to update them. If a pod crashes, the deployment automatically creates a new one.

### Services
A **Service** provides a stable way for other parts of your application to communicate with your pods. Even if pods are created or destroyed, the service provides a consistent endpoint.

### Ingress
An **Ingress** is like a front door for your application. It receives traffic from the internet and routes it to the correct service inside your cluster.

### Namespaces
A **Namespace** is like a virtual cluster within your physical cluster. It provides isolation between different applications or environments (dev, staging, production).

## Configuration Files Explained

### `base/namespace.yaml`
Creates an isolated environment called "production" where our application will run.

**What it does:**
- Creates a separate space for our application
- Prevents conflicts with other applications in the same cluster
- Allows us to set policies specific to our application

### `base/secrets.yaml`
Contains sensitive information that our application needs to run.

**What's included:**
- **DATABASE_URL**: Connection string to reach the PostgreSQL database
- **SECRET_KEY**: Used by FastAPI for security (session encryption, etc.)
- **SMTP settings**: For sending emails (password reset, notifications)
- **REDIS_URL**: For caching and session storage (if using Redis)

**Security Note:** Never put real passwords in this file when committing to Git. These are templates that should be replaced with actual secrets during deployment.

### `base/backend-deployment.yaml`
Tells Kubernetes how to run your FastAPI backend application.

**Key configurations:**
- **Replicas: 2** - Runs 2 copies of your backend for reliability
- **Resource limits** - Prevents the app from using too much CPU/memory
- **Health checks** - Kubernetes checks if the app is healthy via `/health` endpoint
- **Security settings** - Runs the app as a non-root user for security
- **Environment variables** - Loads secrets and configuration into the app

**Health Checks Explained:**
- **Liveness probe**: "Is the application still running?" If not, restart it
- **Readiness probe**: "Is the application ready to receive traffic?" If not, don't send requests to it

### `base/backend-service.yaml`
Creates two ways to access your backend:

1. **backend-service (ClusterIP)**: Internal access within the cluster
2. **backend-service-lb (LoadBalancer)**: External access from the internet

**Load Balancer Annotations Explained:**
- `aws-load-balancer-type: "nlb"` - Uses AWS Network Load Balancer (NLB)
- `aws-load-balancer-backend-protocol: "http"` - Backend uses HTTP protocol
- `aws-load-balancer-healthcheck-path: "/health"` - Checks this URL to ensure backend is healthy

### `base/ingress.yaml`
Configures how external internet traffic reaches your application.

**Key features:**
- **ALB (Application Load Balancer)**: AWS service that distributes incoming traffic
- **SSL/HTTPS redirect**: Automatically redirects HTTP to HTTPS for security
- **Health checks**: Ensures traffic only goes to healthy backend instances
- **Path routing**: Different URLs can go to different services

**Important:** You need to replace `api.your-domain.com` with your actual domain name.

## AWS-Specific Configurations (`overlays/aws/`)

These files add AWS-specific functionality to your Kubernetes cluster.

### `aws-load-balancer-controller.yaml`
**What it does:** Enables Kubernetes to automatically create and manage AWS Load Balancers (ALB/NLB) when you create Ingress resources.

**Why needed:** Without this, Kubernetes doesn't know how to create AWS load balancers automatically.

**Components:**
- **ServiceAccount**: Provides AWS permissions to the controller
- **Deployment**: Runs the controller software that watches for Ingress resources

### `cluster-autoscaler.yaml`
**What it does:** Automatically adds or removes worker nodes (EC2 instances) based on demand.

**How it works:**
- If pods can't be scheduled (not enough resources), it adds new nodes
- If nodes are underutilized, it removes them to save costs
- Monitors resource usage every few seconds

**Cost savings:** Prevents you from paying for unused EC2 instances.

### `ebs-csi-driver.yaml`
**What it does:** Enables your applications to use AWS EBS (Elastic Block Store) volumes for persistent storage.

**EBS explained:** EBS provides persistent storage that survives pod restarts. Like a hard drive that can be attached to different computers.

**Storage Classes:**
- **ebs-gp3**: Default storage class with good performance/cost balance
- **ebs-gp3-retain**: Same as above but data is kept even after pod deletion

## Common Kubernetes Commands

### Viewing Resources
```bash
# See all pods in the production namespace
kubectl get pods -n production

# See detailed information about a specific pod
kubectl describe pod <pod-name> -n production

# See all services
kubectl get services -n production

# Check ingress status
kubectl get ingress -n production
```

### Checking Logs
```bash
# View logs from the backend deployment
kubectl logs -f deployment/backend -n production

# View logs from a specific pod
kubectl logs <pod-name> -n production

# View previous container logs (if pod restarted)
kubectl logs <pod-name> -n production --previous
```

### Debugging
```bash
# Execute commands inside a running pod
kubectl exec -it <pod-name> -n production -- /bin/bash

# Run a temporary pod for debugging
kubectl run debug --image=busybox --rm -it --restart=Never -n production

# Test database connectivity from inside the cluster
kubectl run psql --image=postgres:15 --rm -it --restart=Never -n production -- psql -h <database-endpoint> -U postgres -d nextjs_fastapi
```

### Managing Deployments
```bash
# Apply all configurations
kubectl apply -f base/
kubectl apply -f overlays/aws/

# Update a deployment (after changing the image)
kubectl rollout restart deployment/backend -n production

# Check rollout status
kubectl rollout status deployment/backend -n production

# Scale the application (change number of replicas)
kubectl scale deployment/backend --replicas=3 -n production
```

## Environment Variables and Secrets

### How Secrets Work
1. Secrets are stored in Kubernetes (encrypted at rest)
2. Pods mount secrets as environment variables
3. Applications read these variables at startup

### Updating Secrets
```bash
# Update a secret value
kubectl patch secret app-secrets -n production -p='{"stringData":{"DATABASE_URL":"new-value"}}'

# Restart deployment to pick up new secrets
kubectl rollout restart deployment/backend -n production
```

## Troubleshooting Common Issues

### Pod Won't Start
```bash
# Check pod status and events
kubectl describe pod <pod-name> -n production

# Common issues:
# - Image pull errors (wrong image name/tag)
# - Resource limits too low
# - Missing secrets or config maps
```

### Can't Connect to Database
```bash
# Test database connectivity
kubectl run psql --image=postgres:15 --rm -it --restart=Never -n production -- psql -h <db-endpoint> -U postgres

# Common issues:
# - Wrong DATABASE_URL in secrets
# - Database not accessible from pods (security groups)
# - Database not ready yet
```

### Application Not Accessible
```bash
# Check ingress status
kubectl get ingress -n production
kubectl describe ingress backend-ingress -n production

# Check load balancer status
kubectl get svc -n production

# Common issues:
# - AWS Load Balancer Controller not installed
# - Wrong domain configuration
# - Security groups blocking traffic
```

### High Resource Usage
```bash
# Check resource usage
kubectl top pods -n production
kubectl top nodes

# Check pod resource limits
kubectl describe pod <pod-name> -n production | grep -A 5 "Limits"
```

## Security Best Practices

### What's Already Configured
- **Non-root containers**: Apps run as regular user, not root
- **Read-only file system**: Prevents malicious file modifications
- **Resource limits**: Prevents resource exhaustion attacks
- **Network policies**: (Can be added) Control which pods can communicate
- **Secret management**: Sensitive data stored in Kubernetes secrets

### Additional Security Measures
- Use **Pod Security Standards** to enforce security policies
- Implement **RBAC** (Role-Based Access Control) for fine-grained permissions
- Use **Network Policies** to restrict pod-to-pod communication
- Regularly update container images for security patches
- Use **admission controllers** to enforce security policies

## Monitoring and Observability

### Built-in Health Checks
- **Liveness probes**: Restart unhealthy pods
- **Readiness probes**: Remove unhealthy pods from load balancer rotation

### Additional Monitoring (Not included, but recommended)
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization
- **Jaeger**: Distributed tracing
- **ELK Stack**: Centralized logging

### Useful Monitoring Commands
```bash
# Check pod resource usage
kubectl top pods -n production

# Check node resource usage
kubectl top nodes

# View cluster events
kubectl get events -n production --sort-by='.lastTimestamp'
```

## Next Steps

After deploying these configurations:

1. **Configure monitoring** - Set up Prometheus and Grafana
2. **Set up CI/CD** - Automate deployments with GitHub Actions
3. **Configure backups** - Set up database and persistent volume backups
4. **Implement network policies** - Restrict pod-to-pod communication
5. **Set up alerting** - Get notified when things go wrong

## Getting Help

- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **AWS EKS Documentation**: https://docs.aws.amazon.com/eks/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

Remember: Kubernetes has a learning curve, but once you understand the basic concepts (Pods, Deployments, Services, Ingress), everything else builds on these fundamentals!