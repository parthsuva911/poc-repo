
# Application Deployment Architecture Overview
 
This document provides an overview of the architecture for deploying a Dockerized application to an Amazon EKS cluster using GitHub Actions for CI/CD.
 
## Architecture Components
 
### GitHub Repository
- Contains two branches: `development` and `production`.
- Represents different versions of the application for both development and production environments.
 
### Amazon ECR Repository
- Manages Docker container images for the application.
- Located in the same AWS region as the EKS cluster.
 
### Amazon EKS Cluster
- Deployed with required add-ons for Kubernetes orchestration.
- Includes AWS Load Balancer Controller for managing AWS Load Balancers using Ingress objects.
- The cluster role allows access to create load balancers and pull images from ECR on behalf of users.
 
### AWS Load Balancer
- Created when deploying the application for the first time.
- Managed by the Ingress object created using manifests.
- The load balancer endpoint is accessible to the internet and redirects requests to the application through the associated service.
 
## CI/CD Components
 
### GitHub Actions Workflow
- Automates the deployment process of the Dockerized application to the Amazon EKS cluster.
- Triggers on both `push` and `pull_request` events for branches named `production` and `development`.
- Defines environment variables such as AWS region, ECR repository name, short SHA, and EKS cluster name.
 
### Workflow Steps
1. **Clone**: Clones the repository into the GitHub Actions environment.
2. **Branch used**: Determines the branch being used (from either `push` or `pull_request` event).
3. **Configure AWS credentials**: Configures AWS credentials using GitHub Secrets.
4. **Login to Amazon ECR**: Authenticates Docker to the Amazon ECR registry.
5. **Build, tag, and push image to Amazon ECR**: Checks if the same build exists or not. If it exists, skips this step. Builds the Docker image from the `app` directory, tags it with both `latest` and short SHA, and pushes it to Amazon ECR.
6. **Install and configure kubectl**: Installs and configures kubectl for Kubernetes operations.
7. **Deploy**: Deploys the application to the EKS cluster. Sets environment variables for the ECR registry, branch, image tag. Defines functions for namespace existence check, deployment creation, deployment status check, and deployment rollback. Executes the main deployment process, checking namespace existence, creating deployment, waiting for deployment to complete, and rolling back if necessary.
 

This workflow ensures a streamlined CI/CD process, ensuring that changes pushed to the `production` or `development` branches trigger the building, tagging, and deployment of the Docker image to the EKS cluster.

```
poc-repo/
├─ .github/
│  ├─ workflows/
│  │  ├─ cd.yml
├─ app/
│  ├─ app.py
│  ├─ Dockerfile
│  ├─ requirements.txt
├─ manifests/
│  ├─ deployment.tmpl.yaml
│  ├─ ingress.yml
│  ├─ svc.yml
├─ .gitignore
├─ package.json
├─ README.md
```