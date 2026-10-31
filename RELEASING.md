# Release Management Procedures — Group 1

This document outlines the standard operating procedures for releasing versions of the **USEA Student Portal** using semantic versioning, Git tags, Jenkins CI/CD automation, and Docker Swarm rolling updates.

---

## Release Lifecycle Overview

1. **Feature/Version Changes:** Developer updates `index.html` (or application source) to reflect new features and tag display.
2. **Commit & Tag:** Changes are committed to Git and tagged using semantic versioning (`v1.0.0`, `v1.1.0`, `v1.2.0`).
3. **Automated Pipeline Trigger:** Jenkins detects the Git tag push via webhook or SCM polling.
4. **Testing & Build:** Automated linting and smoke tests validate the build before container images are pushed to Amazon ECR.
5. **Zero-Downtime Deployment:** Docker Swarm executes a rolling update across worker nodes (`order: start-first`, `delay: 10s`).
6. **Telegram Notification:** Pipeline outcome is automatically dispatched to the Group 1 Telegram channel.

---

## 1. Initial Release (`v1.0.0`)
Baseline deployment of the Student Portal.
```bash
# Verify working tree is clean
git status

# Create and push git tag
git tag -a v1.0.0 -m "Release v1.0.0: Initial USEA Student Portal deployment"
git push origin v1.0.0
```

---

## 2. Feature Release (`v1.1.0`)
UI enhancements, performance tuning, and styling updates.
```bash
# Step 1: Update index.html version tag to v1.1.0
sed -i '' 's/Release Version: v1.0.0/Release Version: v1.1.0/' index.html

# Step 2: Commit changes
git add index.html
git commit -m "feat: release v1.1.0 with updated student portal UI"

# Step 3: Create and push tag
git tag -a v1.1.0 -m "Release v1.1.0: Student Portal Feature Update"
git push origin main
git push origin v1.1.0
```

---

## 3. Patch Release (`v1.2.0`)
Bug fixes, security updates, and container configuration improvements.
```bash
# Step 1: Update index.html version tag to v1.2.0
sed -i '' 's/Release Version: v1.1.0/Release Version: v1.2.0/' index.html

# Step 2: Commit changes
git add index.html
git commit -m "fix: release v1.2.0 with critical hotfix and responsive layouts"

# Step 3: Create and push tag
git tag -a v1.2.0 -m "Release v1.2.0: Maintenance and performance patch"
git push origin main
git push origin v1.2.0
```

---

## 4. Zero-Downtime Rollback Procedure (to `v1.0.0`)

In the event of an issue with a newer release, Jenkins provides an instant parameterized rollback without rebuilding the container:

1. Open Jenkins Dashboard: `http://<JENKINS_HOST>:8080/job/usea-assignment/`
2. Click **Build with Parameters**.
3. Set parameters:
   - `ACTION`: `rollback`
   - `VERSION`: `v1.0.0`
4. Click **Build**.
5. Jenkins directly updates the Docker Swarm service using the existing immutable ECR image:
   ```bash
   docker service update --image 781493733610.dkr.ecr.ap-southeast-2.amazonaws.com/usea-first-appb:v1.0.0 --with-registry-auth my_web_app
   ```
6. Verify rollback on the Swarm Manager:
   ```bash
   docker service ps my_web_app
   curl -I http://172.31.47.60/
   ```
