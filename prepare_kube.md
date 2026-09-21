---
## Sort pods based on CPU or memory resource consumption

```bash
# Sort by memory (high to low)
kubectl -n production top pods --sort-by=memory

# Sort by CPU (high to low)
kubectl -n production top pods --sort-by=cpu --no-headers

# Sort by memory (low to high) — reverse using tac
kubectl -n production top pods --sort-by=memory --no-headers | tac

# Sort by CPU (low to high)
kubectl -n production top pods --sort-by=cpu --no-headers | tac
```

---

## How do you troubleshoot a pod in `CrashLoopBackOff`?

`CrashLoopBackOff` means the container starts but exits repeatedly, and Kubernetes is increasing the back-off delay between restarts.

**Step 1 — Check pod logs:**
```bash
kubectl logs <pod-name> -n <namespace>
# If the pod has restarted, check the previous container's logs
kubectl logs <pod-name> -n <namespace> --previous
```

**Step 2 — Check pod events:**
```bash
kubectl describe pod <pod-name> -n <namespace>
# Look at the Events section for OOMKilled, exit codes, and restart reasons
```

**Step 3 — Identify the root cause:**
- **Application crash:** Check logs for stack traces, missing environment variables, or failed connections.
- **OOMKilled:** Container exceeded memory limits — increase `resources.limits.memory` or fix memory leaks.
- **Configuration error:** Missing ConfigMap, Secret, or wrong command/args.
- **Dependency not ready:** Database or external service is not available at startup — use init containers or startup probes.

**Step 4 — Fix and redeploy:**
```bash
# Apply the fix (e.g., increase memory limit)
kubectl set resources deployment/<name> -n <namespace> --limits=memory=2Gi
# Or update the deployment manifest and reapply
kubectl apply -f deployment.yaml
```

---

## What specific logs or kubectl events do you look for when a pod is crashing?

**Pod Logs:**
```bash
kubectl logs <pod-name> -n <namespace> --tail=200
kubectl logs <pod-name> -n <namespace> --previous
kubectl logs <pod-name> -n <namespace> -c <container-name>  # For multi-container pods
```

**Pod Events:**
```bash
kubectl describe pod <pod-name> -n <namespace>
```
Key fields in the output:
- **State:** Current container state (Waiting, Running, Terminated) and reason
- **Last State:** Exit code and reason for the previous crash
- **Restart Count:** How many times the container has restarted
- **Events:** Scheduling, image pull, and kubelet events

**Common Event Reasons:**
- `OOMKilled` — Memory limit exceeded
- `FailedScheduling` — Insufficient resources or scheduling constraints not met
- `ImagePullBackOff` — Image not found or registry authentication failure
- `CreateContainerConfigError` — Missing ConfigMap or Secret
- `Unhealthy` — Liveness or readiness probe failing repeatedly

**Node-Level Checks:**
```bash
kubectl describe node <node-name>
kubectl top pods -n <namespace>
journalctl -u kubelet --since "1 hour ago"  # On the node itself
```

---

## What are all the stages for a pod?

A pod goes through the following lifecycle stages:

| Stage | Description |
|-------|-------------|
| **Pending** | Pod has been created and accepted by Kubernetes, but one or more containers have not been set up or started yet. The scheduler is working on assigning it to a node. |
| **Creating/Pulling Image** | Kubelet is pulling the container image from the registry. |
| **Running** | At least one container is running, and no container has terminated with an error. Init containers (if any) have completed successfully. |
| **Succeeded** | All containers have terminated successfully with exit code 0 (for batch jobs or Jobs/CronJobs). |
| **Failed** | At least one container has terminated with a non-zero exit code or was killed (e.g., OOMKilled). |
| **Unknown** | The kubelet on the node is not communicating with the control plane, so the pod phase cannot be determined. |
| **CrashLoopBackOff** | Container keeps crashing, and kubelet is backing off between restart attempts. |
| **ImagePullBackOff / ErrImagePull** | Kubelet cannot pull the container image (wrong image name, missing credentials, network issue). |

---

## How do you troubleshoot `CrashLoopBackOff` and `ImagePullBackOff`?

### CrashLoopBackOff
1. `kubectl logs <pod> -n <namespace> --previous` — Check the last container's logs
2. `kubectl describe pod <pod>` — Look for OOMKilled, exit codes, and events
3. Check if required environment variables, ConfigMaps, and Secrets exist
4. Verify the application's health endpoints and resource limits
5. Run the container locally with the same image and environment to reproduce the issue

### ImagePullBackOff
1. `kubectl describe pod <pod>` — Check the image name and pull error
2. Verify the **image name and tag** are correct
3. Check **imagePullSecrets** — ensure registry credentials are configured:
   ```yaml
   imagePullSecrets:
   - name: my-registry-secret
   ```
4. Verify network connectivity to the container registry from the worker node
5. For ECR, ensure the node IAM role has `ecr:GetDownloadUrlForLayer` and `ecr:BatchGetImage` permissions

---

## What happens when a Kubernetes worker node goes down?

1. **Node NotReady:** The kubelet stops sending heartbeats. After the `node-monitor-grace-period` (default 40 seconds), the control plane marks the node as `NotReady`.
2. **Pod Eviction:** The **Disruption Controller** begins evicting pods from the failed node. Pods managed by a Deployment, StatefulSet, or DaemonSet are **re-scheduled on healthy nodes**.
3. **Pod Disruption Budget (PDB):** If a PDB is configured, Kubernetes ensures that the minimum number of available pods is maintained during eviction.
4. **Service Endpoints:** Kube-proxy removes the failed node's pod IPs from the Service's endpoint list, so traffic is no longer routed to them.
5. **Persistent Volumes:** Pods with `ReadWriteOnce` PVCs may remain in `Pending` state until they are rescheduled onto a node in the same availability zone (depending on the volume's topology constraints).
6. **Recovery:** If the node comes back online, the kubelet reconnects, and any remaining pods can resume (or be replaced, depending on their configuration).

---

## Difference between Deployment, StatefulSet, and DaemonSet?

| Aspect | Deployment | StatefulSet | DaemonSet |
|--------|-----------|-------------|-----------|
| **Use Case** | Stateless applications (web servers, APIs) | Stateful applications (databases, message queues) | Node-level agents (monitoring, logging) |
| **Pod Identity** | Anonymous, randomly generated names | Stable, ordered names (`web-0`, `web-1`, `web-2`) | One per node, named after the node |
| **Scaling Order** | Random/non-deterministic | Sequential (0, 1, 2...) and reverse for deletion | Automatic — one per matching node |
| **Storage** | Ephemeral or shared PVCs | Dedicated PVC per pod with stable storage | Typically no persistent storage |
| **Networking** | Shared Service IP, no stable hostname | Stable network hostname per pod (`web-0.service.ns.svc.cluster.local`) | No stable network identity |
| **Update Strategy** | RollingUpdate (any order) | RollingUpdate (reverse ordinal order) | RollingUpdate (node by node) |
| **Examples** | Nginx, API gateway, microservices | MySQL, PostgreSQL, Kafka, Elasticsearch | Fluentd, Prometheus Node Exporter, node-problem-detector |

---

## What are readiness and liveness probes?

**Liveness Probe:** Determines **if a container is running**. If the liveness probe fails, Kubernetes **kills and restarts** the container. Use it for applications that may get stuck in a deadlocked state without crashing.

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3
```

**Readiness Probe:** Determines **if a container is ready to accept traffic**. If the readiness probe fails, Kubernetes **removes the pod from the Service's endpoint list** but does not restart it. Use it for applications that need time to initialize (loading caches, connecting to databases).

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

**Startup Probe:** For slow-starting applications, prevents Kubernetes from killing the container while it is still initializing. Once the startup probe succeeds, liveness probe takes over.

| Probe | On Failure | Purpose |
|-------|-----------|---------|
| Liveness | Restart container | Detect and recover from deadlocks |
| Readiness | Remove from Service endpoints | Prevent traffic before app is ready |
| Startup | Wait (do nothing) | Give slow apps time to start |

**Probe Types:** `httpGet` (HTTP endpoint), `tcpSocket` (port check), `exec` (run a command inside the container)

---

## How do you perform a zero-downtime deployment?

Zero-downtime deployment is achieved using Kubernetes **Rolling Update** strategy:

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # Create 1 extra pod during update
      maxUnavailable: 0    # Never take a pod down until the new one is ready
```

**How it works:**
1. Kubernetes creates a new pod with the updated image.
2. The **readiness probe** verifies that the new pod is healthy and ready to accept traffic.
3. Once ready, Kubernetes terminates one old pod.
4. This process repeats until all pods are running the new version.
5. At no point are more than `maxUnavailable` pods down, ensuring continuous availability.

**Supporting mechanisms:**
- **Readiness Probes:** Ensure new pods only receive traffic when they are fully initialized.
- **Connection draining:** Load balancers stop sending new requests to old pods and wait for existing requests to complete before terminating.
- **Pod Disruption Budgets:** Guarantee a minimum number of available pods during the update.
- **Rollback:** If issues are detected, run `kubectl rollout undo deployment/<name>` to revert to the previous version instantly.

---

## How do you troubleshoot a pod that is stuck in the `Pending` state?

A pod in `Pending` state means it was created but **not yet scheduled** onto a node.

**Step 1 — Check pod events:**
```bash
kubectl describe pod <pod-name> -n <namespace>
# Look for FailedScheduling events
```

**Step 2 — Common causes and fixes:**

| Cause | How to Check | Fix |
|-------|-------------|-----|
| **Insufficient resources** | `kubectl top nodes` — check available CPU/memory | Scale up the cluster or reduce resource requests |
| **No matching nodes (nodeSelector/affinity)** | Check pod's `nodeSelector` or `nodeAffinity` rules | Add labels to nodes or relax affinity rules |
| **Taints without tolerations** | `kubectl describe node` — check taints | Add tolerations to the pod or remove the taint |
| **PVC not bound** | `kubectl get pvc` — check if PVC is `Pending` | Provision a PersistentVolume or check StorageClass |
| **Resource quotas** | `kubectl describe resourcequota -n <namespace>` | Increase quota limits |
| **Pod disruption budget** | `kubectl get pdb` | Verify that PDB is not blocking scheduling |
| **Image pull secret missing** | Check events for `ImagePullBackOff` | Create and attach the `imagePullSecret` |

**Step 3 — Check scheduler logs (cluster admin):**
```bash
kubectl logs -n kube-system -l component=kube-scheduler
```
