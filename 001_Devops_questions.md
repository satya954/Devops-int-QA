# 🚀 DevOps Interview Questions & Comprehensive Answers

> **A Complete Guide to DevOps Concepts, Tools, and Best Practices**
>
> Covering SDLC, CI/CD, Containerization, Kubernetes, IaC, Linux, AWS, Docker, and Jenkins

---

## 📑 Table of Contents

### DevOps Fundamentals
| # | Question | Link |
|---|----------|------|
| 1 | Importance of DevOps in SDLC | [#1️⃣ Importance of DevOps](#1️cc-what-is-the-importance-of-devops-in-the-software-development-life-cycle-sdlc) |
| 8 | Use Cases of Ansible | [#8️⃣ Use Cases of Ansible](#8️cc-what-are-the-use-cases-of-ansible) |

### CI/CD
| # | Question | Link |
|---|----------|------|
| 2 | How is CI Achieved? | [#2️⃣ How is CI Achieved](#2️cc-how-is-ci-achieved) |
| 3 | Security & Compliance in CI/CD | [#3️⃣ Security and Compliance in CICD](#3️cc-how-do-you-ensure-security-and-compliance-in-cicd) |

### Containerization & Kubernetes
| # | Question | Link |
|---|----------|------|
| 4 | Containerization in Deployments | [#4️⃣ Containerization in Deployments](#4️cc-how-does-containerization-work-in-deployments) |
| 5 | Blue-Green Deployment | [#5️⃣ Blue-Green Deployment](#5️cc-explain-blue-green-deployment) |
| 6 | Self-Healing in Kubernetes | [#6️⃣ Self-Healing in Kubernetes](#6️cc-what-is-self-healing-in-kubernetes) |
| 7 | Troubleshooting an Unreachable Pod | [#7️⃣ Troubleshooting an Unreachable Pod](#7️cc-how-would-you-troubleshoot-an-unreachable-pod) |
| 22 | Investigating Pod Failure on EKS | [#22️⃣ Investigating Pod Failure on EKS](#22️cc-if-an-application-is-deployed-to-eks-and-a-pod-fails-how-would-you-investigate-it) |

### IaC & Terraform
| # | Question | Link |
|---|----------|------|
| 9 | Infrastructure as Code (IaC) | [#9️⃣ Infrastructure as Code](#9️cc-explain-infrastructure-as-code-iac) |
| 10 | What Happens with `terraform init` | [#10️ What Happens When You Run terraform init](#10-what-happens-when-you-run-terraform-init) |

### Linux & Scripting
| # | Question | Link |
|---|----------|------|
| 11 | Linux Distributions | [#11️⃣ Linux Distributions](#11️cc-what-are-the-different-linux-distributions) |
| 12 | Checking Linux Server Performance | [#12️⃣ Checking Linux Server Performance](#12️cc-how-do-you-check-the-performance-of-a-linux-server) |
| 13 | Troubleshooting Network Issues | [#13️⃣ Troubleshooting Network Issues in Linux](#13️cc-what-commands-do-you-use-to-troubleshoot-network-issues-in-linux) |
| 14 | Bash Scripts in Projects | [#14️⃣ Bash Scripts in Projects](#14️cc-what-kind-of-bash-scripts-have-you-used-in-your-project) |

### Cloud (AWS)
| # | Question | Link |
|---|----------|------|
| 15 | AWS Services Experience | [#15️⃣ AWS Services Experience](#15️cc-what-aws-services-have-you-worked-with) |
| 16 | CloudFormation vs Terraform Usage | [#16️⃣ CloudFormation and Terraform Experience](#16️cc-have-you-used-both-cloudformation-and-terraform) |
| 17 | CloudFormation vs Terraform Differences | [#17️⃣ CloudFormation vs Terraform](#17️cc-what-is-the-difference-between-cloudformation-and-terraform-which-is-better) |
| 18 | Choosing for AWS-Only Work | [#18️⃣ Choosing for AWS-Specific Work](#18️cc-if-you-are-working-specifically-with-aws-which-would-you-choose-cloudformation-or-terraform) |

### Docker & Jenkins
| # | Question | Link |
|---|----------|------|
| 19 | Dockerfile for Node.js | [#19️⃣ Simple Dockerfile for Nodejs](#19️cc-write-a-simple-dockerfile-for-a-nodejs-application) |
| 20 | Multi-Stage Dockerfile | [#20️⃣ Multi-Stage Dockerfile](#20️cc-how-would-you-write-the-same-dockerfile-using-a-multi-stage-build) |
| 21 | Jenkins Pipeline | [#21️⃣ Jenkins Pipeline for Build and Deploy](#21️cc-can-you-create-a-jenkins-pipeline-for-building-and-deploying-the-docker-image) |

---

# 🏗️ DevOps Fundamentals

---

### 1️⃣ What is the Importance of DevOps in the Software Development Life Cycle (SDLC)?

DevOps fundamentally transforms the traditional **Software Development Life Cycle (SDLC)** by breaking down the historical silos between development and operations teams. In a conventional SDLC, developers write code and "throw it over the wall" to operations, who then handle deployment and maintenance. This handoff creates **bottlenecks, miscommunication, and delayed feedback loops**. DevOps replaces this linear model with a **collaborative, continuous cycle** where development and operations share ownership of the entire lifecycle from code commit to production monitoring.

The importance of DevOps in SDLC can be understood through several key dimensions:

* **Speed and Frequency of Deliveries:** DevOps enables organizations to release software **multiple times per day** rather than once per quarter. Continuous Integration and Continuous Deployment (CI/CD) pipelines automate the build, test, and release process, reducing lead time from weeks to minutes. Companies like Amazon deploy code every 11.7 seconds on average.
* **Quality and Reliability:** By integrating automated testing at every stage — unit tests, integration tests, security scans, and performance benchmarks — DevOps catches defects **early in the pipeline** when they are cheapest to fix. This shift-left approach dramatically reduces production incidents.
* **Faster Recovery from Failures:** DevOps promotes practices like **feature toggles, canary releases, and automated rollback** mechanisms. When a bad release reaches production, teams can recover in minutes rather than hours, minimizing customer impact.
* **Cultural Transformation:** Beyond tools, DevOps fosters a culture of **shared responsibility, blameless post-mortems, and continuous learning**. Teams collaborate across functional boundaries, leading to better decision-making and higher employee satisfaction.
* **Cost Efficiency:** Automation reduces manual effort in building, testing, and deploying infrastructure. Infrastructure as Code (IaC) enables teams to **provision and teardown environments on demand**, reducing wasted cloud spend.

In summary, DevOps is not just a set of tools — it is a **philosophy and practice** that aligns business goals with technical execution, ensuring that software delivery is fast, reliable, secure, and scalable throughout the SDLC.

---

### 8️⃣ What are the Use Cases of Ansible?

Ansible is an **agentless, open-source automation tool** that uses SSH (for Linux) or WinRM (for Windows) to manage infrastructure. Its simplicity — driven by human-readable **YAML playbooks** — makes it one of the most widely adopted configuration management and orchestration tools. Here are the primary use cases:

* **Configuration Management:** Ansible ensures that servers are configured consistently across environments. For example, you can write a playbook to install and configure Nginx, set up firewall rules, create system users, and manage cron jobs. Running the same playbook against development, staging, and production guarantees **environment parity** and eliminates "it works on my machine" problems.

* **Application Deployment:** Ansible can deploy applications by pulling the latest code from version control, building artifacts, restarting services, and validating health checks — all in a single playbook. It integrates with **rolling update strategies** to deploy with zero downtime. For instance, you can deploy a Java WAR file to a Tomcat cluster one node at a time, waiting for health checks before proceeding to the next.

* **Orchestration:** Ansible excels at coordinating complex, multi-step workflows across many machines. You can orchestrate the provisioning of a multi-tier application — launching the database server, configuring the application tier, setting up load balancers, and running database migrations — in the correct order with dependency management via **playbook roles and tags**.

* **Cloud Provisioning and Management:** With Ansible's cloud modules, you can **launch EC2 instances, create S3 buckets, manage RDS databases, and configure Auto Scaling groups** directly from playbooks. The `ec2` and `rds` modules provide idempotent operations that only make changes when the desired state differs from the actual state.

* **Patch Management and Compliance:** Ansible can automate OS patching across hundreds of servers, applying security updates during maintenance windows. Combined with compliance frameworks like **CIS benchmarks**, you can write playbooks that audit and remediate configuration drift, generating reports for regulatory audits.

* **Network Automation:** Ansible has modules for managing **Cisco, Juniper, Arista, and Palo Alto** network devices. You can push configuration changes, back up running configs, and validate network topology — all from centralized playbooks.

**Real-World Example:** A typical Ansible workflow involves defining roles (`nginx`, `app_server`, `database`), organizing them in a directory structure, and invoking them with `ansible-playbook -i inventory/production site.yml --limit webservers`. The **idempotent** nature of Ansible means you can run the same playbook repeatedly without causing unintended side effects.

---

# ⚙️ CI/CD

---

### 2️⃣ How is CI Achieved?

**Continuous Integration (CI)** is achieved by establishing an automated pipeline that integrates code changes from multiple developers into a shared repository multiple times per day. The core principle is simple: **integrate early and often** to catch integration issues before they accumulate. Here is how CI is practically achieved:

* **Version Control as the Trigger:** Every time a developer pushes code to the version control system (Git) — typically via a pull request or merge to the main branch — a **webhook** triggers the CI pipeline. Tools like Jenkins, GitLab CI, GitHub Actions, or CircleCI listen for these events and automatically kick off the build process.

* **Automated Build Process:** The CI server pulls the latest code, installs dependencies, and compiles the application. For a Java project, this might mean running `mvn clean package`; for a Node.js project, `npm install && npm run build`. The build step produces **artifacts** (JAR files, Docker images, compiled binaries) that are stored in an artifact repository like **Nexus, Artifactory, or AWS S3** for downstream stages.

* **Automated Testing Suite:** After a successful build, the pipeline runs a comprehensive suite of automated tests:
    * **Unit Tests** — validate individual functions and methods (JUnit, Jest, pytest)
    * **Integration Tests** — verify interactions between modules and external services (database, API)
    * **Static Code Analysis** — tools like **SonarQube, ESLint, or Checkstyle** scan for code smells, security vulnerabilities, and style violations
    * **Security Scans** — SAST tools like **Snyk, OWASP Dependency-Check** identify vulnerable dependencies

* **Feedback Loop:** If any test fails or quality gate is not met, the pipeline **fails fast** and notifies the developer via email, Slack, or chatOps. The build badge on the pull request turns red, preventing merge until issues are resolved. This immediate feedback is what makes CI valuable — developers fix broken builds within minutes rather than discovering conflicts days later.

* **Artifact Versioning and Documentation:** Successful builds are tagged with version numbers (following **Semantic Versioning**) and metadata (commit hash, build timestamp, test coverage percentage). This traceability ensures that every artifact in production can be traced back to the exact commit that produced it.

**Practical Example:** In a typical GitHub Actions CI pipeline, a `.github/workflows/ci.yml` file defines the workflow. On every push to `main` or pull request, the workflow checks out code, caches dependencies (`actions/cache`), runs `npm test`, runs SonarQube analysis, and only on success, builds and pushes a Docker image to Amazon ECR. The entire pipeline completes in **under 5 minutes**, giving developers rapid feedback on every change.

---

### 3️⃣ How do you Ensure Security and Compliance in CI/CD?

Embedding security and compliance into CI/CD — often called **DevSecOps** — means that security is not an afterthought but a **built-in requirement** at every pipeline stage. Here is a comprehensive approach:

* **Shift-Left Security Testing:** Security checks are moved as early as possible in the pipeline:
    * **SAST (Static Application Security Testing):** Tools like **SonarQube, Checkmarx, or Snyk Code** analyze source code for vulnerabilities (SQL injection, XSS, hardcoded secrets) before the code is even compiled.
    * **SCA (Software Composition Analysis):** Tools like **Snyk, Dependency-Check, or WhiteSource** scan third-party dependencies for known CVEs. The pipeline can be configured to **fail the build** if a critical or high severity vulnerability is found.
    * **Secrets Detection:** Tools like **GitGuardian, TruffleHog, or GitLeaks** scan commits and repository history for accidentally committed credentials, API keys, or certificates.

* **Infrastructure Security Scanning:** When using Infrastructure as Code (Terraform, CloudFormation), tools like **Checkov, tfsec, or Terrascan** analyze IaC templates for misconfigurations — such as S3 buckets open to the public, overly permissive IAM roles, or unencrypted storage. These scans run as a **pipeline gate** before infrastructure is provisioned.

* **Container Security:** Docker images are scanned for vulnerabilities using tools like **Trivy, Clair, or Aqua Security**. The pipeline should enforce policies such as:
    * Running containers as **non-root users**
    * Using **minimal base images** (Distroless, Alpine)
    * Signing images with **Cosign or Docker Content Trust**
    * Blocking images with critical CVEs from being deployed to production

* **Compliance as Code:** Compliance requirements (SOC2, HIPAA, PCI-DSS) are encoded as **automated policy checks**. Tools like **OPA (Open Policy Agent) or HashiCorp Sentinel** evaluate infrastructure configurations and pipeline actions against predefined policies. For example, a policy can enforce that "all production RDS instances must be Multi-AZ and encrypted at rest."

* **Auditing and Traceability:** Every pipeline run is **logged and immutable**. CI/CD platforms maintain audit trails showing who triggered the build, what code was deployed, which tests passed, and who approved the deployment. This audit trail is essential for **regulatory compliance** and incident investigation.

* **Access Control and Least Privilege:** Pipeline credentials are managed through **secret management tools** (AWS Secrets Manager, HashiCorp Vault, GitHub Secrets) — never hardcoded. Service accounts used by the pipeline follow the **principle of least privilege**, having only the permissions necessary for their specific stage.

* **Environment Segregation and Approval Gates:** Deployments to production require **manual approval gates** and are executed through a **separate, more restrictive pipeline** than staging. This ensures that only validated, approved code reaches production, and that production deployments are reviewed by authorized personnel.

**Real-World Pipeline:** A production-grade CI/CD pipeline might look like: `Code Commit → SAST Scan → Dependency Scan → Unit Tests → Build → Container Scan → Deploy to Staging → Integration Tests → Security Compliance Check → Manual Approval → Deploy to Production → Smoke Tests → Monitor`.

---

# 🐳 Containerization & Kubernetes

---

### 4️⃣ How does Containerization Work in Deployments?

Containerization packages an application and all its **dependencies** — runtime libraries, configuration files, system tools — into a single, portable unit called a **container**. Unlike virtual machines that include a full guest operating system, containers share the **host kernel** while maintaining isolated user spaces through Linux features like **namespaces** (process, network, mount isolation) and **cgroups** (resource limits).

Here is how containerization works in the deployment lifecycle:

* **Image Creation:** A **Dockerfile** defines the container image as a series of layers. Each instruction (`FROM`, `RUN`, `COPY`, `CMD`) creates a read-only layer. Docker's **layer caching** means that if you modify only the application code, Docker rebuilds only the affected layers, making builds fast. The final image is a complete, immutable artifact that runs identically on any host with a container runtime.

* **Image Registry:** Built images are pushed to a **container registry** (Docker Hub, Amazon ECR, Google Container Registry, Harbor). The registry stores images tagged by version (`myapp:v1.2.3`, `myapp:latest`), enabling teams to pull the exact same image across development, staging, and production environments.

* **Orchestration and Scheduling:** In production, containers are rarely run standalone. **Kubernetes** acts as the orchestration layer, scheduling containers (called **Pods**) across a cluster of worker nodes. Kubernetes handles:
    * **Scheduling:** Placing pods on nodes with sufficient CPU and memory resources
    * **Service Discovery:** Assigning stable network endpoints (ClusterIP, LoadBalancer) to dynamically scaling pods
    * **Load Balancing:** Distributing traffic across healthy pod replicas
    * **Self-Healing:** Restarting failed containers and replacing unhealthy pods automatically

* **Deployment Strategies:** Containerization enables sophisticated deployment strategies:
    * **Rolling Updates:** Kubernetes gradually replaces old pods with new ones, ensuring **zero downtime**. It creates new pods, waits for readiness probes to pass, then terminates old pods one by one.
    * **Blue-Green:** Two identical environments run side by side; traffic is switched from the old (blue) to the new (green) environment instantly via load balancer configuration.
    * **Canary:** A small percentage of traffic (e.g., 5%) is routed to the new version. If metrics look good, the percentage is gradually increased until the new version handles 100% of traffic.

* **Scaling:** Containers scale horizontally by adding or removing replicas. Kubernetes **Horizontal Pod Autoscaler (HPA)** monitors CPU/memory utilization (or custom metrics via Prometheus) and adjusts the number of pod replicas automatically. This elasticity is far more granular and faster than scaling virtual machines.

* **Configuration and Secrets Management:** Containers receive runtime configuration through **environment variables, ConfigMaps, and Secrets**. This separation of configuration from the image means the same container image can be deployed to multiple environments (dev, staging, prod) with different database endpoints, API keys, or feature flags.

**Real-World Example:** A microservices application might consist of 15 services, each containerized and deployed as a Kubernetes Deployment with 3 replicas. The `kubectl apply -f deployment.yaml` command updates the cluster configuration. Kubernetes ensures that the new version of each service is deployed with zero downtime, health-checked, and load-balanced — all without manual intervention on individual servers.

---

### 5️⃣ Explain Blue-Green Deployment.

**Blue-Green Deployment** is a zero-downtime release strategy that uses **two identical production environments** — called "Blue" (currently live) and "Green" (standby) — to deploy new versions of an application with minimal risk and instant rollback capability.

**How It Works — Step by Step:**

1. **Blue Environment is Live:** The current stable version of the application is running in the Blue environment, serving all production traffic through a load balancer or routing layer.
2. **Green Environment is Provisioned:** An identical Green environment is already running (or is spun up on demand). The **new version** of the application is deployed to Green while Blue continues to serve users uninterrupted.
3. **Validation on Green:** The new version undergoes **integration testing, smoke testing, and performance validation** in the Green environment using production-like data. Automated health checks verify that all services are responding correctly.
4. **Traffic Switch:** Once validation passes, the **load balancer or DNS** is reconfigured to route 100% of traffic from Blue to Green. This switch is **instantaneous** — typically a single configuration change — meaning users experience no downtime.
5. **Observation Period:** After the switch, the team monitors Green closely for errors, performance degradation, or unexpected behavior. Metrics dashboards and log aggregation tools are watched intensively.
6. **Rollback (if needed):** If issues are detected, traffic is **immediately switched back to Blue** — which still runs the old, stable version. No redeployment is needed since Blue was never torn down.
7. **Decommission or Keep Warm:** Once the new version is confirmed stable, the Blue environment is either **decommissioned** to save costs or kept warm as the new standby for the next release.

**Advantages:**

* **Zero Downtime:** Users never see an outage during deployment since one environment is always live.
* **Instant Rollback:** Reverting to the previous version is as simple as flipping a switch — no need to rebuild or redeploy.
* **Full Production Testing:** The new version runs in an identical production environment before receiving real traffic, reducing surprises.
* **Reduced Risk:** Teams can validate thoroughly before any user-facing change.

**Disadvantages:**

* **Infrastructure Cost:** Running two full production environments simultaneously **doubles the infrastructure cost** during the deployment window.
* **Data Migration Complexity:** If the new version requires database schema changes, you need a strategy for **backward-compatible migrations** (e.g., adding columns before dropping old ones) since both environments share the same database.
* **Session Management:** User sessions may need to be handled carefully during the switch to avoid mid-request disruption.

**Real-World Example:** In an AWS setup, Blue and Green can be two separate **ECS Services or Kubernetes namespaces**. The traffic switch is handled by an **AWS Application Load Balancer (ALB)** target group update or an **Amazon Route 53** routing policy change. Tools like **AWS CodeDeploy** natively support Blue-Green deployment, automating the provisioning, testing, and traffic-switching steps.

---

### 6️⃣ What is Self-Healing in Kubernetes?

**Self-healing** is one of Kubernetes's core capabilities — the ability to **automatically detect and recover** from failures without human intervention. Kubernetes continuously monitors the state of the cluster and takes corrective action whenever the actual state deviates from the desired state declared in manifests.

**Key Self-Healing Mechanisms:**

* **Restarting Failed Containers:** If a container inside a Pod crashes (exits with a non-zero exit code), the **kubelet** on the worker node automatically restarts it. Kubernetes respects the Pod's **restartPolicy** (`Always`, `OnFailure`, `Never`) and back-off restart limits to prevent crash loops from overwhelming the node. For example, if a Java application's JVM runs out of memory and crashes, Kubernetes restarts the container immediately.

* **Replacing and Rescheduling Failed Pods:** If an entire Pod becomes unreachable — due to a node failure, network partition, or kernel panic — the **kube-controller-manager** detects that the actual number of running pods is less than the desired replicas defined in the Deployment. It creates replacement Pods and **schedules them on healthy nodes**. This is why Deployments specify `replicas: 3` — if one pod dies, Kubernetes ensures two more are running and spawns a third.

* **Killing Unhealthy Pods:** Kubernetes uses **health probes** to determine if an application is functioning correctly:
    * **Liveness Probe:** Checks if the container is running. If the probe fails (e.g., HTTP endpoint returns 500, or TCP port is not responding), Kubernetes **kills and restarts** the container. This is essential for applications that hang or dead-lock without crashing.
    * **Readiness Probe:** Checks if the container is ready to accept traffic. If this fails, Kubernetes **removes the Pod from the Service's endpoint list** so that no user traffic is routed to it. The Pod remains running but is effectively quarantined until it recovers.
    * **Startup Probe:** For slow-starting applications, this probe prevents Kubernetes from killing a container that is still initializing. It gives the application a grace period before liveness checks begin.

* **Node Failure Detection:** Kubernetes monitors node health through the **node-status** subresource. If a node stops sending heartbeats (kubelet is not reporting within the `node-monitor-grace-period`, default 40 seconds), the **Node Problem Detector** marks the node as `NotReady`. The **disruption controller** then evicts Pods from the failed node and reschedules them on healthy nodes.

* **Horizontal and Vertical Scaling:** While not strictly self-healing, **auto-scaling** complements it. The Horizontal Pod Autoscaler (HPA) adds replicas under high load, and the Cluster Autoscaler provisions new nodes when existing nodes are full. This ensures that the cluster can recover from overload conditions.

**Real-World Example:** Imagine a Kubernetes cluster running an e-commerce application. During a Black Friday sale, one of the payment service Pods starts returning 500 errors due to a memory leak. The **liveness probe** (an HTTP GET to `/health`) detects the failure after 3 consecutive failures and restarts the container. Meanwhile, the **readiness probe** ensures that any partially-started pods do not receive traffic until they are fully initialized. The user experience is seamless — failed requests are retried against healthy replicas, and the self-healing process completes in seconds without any operator involvement.

---

### 7️⃣ How would you Troubleshoot an Unreachable Pod?

Troubleshooting an unreachable Pod requires a **systematic, layered approach** — moving from the Pod itself outward through the networking stack. Here is a step-by-step methodology:

**Step 1 — Check Pod Status and Events:**
```bash
kubectl get pod <pod-name> -n <namespace> -o wide
kubectl describe pod <pod-name> -n <namespace>
```
Look for the Pod's **Phase** (Pending, Running, Failed, Succeeded), **RESTARTS count**, and **Events** section. Common issues:
* `ImagePullBackOff` — container image cannot be pulled (wrong image name, missing registry credentials)
* `CrashLoopBackOff` — container starts but crashes repeatedly
* `Pending` — insufficient resources or no node matches scheduling constraints
* Check **node affinity/anti-affinity** rules, **taints and tolerations**, and **resource requests/limits**

**Step 2 — Check Container Logs:**
```bash
kubectl logs <pod-name> -n <namespace> --tail=100
kubectl logs <pod-name> -n <namespace> --previous  # logs from the previous crashed container
kubectl logs <pod-name> -n <namespace> -c <container-name>  # for multi-container pods
```
Application-level errors (connection refused, null pointer exceptions, missing environment variables) appear in logs. This is often the **fastest way to identify the root cause**.

**Step 3 — Verify Readiness and Liveness Probes:**
```bash
kubectl describe pod <pod-name> -n <namespace> | grep -A5 "Liveness\|Readiness"
```
If probes are misconfigured — pointing to a non-existent endpoint, or having too-short initial delays — the Pod may be marked as unhealthy and removed from service endpoints. Temporarily **remove probes** to test if they are causing the issue.

**Step 4 — Check Network Connectivity:**
```bash
# Exec into the pod and test connectivity
kubectl exec -it <pod-name> -n <namespace> -- sh

# From inside the pod:
ping <target-service>
curl -v http://<service-name>:<port>/health
nslookup <service-name>
cat /etc/resolv.conf
```
Verify that the Pod can resolve **DNS names** (CoreDNS issues are common), that **security groups and Network Policies** allow traffic, and that the **Service endpoints** are correctly configured.

**Step 5 — Check Service and Endpoint Configuration:**
```bash
kubectl get svc -n <namespace>
kubectl get endpoints <service-name> -n <namespace>
kubectl get svc <service-name> -n <namespace> -o yaml
```
Ensure the Service's **selector labels** match the Pod's labels. If the Endpoints list is empty, the Service cannot route traffic to any Pod. Common issues include **label mismatch**, **wrong port mapping**, or **readiness probe failures** removing the Pod from endpoints.

**Step 6 — Check Network Policies and CNI:**
```bash
kubectl get networkpolicy -n <namespace>
kubectl get nodes -o wide  # check node IPs and CNI plugin
```
Network Policies can **block ingress or egress traffic** to specific Pods. Check if a policy is denying traffic from the source. Also verify the **CNI plugin** (Calico, Flannel, AWS VPC CNI) is functioning correctly on the node.

**Step 7 — Check Node Health and Resources:**
```bash
kubectl describe node <node-name>
kubectl top node
kubectl top pod -n <namespace>
```
A node may be **memory- or CPU-pressure**, causing the kubelet to evict Pods or become unresponsive. Check for `DiskPressure`, `MemoryPressure`, or `PIDPressure` conditions.

**Step 8 — Check Ingress and Load Balancer:**
If the Pod is reachable internally but not from outside the cluster, check the **Ingress resource, ALB/NLB configuration, and target group health checks**. Mismatches between the Ingress path rules and the application's actual routes are a common cause.

---

### 22️⃣ If an Application is Deployed to EKS and a Pod Fails, how would you Investigate it?

Investigating a pod failure on **Amazon EKS (Elastic Kubernetes Service)** follows the general Kubernetes troubleshooting approach but with AWS-specific tools and considerations:

**Step 1 — Identify the Failed Pod:**
```bash
kubectl get pods -n <namespace> --field-selector=status.phase!=Running
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```
Check the Pod's **status, restart count, and reasons** (Error, OOMKilled, CrashLoopBackOff, ImagePullBackOff).

**Step 2 — Examine Pod Details and Logs:**
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --tail=200
kubectl logs <pod-name> -n <namespace> --previous
```
Look at the **Events** section for scheduling failures, volume mount issues, or probe failures. Application logs reveal runtime errors, connection issues, and missing configuration.

**Step 3 — Check EKS Node Group Health:**
```bash
kubectl describe node <node-name>
kubectl get nodes -o wide
```
In the **AWS Console**, navigate to EC2 → Auto Scaling Groups to verify that the EKS node group has healthy instances. Check for **instance termination events**, **AMR issues**, or **InsufficientInstanceCapacity** errors that prevent new nodes from launching.

**Step 4 — Verify IAM Roles and Permissions:**
EKS uses **IAM Roles for Service Accounts (IRSA)**. If the Pod needs to access AWS services (S3, DynamoDB, Secrets Manager), verify:
```bash
kubectl describe serviceaccount <sa-name> -n <namespace>
```
Check that the **annotated IAM role** exists and has the necessary permissions. Use **CloudTrail** to look for `AccessDenied` events. Misconfigured IRSA is one of the most common causes of EKS pod failures.

**Step 5 — Check VPC Networking:**
```bash
kubectl exec -it <pod-name> -n <namespace> -- curl <aws-service-endpoint>
```
Verify **VPC CNI plugin** health, **security group rules** on node instances, **NAT Gateway** availability for pods in private subnets, and **route tables**. EKS pods get IPs from the VPC subnet — if the subnet is out of IP addresses, new pods cannot be scheduled (`Unable to allocate IP address`).

**Step 6 — Inspect AWS CloudWatch and EKS Control Plane Logs:**
```bash
aws logs filter-log-events --log-group-name /aws/eks/<cluster-name>/cluster
```
The EKS control plane logs (enabled in AWS) reveal **API server errors, authentication failures, and RBAC denials**. CloudWatch Container Insights provides aggregated pod and node metrics.

**Step 7 — Check ECR Image Pull Permissions:**
If the failure is `ImagePullBackOff` or `ImagePullErr`, verify:
* The **ECR repository** exists and the image tag is correct
* The node's IAM role has `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`, and `ecr:BatchCheckLayerAvailability` permissions
* The **imagePullSecrets** in the Pod spec reference a valid secret

**Step 8 — Verify Storage (EBS/EFS):**
If the Pod uses **EBS CSI or EFS** volumes, check:
```bash
kubectl get pv
kubectl get pvc -n <namespace>
```
In AWS Console, verify that EBS volumes are in `available` or `in-use` state, and that the **subnets and security groups** allow attachment. Volume provisioning failures are common when the EBS CSI driver IAM role lacks permissions.

**Step 9 — Check for Resource Quotas and LimitRanges:**
```bash
kubectl get resourcequota -n <namespace>
kubectl get limitrange -n <namespace>
```
Namespace-level **ResourceQuotas** can prevent Pod scheduling if CPU/memory limits are exhausted. **LimitRanges** can reject Pods with requests outside the allowed range.

**Step 10 — AWS-Specific Tools:**
* **AWS EKS Anywhere / eksctl** for cluster diagnostics
* **AWS Fault Injection Simulator (FIS)** for chaos testing
* **Amazon Managed Prometheus** and **Grafana** for metrics visualization
* **AWS X-Ray** for distributed tracing across microservices

---

# 🏛️ Infrastructure as Code (IaC) & Terraform

---

### 9️⃣ Explain Infrastructure as Code (IaC).

**Infrastructure as Code (IaC)** is the practice of managing and provisioning infrastructure — servers, networks, databases, load balancers — through **machine-readable definition files** rather than manual configuration or interactive configuration tools. Instead of clicking through a cloud console to create resources, you write code that describes the **desired state** of your infrastructure, and the IaC tool ensures reality matches that description.

**Core Principles of IaC:**

* **Declarative vs. Imperative:** Most modern IaC tools (Terraform, CloudFormation) are **declarative** — you define what the infrastructure should look like (e.g., "an EC2 instance with t3.medium type in us-east-1"), and the tool figures out how to create or update it. This is different from imperative scripting where you specify each step (launch instance, tag it, attach security group).

* **Idempotency:** Running the same IaC configuration multiple times produces the **same result**. If the infrastructure already matches the desired state, no changes are made. This eliminates the risk of duplicate resources or configuration drift.

* **Version Control:** IaC files are stored in **Git repositories**, enabling the same collaboration workflows used for application code — pull requests, code reviews, branching strategies, and audit trails. Every change to infrastructure is **tracked, reviewed, and reversible**.

* **Reproducibility:** IaC enables you to recreate an entire environment from scratch. If a production environment is corrupted, you can destroy and rebuild it from code in minutes. This is essential for **disaster recovery** and for creating identical **development, staging, and production** environments.

* **Automation and CI/CD Integration:** IaC pipelines integrate with CI/CD systems. When infrastructure code is merged, automated pipelines run `terraform plan` for validation, `terraform apply` for deployment, and **policy checks** for compliance — all without human intervention.

**Popular IaC Tools:**

| Tool | Provider | Language | Key Strength |
|------|----------|----------|-------------|
| **Terraform** | HashiCorp (Multi-cloud) | HCL | Provider-agnostic, state management, large ecosystem |
| **AWS CloudFormation** | AWS (AWS-only) | YAML/JSON | Deep AWS integration, native stack management |
| **Pulumi** | Multi-cloud | TypeScript, Python, Go | Full programming language support |
| **Ansible** | Red Hat | YAML | Agentless, configuration management focus |

**Benefits:**

* **Speed:** Provisioning infrastructure via code is **orders of magnitude faster** than manual setup. A complex multi-tier environment that took days to set up manually can be deployed in minutes.
* **Consistency:** Eliminates **configuration drift** — the gradual divergence between environments caused by manual changes. Every environment is built from the same codebase.
* **Collaboration:** Infrastructure changes go through **pull requests and code reviews**, bringing the same quality gates applied to application code.
* **Cost Management:** IaC makes infrastructure **visible and quantifiable**. You can review cost implications in code before deploying, and teardown unused resources as easily as deleting a file.
* **Compliance:** Infrastructure configurations can be **automatically validated** against security policies (e.g., "no publicly accessible S3 buckets") before deployment.

**Real-World Example:** A Terraform project might have a directory structure with `modules/` for reusable components (VPC, EKS, RDS), `environments/dev/` and `environments/prod/` for environment-specific variables, and a CI/CD pipeline that runs `terraform plan` on every pull request and `terraform apply` on merge to main — with the state stored in a **centralized S3 backend with DynamoDB locking**.

---

### 10 What Happens When You Run `terraform init`?

The `terraform init` command is the **first command** you run in any new Terraform working directory (or after pulling changes that modify provider or module requirements). It initializes the working directory by downloading and installing all the dependencies needed to manage the infrastructure. Here is exactly what happens:

**Step 1 — Backend Configuration:**
Terraform reads the `backend` block in the configuration (e.g., S3, Azure Blob, GCS, or local). If using a **remote backend**, Terraform initializes the connection to the state storage:
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locking"
    encrypt        = true
  }
}
```
For an S3 backend, Terraform verifies that the **bucket exists**, the IAM user has permissions, and initializes **state locking** via DynamoDB to prevent concurrent modifications.

**Step 2 — Provider Installation:**
Terraform scans all configuration files for `required_providers` and downloads the specified provider plugins:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}
```
Providers are downloaded from the **Terraform Registry** (or a mirror/enterprise registry) and installed in the `.terraform/providers/` directory. Each provider is a **compiled binary plugin** that speaks Terraform's protocol and knows how to create, read, update, and delete resources for that cloud/platform.

**Step 3 — Module Installation:**
Terraform resolves and downloads any **child modules** referenced in the configuration:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  # ...
}
```
Modules are downloaded from the **Terraform Registry**, Git repositories, or local paths and stored in `.terraform/modules/`. Terraform builds a **module tree** showing the dependency hierarchy.

**Step 4 — Lock File Generation:**
Terraform creates or updates the `.terraform.lock.hcl` file, which records the **exact versions and hashes** of all installed providers and modules. This lock file ensures that every team member and CI/CD pipeline uses the **same provider versions**, preventing subtle differences caused by automatic version upgrades. The lock file should be **committed to version control**.

**Step 5 — Validation:**
Terraform performs basic validation of the configuration structure, checking that:
* Required providers are present
* Module sources are accessible
* Backend configuration is valid
* No syntax errors in the HCL files

**Output:**
On success, `terraform init` outputs a summary showing which providers were installed, which modules were downloaded, and confirms that the backend is configured. The working directory is now ready for `terraform plan` and `terraform apply`.

**Important Notes:**
* Run `terraform init` **every time** you clone a new Terraform repository or pull changes that modify provider/module requirements
* Use `-upgrade` flag to allow provider version upgrades within the constraints of your version constraints
* Use `-reconfigure` to switch backend configurations (e.g., changing the S3 bucket)
* Use `-migrate-state` when changing backend types and you want to migrate existing state

---

# 🐧 Linux & Scripting

---

### 11️⃣ What are the Different Linux Distributions?

Linux distributions (distros) are complete operating systems built around the **Linux kernel** combined with system utilities, package managers, and default software. They differ in their package management, default desktop environments, release models, and target audiences. Here are the major families:

**Debian-Based Distributions:**

| Distribution | Package Manager | Key Characteristics |
|-------------|-----------------|---------------------|
| **Debian** | `apt` / `.deb` | The parent of many distros; known for extreme stability, large package repository, and strict free-software principles. Release cycle is when ready (approximately every 2 years). |
| **Ubuntu** | `apt` / `.deb` | Most popular desktop and server distro. Based on Debian. Offers **LTS (Long Term Support)** releases every 2 years with 5 years of updates. Backed by Canonical. Widely used in cloud and development environments. |
| **Linux Mint** | `apt` / `.deb` | Desktop-focused, based on Ubuntu. Known for user-friendliness and out-of-the-box experience with multimedia codecs pre-installed. |
| **Kali Linux** | `apt` / `.deb` | Specialized for **penetration testing and security auditing**. Comes pre-loaded with hundreds of security tools (Nmap, Metasploit, Wireshark). |

**Red Hat-Based Distributions:**

| Distribution | Package Manager | Key Characteristics |
|-------------|-----------------|---------------------|
| **RHEL (Red Hat Enterprise Linux)** | `dnf` / `yum` / `.rpm` | Commercial, enterprise-grade. Known for **stability, security, and long-term support** (10 years per release). Used in corporate environments worldwide. Requires subscription. |
| **CentOS** | `dnf` / `yum` / `.rpm` | Was a free RHEL rebuild (binary-compatible). **CentOS Linux was discontinued** in 2021; replaced by CentOS Stream (a rolling preview of RHEL). |
| **Rocky Linux / AlmaLinux** | `dnf` / `yum` / `.rpm` | Community-driven RHEL clones created after CentOS Linux was discontinued. **Binary-compatible with RHEL**, no subscription required. Growing rapidly as enterprise alternatives. |
| **Fedora** | `dnf` / `.rpm` | Upstream for RHEL. Features cutting-edge software, shorter release cycle (6 months). Sponsored by Red Hat. Good for developers who want the latest tools. |

**Other Notable Distributions:**

| Distribution | Base | Key Characteristics |
|-------------|------|---------------------|
| **SUSE / openSUSE** | Independent | Enterprise (SUSE Linux Enterprise) and community (openSUSE). Known for **YaST** configuration tool and strong enterprise support in Europe. |
| **Arch Linux** | Independent | Rolling release, minimal base, **user-assembles** their system. Famous for the Arch Wiki (one of the best Linux documentation resources). Used by enthusiasts. |
| **Alpine Linux** | Independent | **Extremely lightweight** (~5MB base image). Uses `musl libc` and `busybox`. The default base image for many Docker containers due to its small attack surface. |
| **Amazon Linux 2/2023** | RHEL-derived | AWS-optimized. Comes with **Graviton** support, pre-tuned for AWS services. Free for EC2 instances. Amazon Linux 2023 uses a rolling release model. |

**Choosing a Distribution:**
* **Server/Cloud:** Ubuntu LTS, RHEL, Rocky Linux, Amazon Linux 2
* **Desktop:** Ubuntu, Fedora, Linux Mint
* **Containers:** Alpine Linux, Distroless (Google), Ubuntu Minimal
* **Security:** Kali Linux, Parrot OS
* **Learning:** Ubuntu, Fedora, Arch Linux

---

### 12️⃣ How do you Check the Performance of a Linux Server?

Monitoring Linux server performance requires checking **multiple resource dimensions** — CPU, memory, disk, network, and I/O. Here is a comprehensive toolkit:

**CPU Monitoring:**

```bash
# Real-time CPU usage per core
top
htop  # more user-friendly alternative

# CPU usage over time (1-second intervals)
mpstat 1 5

# Detailed per-core statistics
vmstat 1 5

# Identify top CPU-consuming processes
ps aux --sort=-%cpu | head -20
```

* **`top`** shows overall CPU usage (`us` = user, `sy` = system, `id` = idle, `wa` = I/O wait). High `wa` indicates I/O bottleneck, not CPU.
* **`mpstat`** (from `sysstat` package) provides per-CPU breakdown. Look for CPUs consistently above 90% utilization.

**Memory Monitoring:**

```bash
# Human-readable memory summary
free -h

# Detailed memory information
cat /proc/meminfo

# Memory usage per process
ps aux --sort=-%mem | head -20

# Check for swap usage (swap indicates memory pressure)
swapon --show
vmstat -s | grep swap
```

* Key metric: **available memory** (not just free). Linux uses unused memory for disk caching, so low "free" does not mean a problem. Look at the `available` column in `free -h`.
* **Swap usage** indicates the system is under memory pressure. High swap I/O degrades performance significantly.

**Disk Usage and I/O:**

```bash
# Disk space usage
df -h

# Inode usage (running out of inodes prevents file creation even with free space)
df -i

# I/O statistics — identify slow disks
iostat -x 1 5

# Real-time I/O by process
iotop

# Find large files/directories
du -sh /* | sort -rh | head -20
```

* In `iostat`, look at **`%util`** (disk utilization — above 90% is a bottleneck) and **`await`** (average I/O wait time in milliseconds — above 20ms indicates slow disks).
* **`iotop`** shows which processes are generating the most disk I/O.

**Network Monitoring:**

```bash
# Network interface statistics
ifconfig
ip addr show

# Network I/O in real-time
nload
iftop

# Check for network errors (dropped packets, CRC errors)
netstat -i
cat /proc/net/dev

# Connection states
ss -s
netstat -an | awk '{print $6}' | sort | uniq -c | sort -rn
```

* **Dropped packets** and **CRC errors** indicate network hardware or configuration issues.
* High number of **TIME_WAIT** connections may indicate a connection leak or DDoS attack.

**System Load:**

```bash
# Load average (1, 5, 15 minute)
uptime
cat /proc/loadavg

# System-wide statistics
sar -u 1 5  # CPU statistics over time (from sysstat)
sar -r 1 5  # Memory statistics
sar -b 1 5  # I/O and transfer rates
```

* **Load average** should be compared to the number of CPU cores. A load of 4.0 on a 4-core system means the system is fully utilized. Sustained load above the number of cores indicates overload.

**Comprehensive Tools:**

```bash
# All-in-one system monitor
dstat

# Resource monitoring with historical data
sysstat  # provides sar, iostat, mpstat

# Modern system overview
btop  # colorful, interactive resource monitor
```

**Production Monitoring Stack:**
In production environments, command-line tools are complemented by **continuous monitoring** using Prometheus (metrics collection), Grafana (visualization), and Node Exporter (system metrics exporter). Alerts are configured for thresholds like CPU > 85% for 5 minutes, memory available < 10%, disk usage > 90%, and load average > 2x CPU cores.

---

### 13️⃣ What Commands do you Use to Troubleshoot Network Issues in Linux?

Network troubleshooting in Linux requires a **layered approach** — from physical connectivity up through DNS and application-level connectivity. Here is the essential toolkit organized by troubleshooting scenario:

**Basic Connectivity:**

```bash
# Test reachability of a host
ping -c 4 <hostname-or-IP>

# Check the route to a destination (shows each hop)
traceroute <hostname>
tracepath <hostname>  # does not require root

# Check DNS resolution
nslookup <hostname>
dig <hostname>
dig +trace <hostname>  # full DNS resolution chain
host <hostname>
```

* **`ping`** tests Layer 3 (ICMP) connectivity. If ping fails but the host is reachable, ICMP may be blocked by a firewall.
* **`traceroute`** shows the path packets take, helping identify **where along the route** connectivity breaks.

**Network Configuration:**

```bash
# View IP addresses and interfaces
ip addr show
ip link show

# View routing table
ip route show
route -n

# View DNS configuration
cat /etc/resolv.conf
cat /etc/hosts

# View network interface details
ip -s link show
ethtool eth0
```

**Port and Service Testing:**

```bash
# Test if a specific port is reachable
nc -zv <hostname> <port>
telnet <hostname> <port>

# Check which ports are listening on the local machine
ss -tlnp
netstat -tlnp

# Full connection state summary
ss -s
netstat -an

# Check for specific connection issues
ss -tnp state established '( dport = :80 or dport = :443 )'
```

* **`ss`** (socket statistics) is the modern replacement for `netstat`. It's faster and shows more detailed TCP state information.
* **`nc -zv`** (netcat) is the quickest way to test if a remote port is open and accepting connections.

**Firewall and Security:**

```bash
# Check iptables rules
iptables -L -n -v
iptables -L -n -v -t nat  # NAT rules

# Check nftables (modern replacement for iptables)
nft list ruleset

# Check ufw (Uncomplicated Firewall — Ubuntu)
ufw status verbose

# Check firewalld (RHEL/CentOS)
firewall-cmd --list-all
```

**Advanced Diagnostics:**

```bash
# Capture network traffic
tcpdump -i eth0 port 80 -w capture.pcap
tcpdump -i any host <IP> and port <port>

# Analyze packet capture
tshark -r capture.pcap
tshark -i eth0 port 443

# Check for ARP issues
arp -a
ip neigh show

# Check socket statistics (connection resets, retransmissions)
netstat -s | grep -i retrans
ss -i

# Check MTU issues (packet fragmentation)
ping -M do -s 1472 <hostname>
```

**Real-World Troubleshooting Scenarios:**

* **Application cannot connect to database:**
    ```bash
    nc -zv db-host 5432          # is the port reachable?
    curl telnet://db-host/5432   # alternative port test
    ss -tnp | grep 5432          # is anything listening locally?
    ```

* **DNS resolution failure:**
    ```bash
    nslookup google.com          # basic DNS test
    dig @8.8.8.8 myapp.internal  # test against specific DNS server
    cat /etc/resolv.conf         # check configured DNS servers
    systemd-resolve --status     # check systemd-resolved status
    ```

* **High latency / packet loss:**
    ```bash
    ping -c 100 <hostname>       # check packet loss percentage
    mtr <hostname>               # combines ping + traceroute with statistics
    ```

* **Connection refused vs. connection timeout:**
    * **Connection refused** — a host is reachable but nothing is listening on the port (service is down or wrong port)
    * **Connection timeout** — packets are being dropped somewhere (firewall, routing issue, or host is down)

---

### 14️⃣ What kind of Bash Scripts have you Used in your Project?

Bash scripts are the **glue** that automates repetitive operational tasks in DevOps projects. Here are the categories of scripts commonly used, with practical examples:

**1. Log Rotation and Cleanup:**
```bash
#!/bin/bash
# Rotate and compress application logs older than 7 days
LOG_DIR="/var/log/myapp"
find "$LOG_DIR" -name "*.log" -mtime +7 -exec gzip {} \;
find "$LOG_DIR" -name "*.log.gz" -mtime +30 -delete
echo "$(date): Log rotation completed" >> /var/log/maintenance.log
```
This script runs via **cron** (`0 2 * * *`) to compress logs older than 7 days and delete compressed logs older than 30 days, preventing disk space exhaustion.

**2. Health Check and Auto-Restart:**
```bash
#!/bin/bash
SERVICE="nginx"
if ! systemctl is-active --quiet "$SERVICE"; then
    echo "$(date): $SERVICE is down. Attempting restart..." | mail -s "Alert: $SERVICE down" ops@company.com
    systemctl restart "$SERVICE"
    sleep 5
    if systemctl is-active --quiet "$SERVICE"; then
        echo "$(date): $SERVICE restarted successfully"
    else
        echo "$(date): CRITICAL - $SERVICE failed to restart" | mail -s "CRITICAL: $SERVICE" ops@company.com
    fi
fi
```

**3. Backup Script:**
```bash
#!/bin/bash
BACKUP_DIR="/backups/db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MYSQL_USER="backup_user"
MYSQL_PASS="secure_password"

mkdir -p "$BACKUP_DIR"
mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASS" --all-databases | gzip > "$BACKUP_DIR/db_$TIMESTAMP.sql.gz"

# Keep only last 14 days of backups
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +14 -delete

# Verify backup integrity
if gzip -t "$BACKUP_DIR/db_$TIMESTAMP.sql.gz" 2>/dev/null; then
    echo "Backup successful and verified"
else
    echo "BACKUP FAILED" | mail -s "Database Backup Failed" ops@company.com
fi
```

**4. Deployment Script:**
```bash
#!/bin/bash
set -euo pipefail

APP_NAME="myapp"
DEPLOY_DIR="/opt/$APP_NAME"
RELEASE_DIR="$DEPLOY_DIR/releases/$(date +%Y%m%d%H%M%S)"
CURRENT_LINK="$DEPLOY_DIR/current"

# Pull latest code
git clone <repo-url> "$RELEASE_DIR"
cd "$RELEASE_DIR"

# Install dependencies and build
npm ci --production
npm run build

# Create symlink (atomic switch)
ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

# Restart service
systemctl restart "$APP_NAME"

# Verify deployment
sleep 5
if curl -sf http://localhost:8080/health > /dev/null; then
    echo "Deployment successful"
else
    echo "Deployment failed — rolling back"
    # rollback logic
fi
```

**5. Server Provisioning / Initial Setup:**
```bash
#!/bin/bash
set -euo pipefail

# Update system
sudo apt update && sudo apt upgrade -y

# Install common tools
sudo apt install -y curl wget git htop vim tmuf awscli docker.io

# Configure Docker
sudo usermod -aG docker $USER

# Install and configure fail2ban for security
sudo apt install -y fail2ban
sudo systemctl enable fail2ban

# Set up NTP synchronization
sudo apt install -y chrony
sudo systemctl enable chrony

echo "Server provisioning completed at $(date)"
```

**6. Monitoring and Alerting Script:**
```bash
#!/bin/bash
THRESHOLD=90

# Check disk usage
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
    curl -X POST -H "Content-Type: application/json" \
        -d "{\"text\":\"ALERT: Disk usage at ${DISK_USAGE}%\"}" \
        https://hooks.slack.com/services/WEBHOOK_URL
fi

# Check memory usage
MEM_USAGE=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
if [ "$MEM_USAGE" -gt "$THRESHOLD" ]; then
    curl -X POST -H "Content-Type: application/json" \
        -d "{\"text\":\"ALERT: Memory usage at ${MEM_USAGE}%\"}" \
        https://hooks.slack.com/services/WEBHOOK_URL
fi
```

**Key Scripting Best Practices Used:**

* **`set -euo pipefail`** — fail on error (`-e`), fail on undefined variables (`-u`), fail on pipe errors (`-pipefail`)
* **Meaningful variable names** and comment blocks explaining purpose
* **Logging** with timestamps for audit trail
* **Idempotent operations** — scripts can be safely re-run
* **Error handling** with `if/else` blocks and notification on failure
* **Use of `cron`** for scheduled execution and **systemd timers** for more complex scheduling

---

# ☁️ Cloud (AWS)

---

### 15️⃣ What AWS Services have you Worked with?

AWS offers **200+ services** across multiple categories. Here is a comprehensive overview of the most commonly used services organized by category, along with practical use cases:

**Compute:**

| Service | Description | Use Case |
|---------|-------------|----------|
| **EC2** | Virtual servers (IaaS) | Running applications, custom server workloads, CI/CD build agents |
| **Lambda** | Serverless functions | Event-driven processing, API backends, scheduled tasks, data transformation |
| **ECS / EKS** | Container orchestration | Running Docker containers at scale; EKS for Kubernetes-native workflows |
| **Elastic Beanstalk** | PaaS for application deployment | Quick deployment of web applications without managing infrastructure |
| **Auto Scaling** | Dynamic instance scaling | Automatically adding/removing EC2 instances based on load |

**Storage:**

| Service | Description | Use Case |
|---------|-------------|----------|
| **S3** | Object storage | Static website hosting, data lake, backup storage, CI/CD artifact storage |
| **EBS** | Block storage for EC2 | Persistent disk for databases, application data |
| **EFS** | Network file system | Shared file storage across multiple EC2 instances or ECS tasks |
| **DynamoDB** | NoSQL database | High-performance key-value store for session management, catalogs |
| **RDS** | Managed relational database | MySQL, PostgreSQL, Aurora for application databases |

**Networking:**

| Service | Description | Use Case |
|---------|-------------|----------|
| **VPC** | Virtual private network | Isolating resources, defining subnets, route tables, network ACLs |
| **ELB / ALB / NLB** | Load balancers | Distributing traffic across instances, SSL termination, path-based routing |
| **Route 53** | DNS service | Domain registration, DNS routing, health-based failover |
| **CloudFront** | CDN | Caching content at edge locations for low-latency global delivery |
| **Direct Connect** | Dedicated network connection | High-bandwidth, low-latency connection from on-premises to AWS |

**Security & Identity:**

| Service | Description | Use Case |
|---------|-------------|----------|
| **IAM** | Identity and Access Management | Managing users, roles, policies, and permissions |
| **KMS** | Key Management Service | Encrypting data at rest, managing encryption keys |
| **Secrets Manager** | Secret storage | Storing database credentials, API keys with automatic rotation |
| **Security Hub** | Security compliance | Centralized security findings and compliance checking |
| **WAF** | Web Application Firewall | Protecting web applications from common exploits (SQL injection, XSS) |

**Monitoring & Management:**

| Service | Description | Use Case |
|---------|-------------|----------|
| **CloudWatch** | Monitoring and logging | Metrics, logs, alarms, dashboards for all AWS resources |
| **CloudTrail** | API activity logging | Auditing who did what and when across AWS accounts |
| **Config** | Resource configuration tracking | Tracking configuration changes, compliance monitoring |
| **Systems Manager** | Instance management | Patching, run command, parameter store, state manager |
| **Cost Explorer** | Cost analysis | Analyzing and optimizing AWS spending |

**CI/CD & Developer Tools:**

| Service | Description | Use Case |
|---------|-------------|----------|
| **CodeCommit** | Managed Git repositories | Source code hosting |
| **CodeBuild** | Managed build service | Compiling code, running tests, creating artifacts |
| **CodeDeploy** | Application deployment | Deploying to EC2, ECS, Lambda, or on-premises |
| **CodePipeline** | CI/CD orchestration | Automating the release pipeline |
| **ECR** | Container registry | Storing and managing Docker images |

**Serverless & Data:**

| Service | Description | Use Case |
|---------|-------------|----------|
| **API Gateway** | Managed API endpoint | Creating REST/HTTP/WebSocket APIs for Lambda backends |
| **Step Functions** | Workflow orchestration | Coordinating multi-step serverless workflows |
| **Glue** | ETL service | Data transformation and loading into data lakes |
| **Athena** | Serverless query | Running SQL queries directly on S3 data |
| **Kinesis** | Real-time data streaming | Processing streaming data (clickstream, IoT, logs) |

**Typical Architecture:**
A common production setup combines **VPC** (networking) → **ALB** (load balancing) → **ECS/EKS** (compute) → **RDS/Aurora** (database) → **S3** (storage) → **CloudFront** (CDN) → **Route 53** (DNS), with **CloudWatch** for monitoring and **IAM** for access control throughout.

---

### 16️⃣ Have you Used Both CloudFormation and Terraform?

**Yes**, both AWS CloudFormation and Terraform have been used in production environments, each serving different purposes based on project requirements and team preferences.

**CloudFormation Experience:**

* Used CloudFormation for **AWS-native projects** where deep integration with AWS services was required. CloudFormation's native understanding of AWS resource dependencies made it ideal for complex AWS-only architectures.
* Created **nested stacks** to modularize infrastructure — a top-level stack for the VPC, with child stacks for compute, database, and networking components.
* Leveraged **CloudFormation Init (cfn-init)** for instance-level configuration, automatically installing software and configuring services on EC2 launch.
* Used **Change Sets** to preview the impact of stack updates before applying them — similar to `terraform plan`.
* Integrated CloudFormation with **AWS CodePipeline** for fully automated infrastructure deployment as part of the CI/CD process.

**Terraform Experience:**

* Used Terraform as the **primary IaC tool** for multi-cloud and hybrid environments. Its provider-agnostic nature allowed managing AWS, Azure, and on-premises resources from a single codebase.
* Organized Terraform code using **modules** — reusable, versioned components for VPCs, EKS clusters, RDS instances, and IAM configurations. Published internal modules to a private Terraform Registry.
* Managed **remote state** in S3 with DynamoDB locking, enabling team collaboration without state conflicts.
* Used **terraform workspaces** to manage separate environments (dev, staging, prod) from the same codebase with different variable values.
* Integrated Terraform with **Atlantis** for pull-request-based infrastructure reviews and automated plan/apply workflows.

**When Each Was Chosen:**

| Scenario | Tool |
|----------|------|
| AWS-only project with tight AWS service integration | CloudFormation |
| Multi-cloud or hybrid infrastructure | Terraform |
| Team already deeply skilled in AWS | CloudFormation |
| Need for drift detection and correction | Terraform |
| Importing existing infrastructure | Terraform (easier `terraform import`) |
| AWS Service Catalog integration | CloudFormation |

---

### 17️⃣ What is the Difference between CloudFormation and Terraform? Which is Better?

CloudFormation and Terraform are both leading **Infrastructure as Code** tools, but they differ fundamentally in design philosophy, scope, and capabilities. Here is a detailed comparison:

**Architecture and Design:**

| Aspect | CloudFormation | Terraform |
|--------|---------------|-----------|
| **Creator** | Amazon Web Services | HashiCorp |
| **Cloud Support** | AWS only | Multi-cloud (AWS, Azure, GCP, Kubernetes, 200+ providers) |
| **Configuration Language** | JSON or YAML | HCL (HashiCorp Configuration Language) — more readable |
| **Execution Model** | Push-based (AWS manages execution) | Client-based (local or CI/CD runs the tool) |
| **State Management** | Implicit (AWS tracks resource state internally) | Explicit (`.tfstate` file — local or remote backend) |
| **Dependency Resolution** | Auto-detected (references other resources by logical ID) | Auto-detected (references resources by attribute) |

**Key Differences:**

* **Cloud Agnosticism:** Terraform's biggest advantage is its ability to manage resources across **multiple cloud providers** using a consistent syntax. CloudFormation is locked to AWS. If your organization uses AWS and Azure, Terraform provides a **single tool and workflow** for both.

* **Configuration Language:** HCL (Terraform) is generally considered more **readable and maintainable** than CloudFormation's JSON/YAML. HCL supports variables, loops, conditionals, and modules with cleaner syntax. CloudFormation templates can become extremely verbose, especially with complex resource dependencies.

* **State Management:** Terraform's **explicit state file** is both a strength and a consideration. The state file tracks the exact mapping between code and real-world resources, enabling precise plan/apply operations and **drift detection**. CloudFormation's implicit state means AWS always knows the current state, but you cannot easily import resources created outside CloudFormation.

* **Drift Detection:** Terraform can **detect and correct drift** — if someone manually changes a resource in the AWS console, `terraform plan` will show the difference and `terraform apply` can revert it. CloudFormation has drift detection (`cfn detect-stack-drift`) but does not auto-correct as seamlessly.

* **Module Ecosystem:** Both have rich module ecosystems. Terraform Registry has **thousands of community-contributed modules** for all providers. CloudFormation has the AWS Quick Start library and supports nested stacks. Terraform's module system is generally considered more flexible and composable.

* **Resource Import:** Terraform makes it easy to **import existing resources** into state with `terraform import`. CloudFormation's adoption of existing resources is more limited — you typically need to use the `adoptIntoStack` API or recreate resources.

* **Execution Speed:** CloudFormation can be **faster for pure AWS** resources since it runs within AWS's infrastructure and has optimized dependency resolution. Terraform's execution speed depends on the client running it, though parallel execution (`-parallelism`) helps.

* **Rollback Behavior:** CloudFormation performs **automatic rollback** on stack creation failure — if any resource fails to create, the entire stack is rolled back to a clean state. Terraform does not auto-rollback on `apply` failure by default, though you can use `-auto-approve` with caution or implement custom rollback logic.

**Which is Better?**

There is no universal answer — the "better" tool depends on context:

* **Choose Terraform if:** You need multi-cloud support, you value explicit state management and drift detection, you prefer HCL's syntax, or you want to import existing infrastructure easily.
* **Choose CloudFormation if:** You are AWS-only and want the deepest possible integration with AWS services, you prefer AWS-managed execution, or your organization is already heavily invested in the AWS ecosystem.

In practice, many organizations use **both** — Terraform for cross-platform infrastructure and CloudFormation for AWS-specific resources that benefit from native integration (like Lambda layers, CloudFormation-driven SAM applications, or Service Catalog products).

---

### 18️⃣ If you are Working specifically with AWS, which would you Choose — CloudFormation or Terraform?

Even in an **AWS-only environment**, the choice between CloudFormation and Terraform depends on several practical considerations. Here is a nuanced analysis:

**Arguments for Terraform (Even AWS-Only):**

* **Team Skill Portability:** Terraform skills transfer to other clouds and platforms. If the organization ever expands to Azure or GCP, the team's Terraform knowledge carries over. CloudFormation skills are AWS-specific.
* **Drift Detection and Correction:** In environments where operations teams or emergency hotfixes may make **manual changes** in the AWS console, Terraform's ability to detect and correct drift is invaluable. `terraform plan` becomes a powerful audit tool.
* **State File as Source of Truth:** The explicit `.tfstate` file gives teams complete visibility into what Terraform manages. You can inspect, query, and even programmatically manipulate state.
* **Rich Provider Ecosystem:** Even within AWS, Terraform's AWS provider is frequently updated and often supports **newer AWS features** before CloudFormation does. The provider also supports advanced patterns like dynamic blocks and complex data sources.
* **Better Developer Experience:** HCL is more concise than CloudFormation's JSON/YAML. Features like `for_each`, `dynamic` blocks, and `terraform fmt` improve code quality and consistency.
* **Import Existing Resources:** If you have infrastructure created manually or by other tools, `terraform import` lets you gradually adopt IaC without rebuilding from scratch.

**Arguments for CloudFormation (AWS-Only):**

* **Deep AWS Integration:** CloudFormation understands AWS resources at a level that third-party tools cannot match. Features like **cfn-init, cfn-signal, and cfn-hup** provide EC2 instance configuration that Terraform cannot replicate natively.
* **AWS Service Integration:** CloudFormation integrates seamlessly with **AWS Service Catalog** (for governed self-service), **AWS Control Tower** (for multi-account governance), and **AWS Organizations**.
* **No State Management Overhead:** AWS manages the state internally. There is no risk of **state file corruption**, no need to configure remote backends with locking, and no state migration concerns.
* **Change Sets:** CloudFormation's Change Sets provide a **visual, AWS-console-based** preview of changes, which some teams find more accessible than `terraform plan` output.
* **Native Rollback:** Automatic stack rollback on failure provides a **clean failure mode** that Terraform does not offer by default.
* **Organizational Maturity:** If the organization is already using CloudFormation extensively with established templates, processes, and expertise, the **cost of switching** to Terraform may outweigh the benefits.

**Practical Recommendation:**

For a new AWS-only project, **Terraform is generally the preferred choice** due to its superior developer experience, drift detection, and import capabilities. However, CloudFormation remains the right choice when:

* You need **cfn-init** for EC2 instance configuration
* You are building **Service Catalog products** for self-service infrastructure
* Your organization has deep CloudFormation expertise and established templates
* You need the tightest integration with **AWS Control Tower and Organizations**

Many mature AWS teams use a **hybrid approach**: Terraform for the majority of infrastructure, and CloudFormation for specific AWS-native features (SAM/Lambda packaging, Service Catalog, or CloudFormation-driven Blue-Green deployments via CodeDeploy).

---

# 🐋 Docker & Jenkins

---

### 19️⃣ Write a Simple Dockerfile for a Node.js Application

```dockerfile
# Simple Dockerfile for a Node.js application
FROM node:18-alpine

# Set working directory inside the container
WORKDIR /app

# Copy package files first (leverages Docker layer caching)
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application source code
COPY . .

# Expose the application port
EXPOSE 3000

# Set environment variable
ENV NODE_ENV=production

# Health check to verify the application is running
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["node", "server.js"]
```

**Key Points:**

* **`FROM node:18-alpine`** — uses the Alpine-based Node.js 18 image, which is significantly smaller than the full Debian-based image (~150MB vs ~900MB)
* **Layer Caching:** `COPY package*.json` and `npm ci` are placed before `COPY . .` so that dependency installation is cached when only application code changes
* **`npm ci`** instead of `npm install` — ensures deterministic, clean installs from `package-lock.json` (faster and more reliable for CI/CD)
* **`--only=production`** — skips devDependencies, reducing image size
* **`HEALTHCHECK`** — enables Docker and orchestrators (Kubernetes, Swarm) to monitor application health
* **`CMD`** in exec form (JSON array) — ensures the application runs as PID 1 and properly receives signals (SIGTERM for graceful shutdown)

---

### 20️⃣ How would you Write the Same Dockerfile Using a Multi-Stage Build?

Multi-stage builds allow you to use multiple `FROM` statements in a single Dockerfile, **copying only the necessary artifacts** from earlier stages into the final image. This dramatically reduces the final image size by excluding build tools, source code, and intermediate dependencies.

```dockerfile
# ==============================
# Stage 1: Build Stage
# ==============================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files and install ALL dependencies (including devDependencies for building)
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the application (if using a build step like TypeScript compilation or bundling)
# For a simple Node.js app, this step may be skipped
# RUN npm run build

# ==============================
# Stage 2: Production Stage
# ==============================
FROM node:18-alpine AS production

# Add non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

WORKDIR /app

# Copy package files and install only production dependencies
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built application from the builder stage
# If using a build output directory:
# COPY --from=builder /app/dist ./dist
COPY --from=builder /app .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["node", "server.js"]
```

**Benefits of Multi-Stage Build:**

* **Smaller Image Size:** The production image contains only the **runtime dependencies and application code** — no build tools, devDependencies, or source maps. A simple Node.js app image can go from ~300MB (single stage) to ~150MB (multi-stage).
* **Security:** The production image runs as a **non-root user** (`appuser`), reducing the attack surface. If a vulnerability is exploited, the attacker has limited privileges.
* **Cleaner Dependency Install:** Production dependencies are installed fresh in the final stage, ensuring no build-time artifacts or cached files are included.
* **Separation of Concerns:** The build stage and runtime stage are clearly separated, making the Dockerfile easier to understand and maintain.

**Advanced Multi-Stage Example (with TypeScript):**
```dockerfile
# Stage 1: Install all dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: Build the application
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build  # compiles TypeScript to JavaScript in /dist

# Stage 3: Production image
FROM node:18-alpine AS production
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
USER appuser
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

---

### 21️⃣ Can you Create a Jenkins Pipeline for Building and Deploying the Docker Image?

```groovy
pipeline {
    // Execute on an agent with Docker installed
    agent {
        docker {
            image 'docker:24.0-dind'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        // AWS credentials from Jenkins credential store
        AWS_ACCESS_KEY_ID     = credentials('aws-prod-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-prod-secret-key')
        AWS_REGION            = 'us-east-1'
        ECR_REGISTRY          = '123456789012.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPOSITORY        = 'myapp'
        IMAGE_TAG             = "${BUILD_NUMBER}-${env.GIT_COMMIT?.substring(0, 7)}"
        KUBE_CONFIG           = credentials('eks-kubeconfig')
    }

    options {
        // Timeout the build after 30 minutes
        timeout(time: 30, unit: 'MINUTES')
        // Disable concurrent builds of the same pipeline
        disableConcurrentBuilds()
        // Keep build logs for 30 days
        buildDiscarder(logRotator(numToKeepStr: '30'))
        // Set Git CHDIR for cleaner workspace
        checkoutToSubdirectory('')
    }

    triggers {
        // Trigger on SCM polling (or use webhook for instant trigger)
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
        }
        post {
            failure {
                error('Tests failed — aborting pipeline')
            }
        }
        }

        stage('Static Code Analysis') {
            steps {
                sh 'npx eslint . --format json --output-file eslint-report.json'
                sh 'npx sonar-scanner'
            }
            post {
                always {
                    // Archive analysis reports
                    archiveArtifacts artifacts: '*-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                        --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
                        -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                        -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest \
                        .
                '''
            }
        }

        stage('Scan Docker Image') {
            steps {
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy \
                        --exit-code 1 \
                        --severity CRITICAL,HIGH \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                '''
            }
            post {
                failure {
                    error('Image contains critical/high vulnerabilities — aborting deployment')
                }
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh '''
                    awk 'BEGIN {env["KUBECONFIG"]="${KUBE_CONFIG}"}'
                    kubectl set image deployment/myapp \
                        myapp=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                        --namespace=staging
                    kubectl rollout status deployment/myapp --namespace=staging --timeout=300s
                '''
            }
        }

        stage('Staging Smoke Tests') {
            steps {
                sh '''
                    curl -sf https://staging.myapp.com/health || exit 1
                    curl -sf https://staging.myapp.com/api/v1/status || exit 1
                '''
            }
            post {
                failure {
                    error('Staging smoke tests failed — not proceeding to production')
                }
            }
        }

        stage('Deploy to Production') {
            when {
                // Only deploy to production on the main branch
                branch 'main'
            }
            steps {
                // Require manual approval before production deployment
                input message: 'Deploy to Production?', ok: 'Deploy', submitter: 'release-managers'

                sh '''
                    kubectl set image deployment/myapp \
                        myapp=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                        --namespace=production
                    kubectl rollout status deployment/myapp --namespace=production --timeout=300s
                '''
            }
        }

        stage('Production Smoke Tests') {
            steps {
                sh '''
                    curl -sf https://myapp.com/health || exit 1
                    curl -sf https://myapp.com/api/v1/status || exit 1
                '''
            }
        }

        stage('Notify') {
            steps {
                script {
                    if (currentBuild.currentResult == 'SUCCESS') {
                        slackSend channel: '#deployments',
                            color: 'good',
                            message: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} deployed to production [${env.GIT_COMMIT?.substring(0, 7)}]"
                    } else {
                        slackSend channel: '#deployments',
                            color: 'danger',
                            message: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} [${env.GIT_COMMIT?.substring(0, 7)}]"
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up Docker images to free disk space
            sh 'docker system prune -f'
            // Clean up workspace
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed — check console output for details'
        }
        unstable {
            echo 'Pipeline completed with warnings'
        }
    }
}
```

**Pipeline Features:**

* **Multi-stage execution:** Checkout → Test → Analyze → Build → Scan → Push → Deploy → Verify
* **Security scanning:** Trivy scans the Docker image for vulnerabilities before pushing to ECR
* **Manual approval gate:** Production deployment requires explicit approval from authorized users
* **Branch protection:** Production deployment only triggers on the `main` branch
* **Smoke tests:** Automated health checks after each deployment stage
* **Slack notifications:** Team is notified of build success or failure
* **Cleanup:** Docker system prune and workspace cleanup after every run
* **Credentials management:** AWS keys and Kubeconfig stored in Jenkins credential store (never hardcoded)

---

> **Last Updated:** September 2026
> **Total Questions:** 22
> **Categories:** DevOps Fundamentals, CI/CD, Containerization & Kubernetes, IaC & Terraform, Linux & Scripting, Cloud (AWS), Docker & Jenkins
