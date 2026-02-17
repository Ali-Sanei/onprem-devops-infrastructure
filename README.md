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

## Day 10 – Blue/Green Deployment
In Day 10, a Blue/Green deployment strategy was implemented to achieve zero-downtime releases.

### Features
- Parallel Blue and Green application containers on the app-server
- Jenkins pipeline detects active version automatically
- New version deployed to inactive color
- Health check validation before traffic switch
- Nginx dynamically routes traffic to the active container

### Result
- Zero-downtime application deployment
- Safer releases with instant rollback capability
- Production-like deployment strategy implemented on-prem

# 🚀 Production-Grade Blue/Green Deployment with Jenkins, Docker & Ansible

## 📌 Project Overview

This project demonstrates a **production-ready Blue/Green deployment strategy** using:

- Jenkins (CI/CD Pipeline)
- Docker
- Ansible
- Nginx (Reverse Proxy)
- Custom Health Checks
- Zero-downtime deployment logic

The system ensures:

- ✅ Zero downtime
- ✅ Safe automatic rollback
- ✅ Fully automated deployment
- ✅ Infrastructure provisioning via code

---

# 🏗 Architecture

Developer
↓
GitHub
↓
Jenkins Pipeline (app-server agent)
↓
Ansible (Infra provisioning)
↓
Docker Network (app-net)
↓
Nginx Container (Reverse Proxy)
↓
myapp-blue | myapp-green


---

## 🧩 Components

| Component | Purpose |
|-----------|----------|
| Jenkins | CI/CD Orchestration |
| Ansible | Infrastructure provisioning |
| Docker | Container runtime |
| Nginx | Reverse proxy & traffic switching |
| Blue/Green Containers | Zero-downtime deployments |

---

# 🔵🟢 Blue/Green Deployment Flow

1. Detect currently active color (blue/green)
2. Build new Docker image
3. Deploy new container on alternate port
4. Run health checks
5. Switch Nginx upstream to new version
6. Remove old container
7. Rollback automatically on failure

---

# 📂 Project Structure

ansible/
roles/
docker/
nginx/

app/
Dockerfile
app.sh
health.sh
version.txt

nginx/
template/
upstream.conf.tpl


---

# ⚙️ CI/CD Pipeline Stages

1. Ensure Infrastructure (Ansible)
2. Ensure Docker Network
3. Detect Active Color
4. Build Image
5. Deploy New Version
6. Health Check
7. Switch Traffic
8. Cleanup Old Version
9. Rollback on Failure

---

# 🧪 Health Check Strategy

The pipeline waits until the new container returns **HTTP 200** before switching traffic.

- Retries: 10
- Delay: 3 seconds

If health check fails → deployment aborts automatically.

---

# 🔁 Automatic Rollback

If any stage fails:

- The newly deployed container is removed
- Traffic remains on previous stable version
- Deployment marked as failed in Jenkins

This ensures zero-risk deployment.

---

# ⚠️ Challenges & Solutions

| Issue | Solution |
|-------|----------|
| Docker daemon not ready | Added wait loop in Ansible |
| Jenkins shell incompatibility | Avoided `pipefail`, used compatible shell |
| Bad substitution error | Fixed environment variable usage |
| Nginx reload issues | Correct upstream template handling |
| Rollback variable mismatch | Standardized variable naming |

---

# 📦 Docker Network

All containers run inside a dedicated network:


This allows:

- Clean internal communication
- Isolation from host
- Proper service discovery

---

# 🚀 How To Run

1. Push changes to GitHub
2. Trigger Jenkins pipeline
3. Pipeline automatically:
   - Builds Docker image
   - Deploys new version
   - Runs health checks
   - Switches traffic
   - Removes old version

Access the application:


---

# 📈 Future Improvements

- Add Prometheus monitoring
- Add Grafana dashboards
- Push images to private Docker registry
- Add Slack/Telegram notifications
- Implement Canary deployments
- Add Auto-scaling support
- Add Docker Compose or Kubernetes migration

---

# 🎯 What This Project Demonstrates

- Production-ready CI/CD design
- Zero-downtime deployment
- Infrastructure as Code (IaC)
- Automated rollback logic
- Real-world troubleshooting of Docker & Jenkins

---

# 👤 Author

**Ali Sanei**  
DevOps Engineer  
Hands-on Production Infrastructure

---

# 🏁 Final Note

This is not just a demo project.  
It represents a real-world Blue/Green deployment implemented on-prem with real operational challenges.

## 🔁 Blue-Green Deployment Strategy

This project uses a Blue-Green deployment strategy to achieve zero-downtime deployments.

### How It Works

1. Two environments exist:
   - `myapp-blue`
   - `myapp-green`

2. Only one environment serves traffic at a time.

3. Deployment flow:
   - Build Docker image with Git SHA tag
   - Deploy new version to inactive environment
   - Run health checks
   - Switch Nginx upstream to new version
   - Remove old container

If deployment fails, the new container is removed and traffic remains on the previous version.

## 🧪 Health Check

After deploying the new version, Jenkins performs:

- 10 health check attempts
- 3 seconds interval
- HTTP 200 validation

If health check fails:
- Deployment is marked as failed
- New container is removed
- Traffic is not switched

## 🏷 Docker Image Versioning

Each build is tagged with:

- Git short SHA
- latest tag

Example:

myapp:a91d23f
myapp:latest

This ensures traceability between Git commits and running containers.

## 🧱 Infrastructure Provisioning

Infrastructure setup is automated using Ansible.

It ensures:

- Docker is installed and running
- Docker network exists
- Nginx container is running
- Upstream config is managed

## 🔐 Safety Mechanisms

- Health check validation before traffic switch
- Automatic rollback on failure
- Concurrent build prevention
- Timestamped logs

## 📈 CI/CD Pipeline Flow

1. Checkout source code
2. Ensure infrastructure
3. Detect active environment
4. Build Docker image
5. Deploy new version
6. Health check
7. Switch traffic
8. Cleanup old version







