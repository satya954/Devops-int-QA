# 🏢 MNC DevOps Interview Q&A — L2 Round

> **Target Profile:** 4–6 years of DevOps experience | **Round:** L2 (Technical Deep-Dive)
>
> _25 production-grade questions with comprehensive, real-world answers — covering Terraform, Docker, CI/CD, Kubernetes, GitOps, Security, and AI tools._

---

## 📑 Table of Contents

| # | Category | Questions |
|---|----------|-----------|
| 🏗️ | **Terraform & IaC** | [1](#-1-in-a-production-environment-terraform-drift-happens-frequently-how-do-you-detect-and-resolve-terraform-drift) – [3](#-3-how-do-you-integrate-terraform-with-your-cicd-pipeline), [22](#-22-if-someone-manually-changes-infrastructure-in-the-cloud-that-is-managed-by-terraform-how-would-you-prevent-such-changes-from-happening-again) |
| 🐳 | **Docker & Containers** | [4](#-4-how-do-you-secure-a-docker-image) – [6](#-6-what-is-docker-layer-caching-how-does-it-work) |
| 🔄 | **CI/CD Pipeline** | [7](#-7-explain-your-end-to-end-cicd-pipeline) – [10](#-10-apart-from-jenkins-and-github-actions-which-other-cicd-tools-have-you-worked-with) |
| ☸️ | **Kubernetes** | [11](#-11-explain-kubernetes-ingress-and-its-architecture) – [15](#-15-explain-readiness-probe-and-liveness-probe-with-practical-use-cases) |
| 🚀 | **Deployment Strategies** | [16](#-16-explain-canary-deployment-with-a-real-world-example) – [17](#-17-what-is-blue-green-deployment-and-when-would-you-choose-it) |
| 🖥️ | **Cloud Troubleshooting** | [14](#-14-auto-scaling-increased-the-number-of-pods-but-the-application-is-still-experiencing-latency-how-would-you-troubleshoot-it), [18](#-18-your-ec2-instance-is-running-but-you-cannot-access-it-how-would-you-troubleshoot-the-issue) |
| 🔄 | **GitOps & Argo CD** | [19](#-19-explain-how-argo-cd-continuously-reconciles-git-changes-with-the-kubernetes-cluster) – [20](#-20-if-a-developer-modifies-the-gitops-repository-how-does-argo-cd-handle-the-change) |
| 🌿 | **Git & Version Control** | [21](#-21-git-merge-vs-git-rebase-how-do-you-resolve-merge-conflicts) |
| 🔒 | **Security (SAST / DAST)** | [23](#-23-what-is-sast-how-do-you-integrate-sast-into-your-cicd-pipeline) – [24](#-24-how-do-you-integrate-dast-into-your-deployment-process) |
| 🤖 | **AI Tools** | [25](#-25-have-you-used-ai-developer-tools-such-as-openai-codex-github-copilot-or-similar-tools) |

---

# 🏗️ Terraform & IaC

---

### 1️⃣ In a production environment, Terraform drift happens frequently. How do you detect and resolve Terraform drift?

**Terraform drift** occurs when the actual state of cloud infrastructure diverges from the state defined in Terraform configuration — usually due to manual changes via the cloud console, CLI scripts, or automated processes outside Terraform's control.

#### Detecting Drift

- **`terraform plan`** — The primary detection mechanism. Running `terraform plan` compares the **live state** against the **desired state** in `.tf` files. Any differences appear as planned actions (create, update, delete). Schedule this via a cron job or CI/CD pipeline to run periodically:
  ```bash
  # Automated drift detection via scheduled job
  terraform init -backend-config=backend.hcl
  terraform plan -detailed-exitcode > /var/log/terraform-drift.log 2>&1
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 2 ]; then
      # Send alert (Slack, PagerDuty, Email)
      curl -X POST -H 'Content-type: application/json' \
          --data '{"text":"🚨 Terraform drift detected on '"$(date)"'"}' \
          $SLACK_WEBHOOK_URL
  fi
  ```
  Exit code `0` = no changes, `1` = error, `2` = **drift detected**.

- **`terraform state list` and `terraform state show`** — Manually inspect individual resources to see what Terraform believes the state is, then compare with the actual cloud resource.

- **Third-party tools**: Platforms like **Spacelift**, **Env0**, and **Driftctl** provide continuous drift detection with dashboards, alerting, and policy enforcement.

#### Resolving Drift

1. **Root-cause analysis**: Determine _why_ the drift occurred — was it an emergency hotfix, a misconfigured automation, or unauthorized manual changes?
2. **Update Terraform code to match reality** (`terraform import` or `terraform apply -refresh-only`) if the manual change was intentional and should be preserved.
3. **Re-apply Terraform** (`terraform apply`) to revert unauthorized changes back to the desired state.
4. **Prevent recurrence**: Implement **SCPs (Service Control Policies)**, **IAM least-privilege**, and **cloudwatch event rules** to detect out-of-band modifications. See also [Question 22](#-22-if-someone-manually-changes-infrastructure-in-the-cloud-that-is-managed-by-terraform-how-would-you-prevent-such-changes-from-happening-again).

---

### 2️⃣ Explain the Terraform state file. How do you protect and secure the state file?

The **Terraform state file** (`terraform.tfstate`) is a JSON file that maps **real-world cloud resources** to your **Terraform configuration**. It tracks resource IDs, attributes, metadata, and dependencies. Without it, Terraform cannot know what already exists, what needs to be created, or what needs to be destroyed.

#### Why State Matters
- Acts as the **source of truth** for resource mapping
- Enables **dependency resolution** between resources
- Allows **safe updates** by comparing planned vs. actual state
- Stores **sensitive values** (passwords, secrets) in plaintext if not handled properly

#### Protection Strategies

| Strategy | How It Works |
|----------|-------------|
| **Remote Backend** | Store state in **S3 + DynamoDB** (AWS), **GCS** (GCP), or **Azure Blob Storage**. This enables team collaboration and prevents local state loss. |
| **State Locking** | Use **DynamoDB** (AWS) or native locking (GCP/Azure) to prevent concurrent modifications. Prevents race conditions when multiple users run `terraform apply`. |
| **Encryption at Rest** | Enable **SSE-KMS** on the S3 bucket. State file is encrypted before being written to disk. |
| **Encryption in Transit** | Enforce **SSL/TLS** on the backend. Terraform communicates with S3 over HTTPS by default. |
| **Access Control** | Restrict IAM policies so only the CI/CD service account and authorized engineers can read/write the state. |
| **Versioning** | Enable S3 **bucket versioning** to retain history. If state is corrupted, roll back to a previous version. |
| **Sensitive Data Handling** | Use `sensitive = true` on outputs and variables. Never commit `.tfstate` to Git. |

```hcl
# Secure S3 backend configuration
terraform {
  backend "s3" {
    bucket         = "myorg-terraform-state-prod"
    key            = "prod/infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:123456789:key/abcd-1234"
  }
}
```

---

### 3️⃣ How do you integrate Terraform with your CI/CD pipeline?

The goal is **every infrastructure change goes through code review and automated validation** — no manual `terraform apply` on a laptop.

#### Pipeline Stages

| Stage | Tool / Action | Purpose |
|-------|--------------|---------|
| **1. PR Created** | `terraform fmt -check` | Validate formatting and syntax |
| **2. Lint** | `tflint` / `checkov` | Catch anti-patterns, security misconfigurations |
| **3. Plan** | `terraform plan` | Generate execution plan, show diff |
| **4. Review** | Post plan output as PR comment | Humans review what will change |
| **5. Apply** | `terraform apply -auto-approve` | Triggered on merge to `main` |
| **6. Verify** | `terraform plan` (post-apply) | Confirm zero drift after apply |

#### GitHub Actions Example

```yaml
name: Terraform CI/CD
on:
  pull_request:
    paths: ['infrastructure/**']
  push:
    branches: [main]
    paths: ['infrastructure/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0

      - name: Terraform Init
        run: terraform init
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Terraform Format Check
        run: terraform fmt -check -diff

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        if: github.event_name == 'pull_request'
        run: |
          terraform plan -out=tfplan -input=false
          terraform show -no-color tfplan > plan.txt
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Post Plan to PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const plan = require('fs').readFileSync('plan.txt', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '```terraform\n' + plan.substring(0, 6000) + '\n```'
            });

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve tfplan
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

#### Key Best Practices
- **Never store credentials in repository** — use OIDC federation or vault-injected secrets
- **Separate environments** — use workspaces or separate directories (`dev/`, `staging/`, `prod/`)
- **Require manual approval** for `prod` applies via **environment protection rules** in GitHub or Jenkins

---

# 🐳 Docker & Containers

---

### 4️⃣ How do you secure a Docker image?

Securing a Docker image is a **multi-layered defense** strategy covering the build process, runtime, and scanning.

#### Build-Time Security
- **Use minimal base images**: Prefer `distroless`, `alpine`, or `scratch` over full OS images like `ubuntu`. Fewer packages = smaller attack surface.
  ```dockerfile
  # Bad — 700+ MB, hundreds of unnecessary packages
  FROM ubuntu:22.04

  # Good — 40 MB, minimal attack surface
  FROM gcr.io/distroless/java17-debian12
  ```
- **Run as non-root user**: Create a dedicated user to prevent container escape and privilege escalation.
  ```dockerfile
  RUN groupadd -r appuser && useradd -r -g appuser appuser
  USER appuser
  WORKDIR /app
  COPY --chown=appuser:appuser target/*.jar /app/
  ```
- **Multi-stage builds**: Keep build tools (compilers, SDKs) out of the final image.
  ```dockerfile
  FROM maven:3.9-eclipse-temurin-17 AS builder
  WORKDIR /build
  COPY pom.xml .
  RUN mvn dependency:go-offline
  COPY src ./src
  RUN mvn package -DskipTests

  FROM gcr.io/distroless/java17-debian12
  COPY --from=builder /build/target/app.jar /app.jar
  ENTRYPOINT ["java", "-jar", "/app.jar"]
  ```
- **Pin image digests** instead of mutable tags:
  ```dockerfile
  # Bad — tag can be overwritten
  FROM node:18

  # Good — immutable cryptographic reference
  FROM node@sha256:abc123def456...
  ```

#### Scanning & Validation
- **Trivy / Grype / Snyk**: Scan for CVEs in both OS packages and application dependencies (SCA).
  ```bash
  trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:latest
  ```
- **Docker Content Trust (DCT)**: Enforce signed images. `DOCKER_CONTENT_TRUST=1` prevents pulling unsigned images.

#### Runtime Security
- **Drop Linux capabilities**: Remove `CAP_NET_RAW`, `CAP_SYS_ADMIN`, etc.
  ```yaml
  securityContext:
    runAsNonRoot: true
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
  ```
- **Read-only root filesystem**: Prevent malware from writing to the container filesystem.
- **Resource limits**: Set CPU/memory limits to prevent DoS from a compromised container.

---

### 5️⃣ What techniques do you use to reduce Docker image size?

Smaller images mean **faster pulls**, **lower storage costs**, **reduced attack surface**, and **faster deployments**.

#### Techniques with Impact

| Technique | Typical Savings | Description |
|-----------|----------------|-------------|
| **Multi-stage builds** | 60–80% | Separate build and runtime layers; only copy artifacts |
| **Distroless / Alpine base** | 70–90% | Replace Ubuntu (700 MB) with distroless (40–80 MB) |
| **Layer optimization** | 10–30% | Combine RUN commands, minimize filesystem churn per layer |
| **`.dockerignore`** | 5–20% | Exclude `node_modules`, `.git`, `logs/`, `target/` from build context |
| **Use `--no-install-recommends`** | 10–15% | Debian/Ubuntu apt installs fewer dependency packages |
| **Squash layers** | 10–25% | Use `docker build --squash` or `docker-squash` tool |

#### Optimized Dockerfile Example

```dockerfile
## Stage 1: Build
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

## Stage 2: Runtime (minimal)
FROM gcr.io/distroless/java17-debian12
WORKDIR /app
COPY --from=builder /build/target/app-1.0.jar app.jar
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Verification
```bash
# Before optimization
docker images myapp:full     # 650 MB

# After optimization
docker images myapp:slim     # 45 MB

# Compare layers
docker history myapp:slim
```

---

### 6️⃣ What is Docker layer caching? How does it work?

**Docker layer caching** is a build optimization where Docker reuses previously built filesystem layers instead of rebuilding them from scratch. Each instruction in a Dockerfile (`FROM`, `COPY`, `RUN`, `ADD`) creates a new **read-only layer** stacked on top of the previous one.

#### How It Works

```
Dockerfile instructions → Layer cache lookup → Hit or Miss
                                                                    │
                    ┌────────────────────────────────────────────────┘
                    ▼
  Layer 1: FROM ubuntu:22.04      ──► [CACHE HIT] (same base = reused)
  Layer 2: RUN apt-get update     ──► [CACHE HIT] (same command = reused)
  Layer 3: COPY pom.xml .         ──► [CACHE HIT] (same file hash = reused)
  Layer 4: RUN mvn install        ──► [CACHE MISS] (pom.xml changed → rebuild)
  Layer 5: COPY src ./src         ──► [CACHE MISS] (cascade — everything after a miss rebuilds)
```

**Key rule**: If any layer changes, **all subsequent layers are invalidated**. The cache is a chain — break one link, rebuild everything downstream.

#### Cache Optimization Strategy

The golden rule: **order instructions from least-changing to most-changing**.

```dockerfile
## ❌ Bad ordering — cache busts on every code change
FROM maven:3.9-eclipse-temurin-17
WORKDIR /app
COPY . .                          # Changes every commit → busts cache
RUN mvn dependency:go-offline     # Re-downloads every build
RUN mvn package

## ✅ Good ordering — dependencies only rebuild when pom.xml changes
FROM maven:3.9-eclipse-temurin-17
WORKDIR /app
COPY pom.xml .                    # Rarely changes → cache hits often
RUN mvn dependency:go-offline     # Cached unless pom.xml changes
COPY src ./src                    # Changes frequently → isolated to last layers
RUN mvn package -DskipTests
```

#### Cache Persistence Tips
- Use **BuildKit** (`DOCKER_BUILDKIT=1`) for parallel layer building and remote cache backends
- Push cache to a **remote registry**: `docker buildx build --cache-to type=registry,ref=myorg/cache:latest`
- In CI/CD: `actions/cache` or **GitHub Actions BuildX persist-to** for cross-run caching

---

# 🔄 CI/CD Pipeline

---

### 7️⃣ Explain your end-to-end CI/CD pipeline.

A production-grade CI/CD pipeline automates the journey from **developer commit** to **production deployment** with quality gates at every stage.

#### Pipeline Architecture

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Commit   │ ──► │   CI     │ ──► │  Artifact│ ──► │  CD      │ ──► │  Monitor │
│  (Git)    │     │  (Build) │     │Registry  │     │(Deploy)  │     │  & Obsv  │
└──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
                       │                              │
                  ┌────▼─────┐                   ┌────▼─────┐
                  │  SAST    │                   │  DAST    │
                  │  SCA     │                   │  E2E Test│
                  │  Unit Tst│                   │  Smoke T │
                  └──────────┘                   └──────────┘
```

#### Detailed Flow

1. **Trigger** — Developer pushes to a feature branch or creates a Pull Request
2. **Checkout** — Pipeline clones the repo, checks out the specific commit
3. **Pre-Build** — Linting (`eslint`, `checkstyle`), static analysis, dependency vulnerability scan
4. **Build** — Compile source code, run unit tests, package artifact (JAR/WAR/Docker image)
5. **Scan** — SAST (SonarQube), DAST (if applicable), Container scan (Trivy)
6. **Publish** — Push artifact to **Nexus/Artifactory** and container image to **ECR/ACR/GCR**
7. **Deploy to Dev** — Automated deployment to development Kubernetes cluster
8. **Integration Tests** — Run API/E2E tests against the deployed environment
9. **Deploy to Staging** — After dev tests pass, promote to staging
10. **Manual Approval** — QA sign-off for production (gated by environment protection rule)
11. **Deploy to Production** — Blue-green or canary deployment strategy
12. **Post-Deploy Verification** — Health checks, smoke tests, observability dashboards
13. **Monitoring** — Alerting via Prometheus/Grafana/PagerDuty for any degradation

#### Key Principles
- **Immutable artifacts**: Build once, promote the same artifact through all environments
- **Fast feedback**: Failures surface within 5–10 minutes
- **Idempotent deployments**: Re-running the pipeline produces the same result
- **Rollback capability**: Every deployment has a one-click rollback path

---

### 8️⃣ Explain the pre-build, build, and post-build stages in your CI/CD pipeline.

Each stage has a distinct responsibility and quality gate.

#### Pre-Build Stage (Validation & Analysis)

| Activity | Tool | Purpose |
|----------|------|---------|
| **Code Linting** | ESLint, Checkstyle, Pmd | Enforce code style, catch syntax errors before compilation |
| **SAST** | SonarQube, Checkmarx, Semgrep | Detect vulnerabilities in source code (SQLi, XSS, hardcoded secrets) |
| **Dependency Audit** | OWASP Dependency-Check, Snyk | Check for known CVEs in third-party libraries |
| **Secret Scanning** | GitLeaks, TruffleHog | Ensure no credentials leaked into source code |
| **IaC Scanning** | Checkov, Tfsec | Validate Terraform/Kubernetes manifests for misconfigurations |

#### Build Stage (Compile & Test)

| Activity | Tool | Purpose |
|----------|------|---------|
| **Dependency Resolution** | Maven (`mvn dependency:resolve`) | Download and verify all project dependencies |
| **Compilation** | Maven (`mvn compile`) / Gradle (`gradle build`) | Transform source code into bytecode/artifacts |
| **Unit Tests** | JUnit 5, TestNG | Validate individual components in isolation (target: 80%+ coverage) |
| **Integration Tests** | Testcontainers, Spock | Validate component interactions against real databases/APIs |
| **Packaging** | Maven (`mvn package`) | Produce JAR/WAR/Docker image artifact |

```xml
<!-- Maven surefire plugin for test execution -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>3.2.5</version>
    <configuration>
        <failIfNoTests>true</failIfNoTests>
        <argLine>-Xmx512m</argLine>
    </configuration>
</plugin>
```

#### Post-Build Stage (Publish & Deploy)

| Activity | Tool | Purpose |
|----------|------|---------|
| **Artifact Publishing** | `mvn deploy` → Artifactory | Store build artifact with version metadata |
| **Docker Image Build** | `docker buildx build` | Create container image from packaged artifact |
| **Image Scanning** | Trivy, Clair | Scan for OS-level and application-level CVEs |
| **Image Push** | `docker push` → ECR/ACR/GCR | Publish to container registry |
| **Update Helm/Manifest** | Helm chart version bump | Update image tag in deployment manifests |
| **Deploy** | Argo CD / Flux / `kubectl apply` | Deploy to target Kubernetes cluster |
| **Notification** | Slack, Email, Teams | Notify team of build success/failure with summary |

---

### 9️⃣ At which stage do you publish Maven artifacts (JAR/WAR) to Artifactory?

Maven artifacts are published in the **post-build stage**, immediately after a **successful build and test phase**.

#### Pipeline Position

```
Compile → Unit Tests → Package (JAR/WAR) → [✅ Tests pass] → Publish to Artifactory
                                                              ↓
                                                    Docker Build (uses JAR from Artifactory)
                                                              ↓
                                                    Push Docker Image
```

#### Why This Positioning?
- **Fail-fast**: If unit tests fail, the artifact is never published, saving registry space
- **Immutable artifact**: The same JAR built in CI is promoted through dev → staging → production
- **Decoupled Docker build**: The Docker build stage pulls the verified JAR from Artifactory rather than relying on local build outputs

#### Maven Publish Configuration

```xml
<!-- settings.xml or pipeline-injected properties -->
<distributionManagement>
    <repository>
        <id>releases</id>
        <url>https://artifactory.company.com/artifactory/maven-releases</url>
    </repository>
    <snapshotRepository>
        <id>snapshots</id>
        <url>https://artifactory.company.com/artifactory/maven-snapshots</url>
    </snapshotRepository>
</distributionManagement>
```

```bash
# In CI pipeline — post-build stage
mvn deploy -DskipTests \
    -DaltDeploymentRepository=releases::default::https://artifactory.company.com/artifactory/maven-releases \
    -Dbuild.number=$CI_BUILD_NUMBER
```

#### Versioning Strategy
- **SNAPSHOT** versions → deployed to `maven-snapshots` repo on every commit to feature branches
- **RELEASE** versions → deployed to `maven-releases` repo only on merge to `main` or tagged releases
- Use **Semantic Versioning** (`v1.2.3`) for all production releases

---

### 🔟 Apart from Jenkins and GitHub Actions, which other CI/CD tools have you worked with?

Beyond Jenkins and GitHub Actions, the DevOps ecosystem offers several CI/CD platforms, each with distinct strengths:

#### Tools Overview

| Tool | Key Strength | Typical Use Case |
|------|-------------|-----------------|
| **GitLab CI** | Native Git integration, single-platform DevSecOps | Organizations already on GitLab; `.gitlab-ci.yml` as code |
| **CircleCI** | Fast parallel execution, OCI image layer caching | High-throughput Java/Go builds needing speed |
| **Harness** | AI-powered CI/CD, strong release orchestration | Enterprise-grade deployment with policy governance |
| **Argo CD** | GitOps-native, declarative deployment | Kubernetes environments with GitOps workflow |
| **Tekton** | Cloud-native, Kubernetes-native pipelines | CNCF-aligned teams building custom CI on K8s |
| **Azure DevOps** | Microsoft ecosystem integration | Teams using Azure cloud + Visual Studio ecosystem |

#### GitLab CI Example

```yaml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

build:
  stage: build
  script:
    - mvn clean package -DskipTests
    - docker build -t $DOCKER_IMAGE .
  artifacts:
    paths:
      - target/*.jar

test:
  stage: test
  script:
    - mvn verify
    - trivy image --severity HIGH,CRITICAL $DOCKER_IMAGE

deploy-staging:
  stage: deploy
  script:
    - kubectl set image deployment/myapp myapp=$DOCKER_IMAGE
  environment:
    name: staging
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
```

#### Key Comparison Points
- **Jenkins**: Most customizable, plugin ecosystem, but requires maintenance of master agents
- **GitHub Actions**: Best developer experience for GitHub-native teams, marketplace actions
- **GitLab CI**: All-in-one (repo + CI/CD + container registry + security scanning)
- **Harness**: Strongest for enterprise governance with AI-driven release recommendations
- **CircleCI**: Best raw build speed with intelligent caching and parallelism

---

# ☸️ Kubernetes

---

### 1️⃣1️⃣ Explain Kubernetes Ingress and its architecture.

**Kubernetes Ingress** is a Kubernetes API object that manages **external HTTP/HTTPS access** to services within a cluster. It acts as a ** Layer 7 (application-layer) reverse proxy and load balancer** — routing incoming requests to the correct backend Service based on hostnames and URL paths.

#### Architecture

```
                    ┌─────────────────┐
                    │   Internet      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Ingress Resource │ ← Declarative YAML (rules, hosts, paths)
                    └────────┬────────┘
                             │ watches
                    ┌────────▼────────┐
              ┌─────┴────────┐       │
              │  Ingress      │◄──────┘
              │  Controller   │  (reconciles Ingress → ConfigMap/Proxy config)
              └─────┬────────┘
                    │ configures
           ┌────────▼────────┐
           │  Load Balancer   │  (Cloud LB / Nginx / Traefik process)
           │  (External IP)   │
           └────────┬────────┘
                    │ routes to
       ┌────────────┼────────────┐
       ▼            ▼            ▼
  ┌─────────┐  ┌─────────┐  ┌─────────┐
  │ Service  │  │ Service  │  │ Service  │
  │  /api    │  │  /web    │  │  /auth   │
  └─────────┘  └─────────┘  └─────────┘
```

#### Key Components
- **Ingress Resource**: YAML manifest defining routing rules (hosts, paths, TLS). It is a **declarative specification**, not an active component.
- **Ingress Controller**: The **actual workload** (deployment) that reads Ingress resources and configures a proxy (Nginx, Traefik, HAProxy, Envoy). It is the only component that handles real traffic.
- **Load Balancer Service**: A `type: LoadBalancer` Service exposing the Ingress Controller to the internet with a public IP.

#### Sample Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls-secret
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 80
```

---

### 1️⃣2️⃣ What is an Ingress Controller, and why is it required?

An **Ingress Controller** is a Kubernetes **Deployment** that runs a reverse proxy (Nginx, Traefik, HAProxy, or Envoy). It **watches** the Kubernetes API for Ingress resources and dynamically configures the proxy to route traffic according to the defined rules.

#### Why It Is Required

| Without Ingress Controller | With Ingress Controller |
|---------------------------|------------------------|
| Each Service needs its own LoadBalancer (costly, multiple IPs) | Single LoadBalancer handles all HTTP/HTTPS routing |
| No path-based or host-based routing | Advanced L7 routing (path, host, regex, headers) |
| No TLS termination at cluster edge | Centralized TLS termination with cert-manager |
| No rate limiting, WAF, or rewriting | Rich features: rate limiting, canary, rewrite, auth |

#### Popular Ingress Controllers

| Controller | Best For |
|-----------|---------|
| **NGINX Ingress** | Most widely adopted, mature, extensive annotation support |
| **Traefik** | Cloud-native, auto-discovery, great for microservices |
| **HAProxy Ingress** | High-performance, low-latency workloads |
| **Envoy (ISTIO/Gloo)** | Service mesh environments, advanced observability |

#### Deployment Example (NGINX Ingress via Helm)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.service.annotations.service.beta.kubernetes.io/aws-load-balancer-type=nlb
```

---

### 1️⃣3️⃣ How would you configure a single Ingress to route traffic to multiple applications?

A single Ingress resource can route to **multiple backends** using a combination of **host-based** and **path-based** rules.

#### Path-Based Routing (Single Host, Multiple Apps)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: myapp.company.com
      http:
        paths:
          - path: /api-v1
            pathType: Prefix
            backend:
              service:
                name: api-service
                port: { number: 8080 }
          - path: /web
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port: { number: 80 }
          - path: /auth(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: auth-service
                port: { number: 8443 }
```

#### Host-Based Routing (Multiple Hosts, Single Ingress)

```yaml
spec:
  rules:
    - host: api.company.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: { name: api-service, port: { number: 8080 } }
    - host: dashboard.company.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: { name: dashboard-service, port: { number: 3000 } }
```

#### Key Considerations
- Use **`pathType: Prefix`** for most cases, **`ImplementationSpecific`** for regex
- **Rewrite annotations** (`rewrite-target`) strip the path prefix before forwarding
- Each backend must be a **ClusterIP Service** (not LoadBalancer or NodePort)
- For complex routing needs (header-based, cookie-based), consider **Envoy Proxy** or **Istio VirtualService**

---

### 1️⃣4️⃣ Auto-scaling increased the number of Pods, but the application is still experiencing latency. How would you troubleshoot it?

This is a classic scenario where **horizontal scaling alone does not solve the bottleneck**. The issue may lie beyond Pod count.

#### Systematic Troubleshooting Approach

**Step 1 — Verify Pod Health**
```bash
# Are new Pods actually Ready?
kubectl get pods -l app=myapp -o wide

# Check for CrashLoopBackOff or pending Pods
kubectl describe pod <pod-name>

# Check events for resource pressure
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

**Step 2 — Check Resource Constraints**
```bash
# Are Pods CPU-throttled?
kubectl top pods -l app=myapp

# Check if requests/limits are too low
kubectl describe deployment myapp | grep -A5 resources
```
If CPU throttling is high, increase `resources.requests` and `resources.limits`. HPA scales on CPU percentage — if limits are `100m`, Pods hit 100% quickly and throttle.

**Step 3 — Examine Application Logs**
```bash
kubectl logs -l app=myapp --tail=100 --previous
```
Look for: slow database queries, external API timeouts, thread pool exhaustion, GC pauses.

**Step 4 — Database / External Dependencies**
- **Connection pool exhaustion**: More pods = more connections. Check if the database has hit `max_connections`.
- **Slow queries**: Use query profiling. A single unindexed query doesn't get faster with more pods.
- **Throttled external APIs**: Third-party rate limits (e.g., AWS SQS, Stripe API) don't scale with pod count.

**Step 5 — Network & Service Mesh**
```bash
# Check Service endpoints — are all Pods registered?
kubectl get endpoints myapp-service

# Check for NetworkPolicy blocking inter-Pod communication
kubectl get networkpolicy -A

# If using Istio/Linkerd, check sidecar proxy latency
istioctl proxy-config cluster <pod> | head -20
```

**Step 6 — Check Ingress / Load Balancer**
- Is the **Load Balancer** itself saturated (connection limit, CPU)?
- Are **Ingress rate limits** kicking in (HTTP 429 responses)?

**Step 7 — Application-Level Bottlenecks**
- **Synchronous blocking calls**: A blocking database call per request won't benefit from more pods if the DB is the bottleneck
- **Lock contention**: Distributed locks or single-writer patterns serialize requests
- **Memory/GC**: Check JVM GC logs for Stop-the-World pauses

#### Root Cause Summary

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Pods Ready but slow | DB bottleneck | Add indexes, connection pooling, read replicas |
| CPU at 100% on all pods | Limits too low | Increase CPU limits, optimize code |
| Connection refused errors | Max DB connections | Increase pool size, use PgBouncer |
| High network latency | Cross-AZ traffic | Pod affinity to same AZ, optimize LB |
| HTTP 429 responses | Rate limiting at LB | Increase rate limit, add request queuing |

---

### 1️⃣5️⃣ Explain Readiness Probe and Liveness Probe with practical use cases.

Probes are Kubernetes' mechanism for **health checking** containers. They determine whether a Pod should receive traffic (Readiness) or be restarted (Liveness).

#### Readiness Probe — "Are you ready to serve traffic?"

- **Purpose**: Determines if a Pod should be added to Service endpoints
- **Failure action**: Pod is **removed from load balancer** but NOT restarted
- **Use case**: Application needs time to initialize (load config, warm caches, connect to DB)

```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10    # Wait 10s before first check
  periodSeconds: 5           # Check every 5s
  failureThreshold: 3        # 3 failures = mark NotReady
  successThreshold: 1
```

**Real-world scenario**: A Java Spring Boot app takes 30 seconds to start (loading Hibernate mappings, building connection pool). Without a readiness probe, the Service sends traffic immediately, and users get 503 errors. With the probe, the Pod stays out of the endpoint list until `/health/ready` returns HTTP 200.

#### Liveness Probe — "Are you alive or stuck?"

- **Purpose**: Determines if a container should be **restarted**
- **Failure action**: Container is **killed and restarted** by kubelet
- **Use case**: Application enters a **deadlock**, thread pool exhaustion, or memory leak

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30    # Wait for full startup
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 5
```

**Real-world scenario**: A Node.js app has a bug where after processing 10,000 requests, the event loop blocks. The container doesn't crash, but it stops responding. The liveness probe detects HTTP timeouts after 30 seconds and restarts the container automatically — avoiding manual intervention.

#### StartUp Probe — "Are you still starting?"

```yaml
startupProbe:
  httpGet:
    path: /health/live
    port: 8080
  failureThreshold: 30
  periodSeconds: 10          # Allows up to 300s for startup
```

Prevents liveness probe from killing a slowly starting container. Recommended for **slow-starting Java apps**.

#### Probe Comparison

| Aspect | Readiness | Liveness | StartUp |
|--------|-----------|----------|---------|
| **Checks** | Can serve traffic? | Is it alive? | Is it still booting? |
| **On failure** | Remove from Service | Restart container | Treat as not alive |
| **Typical endpoint** | `/health/ready` | `/health/live` | Same as liveness |
| **When to use** | Always | For apps that can deadlock | For slow-starting apps |

---

# 🚀 Deployment Strategies

---

### 1️⃣6️⃣ Explain Canary Deployment with a real-world example.

**Canary Deployment** is a release strategy where a new version is rolled out to a **small subset of users** first. If metrics look healthy, the rollout gradually expands to 100%. If issues are detected, the rollout is automatically or manually rolled back.

#### Real-World Example — E-Commerce Checkout Service

**Scenario**: Your team deployed v2.0 of the checkout service. Instead of cutting all 50,000 hourly users to v2.0 at once, you use canary:

| Phase | v1.9 (stable) | v2.0 (canary) | Duration | Criteria to Proceed |
|-------|--------------|---------------|----------|-------------------|
| **1** | 95% | 5% | 15 min | Error rate < 0.1%, P99 latency < 500ms |
| **2** | 80% | 20% | 30 min | No increase in failed payments |
| **3** | 50% | 50% | 30 min | Transaction success rate matches v1.9 |
| **4** | 0% | 100% | — | All metrics green, manual sign-off |

#### Implementation with Kubernetes + Istio

```yaml
# VirtualService — route 5% to canary
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: checkout-vs
spec:
  hosts:
    - checkout-service
  http:
    - route:
        - destination:
            host: checkout-service-v19   # stable
          weight: 95
        - destination:
            host: checkout-service-v20   # canary
          weight: 5
```

#### Implementation with Argo Rollouts

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: checkout-rollout
spec:
  replicas: 10
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: { duration: 15m }
        - setWeight: 25
        - pause: { duration: 30m }
        - setWeight: 50
        - pause: { duration: 30m }
        - setWeight: 100
      analysis:
        templates:
          - templateName: checkout-analysis
        startingStep: 1
  analysis:
    metrics:
      - name: error-rate
        interval: 1m
        successCondition: result[0] < 0.01
        provider:
          prometheus:
            query: sum(rate(http_requests_total{status=~"5.."}[5m]))
```

#### Automated Rollback
If the Prometheus analysis detects error rate > 1%, Argo Rollouts **automatically pauses** the rollout and can be configured to **abort** (revert to stable version) without human intervention.

#### When to Choose Canary
- **High-risk changes** (payment processing, authentication, data migration)
- **User-facing services** where downtime causes revenue loss
- **A/B testing** scenarios where you need to compare metrics between versions

---

### 1️⃣7️⃣ What is Blue-Green Deployment, and when would you choose it?

**Blue-Green Deployment** maintains **two identical production environments**. One (Blue) serves live traffic while the other (Green) receives the new deployment. Once Green is verified, traffic is **instantly switched** from Blue to Green with a single routing change.

#### Architecture

```
Phase 1:                    Phase 2:                    Phase 3:
┌──────────────┐           ┌──────────────┐           ┌──────────────┐
│  BLUE (Live)  │──traffic  │  GREEN (Idle) │──deploy v2 │  GREEN (Live) │──traffic
│  Running v1   │           │  Deploying v2 │           │  Running v2   │
└──────────────┘           └──────────────┘           └──────────────┘
                                                                    │
                                                            ┌──────▼──────┐
                                                            │ BLUE (Idle) │
                                                            │ (rollback)  │
                                                            └─────────────┘
```

#### Kubernetes Implementation

```yaml
# Blue deployment (current live)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  template:
    spec:
      containers:
        - name: myapp
          image: myapp:v1.9

# Green deployment (new version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  template:
    spec:
      containers:
        - name: myapp
          image: myapp:v2.0

# Service — switch selector for instant cutover
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    version: green    # Change from "blue" to "green" for cutover
  ports:
    - port: 80
      targetPort: 8080
```

#### When to Choose Blue-Green Over Canary

| Factor | Blue-Green | Canary |
|--------|-----------|--------|
| **Downtime** | Zero (instant switch) | Near-zero (gradual) |
| **Rollback speed** | Instant (switch selector back) | Fast (reduce canary weight to 0) |
| **Resource cost** | 2× (two full environments) | 1.1–1.5× (small canary subset) |
| **Risk level** | All-or-nothing cutover | Gradual exposure |
| **Best for** | Full platform upgrades, database migrations, infrastructure changes | Feature-level changes, iterative rollouts |
| **Testing** | Full environment tested before cutover | Tested in production with real traffic |

#### Decision Guide
- Choose **Blue-Green** when: The change is risky, you need instant rollback, and resource cost is acceptable (e.g., platform migration, framework upgrade)
- Choose **Canary** when: You want to validate with real production traffic gradually, resources are constrained, or you need A/B metrics

---

# 🖥️ Cloud Troubleshooting

---

### 1️⃣8️⃣ Your EC2 instance is running, but you cannot access it. How would you troubleshoot the issue?

This is a layered troubleshooting exercise. Work from the **network edge inward**.

#### Step-by-Step Troubleshooting

**Step 1 — Verify Instance State**
```bash
# Is the instance actually running and passed status checks?
aws ec2 describe-instances --instance-id i-0abcd1234 \
  --query 'Reservations[*].Instances[*].{State:State.Name,Status:StateTransitionReason,Checks:Monitoring.State}'

# Check system and instance status checks
aws ec2 describe-instance-status --instance-id i-0abcd1234
```
- **System status check failed**: Hardware issue. Stop and start the instance (moves to new host).
- **Instance status check failed**: OS/kernel/crash issue. Check serial console.

**Step 2 — Security Group & NACL**
```bash
# Security Groups
aws ec2 describe-security-groups --group-ids sg-0abcd1234

# Check NACLs on the subnet
aws ec2 describe-network-acls --acl-id acl-0abcd1234
```
- Ensure **inbound rule** allows SSH (port 22) or HTTP/HTTPS from your IP
- Verify **outbound rule** allows all traffic (default)
- Check **NACLs** — they are stateless and must allow both inbound and outbound

**Step 3 — Network Reachability**
```bash
# Is the instance in a public subnet with an Internet Gateway?
aws ec2 describe-instances --instance-id i-0abcd1234 \
  --query 'Reservations[*].Instances[*].{Subnet:SubnetId,VPC:VpcId,IP:PrivateIpAddress,PublicIP:PublicIpAddress}'

# Check route table
aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-0abcd
```
- **No public IP / Elastic IP**: Instance is not directly reachable from internet
- **No Internet Gateway route**: `0.0.0.0/0 → igw-xxxx` missing from route table
- **Private subnet**: Need a **Bastion host** or **SSH via SSM Session Manager**

**Step 4 — EC2 Serial Console**
If SSH is completely unreachable, use the **EC2 Serial Console** (no network required, works at the serial port level):
```bash
aws ec2 get-console-output --instance-id i-0abcd1234 --latest
```

**Step 5 — OS-Level Checks** (if you can reach via Serial Console / SSM)
```bash
# Is SSH service running?
sudo systemctl status sshd

# Is firewalld/iptables blocking?
sudo iptables -L -n
sudo ufw status

# Check /etc/ssh/sshd_config
grep -E "^Port|^PermitRootLogin|^PasswordAuthentication" /etc/ssh/sshd_config

# Disk full?
df -h

# High load?
top -bn1 | head -20
```

**Step 6 — DNS & Hostname Resolution**
```bash
# Is the DNS name resolving correctly?
nslookup ec2-xx-xx-xx-xx.compute-1.amazonaws.com

# Check /etc/resolv.conf on the instance
cat /etc/resolv.conf
```

#### Troubleshooting Checklist

| Layer | Check | Common Fix |
|-------|-------|-----------|
| **Instance** | Status checks, state | Stop/start, reboot |
| **Security Group** | Inbound rules | Add SSH/HTTP rule for your IP |
| **NACL** | Inbound + outbound | Allow ephemeral ports for return traffic |
| **Route Table** | IGW route | Add `0.0.0.0/0 → igw-xxx` |
| **Subnet** | Public vs private | Assign Elastic IP, move to public subnet |
| **OS Firewall** | iptables, ufw | `sudo ufw allow 22` |
| **SSH Config** | Port, auth method | Use key-based auth, verify port |
| **Disk** | Full root partition | Clean logs, expand EBS volume |

---

# 🔄 GitOps & Argo CD

---

### 1️⃣9️⃣ Explain how Argo CD continuously reconciles Git changes with the Kubernetes cluster.

Argo CD implements the **GitOps** paradigm: **Git is the single source of truth** for desired application state. Argo CD runs inside the Kubernetes cluster as a **continuous reconciliation controller**.

#### Reconciliation Loop

```
  ┌──────────────────────────────────────────────────────┐
  │                    Argo CD Controller                 │
  │                                                      │
  │  1. Watch Git repository (polling / webhook)         │
  │     ↓                                                │
  │  2. Fetch latest manifests from target branch         │
  │     ↓                                                │
  │  3. Compare with current cluster state               │
  │     ↓                                                │
  │  4. If drift detected → Calculate diff               │
  │     ↓                                                │
  │  5. Apply changes to cluster (kubectl apply equivalent)│
  │     ↓                                                │
  │  6. Repeat every 3 minutes (default sync period)     │
  └──────────────────────────────────────────────────────┘
         ▲                               │
         │ reconciles                    │ applies
         │                               ▼
  ┌──────┴──────┐              ┌────────────────┐
  │  Git Repo   │              │  K8s Cluster   │
  │ (Source of  │              │ (Live State)   │
  │   Truth)    │              └────────────────┘
  └─────────────┘
```

#### Key Mechanisms

| Component | Responsibility |
|-----------|---------------|
| **Application CRD** | Declarative definition of what to deploy (repo URL, path, target namespace, sync policy) |
| **Repo Server** | Clones and serves Git repositories to the controller |
| **Application Controller** | Core reconciliation loop — compares Git state vs. cluster state |
| **API Server** | REST/gRPC API for UI and CLI |
| **Notifications** | Webhook/email/slack alerts on sync status changes |

#### Application Manifest

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/k8s-manifests.git
    targetRevision: main
    path: apps/myapp
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true        # Delete resources removed from Git
      selfHeal: true     # Revert manual cluster changes back to Git
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
```

#### Self-Healing in Action
If an operator manually runs `kubectl scale deployment/myapp --replicas=5` in the cluster, but Git says `replicas: 3`, Argo CD detects the **drift** on the next reconciliation cycle and **automatically reverts** the replicas back to 3 — enforcing Git as the source of truth.

---

### 2️⃣0️⃣ If a developer modifies the GitOps repository, how does Argo CD handle the change? How would you secure the repository from unauthorized modifications?

#### How Argo CD Handles Git Changes

When a developer pushes a commit to the GitOps repository:

1. **Webhook Trigger** (instant) — GitHub/GitLab sends a webhook to Argo CD's API server
2. **Polling Fallback** — If no webhook, Argo CD polls every 3 minutes (configurable via `--app-refresh-timeout`)
3. **Diff Calculation** — Argo CD fetches the latest manifests and compares against the live cluster state
4. **Status Update** — Application status changes to **`OutOfSync`** in the UI and API
5. **Auto-Sync** (if configured) — If `syncPolicy.automated` is enabled, Argo CD immediately applies the changes
6. **Manual Sync** — If auto-sync is disabled, a human must approve via UI or CLI: `argocd app sync myapp`

#### Security Measures

| Control | Implementation |
|---------|---------------|
| **Branch Protection** | Require PR + approval for `main` branch. No direct pushes. |
| **Repository Access** | Restrict write access to senior DevOps engineers via GitHub team permissions |
| **Signed Commits** | Require GPG-signed commits. GitHub enforces `commit.gpgsign = true` |
| **Argo CD RBAC** | Restrict who can trigger sync, who can modify Applications |
| **Argo CD Projects** | Namespace-level isolation with resource/cluster whitelist |
| **Audit Logging** | Enable Argo CD audit logs to track who synced what and when |
| **Read-Only Deploy Keys** | Argo CD uses SSH deploy keys (read-only) to clone repos, never push |
| **CI Gate** | Require CI pipeline (lint, test, policy check) to pass before PR merge |

#### Argo CD RBAC Configuration

```yaml
# argocd-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default_role: role:readonly
  policy.csv: |
    p, role:devops-admin, applications, *, *, allow
    p, role:developer, applications, get, apps/*, allow
    p, role:developer, applications, sync, apps/*, deny
    g, github:org:devops-team, role:devops-admin
    g, github:org:dev-team, role:developer
```

#### Argo CD Project with Resource Whitelist

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
  namespace: argocd
spec:
  clusterWhitelist:
    - https://kubernetes.default.svc
  namespaceWhitelist:
    - production
    - staging
  sourceRepos:
    - https://github.com/org/k8s-manifests.git
  description: "Production environment — restricted to approved resources"
  orphanedResources:
    warn: true
```

---

# 🌿 Git & Version Control

---

### 2️⃣1️⃣ Git Merge vs Git Rebase. How do you resolve merge conflicts?

#### Git Merge

- **Creates a merge commit** that ties together two branches
- **Preserves full history** — every commit and branch point is visible
- **Non-destructive** — original commits are never rewritten
- **Recommended for shared branches** (`main`, `release`)

```
Before merge:                    After merge:
   A---B---C (feature)            A---B---C (feature)
  /                              /         \
D---E (main)                   D---E-----M (main)
                                    \     /
                                     merge
```

```bash
git checkout main
git merge feature-branch
# Creates merge commit M with two parents
```

#### Git Rebase

- **Replays** commits from the feature branch onto the target branch
- **Linear, clean history** — no merge commits cluttering the log
- **Rewrites history** — commit hashes change (DANGEROUS on shared branches)
- **Recommended for local/feature branches** before PR

```
Before rebase:                   After rebase:
   A---B---C (feature)            A'--B'--C' (feature)
  /                              /
D---E (main)                   D---E (main)
```

```bash
git checkout feature-branch
git rebase main
# Replays A, B, C on top of E — new hashes A', B', C'
```

#### Merge vs Rebase Decision Matrix

| Factor | Merge | Rebase |
|--------|-------|--------|
| History | Complete, branched | Clean, linear |
| Safety | Safe for shared branches | Never on pushed/shared branches |
| Debugging | Easy (full graph preserved) | Harder (rewritten hashes) |
| Team workflow | Preferred for `main` integration | Preferred for local cleanup |
| Bisect-friendly | Yes | Caution — history rewritten |

#### Resolving Merge Conflicts

**Step 1 — Identify conflicts**
```bash
git merge feature-branch
# Auto merge fails with:
# CONFLICT (content): Merge conflict in src/main/java/com/App.java
# Automatic merge failed; fix conflicts and then commit the result.
```

**Step 2 — Find conflicting files**
```bash
git status
# Both modified:   src/main/java/com/App.java
# Both modified:   pom.xml
```

**Step 3 — Resolve in editor** — Git inserts markers:
```java
<<<<<<< HEAD
    private int maxRetries = 3;
=======
    private int maxRetries = 5;
>>>>>>> feature-branch
```

**Step 4 — Choose, edit, or combine** — Pick the correct version or merge both:
```java
    private int maxRetries = 5;  // Accepted feature-branch value
```

**Step 5 — Mark resolved and complete**
```bash
git add src/main/java/com/App.java pom.xml
git commit -m "Merge feature-branch: resolve retry config conflict"

# For rebase:
git rebase --continue
```

**Step 6 — Abort if needed**
```bash
git merge --abort    # Cancel merge, return to pre-merge state
git rebase --abort   # Cancel rebase, return to pre-rebase state
```

#### Pro Tips
- Use **`git mergetool`** (vimdiff, meld, kdiff3) for visual conflict resolution
- **`git rerere`** (Reuse Recorded Resolution) — remembers how you resolved a conflict and auto-applies it if the same conflict recurs
- For rebase conflicts: **`git rebase --skip`** (discard current commit) or **`git rebase --edit`** (amend the commit)

---

# 🔒 Preventing Manual Infrastructure Changes

---

### 2️⃣2️⃣ If someone manually changes infrastructure in the cloud that is managed by Terraform, how would you prevent such changes from happening again?

Preventing manual changes requires a combination of **policy enforcement**, **access control**, and **continuous monitoring**.

#### Layer 1 — IAM & Permission Boundaries

```json
// SCP (Service Control Policy) — deny direct EC2 modifications
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:ModifyInstanceAttribute",
        "s3:CreateBucket",
        "rds:CreateDBInstance"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

- **Remove direct console access** for production accounts — use break-glass procedure with audit trail
- **IAM roles for CI/CD**: Only the Terraform pipeline service account has infrastructure modification permissions

#### Layer 2 — CloudWatch Event Rules (Detection & Alerting)

```json
// Detect any EC2 instance creation outside Terraform
{
  "Source": ["aws.ec2"],
  "Detail-type": "AWS API Call via CloudTrail",
  "Detail": {
    "eventSource": ["ec2.amazonaws.com"],
    "eventName": ["RunInstances", "TerminateInstances"]
  }
}
```
Trigger: Lambda → Slack/PagerDuty alert: "Unauthorized EC2 modification detected by user X"

#### Layer 3 — Terraform Import & Reconciliation

```bash
# After discovering manual changes:
terraform import aws_instance.manual-server i-0abc123def456
# This imports the manually created resource into Terraform state
# Then write the corresponding .tf configuration to match
# Next terraform plan should show no drift
```

#### Layer 4 — Sentinel / OPA Policies

```rego
# OPA/Conftest policy — deny EC2 instances without Terraform tags
package terraform.ec2

deny[msg] {
  resource = input.resource_changes[_]
  resource.type == "aws_instance"
  "terraform-managed" != resource.after.tags["ManagedBy"]
  msg = sprintf("EC2 instance must have tag ManagedBy=terraform-managed: %v", [resource.address])
}
```

#### Layer 5 — Cultural & Process Controls
- **Documented break-glass procedure**: Emergency changes go through a runbook, are logged, and must be codified in Terraform within 24 hours
- **Regular drift audits**: Weekly `terraform plan` across all environments with Slack notifications
- **Training**: Onboard engineers on IaC principles — "if it's not in Terraform, it doesn't exist"

---

# 🔐 Security (SAST / DAST)

---

### 2️⃣3️⃣ What is SAST? How do you integrate SAST into your CI/CD pipeline?

**SAST (Static Application Security Testing)** analyzes **source code** (or compiled bytecode) for security vulnerabilities **without executing** the application. It is a **white-box** technique — the scanner has full access to the codebase.

#### What SAST Detects

| Vulnerability Type | Example | OWASP Category |
|-------------------|---------|---------------|
| **SQL Injection** | String concatenation in SQL queries | A03:2021 |
| **XSS** | Unescaped user input in HTML output | A03:2021 |
| **Hardcoded Secrets** | API keys, passwords in source code | A07:2021 |
| **Insecure Deserialization** | Unsafe `ObjectInputStream.readObject()` | A08:2021 |
| **Path Traversal** | `../` in file paths without validation | A01:2021 |
| **CSPRNG weakness** | Using `Random` instead of `SecureRandom` | A02:2021 |

#### Popular SAST Tools

| Tool | License | Language Support |
|------|---------|-----------------|
| **SonarQube** | Community (free) / Enterprise | 30+ languages |
| **Checkmarx** | Commercial | 40+ languages |
| **Semgrep** | Open source | 20+ languages |
| **Fortify (OpenText)** | Commercial | 45+ languages |
| **CodeQL (GitHub)** | Free with GitHub Advanced Security | 10+ languages |

#### Integration into CI/CD Pipeline (SonarQube Example)

```yaml
# GitHub Actions — SAST gate
- name: SonarQube Scan
  uses: sonarsource/sonarqube-scan-action@v2
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
  with:
    projectBaseDir: .
    args: >
      -Dsonar.projectKey=myapp
      -Dsonar.sources=src/
      -Dsonar.java.binaries=target/classes
      -Dsonar.qualitygate.wait=true

# The quality gate blocks the pipeline if:
# - New security vulnerabilities > 0
# - Coverage drops below 80%
# - Duplicate code > 3%
```

#### Integration into CI/CD Pipeline (Semgrep Example)

```yaml
- name: Semgrep SAST Scan
  uses: returntocorp/semgrep-action@v1
  with:
    config: >-
      p/default
      p/secrets
      p/owasp-top-ten
  env:
    SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

#### Semgrep Custom Rule Example

```yaml
# .semgrep/rules/no-hardcoded-aws-key.yml
rules:
  - id: no-hardcoded-aws-access-key
    patterns:
      - pattern-regex: 'AKIA[0-9A-Z]{16}'
    message: "Possible hardcoded AWS Access Key ID found"
    severity: ERROR
    languages: [java, python, javascript, yaml]
```

#### Pipeline Gate Strategy
- **Block on CRITICAL/HIGH** severity findings — pipeline fails, PR cannot merge
- **Warn on MEDIUM/LOW** — pipeline passes but findings are reported to Jira/Slack
- **Trend tracking** — track vulnerability count over time, aim for reduction each sprint

---

### 2️⃣4️⃣ How do you integrate DAST into your deployment process?

**DAST (Dynamic Application Security Testing)** analyzes a **running application** for security vulnerabilities by sending malicious requests and analyzing responses. It is a **black-box** technique — no source code access needed.

#### DAST vs SAST

| Aspect | SAST | DAST |
|--------|------|------|
| **Input** | Source code | Running application (URL) |
| **Timing** | Shift-left (build time) | Post-deployment (runtime) |
| **Blind spots** | Runtime config, infrastructure | Logic bugs, code-level issues |
| **False positives** | Higher (context-limited) | Lower (real behavior observed) |
| **Best for** | Developer feedback | Pre-production validation |

#### DAST Integration Strategy

```
Deploy to Staging → Health Check → DAST Scan → Gate → Promote to Prod
```

#### OWASP ZAP Integration (Open Source)

```yaml
# GitHub Actions — DAST scan after staging deployment
- name: Deploy to Staging
  run: kubectl apply -f k8s/staging/

- name: Wait for application health
  run: |
    for i in {1..30}; do
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://staging.myapp.com/health)
      if [ "$HTTP_CODE" = "200" ]; then
        echo "Application is healthy"
        break
      fi
      sleep 10
    done

- name: DAST Scan with OWASP ZAP
  uses: zaproxy/action-full-scan@v0.9.0
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    target: 'https://staging.myapp.com/'
    rules_file_name: '.zap/rules.tsv'
    cmd_options: '-a'
    artifact_name: 'ZAP-Report'
    fail_action: true
    allow_issue_writing: false

# Pipeline fails if DAST finds HIGH/CRITICAL vulnerabilities
```

#### Commercial DAST Tools
- **Burp Suite Professional** — Most popular for manual + automated web app testing
- **Acunetix** — Fast scanning, large vulnerability database
- **Qualys WAS** — Cloud-based, enterprise compliance reporting
- **Veracode** — Combined SAST + DAST platform

#### DAST Scan Configuration

```yaml
# .zap/rules.tsv — custom severity rules
# Format: ruleId\talertThreshold\tseverity\tenabled
40012\tMEDIUM\t3\ttrue    # SQL Injection
2\tMEDIUM\t3\ttrue        # Path Traversal
90022\tMEDIUM\t2\ttrue    # Cookie without Secure flag
```

#### Best Practices
- **Run DAST against staging**, never directly against production
- **Authenticate the scanner**: Use ZAP's authentication add-on to scan behind login
- **Baseline & exclusions**: Exclude known safe findings (e.g., third-party scripts, CDN assets)
- **Schedule regularly**: In addition to pipeline gates, run weekly DAST scans for regression detection
- **Combine with IAST**: Tools like **Contrast Security** or **Deepfence** provide in-app security monitoring with lower false positive rates

---

# 🤖 AI Tools

---

### 2️⃣5️⃣ Have you used AI developer tools such as OpenAI Codex, GitHub Copilot, or similar tools? How do they improve your DevOps workflow?

Yes, AI developer tools have become a significant productivity multiplier across the DevOps lifecycle. Here is a practical assessment:

#### Tools Used

| Tool | Primary Use in DevOps | Impact |
|------|----------------------|--------|
| **GitHub Copilot** | Auto-complete for Terraform, Helm, Kubernetes YAML, Shell scripts | 30–40% faster boilerplate generation |
| **Amazon Q Developer** | CloudFormation/YAML generation, AWS SDK code, inline documentation | Reduces AWS API learning curve for new services |
| **JetBrains AI Assistant** | IntelliJ-based IDE assistance for Java/Kotlin CI pipeline code | Context-aware suggestions within IDE |
| **Cursor / Continue.dev** | Chat-based code generation with full repo context | Rapid Terraform module creation, debugging |
| **OpenAI Codex (legacy)** | Early experimentation with shell script generation | Superseded by GPT-4-powered Copilot |

#### Specific DevOps Workflow Improvements

**1. Infrastructure as Code Generation**
```
Prompt: "Create a Terraform module for an ALB with WAF, targeting 2 AZs in us-east-1"

Output: Complete module with aws_lb, aws_lb_target_group, 
        aws_lb_listener, aws_wafv2_web_acl, and outputs — 
        saving 30+ minutes of manual lookup and typing
```

**2. Kubernetes Manifest Generation**
```
Prompt: "Generate a Kubernetes Deployment with HPA, PDB, 
        resource limits, readiness/liveness probes, and 
        pod anti-affinity for a Java microservice"

Output: Production-ready YAML with all best practices included
```

**3. Shell Script & CI/CD Pipeline Authoring**
- Auto-generate complex **bash scripts** for log parsing, data migration, backup automation
- Generate **Jenkinsfile** or **GitHub Actions** YAML from natural language description
- Debug failed pipeline scripts by pasting error output and getting targeted fixes

**4. Log Analysis & Troubleshooting**
- Paste stack traces or log snippets → AI identifies root cause, suggests fixes
- Convert verbose Kubernetes `describe pod` output into a structured summary
- Generate **Prometheus/Grafana queries** for custom dashboards

**5. Documentation & Runbooks**
- Generate **incident runbooks** from existing Terraform/Kubernetes manifests
- Create **onboarding documentation** from infrastructure code
- Summarize complex architecture decisions from PR descriptions

#### Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| **Hallucinated configurations** (AI generates incorrect API or invalid YAML) | Always validate: `terraform validate`, `kubeval`, `kubectl apply --dry-run=client` |
| **Security vulnerabilities** (AI suggests insecure defaults) | Run through SAST/IaC scan (Checkov, Tfsec) before merging |
| **Proprietary code leakage** | Use enterprise Copilot/Q with data retention controls disabled |
| **Over-reliance** (team loses deep understanding) | Treat AI as a **pair programmer**, not a replacement — review and understand every generated artifact |
| **Licensing compliance** | Verify generated code doesn't conflict with open-source licenses |

#### Measurable Impact
- **Faster onboarding**: New team members can query AI for "how do we deploy X" instead of searching through documentation
- **Reduced boilerplate**: Standardized patterns (Deployment, Service, Ingress, HPA) generated consistently
- **Faster debugging**: 2–3 minute AI-assisted root cause analysis vs. 15–30 minutes of manual log digging
- **Knowledge transfer**: AI bridges gaps when team members are unavailable — generates explanations of existing infrastructure code

---

> _End of L2 Round Q&A — 25 Questions with Production-Grade Answers_
