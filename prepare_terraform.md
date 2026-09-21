---
## Terraform Production Execution Commands

```bash
terraform fmt        # Format Terraform files for consistent styling
terraform validate   # Validate syntax and internal consistency of configuration
terraform plan       # Generate an execution plan — shows what will be created, modified, or destroyed
terraform apply      # Apply the changes to infrastructure
```

---

## How do you pass environment-wise variables while applying the changes?

Environment-specific variables are passed using **.tfvars files** or **environment variables**:

```bash
# Using -var-file flag (recommended)
terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/prod.tfvars"

# Using individual -var flag
terraform apply -var="environment=production" -var="instance_type=m5.large"

# Using TF_VAR_ environment variables
export TF_VAR_environment=production
export TF_VAR_instance_type=m5.large
terraform apply
```

**`env/dev.tfvars`:**
```hcl
environment   = "dev"
instance_type = "t3.medium"
db_instance   = "db.t3.micro"
```

**`env/prod.tfvars`:**
```hcl
environment   = "production"
instance_type = "m5.xlarge"
db_instance   = "db.r5.large"
```

You can also use **Terraform Workspaces** to maintain separate state for each environment, though separate directories or S3 state paths per environment are the more common production approach.

---

## How do you enforce engineers to use secure Terraform modules?

- **Private Module Registry:** Host approved, security-reviewed modules in a **private Terraform Registry** (e.g., HashiCorp Terraform Cloud, Self-Hosted Registry, or Git-based module source). Restrict engineers to use only registry-published modules.
- **Sentinel / OPA Policies:** Enforce **policy-as-code** using HashiCorp Sentinel (Terraform Cloud) or **OPA Gatekeeper** to reject configurations that use unapproved modules or contain security misconfigurations.
- **Pre-commit Hooks & CI Validation:** Run **`terraform validate`**, **`tflint`**, and **`checkov`** in the CI pipeline. Block merges if the plan uses non-compliant modules.
- **Module Version Pinning:** Require that all module references specify an explicit version (e.g., `version = "~> 2.0"`) to prevent unexpected breaking changes.
- **Code Review:** Enforce pull request reviews for all Terraform changes, with checklists that verify module sources and security configurations.

---

## How do you prevent developers from creating unencrypted or publicly accessible resources?

- **Sentinel / OPA Policies:** Write mandatory policies that enforce encryption and access controls:
  - All S3 buckets must have `acl = "private"` and server-side encryption enabled
  - All RDS instances must have `storage_encrypted = true` and `publicly_accessible = false`
  - All security groups must not allow `0.0.0.0/0` on sensitive ports
- **`checkov` / `tfsec` in CI:** Scan Terraform code before `terraform apply` to detect misconfigurations:
  ```bash
  checkov -d . --framework terraform --soft-fail
  tfsec . --exclude-check GEN001
  ```
- **AWS Service Control Policies (SCPs):** Apply organization-level SCPs that deny creation of unencrypted S3 buckets, publicly accessible RDS instances, or overly permissive security groups — regardless of whether the resource was created via Terraform or the console.
- **Default-Secure Module Design:** Build internal Terraform modules that default to secure configurations (encryption enabled, private access only), so engineers must explicitly opt into insecure settings.

---

## How do you enforce these controls consistently for every engineer?

- **CI/CD Pipeline Gates:** Run `terraform plan`, `checkov`, `tfsec`, and `tflint` as mandatory steps in every pull request. Fail the build if security violations are detected.
- **Terraform Cloud / Enterprise Policy Sets:** Attach **Sentinel policy sets** at the organization or workspace level, so policies are evaluated automatically for every plan and apply — regardless of who triggers it.
- **Remote Backend with State Locking:** Use a shared remote backend (S3 + DynamoDB) so all engineers work against the same state, and no one can bypass the pipeline by running `terraform apply` locally.
- **Least-Privilege IAM:** Restrict direct `terraform apply` permissions. Only the CI/CD service account can execute `apply`, and engineers can only trigger plans through pull requests.
- **Mandatory Code Review:** Require at least one approved review for all infrastructure changes before merging.

---

## What is the difference between `terraform import` and `terraform taint`?

| Aspect | `terraform import` | `terraform taint` |
|--------|-------------------|-------------------|
| **Purpose** | Brings **existing infrastructure** under Terraform management | Marks a **managed resource** for recreation on the next `apply` |
| **When to Use** | When infrastructure was created manually (via console or CLI) and needs to be tracked by Terraform | When a resource is misconfigured or corrupted and needs to be replaced |
| **Effect** | Creates the resource entry in the state file without modifying the actual infrastructure | Marks the resource so that `terraform apply` will **destroy and recreate** it |
| **Example** | `terraform import aws_instance.web i-0abc123def456` | `terraform taint aws_instance.web` |

**`terraform import` example:**
```bash
# Import an existing EC2 instance into Terraform state
terraform import aws_instance.existing_server i-0abc123def456
# After import, write the matching resource block in .tf files
```

**`terraform taint` example:**
```bash
# Mark a resource for recreation
terraform taint aws_instance.web
terraform apply   # Will destroy and recreate the tainted resource
```

Note: `terraform taint` is deprecated in Terraform 0.15+. Use `-replace` flag instead:
```bash
terraform apply -replace='aws_instance.web'
```

---

## How do you manage secrets in Terraform without hardcoding them?

- **Environment Variables:** Pass secrets via `TF_VAR_` prefixed environment variables:
  ```bash
  export TF_VAR_db_password=$(aws secretsmanager get-secret-value --secret-id prod/db/password --query SecretString --output text)
  terraform apply
  ```
- **AWS Secrets Manager / SSM Parameter Store:** Retrieve secrets at plan/apply time:
  ```hcl
  data "aws_secretsmanager_secret_version" "db_password" {
    secret_id = "prod/db/password"
  }

  resource "aws_db_instance" "example" {
    password = data.aws_secretsmanager_secret_version.db_password.secret_string
  }
  ```
- **HashiCorp Vault:** Use the **Vault provider** to read secrets:
  ```hcl
  data "vault_generic_secret" "db" {
    path = "secret/data/prod/database"
  }

  resource "aws_db_instance" "example" {
    password = data.vault_generic_secret.db.data["password"]
  }
  ```
- **`sensitive` Attribute:** Mark variables and outputs as sensitive to prevent them from appearing in logs:
  ```hcl
  variable "db_password" {
    type      = string
    sensitive = true
  }

  output "db_password" {
    value     = var.db_password
    sensitive = true
  }
  ```
- **Never commit** `.tfstate` files or files containing secrets to version control. Add them to `.gitignore`.

---

## What's the difference between `count` and `for_each`? Give a real-world use case.

| Aspect | `count` | `for_each` |
|--------|---------|------------|
| **Type** | Creates resources based on an **integer index** (0, 1, 2...) | Creates resources based on a **map or set of strings** |
| **Reference** | Accessed by index: `aws_instance.web[0]` | Accessed by key: `aws_instance.web["us-east-1"]` |
| **Stability** | Removing an item shifts all indices, potentially destroying/recreating wrong resources | Keys are stable — removing one item does not affect others |
| **Flexibility** | Limited — all resources are identical except for index-based differences | More flexible — each resource can have unique attributes from the map |

**`count` example:**
```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-123456"
  instance_type = "t3.medium"
  tags = {
    Name = "web-${count.index}"
  }
}
```

**`for_each` example (real-world use case — subnets per AZ):**
```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

resource "aws_subnet" "public" {
  for_each        = toset(var.availability_zones)
  vpc_id          = aws_vpc.main.id
  cidr_block      = cidrsubnet(aws_vpc.main.cidr_block, 8, index(var.availability_zones, each.value))
  availability_zone = each.value

  tags = {
    Name = "public-subnet-${each.value}"
  }
}
```

`for_each` is preferred in production because it provides **stable resource identities** and avoids the index-shifting problem that `count` has when items are removed from the middle of a list.

---

## How do you handle drift detection in Terraform?

- **Scheduled `terraform plan`:** Run `terraform plan` periodically (via cron or CI/CD scheduled pipeline) and alert when the exit code is `2` (drift detected):
  ```bash
  terraform plan -detailed-exitcode
  # Exit code 2 = drift detected → send alert via Slack/PagerDuty
  ```
- **`terraform plan -refresh-only`:** Refreshes the state without proposing changes, useful for detecting drift without an execution plan:
  ```bash
  terraform plan -refresh-only -detailed-exitcode
  ```
- **Third-Party Tools:** Use **Spacelift**, **Env0**, or **Driftctl** for continuous drift detection with dashboards and automated reporting.
- **Prevention:** Enforce **all infrastructure changes through Terraform** (no manual console changes). Use AWS SCPs, IAM least privilege, and CloudTrail alerts to detect out-of-band modifications.

---

## What is a Terraform remote backend, and why is it important?

A **remote backend** stores Terraform state in a shared, centralized location instead of a local `terraform.tfstate` file. The most common remote backend is **S3 + DynamoDB** on AWS:

```hcl
terraform {
  backend "s3" {
    bucket         = "myorg-terraform-state"
    key            = "prod/infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:123456789:key/abcd-1234"
  }
}
```

**Why it is important:**
- **Team Collaboration:** Multiple engineers can work on the same infrastructure without overwriting each other's state.
- **State Locking:** DynamoDB prevents concurrent modifications, avoiding race conditions when multiple users run `terraform apply` simultaneously.
- **Security:** State files contain sensitive data (passwords, private IPs). Remote backends support **encryption at rest** (KMS) and **access control** (IAM policies).
- **Durability:** S3 provides versioning and long-term persistence, protecting against state corruption or accidental deletion.

---

## How do you manage multiple environments (dev, staging, prod) in Terraform?

**Approach 1 — Separate Directories (Most Common in Production):**
```
infrastructure/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   └── backend.tf     # S3 backend: key = "dev/terraform.tfstate"
├── staging/
│   ├── main.tf
│   ├── variables.tf
│   └── backend.tf     # S3 backend: key = "staging/terraform.tfstate"
└── prod/
    ├── main.tf
    ├── variables.tf
    └── backend.tf     # S3 backend: key = "prod/terraform.tfstate"
```
Each environment has its own **state file**, **variables**, and **CI/CD pipeline**, providing complete isolation.

**Approach 2 — Terraform Workspaces:**
```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace select prod
terraform apply -var-file="env/${terraform.workspace}.tfvars"
```
Workspaces share the same configuration but maintain separate state. Suitable for simpler projects but less commonly used in enterprise environments.

**Approach 3 — Single Config with `for_each`:** Use a single configuration with `for_each` to create environment-specific resources, though this makes per-environment deployment and rollback more complex.

---

## Difference between `local-exec` and `remote-exec` provisioners

| Aspect | `local-exec` | `remote-exec` |
|--------|-------------|---------------|
| **Execution Location** | Runs on the **machine where Terraform is executing** (local machine or CI agent) | Runs on the **remote resource** (e.g., inside an EC2 instance) |
| **Use Case** | Trigger webhooks, update local files, invoke external APIs | Install software, configure services, run scripts on the provisioned instance |
| **Connection Required** | No | Requires a connection block (SSH for Linux, WinRM for Windows) |
| **Example** | `command = "echo ${aws_instance.web.id} > instance_id.txt"` | `command = "sudo apt-get update && sudo apt-get install -y nginx"` |

```hcl
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = "t3.medium"

  # Runs on the local machine
  provisioner "local-exec" {
    command = "echo ${self.id} > instance_id.txt"
  }

  # Runs on the remote instance
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}
```

**Note:** Provisioners are generally discouraged in favor of **immutable infrastructure** (bake configurations into AMIs using Packer) or **configuration management tools** (Ansible, Chef). Use them sparingly.

---

## How do you safely roll back infrastructure changes after a failed deployment?

- **`terraform apply -auto-approve` with Saved Plan:** In CI/CD, generate a plan file with `terraform plan -out=tfplan`, review it, and then apply it with `terraform apply tfplan`. To rollback, run `terraform plan -out=rollback.tfplan -refresh-only` (which generates the inverse plan) and apply it.
- **State Versioning:** With S3 backend versioning enabled, roll back the state file to a previous version:
  ```bash
  aws s3 cp s3://bucket/terraform.tfstate#12 ./terraform.tfstate
  terraform plan -out=rollback.tfplan
  terraform apply rollback.tfplan
  ```
- **`terraform state mv` / `terraform state rm`:** If a specific resource failed, remove it from state and re-apply with corrected configuration.
- **Blue-Green Infrastructure:** Deploy new infrastructure alongside the old, switch traffic only after validation, and destroy the old infrastructure. If the new deployment fails, keep traffic on the old infrastructure and discard the new state.
- **Destroy and Recreate:** As a last resort, `terraform destroy` the failed environment and re-apply from a known-good configuration.

---

## Explain `terraform refresh` vs `terraform plan`

| Aspect | `terraform refresh` | `terraform plan` |
|--------|---------------------|-----------------|
| **Purpose** | Updates the **state file** with the real-world state of existing resources | Compares the **current state** against the **desired configuration** (.tf files) and proposes changes |
| **What it does** | Reads the actual attributes of cloud resources and writes them to the state file — **does not modify infrastructure** | Shows what will be **created, modified, or destroyed** to align actual state with configuration |
| **When to Use** | When external changes have been made to infrastructure and the state file is out of sync | Before every `terraform apply` to review the execution plan |
| **Usage** | `terraform refresh` (deprecated in Terraform 1.x — use `terraform apply -refresh-only`) | `terraform plan` |

**Key distinction:** `refresh` updates the **state** to match reality, while `plan` compares the **state against the code** to generate a proposed action.

---

## How do you write reusable Terraform modules?

1. **Structure the Module Directory:**
   ```
   modules/
   └── vpc/
       ├── main.tf        # Resource definitions
       ├── variables.tf   # Input variables with types, descriptions, defaults
       ├── outputs.tf     # Output values exposed to the root module
       └── versions.tf    # Provider and Terraform version constraints
   ```

2. **Define Input Variables with Types and Descriptions:**
   ```hcl
   variable "vpc_cidr" {
     description = "CIDR block for the VPC"
     type        = string
     default     = "10.0.0.0/16"
   }

   variable "environment" {
     description = "Environment name (dev, staging, prod)"
     type        = string
   }
   ```

3. **Expose Useful Outputs:**
   ```hcl
   output "vpc_id" {
     description = "The ID of the VPC"
     value       = aws_vpc.main.id
   }

   output "public_subnet_ids" {
     description = "List of public subnet IDs"
     value       = aws_subnet.public[*].id
   }
   ```

4. **Version and Publish:** Store modules in a Git repository and tag releases (e.g., `v1.0.0`). Reference them by source URL:
   ```hcl
   module "vpc" {
     source      = "git::https://github.com/myorg/terraform-modules.git//modules/vpc?ref=v1.0.0"
     vpc_cidr    = "10.0.0.0/16"
     environment = var.environment
   }
   ```

5. **Best Practices:**
   - Keep modules **focused and single-purpose** (one module per resource type or logical group)
   - Use **`count` or `for_each`** within modules for flexibility
   - Document the module with a `README.md` showing usage examples
   - Avoid hardcoding values — make everything configurable through variables
   - Add **`validation` blocks** to enforce constraints on input variables



## Existing infrastructure is there , now you want to migrate your state file to backend, without re-creating infrastucture ?
 . create s3 bucket if not exists
 . create dynamodb table ( for state locking )
 . update the terraform code ( in your local ) with the details 
 . Now execute the command. 
	terraform init -migrate-state


## Suppose your state file is stuck in lock state, but there are no running processes how do you resolve this issue ?
 . First, check the running processes are there any. Now check the infra, by running the terraform plan command.
 . With the "terraform state list" check what all are created /modified /destroyed.
 . To unlock the terraform state file 
		terraform --force-unlock <Lock-ID>
 . verify the lock is released or not 
		terraform plan

## What are the chances for state lock file in lock state.
	Ctrl +C, Crash, Network issue, CI/CD job failed.


## Suppose your terraform state file is huge in size, and is taking lot of time to apply. How do you resolve this issue ?
 . First check the size of the file and its contents.
 . reduce the modules , providers if there are any and move them to the different locations.
 . Use the data resources wherever applicable instead of creating resource blocks.
 . Split the resources into multiple workspaces.

## What will you do if you lost your terraform state file ?
 . Check the backend versioning file.
 . Check for your local copy ( if available )
 . Recover from backend backup.
 . Use terraform import options from the current infrastructure.
 . 






















