# AWS Interview Preparation

---

## Which AWS load balancers have you worked with?

I have worked with **Application Load Balancer (ALB)**, **Network Load Balancer (NLB)**, and **Classic Load Balancer (CLB)**. In my current project, I primarily use ALB for HTTP/HTTPS traffic at Layer 7 (application layer) with path-based and host-based routing. I use NLB for Layer 4 (transport layer) traffic when low latency and high throughput are required, such as for TCP/UDP-based services. Classic Load Balancer is largely deprecated and is only used for legacy applications.

---

## Can a load balancer redirect or route traffic to a different AWS region?

**No**, a single load balancer (ALB, NLB, or CLB) cannot directly route traffic to targets in a different AWS region. Load balancers are region-specific and can only route traffic to targets (EC2 instances, containers, IP addresses) within the **same region**.

---

## If not directly, how can you redirect traffic to a different region?

You can achieve cross-region traffic routing using the following approaches:

- **Amazon Route 53 with Health Checks:** Use Route 53's **latency-based**, **failover**, or **geoproximity routing policies** to direct traffic to load balancers in different regions. If the primary region becomes unhealthy, Route 53 automatically fails over to the secondary region.
- **Global Accelerator:** AWS Global Accelerator provides static anycast IP addresses that route traffic to the nearest healthy endpoint across multiple regions, offering faster failover than Route 53 (within 30–60 seconds).
- **Cross-Region Lambda@Edge or CloudFront:** For HTTP/HTTPS content, CloudFront can route requests to origin servers in different regions based on viewer location or origin health.

---

## What is the difference between a VPC and a subnet?

A **VPC (Virtual Private Cloud)** is a logically isolated section of the AWS cloud where you can launch resources in a virtual network that you define. It spans the entire AWS region. A **subnet** is a subdivision of a VPC that resides within a **single Availability Zone**. Subnets allow you to segment your VPC into public and private sections, assign specific CIDR blocks, and control which AZ your resources run in. Think of a VPC as your entire network and subnets as individual segments within it.

---

## Have you installed or worked with SSL certificates?

Yes, I have extensive experience provisioning, installing, and renewing SSL/TLS certificates. In AWS, I use **AWS Certificate Manager (ACM)** to request and manage public certificates for ALB, CloudFront, and API Gateway. For on-premises or EC2 instances, I have installed certificates from **Let's Encrypt (Certbot)** and enterprise CAs (e.g., DigiCert, Sectigo). I also handle private certificates for internal services using **ACM Private Certificate Authority (ACM PCA)**.

---

## What is an SSL certificate?

An **SSL/TLS certificate** is a digital certificate that authenticates the identity of a website or server and enables encrypted communication between the server and clients (browsers, applications). It contains the server's **public key**, identity information (domain name, organization), and is signed by a trusted **Certificate Authority (CA)**. When a client connects, the server presents its certificate, and the client validates it against its trusted CA store. If valid, an encrypted TLS session is established, ensuring data confidentiality and integrity.

---

## What happens if the SSL certificate is not installed on the server?

Without an SSL certificate, the server cannot establish **encrypted HTTPS connections**. Clients attempting to connect via HTTPS will receive a **connection error** or a **security warning**. Browsers will display "Your connection is not private" or similar warnings, and many modern browsers will block access entirely. Sensitive data (passwords, credit card details, API tokens) will be transmitted in **plaintext over HTTP**, making it vulnerable to **eavesdropping, man-in-the-middle attacks, and data interception**.

---

## How are secrets stored in AWS Secrets Manager?

AWS Secrets Manager stores secrets in an **encrypted format** using AES-256 encryption. By default, it uses an AWS-managed CMK (Customer Master Key) in AWS KMS, but you can also specify a customer-managed KMS key for additional control. Secrets are stored as **key-value pairs** (or JSON structures) and are never exposed in plaintext unless explicitly retrieved via the `GetSecretValue` API call. Access is controlled through **IAM policies**, and the service supports **automatic rotation** using Lambda functions on a scheduled basis (every 30, 60, 90, or 180 days). Audit trails are maintained via **AWS CloudTrail**.

---

## How do you manage application secrets & application configuration in your current project?

Currently, my applications are deployed on **AWS EKS** with databases in **RDS**. Here is how secrets and configuration are managed:

**Secrets Management:**
- The Kubernetes Pod Service Account is linked with an **IAM Role** (via IRSA — IAM Roles for Service Accounts). This IAM Role has permissions to access **AWS Secrets Manager**.
- Applications retrieve secrets at runtime by calling the Secrets Manager API, eliminating the need to store secrets in Kubernetes Secrets.
- For sensitive database credentials, we use **RDS IAM authentication** where possible, avoiding password-based logins.

**Configuration Management:**
- Non-sensitive configuration data (application URLs, feature flags, environment-specific settings) is managed using **Kubernetes ConfigMaps** and mounted as environment variables or configuration files.
- Configuration is version-controlled and updated via the CI/CD pipeline.

**Environment Architecture:**

```
Development/Test                  Staging/Production
-----------------                 ------------------
On-prem Kubernetes                AWS EKS
        │                                │
        ▼                                ▼
On-prem MySQL/DB                   AWS RDS
        │                                │
        ▼                                ▼
K8s Secrets / Vault                AWS Secrets Manager
```

---

## Explain VPC, subnet, route table, and security groups.

- **VPC (Virtual Private Cloud):** A logically isolated virtual network in AWS where you launch resources. You define its CIDR block (e.g., `10.0.0.0/16`) at creation, and it spans an entire AWS region.
- **Subnet:** A subdivision of a VPC within a single Availability Zone. Subnets have their own CIDR blocks (e.g., `10.0.1.0/24`) and are classified as **public** (with a route to an Internet Gateway) or **private** (no direct internet access).
- **Route Table:** A set of rules that determine where network traffic is directed. Each subnet is associated with a route table. Routes can point to an Internet Gateway (for internet access), a NAT Gateway (for outbound access from private subnets), a VPC Peering Connection, or a VPN Gateway.
- **Security Group:** A stateful virtual firewall that controls **inbound and outbound traffic** at the instance level. Security groups support allow rules only (no deny rules) and can reference other security groups, IP addresses, or CIDR blocks. They act at the **ENI (Elastic Network Interface)** level.

---

## Difference between ALB, NLB, and CloudFront?

| Feature | ALB (Application Load Balancer) | NLB (Network Load Balancer) | CloudFront |
|---------|--------------------------------|----------------------------|------------|
| **OSI Layer** | Layer 7 (Application) | Layer 4 (Transport) | CDN (Content Delivery Network) |
| **Protocols** | HTTP, HTTPS, WebSocket | TCP, UDP, TLS | HTTP, HTTPS |
| **Routing** | Path-based, host-based, header-based | IP-based, port-based | Edge-based, geographic caching |
| **Use Case** | Microservices, web apps, API routing | High-performance TCP/UDP, static IPs | Static content delivery, global caching |
| **Latency** | ~ms level | Sub-ms (ultra-low) | Sub-ms at edge locations |
| **SSL Termination** | Yes (ACM integrated) | Yes (bring your own or import) | Yes (ACM integrated) |
| **Scope** | Regional | Regional | Global |

---

## How do you secure an AWS environment?

Securing an AWS environment involves a **multi-layered defense strategy**:

- **IAM (Identity and Access Management):** Enforce the **principle of least privilege** using IAM policies. Enable **MFA** for all users, especially root and privileged accounts. Use **IAM Roles** instead of access keys where possible. Implement **IAM Access Analyzer** to identify resources shared with external entities.
- **Network Security:** Use **Security Groups** and **NACLs** to restrict traffic. Deploy resources in **private subnets** with NAT Gateway for outbound access. Use **VPC Flow Logs** to monitor network traffic and detect anomalies.
- **Encryption:** Encrypt data at rest using **AWS KMS** (EBS, RDS, S3) and in transit using **TLS/SSL**. Enable **S3 Bucket Policies** to enforce HTTPS-only access.
- **Monitoring and Logging:** Enable **CloudTrail** for API audit logging, **VPC Flow Logs** for network monitoring, and **CloudWatch** for resource-level metrics. Send logs to a centralized SIEM (e.g., Splunk, GuardDuty).
- **GuardDuty & Security Hub:** Use **Amazon GuardDuty** for threat detection (malicious IPs, unusual API calls) and **AWS Security Hub** for aggregated compliance checks across AWS Foundational Security Best Practices, CIS, and PCI-DSS.
- **WAF (Web Application Firewall):** Protect ALB/CloudFront from common web exploits (SQL injection, XSS, DDoS) using AWS WAF rules and managed rule groups (AWS Managed Rules, Bot Control).
- **Secrets Management:** Use **AWS Secrets Manager** or **SSM Parameter Store** for storing and rotating secrets, rather than hardcoding them in application code.

---

## How do you troubleshoot an unreachable EC2 instance?

I follow a **systematic, layer-by-layer approach**:

**Step 1 — Check Instance State:**
```bash
aws ec2 describe-instances --instance-ids i-xxxxxxxx
# Verify the instance state is 'running' and status checks pass
```

**Step 2 — Security Group Rules:**
- Verify that the security group attached to the instance allows **inbound traffic** on the required port (e.g., SSH port 22, HTTP port 80/443) from the source IP/CIDR.
- Check that **outbound rules** allow response traffic.

**Step 3 — Network ACLs:**
- Verify that the NACL associated with the subnet allows inbound and outbound traffic on the relevant ports. Unlike security groups, NACLs are **stateless** and require explicit return traffic rules.

**Step 4 — Route Table:**
- Ensure the subnet's route table has a route to an **Internet Gateway** (for public subnets) or a **NAT Gateway** (for private subnets requiring outbound access).

**Step 5 — Instance-Level Checks:**
- Check if a **local firewall** (e.g., `iptables`, `firewalld`) is blocking connections.
- Verify the SSH service or application is running: `systemctl status sshd`
- Check system logs: `journalctl -u sshd` or `/var/log/auth.log`

**Step 6 — Elastic IP / Public IP:**
- Confirm the instance has a public IP or Elastic IP assigned. If behind a NAT, ensure the NAT Gateway is properly configured.

**Step 7 — Use EC2 Instance Connect or Session Manager:**
```bash
aws ssm start-session --target i-xxxxxxxx
# AWS Systems Manager Session Manager provides SSH-less access
```

---

## How do you monitor applications using CloudWatch?

Amazon CloudWatch provides comprehensive monitoring through the following components:

- **CloudWatch Metrics:** Collect numerical data about AWS resources (CPU utilization, disk I/O, network throughput, RDS connections). Metrics are collected at 1-minute or 1-second (Detailed Monitoring) intervals and can be visualized in **CloudWatch Dashboards**.
- **CloudWatch Alarms:** Trigger automated actions (SNS notification, Auto Scaling, Systems Manager Runbook) when a metric crosses a threshold. For example, an alarm can trigger an SNS alert when EC2 CPU utilization exceeds 80% for five consecutive minutes.
- **CloudWatch Logs:** Centralized log collection from EC2 instances, ECS, EKS, Lambda, and application logs. Use the **CloudWatch Agent** to push custom logs and metrics. **Log Insights** enables real-time querying of log data using a purpose-built query language.
- **CloudWatch Events / EventBridge:** React to changes in AWS resources (e.g., EC2 state change, Auto Scaling events) by triggering Lambda functions, SNS topics, or Step Functions workflows.
- **CloudWatch Application Signals:** Application Performance Monitoring (APM) for tracking service-level indicators (SLIs) such as latency, request count, and error rate across distributed applications.

---

## How do you design a highly available application on AWS?

High availability on AWS is achieved through the following design principles:

- **Multi-AZ Deployment:** Deploy application components across **multiple Availability Zones** to survive data center failures. Use Auto Scaling Groups with subnets in multiple AZs.
- **Elastic Load Balancing:** Place an **ALB or NLB** in front of application instances to distribute traffic and automatically route around unhealthy targets.
- **Auto Scaling:** Configure **Auto Scaling Groups** with minimum, desired, and maximum instance counts, scaling based on CPU/memory metrics or custom CloudWatch metrics.
- **Managed Services:** Use **Amazon RDS Multi-AZ** for automated failover, **Amazon ElastiCache (Redis/Memcached)** with cluster mode, and **Amazon S3** (which is inherently multi-AZ).
- **EKS with Multi-AZ Worker Nodes:** Deploy EKS worker nodes across multiple AZs and use pod disruption budgets to maintain availability during node failures.
- **Health Checks & Self-Healing:** Configure load balancer health checks to detect and remove unhealthy instances. Use Kubernetes liveness and readiness probes for container-level health monitoring.
- **Backup and Disaster Recovery:** Implement automated backups (RDS snapshots, EBS snapshots, S3 versioning) and a **cross-region disaster recovery plan** using Route 53 failover routing.

---

## How is monitoring, logging, and alerting for your AWS infrastructure and application setup configured in your current project?

**AWS Infrastructure Monitoring:**
- Load balancers, EC2 instances, Auto Scaling Groups, RDS, and EBS volumes are monitored using **AWS CloudWatch**.
- We track metrics such as **CPU utilization, memory usage, disk I/O, and network throughput**. CloudWatch Alarms are configured to trigger SNS notifications when thresholds are breached.

**Kubernetes (EKS) Monitoring:**
- We use **Prometheus and Grafana** deployed within the EKS cluster for Kubernetes-level monitoring.
- **Prometheus** collects metrics from the cluster using **Node Exporter** (node-level metrics), **kube-state-metrics** (Kubernetes resource metrics), and application-level custom metrics.
- **Grafana** provides graphical dashboards for visualizing the data collected by Prometheus. We have pre-built dashboards for cluster health, pod resource utilization, and application performance.

**Logging:**
- We use **Fluentd** deployed as a **DaemonSet** that runs on each EKS node. Fluentd collects application logs from container stdout/stderr and log files, and forwards them to the **ELK Stack (Elasticsearch, Logstash, Kibana)** for centralized log aggregation and analysis.
- For infrastructure logs, we use **CloudWatch Logs** with the CloudWatch Agent, and **VPC Flow Logs** for network traffic monitoring.

**Alerting:**
- Critical alerts are routed through **SNS → PagerDuty/OpsGenie** for on-call escalation.
- Non-critical alerts are sent to **Slack/Teams** channels for the development team.
