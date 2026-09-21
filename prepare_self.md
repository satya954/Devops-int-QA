# Self Introduction & Behavioral Questions

---

## Have you automated anything recently?

Recently, I automated our **container image vulnerability scanning and remediation workflow**. Previously, the team manually ran Trivy scans after each Docker build and tracked CVE findings in a spreadsheet. I integrated Trivy directly into the Jenkins CI/CD pipeline so that every image is automatically scanned for HIGH and CRITICAL vulnerabilities before being pushed to the registry. If critical vulnerabilities are detected, the pipeline fails and posts a detailed report to the team's Slack channel. This reduced the average time to identify vulnerable images from days to minutes and eliminated images with critical CVEs from reaching production.

Additionally, I wrote a **Python-based automation script** that monitors EKS cluster node utilization and triggers Karpenter to right-size underutilized nodes, reducing our monthly cloud spend by approximately 15%.

---

## What operational activities have you automated?

- **CI/CD Pipeline Orchestration:** Built end-to-end Jenkins pipelines that automate code checkout, building, testing, container image creation, security scanning (SonarQube, Trivy), and multi-environment deployment (staging → production with approval gates).
- **Infrastructure Provisioning:** Automated AWS infrastructure deployment using **Terraform**, with separate modules for VPC, EKS, RDS, and IAM. Terraform plans and applies are executed through the CI/CD pipeline, eliminating manual console-based provisioning.
- **Log Management:** Deployed **Fluentd as a DaemonSet** on EKS to automatically collect application logs from all nodes and ship them to the ELK stack, replacing manual log extraction from individual servers.
- **Monitoring and Alerting:** Set up automated CloudWatch alarms for infrastructure metrics (CPU, memory, disk) and Prometheus/Grafana alerts for Kubernetes-level metrics, with notifications routed to PagerDuty and Slack.
- **Secret Rotation:** Configured **AWS Secrets Manager** with automatic Lambda-based rotation for RDS credentials, eliminating manual password updates.
- **Incident Response Runbooks:** Created AWS Systems Manager (SSM) Automation Documents for common operational tasks — restarting failed services, clearing disk space, and scaling up Auto Scaling Groups — reducing mean time to resolution.

---

## Explain one critical production issue you have solved

### Issue 1: EC2 Disk Full Due to Unbounded Application Logging

I received an alert that one of our EC2 instances had reached a critical disk usage state. Upon logging into the instance, I found that the disk was nearly full. After investigating, I discovered that an application was writing GBs of log data due to a data query mismatch — the logs were filled with repeated error messages in an infinite loop. A cron job ran on only one instance, which is why only that node was affected.

**Resolution:** I immediately removed the instance from the load balancer and stopped the application. I compressed the oversized log file to reclaim disk space, and then collaborated with the development team to fix the underlying query issue and implement proper log rotation. We also added disk usage alerts at the 80% threshold to catch such issues earlier.

### Issue 2: Database ALTER Query Causing Application Slowdown

A long-running `ALTER TABLE` query on our production database caused significant application performance degradation. The query was locking tables, which in turn caused user requests to timeout and created a cascading failure across dependent services.

**Resolution:** We immediately paused the application deployment to prevent additional load. The ALTER query completed within a few minutes, during which users experienced intermittent failures. Upon successful execution, we restarted the application. To prevent recurrence, we adopted **online schema migration tools** (e.g., `pt-online-schema-change`) that perform alterations without locking production tables.

### Issue 3: ActiveMQ Queue Buildup

We observed that the number of messages in our ActiveMQ queues was growing significantly, leading to increased processing latency and consumer lag.

**Resolution:** We immediately increased the number of consumer replicas through the Horizontal Pod Autoscaler (HPA) and set a fixed minimum replica count to ensure sufficient processing capacity. We also investigated the root cause and found that a downstream service degradation was slowing message consumption. After restoring the downstream service, the queues drained to normal levels.

---

## Explain the biggest challenge you have faced in your current organization

One of the biggest challenges I faced in my current organization was a **recurring Java application outage in our Kubernetes environment**.

We had a production Java microservice that was restarting unexpectedly. Initially, the application team suspected a Kubernetes or infrastructure issue because the pod was disappearing and coming back up. I started by checking the pod events and container termination reason. I noticed that the container was being terminated with **exit code 137**, which indicated an **out-of-memory (OOM) condition**.

I then compared the Kubernetes resource configuration with the JVM configuration. The container had a memory limit of approximately 3 GB, while the JVM heap was configured at around 2 GB. When I examined the actual memory consumption, I found that the application was using additional memory outside the Java heap — including native memory, metaspace, and other JVM overhead — which pushed the total memory usage beyond the container's limit.

Using Kubernetes metrics, Grafana dashboards, pod events, and JVM memory information, I established that the container was reaching its Kubernetes memory limit rather than simply having a Java heap problem.

I discussed the findings with the application team, and we adjusted both the Kubernetes resource limits and the JVM settings based on the application's actual memory requirements. We also improved our monitoring and alerting so that we could identify abnormal memory growth before the pod reached its limit.

**Key Learning:** Troubleshooting a Kubernetes OOM issue requires looking at both sides — **Kubernetes resource limits** and **JVM memory usage**. Increasing the memory limit blindly may hide the problem, so it is important to understand where the memory is actually being consumed.

This incident helped us improve our monitoring practices and made our troubleshooting process more structured for similar production issues.
