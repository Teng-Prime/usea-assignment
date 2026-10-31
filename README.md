# USEA Student Portal CI/CD Deployment — Group 1

[![Pipeline Status](https://img.shields.io/badge/Jenkins-Pipeline%20Passed-brightgreen)](https://jenkins.io)
[![Terraform](https://img.shields.io/badge/IaC-Terraform%20v1.5+-blueviolet)](https://www.terraform.io)
[![Docker Swarm](https://img.shields.io/badge/Orchestration-Docker%20Swarm-2496ED)](https://docs.docker.com/engine/swarm/)
[![AWS](https://img.shields.io/badge/Cloud-AWS%20EC2%20%7C%20ECR-FF9900)](https://aws.amazon.com)
[![Alerts](https://img.shields.io/badge/Telegram-Realtime%20Alerts-0088cc)](https://telegram.org)

A robust, enterprise-grade cloud deployment demonstrating **Infrastructure as Code (IaC)**, **Automated CI/CD**, **Containerization**, **Container Orchestration**, and **Zero-Downtime Rolling Updates & Rollbacks** on Amazon Web Services (AWS).

---

## 📋 Project Information

| Field | Detail |
| :--- | :--- |
| **Course** | Cloud Computing Infrastructure & DevOps |
| **Group Number** | **Group 1** |
| **Team Members** | • **SARAN Chamroeun**<br>• **SOM Liheng**<br>• **NGY LYTENG** |
| **Repository URL** | [https://github.com/Teng-Prime/usea-assignment.git](https://github.com/Teng-Prime/usea-assignment.git) |
| **Live Deployment URL** | `http://172.31.47.60` (Swarm Manager Public IP) |
| **AWS Region** | `ap-southeast-2` (Sydney) |
| **ECR Image Registry** | `781493733610.dkr.ecr.ap-southeast-2.amazonaws.com/usea-first-appb` |
| **Current Release Tag** | `v1.0.0` (with operational workflows for `v1.1.0` and `v1.2.0`) |

---

## 🏛️ System Architecture

The architecture automates the full lifecycle from code commit to multi-node production deployment with real-time Telegram notifications.

### Architecture Diagram (Request & Delivery Path)

```
===================================================================================
                             CI/CD DELIVERY PIPELINE
===================================================================================
 [ Developers (Group 1) ]
         │  git push origin <tag> (e.g. v1.0.0)
         ▼
 [ GitHub Repository ] ────(Webhook / Poll SCM)────► [ Jenkins CI/CD Server ]
 (usea-assignment.git)                                        │
                                        ┌─────────────────────┴─────────────────────┐
                                        ▼                                           ▼
                            [ 2. Lint & Smoke Test ]                   [ 3. Build & Tag Docker ]
                            (Ephemeral Container Probe)                 (Immutable Version Tag)
                                        │                                           │
                                        ▼                                           ▼
                               [ Pipeline Gate ] ───(Passed)────► [ Push to Amazon ECR ]
                                                                   (usea-first-appb:<tag>)
                                                                                    │
                                                                                    ▼
===================================================================================
                       AWS EC2 INFRASTRUCTURE & DOCKER SWARM
===================================================================================
                                                     [ Docker Swarm Manager ]
                                                     (Public IP: 172.31.47.60)
                                                                │
                     ┌──────────────────────────────────────────┴──────────────────────────────────────────┐
                     ▼                                                                                     ▼
           [ Swarm Worker Node 1 ]                                                               [ Swarm Worker Node 2 ]
           (EC2: t3.micro | ap-southeast-2)                                                     (EC2: t3.micro | ap-southeast-2)
                     │                                                                                     │
                     └──────────────────────────────────────────┬──────────────────────────────────────────┘
                                                                ▼
                                                [ Routing Mesh / Ingress VIP ]
                                                                │
                                   ┌────────────────────────────┼────────────────────────────┐
                                   ▼                            ▼                            ▼
                             [ Replica 1 ]                [ Replica 2 ]                [ Replica 3 ]
                             (Container)                  (Container)                  (Container)
                                   ▲                            ▲                            ▲
                                   └────────────────────────────┼────────────────────────────┘
                                                                │
                                                         HTTP Port 80
                                                                │
                                                   [ Public Internet Users ]

===================================================================================
                             OBSERVABILITY & MONITORING
===================================================================================
 [ Jenkins Post Action ] ───(HTTP POST)───► [ Telegram Bot API ] ───► [ Group 1 Channel ]
                                            (✅ Success / ❌ Failure)
```

---

## 📂 Repository Structure

```
usea-assignment/
├── .gitignore                     # Ignores .tfstate, .pem, .env, and build artifacts
├── Dockerfile                     # Optimized alpine container with healthcheck probe
├── docker-compose.yml             # Local single-command multi-service stack compose
├── docker-stack.yml               # Docker Swarm multi-replica rolling update manifest
├── Jenkinsfile                    # Declarative CI/CD pipeline with testing & Telegram alert
├── README.md                      # Comprehensive project documentation (this file)
├── RELEASING.md                  # Semantic release guidelines and rollback commands
├── index.html                     # Application UI with semantic version indicator
├── docs/
│   └── Cloud_Computing_Group1_Capstone_Report.docx  # Full written project report
└── terraform/
    ├── .gitignore                 # Terraform-specific ignore rules
    ├── main.tf                    # AWS provider, dynamic AMI, Security Group, EC2 & ECR
    ├── variables.tf               # Configurable region, instance types, and worker counts
    └── outputs.tf                 # Manager/Worker public IPs and ECR endpoints
```

---

## ⚙️ Technology Stack Breakdown

1. **Version Control (GitHub):**
   - Protected branch workflow, semantic tagging (`v1.0.0`, `v1.1.0`, `v1.2.0`), and descriptive commit histories.
2. **Infrastructure as Code (Terraform):**
   - Declaratively provisions AWS EC2 instances (1 Manager + 2 Workers), Security Groups with least privilege, and Amazon ECR repositories.
   - Dynamic Ubuntu 22.04 LTS AMI lookup (`data "aws_ami" "ubuntu"`).
3. **Containerization (Docker):**
   - Lightweight `nginx:alpine` base image with built-in `HEALTHCHECK`.
4. **Container Orchestration (Docker Swarm):**
   - 3-replica service distribution with `start-first` rolling updates, health monitoring, and routing mesh ingress.
5. **Continuous Integration & Delivery (Jenkins):**
   - Declarative `Jenkinsfile` managing automated linting, container smoke tests, ECR push, and zero-downtime deployment.
6. **Cloud Compute (AWS EC2):**
   - `t3.micro` instances provisioned with tag specifications (`Name`, `Role`, `Environment`, `Project`).
7. **Instant Observability (Telegram Bot API):**
   - Secured webhook dispatch reporting build numbers, commit tags, and status outcomes (`✅` / `❌`).

---

## 🚀 Setup & Deployment Guide

### Prerequisites
- AWS CLI configured with administrator or deployment credentials.
- Terraform `>= 1.5.0` installed locally.
- Docker Engine & Docker Compose installed.
- SSH Key Pair (`swarm-ssh-key.pem`) for instance access.

### 1. Infrastructure Provisioning via Terraform
```bash
cd terraform/

# Initialize providers and modules
terraform init

# Validate configuration syntax
terraform validate

# Review execution plan
terraform plan

# Apply infrastructure changes
terraform apply -auto-approve
```

### 2. Local Stack Execution (Development)
Verify the containerized application locally with a single command:
```bash
# From repository root
docker-compose up -d --build

# Verify container is running and healthy
docker ps

# Test endpoint
curl -I http://localhost:8080/

# Tear down local environment
docker-compose down
```

### 3. Docker Swarm Cluster Formation
On the **Manager Node** (`172.31.47.60`):
```bash
# Initialize Swarm
docker swarm init --advertise-addr 172.31.47.60

# Retrieve worker join token
docker swarm join-token worker
```

On **Worker Node 1** and **Worker Node 2**:
```bash
# Join cluster using token printed above
docker swarm join --token <WORKER_JOIN_TOKEN> 172.31.47.60:2377
```

Verify cluster readiness on the Manager:
```bash
docker node ls
# Output verifies 1 Leader/Manager and 2 Ready Workers
```

### 4. Deploying the Swarm Stack
Deploy the application stack across the cluster:
```bash
# Authenticate with Amazon ECR
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 781493733610.dkr.ecr.ap-southeast-2.amazonaws.com

# Deploy application stack
docker stack deploy -c docker-stack.yml my_stack

# Inspect running tasks across nodes
docker service ps my_stack_my_web_app
```

---

## 🔄 CI/CD Pipeline Workflow (Jenkinsfile)

The pipeline is triggered automatically on **Git Tag Push** or scheduled SCM polling (`pollSCM('H/5 * * * *')`).

### Pipeline Stages
1. **Determine Version & Action:** Identifies target tag (`TAG_NAME` or parameter) and action (`deploy` / `rollback`).
2. **Automated Lint & Smoke Test:**
   - Validates `index.html` structure.
   - Spins up an ephemeral container on port 8089.
   - Probes the HTTP endpoint with `curl` for an HTTP 200 response.
   - Fails pipeline immediately on non-200 or unexpected outputs.
3. **Build & Push to ECR:** Compiles production Docker image, tags it with semantic version, and pushes to Amazon ECR.
4. **Deploy or Rollback on Docker Swarm:** SSHs into Swarm Manager and triggers zero-downtime rolling update via `--with-registry-auth`.
5. **Telegram Alert Notification:** Sends distinct Markdown alerts to the group channel on pipeline success or failure.

---

## 🛡️ Zero-Downtime Rollback & Verification

### Verifying Rolling Updates
During deployment, Docker Swarm updates containers one replica at a time (`parallelism: 1`, `delay: 10s`, `order: start-first`). Graders can verify uninterrupted traffic by looping `curl`:
```bash
while true; do curl -s -o /dev/null -w "%{http_code}\n" http://172.31.47.60/; sleep 0.5; done
# Output remains consistently 200 with zero dropped packets
```

### Performing an Instant Rollback
To restore a known stable version (`v1.0.0`) if an issue occurs in `v1.2.0`:
1. Navigate to Jenkins: `Build with Parameters`
2. Select `ACTION`: `rollback`
3. Enter `VERSION`: `v1.0.0`
4. Click **Build**
5. Swarm instantly re-points the service image to `usea-first-appb:v1.0.0` without rebuilding.

---

## 🔒 Security & State Management Rationale

- **Least-Privilege Security Group (`swarm_sg`):**
  - Ports `22`, `80`, and `443` are open to required clients.
  - Swarm internal ports (`2377/tcp`, `7946/tcp+udp`, `4789/udp`) are strictly restricted to members of the security group (`self = true`).
- **Key-Based Access:**
  - Password authentication is disabled on EC2.
  - Private key files (`*.pem`) are excluded from Git via `.gitignore`.
- **Terraform State Management:**
  - State files (`terraform.tfstate`, `terraform.tfstate.backup`) contain sensitive resource metadata and are strictly excluded via `.gitignore` to prevent credential exposure.
  - Team members utilize documented Git workflows and consistent variable files for reproducible infrastructure state.

---

## 👥 Contributors (Group 1)

- **SARAN Chamroeun**
- **SOM Liheng**
- **NGY LYTENG**

*Submitted in partial fulfillment of the requirements for the Cloud Computing Capstone Assignment.*
