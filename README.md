# USEA Student Portal CI/CD Deployment - Group 1

## Project Details
- **Group Number:** Group 1
- **Group Members:** SARAN Chamroeun, SOM Liheng, NGY LYTENG
- **Repository URL:** `https://github.com/Teng-Prime/usea-assignment.git`
- **Live Deployment:** `http://172.31.47.60`

## System Architecture
1. **Infrastructure as Code (Terraform):** Provisions AWS EC2, Security Groups, and Amazon ECR repository `usea-first-appb`.
2. **Containerization (Docker & ECR):** Multi-stage builds published with immutable tags (`v1.0.0`, `v1.1.0`, `v1.2.0`).
3. **Automated Pipeline (Jenkinsfile):** Tag-triggered releases and manual parameterized zero-downtime rollbacks.
4. **Orchestration (Docker Swarm):** Multi-replica container deployment with rolling update strategy.
5. **Monitoring:** Real-time Telegram Bot alerts on pipeline success and failure.