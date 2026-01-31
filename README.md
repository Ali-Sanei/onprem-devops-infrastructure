# onprem-devops-infrastructure
A production-like on-prem DevOps infrastructure built using ESXi, Linux, Ansible, Docker, Jenkins, and monitoring tools.


## Project Overview
Production-like on-prem DevOps infrastructure using ESXi, Linux, Ansible, Docker, Jenkins.

## Architecture
- CI Server (Jenkins)
- Application Server (Docker, Nginx)
- Monitoring Server (Prometheus, Grafana)

## Network Plan
- ci-server: 192.168.10.10
- app-server: 192.168.10.20
- monitoring: 192.168.10.30

## Tech Stack
- Ubuntu Server 22.04
- ESXi
- Ansible
- Docker
- Jenkins

## Security
- SSH key-based authentication
- Root login disabled
- UFW enabled

## CI/CD
- Jenkins running on dedicated CI server
- Docker used for application deployment

## Day 7 – Jenkins CI/CD Pipeline with Docker & Ansible

In Day 7, a complete CI/CD pipeline was implemented using Jenkins.

### 🔧 Architecture
- **CI Server**: Jenkins  
- **App Server**: Docker runtime (application deployment)
- Jenkins connects to app-server via SSH agent.

### 🚀 Pipeline Workflow
1. Checkout source code from GitHub
2. Build Docker image for a simple Nginx application
3. Deploy and run the container on the app-server

### 📦 Technologies Used
- Jenkins (Declarative Pipeline)
- Docker
- Ansible
- SSH Agent

### ✅ Result
- Jenkins pipeline executed successfully
- Docker container deployed on app-server
- Application accessible via app-server IP in browser

This was the first fully automated CI/CD workflow in the project.

### CI/CD Pipelines

- **infra-pipeline**  
  Provisions infrastructure using Ansible (Docker, Java, Jenkins agent)

- **app-pipeline**  
  Builds Docker image and deploys application to app-server

## Day 8 – Infrastructure as Code with Ansible

In Day 8, infrastructure provisioning was fully automated using Ansible and executed via Jenkins.

### 🔧 Implemented Features
- Docker installation and configuration via Ansible
- Java installation via Ansible
- User permission management (docker group)
- Idempotent infrastructure setup

### 🚀 CI Integration
- Dedicated Jenkins infra pipeline
- Ansible executed on app-server via SSH agent
- Clear separation between infrastructure and application pipelines

### ✅ Result
- Infrastructure fully provisioned from code
- Jenkins infra pipeline completed successfully

## Day 9 – Versioned Docker Deployment with Rollback

### Features
- Docker images built with semantic versioning
- Jenkins pipeline executed on app-server agent
- Automatic rollback to previous version on failure
- Safe container replacement without manual intervention

### Workflow
1. Read application version from repository
2. Save currently running container version
3. Build new Docker image
4. Deploy new version
5. Roll back automatically if deployment fails

### Result
- Zero manual intervention deployment
- High reliability deployment strategy





