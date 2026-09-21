
---

## File and Directory Operations

### Print file names that are more than 1 GB in size
```bash
find . -type f -maxdepth 1 -size +1G
```

### Print directory names in a folder
```bash
find . -maxdepth 1 -type d
find . -maxdepth 1 -type d | wc -l    # Count directories
```

### Print file names in a folder
```bash
find . -type f -maxdepth 1 -exec ls -l {} \;
find . -maxdepth 1 -type f -printf '%p\n'
```

### Print file names sorted by size
```bash
find . -maxdepth 1 -type f -exec ls -l {} \; | sort -k5 -h
find . -maxdepth 1 -type f -exec ls -l {} \; | sort -k5 -hr    # Reverse order (largest first)
```

### Print files larger than 1 GB, sorted by size
```bash
find . -maxdepth 1 -type f -size +1G -exec ls -lh {} \; | sort -k5 -hr
```

---

## Process Management

### Sort processes by CPU or memory usage
```bash
# Sort by CPU or memory (ascending)
ps --sort=%cpu
ps --sort=%mem

# Sort by memory (descending)
ps --sort=-%mem

# Sort by CPU, then memory (ascending)
ps --sort=%cpu,%mem

# Sort by CPU and memory (descending)
ps --sort=-%cpu,-%mem
```

### Print process ID and CPU for processes consuming more than 50% CPU
```bash
ps -eo pid,comm,%cpu --sort=-%cpu | awk 'NR==1 || $3 > 50'
```

---

## Shell Scripts

### Print even numbers from 1 to 10
```bash
for i in {1..10}; do
   if (( i % 2 == 0 )); then
       echo $i
   fi
done
```

### Print even numbers up to a user-specified number
```bash
#!/bin/bash
read -p "Enter your number: " n
for (( i=1; i<=n; i++ )); do
  if (( i % 2 == 0 )); then
      echo $i
  fi
done
```

### FizzBuzz-style loop (multiples of 3, 5, and 15)
```bash
#!/bin/bash
read -p "Enter the number: " n

i=1
while (( i <= n )); do
  if (( i % 15 == 0 )); then
      echo "multiply by 15"
  elif (( i % 3 == 0 )); then
      echo "number by 3"
  elif (( i % 5 == 0 )); then
      echo "number by 5"
  else
      echo "$i"
  fi
  (( i++ ))
done
```

---

## Text Utilities

### Print file content in reverse order using `tac`
```bash
cat 1.txt
# Output:
# 1
# 2
# 3

cat 1.txt | tac
# Output:
# 3
# 2
# 1
```

---

## Troubleshooting Scenarios

### What would you do if CPU utilization suddenly reaches 95–100%?

1. **Identify the offending process:**
   ```bash
   top -bn1 | head -20
   ps aux --sort=-%cpu | head -10
   ```
2. **Determine if it is user-space or system-space load:**
   ```bash
   vmstat 1 5    # Check %wa (I/O wait) and %si (softirq)
   mpstat -P ALL 1 5    # Per-core utilization
   ```
3. **Take immediate action:** If a specific process is misbehaving, throttle it with `renice` or restart the service. If it is an I/O bottleneck, investigate disk performance with `iostat -x 1 5`.
4. **Investigate the root cause:** Check application logs, recent deployments, or scheduled jobs (cron) that may have triggered the spike.
5. **Set up alerting:** Configure Prometheus/Grafana alerts for sustained high CPU (>80% for 5 minutes) to catch issues early.

---

### How would you troubleshoot HTTP 503 errors?

**503 Service Unavailable** means the server is temporarily unable to handle the request.

1. **Check backend service health:**
   ```bash
   curl -v http://localhost:8080/health
   systemctl status <service>
   ```
2. **Check if the application is running and listening:**
   ```bash
   ss -tlnp | grep 8080
   ps aux | grep <app>
   ```
3. **Check load balancer health checks:** Verify that the load balancer is marking instances as unhealthy due to failed health check endpoints.
4. **Check for resource exhaustion:**
   ```bash
   free -h        # Memory
   df -h          # Disk
   ulimit -n      # File descriptors
   ```
5. **Review application logs** for connection pool exhaustion, thread pool saturation, or downstream service timeouts.
6. **Check rate limiting or WAF rules** that may be blocking legitimate traffic.

---

### Application latency increased from 200 ms to 5 seconds — how would you investigate?

1. **Check application metrics** in Grafana/Prometheus for increased request latency, error rates, and active connections.
2. **Profile the application:** Enable slow query logs for database calls, and check for long-running API calls or blocked threads.
3. **Check database performance:**
   ```bash
   # Look for slow queries, lock waits, connection pool exhaustion
   mysql> SHOW PROCESSLIST;
   # Check RDS CloudWatch metrics — CPU, connections, read IOPS
   ```
4. **Check network latency** between services:
   ```bash
   mtr <target_host>    # Network path analysis
   ```
5. **Check for resource contention:** CPU throttling, memory pressure (swap usage), or disk I/O saturation.
6. **Check downstream dependencies:** External API calls, cache misses (Redis/ElastiCache), or message queue backlog.
7. **Review recent deployments** — the latency spike may correlate with a new code release or configuration change.

---

### Disk usage reached 95% — what steps would you take?

1. **Identify what is consuming space:**
   ```bash
   df -h                          # Filesystem usage
   du -sh /* | sort -hr | head    # Top-level directory sizes
   du -sh /var/log/* | sort -hr   # Log directory sizes
   ```
2. **Check for large log files:**
   ```bash
   find /var/log -type f -size +100M -exec ls -lh {} \;
   ```
3. **Take immediate action:**
   - **Truncate** (not delete) large log files that are held open by applications:
     ```bash
     truncate -s 0 /var/log/large_app.log
     ```
   - Remove old core dumps, temporary files, and unused Docker images:
     ```bash
     docker system prune -a
     journalctl --vacuum-size=100M
     ```
4. **Check for deleted files still held open:**
   ```bash
   lsof +L1    # Shows deleted files still consuming disk space
   ```
5. **Set up long-term prevention:** Configure **logrotate**, set up disk usage alerts at 80%, and implement log shipping to centralized logging (ELK, CloudWatch).

---

### How do you monitor application availability and latency?

- **Synthetic Monitoring:** Use tools like **Datadog Synthetic Checks**, **Pingdom**, or **Uptime Kuma** to periodically hit application endpoints from multiple geographic locations and measure response time and availability.
- **Real User Monitoring (RUM):** Embed JavaScript agents (e.g., **New Relic Browser**, **Datadog RUM**) to capture actual user experience metrics.
- **Prometheus + Grafana:** Scrape application `/metrics` endpoints to track request latency histograms, error rates, and throughput (RED method: Rate, Errors, Duration).
- **CloudWatch Alarms:** Set alarms on ALB 5xx error rates and target response times.
- **Service Level Indicators (SLIs):** Track metrics like `p99 latency < 500ms` and `availability > 99.9%`.

---

### What are SLI, SLO, and SLA?

| Term | Full Form | Definition | Example |
|------|-----------|-----------|---------|
| **SLI** | Service Level Indicator | A **measurable metric** that defines the actual performance of a service | 99.5% of requests respond in under 500ms |
| **SLO** | Service Level Objective | A **target value** for an SLI — the goal the team commits to | 99.9% of requests respond in under 500ms (monthly target) |
| **SLA** | Service Level Agreement | A **contractual commitment** to the customer, with consequences (credits, penalties) for missing the SLO | If availability drops below 99.9%, customer receives 10% service credit |

**Relationship:** SLIs measure actual performance, SLOs define the target, and SLAs enforce accountability through business agreements.

---

### How do you handle a P1 production incident?

1. **Activate Incident Response:** Declare the incident, assign an **incident commander**, and notify the on-call team via PagerDuty/OpsGenie.
2. **Assess Impact:** Determine the scope — how many users are affected, which services are down, and whether data is at risk.
3. **Communicate:** Send an initial status update to stakeholders (engineering, product, customer support) and set up a war room (Slack/Teams channel or bridge call).
4. **Mitigate First:** Focus on **restoring service** before root-cause analysis. Options include:
   - Rolling back the recent deployment
   - Scaling up resources (HPA, ASG)
   - Enabling circuit breakers or degrading non-critical features
   - Failing over to a secondary region
5. **Resolve:** Implement the fix and verify that services are healthy and metrics have returned to normal.
6. **Communicate Resolution:** Update stakeholders that the incident is resolved and services are operational.
7. **Post-Incident Review (Blameless Post-Mortem):** Within 48 hours, document the timeline, root cause, impact, and **action items** to prevent recurrence. Share the post-mortem with the organization.
