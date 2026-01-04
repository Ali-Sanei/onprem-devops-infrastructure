# onprem-devops-infrastructure
Production-like on-prem DevOps infrastructure using ESXi, Linux, Ansible, Docker, Jenkins and monitoring tools.


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

