# 💼 Wipro DevOps Interview Q&A

> **Target Profile:** 5–8 years of experience | **Domains:** Linux, Docker, Kubernetes, CI/CD, Cloud, Terraform & IaC

---

## 📑 Table of Contents

| # | Category | Topic |
|---|----------|-------|
| 01–07 | 🔹 Linux + Shell Scripting | Troubleshooting, scripting, automation |
| 08–13 | 🔹 Docker + Containers | Image optimization, networking, secrets |
| 14–22 | 🔹 Kubernetes | Pod troubleshooting, deployments, HPA, Helm |
| 23–28 | 🔹 CI/CD | Pipeline design, rollback, security gates |
| 29–34 | 🔹 Cloud + Infrastructure | HA, DR, networking, cost, data security |
| 35–39 | 🔹 Terraform + IaC | State, modules, secrets, multi-environment |

---

# 🔹 LINUX + SHELL SCRIPTING

---

### 01) How would you troubleshoot high CPU and memory usage on Linux?

**Step 1 – Identify the offending processes.** Start by checking overall system load and then drill into per-process resource consumption:

```bash
# Overall load and uptime
uptime
top -bn1 | head -20

# Sort processes by CPU usage
ps aux --sort=-%cpu | head -20

# Sort processes by memory usage
ps aux --sort=-%mem | head -20

# Real-time view (interactive)
htop
```

**Step 2 – Analyse CPU usage patterns.** Determine whether the load is **user-space** or **system/kernel** bound. High `si` (softirq) or `wa` (iowait) in `top` or `vmstat` points to I/O or interrupt issues rather than pure compute:

```bash
# Check CPU breakdown over time
vmstat 1 5

# Check per-core utilization
mpstat -P ALL 1 5
```

**Step 3 – Analyze memory pressure.** Look at `free`, `/proc/meminfo`, and `smem` to determine whether the system is swapping or hitting OOM:

```bash
free -h
cat /proc/meminfo | grep -iE 'memfree|memavail|swap|buff'
dmesg | grep -i 'oom\|killed'
```

**Step 4 – Resolve the root cause.** Depending on findings:
- **Memory leak:** Identify the leaking process, restart it, and file a bug with the development team.
- **Unbounded process:** Apply **cgroups** or **systemd** resource limits (`MemoryMax`, `CPUQuota`).
- **Zombie/defunct processes:** Kill the parent process or send appropriate signals.
- **Swap thrashing:** Add physical RAM, reduce workload, or increase `vm.swappiness` threshold.

**Prevention:** Set up **Prometheus + Node Exporter** for continuous monitoring, configure **alerting** on `node_load1 > 80%` and `node_memory_MemAvailable_bytes < 10%`, and enforce resource limits via **systemd drop-in** files or container orchestration.

---

### 02) How do you identify the cause of disk I/O bottlenecks?

**Step 1 – Confirm the bottleneck.** Use `iostat` and `vmstat` to check whether I/O wait (`%wa`) is consuming significant CPU time:

```bash
# I/O statistics per device (1-second intervals, 5 samples)
iostat -x 1 5

# Look for %util > 80% and high await (ms) values
iostat -d -k 1 5

# Check I/O wait in vmstat
vmstat 1 5
```

**Step 2 – Pinpoint the processes causing I/O.** Use `iotop` and `pidstat` to identify which processes are generating the most disk activity:

```bash
iotop -oP
pidstat -d 1 5
```

**Step 3 – Examine the I/O pattern.** Determine if the workload is sequential, random reads, or random writes, as each has different mitigation strategies:

```bash
# Check filesystem-level metrics
nfsstat -s  # for NFS mounts
df -hT       # check filesystem type and usage
lsblk        # block device layout
```

**Step 4 – Check the storage layer.**
- **HDD vs SSD:** `await` > 10ms on HDD is normal; >5ms on SSD warrants investigation.
- **RAID degradation:** Check `cat /proc/mdstat` for software RAID health.
- **Cloud storage:** Review EBS/managed disk metrics (burst balance, throughput limits).

**Resolution strategies:**
- **Optimize the application:** Batch writes, reduce fsync frequency, add caching layers.
- **Upgrade storage:** Move from HDD to SSD, increase IOPS provisioned (cloud), or add striping.
- **Reduce contention:** Move logs/metrics to a separate disk, use `noatime` mount option.

---

### 03) Write a Bash approach to monitor and restart a failed service.

A robust monitoring script checks the service health at intervals and performs a **graceful restart** with alerting and logging:

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="myapp"
CHECK_INTERVAL=30          # seconds between health checks
MAX_RESTARTS=5             # restart limit to prevent restart loops
RESTART_WINDOW=300         # 5-minute sliding window for restart counting
LOG_FILE="/var/log/service_monitor.log"
ALERT_EMAIL="ops-team@company.com"

restart_count=0
window_start=$(date +%s)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

send_alert() {
    echo "ALERT: $*" | mail -s "Service Alert: ${SERVICE_NAME}" "$ALERT_EMAIL"
    log "ALERT: $*"
}

check_and_restart() {
    local now=$(date +%s)
    local elapsed=$((now - window_start))

    # Reset counter if the restart window has elapsed
    if (( elapsed > RESTART_WINDOW )); then
        restart_count=0
        window_start=$now
    fi

    # Check if the service is running
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        restart_count=$((restart_count + 1))
        log "Service $SERVICE_NAME is down. Attempting restart #$restart_count"

        if (( restart_count > MAX_RESTARTS )); then
            send_alert "$SERVICE_NAME has restarted $restart_count times in ${RESTART_WINDOW}s. Giving up."
            log "Max restarts exceeded. Alerting and stopping monitor."
            exit 1
        fi

        systemctl start "$SERVICE_NAME"

        # Verify the service came up
        sleep 5
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log "Service $SERVICE_NAME restarted successfully."
        else
            send_alert "$SERVICE_NAME failed to restart on attempt $restart_count."
        fi
    fi
}

# Main loop
log "Starting monitor for $SERVICE_NAME (interval=${CHECK_INTERVAL}s)"
while true; do
    check_and_restart
    sleep "$CHECK_INTERVAL"
done
```

**Key design decisions:**
- **Restart loop protection:** The `MAX_RESTARTS` counter within a `RESTART_WINDOW` prevents the script from endlessly restarting a fundamentally broken service.
- **Systemd native monitoring:** In production, prefer `systemctl` with `Restart=on-failure` and `RestartSec=5` in the unit file rather than an external script.
- **Health endpoint:** For HTTP services, use `curl -sf http://localhost:PORT/health || systemctl restart myapp` instead of just checking the process state.

---

### 04) How would you troubleshoot DNS or connectivity issues from Linux?

**Step 1 – Verify local DNS configuration.** Check the resolver settings and the order of name resolution:

```bash
cat /etc/resolv.conf
cat /etc/nsswitch.conf | grep hosts
systemd-resolve --status   # or resolvectl status
```

**Step 2 – Test DNS resolution step by step.** Go from the application's perspective down to the raw protocol:

```bash
# Application-level lookup
nslookup example.com
dig example.com +short

# Detailed DNS query with all records
dig example.com ANY

# Trace the resolution path
dig +trace example.com

# Check specific DNS server
dig @8.8.8.8 example.com

# Check reverse DNS
dig -x <IP_ADDRESS>
```

**Step 3 – Test network connectivity at each layer.**

```bash
# Layer 3: IP connectivity
ping -c 4 example.com

# Layer 4: TCP port connectivity
nc -zv example.com 443
telnet example.com 443

# Layer 3-4 path analysis
traceroute example.com
mtr example.com        # continuous ping + traceroute

# DNS-specific
host example.com
getent hosts example.com
```

**Step 4 – Diagnose common patterns.**
| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `ping` fails, `ping <IP>` works | DNS misconfiguration | Fix `/etc/resolv.conf`, check DNS server health |
| `ping` works, `curl` fails | Firewall/port blocked | Check `iptables`/`firewalld`, security groups |
| Intermittent failures | Network MTU/DNS TTL issues | Check `ip route`, reduce MTU, flush DNS cache |
| Slow resolution | DNS server overload | Switch resolvers, add local caching (`systemd-resolved`) |

**Step 5 – Advanced tools.**
```bash
# Capture DNS traffic
tcpdump -i any port 53 -nn

# Check for DNS poisoning or cache issues
unbound-host example.com
```

---

### 05) How do you safely manage processes, signals and system resources?

**Signal fundamentals.** Linux signals are the primary mechanism for inter-process communication and lifecycle management:

| Signal | Number | Effect | Use Case |
|--------|--------|--------|----------|
| SIGTERM | 15 | Graceful shutdown | Default for `kill` |
| SIGKILL | 9 | Force kill (non-catchable) | Last resort |
| SIGHUP | 1 | Reload config / hangup | Config reload |
| SIGSTOP | 19 | Pause (non-catchable) | Debugging |
| SIGCONT | 18 | Resume | After SIGSTOP |
| SIGQUIT | 3 | Quit with core dump | Debugging |

**Process lifecycle management:**

```bash
# Graceful shutdown (always try SIGTERM first)
kill -SIGTERM <PID>
sleep 5
# If still running, force kill
kill -SIGKILL <PID>

# Kill all processes matching a pattern
pkill -f "myapp"
killall myapp

# Send signal to process group
kill -SIGTERM -<PGID>
```

**Resource control with cgroups and systemd:**

```bash
# Check current resource limits
ulimit -a

# Set per-process limits
ulimit -n 65536   # file descriptors
ulimit -u 4096    # max user processes

# View cgroup usage for a process
systemd-cgtop
systemctl show -p MemoryCurrent,MemoryMax <service>.service
```

**Systemd resource limits (recommended approach):**

```ini
# /etc/systemd/system/myapp.service.d/limits.conf
[Service]
MemoryMax=2G
MemoryHigh=1.5G
CPUQuota=80%
TasksMax=512
IOWeight=100
```

**Best practices:**
- **Always use `SIGTERM` first.** `SIGKILL` bypasses cleanup handlers, leaving temp files, broken connections, and inconsistent state.
- **Use `systemd` for service management.** It handles restarts, logging (`journalctl`), resource limits, and dependency ordering natively.
- **Monitor with `systemd-cgtop` and `journalctl --since`** to catch resource issues before they cascade.

---

### 06) How would you investigate a sudden spike in open file descriptors?

**Step 1 – Measure the current state.**

```bash
# System-wide open FDs
cat /proc/sys/fs/file-nr
# Output: allocated  maximum  free

# Per-process FD count
ls /proc/*/fd 2>/dev/null | cut -d/ -f3 | sort | uniq -c | sort -rn | head -20

# Specific process
ls -l /proc/<PID>/fd | wc -l

# Process limits
cat /proc/<PID>/limits | grep 'open files'
```

**Step 2 – Identify which process is responsible.**

```bash
# Find top FD consumers
for pid in /proc/[0-9]*/fd; do
    count=$(ls "$pid" 2>/dev/null | wc -l)
    echo "$count $(dirname "$pid" | xargs basename)"
done | sort -rn | head -10
```

**Step 3 – Examine what the FDs are pointing to.**

```bash
ls -l /proc/<PID>/fd | head -50
# Look for patterns:
# - /dev/urandom (normal)
# - socket:[...] (network connections)
# - /var/log/... (log files)
# - anon_inode:[eventpoll] (epoll, usually from high connection count)
```

**Step 4 – Check for common root causes.**
- **Connection leak:** Application opens sockets without closing them → `ls -l /proc/<PID>/fd | grep socket | wc -l`
- **Log file leak:** Application opens log files on each request → check for many `/var/log` or temp file references
- **Database connection pool:** Pool size set too high, or connections not returned properly
- **Epoll/select FDs:** High concurrency web proxy or load balancer

**Step 5 – Remediate and set limits.**

```bash
# Increase system-wide limit
sysctl -w fs.file-max=2097152

# Increase per-user/per-process limits
# /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536

# Systemd service override
systemctl set-property myapp.service LimitNOFILE=65536
```

---

### 07) How do you automate log cleanup without impacting running services?

**Key principle:** Never `rm` a log file that an application has open — the application keeps the file descriptor, the disk space is not reclaimed, and the app may crash on next write. Use **log rotation** or `truncate` instead.

**Approach 1 – Logrotate (the standard solution):**

```conf
# /etc/logrotate.d/myapp
/var/log/myapp/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 appuser appgroup
    sharedscripts
    postrotate
        # Send HUP to signal the app to reopen log files
        systemctl reload myapp.service
    endscript
}
```

**Approach 2 – Truncate without closing FDs (for non-logrotate apps):**

```bash
#!/usr/bin/env bash
# safe_truncate.sh — truncate logs that exceed a size threshold
set -euo pipefail

LOG_DIR="/var/log/myapp"
MAX_SIZE_MB=500
DAYS_TO_KEEP=30

truncate_large_files() {
    find "$LOG_DIR" -name "*.log" -type f -size +${MAX_SIZE_MB}M | while read -r file; do
        # Truncate to zero bytes while keeping the FD open
        truncate -s 0 "$file"
        echo "[$(date)] Truncated $file" >> /var/log/log_cleanup.log
    done
}

cleanup_old_files() {
    find "$LOG_DIR" -name "*.log.*.gz" -type f -mtime +${DAYS_TO_KEEP} -delete
}

truncate_large_files
cleanup_old_files
```

**Approach 3 – Cron-based automation:**

```cron
# Run cleanup at 2 AM daily
0 2 * * * /usr/local/bin/safe_truncate.sh >> /var/log/log_cleanup.log 2>&1

# Force logrotate check for specific app
0 0 * * * /usr/sbin/logrotate -f /etc/logrotate.d/myapp
```

**Important safeguards:**
- **Never delete open files.** Use `truncate -s 0` or rely on logrotate's `copytruncate` if the application cannot handle SIGHUP.
- **Set disk usage alerts** at 80% threshold before cleanup becomes urgent.
- **Use `lsof +L1`** to find deleted files still held open by processes.

---

# 🔹 DOCKER + CONTAINERS

---

### 08) How would you optimize a large Docker image?

**Strategy 1 – Choose the right base image.** The foundation determines the floor size:

```dockerfile
# ❌ Large base — ~200MB
FROM ubuntu:22.04

# ✅ Minimal base — ~20MB
FROM debian:bookworm-slim

# ✅ Ultra-minimal — ~5MB (no package manager)
FROM alpine:3.19

# ✅ Language-specific distroless — smallest + most secure
FROM gcr.io/distroless/java17-debian12
```

**Strategy 2 – Minimize layers and clean up in the same layer.** Every `RUN` creates a new layer. Combine install and cleanup:

```dockerfile
# ❌ Bad — cleanup in separate layer (space wasted)
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# ✅ Good — install and cleanup in one layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean
```

**Strategy 3 – Multi-stage builds.** Compile in one stage, copy only artifacts to the final:

```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /app .

# Runtime stage
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /app /usr/local/bin/app
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/app"]
```

**Strategy 4 – Additional optimizations.**
- Use `.dockerignore` to exclude `node_modules`, `.git`, test files, and documentation.
- Order `COPY` instructions from least to most frequently changing (maximize layer cache).
- Remove build tools, cache directories, and debug symbols from the final image.
- Scan with `dive` to inspect layer contents and find wasted space.
- Use `docker squash` (if available) or buildkit's `docker.inline` exporter to reduce layers.

**Before/after example:** A typical Node.js image goes from ~1.2 GB (node:18 + ubuntu base) to ~180 MB (node:18-alpine + multi-stage + proper .dockerignore).

---

### 09) Explain multi-stage builds for production containers.

Multi-stage builds allow you to use **multiple `FROM` statements** in a single Dockerfile, each representing a separate build stage. Only the final stage becomes the production image.

**How it works:**

```dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Production runtime
FROM node:20-alpine AS production
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=dependencies /app/node_modules ./node_modules
USER appuser
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

**Benefits:**
- **Smaller images:** Build tools, source code, and intermediate artifacts never reach the final image.
- **Improved security:** Fewer packages means smaller attack surface; distroless final stages eliminate shell access.
- **Faster builds:** Docker caches dependency stages separately — `package.json` unchanged means `npm ci` is skipped.
- **Cleaner separation:** Each stage has a single responsibility (dependencies → build → runtime).

**Production best practices:**
- Name stages meaningfully (`AS dependencies`, `AS builder`, `AS production`) for readability and debugging.
- Use `--target` flag to build a specific stage during development: `docker build --target builder .`
- Combine with **Docker BuildKit** for advanced caching: `DOCKER_BUILDKIT=1 docker build .`
- Add health checks and resource limits in the final stage.

---

### 10) How do you troubleshoot a container that repeatedly exits?

**Step 1 – Check exit code and logs.**

```bash
# View container status and exit code
docker ps -a | grep <container_name>

# View container logs
docker logs <container_name> --tail 100

# View logs with timestamps
docker logs <container_name> --tail 100 -t

# Inspect container metadata
docker inspect <container_name> | jq '.[0].State'
```

**Common exit codes and their meaning:**

| Exit Code | Meaning |
|-----------|---------|
| 0 | Normal exit (expected for batch jobs) |
| 1 | Application error |
| 126 | Command invoked cannot execute (permissions) |
| 127 | Command not found |
| 137 | OOM Killed (SIG9) |
| 139 | Segmentation fault |
| 143 | SIGTERM received |

**Step 2 – Check for OOM kills.**

```bash
# Check if container was OOM killed
docker inspect <container_name> | jq '.[0].State.OOMKilled'

# Check host dmesg for OOM events
dmesg -T | grep -i 'oom\|killed'

# Check container memory stats
docker stats --no-stream <container_name>
```

**Step 3 – Debug the application startup.**

```bash
# Run the container interactively to reproduce the issue
docker run -it --entrypoint /bin/sh <image_name>

# Check if required environment variables are set
docker run --rm <image_name> env

# Test the entrypoint command manually
docker run --rm <image_name> <entrypoint_command>
```

**Step 4 – Common root causes.**
- **Missing environment variables or config files** → Check `docker-compose.yml` or `docker run -e` flags.
- **Permission issues** → Ensure entrypoint has `chmod +x` and volumes are mounted with correct ownership.
- **Health check failures** → Verify the health endpoint is accessible within the container.
- **Dependencies not ready** → Use `dockerize`, `wait-for-it`, or orchestration-level health checks.
- **Entrypoint returns immediately** → For stateless apps, the container exits when the main process finishes. Use `tail -f /dev/null` or a proper process manager.

---

### 11) How would you securely manage secrets in containers?

**Approach 1 – Docker Secrets (Swarm only).** Built-in secret management that mounts secrets as files in `/run/secrets`:

```bash
echo "my-db-password" | docker secret create db_password -
docker service create --secret db_password --secret db_user myapp
```

**Approach 2 – External vault (Vault, AWS Secrets Manager, Azure Key Vault).** The most secure approach for production:

```dockerfile
# Do NOT bake secrets into the image
# Instead, mount at runtime from external secrets manager
FROM myapp:latest
# App reads secrets from environment or mounted files at startup
```

```yaml
# docker-compose.yml with external secrets
services:
  app:
    image: myapp:latest
    environment:
      VAULT_ADDR: "https://vault.example.com"
      VAULT_TOKEN: "${VAULT_TOKEN}"
    # Or use mounted secret files
    volumes:
      - ./secrets/db_password:/run/secrets/db_password:ro
```

**Approach 3 – Bind-mount secret files at runtime.**

```bash
# Create secret file on host (never commit to repo)
echo "supersecret" > /secure/db_password
chmod 400 /secure/db_password

# Mount as read-only
docker run -v /secure/db_password:/run/secrets/db_password:ro myapp
```

**Approach 4 – Build-time secrets with BuildKit.**

```bash
DOCKER_BUILDKIT=1 docker build \
  --secret id=gpg,key=/home/user/.gnupg/secring.gpg \
  --secret id=npm,env=NPM_TOKEN \
  -t myapp .
```

```dockerfile
# Dockerfile
RUN --mount=type=secret,id=npm \
    export NPM_TOKEN=$(cat /run/secrets/npm) && \
    npm publish
```

**Security rules:**
- **Never embed secrets in Docker images** — they persist in layers and are exposed by `docker history`/`docker inspect`.
- **Never pass secrets via `-e` in docker-compose** — they appear in `docker inspect` and process listings.
- **Always use read-only mounts** (`:ro`) for secret files.
- **Rotate secrets regularly** and use short-lived tokens where possible.
- **Use Vault Agent or CSI drivers** for Kubernetes — they handle secret rotation automatically.

---

### 12) How do Docker networking modes affect service communication?

Docker provides several networking drivers, each with different isolation and connectivity characteristics:

**Bridge (default):**

```bash
docker network create --driver bridge mybridge
docker run --network mybridge --name web nginx
docker run --network mybridge --name api myapi

# Containers on the same bridge can reach each other by name
docker exec web curl http://api:8080
```

- **Isolated** from the host network; containers on the same bridge communicate by container name (DNS).
- **No cross-network communication** without explicit `--network connect`.
- Best for **single-host multi-container apps**.

**Host:**

```bash
docker run --network host myapp
```

- Container shares the host's network namespace entirely — **no port mapping needed**, no NAT overhead.
- **No isolation** — port conflicts are possible, security boundary is weaker.
- Best for **maximum performance** when isolation is not required.

**None:**

```bash
docker run --network none myapp
```

- Completely **isolated** — only loopback (`lo`) interface.
- Useful for **batch jobs** that don't need network access.

**Overlay (Swarm only):**

```bash
docker network create --driver overlay myoverlay
docker service create --network myoverlay --name web nginx
```

- Spans **multiple Docker hosts** in a Swarm cluster.
- Enables cross-host container communication with built-in service discovery.

**Macvlan:**

```bash
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 macnet
```

- Assigns each container a **real MAC address** on the physical network.
- Containers appear as **physical devices** on the network.
- Best for **legacy apps** that require direct network presence.

**Choosing the right network:**
| Requirement | Recommended Driver |
|------------|-------------------|
| Single-host app | Bridge |
| Multi-host Swarm | Overlay |
| Maximum performance | Host |
| Legacy network integration | Macvlan |
| Isolated batch jobs | None |

---

### 13) How would you reduce container startup time?

**Strategy 1 – Optimize the image size.** Smaller images pull and extract faster:

```dockerfile
# Use minimal base images
FROM alpine:3.19        # ~5MB vs ~100MB for ubuntu
# or
FROM gcr.io/distroless/static-debian12  # ~2MB
```

**Strategy 2 – Optimize layer ordering for caching.**

```dockerfile
# Copy dependency files first (rarely change)
COPY go.mod go.sum ./
RUN go mod download

# Copy source code (changes frequently)
COPY . .
RUN go build -o /app
```

**Strategy 3 – Reduce startup work.**

```dockerfile
# Pre-warm caches at build time, not runtime
RUN python -c "import nltk; nltk.download('punkt')"

# Pre-resolve DNS or warm connections
RUN apk add --no-cache bind-tools && \
    host api.example.com > /dev/null
```

**Strategy 4 – Application-level optimizations.**
- **Use compiled languages** (Go, Rust) instead of interpreted ones for lower startup latency.
- **Reduce dependency count** and initialization time (lazy loading, deferred initialization).
- **Use Nginx/Envoy as sidecar** instead of a full web server framework for static content.
- **Pre-link binaries** for native apps (`ldconfig` at build time).

**Strategy 5 – Orchestration-level optimizations.**

```yaml
# Kubernetes: Pre-pull images to avoid pull-on-demand delay
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: image-prepull
spec:
  template:
    spec:
      containers:
      - name: prepull
        image: myapp:latest
        command: ["sleep", "infinity"]
      initContainers:
      - name: puller
        image: myapp:latest
        command: ["true"]
```

**Measurable impact:** A Java application can go from 30s startup (cold JVM, large image) to 5s (GraalVM native image, small base, warmed dependencies).

---

# 🔹 KUBERNETES

---

### 14) How would you troubleshoot a Pod stuck in CrashLoopBackOff?

**Step 1 – Inspect the Pod state and events.**

```bash
# Check pod status
kubectl get pod <pod-name> -n <namespace> -o wide

# Describe the pod for events and recent state
kubectl describe pod <pod-name> -n <namespace>

# Check the last state
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.lastState}'
```

**Step 2 – Check application logs (both current and previous).**

```bash
# Current container logs
kubectl logs <pod-name> -n <namespace> --tail=100

# Previous container logs (before the crash)
kubectl logs <pod-name> -n <namespace> --previous --tail=100

# All containers in the pod
kubectl logs <pod-name> -n <namespace> -c <container-name> --previous
```

**Step 3 – Common causes and fixes.**

| Cause | Diagnostic | Fix |
|-------|-----------|-----|
| Application crash (runtime error) | `kubectl logs --previous` shows stack trace | Fix the code, add error handling |
| Missing env/config | Logs show `Missing required config` errors | Verify ConfigMap/Secret mounted correctly |
| OOMKilled | `kubectl describe pod` shows `OOMKilled` | Increase memory limits: `resources.limits.memory` |
| Crash on startup | Logs end abruptly, no app output | Add startup script, fix entrypoint, check dependencies |
| Liveness probe failing | Pod restarts even when app is healthy | Relax probe thresholds, increase `initialDelaySeconds` |
| Dependency not ready | Connection refused errors in logs | Add init containers, use service health checks |

**Step 4 – Check resource limits and constraints.**

```bash
# Check if OOMKilled
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

# Check resource usage
kubectl top pod <pod-name>

# Check node capacity
kubectl describe node <node-name> | grep -A5 "Allocated resources"
```

**Step 5 – Debug interactively.**

```bash
# Run a debug container in the same pod
kubectl debug -it <pod-name> --image=busybox --target=<container-name>

# Or exec into a crashing pod quickly (if it stays up long enough)
kubectl exec -it <pod-name> -- /bin/sh
```

---

### 15) How do you diagnose Pending Pods caused by scheduling constraints?

**Step 1 – Check the events and conditions.**

```bash
kubectl describe pod <pod-name> -n <namespace>
# Look for:
# - FailedScheduling events
# - Unschedulable condition
# - Insufficient cpu/memory/ephemeral-storage
```

**Step 2 – Common causes and diagnostics.**

```bash
# Check node resources
kubectl top nodes
kubectl describe nodes | grep -A10 "Allocated resources"

# Check if any nodes exist
kubectl get nodes

# Check for taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Check for node selectors / affinity issues
kubectl get pod <pod-name> -o jsonpath='{.spec.nodeSelector}'
kubectl get pod <pod-name> -o jsonpath='{.spec.affinity}'

# Check for PersistentVolume binding issues
kubectl get pvc -n <namespace>
kubectl get pv

# Check for resource quotas
kubectl describe quota -n <namespace>
```

**Step 3 – Remediation strategies.**

| Issue | Solution |
|-------|----------|
| Insufficient CPU/memory | Scale up nodes, reduce pod resource requests, use cluster autoscaler |
| Taints without tolerations | Add `tolerations` to pod spec or remove taints |
| NodeSelector/Affinity mismatch | Update node labels or pod affinity rules |
| PV not bound | Check PV capacity, storage class, and access modes |
| ResourceQuota exceeded | Increase quota or reduce requests |
| Pod anti-affinity too strict | Relax `requiredDuringSchedulingIgnoredDuringExecution` to `preferredDuringScheduling...` |
| Insufficient ephemeral storage | Increase `requests.ephemeral-storage` or add node storage |

**Step 4 – Use scheduler debug tools.**

```bash
# Run a dry-run to see scheduling analysis
kubectl create -f pod.yaml --dry-run=server -o json

# Check scheduler logs (if running in-cluster)
kubectl logs -n kube-system deployment/kubernetes-scheduler

# Use kubectl debug to get scheduling feasibility
kubectl get events --field-selector reason=FailedScheduling
```

---

### 16) How would you troubleshoot a Kubernetes Service returning 503?

A **503 Service Unavailable** means the Service exists but cannot route traffic to any healthy backend.

**Step 1 – Verify the Service has endpoints.**

```bash
# Check if the Service has endpoints
kubectl get endpoints <service-name> -n <namespace>
# If ENDPOINTS shows "<none>", the Service has no matching Pods

# Check the Service definition
kubectl get svc <service-name> -n <namespace> -o yaml
```

**Step 2 – Common causes.**

| Cause | Diagnostic | Fix |
|-------|-----------|-----|
| No matching endpoints | `kubectl get endpoints` shows `<none>` | Check label selector matches running Pods |
| Pods not ready | Readiness probe failing | Check probe config, fix the health endpoint |
| All Pods in CrashLoopBackOff | `kubectl get pods` shows crashes | Fix the underlying Pod issue (Q14) |
| Wrong selector label | Service selector doesn't match Pod labels | Fix selector or Pod template labels |
| NetworkPolicy blocking | No endpoints but connectivity denied | Check NetworkPolicy rules |

**Step 3 – Deep-dive into Service networking.**

```bash
# Verify DNS resolution inside a Pod
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup <service-name>.<namespace>.svc.cluster.local

# Test connectivity from another Pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -v http://<service-name>:<port>/health

# Check kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy

# Verify iptables/IPVS rules
kubectl get ep <service-name> -o yaml
```

**Step 4 – Check Ingress controller (if applicable).**

```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
kubectl logs -n <ingress-namespace> deployment/<ingress-controller>
```

---

### 17) How do readiness and liveness probes affect production availability?

**Liveness Probe — "Is it alive?"** Determines whether a container should be **restarted**.

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30    # Wait for startup
  periodSeconds: 10          # Check every 10s
  failureThreshold: 3        # 3 failures → restart
  timeoutSeconds: 5
```

**Readiness Probe — "Is it ready to serve traffic?"** Determines whether the Pod should receive **traffic via Service endpoints**.

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3        # 3 failures → remove from Service
  successThreshold: 1        # 1 success → add back to Service
  timeoutSeconds: 3
```

**Startup Probe — "Is it still starting?"** Prevents premature liveness kills during slow startup.

```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10          # Allows up to 300s for startup
```

**Production impact:**

| Misconfiguration | Consequence | Fix |
|-----------------|-------------|-----|
| Liveness too aggressive | Pods restart unnecessarily, causing load spikes | Increase `initialDelaySeconds`, `failureThreshold` |
| Readiness too lenient | Traffic sent to unready Pods, causing errors | Tighten check interval, add real dependency checks |
| No startup probe | Slow-starting apps killed by liveness before ready | Add `startupProbe` with generous timeout |
| Probes on same endpoint | App returns 200 for startup but not fully ready | Separate `/healthz` (alive) from `/ready` (serving) |
| Probe endpoint not resilient | Flapping (ready ↔ not ready) causes thundering herd | Add hysteresis, retry logic, circuit breaker |

**Best practices:**
- **Liveness** checks: Is the process running and not deadlocked? (basic health, thread pool alive, GC not stuck)
- **Readiness** checks: Can I serve requests? (DB connected, cache warmed, downstream deps available)
- **Startup** probe: How long does it take to start? (separate from liveness to avoid premature restarts)
- Use **separate endpoints** for liveness and readiness — readiness should be stricter than liveness.

---

### 18) How would you configure HPA for unpredictable traffic?

**Standard HPA with CPU/memory:**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Pods
        value: 4
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Pods
        value: 2
        periodSeconds: 120
```

**HPA with custom metrics (request rate, queue depth):**

```yaml
metrics:
- type: Pods
  pods:
    metric:
      name: http_requests_per_second
    target:
      type: AverageValue
      averageValue: "100"
- type: Object
  object:
    metric:
      name: rabbitmq_queue_messages
    describedObject:
      apiVersion: v1
      kind: Service
      name: rabbitmq
    target:
      type: Value
      value: "1000"
```

**Design decisions for unpredictable traffic:**

| Aspect | Recommendation |
|--------|---------------|
| `minReplicas` | Set to handle baseline + surge absorption (at least 3 for HA) |
| `maxReplicas` | Cap at cluster capacity; coordinate with **Cluster Autoscaler** |
| `stabilizationWindowSeconds` | Scale-up: 60s (respond quickly); Scale-down: 300s (avoid flapping) |
| Custom metrics | Use **Prometheus Adapter** for request rate, p99 latency, queue depth |
| Pod readiness | Increase `initialDelaySeconds` so new Pods don't count as ready too early |
| Cluster Autoscaler | Set scale-up delay to match HPA scale-up policy for smooth scaling |

**KEDA (Kubernetes Event-driven Autoscaling):** For event-driven workloads (queues, cron, HTTP), KEDA provides more granular scaling:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: myapp-scaledobject
spec:
  scaleTargetRef:
    name: myapp
  minReplicaCount: 1
  maxReplicaCount: 100
  triggers:
  - type: rabbitmq
    metadata:
      queueName: myqueue
      queueLength: "10"
```

---

### 19) When would you use rolling, blue-green or canary deployments?

**Rolling Update (default in Kubernetes):**

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
```

- **When to use:** Standard deployments with backward-compatible changes, low risk, small-to-medium impact.
- **Pros:** Zero downtime, simple, built into Deployment resource.
- **Cons:** Old and new versions run simultaneously (requires backward compatibility), no easy rollback point.

**Blue-Green:**

```yaml
# Blue (current) and Green (new) — swap the Service selector
# Blue
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  template:
    metadata:
      labels:
        version: blue
    spec:
      containers:
      - image: myapp:1.0

# Green
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  template:
    metadata:
      labels:
        version: green
    spec:
      containers:
      - image: myapp:2.0

# Service — switch selector from blue to green
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    version: green   # ← change this to switch traffic
```

- **When to use:** Major version changes, database migrations, zero-downtime requirement with instant rollback.
- **Pros:** Instant rollback (switch selector back), full QA on new version before traffic, zero-downtime.
- **Cons:** **2× resource usage** during transition, requires infrastructure automation.

**Canary:**

```yaml
# Canary with Istio traffic splitting
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-vs
spec:
  hosts:
  - myapp
  http:
  - route:
    - destination:
        host: myapp
        subset: v1   # 90% traffic
      weight: 90
    - destination:
        host: myapp
        subset: v2   # 10% traffic (canary)
      weight: 10
```

- **When to use:** High-risk changes, gradual rollout with monitoring, A/B testing.
- **Pros:** **Minimal blast radius**, data-driven promotion, early error detection.
- **Cons:** Complex setup (requires service mesh or advanced ingress), slower rollout, harder debugging.

| Strategy | Risk Tolerance | Resource Cost | Rollback Speed | Complexity |
|----------|---------------|---------------|----------------|------------|
| Rolling | Medium | Low | Slow (redeploy) | Low |
| Blue-Green | Low | High (2×) | Instant | Medium |
| Canary | Very Low | Low-Medium | Fast (revert weights) | High |

---

### 20) How do you manage application configuration and secrets?

**ConfigMaps — for non-sensitive configuration:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  DATABASE_HOST: "db.example.com"
  # Can also store entire config files
  application.properties: |
    server.port=8080
    spring.profiles.active=prod
```

**Mounting ConfigMaps:**

```yaml
# As environment variables
envFrom:
- configMapRef:
    name: app-config

# As files (for hot-reload)
volumeMounts:
- name: config-volume
  mountPath: /etc/app
volumes:
- name: config-volume
  configMap:
    name: app-config
```

**Secrets — for sensitive data:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQxMjM=    # base64 encoded
  API_KEY: YWJjZGVmZw==
```

**Production-grade secret management:**

| Approach | Use Case | Tool |
|----------|---------|------|
| Native Kubernetes Secrets | Small teams, non-compliant environments | `kubectl create secret` (base64 only — not encryption) |
| External Secrets Operator | Sync from external vault | External Secrets + AWS Secrets Manager / Vault |
| CSI Driver | Runtime secret rotation | Secrets Store CSI Driver |
| Vault Agent Sidecar | Dynamic secrets, short-lived tokens | HashiCorp Vault + Init Container |

**Vault Agent Sidecar pattern:**

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      serviceAccountName: vault-agent
      initContainers:
      - name: vault-agent
        image: hashicorp/vault:1.15
        command:
        - vault agent -config=/vault/config/agent.hcl
        volumeMounts:
        - name: vault-secrets
          mountPath: /vault/secrets
      containers:
      - name: app
        image: myapp
        volumeMounts:
        - name: vault-secrets
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: vault-secrets
        emptyDir:
          medium: Memory    # Keep secrets in RAM only
```

**Best practices:**
- **Never store secrets in ConfigMaps** or plain text in Git repositories.
- Enable **Encryption at Rest** for etcd secrets: `--encryption-provider-config`.
- Use **least-privilege ServiceAccounts** with RBAC to limit secret access.
- **Rotate secrets** automatically using Vault dynamic secrets or AWS Secrets Manager rotation.

---

### 21) How would you troubleshoot node-level failures in EKS/AKS/GKE?

**Step 1 – Identify the scope of the failure.**

```bash
# Check node status
kubectl get nodes -o wide
kubectl describe node <node-name>

# Check which Pods are affected
kubectl get pods --field-selector spec.nodeName=<node-name> -o wide

# Check events on the node
kubectl get events --field-selector involvedObject.name=<node-name> --sort-by='.lastTimestamp'
```

**Step 2 – Common node-level issues.**

| Issue | Diagnostic | Cloud-Specific Action |
|-------|-----------|----------------------|
| Node NotReady | `kubectl get nodes` shows NotReady | Check node instance status in cloud console |
| Disk pressure | `kubelet` evicting Pods | Check EBS/disk usage, clear temp files |
| Memory pressure | OOM at node level | Scale up node type, reduce pod requests |
| Network plugin failure | CNI pods crash-looping | Restart CNI DaemonSet, check VPC/security groups |
| API server unreachable | `Kublet` cannot reach API | Check network policies, NAT Gateway, VPC endpoints |
| Instance termination | Cloud lifecycle events | Check instance lifecycle, ASG health checks |

**Step 3 – Cloud provider diagnostics.**

```bash
# EKS — check Control Plane API server
aws eks describe-cluster --name <cluster-name>

# EKS — check managed node group
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <ng-name>

# AKS — check node pool
az aks nodepool show --resource-group <rg> --cluster-name <aks> --name <pool>

# GKE — check node pool
gcloud container node-pools describe <pool> --cluster <cluster>
```

**Step 4 – kubelet and container runtime logs.**

```bash
# SSH into the node (if possible)
ssh ec2-user@<node-ip>

# Check kubelet logs
journalctl -u kubelet --since "30 min ago"

# Check container runtime
journalctl -u containerd --since "30 min ago"

# Check dmesg for hardware/kernel issues
dmesg -T | tail -50
```

**Step 5 – Recovery actions.**
- **Replace unhealthy nodes:** Delete from node group → auto-replacement via ASG/managed node group.
- **Drain and cordon:** `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` before decommissioning.
- **Enable cluster autoscaler** to automatically replace unhealthy nodes.
- **Set up CloudWatch/Azure Monitor/GCP monitoring** alerts for node health, disk, and memory pressure.

---

### 22) How do Helm charts support reusable Kubernetes deployments?

**Helm chart structure:**

```
myapp-chart/
├── Chart.yaml              # Metadata (name, version, dependencies)
├── values.yaml             # Default configuration values
├── values-production.yaml  # Environment-specific overrides
├── charts/                 # Sub-chart dependencies
└── templates/
    ├── deployment.yaml     # Templated Deployment
    ├── service.yaml        # Templated Service
    ├── configmap.yaml
    ├── _helpers.tpl        # Reusable template functions
    └── NOTES.txt           # Post-install instructions
```

**Template example with values:**

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    app: {{ include "myapp.labels" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: {{ .Values.service.port }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        env:
        - name: LOG_LEVEL
          value: {{ .Values.config.logLevel | quote }}
```

**Values override:**

```yaml
# values-production.yaml
replicaCount: 6
image:
  repository: myregistry.myapp
  tag: v2.3.1
resources:
  limits:
    cpu: "2"
    memory: "4Gi"
  requests:
    cpu: "500m"
    memory: "2Gi"
```

**Key benefits:**
- **Parameterization:** Single chart, multiple environments via different `values-*.yaml` files.
- **Versioning:** Chart versions track deployment manifests independently of container image tags.
- **Dependency management:** `requirements.yaml` / `Chart.yaml` dependencies manage sub-charts.
- **Lifecycle hooks:** Pre-install, post-upgrade, and test hooks for migrations and validations.
- **Community library:** 25,000+ public charts for Nginx, Postgres, Redis, Elasticsearch, etc.

**Installation:**

```bash
# Install with default values
helm install myapp ./myapp-chart

# Install with environment-specific values
helm install myapp ./myapp-chart -f values-production.yaml

# Upgrade in place
helm upgrade myapp ./myapp-chart -f values-production.yaml

# Rollback to previous release
helm rollback myapp 2
```

**Advanced patterns:**
- Use **Helmfile** to manage multiple releases across namespaces/clusters declaratively.
- Use **CI/CD integration** with `helm diff plugin` for pre-deployment review.
- Store charts in a private registry for version control and audit trail.

---

# 🔹 CI/CD

---

### 23) How would you design a secure Jenkins or GitHub Actions pipeline?

**GitHub Actions Pipeline (recommended):**

```yaml
# .github/workflows/deploy.yml
name: Secure CI/CD Pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  security-events: write

jobs:
  # Stage 1: Build
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Build Docker image
      run: docker build -t myapp:${{ github.sha }} .

    # Stage 2: Test
    - name: Run unit tests
      run: npm test

    # Stage 3: Security scanning
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: "myapp:${{ github.sha }}"
        format: "sarif"
        output: "trivy-results.sarif"
        severity: "CRITICAL,HIGH"

    - name: Upload Trivy results to GitHub Security
      uses: github/codeql-action/upload-sarif@v3
      if: always()
      with:
        sarif_file: "trivy-results.sarif"

    # Stage 4: Sign image
    - name: Sign image with Cosign
      run: |
        cosign sign --key env://COSIGN_KEY myapp:${{ github.sha }}

    # Stage 5: Push to registry
    - name: Push image
      if: github.ref == 'refs/heads/main'
      run: |
        echo "${{ secrets.REGISTRY_TOKEN }}" | docker login -u "${{ secrets.REGISTRY_USER }}" --password-stdin
        docker push myapp:${{ github.sha }}

    # Stage 6: Deploy
    - name: Deploy to Kubernetes
      if: github.ref == 'refs/heads/main'
      uses: azure/k8s-deploy@v4
      with:
        namespace: production
        manifests: k8s/deployment.yaml
        images: "myapp:${{ github.sha }}"
```

**Security principles:**

| Principle | Implementation |
|-----------|---------------|
| Least privilege | Use OIDC for cloud auth (no long-lived tokens), `permissions: contents: read` |
| Secret management | Store in GitHub Secrets / Jenkins Credentials — never in repo or logs |
| Image scanning | Trivy, Snyk, Grype for CVE detection before deploy |
| Image signing | Cosign (Sigstore), Docker Content Trust |
| Branch protection | Require PR approval, status checks, squash merge |
| Pipeline as code | Store in Git, code review changes to CI/CD |
| Audit logging | Enable Jenkins audit trail, GitHub audit log |
| Environment protection | Require manual approval for production, environment-specific secrets |
| Agent hygiene | Use ephemeral runners, clean workspace between jobs |

**Jenkins-specific security:**
- Use **Pipeline as Code** (Jenkinsfile in Git) instead of UI-based jobs.
- Enable **RBAC** with role-based folder permissions.
- Use **Credentials Binding Plugin** for secret injection.
- Disable script console in production, restrict Groovy sandbox.
- Run build agents in **isolated containers** (Kubernetes plugin).

---

### 24) A deployment succeeds but the application fails. How do you debug it?

**Step 1 – Check the deployment pipeline output.**

```bash
# Review the CI/CD logs for the last deployment
# Look for warnings during build, image push, and kubectl apply
```

**Step 2 – Check the application from the outside in.**

```bash
# External → Service → Pod
curl -v http://myapp.example.com/health

# Check if the Service has endpoints
kubectl get endpoints myapp

# Check Pod status
kubectl get pods -l app=myapp -o wide

# Check Ingress/LB status
kubectl get ingress,svc -l app=myapp
```

**Step 3 – Check application logs.**

```bash
# Application logs
kubectl logs -l app=myapp --tail=200 --follow

# Previous container logs (if restarted)
kubectl logs -l app=myapp --previous --tail=200

# All containers including init
kubectl logs -l app=myapp -c <container-name> --previous
```

**Step 4 – Debug inside the running Pod.**

```bash
# Exec into the Pod
kubectl exec -it <pod-name> -- /bin/sh

# Check mounted config
cat /etc/config/app.properties
ls -la /etc/secrets/

# Check environment variables
env | sort

# Check network connectivity to dependencies
nslookup db.example.com
curl http://redis:6379

# Check disk space
df -h

# Check file permissions
ls -la /app/
```

**Step 5 – Common post-deployment issues.**

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| 502/503 from LB | No ready Pods / readiness failing | Check readiness probes, logs |
| Application errors | Config drift between environments | Compare ConfigMap to expected values |
| Dependency connection refused | Wrong DNS, network policy, missing service | Check service name, NetworkPolicy |
| OOM after deployment | Increased memory usage in new version | Increase limits, profile memory |
| SSL/TLS errors | Certificate expired or wrong domain | Check cert expiry, SANs |
| Slow response | Resource contention, cold cache | Check metrics, add warmup endpoint |

**Step 6 – Rollback and iterate.**

```bash
# Kubernetes rollback
kubectl rollout undo deployment/myapp

# Helm rollback
helm rollback myapp <revision-number>

# Check rollout history
kubectl rollout history deployment/myapp
```

---

### 25) How would you implement automated rollback in CI/CD?

**Strategy 1 – Kubernetes native rollback with health gate:**

```yaml
# .github/workflows/deploy.yml
name: Deploy with Auto-Rollback
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Deploy new version
      run: |
        kubectl set image deployment/myapp \
          myapp=myregistry/myapp:${{ github.sha }}

    - name: Wait for rollout
      run: |
        kubectl rollout status deployment/myapp --timeout=300s

    - name: Validate deployment
      run: |
        # Check HTTP health endpoint
        for i in {1..10}; do
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            http://myapp.example.com/health)
          if [ "$STATUS" = "200" ]; then
            echo "Health check passed"
            exit 0
          fi
          echo "Attempt $i: HTTP $STATUS"
          sleep 10
        done
        echo "Health check failed after 10 attempts"
        exit 1

    - name: Auto-rollback on failure
      if: failure()
      run: |
        kubectl rollout undo deployment/myapp
        kubectl rollout status deployment/myapp --timeout=300s
```

**Strategy 2 – Helm-based rollback with post-deploy tests:**

```yaml
# Helm post-upgrade hook
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ .Release.Name }}-verify"
  annotations:
    "helm.sh/hook": post-upgrade
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      containers:
      - name: verify
        image: curlimages/curl
        command:
        - sh
        - -c
        - |
          for i in $(seq 1 30); do
            curl -sf http://myapp/health && exit 0
            sleep 5
          done
          exit 1
      restartPolicy: Never
```

**Strategy 3 – GitOps with ArgoCD automatic rollback:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
    syncOptions:
    - PruneLast=true
    - CreateNamespace=true
```

**Key principles:**
- **Always have a health check gate** — rollback is only as good as the validation it triggers on.
- **Keep rollback fast** — Kubernetes `rollout undo` and `helm rollback` are instant.
- **Version everything** — immutable image tags (`${{ github.sha }}`) enable precise rollback.
- **Notify on rollback** — Slack/PagerDuty alert when auto-rollback occurs.
- **Test rollback** — Include rollback testing in staging CI/CD runs.

---

### 26) How do you manage artifacts across environments?

**Artifact versioning and promotion model:**

```
Build → Test → Staging → Production
   │       │        │          │
   └───────┼────────┼──────────┘
           │        │
     Same immutable   Same immutable
     artifact tag     artifact tag
```

**Docker image lifecycle:**

```bash
# Build — tag with commit SHA (immutable)
docker build -t myapp:${GITHUB_SHA} .

# Test environment — promote by tag
docker tag myapp:${GITHUB_SHA} myapp:test

# Staging — same artifact, different tag
docker tag myapp:${GITHUB_SHA} myapp:staging

# Production — tag with semantic version
docker tag myapp:${GITHUB_SHA} myapp:v1.2.3
docker tag myapp:${GITHUB_SHA} myapp:latest
```

**Registry organization:**

```
registry.company.com/
├── myapp/
│   ├── develop/       # Branch builds
│   ├── test/          # QA environment
│   ├── staging/       # Pre-production
│   └── production/    # Released versions
```

**GitHub Actions multi-environment promotion:**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Build and push
      run: |
        docker build -t registry.company.com/myapp:${{ github.sha }} .
        docker push registry.company.com/myapp:${{ github.sha }}

  deploy-test:
    needs: build
    environment: test
    steps:
    - name: Deploy to test
      run: |
        helm upgrade myapp ./chart \
          --set image.tag=${{ github.sha }} \
          --namespace test

  deploy-production:
    needs: deploy-staging
    environment: production
    steps:
    - name: Tag as release
      run: |
        docker tag registry.company.com/myapp:${{ github.sha }} \
          registry.company.com/myapp:${{ github.ref_name }}
        docker push registry.company.com/myapp:${{ github.ref_name }}
```

**Best practices:**
- **Build once, promote** — never rebuild for different environments; promotes consistency.
- **Use immutable tags** — SHA or semantic version, not `latest` in CI/CD pipelines.
- **Environment isolation** — separate registry paths, namespaces, and access policies per environment.
- **Artifact retention** — set retention policies (e.g., keep last 90 days, all releases).
- **Scan at each promotion** — re-scan artifacts as new CVEs are discovered.

---

### 27) How would you add quality and security gates to a pipeline?

**Comprehensive pipeline with gates:**

```yaml
name: CI/CD with Quality & Security Gates
on:
  pull_request:
    branches: [main]

jobs:
  quality-gate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    # Gate 1: Code quality
    - name: Lint code
      run: npm run lint

    - name: SonarQube analysis
      uses: SonarSource/sonarqube-scan-action@v4
      env:
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_URL }}

    # Gate 2: Tests
    - name: Run unit tests
      run: npm test -- --coverage
    - name: Check coverage threshold
      run: npm run coverage:check  # fail if < 80%

    # Gate 3: SAST (Static Application Security Testing)
    - name: Run CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: javascript
    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v3

  security-gate:
    needs: quality-gate
    runs-on: ubuntu-latest
    steps:
    # Gate 4: Dependency scanning
    - name: Run npm audit
      run: npm audit --audit-level=high

    - name: Run OSV-Scanner
      uses: google/osv-scanner-action@v1
      with:
        fail-on-vuln: HIGH

    # Gate 5: Container scanning
    - name: Build image
      run: docker build -t myapp:pr-${{ github.event.pull_request.number }} .

    - name: Trivy image scan
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: "myapp:pr-${{ github.event.pull_request.number }}"
        exit-code: "1"
        severity: "CRITICAL,HIGH"

    # Gate 6: Secret scanning
    - name: Trivy filesystem scan (secrets)
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: "fs"
        scan-ref: "."
        trivy-config: "/tmp/trivy-secret-config.json"

    # Gate 7: DAST (optional for PR)
    - name: Run DAST scan
      if: github.ref == 'refs/heads/main'
      uses: zaproxy/action-full-scan@v0.9.0
      with:
        target: "http://myapp-staging.example.com"
```

**Gate matrix:**

| Gate | Tool | What It Catches | Stage |
|------|------|----------------|-------|
| Code quality | ESLint, Prettier, SonarQube | Code smells, duplication, complexity | Build |
| Unit tests | Jest, PyTest, JUnit | Logic errors, regressions | Build |
| SAST | CodeQL, Semgrep, Checkmarx | SQL injection, XSS, hardcoded secrets | Build |
| Dependency scan | npm audit, OSV-Scanner, Dependabot | Known vulnerable dependencies | Build |
| Container scan | Trivy, Grype, Snyk | OS/CVE vulnerabilities in images | Build |
| IaC scan | Checkov, tfsec, terrascan | Misconfigured infrastructure | Plan |
| DAST | ZAP, Burp Suite, OWASP | Runtime vulnerabilities (auth, injection) | Staging |
| Secret scan | Trivy, gitleaks, detect-secrets | Leaked API keys, passwords, tokens | Pre-commit |

**Enforcement:**
- Configure **branch protection rules** to require all gates to pass before merge.
- Set **security policy thresholds** (block on HIGH+ CVEs, allow with waiver on LOW).
- Generate **PR comments** with scan results for developer feedback.
- Track **security metrics** in a dashboard (time to fix, vulnerability trend).

---

### 28) How do you prevent concurrent deployments from causing conflicts?

**Strategy 1 – Pipeline-level locking.**

```yaml
# GitHub Actions concurrency group
name: Deploy
on:
  push:
    branches: [main]

concurrency:
  group: deploy-production
  cancel-in-progress: false  # Wait for previous to finish (do NOT cancel)

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Deploy
      run: helm upgrade --install myapp ./chart
```

**Strategy 2 – Kubernetes-native deployment ordering.**

```yaml
# Use resourceVersion and revisionHistoryLimit for atomic updates
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  revisionHistoryLimit: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0       # Zero-downtime
      maxSurge: 1             # Only 1 new Pod at a time
```

**Strategy 3 – Database migration locking.**

```yaml
# Use a job that runs before deployment with a lock
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate-lock
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: myapp:migrate
        command: ["flyway", "migrate"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
      restartPolicy: Never
```

**Strategy 4 – Consul/Nomad distributed locking.**

```bash
# Acquire a leader lock before deploying
consul lock "deploy/myapp" -- \
  bash -c 'kubectl rollout restart deployment/myapp'
```

**Strategy 5 – CI/CD orchestrator-level controls.**

| Tool | Mechanism |
|------|-----------|
| Jenkins | `lock(resource: 'deploy-production')` in pipeline script |
| GitHub Actions | `concurrency` group with `cancel-in-progress: false` |
| ArgoCD | Application-level sync with `syncOptions: PruneLast=true` |
| GitLab CI | `resource_group` keyword for job-level locking |
| Spinnaker | Pipeline-level locks via `lock` stage |

**Best practices:**
- **Never cancel in-progress deployments** — set `cancel-in-progress: false` to let the running deployment finish.
- **Use immutable deployments** — Kubernetes `kubectl apply` is idempotent, `helm upgrade` tracks revisions.
- **Serialize database migrations** — use a single migration runner with advisory locks or a leader election pattern.
- **Add deployment cooldowns** — minimum interval between deployments (e.g., 5 minutes) to allow health checks.
- **Use blue-green or canary** — concurrent deploys become less dangerous when traffic is split.

---

# 🔹 CLOUD + INFRASTRUCTURE

---

### 29) How would you design highly available infrastructure on AWS/Azure/GCP?

**Core principles of HA design:**

| Principle | AWS | Azure | GCP |
|-----------|-----|-------|-----|
| Multi-AZ/Region | Multi-AZ + cross-region replication | Availability Zones + regions | Multi-zone + regions |
| Compute HA | Auto Scaling Group | Availability Set / Scale Set | Managed Instance Group |
| Load Balancer | ALB/NLB (multi-AZ) | Application Gateway / LB | Cloud Load Balancing |
| Database HA | RDS Multi-AZ | SQL Managed Instance HA | Cloud SQL HA (regional) |
| Storage HA | S3 (11×9s durability) | Storage Replica / ZRS | Multi-regional storage |

**AWS example — Multi-AZ application architecture:**

```
                      Internet
                          │
                    ┌─────┴─────┐
                    │  Route 53  │ (DNS Failover)
                    └─────┬─────┘
                          │
              ┌───────────┴───────────┐
              │   Application LB      │ (ALB, Multi-AZ)
              └───────────┬───────────┘
                  ┌────────┴────────┐
          ┌───────┴───────┐ ┌───────┴───────┐
          │  AZ-1         │ │  AZ-2         │
          │  EC2 x3       │ │  EC2 x3       │
          │  (ASG)        │ │  (ASG)        │
          └───────┬───────┘ └───────┬───────┘
                  └────────┬────────┘
                          │
                    ┌─────┴─────┐
                    │  RDS      │ (Multi-AZ)
                    │  Primary  │ ──sync──▶ Standby
                    └───────────┘
```

**Key design elements:**
- **No single point of failure** — every component has at least one redundant instance.
- **Cross-AZ deployment** — application instances spread across ≥3 availability zones.
- **Auto Scaling** — ASG with min/desired/max to handle node failures and demand spikes.
- **Managed database HA** — RDS Multi-AZ with automatic failover (<60s).
- **DNS failover** — Route 53 health checks with latency-based or failover routing.
- **Cross-region DR** — S3 cross-region replication, RDS read replicas in another region.

**Azure equivalent:** Use **Availability Zones**, **Application Gateway WAF**, **Azure SQL Geo-Replication**, and **Traffic Manager** for DNS failover.

**GCP equivalent:** Use **Multi-zone MIGs**, **Cloud Load Balancing (global)**, **Cloud SQL regional HA**, and **Cloud DNS** with health checks.

---

### 30) How do load balancers and auto scaling work together?

**Integration flow:**

```
Client Request
    │
    ▼
┌─────────────────┐
│  Load Balancer   │ ← Health checks every 10-30s
│  (ALB/NLB/CLB)   │
└────────┬────────┘
    │ Pass → register | Fail → deregister
    ▼
┌─────────────────┐
│  Auto Scaler     │ ← Monitors target group metrics
│  (ASG/Scale Set) │
└────────┬────────┘
    │ Scale in/out
    ▼
┌─────────────────┐
│  Instance Pool   │ ← New instances pass health → receive traffic
│  (EC2/VM/Node)   │
└─────────────────┘
```

**How they coordinate:**

1. **Health check handshake:** The LB performs periodic health checks (TCP, HTTP, or custom) against each registered instance.
2. **Instance registration:** When ASG launches a new instance, it registers with the LB's target group **only after** it passes the health check.
3. **Instance deregistration:** When an instance fails health checks, the LB **removes it from rotation** — traffic is not sent to unhealthy instances.
4. **Scale-out trigger:** ASG monitors metrics (CPU, request count, target group size). When the threshold is exceeded, it launches new instances.
5. **Scale-in trigger:** When demand drops, ASG terminates instances. The LB drains existing connections (`deregistration_delay_timeout`) before removing them.

**Terraform configuration example:**

```hcl
resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  # Allow time for in-flight requests to complete
  deregistration_delay_timeout = 30
}

resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  min_size            = 2
  max_size            = 10
  desired_capacity    = 3
  target_group_arns   = [aws_lb_target_group.app.arn]
  vpc_zone_identifier = aws_subnet.private.*.id

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_appautoscaling_target" "alb_target" {
  service_namespace = "applicationautoscaling"
  resource_id       = "targetgroup/${aws_lb_target_group.app.name}"
  scalable_dimension = "alb:targetgroup.DesiredCapacity"
  min_capacity      = 2
  max_capacity      = 10
}
```

**Key tuning parameters:**
- **Health check interval:** 10-30s (faster detection vs. noise)
- **Deregistration delay:** 30-120s (allow in-flight requests to complete)
- **Warmup period:** 10-60s (new instance warms cache before receiving full traffic)
- **Cooldown period:** 60-300s (prevent rapid scale-up/scale-down oscillation)

---

### 31) How would you design disaster recovery for a critical service?

**DR strategy selection:**

| Strategy | RTO | RPO | Cost | Complexity |
|----------|-----|-----|------|------------|
| Backup & Restore | Hours-Days | Last backup | Low | Low |
| Pilot Light | Minutes-Hours | Minutes | Medium | Medium |
| Warm Standby | Minutes | Near-zero | High | High |
| Multi-Active | Near-zero | Zero | Very High | Very High |

**Warm Standby Architecture (recommended for most critical services):**

```
Primary Region (us-east-1)                DR Region (us-west-2)
┌──────────────────────┐                ┌──────────────────────┐
│ Application (full)    │                │ Application (scaled) │
│ Database (Primary)    │───replicate───▶│ Database (Standby)   │
│ Cache                 │                │ (minimal capacity)   │
│ Object Storage        │───replicate───▶│ Object Storage       │
└──────────────────────┘                └──────────────────────┘
          │                                        │
          └──────── Route 53 Failover ─────────────┘
                    (health-check triggered)
```

**Implementation steps:**

1. **Data replication:**
```hcl
# RDS cross-region read replica
resource "aws_db_instance" "dr_replica" {
  identifier        = "myapp-dr-replica"
  replicate_source_db = aws_db_instance.primary.arn
  instance_class    = "db.r6g.large"  # Can be smaller for cost savings
  region            = "us-west-2"
}

# S3 cross-region replication
resource "aws_s3_bucket_replication_configuration" "dr" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    destination {
      bucket = aws_s3_bucket.dr.arn
      region = "us-west-2"
    }
    status = "Enabled"
  }
}
```

2. **DNS failover with health checks:**
```hcl
resource "aws_route53_health_check" "primary" {
  fqdn              = "alb.primary.us-east-1.elb.amazonaws.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_record" "failover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }
  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
  health_check_id = aws_route53_health_check.primary.id
}
```

3. **DR runbook and testing:**
- **Quarterly DR drill** — simulate primary failure, measure actual RTO/RPO.
- **Automated failover script** — promote DR replica, update DNS, verify traffic.
- **Communication plan** — stakeholder notification, status page update.

**Key metrics to track:**
- **RTO (Recovery Time Objective):** Target ≤ 30 minutes for critical services
- **RPO (Recovery Point Objective):** Target ≤ 5 minutes of data loss
- **Failover frequency:** Test quarterly minimum
- **Replication lag:** Monitor continuously, alert on > 1 minute

---

### 32) How would you troubleshoot sudden cloud cost increases?

**Step 1 – Identify the cost driver.**

```bash
# AWS Cost Explorer via CLI
aws ce get-cost-and-usage \
  --time-period Start=2026-09-01,End=2026-09-15 \
  --granularity DAILY \
  --group-by Type=DIMENSION,Key=SERVICE

# Azure Cost Management
az consumption usage list --start-date 2026-09-01 --end-date 2026-09-15

# GCP Billing export (BigQuery)
SELECT service.description, SUM(cost)
FROM `project-billing.gcp_billing_export.*`
WHERE usage_start BETWEEN '2026-09-01' AND '2026-09-15'
GROUP BY 1
ORDER BY 2 DESC
```

**Step 2 – Common causes and investigation.**

| Cost Spike | Likely Cause | Investigation |
|------------|-------------|---------------|
| Compute | Auto Scaling launched extra instances, unattached reservations expired | Check ASG scale events, reserved instance coverage |
| Storage | Unrestricted snapshots, unattached EBS volumes, log accumulation | `aws ec2 describe-volumes --filters Name=status,Values=available` |
| Data Transfer | Cross-region replication, missing VPC peering, egress to internet | Check CloudWatch `NetworkOut`, Cloud TGW costs |
| Database | Provisioned IOPS too high, unneeded read replicas, backup retention | Check RDS metrics, backup retention policy |
| Load Balancer | Idle LBs, per-NAT gateway charges, over-provisioned capacity | Check LB metrics (zero request count = idle) |
| Container | Over-provisioned node pools, unneeded add-ons, spot interruption | Check cluster node count, spot interruption rate |

**Step 3 – Automated cost controls.**

```hcl
# AWS Budgets with alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "cost-alerts"
}

resource "aws_budgets_budget" "monthly" {
  name          = "monthly-budget"
  budget_type   = "COST"
  time_unit     = "MONTHLY"
  limit_amount  = "10000"
  limit_unit    = "USD"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    subscriber {
      addressed_to = aws_sns_topic.cost_alerts.topic_arn
    }
  }
}

# Anomaly detection
resource "aws_cur_report_definition" "cost_report" {
  report_name          = "cost-and-usage"
  time_unit            = "DAILY"
  format               = "Parquet"
  compression          = "Parquet"
  additional_schema_elements = ["RESOURCES"]
}
```

**Step 4 – Cost optimization actions.**
- **Right-size** underutilized instances (check CloudWatch CPU < 20% for 30 days).
- **Purchase Savings Plans/Reserved Instances** for steady-state workloads.
- **Use Spot/Preemptible instances** for fault-tolerant batch workloads.
- **Implement tagging policy** to allocate costs to teams/projects.
- **Set up automated cleanup** — delete unattached volumes, old snapshots, idle LBs.
- **Enable cost anomaly detection** — AWS Cost Anomaly Detection, Azure Cost Management alerts.

---

### 33) How would you secure S3/ADLS/GCS data and access?

**AWS S3 Security (comprehensive):**

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "company-sensitive-data"
  force_destroy = false

  tags = {
    Environment = "production"
    DataClass   = "confidential"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption (SSE-KMS)
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
    bucket_key_enabled = true
  }
}

# Versioning for recovery
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Access logging
resource "aws_s3_bucket_logging" "data" {
  bucket = aws_s3_bucket.data.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

# Lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    id     = "archive-old-data"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
  }
}

# Bucket policy — restrict by VPC endpoint and IAM
resource "aws_s3_bucket_policy" "data" {
  bucket = aws_s3_bucket.data.id
  policy = data.aws_iam_policy_document.data_policy.json
}

data "aws_iam_policy_document" "data_policy" {
  statement {
    sid       = "AllowVPCOnly"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.data.arn, "${aws_s3_bucket.data.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }
}
```

**GCS equivalent (key controls):**

```hcl
resource "google_storage_bucket" "data" {
  name          = "company-gcs-data"
  location      = "US"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = 90
    }
  }
}
```

**Azure ADLS equivalent:**

```hcl
resource "azurerm_storage_account" "data" {
  name                     = "companydatalake"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = [azurerm_subnet.private.id]
  }
}
```

**Security checklist:**
- **Encryption at rest:** SSE-KMS (AWS), CMEK (GCP), CMK (Azure) — bring your own key.
- **Encryption in transit:** Enforce TLS 1.2+, deny non-SSL requests.
- **Public access blocked:** Default deny, explicit allow via IAM/VPC endpoint.
- **IAM least privilege:** Specific S3 bucket policies, not wildcard `s3:*`.
- **Access logging:** Enable and ship to SIEM for monitoring.
- **MFA Delete:** Require MFA for Delete operations on critical buckets.
- **Object Lock:** WORM (Write Once Read Many) for compliance-critical data.
- **VPC/VNet Endpoints:** Keep traffic off the public internet.

---

### 34) How would you design networking between private cloud workloads?

**Multi-tier private networking design:**

```
                    ┌──────────────────────┐
                    │     Internet Gateway  │
                    └──────────┬───────────┘
                               │
                    ┌──────────┴───────────┐
                    │      NAT Gateway     │ (outbound only)
                    └──────────┬───────────┘
                               │
              ┌────────────────┴────────────────┐
              │        Public Subnets            │
              │  ┌──────┐  ┌──────┐  ┌──────┐   │
              │  │LB/ALB│  │LB/ALB│  │LB/ALB│   │
              │  └──┬───┘  └──┬───┘  └──┬───┘   │
              └─────┼────────┼─────────┼────────┘
                    │        │         │
              ┌─────┼────────┼─────────┼────────┐
              │     │Private Subnets (per AZ)    │
              │  ┌──┴──┐  ┌──┴──┐  ┌──┴──┐     │
              │  │App  │  │App  │  │App  │     │
              │  │Tier │  │Tier │  │Tier │     │
              │  └──┬──┘  └──┬──┘  └──┬──┘     │
              │     │        │         │        │
              │  ┌──┴──┐  ┌──┴──┐  ┌──┴──┘     │
              │  │Data │  │Data │  │Cache│     │
              │  │Tier │  │Tier │  │Tier │     │
              │  └─────┘  └─────┘  └─────┘     │
              └─────────────────────────────────┘
```

**VPC/Terraform implementation:**

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "production-vpc"
  }
}

# Public subnets (one per AZ)
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 10}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false  # No public IPs on instances

  tags = {
    Name = "public-subnet-${count.index + 1}"
    Tier = "public"
  }
}

# Private subnets (app tier)
resource "aws_subnet" "app" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "app-subnet-${count.index + 1}"
    Tier = "private"
  }
}

# Private subnets (data tier)
resource "aws_subnet" "data" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 30}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "data-subnet-${count.index + 1}"
    Tier = "private-data"
  }
}

# NAT Gateway for outbound internet access from private subnets
resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
}

# VPC Endpoints for AWS services (no internet required)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private.*.id]
}

resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  private_dns_enabled = true
}
```

**Networking security controls:**
- **Security groups:** Stateful, instance-level firewall — allow only required ports between tiers.
- **NACLs:** Stateless, subnet-level firewall — deny all inbound from unknown CIDRs.
- **VPC Peering / Transit Gateway:** Connect multiple VPCs for microservice communication.
- **PrivateLink / VPC Endpoint:** Access AWS/Azure services without traversing the public internet.
- **Network segmentation:** Separate tiers (public, app, data) with minimal cross-tier access.
- **Private DNS:** Use Route 53 Private Hosted Zones for internal service discovery.

---

# 🔹 TERRAFORM + IaC

---

### 35) How would you structure Terraform for multiple environments?

**Recommended structure — monorepo with environment-based variable override:**

```
terraform/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── ecs/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── rds/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── backend.tf
└── .tflint.hcl
```

**Module (reusable infrastructure component):**

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.environment}-vpc"
  })
}

resource "aws_subnet" "private" {
  count             = var.num_availability_zones
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-private-${count.index + 1}"
  }
}
```

**Environment root module:**

```hcl
# environments/production/main.tf
module "vpc" {
  source = "../../modules/vpc"

  environment                = "production"
  cidr_block                 = var.vpc_cidr
  num_availability_zones     = 3
  common_tags                = var.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  environment       = "production"
  cluster_name      = "production-cluster"
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  container_image   = var.container_image
  desired_count     = var.desired_count
}
```

**Environment-specific variables:**

```hcl
# environments/dev/terraform.tfvars
vpc_cidr        = "10.1.0.0/16"
desired_count   = 1
container_image = "myapp:develop"

# environments/production/terraform.tfvars
vpc_cidr        = "10.0.0.0/16"
desired_count   = 6
container_image = "myapp:v1.2.3"
```

**Separate state per environment:**

```hcl
# environments/production/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

**Key principles:**
- **Modules are environment-agnostic** — no hardcoded environment names inside modules.
- **State is separated per environment** — prevents cross-environment state conflicts.
- **Variables flow from environment → module** — override via `.tfvars` per environment.
- **Use workspaces** (alternative to directory-per-environment): `terraform workspace new production`.
- **Version modules** using Git tags or a module registry for dependency tracking.

---

### 36) How do you handle Terraform state locking and drift?

**State locking — preventing concurrent modifications:**

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Purpose = "Terraform State Locking"
  }
}
```

**How locking works:**
1. Terraform acquires a **DynamoDB lock** (with `LockID` = state file hash) before any `plan` or `apply`.
2. If another `apply` is running, the second operation **fails with a lock error**.
3. On success, the lock is **released automatically**.
4. On failure, the lock may remain — use `terraform force-unlock <LOCK_ID>` to release it.

**State drift detection:**

```bash
# Plan to detect drift (no changes expected in terraform.tfvars)
terraform plan -detailed-exitcode

# Exit codes:
# 0 = no changes
# 1 = error
# 2 = changes detected (drift)

# Automated drift detection (CI pipeline)
terraform plan -input=false -no-color -detailed-exitcode | tee drift-report.txt
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 2 ]; then
  echo "DRIFT DETECTED — resources changed outside Terraform"
  echo "Report: $(cat drift-report.txt)"
  # Send alert to Slack/PagerDuty
  exit 2
fi
```

**Common drift causes:**
| Source | Example | Prevention |
|--------|---------|------------|
| Manual console changes | Adding security group rule via AWS Console | Enforce change-through-Terraform policy |
| Auto-scaling events | ASG replaces instances (not tracked in state) | Use `ignore_changes` for dynamic attributes |
| Provider auto-updates | Provider version upgrade changes default behavior | Pin provider versions in `required_providers` |
| IAM policy drift | AWS service adds permissions automatically | Use `import` to bring resources under management |
| AWS managed updates | Route table propagation, DHCP options | Use `lifecycle { ignore_changes = [...] }` |

**Handling drift:**

```hcl
# Ignore auto-managed attributes
resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = var.vpc_id

  lifecycle {
    ignore_changes = [
      # AWS auto-adds related rules for egress
      egress,
      # Ignore tags added by other tools
      tags_all,
    ]
  }
}
```

---

### 37) How would you safely manage secrets in Terraform?

**Strategy 1 – Reference secrets from external vaults (preferred):**

```hcl
# Reference secrets from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "production/db/password"
}

resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = "db.r6g.large"
  password       = data.aws_secretsmanager_secret_version.db_password.secret_string
}

# Reference from HashiCorp Vault
data "vault_generic_secret" "app" {
  path = "secret/production/app"
}

resource "aws_instance" "app" {
  user_data = <<-EOF
    export DB_PASSWORD="${data.vault_generic_secret.app.data["db_password"]}"
  EOF
}
```

**Strategy 2 – Use Terraform variable files (with care):**

```hcl
# variables.tf
variable "db_password" {
  type      = string
  sensitive = true   # Prevents output in CLI
}

# Never commit terraform.tfvars — use -var-file flag at runtime
# terraform apply -var-file="secrets.tfvars"
```

```bash
# .gitignore
secrets.tfvars
*.auto.tfvars
```

**Strategy 3 – SOPS-encrypted variables:**

```yaml
# secrets.yaml (SOPS encrypted)
db_password: ENC[AES256_GCM,data:xxxxx,iv:xxxxx,...]
api_key: ENC[AES256_GCM,data:xxxxx,iv:xxxxx,...]
```

```hcl
# Use sops data source or decrypt in CI pipeline
data "external" "secrets" {
  program = ["sops", "--extract", "db_password", "secrets.yaml"]
}
```

**Strategy 4 – GitHub Actions / CI secret injection:**

```yaml
- name: Terraform Apply
  env:
    TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
    TF_VAR_api_key:     ${{ secrets.API_KEY }}
  run: terraform apply -auto-approve
```

**Security best practices:**

| Practice | Implementation |
|----------|---------------|
| Mark variables as `sensitive` | `sensitive = true` prevents output in `plan`/`apply` |
| Encrypt state at rest | S3 backend with `encrypt = true` + KMS key |
| Restrict state access | IAM policy on S3 bucket + DynamoDB, VPC endpoint |
| Never log secrets | CI/CD masking, Terraform `sensitive` flag |
| Use external secrets | Vault, AWS Secrets Manager — secrets never in state |
| Enable state encryption | KMS customer-managed key (not AWS-managed) |
| Audit secret access | CloudTrail for S3/DynamoDB, Vault audit device |

**Critical rule:** If a secret is referenced directly in a resource (e.g., `password = var.db_password`), it is stored **in the state file in plaintext**. Always prefer referencing from external vaults so the state only contains the secret ARN/path, not the value.

---

### 38) How do modules improve large-scale infrastructure management?

**Benefits of modular design:**

| Benefit | Explanation |
|---------|-------------|
| **Reusability** | Write once, deploy across environments and regions |
| **Consistency** | Standard patterns enforced through module interfaces |
| **Maintainability** | Fix a bug in one module → all environments benefit |
| **Team isolation** | Teams own specific modules without touching others |
| **Testing** | Modules can be tested in isolation with `terraform test` |
| **Documentation** | Module `README` with `terraform-docs` auto-generated |

**Module interface design:**

```hcl
# modules/ecs/variables.tf
variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, production)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for ECS cluster placement"
}

variable "desired_count" {
  type        = number
  default     = 3
  description = "Number of tasks to run"
}

variable "container_image" {
  type        = string
  description = "Docker image URI"
}

variable "enable_logging" {
  type    = bool
  default = true
}

# modules/ecs/outputs.tf
output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.this.arn
}
```

**Calling modules with inheritance:**

```hcl
# Root module calling multiple module instances
module "ecs_frontend" {
  source = "./modules/ecs"

  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  desired_count   = var.frontend_replicas
  container_image = var.frontend_image
  enable_logging  = true
}

module "ecs_backend" {
  source = "./modules/ecs"

  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  desired_count   = var.backend_replicas
  container_image = var.backend_image
  enable_logging  = true
}

module "ecs_worker" {
  source = "./modules/ecs"

  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  desired_count   = var.worker_replicas
  container_image = var.worker_image
  enable_logging  = false  # Workers don't need CloudWatch Logs
}
```

**Module versioning strategy:**

```hcl
# Call from Git URL with version tag
module "vpc" {
  source  = "git::https://github.com/company/terraform-modules.git//modules/vpc?ref=v2.1.0"
  # or from a registry
  # source  = "company/vpc/aws"
  # version = "2.1.0"
}
```

**Testing modules:**

```hcl
# modules/vpc/tftest/main.tftest.hcl
variables {
  cidr_block           = "10.0.0.0/16"
  environment          = "test"
  num_availability_zones = 2
}

run "basic" {
  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should match input"
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets"
  }
}
```

---

### 39) How would you recover from a failed Terraform deployment?

**Step 1 – Assess the failure.**

```bash
# Check what Terraform was doing when it failed
terraform plan -detailed-exitcode

# Check the state for partial changes
terraform state list

# Check the state for the specific failed resource
terraform state show aws_instance.failed_resource

# View the full state (for manual inspection)
terraform state pull | jq '.resources[] | select(.type == "aws_instance")'
```

**Step 2 – Common failure scenarios and recovery.**

| Failure Type | Symptom | Recovery |
|-------------|---------|----------|
| Provider timeout | `error: timeout waiting for state` | Wait for resource to stabilize, then `terraform apply` |
| API rate limiting | `Throttling` errors | Wait and retry, configure provider retry settings |
| Resource conflict | `already exists`, `duplicate` | `terraform import` the existing resource, or `terraform state rm` |
| Partial apply | Some resources created, rest failed | `terraform apply` retries — only creates missing resources |
| State corruption | `state file corrupted`, JSON parse error | Restore from state versioning (S3), `terraform state pull` |
| Lock conflict | `Error acquiring the state lock` | `terraform force-unlock <LOCK_ID>` (only if no apply is running) |
| Dependency cycle | `Cycle: A -> B -> A` | Refactor modules, use `data` sources instead of `resource` |

**Step 3 – Recovery procedures.**

```bash
# Scenario 1: Import a manually created resource
terraform import aws_instance.existing i-0abcd1234efgh5678

# Scenario 2: Remove a resource from state (without deleting it)
terraform state rm aws_instance.problematic

# Scenario 3: Move a resource to a different address in state
terraform state mv aws_instance.old aws_instance.new

# Scenario 4: Restore state from S3 versioning
# (Manual: use AWS Console → S3 → Version History → Restore)
aws s3api get-object \
  --bucket company-terraform-state \
  --key production/terraform.tfstate \
  --version-id <previous-version-id> \
  restored.tfstate

# Scenario 5: Refresh state to match reality
terraform refresh
```

**Step 4 – Preventing future failures.**

```hcl
# Provider retry configuration
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}

# Retry settings in .terraformrc
# retry_max      = 5
# retry_mode     = "error"

# Use -refresh-only to sync state without changes
# terraform apply -refresh-only

# Use -target to fix one resource at a time
# terraform apply -target=aws_instance.problematic
```

**Recovery checklist:**
1. **Read the error** — understand what resource and operation failed.
2. **Check the actual infrastructure** — verify what exists vs. what state says.
3. **Never edit state manually** — use `terraform state` commands.
4. **Use `-target` for surgical fixes** — isolate the failing resource.
5. **Import or remove** — bring manually created resources under management or remove ghost entries.
6. **Restore from backup** — S3 versioning provides point-in-time state recovery.
7. **Document the incident** — update runbooks with the recovery steps.
