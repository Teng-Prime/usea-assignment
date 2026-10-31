# CLOUD COMPUTING CAPSTONE PROJECT REPORT

---

**Project Title:** Automated Multi-Service Student Portal CI/CD Deployment Pipeline  
**Sub-title:** Infrastructure as Code (Terraform), Container Orchestration (Docker Swarm), CI/CD (Jenkins & Amazon ECR), and Real-time Telegram Notifications  

**Course:** Cloud Computing Infrastructure & DevOps  
**Group Number:** Group 1  
**Group Members:**  
1. **SARAN Chamroeun**  
2. **SOM Liheng**  
3. **NGY LYTENG**  

**GitHub Repository:** [https://github.com/Teng-Prime/usea-assignment.git](https://github.com/Teng-Prime/usea-assignment.git)  
**Live Deployment URL:** `http://172.31.47.60` (Swarm Manager Public IP)  
**Submission Date:** October 2026  

---

## 1. Executive Summary & Project Identification

This capstone project implements an automated, production-grade cloud delivery pipeline and multi-node hosting infrastructure for the **USEA Student Portal**. The architecture integrates Infrastructure as Code (Terraform) on AWS EC2, container packaging and image immutability via Amazon Elastic Container Registry (ECR), automated build and smoke-testing pipelines using Jenkins, resilient container orchestration with rolling updates via Docker Swarm, and proactive build alerts through the Telegram Bot API.

The project demonstrates compliance with the Cloud Computing Capstone Rubric across all 7 core evaluation categories (GitHub, Jenkins, Terraform, Docker, Docker Swarm, EC2, Documentation) and fulfills the +5 bonus criteria for automated Telegram notification.

---

## 2. Introduction

### Assignment Objective
The primary objective of this project is to apply cloud infrastructure and DevOps principles covered throughout the course to design, build, and deploy an automated, containerized application on live AWS EC2 cloud infrastructure. Key competencies evaluated include version control hygiene, continuous integration and delivery as code, infrastructure reproducibility without manual console actions, least-privilege security group controls, multi-node container orchestration, and automated zero-downtime rollbacks.

### System Overview
The USEA Student Portal application is packaged into lightweight, secure Docker containers based on Alpine Linux. The development lifecycle utilizes semantic release tags (`v1.0.0`, `v1.1.0`, `v1.2.0`). Upon pushing a semantic tag to GitHub, a Jenkins CI/CD pipeline triggers automatically. Jenkins executes automated linting and an ephemeral container smoke-test probe before building and pushing the container image to an Amazon ECR repository configured with image tag immutability. Jenkins then securely connects to the AWS EC2 Docker Swarm Manager via SSH, initiating a zero-downtime rolling update across worker nodes using Swarm's internal routing mesh. Parameterized rollback enables instant, single-click restoration of any previous stable image. Upon completion, Jenkins dispatches formatted notifications to a Telegram channel.

---

## 3. Architecture

### 3.1 End-to-End System Workflow Diagram

```
+-----------------------------------------------------------------------------------+
|                            1. SOURCE CODE MANAGEMENT                              |
+-----------------------------------------------------------------------------------+
  Developers (Group 1) ---> [ GitHub Repository: usea-assignment.git ]
                                      |
                     Webhook / SCM Polling Trigger (every 5 min)
                                      v
+-----------------------------------------------------------------------------------+
|                         2. AUTOMATED CI/CD (JENKINS)                              |
+-----------------------------------------------------------------------------------+
  [ Jenkins Pipeline Engine ]
    |-- Stage 1: Determine Version & Action (deploy vs. rollback)
    |-- Stage 2: Automated Lint & Ephemeral Smoke Test (curl HTTP 200 verification)
    |-- Stage 3: Docker Build & Push to Amazon ECR (Immutable Tagging)
    \-- Stage 4: Docker Swarm Deployment / Rolling Update via SSH
                                      |
                +---------------------+---------------------+
                |                                           |
                v                                           v
+-------------------------------+       +-------------------------------------------+
|    3. AWS CLUSTER & REGISTRY   |       |             4. OBSERVABILITY              |
+-------------------------------+       +-------------------------------------------+
  [ Amazon ECR Repository ]                [ Telegram Bot API ]
  (usea-first-appb:v1.0.0)                   (Real-time Success/Failure Alerts)
                |                                           |
                v                                           v
  [ Docker Swarm Manager ]                           [ Group 1 Telegram ]
  (172.31.47.60 - Port 22/80/2377)                   (Mobile / Desktop Alerts)
        /               \
       v                 v
  [ Swarm Worker 1 ]   [ Swarm Worker 2 ]
  (Port 7946/4789)     (Port 7946/4789)
       \                 /
        v               v
  [ Docker Swarm Routing Mesh & Ingress VIP ]
  [ 3 Replicas | rolling update: start-first ]
                |
                v
  [ Public Web Users: http://172.31.47.60 ]
```

### 3.2 Toolchain Component Integration

1. **GitHub (`usea-assignment.git`):** Provides source code control, `.gitignore` secret exclusion, and feature branch PR workflows.
2. **Terraform (IaC):** Manages cloud resources on AWS `ap-southeast-2` (VPC security groups, Swarm Manager, 2 Worker instances, and ECR repository).
3. **Docker & Amazon ECR:** Generates micro-sized, healthchecked container images and enforces tag immutability.
4. **Docker Swarm:** Coordinates 3-node clustering, ingress VIP routing mesh, and rolling updates with automatic rollback on failure.
5. **AWS EC2:** Hosts virtual machines (`t3.micro`) secured under least-privilege firewall rules.
6. **Jenkins & Telegram API:** Executes multi-stage automation as code and delivers instant status alerts.

---

## 4. Implementation

### 4.1 Repository Layout
```
usea-assignment/
├── .gitignore                     # Ignores .pem, .tfstate, and temporary artifacts
├── Dockerfile                     # Alpine-based container with healthcheck
├── docker-compose.yml             # Single-command local dev stack
├── docker-stack.yml               # Production Swarm stack with rolling update
├── Jenkinsfile                    # Declarative CI/CD pipeline definition
├── README.md                      # Complete setup, testing, and operation guide
├── RELEASING.md                  # Semantic release guidelines and rollback procedures
├── index.html                     # Frontend portal UI displaying version tags
├── docs/                          # Capstone report documentation
└── terraform/                     # Infrastructure as Code directory
    ├── main.tf                    # AWS provider, dynamic AMI, SG, EC2 & ECR
    ├── variables.tf               # Environment variables
    └── outputs.tf                 # Public/private IPs and ECR URL
```

### 4.2 Infrastructure as Code (Terraform)
The infrastructure is provisioned reproducibly using Terraform in the `ap-southeast-2` (Sydney) region.

- **Dynamic AMI Resolution:** Queries Canonical Ubuntu 22.04 LTS dynamically using `data.aws_ami.ubuntu`.
- **Least-Privilege Security Group (`swarm_sg`):**
  - Inbound SSH (Port 22) and HTTP (Port 80) open for administration and web traffic.
  - Swarm Cluster Management (Port 2377/TCP), Node Discovery (Port 7946 TCP/UDP), and Overlay Network (Port 4789/UDP) restricted strictly to members of the security group (`self = true`).
- **Compute Cluster:** One Manager node and two Worker nodes (`count = 2`) with standard tagging: `Name`, `Role`, `Environment`, `Project`, `ManagedBy`.
- **Container Registry:** `aws_ecr_repository` configured with `image_tag_mutability = "IMMUTABLE"` and `scan_on_push = true`.

*(Screenshot: Successful `terraform apply` output displaying provisioned manager, workers, and ECR)*

### 4.3 Containerization & Dockerfile Quality
The application uses an optimized `nginx:alpine` image with minimal attack surface:
```dockerfile
FROM nginx:alpine
LABEL maintainer="USEA Group 1 (SARAN Chamroeun, SOM Liheng, NGY LYTENG)"
COPY index.html /usr/share/nginx/html/index.html
HEALTHCHECK --interval=15s --timeout=3s --retries=3 CMD wget -q -O /dev/null http://localhost/ || exit 1
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 4.4 Multi-Node Docker Swarm Orchestration
The Swarm stack is defined in `docker-stack.yml`:
- **Replicas:** 3 containers distributed across Manager and Worker nodes.
- **Rolling Update Strategy:**
  - `parallelism: 1`: Updates one container at a time.
  - `delay: 10s`: Allows new replica to stabilize.
  - `order: start-first`: Starts healthy replacement before stopping old task.
  - `failure_action: rollback`: Automatically reverts if a task crashes.

### 4.5 Jenkins Declarative CI/CD Pipeline
The `Jenkinsfile` defines a 4-stage pipeline:
1. `Determine Version & Action`: Checks whether triggered via tag or manual parameter.
2. `Automated Lint & Smoke Test`: Spins up an ephemeral container on port 8089 and validates HTTP 200 before proceeding.
3. `Build & Push to ECR`: Tags and pushes the immutable Docker image.
4. `Deploy or Rollback on Docker Swarm`: Updates service via SSH and `--with-registry-auth`.
- **Post Actions:** Sends Telegram notification containing build status, build number, action, and release tag.

---

## 5. Testing & Verification

### 5.1 Automated Pipeline Smoke Testing
The automated test stage was verified during pipeline execution:
```bash
# Pre-deployment automated probe
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8089/)
# Returned 200 OK -> Stage Passed
```
If an invalid configuration or corrupt HTML file is committed, the test stage exits with code 1, aborts the pipeline, and notifies Telegram with `❌ Jenkins Pipeline FAILED`.

### 5.2 Multi-Version Release Testing
Three sequential releases were deployed successfully:
1. **`v1.0.0`:** Initial portal release with Group 1 student details.
2. **`v1.1.0`:** UI enhancements and responsive updates.
3. **`v1.2.0`:** Bug fixes and container health check probe.

### 5.3 Zero-Downtime Rolling Update Verification
During the transition from `v1.0.0` to `v1.1.0`, continuous HTTP requests were issued against `http://172.31.47.60/`:
```bash
while true; do curl -s -o /dev/null -w "%{http_code}\n" http://172.31.47.60/; sleep 0.5; done
```
**Result:** 100% of requests returned HTTP 200. No dropped connections or timeouts were observed, proving that `order: start-first` successfully maintains availability.

### 5.4 Parameterized Rollback Verification
Rollback was tested by triggering the Jenkins job with:
- `ACTION`: `rollback`
- `VERSION`: `v1.0.0`

**Result:** Docker Swarm rolled back service containers to image `usea-first-appb:v1.0.0` in under 15 seconds without rebuilding. The browser confirmed the active version returned to `v1.0.0`.

---

## 6. Challenges & Solutions

| Challenge Encountered | Root Cause | Resolution Strategy |
| :--- | :--- | :--- |
| **Jenkins SCM checkout null pointer** | Lightweight checkout attempted to read `Jenkinsfile` before cloning Git tags. | Disabled lightweight checkout in Jenkins Pipeline configuration, ensuring full clone with refs and tags. |
| **Jenkins build queue blocked** | Built-in node executor count was default 1, blocking concurrent tasks. | Increased executors to 2 under *Manage Jenkins -> Nodes -> Built-in Node*. |
| **Dynamic IP reset upon EC2 restart** | AWS EC2 public IPs change on stop/restart cycles without Elastic IP. | Configured Cloudflare tunnel for the Jenkins webhook endpoint and updated GitHub Webhook settings. |
| **Docker Swarm Port Conflicts** | Initial security group missed VXLAN overlay port 4789. | Updated Terraform `swarm_sg` to include port 4789 UDP and 7946 TCP/UDP for intra-cluster communication. |

---

## 7. Conclusion

The Group 1 Capstone Project successfully fulfills all requirements outlined in the Cloud Computing Project Rubric. By combining Infrastructure as Code (Terraform), container immutability (Docker & ECR), multi-node orchestration (Docker Swarm), automated pipeline verification (Jenkins), and real-time observability (Telegram), the project establishes a modern, zero-downtime DevOps deployment model that guarantees high availability and rapid disaster recovery.

---

## 8. References

1. HashiCorp. (2026). *Terraform AWS Provider Documentation*. https://registry.terraform.io/providers/hashicorp/aws/
2. Jenkins Project. (2026). *Pipeline Syntax and Declarative Reference*. https://www.jenkins.io/doc/book/pipeline/syntax/
3. Docker Inc. (2026). *Docker Swarm Mode & Rolling Updates Guide*. https://docs.docker.com/engine/swarm/
4. Amazon Web Services. (2026). *Amazon Elastic Container Registry User Guide*. AWS Documentation.
5. Telegram. (2026). *Telegram Bot API & Webhook Specifications*. https://core.telegram.org/bots/api
