# End-to-End DevOps Pipeline for a Web Application with CI/CD

## Problem Statement

DevOps teams require a CI/CD pipeline to streamline the development and deployment process, ensuring that changes are consistently tested, built, and deployed across environments. This project implements a **GitOps-based pipeline** using Jenkins for CI (build & push) and **Argo CD** for CD (continuous deployment to Kubernetes). Jenkins automates building and testing, while Argo CD watches the Git repository for manifest changes and syncs them to AWS EKS — ensuring the cluster always matches the desired state in Git.

## Project Goals

1. Design an application architecture that includes load balancing, container orchestration, and monitoring on AWS.
2. Provision AWS infrastructure using Terraform, including VPC, subnets, and EKS clusters.
3. Automate configuration management with Ansible to streamline server setup and application configuration.
4. Deploy the application on Kubernetes within AWS EKS, ensuring scalability and resilience.
5. Implement Jenkins CI for continuous integration and **Argo CD for GitOps-based continuous deployment** from code changes to production.
6. Set up monitoring with Prometheus and Grafana to monitor infrastructure and application performance.

## Architecture Overview

The architecture has three layers: (1) **Bootstrap layer** — Terraform provisions infrastructure and Ansible configures Jenkins + Argo CD, (2) **CI layer** — Jenkins builds and pushes images, updates manifests, and (3) **CD layer** — Argo CD syncs manifests from Git to EKS.

### Bootstrap Flow (One-time Setup)

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                           BOOTSTRAP LAYER                                      │
│                                                                               │
│  ┌──────────┐       ┌──────────────────┐       ┌──────────────────────────┐  │
│  │Terraform │──────▶│ AWS Resources:   │──────▶│  Ansible Configures:     │  │
│  │(Provision│       │ - EC2 (Jenkins)  │       │  - Jenkins server        │  │
│  │ all infra│       │ - EKS Cluster    │       │  - Plugins & JCasC       │  │
│  │         )│       │ - ECR Registry   │       │  - Docker, kubectl       │  │
│  └──────────┘       │ - VPC/Subnets    │       │  - AWS CLI               │  │
│                     │ - S3 (state)     │       │  - Argo CD on EKS        │  │
│                     │ - IAM Roles      │       │                          │  │
│                     └──────────────────┘       └──────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────┘
```

### CI/CD Pipeline Flow (Continuous — GitOps)

```
┌─────────────┐     ┌─────────────┐     ┌───────────────────────────────────────┐
│  Developer  │────▶│   GitHub    │────▶│       Jenkins CI (EC2)                │
│  (Git Push) │     │  (App Repo) │     │  ┌─────────────────────────────────┐  │
└─────────────┘     └─────────────┘     │  │ Pipeline Stages:                │  │
                                         │  │  1. Build → Docker Image        │  │
                                         │  │  2. Test → Run unit/lint tests  │  │
                                         │  │  3. Push → Image to AWS ECR     │  │
                                         │  │  4. Update → K8s manifests with │  │
                                         │  │     new image tag (Git commit)  │  │
                                         │  └─────────────────────────────────┘  │
                                         └──────────────────┬────────────────────┘
                                                            │
                                                  (commits updated manifests)
                                                            │
                                                            ▼
                    ┌──────────────────────────────────────────────────────────┐
                    │              GitHub (K8s Manifests / GitOps Repo)         │
                    └────────────────────────────┬─────────────────────────────┘
                                                 │
                                          (Argo CD watches)
                                                 │
                                                 ▼
                    ┌──────────────────────────────────────────────────────────┐
                    │                      AWS EKS Cluster                      │
                    │                                                          │
                    │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │
                    │  │  Argo CD   │  │ Prometheus │  │  Grafana   │         │
                    │  │  (GitOps   │  │(Monitoring)│  │(Dashboards)│         │
                    │  │  Controller)  │  └──────┬─────┘  └──────┬─────┘         │
                    │  └─────┬──────┘           │               │               │
                    │        │ (syncs)          │               │               │
                    │        ▼                  │               │               │
                    │  ┌────────────┐           │               │               │
                    │  │  App Pods  │           │               │               │
                    │  │(Deployment)│           │               │               │
                    │  └─────┬──────┘           │               │               │
                    │        │                  │               │               │
                    │  ┌─────▼──────────────────▼───────────────▼─────┐         │
                    │  │     Load Balancer + HPA (Auto-Scaling)        │         │
                    │  └──────────────────────────────────────────────┘         │
                    └──────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
                                         ┌──────────────┐
                                         │   End Users   │
                                         └──────────────┘
```

### Key Design Decisions

| Concern | Approach |
|---------|----------|
| **CI (Build & Test)** | Jenkins — builds Docker images, runs tests, pushes to ECR |
| **CD (Deploy)** | Argo CD — watches Git for manifest changes, syncs to EKS |
| **GitOps Single Source of Truth** | Kubernetes manifests in Git define desired cluster state |
| **Jenkins Server Management** | Ansible — installs, configures, maintains Jenkins as code |
| **Infrastructure** | Terraform — provisions all AWS resources |

### Ansible's Role in the Architecture

Ansible operates at **two levels**:

| Scope | What Ansible Does |
|-------|-------------------|
| **Jenkins Server (Bootstrap)** | Installs Jenkins, Java, Docker, kubectl, AWS CLI; configures plugins, credentials, JCasC, and pipeline seeds |
| **EKS Cluster Setup** | Installs Argo CD, configures Argo CD applications, sets up worker node dependencies |

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| **Jenkins** | CI pipeline — build, test, push images, update manifests |
| **Argo CD** | CD pipeline — GitOps controller, syncs K8s manifests from Git to EKS |
| **Docker** | Container image builds |
| **Terraform** | Infrastructure as Code (VPC, EKS, EC2, S3) |
| **Ansible** | Configuration management — manages Jenkins server setup + Argo CD installation |
| **Kubernetes (EKS)** | Container orchestration and deployment |
| **AWS ECR** | Docker image registry |
| **Prometheus** | Metrics collection and alerting |
| **Grafana** | Metrics visualization and dashboards |
| **kubectl** | Kubernetes resource management |

### Jenkins Plugins Required

- Docker Pipeline Plugin
- Kubernetes Plugin
- AWS CLI Plugin
- Git Plugin

## CI/CD Pipeline Stages

```
┌────────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────┐
│  Bootstrap │    │  Build   │───▶│  Test    │───▶│Push Image│───▶│Update Manifests│
│  (Ansible) │    │  Stage   │    │  Stage   │    │ to ECR   │    │ in Git (tag)  │
│  [One-time]│    └──────────┘    └──────────┘    └──────────┘    └───────┬───────┘
└─────┬──────┘         ▲                                                  │
      │                │                                          (Git commit)
      ▼                │                                                  │
┌────────────┐   ┌─────┴──────┐                                           ▼
│Jenkins +   │──▶│  Git Push  │                                  ┌────────────────┐
│Argo CD     │   │  Trigger   │                                  │   Argo CD      │
│Ready       │   └────────────┘                                  │  (auto-sync)   │
└────────────┘                                                   │  deploys to EKS│
                                                                 └────────────────┘
```

### How Jenkins + Argo CD Work Together (GitOps)

1. **Developer pushes code** → triggers Jenkins pipeline
2. **Jenkins (CI)** → builds Docker image, runs tests, pushes image to ECR
3. **Jenkins updates manifests** → commits new image tag to the Kubernetes manifests repo/branch
4. **Argo CD (CD)** → detects manifest change in Git, syncs the new desired state to EKS
5. **EKS rolls out** → new pods with updated image, health checks pass

This separation means:
- Jenkins never directly touches the cluster (no kubectl in CI)
- Git is the single source of truth for what's deployed
- Rollbacks = revert a Git commit
- Argo CD provides drift detection and self-healing

### Bootstrap Phase (One-time, via Ansible)
- Terraform provisions AWS infrastructure (VPC, EKS, EC2 for Jenkins, ECR, S3)
- Ansible configures the Jenkins EC2 instance:
  - Installs Jenkins, Java, Docker, AWS CLI
  - Installs and configures plugins (Docker Pipeline, Git, AWS CLI)
  - Applies Jenkins Configuration as Code (JCasC) for credentials, jobs, and security
  - Seeds pipeline jobs from Jenkinsfiles in the repo
- Ansible installs Argo CD on EKS cluster:
  - Deploys Argo CD namespace and components
  - Configures Argo CD Application CRD pointing to the GitOps manifests repo
  - Sets up sync policies (auto-sync, self-heal, prune)

### 1. Build Stage (Jenkins)
- Triggers when code is pushed to the application repository
- Builds Docker image for the application

### 2. Test Stage (Jenkins)
- Runs unit tests, linting, and security scans
- Fails fast if quality gates are not met

### 3. Push Stage (Jenkins)
- Tags and pushes the Docker image to AWS ECR

### 4. Update Manifests Stage (Jenkins)
- Updates the Kubernetes deployment manifest with the new image tag
- Commits and pushes the change to the GitOps manifests repository

### 5. Deploy Stage (Argo CD — Automatic)
- Argo CD detects the new commit in the manifests repo
- Syncs the desired state to the EKS cluster
- Performs progressive rollout with health checks
- Self-heals if cluster state drifts from Git

### 6. Monitoring & Alerts
- Prometheus collects metrics from application and nodes
- Grafana visualizes performance dashboards
- Alerts configured for deployment failures and resource issues

## Project Structure

```
.
├── app/                        # Web application source code
│   ├── Dockerfile              # Application Dockerfile
│   └── ...
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── vpc.tf                  # VPC and networking
│   ├── eks.tf                  # EKS cluster configuration
│   ├── ec2-jenkins.tf          # Jenkins EC2 instance
│   └── backend.tf              # S3 state backend configuration
├── ansible/                    # Configuration management
│   ├── site.yml                # Master playbook
│   ├── inventory/
│   │   ├── hosts               # Static inventory
│   │   └── aws_ec2.yml         # Dynamic inventory (AWS EC2 plugin)
│   ├── roles/
│   │   ├── jenkins/            # Jenkins server role
│   │   │   ├── tasks/
│   │   │   │   ├── main.yml
│   │   │   │   ├── install.yml       # Install Jenkins + Java
│   │   │   │   ├── plugins.yml       # Install & configure plugins
│   │   │   │   └── jcasc.yml         # Apply JCasC configuration
│   │   │   ├── templates/
│   │   │   │   └── jenkins.yaml.j2   # JCasC template
│   │   │   ├── files/
│   │   │   └── defaults/
│   │   │       └── main.yml          # Default variables
│   │   ├── argocd/             # Argo CD installation role
│   │   │   ├── tasks/main.yml        # Install Argo CD on EKS
│   │   │   ├── templates/
│   │   │   │   └── application.yaml.j2  # Argo CD Application CRD
│   │   │   └── defaults/
│   │   │       └── main.yml
│   │   ├── docker/             # Docker installation role
│   │   │   └── tasks/main.yml
│   │   └── aws-cli/            # AWS CLI installation role
│   │       └── tasks/main.yml
│   └── playbooks/
│       ├── setup-jenkins.yml   # Full Jenkins server setup
│       ├── setup-argocd.yml    # Install & configure Argo CD on EKS
│       └── setup-workers.yml   # EKS worker node configuration
├── kubernetes/                 # Kubernetes manifests (GitOps repo)
│   ├── base/
│   │   ├── deployment.yaml     # Application deployment
│   │   ├── service.yaml        # Load balancer service
│   │   ├── hpa.yaml            # Horizontal Pod Autoscaler
│   │   └── kustomization.yaml
│   ├── overlays/
│   │   ├── dev/
│   │   │   └── kustomization.yaml
│   │   └── prod/
│   │       └── kustomization.yaml
│   ├── argocd/
│   │   └── application.yaml   # Argo CD Application definition
│   └── monitoring/
│       ├── prometheus.yaml     # Prometheus configuration
│       └── grafana.yaml        # Grafana configuration
├── jenkins/                    # Jenkins pipeline definitions
│   └── Jenkinsfile             # CI pipeline (build, test, push, update manifests)
└── README.md
```

## Sprint Breakdown

### Sprint 1: Architecture Design, Dockerization, and Jenkins Setup via Ansible
- Design the GitOps application architecture for deployment on AWS EKS
- Dockerize the web application (Dockerfile + AWS ECR)
- Provision Jenkins EC2 instance with Terraform
- **Write Ansible roles to fully configure Jenkins server:**
  - Install Jenkins, Java, Docker, AWS CLI
  - Install and pin required plugins (Docker Pipeline, Git, AWS CLI)
  - Apply Jenkins Configuration as Code (JCasC) for credentials, security, and job seeds
  - Configure IAM role access for ECR
- Set up Git webhook integration for automatic build triggers
- Validate Jenkins is fully operational via Ansible (idempotent re-runs)

### Sprint 2: AWS Infrastructure Provisioning with Terraform
- Write Terraform scripts for VPC, EKS cluster, subnets, security groups, EC2
- Store Terraform state files securely in AWS S3
- Provision ECR repository for Docker images
- Test infrastructure provisioning consistency across environments

### Sprint 3: Argo CD Setup and GitOps Configuration
- **Install Argo CD on EKS cluster via Ansible**
- Configure Argo CD Application CRD pointing to the K8s manifests in Git
- Set up sync policies: auto-sync, self-heal, prune
- Structure Kubernetes manifests with Kustomize (base + overlays for dev/prod)
- Test Argo CD sync by pushing a manifest change and verifying deployment

### Sprint 4: CI Pipeline (Jenkins) + CD Integration (Argo CD)
- Create Jenkins CI pipeline (build, test, push to ECR)
- Add pipeline stage to update image tag in K8s manifests and commit to Git
- Verify end-to-end flow: code push → Jenkins builds → manifest updated → Argo CD deploys
- Configure health checks and HPA in deployment manifests
- Test rollback by reverting a manifest commit

### Sprint 5: Monitoring Setup with Prometheus and Grafana
- Install Prometheus in EKS cluster for metrics collection
- Set up Grafana dashboards for application performance and resource health
- Monitor Argo CD sync status and deployment health
- Configure alerting rules and Jenkins notifications for failures

### Sprint 6: Testing, Documentation, and Final Automation
- Write test cases for application functionality, deployment, and infrastructure
- Document Jenkins pipeline, Terraform, Ansible, and Argo CD setup
- Automate full flow testing (code push → deploy → validate)
- Conduct final end-to-end testing
- Production-readiness validation

## Getting Started

### Prerequisites
- AWS Account with appropriate IAM permissions
- AWS CLI configured locally
- Terraform >= 1.0
- Ansible >= 2.9
- Docker
- kubectl
- Jenkins (will be provisioned on EC2)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd gitops-webapp-pipeline
   ```

2. **Provision infrastructure:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Configure Jenkins with Ansible:**
   ```bash
   cd ../ansible
   ansible-playbook -i inventory/aws_ec2.yml playbooks/setup-jenkins.yml
   ```

4. **Install Argo CD on EKS:**
   ```bash
   ansible-playbook -i inventory/aws_ec2.yml playbooks/setup-argocd.yml
   ```

5. **Access Jenkins:**
   - Navigate to `http://<jenkins-ec2-public-ip>:8080`
   - CI pipeline is pre-configured via JCasC

6. **Access Argo CD:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8443:443
   ```
   - Navigate to `https://localhost:8443`
   - Argo CD watches the `kubernetes/` directory for manifest changes

7. **Trigger the pipeline:**
   - Push a code change → Jenkins builds & pushes image → updates manifests → Argo CD deploys

## Deliverables

- **Jenkins CI Pipeline** — Automated build, test, and push pipeline triggered by code changes
- **Argo CD GitOps Deployment** — Continuous deployment from Git manifests to EKS with auto-sync and self-healing
- **AWS Infrastructure** — Automated infrastructure setup using Terraform (VPC, EKS, EC2, S3, ECR)
- **Configuration Management** — Ansible roles for Jenkins server setup and Argo CD installation
- **Kubernetes Manifests** — Kustomize-based manifests with base/overlays for multi-environment support
- **Monitoring and Alerts** — Real-time monitoring with Prometheus and Grafana, integrated alerts
- **Comprehensive Documentation** — Setup guides, usage instructions, and troubleshooting

## Evaluation Criteria

| Category | Weight |
|----------|--------|
| Documentation | 15% |
| Implementation | 75% |
| Cost Optimization | 10% |
