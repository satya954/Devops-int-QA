# 🏗️ Siemens DevOps Engineer Interview Q&A

> **Role:** DevOps Engineer (5+ years experience) | **Platform:** Azure Cloud & GitHub/Azure DevOps Ecosystem
>
> *Comprehensive guide covering CI/CD pipelines, security, Terraform, deployment strategies, and operational excellence.*

---

## 📋 Table of Contents

| # | Category | Question |
|---|----------|----------|
| 1 | **CI/CD & Pipelines** | Walk through a YAML pipeline for deploying Terraform or a Function App |
| 2 | **CI/CD & Pipelines** | Azure DevOps Pipelines vs. GitHub Actions — pros and cons |
| 3 | **CI/CD & Pipelines** | Branching strategy and triggering pipelines on specific branch/path changes |
| 4 | **CI/CD & Pipelines** | Setting up self-hosted agents/runners and when to use them |
| 5 | **Security & Secrets** | Managing secrets in pipelines (Key Vault, Variable Groups, GitHub Secrets/OIDC) |
| 6 | **Security & Secrets** | OIDC / Workload Identity Federation setup with Azure |
| 7 | **Security & Secrets** | Enforcing code quality and security scanning in pipelines |
| 8 | **Terraform & IaC** | Terraform plan/apply pipeline with manual approval |
| 9 | **Terraform & IaC** | Managing remote state and state locking in CI/CD |
| 10 | **Terraform & IaC** | Detecting and handling infrastructure drift |
| 11 | **Deployment & Governance** | Approval gates and environments for production |
| 12 | **Deployment & Governance** | Rolling back a failed deployment |
| 13 | **Deployment & Governance** | Multi-environment pipelines with promotion |
| 14 | **Bonus** | Alerts and notifications for pipeline failures |
| 15 | **Bonus** | Blue-green and canary deployment strategies in Azure |

---

## 🔹 CI/CD & Pipelines

### 1️⃣ Walk through a YAML pipeline you've built for deploying Terraform code or a Function App

I typically build a **multi-stage pipeline** that follows a **plan → validate → approve → apply** lifecycle for Terraform, or a **build → test → deploy → verify** flow for Azure Function Apps. Here is how a production-grade Terraform pipeline looks:

**Pipeline Structure:**

The pipeline is divided into stages — **Validate**, **Plan**, and **Apply** — each running in separate Azure DevOps stages (or GitHub Actions jobs). The **Validate** stage runs `terraform fmt -check` and `terraform validate` to catch syntax errors early. The **Plan** stage runs `terraform plan` and uploads the output as an artifact so stakeholders can review it. The **Apply** stage is gated behind a **manual approval** and consumes the saved plan file to ensure idempotency.

```yaml
# azure-pipelines.yml — Terraform CI/CD Pipeline
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - terraform/**

stages:
  - stage: Validate
    jobs:
      - job: TerraformValidate
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: 'latest'
          - script: terraform init -backend-config=backend.hcl
            displayName: 'Terraform Init'
          - script: terraform fmt -check -recursive
            displayName: 'Terraform Format Check'
          - script: terraform validate
            displayName: 'Terraform Validate'

  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: TerraformPlan
        pool:
          vmImage: 'ubuntu-latest'
        variables:
          - group: Terraform-KeyVault-Vars
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: 'latest'
          - script: terraform init -backend-config=backend.hcl
            displayName: 'Terraform Init'
          - script: |
              terraform plan -var-file=env/prod.tfvars \
                -out=tfplan.out
            displayName: 'Terraform Plan'
          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: '$(System.DefaultWorkingDirectory)/tfplan.out'
              artifactName: 'tfplan'

  - stage: Apply
    dependsOn: Plan
    condition: succeeded()
    jobs:
      - deployment: TerraformApply
        environment: production
        strategy:
          runOnce:
            deploy:
              steps:
                - task: DownloadBuildArtifacts@0
                  inputs:
                    artifactName: 'tfplan'
                - script: |
                    terraform init -backend-config=backend.hcl
                    terraform apply -auto-approve tfplan.out
                  displayName: 'Terraform Apply'
```

For an **Azure Function App**, the pipeline uses the `AzureFunctionApp@1` deployment task, runs unit tests in a `Build` stage, publishes a ZIP artifact, and deploys to the target slot. The key difference is the inclusion of a **smoke-test verification** step post-deployment to confirm health endpoints respond correctly.

**Key design decisions:**
- **`terraform plan -out`** serializes the plan so the Apply stage executes exactly what was reviewed, preventing drift between plan and apply.
- **Secrets** are injected via Azure DevOps **Variable Groups** linked to **Azure Key Vault**, so no credentials appear in YAML.
- The **Apply stage** maps to an Azure DevOps **Environment** (`production`), which enables built-in approval gates and deployment history tracking.

---

### 2️⃣ Difference between Azure DevOps Pipelines and GitHub Actions — pros and cons of each

Both platforms are mature CI/CD solutions, but they differ in **ecosystem integration**, **extensibility**, and **organizational fit**.

| Aspect | Azure DevOps Pipelines | GitHub Actions |
|--------|----------------------|----------------|
| **YAML Syntax** | `azure-pipelines.yml` — stages → jobs → steps | `.github/workflows/*.yml` — jobs → steps |
| **Ecosystem** | Tightly integrated with Azure Boards, Artifacts, Repos | Native to GitHub; best for orgs already on GitHub |
| **Marketplace** | Large task library (Microsoft-built + community) | Rich Actions Marketplace with open-source dominance |
| **Self-hosted Runners** | Full support with agent pools and capacity management | Full support with runner groups and ephemeral runners |
| **OIDC to Azure** | Supported via Federated Credentials | Supported via OIDC token (`azure/login`) |
| **Environments & Approvals** | First-class built-in environments with approval gates | Requires third-party actions or manual approval (`environment: reviewers`) |
| **Artifact Sharing** | Built-in build/release artifacts with retention policies | Upload/download artifacts; newer `actions/cache` for speed |
| **Pricing** | Free for open-source; paid per parallel job | Generous free tier for public repos; minutes-based for private |

**Pros of Azure DevOps Pipelines:**
- **Mature enterprise governance**: built-in environments, approval policies, and deployment retention make it ideal for regulated industries.
- **Azure-native**: seamless integration with Azure Key Vault, Azure Artifacts, and Azure Monitor.
- **Classic release pipelines** are still available for teams migrating from legacy workflows.

**Cons of Azure DevOps Pipelines:**
- YAML syntax is more verbose and less intuitive for developers used to GitHub.
- Smaller open-source community compared to GitHub Actions.
- Can feel **heavyweight** for smaller projects or teams not using Azure Boards.

**Pros of GitHub Actions:**
- **Developer-first**: YAML lives in the repo alongside code; PR-driven workflow is natural for open-source and modern teams.
- **Massive Marketplace**: thousands of community-contributed actions reduce boilerplate.
- **Reusability**: workflow calls and composite actions enable modular pipeline design.

**Cons of GitHub Actions:**
- **Approval gates** are less mature — you rely on branch protection rules or third-party tools for complex approval workflows.
- **Artifact storage** has size and retention limits on the free tier.
- Can become **complex** at scale without a strong convention for workflow organization.

**Verdict:** For Siemens-scale enterprises deeply invested in Azure, **Azure DevOps Pipelines** often win on governance and compliance. For teams prioritizing developer velocity and open-source collaboration, **GitHub Actions** is the stronger choice. Many organizations run both in parallel.

---

### 3️⃣ How do you handle branching strategy and trigger pipelines only on specific branch/path changes?

I typically implement a **GitFlow** or **Trunk-Based Development** strategy depending on team maturity. For enterprise environments like Siemens, a modified GitFlow is common:

**Branching Model:**
- **`main`** — production-ready code, protected branch, deploys to Production
- **`develop`** — integration branch, deploys to Staging
- **`feature/*`** — feature branches, triggers build and validation only (no deploy)
- **`release/*`** — release preparation, deploys to UAT/Staging
- **`hotfix/*`** — emergency fixes, fast-tracked to Production

**Branch + Path Filtering in Azure DevOps:**

```yaml
trigger:
  branches:
    include:
      - main
      - develop
      - release/*
  paths:
    include:
      - terraform/**
      - src/**
    exclude:
      - docs/**
      - README.md
```

This ensures pipelines only fire when infrastructure or application code changes — **not** when documentation is updated.

**Path-Filtered Workflows in GitHub Actions:**

```yaml
name: Terraform CI
on:
  push:
    branches: [main, develop]
    paths:
      - 'terraform/**'
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'
```

**Per-Environment Mapping:**

| Branch | Pipeline Trigger | Target Environment |
|--------|-----------------|-------------------|
| `feature/*` | PR only | None (validation only) |
| `develop` | Push | Staging |
| `release/*` | Push | UAT |
| `main` | Push | Production (with approval) |

**Pull Request Validation:**
I also configure **PR-triggered pipelines** that run `terraform plan` (diff-only, no apply) and post the infrastructure diff as a **comment on the PR**. This gives reviewers visibility into what resources will be created, modified, or destroyed before merge.

In Azure DevOps, this maps to **PR Validation pipelines** via the `pr:` trigger. In GitHub Actions, it maps to `pull_request` events with `conclusion: success` as a required **branch protection status check**.

---

### 4️⃣ How would you set up a self-hosted agent/runner, and why might you need one over a Microsoft-hosted one?

**Why use self-hosted runners?**

| Reason | Explanation |
|--------|------------|
| **Cost** | Microsoft-hosted runners charge per-minute; self-hosted eliminates this for high-frequency pipelines |
| **Network Access** | Self-hosted runners can access private VNet resources, on-premises systems, or internal registries without VPN/tunneling |
| **Persistent Cache** | Build artifacts, dependency caches, and Docker layers persist across runs, drastically reducing build times |
| **Custom Tools** | Pre-installed proprietary tooling, SDKs, or licensed software that cannot be installed on ephemeral VMs |
| **Compliance** | Data residency and air-gapped environments require workloads to stay within the organization's infrastructure |
| **Large Builds** | Custom hardware (CPU, RAM, GPU) for heavy compilation or ML model training |

**Setting Up a Self-Hosted Runner in GitHub Actions:**

```bash
# 1. Install prerequisites
sudo apt update && sudo apt install -y curl git unzip jq

# 2. Download and extract the runner
curl -o runner.tar.gz -L https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64.tar.gz
tar xzf runner.tar.gz

# 3. Configure with registration token (from repo Settings → Actions → Runners)
./config.sh --url https://github.com/ORG/REPO --token <REGISTRATION_TOKEN> \
  --unattended --replace --runasservice \
  --name "siemens-selfhosted-runner-01"

# 4. Start the service
sudo systemctl start actions.runner.ORG.REPO
sudo systemctl enable actions.runner.ORG.REPO

# 5. Label the runner for targeted job routing
./config.sh --labels terraform azure-linux
```

**Setting Up a Self-Hosted Agent in Azure DevOps:**

```bash
# 1. Download agent package
curl -o vsts-agent.tar.gz -L https://vstsagentpackage.azureedge.net/agent/4.202.1/agents/linux-x64-4.202.1.tar.gz
tar xzf vsts-agent.tar.gz

# 2. Configure with PAT token from Azure DevOps → Organization Settings → Agent Pools
./config.sh --url https://dev.azure.com/ORG --auth pat --token <PAT_TOKEN> \
  --pool "siemens-agent-pool" --agent selfhosted-agent-01 \
  --runasservice --acceptTeeEula

# 3. Start
sudo ./svc.sh start
```

**Best Practices:**
- Run agents in an **agent pool** with multiple instances for parallelism and redundancy.
- Use **auto-scaling** (GitHub Actions auto-scaling runners on EC2/AKS, or Azure DevOps with Virtual Machine Scale Sets).
- Restrict self-hosted runners to **private repositories only** — Microsoft's security guidance strongly advises against running public-code workloads on self-hosted infrastructure.
- Monitor runner health via **Azure Monitor** or **Prometheus/Grafana** and set up auto-restart on crash.

---

## 🔹 Security & Secrets

### 5️⃣ How do you manage secrets in pipelines (Azure DevOps variable groups + Key Vault, GitHub Secrets/OIDC)?

**Secret management** is one of the highest-priority concerns in pipeline design. The goal is to ensure that **no secret ever appears in plaintext** in pipeline logs, YAML files, or repository history.

**Azure DevOps — Variable Groups Linked to Key Vault:**

The recommended approach is to store secrets in **Azure Key Vault** and reference them in Azure DevOps via a **Variable Group** with a linked connection. This provides automatic secret rotation — the variables refresh from Key Vault at the start of every pipeline run.

```yaml
# azure-pipelines.yml
stages:
  - stage: Deploy
    variables:
      - group: KeyVault-Secrets-Group  # Linked to Azure Key Vault
    jobs:
      - job: Deploy
        steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'Azure-RM-ServiceConnection'
              scriptType: 'bash'
              scriptLocation: 'inline'
              inlineScript: |
                echo "Logging in with SPN..."
                # Variables from Key Vault are available as $(KEY_VAULT_SECRET_NAME)
                az login --service-principal \
                  -u $(CLIENT_ID) \
                  -p $(CLIENT_SECRET) \
                  --tenant $(TENANT_ID)
```

**Setup Steps:**
1. Create an **Azure Key Vault** and add secrets (client IDs, connection strings, API keys).
2. In Azure DevOps, navigate to **Pipelines → Library → + Variable Group**.
3. Select **Linked Azure Key Vault** and choose the vault + subscription.
4. Check the boxes for secrets you want to pull — Azure DevOps marks them as **masked** automatically.
5. Reference the variable group in pipeline YAML via `variables: - group: <group-name>`.

**GitHub Actions — Repository/Organization Secrets:**

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Login to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}  # JSON with clientId, clientSecret, tenantId
      - name: Deploy Terraform
        run: |
          terraform init
          terraform apply -auto-approve -var="client_secret=${{ secrets.TF_CLIENT_SECRET }}"
```

Secrets are stored in **GitHub Settings → Secrets and variables → Actions** and are never exposed in logs — GitHub **auto-masks** any value that matches a secret.

**Key Principles:**
- **Never hardcode** secrets in YAML, scripts, or environment files.
- Use **separate Key Vault per environment** (dev, staging, prod) for least-privilege isolation.
- **Rotate secrets regularly** — Key Vault + linked variable groups make rotation zero-downtime.
- Audit secret access via **Azure Key Vault diagnostic logs** sent to Log Analytics.
- For GitHub, prefer **OIDC federation** (see next question) over static `AZURE_CREDENTIALS` secrets to eliminate long-lived credentials entirely.

---

### 6️⃣ How would you set up OIDC/Workload Identity Federation between GitHub Actions/Azure DevOps and Azure to avoid storing long-lived credentials?

**OIDC (OpenID Connect) federation** eliminates the need for **Service Principals with client secrets or certificates**. Instead, the CI/CD platform requests a short-lived JWT token that Azure validates against a **Federated Identity Credential** on a managed identity or service principal.

**Why this matters:**
- No secret rotation to manage — tokens are **ephemeral** (1-hour TTL).
- Reduced blast radius — tokens are scoped to a specific **repository, branch, and environment**.
- Auditability — every token issuance is traceable to a specific workflow run.

**Setup for GitHub Actions → Azure (OIDC):**

*Step 1 — Create Azure Enterprise Application & Federated Credential:*

```bash
# Create a service principal (no secret)
az ad sp create-for-rbac --name "github-oidc-sp" --skip-assignment

# Output:
# {
#   "appId": "xxxx-xxxx-xxxx",
#   "tenantId": "yyyy-yyyy-yyyy",
#   "id": "zzzz-zzzz-zzzz"  <-- this is the clientId for the app
# }

# Add federated credential scoped to repo + branch
az ad app federated-credential create --id <APP-OBJECT-ID> --parameters '{
  "name": "github-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:ORG/REPO:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

*Step 2 — Assign RBAC roles to the Service Principal:*

```bash
az role assignment create \
  --role "Contributor" \
  --assignee-object-id <SP-OBJECT-ID> \
  --assignee-principal-type ServicePrincipal \
  --scope /subscriptions/<SUB-ID>/resourceGroups/<RG-NAME>
```

*Step 3 — Configure GitHub Actions workflow:*

```yaml
name: Deploy via OIDC
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write    # Required for OIDC token request
      contents: read     # Required for actions/checkout

    steps:
      - uses: actions/checkout@v4

      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}     # The SP appId
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}      # Azure AD tenant
          subscription-id: ${{ secrets.AZURE_SUB_ID }}   # Target subscription
          # No client-secret needed — login action requests JWT automatically

      - name: Deploy
        run: az deployment group create --resource-group rg-prod --template-file main.bicep
```

The only GitHub secrets needed are the **non-sensitive** `client-id`, `tenant-id`, and `subscription-id`. No passwords, no certificates, no rotation.

**Setup for Azure DevOps → Azure (OIDC):**

Azure DevOps supports OIDC via the **`AzureCLI@2` task with `serviceConnectionTypes: 'Managed Service Identity'`** or by using a **service connection configured with a federated credential**.

```yaml
# In Azure DevOps service connection:
# Type: Service Principal (Automatic) with Workload Identity Federation
# Azure DevOps generates a JWT, Azure validates it against the federated credential

steps:
  - task: AzureCLI@2
    inputs:
      azureSubscription: 'OIDC-Service-Connection'
      scriptType: bash
      scriptLocation: inline
      inlineScript: |
        az account show
```

**Subject claim formats:**

| Platform | Subject Format |
|----------|---------------|
| GitHub Actions | `repo:ORG/REPO:ref:refs/heads/main` |
| GitHub Actions (PR) | `repo:ORG/REPO:pull_request` |
| Azure DevOps | Configured automatically by the service connection |

**Best Practices:**
- Scope federated credentials to the **narrowest branch/environment** possible (e.g., `main` for prod, `develop` for staging).
- Use **separate Service Principals** per environment with different RBAC scopes.
- Combine OIDC with **Azure Managed Identities** for workloads running in Azure (VMs, AKS, App Service) to achieve a fully credential-free architecture.

---

### 7️⃣ How do you enforce code quality/security scanning (tfsec, Checkov, linting) in the pipeline?

**Shift-left security** means catching misconfigurations, policy violations, and code quality issues **before** they reach production. I implement a multi-layer scanning approach:

**Tool Stack:**

| Tool | Purpose | Language/Target |
|------|---------|----------------|
| **Checkov** | Infrastructure-as-Code security & policy scanning | Terraform, Bicep, ARM, Kubernetes, CloudFormation |
| **tfsec** (formerly terrascan) | Terraform security scanning with SARIF output | Terraform |
| **tflint** | Terraform linting — rule validation, deprecated syntax | Terraform |
| **hadolint** | Dockerfile linting | Docker |
| **SonarQube / SonarCloud** | Code quality, duplication, security hotspot analysis | Multi-language |
| **Trivy** | Container image and filesystem vulnerability scanning | Container images, FS |
| **OWASP Dependency-Check** | Dependency vulnerability scanning | Java, Node.js, .NET |

**Pipeline Implementation (Azure DevOps):**

```yaml
stages:
  - stage: SecurityScanning
    jobs:
      - job: IaCScan
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          # ---- Checkov ----
          - script: |
              pip install checkov
              checkov -d terraform/ \
                --framework terraform \
                --soft-fail \
                --output cli,json,sarif \
                --output-file-report-value checkov-report \
                --download-external-modules true
            displayName: 'Checkov - Terraform Security Scan'

          - task: PublishSecurityAnalysisLogs@3
            inputs:
              ArtifactUpload: 'true'
              SecureFile: 'checkov-report.sarif'

          # ---- tflint ----
          - script: |
              curl -sSLo tflint https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip
              unzip tflint.zip && sudo mv tflint /usr/local/bin/
              tflint --config .tflint.hcl
            displayName: 'tflint - Terraform Linting'

          # ---- tfsec with SARIF for GitHub Code Scanning ----
          - script: |
            wget -O tfsec.tar.gz https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64.tar.gz
            tar xzf tfsec.tar.gz
            ./tfsec terraform/ --format sarif -o tfsec-results.sarif
            displayName: 'tfsec - Security Scan'
```

**Pipeline Implementation (GitHub Actions):**

```yaml
name: Security Scanning
on:
  pull_request:
    branches: [main]

jobs:
  checkov:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/
          framework: terraform
          soft_fail: true
          output_format: sarif
          output_file_path: checkov-results.sarif
      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: checkov-results.sarif

  tfsec:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: terraform/
          sarif_output: tfsec-results.sarif
```

**Enforcement Strategy:**
- **`soft_fail: true`** — scan results are reported but don't block the PR on first integration. This allows the team to remediate existing violations gradually.
- **`fail_on_error: true`** (production mode) — once baseline is cleaned up, switch to **hard-fail** so new violations **block the merge**.
- **SARIF upload** — security findings appear directly on the **GitHub Security tab** and as **inline annotations on the PR diff**.
- **Scheduled scans** — run a weekly full-repo scan on `main` to catch drift from updated module versions or new policy rules.
- **Custom Checkov policies** — write organization-specific policies (e.g., "all resources must have `environment` and `cost-center` tags") using Checkov's **BC_ (custom block type)** and **CKV_ (custom check)** frameworks.

---

## 🔹 Terraform & Infrastructure as Code

### 8️⃣ Explain how you'd implement a Terraform plan/apply pipeline with manual approval before apply

This is a critical pattern for enterprise infrastructure. The goal is to ensure that **every infrastructure change is reviewed and explicitly approved** before it touches production.

**Approach in Azure DevOps (Recommended for Siemens):**

Azure DevOps provides **native approval gates** via **Environments**. When a stage targets an Environment, you can configure required approvers, automatic gates, and PLAs (Pre-Deployment Approvals).

```yaml
stages:
  - stage: Plan
    jobs:
      - job: TerraformPlan
        pool:
          vmImage: 'ubuntu-latest'
        variables:
          - group: Terraform-KeyVault-Vars
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: 'latest'
          - script: terraform init -backend-config=backend.hcl
          - script: |
              terraform plan -var-file=env/prod.tfvars \
                -out=tfplan.out \
                -input=false
            displayName: 'Generate Terraform Plan'
          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: 'tfplan.out'
              artifactName: 'terraform-plan'

  - stage: Apply
    dependsOn: Plan
    condition: succeeded()
    # This environment has manual approval configured in Azure DevOps UI
    jobs:
      - deployment: ApplyToProduction
        environment: production  # <-- Triggers approval gate
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: terraform-plan
                - task: TerraformInstaller@0
                  inputs:
                    terraformVersion: 'latest'
                - script: |
                    terraform init -backend-config=backend.hcl
                    terraform apply -auto-approve $(Pipeline.Workspace)/terraform-plan/tfplan.out
                  displayName: 'Apply Terraform Plan'
```

**Configuring the Approval Gate:**
1. Navigate to **Azure DevOps → Pipelines → Environments → production → Settings**.
2. Under **Approval checks**, add **Required reviewers** (e.g., Infrastructure Lead, Security Team).
3. Optionally add **Automatic gates** (e.g., quality gates from SonarQube, deployment frequency limits).
4. Set **Retention policy** to keep deployment history for compliance audits.

**Approach in GitHub Actions:**

GitHub Actions doesn't have native stage-based approvals, but you can use **Environment Protection Rules**:

```yaml
name: Terraform Plan & Apply
on:
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  plan:
    runs-on: ubuntu-latest
    outputs:
      plan_file: ${{ steps.plan.outputs.plan_file }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init -backend-config=backend.hcl
      - run: terraform plan -out=tfplan.out -input=false
        id: plan
      - uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: tfplan.out

  apply:
    needs: plan
    runs-on: ubuntu-latest
    environment: production  # <-- Protection rule requires approval
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: tfplan
          path: .
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init -backend-config=backend.hcl
      - run: terraform apply -auto-approve tfplan
```

In **GitHub → Settings → Environments → production → Protection rules**, add **Required reviewers** and optionally **Wait timer** (e.g., 30-minute cooling-off period).

**Key Design Principles:**
- **Plan and Apply are separate stages/jobs** — this creates a natural review checkpoint.
- **`terraform plan -out`** serializes the plan binary so Apply executes exactly what was reviewed (not a re-computed plan).
- **Plan output is posted** as a PR comment or build summary so approvers can see the diff.
- For extra safety, run `terraform show tfplan.out` in text format and publish it as a log artifact for the audit trail.

---

### 9️⃣ How do you manage Terraform remote state and state locking in a team CI/CD environment?

**Remote state** is essential for team collaboration. Local state files cause conflicts, data loss, and make CI/CD impossible. I use **Azure Blob Storage with Azure Cosmos DB** (or just Azure Storage with built-in state locking) as the backend.

**Backend Configuration:**

```hcl
# backend.hcl
bucket_name = "tfstate-siemens-prod"
key         = "infrastructure/prod/terraform.tfstate"
resource_group_name = "rg-terraform-state"
storage_account_name = "tfstateprodeu"
access_key          = "managed-by-keyvault"  # Use OIDC instead in production
```

```hcl
# main.tf — Backend block
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateprodeu"
    container_name       = "tfstate"
    key                  = "infrastructure/prod/terraform.tfstate"
  }
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}
```

**State Locking Mechanism:**

| Backend | Locking Mechanism | How It Works |
|---------|-----------------|--------------|
| **AzureRM (Blob Storage)** | **Lease on blob** | Azure Storage automatically acquires a lease when `terraform plan/apply` runs. If another process tries to acquire the lease, it fails with a lock error. |
| **S3 + DynamoDB** | DynamoDB table | Terraform writes a lock entry; concurrent operations detect the entry and wait/fail. |
| **Terraform Cloud/Enterprise** | Built-in | Managed state locking with UI visibility into who holds the lock. |

**State Organization Strategy (per-environment isolation):**

```
tfstate (container)
├── infrastructure/
│   ├── dev/terraform.tfstate
│   ├── staging/terraform.tfstate
│   └── prod/terraform.tfstate
├── networking/
│   ├── dev/terraform.tfstate
│   └── prod/terraform.tfstate
└── platform/
    ├── dev/terraform.tfstate
    └── prod/terraform.tfstate
```

Each team and environment gets its own **state file key** within the same storage account. This prevents cross-environment contamination and enables **per-workspace RBAC**.

**Security Best Practices for State:**
- **Enable encryption** at rest (Azure Storage Service Encryption — SSE) and in transit (TLS 1.2+).
- **Disable public access** on the storage account — set `public_access_level` to `Disabled`.
- **Enable soft delete** and **versioning** on the blob container to recover from accidental `terraform state rm` or state corruption.
- **Restrict access** using Azure RBAC — only the pipeline Service Principal should have `Storage Blob Data Contributor` on the state container.
- **State files contain sensitive data** (passwords, connection strings) — treat them as **highly classified** and apply network-level restrictions (private endpoints, VNet rules).

**Handling Stale Locks:**
If a pipeline is killed mid-apply, the lock can persist. Resolution:
```bash
# Force unlock (use with extreme caution — only when you are sure no other process is running)
terraform force-unlock <LOCK-ID>
```
I typically add a **pipeline cleanup step** that runs `terraform force-unlock` only when the pipeline is manually cancelled, using a conditional check.

---

### 🔟 How do you detect and handle infrastructure drift?

**Infrastructure drift** occurs when the actual state of resources diverges from what Terraform expects — typically caused by manual changes in the Azure Portal, other automation tools, or Azure auto-remediation features.

**Detection Strategies:**

1. **Scheduled `terraform plan` (Drift Detection Pipeline):**

```yaml
# Run daily at 2 AM to detect drift
schedules:
  - cron: '0 2 * * *'
    branches:
      include:
        - main
    always: true  # Run even if no code changed

steps:
  - script: |
      DRIFT_OUTPUT=$(terraform plan -detailed-exitcode -input=false 2>&1)
      EXIT_CODE=$?
      if [ $EXIT_CODE -eq 2 ]; then
        echo "##[error]DRIFT DETECTED in production infrastructure"
        echo "$DRIFT_OUTPUT" > drift-report.txt
        # Post alert to Teams channel
        curl -X POST -H 'Content-Type: application/json' \
          -d "{\"text\": \"🚨 Infrastructure drift detected in prod\"}" \
          "$TEAMS_WEBHOOK_URL"
      fi
    displayName: 'Detect Drift'
```

The **`-detailed-exitcode`** flag returns exit code `2` when changes are detected (vs. `0` for no changes). This makes it trivial to trigger alerts.

2. **Azure Policy + Guest Configuration:**
Deploy **Azure Policy assignments** that continuously audit resource compliance. For example, policies that flag untagged resources or security misconfigurations that Terraform doesn't track.

3. **Terraform Cloud/Enterprise Drift Detection:**
Terraferm Cloud offers **built-in drift detection** with a visual dashboard showing when and where drift occurred, who made manual changes, and the magnitude of divergence.

**Handling Drift — Remediation Approaches:**

| Approach | When to Use | Risk |
|----------|------------|------|
| **`terraform import`** — Import the manually changed resource back into state | When the manual change was intentional and should be preserved | Low — keeps state in sync |
| **`terraform apply`** — Let Terraform revert the resource to declared state | When the manual change was unauthorized or accidental | Medium — may cause brief service disruption |
| **Update Terraform code** to match the manual change, then `terraform apply` | When the manual change was a valid fix that needs to be codified | Low — converges code and infrastructure |
| **`terraform state mv` / `terraform state rm`** — Manual state manipulation | When resources were renamed or moved outside of Terraform | High — requires careful validation |

**Prevention Strategies:**
- **Restrict Azure Portal access** — use Azure RBAC to limit who can manually modify production resources. Grant **Reader** role to most users; **Contributor** only to infrastructure owners.
- **Enable Azure Resource Locks** (`CanNotDelete` and `ReadOnly`) on critical resources to prevent accidental deletion or modification.
- **Document the change management process** — any manual change must be followed by a Terraform code update within 24 hours.
- **Use Azure Activity Log alerts** to notify the team immediately when someone modifies infrastructure outside of CI/CD.

---

## 🔹 Deployment Strategy & Governance

### 🔟➊ How do you implement approval gates / environments for production deployments?

Approval gates are the **last line of defense** before code reaches production. I implement them at multiple levels:

**Azure DevOps — Multi-Layer Approval:**

```yaml
stages:
  - stage: DeployProduction
    dependsOn: DeployStaging
    condition: succeeded('DeployStaging')
    jobs:
      - deployment: ProdDeploy
        environment: production
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Deploying to production..."
```

**Environment Configuration (done in Azure DevOps UI):**

| Gate Type | Configuration | Purpose |
|-----------|-------------|---------|
| **Pre-deployment Approval** | Require 2 reviewers (Infra Lead + Security Lead) | Human review before prod changes |
| **Pre-deployment Gate — Quality Gate** | SonarQube quality gate must pass | Code quality threshold enforcement |
| **Pre-deployment Gate — Query Pipeline Runs** | Staging deployment must have succeeded | Pipeline dependency verification |
| **Wait Time Gate** | 30-minute delay after approval | Cooling-off period for last-minute cancellation |
| **CAB Schedule Gate** | Only deploy during approved change windows (e.g., Tue/Thu 2–6 PM) | Change Advisory Board compliance |

**GitHub Actions — Environment Protection Rules:**

```yaml
jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://prod.example.com
    steps:
      - name: Deploy to Production
        run: |
          ./deploy.sh --environment production
```

**GitHub Protection Rules (Settings → Environments):**
- **Required reviewers**: minimum 2 people from `@infra-leads` team.
- **Wait timer**: 30 minutes after approval before job starts.
- **Deployment branches**: restrict to `main` only (no feature branch deploys to prod).
- **Protection rules for tags**: allow `v*` tagged releases only.

**Enterprise Governance Additions:**
- **ServiceNow / Jira integration** — pipeline creates a Change Request (CR) ticket automatically; deployment only proceeds once the CR is approved.
- **Deployment windows** — use cron-based scheduling to prevent deployments during business hours or known maintenance windows.
- **Runbook attachment** — every prod deployment links to a runbook with rollback steps, contact info, and expected downtime.

---

### 🔟➋ How do you roll back a failed deployment in your pipeline?

Rollback strategy depends on the **deployment type** and **infrastructure mutability**. I implement rollback at three levels:

**Level 1 — Application Rollback (Fastest, < 2 minutes):**

For Azure App Service / Function Apps, use **deployment slots swap with automatic rollback**:

```yaml
# Azure DevOps — Slot Swap with Rollback
- task: AzureAppServiceManage@0
  inputs:
    AzureSubscription: 'Azure-RM-Connection'
    Action: 'Swap Slots with Specific Name'
    WebAppName: 'siemens-app-prod'
    SourceAndDestinationSlot: 'production, staging'
    VaultCertificate: true

# If health check fails post-swap:
- task: AzureAppServiceManage@0
  condition: failed()
  inputs:
    AzureSubscription: 'Azure-RM-Connection'
    Action: 'Swap Slots with Specific Name'
    WebAppName: 'siemens-app-prod'
    SourceAndDestinationSlot: 'production, staging'  # Swap back
```

**Level 2 — Terraform Rollback (State-Based):**

```yaml
# On apply failure, revert to previous known-good state
- script: |
    if terraform apply -auto-approve tfplan.out; then
      echo "Apply succeeded"
    else
      echo "Apply failed — rolling back to previous state"
      # Option A: Re-apply the previous plan (if saved)
      terraform apply -auto-approve previous-tfplan.out
      # Option B: Import current state and revert
      terraform state pull > failed-state.json
      terraform state push last-known-good-state.json
      terraform apply -auto-approve
    fi
  displayName: 'Apply with Rollback'
```

**Level 3 — Full Infrastructure Rollback (Nuclear option):**

For major infrastructure failures, use **Terraform state versioning**:
```bash
# Azure Blob Storage enables versioning — restore previous state version
az storage blob versions list --container-name tfstate --name infrastructure/prod/terraform.tfstate

# Download and restore the previous version
az storage blob download --container-name tfstate \
  --name infrastructure/prod/terraform.tfstate \
  --version-id <PREVIOUS-VERSION-ID> \
  --file restored-state.json

terraform state push restored-state.json
terraform apply -auto-approve  # Converge infrastructure back to known-good state
```

**Rollback Checklist:**
- **Health checks** run automatically after every deployment — failure triggers rollback.
- **Database migrations** are the hardest to rollback — use **expansion/contraction pattern** (add columns before removing old ones) and forward-compatible schemas.
- **Rollback runbooks** are documented per-service and tested quarterly.
- **Feature flags** (Azure App Configuration) allow disabling a feature without full rollback.

---

### 🔟➌ How do you design pipelines across dev/staging/prod with promotion between environments?

I use a **progressive delivery** model where code must pass through each environment sequentially, with **gating criteria** at each promotion point.

**Multi-Environment Pipeline Architecture:**

```
  Feature Branch                    PR Merge to develop                   Merge to main
  ──────────────                   ──────────────────                   ─────────────
         │                                │                                  │
         ▼                                ▼                                  ▼
  ┌──────────────┐              ┌──────────────────┐              ┌─────────────────┐
  │   Validate   │              │    STAGING       │              │   PRODUCTION    │
  │   (PR only)   │ ──────────► │  (Auto Deploy)   │ ──────────► │  (Approval Gate) │
  └──────────────┘              └──────────────────┘              └─────────────────┘
   - Unit Tests                   - Integration Tests               - Smoke Tests
   - Linting                      - Performance Tests               - Monitoring
   - Security Scan                - Manual QA Sign-off              - Runbook
   - terraform plan               - terraform apply                 - terraform apply
                                  - Approval (1 reviewer)
```

**Azure DevOps Multi-Stage Pipeline:**

```yaml
trigger:
  branches:
    include:
      - develop
      - main

stages:
  # ---- Stage 1: DEV (on every PR to develop) ----
  - stage: Dev
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/develop')
    variables:
      environment: dev
      tfvar_file: env/dev.tfvars
    jobs:
      - job: BuildAndDeployDev
        steps:
          - script: terraform init
          - script: terraform plan -var-file=$(tfvar_file)
          - script: terraform apply -auto-approve -var-file=$(tfvar_file)
          - script: |
              ./run-smoke-tests.sh --env dev
            displayName: 'Smoke Tests'

  # ---- Stage 2: STAGING (auto-promoted from Dev) ----
  - stage: Staging
    dependsOn: Dev
    condition: succeeded('Dev')
    variables:
      environment: staging
      tfvar_file: env/staging.tfvars
    jobs:
      - deployment: DeployStaging
        environment: staging
        strategy:
          runOnce:
            deploy:
              steps:
                - script: terraform init
                - script: terraform apply -auto-approve -var-file=$(tfvar_file)
                - script: |
                    ./run-integration-tests.sh --env staging
                  displayName: 'Integration Tests'

  # ---- Stage 3: PRODUCTION (manual approval + CAB window) ----
  - stage: Production
    dependsOn: Staging
    condition: and(succeeded('Staging'), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    variables:
      environment: production
      tfvar_file: env/prod.tfvars
    jobs:
      - deployment: DeployProduction
        environment: production
        strategy:
          runOnce:
            deploy:
              steps:
                - script: terraform init
                - script: terraform apply -auto-approve -var-file=$(tfvar_file)
                - script: |
                    ./run-smoke-tests.sh --env prod
                    ./verify-health-endpoints.sh --env prod
                  displayName: 'Post-Deploy Verification'
```

**Promotion Criteria:**

| Environment | Promotion Trigger | Gates |
|------------|------------------|-------|
| **Dev** | PR merge to `develop` | Tests pass, security scan clean |
| **Staging** | Dev stage succeeds | 1 reviewer approval, integration tests pass |
| **Production** | Staging succeeds + merge to `main` | 2+ reviewers, CAB approval, quality gate, deployment window |

**Environment-Specific Configuration:**
- **Separate `.tfvars` per environment** — never share variable files.
- **Separate state files per environment** — prevents cross-environment state corruption.
- **Separate Key Vaults per environment** — secrets isolation.
- **Different Service Principals** per environment — least-privilege RBAC.

---

## 🔹 Bonus

### 🔟➍ How do you set up alerts/notifications (Teams/Slack/email) for pipeline failures?

Notification is critical for **MTTR (Mean Time To Recovery)**. I set up multi-channel alerts so the right people are notified at the right time.

**Azure DevOps — Built-in Notifications:**

Azure DevOps has a native **Teams connector** and email notification system:

1. Navigate to **User Settings → Notifications** (gear icon).
2. Create a rule: **When a build fails → Notify via Email + Teams**.
3. For Teams: install the **Azure DevOps Connector** in your Teams channel. Pipeline runs automatically post status cards, and failures post red alert messages.

**Azure DevOps — Webhook to Teams (Custom):**

```yaml
# At the end of the pipeline, send failure notification
- script: |
    PIPELINE_RESULT="$(Build.Result)"
    if [ "$PIPELINE_RESULT" = "Failed" ]; then
      curl -X POST -H 'Content-Type: application/json' \
        -d '{
          "@type": "MessageCard",
          "@context": "https://schema.org/extensions",
          "summary": "Pipeline Failed",
          "themeColor": "FF0000",
          "title": "🚨 CI/CD Pipeline Failure",
          "sections": [{
            "activityTitle": "Pipeline: '$(Build.DefinitionName)'",
            "activitySubtitle": "Build #$(Build.BuildNumber) failed",
            "facts": [
              {"name": "Branch", "value": "$(Build.SourceBranch)"},
              {"name": "Triggered By", "value": "$(Build.RequestedFor)"},
              {"name": "Pipeline URL", "value": "$(Build.Url)"}
            ]
          }]
        }' \
        "$TEAMS_WEBHOOK_URL"
    fi
  displayName: 'Send Teams Alert on Failure'
  condition: failed()
```

**GitHub Actions — Notifications:**

```yaml
# Using slack-api/slack-notify-action
- name: Notify Slack on Failure
  if: failure()
  uses: slackapi/slack-github-action@v1.25.0
  with:
    payload: |
      {
        "text": "🚨 Pipeline Failed: ${{ github.workflow }}",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Build Failed*\nRepository: ${{ github.repository }}\nBranch: ${{ github.ref }}\nCommit: ${{ github.sha }}\n<a href=\"${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Run>"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
    SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK
```

**Escalation Strategy:**

| Severity | Channel | Recipients | SLA |
|----------|---------|-----------|-----|
| **Build Failure** | Teams/Slack #ci-cd channel | Dev Team | Next sprint |
| **Staging Deploy Failure** | Teams/Service Owner channel + Email | Service Owner + Dev Lead | 4 hours |
| **Production Deploy Failure** | Teams #incident channel + PagerDuty | On-Call Engineer + Infra Lead | 15 minutes |
| **Drift Detected** | Email + Teams | Infra Team | 24 hours |

For **PagerDuty integration**, I use the PagerDuty Azure DevOps extension or the `pagerduty/pagerduty-deployment-github-action` to create incidents automatically on prod failures.

---

### 🔟➎ How would you implement a blue-green or canary deployment strategy in Azure?

**Blue-Green Deployment** and **Canary Deployment** are progressive delivery strategies that minimize downtime and risk. Azure provides native support for both patterns.

---

**Blue-Green Deployment (Azure App Service Slots):**

The concept: maintain **two identical production environments** — Blue (current live) and Green (new version). Swap them instantly with zero downtime.

```yaml
# Azure DevOps — Blue-Green via Deployment Slots
stages:
  - stage: BlueGreenDeploy
    jobs:
      - deployment: DeployToGreenSlot
        environment: production-green
        strategy:
          runOnce:
            deploy:
              steps:
                # 1. Deploy new version to Green (staging) slot
                - task: AzureFunctionApp@1
                  inputs:
                    azureSubscription: 'Azure-RM-Connection'
                    appType: 'functionApp'
                    appName: 'siemens-app'
                    resourceGroupName: 'rg-prod'
                    package: '$(Pipeline.Workspace)/drop/function-app.zip'
                    deployToSlotOrAssembly: true
                    slotName: 'green'

                # 2. Run smoke tests against Green slot
                - script: |
                    ./smoke-tests.sh --url https://siemens-app-green.azurewebsites.net
                  displayName: 'Smoke Tests on Green'

                # 3. Swap Green to Production (instant, zero-downtime)
                - task: AzureAppServiceManage@0
                  inputs:
                    AzureSubscription: 'Azure-RM-Connection'
                    Action: 'Swap Slots with Specific Name'
                    WebAppName: 'siemens-app'
                    SourceAndDestinationSlot: 'green, production'

                # 4. If anything fails post-swap, swap back immediately
                - task: AzureAppServiceManage@0
                  condition: failed()
                  inputs:
                    AzureSubscription: 'Azure-RM-Connection'
                    Action: 'Swap Slots with Specific Name'
                    WebAppName: 'siemens-app'
                    SourceAndDestinationSlot: 'green, production'  # Rollback
                  displayName: 'Emergency Rollback'
```

**Key characteristics of Blue-Green:**
- **Zero downtime** — swap is near-instant (DNS-level or load balancer level).
- **Instant rollback** — swap back to the previous slot if post-deploy monitoring detects issues.
- **Warm-up** — Green slot can be pre-warmed with traffic mirroring before swap.
- **Cost** — requires 2x infrastructure (two full environments running simultaneously).

---

**Canary Deployment (Azure Kubernetes Service — AKS):**

For containerized workloads, I use **Istio Service Mesh** or **Flagger** on AKS for automated canary analysis.

```yaml
# Flanger Canary Configuration (Kubernetes manifest)
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: siemens-api
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: siemens-api
  service:
    name: siemens-api
    port: 80
  analysis:
    interval: 60s
    threshold: 5          # Max failures before rollback
    maxWeight: 50          # Max traffic to canary
    stepWeight: 10         # Increment by 10% each step
    metrics:
      - name: request-success-rate
        interval: 2m
        thresholdRange:
          min: 99          # Rollback if success rate < 99%
      - name: request-duration
        interval: 2m
        thresholdRange:
          max: 500         # Rollback if p99 latency > 500ms
    webhooks:
      - name: smoke-test
        url: http://flagger-hook.hook.svc.cluster.net/smoke-test
        timeout: 30s
        mutex: true
      - name: approve-canary
        url: http://flagger-hook.hook.svc.cluster.net/decision
        timeout: 30s
        mutate: true
```

**Canary Traffic Progression:**

```
Step 1:  10% traffic → Canary    (monitor for 2 min)
Step 2:  20% traffic → Canary    (monitor for 2 min)
Step 3:  30% traffic → Canary    (monitor for 2 min)
Step 4:  50% traffic → Canary    (manual approval gate)
Step 5:  100% → Canary           (promote, delete old version)
```

At any step, if error rate exceeds threshold or latency spikes, **Flagger automatically rolls back** to the stable version.

**Azure-native Canary (without Service Mesh):**

For simpler scenarios, use **Azure Front Door** or **Application Gateway** weighted routing:

```bash
# Azure CLI — Route 10% to canary backend
az network application-gateway rule update \
  --gateway-name gw-prod \
  --resource-group rg-prod \
  --name routing-rule \
  --backend-http-settings backend-settings

# Use Azure Traffic Manager for DNS-based weighted routing
az network traffic-manager profile endpoint update \
  --name tm-siemens-app \
  --resource-group rg-prod \
  --type External \
  --target-endpoint siemens-app-canary.azurewebsites.net \
  --weight 10
```

**Comparison:**

| Strategy | Best For | Rollback Speed | Complexity | Cost |
|----------|---------|---------------|------------|------|
| **Blue-Green** | App Service, VMs, simple stateless apps | Instant (slot swap) | Low | 2x infra |
| **Canary** | Microservices, AKS, API workloads | Automatic (metric-driven) | Medium-High | Minimal (incremental) |
| **Feature Flags** | Application-level feature rollout | Instant (toggle off) | Low | Free |

In practice, I combine all three: **blue-green for infrastructure**, **canary for API services**, and **feature flags (Azure App Configuration)** for application-level feature control.

---

> *"The goal of DevOps is not to automate the delivery of broken software faster — it is to build systems that are safe to change at any time."*

---

*Document prepared for Siemens DevOps Engineer interview preparation. Covers Azure cloud platform, Terraform, CI/CD, security, and progressive delivery patterns.*
