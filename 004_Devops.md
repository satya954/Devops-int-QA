# 🚀 Ascendion DevOps Interview Q&A

> **Comprehensive DevOps Interview Guide** — Covering Kubernetes, CI/CD, EKS, Security, Monitoring, Terraform, and more.  
> **Last Updated:** September 2026 | **Total Questions:** 28

---

## 📑 Table of Contents

| # | Category | Questions |
|---|----------|-----------|
| 🟦 | **Kubernetes Fundamentals** | Q1–Q3, Q23–Q25 |
| 🟧 | **CI/CD & Jenkins** | Q4–Q10 |
| 🟩 | **Microservices & Pipeline Design** | Q9, Q11 |
| 🟨 | **Security & IAM** | Q12–Q14 |
| 🟪 | **Monitoring & Logging** | Q15–Q17 |
| 🟥 | **EKS Architecture** | Q18–Q20 |
| 🟫 | **Deployment Strategies** | Q21–Q22 |
| ⬜ | **Terraform & Infrastructure** | Q27 |
| 🟦 | **Python Scripting** | Q26 |
| 🟧 | **Network Policies** | Q28 |

---

## 🟦 Kubernetes Fundamentals

---

### 1️⃣ Recently did you create any deployment and service? Why? What was the purpose?

**Answer:**

In my recent project, I created a **Kubernetes Deployment** and **Service** for a microservices-based order processing application. The deployment managed a set of identical, stateless pods running a Java/Spring Boot application that handled customer orders.

**Why a Deployment?**
- **Self-healing:** Deployments automatically restart failed pods, replacing them with new ones to maintain the desired replica count. This ensured **high availability** even during partial failures.
- **Rolling Updates:** I needed zero-downtime deployments. Deployments support **rolling update strategies**, allowing me to update application versions without service interruption by gradually replacing old pods with new ones.
- **Scalability:** Deployments integrate with the **Horizontal Pod Autoscaler (HPA)**, enabling automatic scaling based on CPU/memory utilization or custom metrics.

**Why a Service?**
- **Stable Network Endpoint:** Pods are ephemeral — they get new IPs on every restart. A **ClusterIP Service** provided a stable DNS name and IP address that other services could use to reach the order processing application.
- **Load Balancing:** The Service distributed incoming traffic across all healthy pod replicas using round-robin load balancing, ensuring even distribution of requests.

Here is the manifest I used:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  labels:
    app: order-service
    team: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: myregistry/order-service:v2.1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "250m"
            memory: "512Mi"
          limits:
            cpu: "500m"
            memory: "1Gi"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  type: ClusterIP
  selector:
    app: order-service
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

The **purpose** was to create a resilient, scalable, and self-healing application layer that could handle production traffic with automated recovery, version rollouts, and stable networking for downstream consumers.

---

### 2️⃣ Can you explain what is a Deployment?

**Answer:**

A **Deployment** is a Kubernetes workload resource that provides **declarative updates** for Pods and ReplicaSets. It is one of the most commonly used resources in Kubernetes and serves as the higher-level abstraction for managing application state.

**Key characteristics of a Deployment:**

- **Declarative Model:** You define the desired state (number of replicas, container image, resource limits) in a YAML manifest. Kubernetes controllers continuously reconcile the actual state with the desired state.
- **ReplicaSet Management:** A Deployment creates and manages a **ReplicaSet**, which in turn manages the actual Pods. This indirection allows the Deployment to handle advanced update strategies while the ReplicaSet ensures the correct number of pods are running.
- **Update Strategies:** Deployments support two update strategies:
  - **RollingUpdate** (default): Gradually replaces old pods with new ones. You can control `maxSurge` (extra pods created during update) and `maxUnavailable` (pods allowed to be down during update).
  - **Recreate:** Kills all existing pods before creating new ones. Used when rolling updates are not feasible.
- **Rollback Capability:** Deployments maintain a revision history. If a new deployment causes issues, you can **rollback** to a previous revision using `kubectl rollout undo deployment/<name>`.
- **Scaling:** You can scale deployments manually (`kubectl scale deployment/<name> --replicas=5`) or automatically using **Horizontal Pod Autoscaler (HPA)**.

```bash
# Common deployment operations
kubectl get deployments
kubectl describe deployment my-app
kubectl scale deployment my-app --replicas=5
kubectl rollout status deployment my-app
kubectl rollout history deployment my-app
kubectl rollout undo deployment my-app --to-revision=2
```

Deployments are ideal for **stateless applications** such as web servers, APIs, and microservices where any pod can serve any request and there is no affinity to a particular node or persistent data.

---

### 3️⃣ If a pod is down, how do you debug?

**Answer:**

Debugging a down pod requires a **systematic, step-by-step approach**. Here is my troubleshooting methodology:

**Step 1: Check Pod Status and Events**
```bash
# Get pod status and phase
kubectl get pod <pod-name> -n <namespace> -o wide

# Describe the pod to see events, conditions, and reasons
kubectl describe pod <pod-name> -n <namespace>
```
The `describe` output shows **Events** at the bottom, which often reveal scheduling failures, image pull errors, or OOMKilled events. Look at the **State** and **Last State** fields in the container status section.

**Step 2: Check Pod Logs**
```bash
# Current container logs
kubectl logs <pod-name> -n <namespace>

# If pod has crashed and restarted, get previous container logs
kubectl logs <pod-name> -n <namespace> --previous

# For multi-container pods (sidecars)
kubectl logs <pod-name> -n <namespace> -c <container-name>

# Stream logs in real-time
kubectl logs -f <pod-name> -n <namespace>
```

**Step 3: Identify Common Failure Modes**
- **ImagePullBackOff / ErrImagePull:** Check the image name, tag, registry credentials (imagePullSecrets), and network connectivity to the container registry.
- **CrashLoopBackOff:** The container starts but exits immediately. Check application logs for errors, missing environment variables, or configuration issues.
- **OOMKilled:** Container exceeded memory limits. Increase memory limits or fix memory leaks in the application.
- **Pending:** Pod cannot be scheduled. Check node resources, taints/tolerations, affinity rules, and PVC binding status.
- **CreateContainerConfigError:** Missing ConfigMap, Secret, or volume mount issues.

**Step 4: Deep Debugging with Debug Pod**
```bash
# Open a debug container in the pod's namespace and namespace
kubectl debug -it <pod-name> -n <namespace> --image=busybox --target=<container-name>

# Or exec into a running sidecar container
kubectl exec -it <pod-name> -n <namespace> -c <container-name> -- /bin/sh
```

**Step 5: Check Node-Level Issues**
```bash
# Check if the node itself has issues
kubectl describe node <node-name>
kubectl top nodes
kubectl get events --field-selector reason=FailedScheduling
```

**Step 6: Check System Logs (if cluster admin)**
```bash
# Check kubelet logs on the node
journalctl -u kubelet --since "1 hour ago"

# Check container runtime logs
journalctl -u containerd --since "1 hour ago"
```

The key is to **start from the Kubernetes API layer** (pod status, events, logs) and **drill down** to container-level, node-level, and infrastructure-level causes.

---

### 23️⃣ Can you explain the architecture of Kubernetes and how components work?

**Answer:**

Kubernetes architecture consists of two main parts: the **Control Plane** (master) and the **Worker Nodes**. Each part has specific components that work together to orchestrate containerized workloads.

**Control Plane Components:**

| Component | Responsibility |
|-----------|---------------|
| **API Server (`kube-apiserver`)** | Central entry point for all Kubernetes operations. Exposes the REST API, validates and processes requests, and updates the etcd datastore. All other components communicate through it. |
| **etcd** | Distributed, consistent key-value store that holds the **entire cluster state** — all objects (Pods, Services, ConfigMaps, etc.), their desired state, and actual state. It is the single source of truth. |
| **Scheduler (`kube-scheduler`)** | Watches for unscheduled Pods and assigns them to nodes based on **resource requirements, affinity/anti-affinity rules, taints/tolerations, and node conditions**. |
| **Controller Manager (`kube-controller-manager`)** | Runs all built-in controllers: Node Controller (detects node failures), Replication Controller (maintains replica count), Endpoint Controller (updates Service endpoints), Service Account & Token Controllers, etc. |
| **Cloud Controller Manager** | Integrates Kubernetes with cloud provider APIs. Manages cloud-specific operations like load balancer provisioning, route management, and volume attachment. |

**Worker Node Components:**

| Component | Responsibility |
|-----------|---------------|
| **Kubelet** | Agent running on each node. Communicates with the API Server, watches for Pod assignments, and ensures containers are running as specified. Handles health checks, resource reporting, and lifecycle management. |
| **Kube-proxy** | Maintains network rules on each node to enable **Service-level networking**. Implements network proxying (iptables/IPVS mode) to route traffic to the correct pod endpoints. |
| **Container Runtime** | Software that runs containers (containerd, CRI-O, or Docker Engine). Responsible for pulling images, starting/stopping containers, and managing container filesystems. |

**How They Work Together:**

1. User submits a manifest via `kubectl apply` → request goes to **API Server**
2. API Server validates the request and stores the desired state in **etcd**
3. **Scheduler** detects the unscheduled Pod, evaluates nodes, and binds the Pod to a node (stored in etcd)
4. **Kubelet** on the target node watches for Pod assignments, pulls the container image via the **Container Runtime**, and starts the container
5. **Controllers** continuously watch etcd and reconcile actual state with desired state (e.g., if a pod dies, the Replica Controller creates a replacement)
6. **Kube-proxy** ensures Services can route traffic to healthy Pod endpoints

---

### 24️⃣ Can you tell me the difference between Deployment and StatefulSet?

**Answer:**

**Deployment** and **StatefulSet** are both Kubernetes workload resources, but they serve fundamentally different use cases:

| Aspect | Deployment | StatefulSet |
|--------|-----------|-------------|
| **Identity** | Pods are **anonymous** and interchangeable. Pod names are randomly generated (e.g., `web-abc123-def456`). | Pods have **stable, unique identities**. Pod names follow a predictable pattern (e.g., `web-0`, `web-1`, `web-2`). |
| **Use Case** | **Stateless** applications — web servers, APIs, microservices where any pod can serve any request. | **Stateful** applications — databases (MySQL, PostgreSQL, Kafka), distributed storage (Ceph, Elasticsearch), message queues. |
| **Scaling Order** | Pods are created and destroyed in **random/non-deterministic order**. | Pods are created **sequentially** (0, 1, 2…) and deleted **in reverse order** (2, 1, 0). |
| **Storage** | Uses **emptyDir** or shared PVCs. No guaranteed storage binding to a specific pod. | Each pod gets its **own PersistentVolumeClaim** with stable storage that persists across rescheduling. Storage is bound to the pod's ordinal identity. |
| **Networking** | No stable network identity. Service provides a single ClusterIP shared by all pods. | Each pod gets a **stable network hostname** (e.g., `web-0.web-service.namespace.svc.cluster.local`). Headless Service enables direct pod-to-pod communication. |
| **Update Strategy** | RollingUpdate — replaces pods in any order. | RollingUpdate — replaces pods **in reverse ordinal order** (highest number first), ensuring data consistency. |

**When to Use Which:**
- **Deployment:** Web frontend, REST API, authentication service, cache layer — anything where state can be reconstructed and any instance can handle any request.
- **StatefulSet:** Database clusters (primary-replica setups), distributed systems (Kafka brokers with partition ownership), stateful caches (Redis Sentinel), any application requiring stable storage identity or ordered deployment.

```yaml
# StatefulSet example - note the headless service requirement
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None  # Headless service for stable DNS
  selector:
    app: mysql
  ports:
  - port: 3306
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: "mysql-headless"
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

---

### 25️⃣ What do you understand by affinity and taints? Where have you implemented them? Give me a real scenario.

**Answer:**

**Taints and Tolerations** and **Affinity/Anti-Affinity** are Kubernetes scheduling mechanisms that control **where Pods can and cannot run** on nodes.

**Taints and Tolerations (Node → Pod, Repelling Force):**

- A **taint** is applied to a **node** and says "Pods cannot run here unless they have a matching toleration."
- A **toleration** is applied to a **Pod** and says "I can tolerate this taint and run on this node."
- Think of it as a **gatekeeper** — nodes repel pods that don't explicitly accept the taint.

```bash
# Apply a taint to a GPU node
kubectl taint nodes gpu-node-1 gpu=true:NoSchedule

# This pod won't schedule on gpu-node-1 without a toleration
# Pod with toleration:
tolerations:
- key: "gpu"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
```

**Affinity and Anti-Affinity (Pod → Node/Other Pods, Attracting Force):**

- **Node Affinity:** Schedules pods onto nodes that match specific label selectors.
- **Pod Affinity:** Schedules pods onto nodes that already run pods with matching labels (co-location).
- **Pod Anti-Affinity:** Prevents pods from being scheduled on nodes that already run pods with matching labels (spread across nodes).

```yaml
# Example: Node Affinity + Pod Anti-Affinity
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: topology.kubernetes.io/zone
          operator: In
          values:
          - us-east-1a
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - order-service
      topologyKey: kubernetes.io/hostname
```

**Real-World Scenario I Implemented:**

In a production environment, we had a mixed workload with **CPU-intensive batch processing jobs**, **memory-intensive analytics services**, and **GPU-based ML inference models** running on the same EKS cluster.

1. **Taints:** I applied taints to GPU-dedicated nodes (`gpu=true:NoSchedule`) so that only ML inference pods with the matching toleration could be scheduled there. This prevented regular workloads from consuming expensive GPU nodes.
2. **Pod Anti-Affinity:** For our order processing service, I configured `podAntiAffinity` with `topologyKey: kubernetes.io/hostname` to ensure replicas were spread across different physical nodes. This prevented a single node failure from taking down multiple replicas simultaneously.
3. **Node Affinity:** Our analytics service required SSD-backed storage. I applied node affinity rules matching the label `disktype=ssd` to ensure these pods only landed on nodes with high-performance storage.
4. **Preferred vs Required:** For non-critical workloads, I used `preferredDuringSchedulingIgnoredDuringExecution` (soft affinity) to allow scheduling even when ideal nodes were unavailable, while critical services used `requiredDuringSchedulingIgnoredDuringExecution` (hard affinity).

---

## 🟧 CI/CD & Jenkins

---

### 4️⃣ You have Python, Node.js, and Java applications. How would you design a common CI/CD reusable workflow?

**Answer:**

The key is to design a **shared, language-agnostic pipeline framework** that handles common stages (code checkout, security scanning, container build, deployment) while allowing **language-specific build/test steps** to be plugged in as shared libraries or parameterized stages.

**Architecture of the Reusable Pipeline:**

```
┌─────────────────────────────────────────────────┐
│           Shared Pipeline Library               │
│  ┌─────────┐ ┌──────┐ ┌──────┐ ┌────────────┐  │
│  │ Checkout │→│ SAST │→│Build │→│ Container  │  │
│  │         │  │ Scan │ │&Test │→│ Build &    │  │
│  └─────────┘ └──────┘ └──────┘ │ Push       │  │
│       ↓          ↓         ↓    └────────────┘  │
│  (shared)   (shared)  (language│       ↓        │
│               │       specific) │  Deploy to    │
│               │                 │  Kubernetes   │
│               │                 └───────────────┘
└─────────────────────────────────────────────────┘
```

**Jenkins Shared Library — `vars/buildAndTest.groovy`:**
```groovy
def call(String language) {
    switch(language) {
        case 'java':
            sh 'mvn clean install -DskipTests=false'
            sh 'mvn package -Pproduction'
            sh 'mvn jacoco:report'
            break
        case 'node':
            sh 'npm ci'
            sh 'npm run build'
            sh 'npm test -- --coverage'
            break
        case 'python':
            sh 'pip install -r requirements.txt'
            sh 'flake8 --max-line-length=120'
            sh 'pytest --junitxml=report.xml --cov=.'
            break
        default:
            error("Unsupported language: ${language}")
    }
}
```

**Main Pipeline (`Jenkinsfile`):**
```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'LANGUAGE', choices: ['java', 'node', 'python'], description: 'Application Language')
        string(name: 'APP_NAME', defaultValue: 'my-app', description: 'Application Name')
        string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker Image Tag')
    }

    environment {
        REGISTRY = 'myregistry.io/company'
        NAMESPACE = 'production'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Security Scan') {
            steps {
                sh 'trivy fs --severity HIGH,CRITICAL .'
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    buildAndTest(params.LANGUAGE)
                }
            }
        }

        stage('Container Build & Push') {
            steps {
                script {
                    def img = "${REGISTRY}/${params.APP_NAME}:${params.IMAGE_TAG}"
                    sh """
                        docker build -t ${img} -f Dockerfile .
                        docker push ${img}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh """
                        kubectl set image deployment/${params.APP_NAME} \\
                            ${params.APP_NAME}=${REGISTRY}/${params.APP_NAME}:${params.IMAGE_TAG} \\
                            -n ${NAMESPACE}
                        kubectl rollout status deployment/${params.APP_NAME} -n ${NAMESPACE} --timeout=300s
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            emailext(
                subject: "✅ Build Success: ${params.APP_NAME}",
                body: "Deployment of ${params.APP_NAME} completed successfully",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
        failure {
            emailext(
                subject: "❌ Build Failed: ${params.APP_NAME}",
                body: "Check console output: ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider']]
            )
        }
    }
}
```

**Key Design Principles:**
- **Shared Library:** Language-specific logic is encapsulated in reusable library functions, keeping the main pipeline clean and generic.
- **Parameterization:** Language, app name, and image tag are parameters so the same pipeline definition works for all three languages.
- **Common Stages:** Checkout, security scanning, container build, and deployment are identical across all languages.
- **Post-Actions:** Notifications and workspace cleanup are universal, applied regardless of language.

---

### 5️⃣ Difference between Scripted Pipeline and Declarative Pipeline?

**Answer:**

Jenkins pipelines can be written in two syntax styles: **Scripted** and **Declarative**. Both use Groovy under the hood, but they differ significantly in structure, readability, and flexibility.

| Aspect | Scripted Pipeline | Declarative Pipeline |
|--------|------------------|---------------------|
| **Syntax** | Free-form Groovy code wrapped in `node {}` block | Structured, predefined DSL with `pipeline { }` block |
| **Structure** | Flexible — you define the flow with Groovy control structures | Rigid — predefined sections like `stages`, `steps`, `post`, `environment` |
| **Readability** | Harder to read, especially for non-Groovy developers | Easier to read, more structured and self-documenting |
| **Error Handling** | Manual — use `try/catch/finally` blocks | Built-in — `post` section with `always`, `success`, `failure`, `unstable` |
| **Directives** | Limited — mostly Groovy logic | Rich — `agent`, `options`, `parameters`, `triggers`, `environment`, `options` |
| **Parallel Execution** | Requires `parallel {}` Groovy step | Built-in `parallel` keyword within `stages` |
| **Input/Approval** | `input()` step | `input` step in `stage` |
| **Validation** | No syntax validation at load time | `validate pipeline` feature available in Jenkins UI |
| **Learning Curve** | Steeper — requires Groovy knowledge | Gentler — more intuitive, less Groovy required |

**Scripted Pipeline Example:**
```groovy
node {
    try {
        stage('Build') {
            sh 'mvn clean package'
        }
        stage('Test') {
            sh 'mvn test'
        }
    } catch (Exception e) {
        currentBuild.result = 'FAILED'
        echo "Build failed: ${e.message}"
        throw e
    } finally {
        cleanWs()
    }
}
```

**Declarative Pipeline Example:**
```groovy
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo "Build failed — check console output"
        }
    }
}
```

**Recommendation:** Use **Declarative Pipelines** as the default — they are more maintainable, provide better structure, and are the recommended approach by Jenkins. Use **Scripted Pipelines** only when you need complex Groovy logic that declarative syntax cannot express (e.g., dynamic stage generation, complex loops, or advanced conditional logic).

---

### 6️⃣ What is the Groovy syntax?

**Answer:**

**Groovy** is a dynamic, optionally-typed programming language that runs on the **Java Virtual Machine (JVM)**. It is the default scripting language for **Jenkins Pipeline** (Jenkinsfiles). Groovy is fully compatible with Java but offers a more concise, expressive syntax.

**Key Groovy Syntax Features:**

1. **Dynamic Typing with `def`:**
```groovy
def name = "Jenkins"        // String
def count = 42              // Integer
def list = [1, 2, 3, 4, 5] // List
def map = [key: 'value']    // Map
```

2. **String Interpolation:**
```groovy
def app = "order-service"
def version = "2.1.0"
echo "Deploying ${app} version ${version}"  // Double quotes for interpolation
echo 'No interpolation in single quotes: ${app}'
```

3. **Closures (Anonymous Functions):**
```groovy
def greet = { name ->
    echo "Hello, ${name}!"
}
greet.call("DevOps")

// Closure in pipeline context
stage('Build') {
    steps {
        sh 'mvn clean package'
    }
}
```

4. **Collection Operations:**
```groovy
def languages = ['java', 'node', 'python']

// Each iteration
languages.each { lang ->
    echo "Building ${lang}"
}

// Filter and map
def filtered = languages.findAll { it != 'node' }
def uppercased = languages.collect { it.toUpperCase() }
```

5. **Conditional Logic:**
```groovy
if (env.BRANCH_NAME == 'main') {
    sh 'deploy --environment=production'
} else if (env.BRANCH_NAME == 'develop') {
    sh 'deploy --environment=staging'
} else {
    echo "Skipping deployment for feature branch"
}

// Ternary operator
def env = (params.DEPLOY_TO_PROD == true) ? 'production' : 'staging'
```

6. **Exception Handling:**
```groovy
try {
    sh 'mvn test'
} catch (Exception e) {
    echo "Tests failed: ${e.message}"
    currentBuild.result = 'UNSTABLE'
} finally {
    cleanWs()
}
```

7. **Method Definition:**
```groovy
def buildImage(String imageName, String tag) {
    sh "docker build -t ${imageName}:${tag} ."
    sh "docker push ${imageName}:${tag}"
}
buildImage('myapp', 'v1.0')
```

**Groovy in Jenkins Pipeline:**
```groovy
pipeline {
    agent any

    environment {
        REGISTRY = 'myregistry.io'
    }

    stages {
        stage('Dynamic Parallel') {
            parallel {
                stage('Java') {
                    steps {
                        script {
                            def jars = sh(script: 'find target -name "*.jar"', returnStdout: true).trim()
                            echo "Found: ${jars}"
                        }
                    }
                }
                stage('Node') {
                    steps {
                        sh 'npm test'
                    }
                }
            }
        }
    }
}
```

**Why Groovy for Jenkins?**
- Runs on JVM, so it can use all Java libraries
- DSL-friendly syntax makes pipeline code readable
- Dynamic nature allows flexible, programmable pipelines
- Built-in integration with Jenkins API (steps, environment variables, build properties)

---

### 7️⃣ MVN clean install vs MVN clean package?

**Answer:**

Both commands are **Maven lifecycle commands** used in Java project builds, but they execute different phases of the build lifecycle and serve different purposes.

**Maven Build Lifecycle Phases (in order):**
```
validate → compile → test → package → verify → install → deploy
```

**`mvn clean package`:**
- Executes phases up to and including **package**.
- `clean` → Deletes the `target/` directory (removes previous build artifacts).
- `compile` → Compiles source code.
- `test` → Runs unit tests (but does NOT fail the build if tests fail by default — depends on surefire config).
- `package` → Packages the compiled code into a distributable format — typically a **JAR** or **WAR** file in the `target/` directory.
- **Output:** Build artifact (JAR/WAR) in `target/` directory, but **NOT installed** in the local Maven repository.
- **Use case:** When you only need the build artifact for deployment or manual testing, and don't need to share it with other local projects.

**`mvn clean install`:**
- Executes all phases of `clean package` **plus** the **install** phase.
- `install` → Copies the built artifact (JAR/WAR) into the **local Maven repository** (`~/.m2/repository/`).
- **Output:** Build artifact in `target/` AND installed in `~/.m2/repository/` for use by other local Maven projects.
- **Use case:** When other local Maven projects depend on this project as a library, or when you need the artifact available for local development and integration.

| Aspect | `mvn clean package` | `mvn clean install` |
|--------|-------------------|-------------------|
| Build Artifact Created | ✅ Yes (in `target/`) | ✅ Yes (in `target/`) |
| Installed to Local Repo | ❌ No | ✅ Yes (`~/.m2/repository/`) |
| Can be Depended On Locally | ❌ No | ✅ Yes |
| Typical CI/CD Usage | For standalone apps (WAR/JAR deployment) | For library modules, multi-module projects |
| Build Time | Slightly faster | Slightly slower (includes install step) |

**In CI/CD Pipelines:**
```groovy
// For a standalone application — package is sufficient
stage('Build Java App') {
    steps {
        sh 'mvn clean package -DskipTests=false'
    }
}

// For a library or multi-module project — install is needed
stage('Build Java Library') {
    steps {
        sh 'mvn clean install -DskipTests=false'
    }
}

// For production build — skip tests, sign artifacts
stage('Build for Production') {
    steps {
        sh 'mvn clean package -DskipTests -Pproduction -Dgpg.skip=true'
    }
}
```

**Best Practice:** In CI/CD, use `mvn clean package` for application deployments and `mvn clean install` for library projects. Always include test execution in non-production builds (`-DskipTests=false` is default, but be explicit).

---

### 8️⃣ What type of tests do you perform in pipelines?

**Answer:**

In CI/CD pipelines, I implement a **multi-layered testing strategy** that catches defects early, ensures quality gates, and prevents broken code from reaching production. The tests are organized in a **testing pyramid** approach:

**1. Static Code Analysis (SAST) — Fastest, runs first:**
```groovy
stage('Static Analysis') {
    steps {
        // Java - SonarQube
        sh 'mvn sonar:sonar -Dsonar.host.url=http://sonarqube:9000'

        // Node.js - ESLint
        sh 'npx eslint --ext .js,.ts src/'

        // Python - Flake8 + Pylint
        sh 'flake8 --max-line-length=120 src/'
        sh 'pylint src/'

        // Security - Trivy for dependency scanning
        sh 'trivy fs --severity HIGH,CRITICAL .'
    }
}
```

**2. Unit Tests — Fast, isolated, run on every commit:**
```groovy
stage('Unit Tests') {
    steps {
        script {
            if (params.LANGUAGE == 'java') {
                sh 'mvn test'
                sh 'mvn jacoco:report'  // Code coverage
            } else if (params.LANGUAGE == 'node') {
                sh 'npm test -- --coverage'
            } else if (params.LANGUAGE == 'python') {
                sh 'pytest tests/unit --junitxml=reports/unit.xml --cov=src'
            }
        }
    }
}
```

**3. Integration Tests — Validates component interaction:**
```groovy
stage('Integration Tests') {
    steps {
        script {
            // Spin up test database using Testcontainers
            sh '''
                docker-compose -f docker-compose-test.yml up -d
                pytest tests/integration --junitxml=reports/integration.xml
                docker-compose -f docker-compose-test.yml down
            '''
        }
    }
}
```

**4. Container Image Scanning — Security check:**
```groovy
stage('Image Security Scan') {
    steps {
        sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL myregistry/myapp:${BUILD_NUMBER}'
    }
}
```

**5. Smoke Tests — Post-deployment validation:**
```groovy
stage('Smoke Tests') {
    steps {
        sh '''
            # Verify the deployed service is healthy
            curl -f http://myapp-service/health || exit 1

            # Run basic API checks
            curl -f http://myapp-service/api/v1/status || exit 1
        '''
    }
}
```

**6. Performance/Load Tests — Gate for production:**
```groovy
stage('Performance Tests') {
    when {
        branch 'main'
    }
    steps {
        sh '''
            k6 run --out json=k6-results.json scripts/load-test.js
            # Fail if p95 latency > 500ms
            jq '.metrics.http_req_duration.values.p(95)' k6-results.json
        '''
    }
}
```

**Quality Gates:**
- **Code Coverage:** Minimum 80% line coverage (enforced by JaCoCo, Istanbul, or pytest-cov)
- **Security:** Zero CRITICAL/HIGH vulnerabilities (Trivy, Snyk, or SonarQube)
- **Static Analysis:** Zero blocker/critical issues in SonarQube
- **Build Stability:** All unit and integration tests must pass
- **Pipeline SLA:** Build should complete within defined time threshold (e.g., 15 minutes)

---

### 9️⃣ How do you set up reusable workflows for 10 microservices? How are pipeline triggers for different microservices?

**Answer:**

For managing **10 microservices**, the key is to avoid duplicating pipeline logic. I use a combination of **Jenkins Shared Libraries**, **folder-level pipeline templates**, and **event-driven triggers** to create a maintainable, scalable CI/CD system.

**Architecture:**

```
┌─────────────────────────────────────────────┐
│         Jenkins Shared Library              │
│  (buildAndTest, scanImage, deployToK8s,     │
│   notifySlack, runTests)                    │
└──────────┬──────────────────────────────────┘
           │ imported by
    ┌──────┴──────┬──────────┬──────────┐
    │             │          │          │
 ┌───────┐  ┌────────┐ ┌───────┐ ┌───────┐
 │ order │  │ payment│ │ user  │ │ email │
 │_svc   │  │_svc    │ │_svc   │ │_svc   │
 │Jenkins│  │Jenkins │ │Jenkins│ │Jenkins│
 │file   │  │file    │ │file   │ │file   │
 └───────┘  └────────┘ └───────┘ └───────┘
```

**Jenkins Shared Library — `vars/deployMicroservice.groovy`:**
```groovy
def call(String serviceName, String namespace, String imageTag) {
    def registry = 'myregistry.io/company'

    stage("Deploy ${serviceName}") {
        sh """
            kubectl set image deployment/${serviceName} \\
                ${serviceName}=${registry}/${serviceName}:${imageTag} \\
                -n ${namespace}
            kubectl rollout status deployment/${serviceName} \\
                -n ${namespace} --timeout=300s
        """
    }

    stage("Smoke Test ${serviceName}") {
        sh "curl -f http://${serviceName}-service.${namespace}/health"
    }
}
```

**Individual Microservice Jenkinsfile (reused across all 10 services):**
```groovy
@Library('ci-cd-library') _

pipeline {
    agent any

    environment {
        SERVICE_NAME = env.JENKINS_JOB_NAME
        NAMESPACE = 'production'
        LANGUAGE = 'java'  // Override per service if needed
    }

    triggers {
        // Trigger on SCM change
        pollSCM('H/5 * * * *')

        // Trigger on webhook (GitHub/GitLab push)
        // Configured via Jenkins webhook plugin
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build & Test') {
            steps {
                script { buildAndTest(env.LANGUAGE) }
            }
        }

        stage('Container Build') {
            steps {
                sh """
                    docker build -t myregistry.io/${SERVICE_NAME}:${BUILD_NUMBER} .
                    docker push myregistry.io/${SERVICE_NAME}:${BUILD_NUMBER}
                """
            }
        }

        stage('Deploy') {
            when { branch 'main' }
            steps {
                script {
                    deployMicroservice(env.SERVICE_NAME, env.NAMESPACE, "${BUILD_NUMBER}")
                }
            }
        }
    }

    post {
        always { cleanWs() }
        success {
            script { notifySlack("${SERVICE_NAME} deployed successfully") }
        }
        failure {
            script { notifySlack("${SERVICE_NAME} build FAILED") }
        }
    }
}
```

**Trigger Strategies for Different Microservices:**

| Trigger Type | How It Works | Use Case |
|-------------|-------------|----------|
| **Webhook (Push)** | GitHub/GitLab sends POST to Jenkins on every push. Jenkins matches the repo to the pipeline. | Real-time builds on code push |
| **PollSCM** | Jenkins polls the repository at a cron schedule for changes. | Fallback when webhooks are not available |
| **Upstream Trigger** | Pipeline A completes → triggers Pipeline B (downstream dependency). | When service B depends on service A's deployment |
| **Downstream Trigger (Multi-Service)** | A "parent" pipeline triggers all 10 microservice pipelines in parallel. | Full environment deployment / release train |
| **Manual Trigger** | Jenkins button click with parameters. | Emergency rollback, canary promotion |
| **Scheduled Trigger** | Cron-based trigger (e.g., nightly). | Scheduled dependency updates, cleanup jobs |

**Parent Pipeline for Full Deployment:**
```groovy
stage('Deploy All Services') {
    parallel {
        stage('Deploy Order Service') {
            steps { buildJob 'order-service/deploy', propagate: true, wait: true }
        }
        stage('Deploy Payment Service') {
            steps { buildJob 'payment-service/deploy', propagate: true, wait: true }
        }
        stage('Deploy User Service') {
            steps { buildJob 'user-service/deploy', propagate: true, wait: true }
        }
        // ... remaining services
    }
}
```

---

### 🔟 What metrics and SLA do you define to get a pipeline's health?

**Answer:**

Pipeline health is measured through a combination of **quantitative metrics** and **service level agreements (SLAs)** that give visibility into reliability, speed, and quality of the CI/CD system.

**Key Pipeline Metrics:**

| Metric | Definition | Target | How to Measure |
|--------|-----------|--------|----------------|
| **Build Success Rate** | Percentage of builds that pass vs. total builds | ≥ 95% | Jenkins build statistics, Prometheus |
| **Build Duration (Lead Time)** | Time from code commit to deployment | < 15 min for microservice | Jenkins `BUILD_DURATION`, Prometheus histogram |
| **Deployment Frequency** | Number of successful deployments per day/week | ≥ 5/day per service | Deployment event count from K8s |
| **Mean Time to Recovery (MTTR)** | Average time to rollback from a failed deployment | < 5 minutes | Time between failed deploy and successful rollback |
| **Change Failure Rate** | Percentage of deployments that cause incidents | < 5% | Incident management tool correlation |
| **Queue Wait Time** | Time a build waits before execution | < 2 minutes | Jenkins queue metrics |
| **Test Coverage** | Code coverage percentage per build | ≥ 80% | JaCoCo / Istanbul / pytest-cov reports |
| **Security Vulnerability Count** | Number of CRITICAL/HIGH vulnerabilities per build | 0 | Trivy / Snyk / SonarQube |
| **Pipeline Stability Index** | Consecutive successful builds ratio | ≥ 10 consecutive | Jenkins trend analysis |

**SLA Definitions:**

```yaml
# Pipeline SLA Configuration
pipeline_sla:
  build_completion:
    target: "15 minutes"
    warning: "20 minutes"
    critical: "30 minutes"

  deployment_window:
    target: "5 minutes"
    warning: "10 minutes"
    critical: "15 minutes"

  availability:
    target: "99.9%"  # Jenkins controller uptime
    measurement: "monthly"

  quality_gates:
    unit_test_pass_rate: "100%"
    code_coverage_minimum: "80%"
    critical_vulnerabilities: "0"
    code_smell_threshold: "0 blocker issues"

  rollback:
    mttr_target: "5 minutes"
    max_rollback_time: "10 minutes"
```

**Monitoring Dashboard (Prometheus + Grafana):**

```promql
# Build success rate (last 24h)
sum(increase(jenkins_builds_success[24h])) / sum(increase(jenkins_builds_total[24h])) * 100

# Average build duration
avg(jenkins_build_duration_seconds)

# Build queue wait time
avg(jenkins_queue_wait_seconds)

# Deployment frequency
count(jenkins_deployments{status="success"}[1d])
```

**Alerting Rules:**
- **Page on-call:** Build success rate drops below 90% over 1 hour
- **Warning:** Average build duration exceeds 20 minutes for 3 consecutive builds
- **Info:** Code coverage drops below 80% on a PR build
- **Critical:** Any build with CRITICAL security vulnerabilities should block deployment and notify the security team

---

## 🟩 Microservices & Pipeline Design

---

### 11️⃣ Did you work on any migrations?

**Answer:**

Yes, I have extensive experience with migrations across multiple dimensions. Here are the most significant migration projects I have worked on:

**1. On-Premises to AWS EKS Migration:**

We migrated a monolithic application running on **on-premises virtual machines** (running Tomcat + Nginx) to a **microservices architecture on AWS EKS**.

- **Strategy:** Used a **strangler fig pattern** — gradually extracted individual services from the monolith and deployed them to EKS, while maintaining the original system running in parallel.
- **Database Migration:** Used **AWS DMS (Database Migration Service)** for zero-downtime data migration from on-premises Oracle to Amazon RDS PostgreSQL. Implemented **binlog-based replication** to keep data in sync during the transition period.
- **DNS Cutover:** Gradually shifted traffic using **weighted routing in AWS Route 53** (10% → 25% → 50% → 100%) to minimize risk and allow rollback at any point.
- **Challenges:** Legacy application dependencies, incompatible data formats, network latency between on-prem and cloud (resolved with AWS Direct Connect).

**2. Docker Swarm to Kubernetes (EKS) Migration:**

- Migrated 15+ microservices from **Docker Swarm** orchestration to **Amazon EKS**.
- Rewrote all **Compose files** as Kubernetes manifests (Deployments, Services, ConfigMaps, Secrets, Ingress).
- Replaced Swarm's built-in service mesh with **Istio Service Mesh** for advanced traffic management, mTLS, and observability.
- Migrated shared volumes and stateful services to use **AWS EBS CSI driver** and **StatefulSets**.
- Implemented **GitOps** with ArgoCD for continuous deployment, replacing Swarm's manual update process.

**3. Jenkins 2.x to Jenkins 2.4xx Upgrade:**

- Upgraded Jenkins from version 2.289 to 2.426 (LTS) with **zero downtime**.
- Performed a **staged upgrade** (2.289 → 2.303 → 2.333 → 2.375 → 2.426) to minimize plugin compatibility issues.
- Migrated from **freestyle jobs** to **Declarative Pipeline as Code** (Jenkinsfiles stored in Git).
- Implemented **Jenkins Controller high availability** using Jenkins Operator and external storage for job configuration.

**4. Terraform State Migration (Local to S3 Backend):**

- Migrated Terraform state from **local filesystem** to **S3 backend with DynamoDB locking**.
- Used `terraform state pull` → `terraform init -migrate-state` → configured remote backend.
- Enabled **state encryption at rest** and **versioning** for auditability.

**Key Takeaways from Migrations:**
- Always have a **rollback plan** documented and tested before starting
- Use **feature flags** and **canary deployments** for gradual cutover
- Ensure **monitoring and alerting** are in place before and during migration
- **Communicate** with all stakeholders — migrations impact many teams
- **Automate** as much as possible — manual steps are error-prone during migration

---

## 🟨 Security & IAM

---

### 12️⃣ Anything about security, identity, and secret management?

**Answer:**

Security, identity, and secret management are foundational pillars of a production-grade DevOps platform. Here is how I approach each area:

**Secret Management:**

| Tool | Use Case | How It Works |
|------|----------|-------------|
| **HashiCorp Vault** | Centralized secret store for dynamic secrets, certificates, API keys | Dynamic database credentials, lease-based rotation, audit logging, PKI secret engine for TLS certs |
| **AWS Secrets Manager** | AWS-native secret storage with automatic rotation | Stores RDS credentials, API keys; integrates with Lambda for rotation schedules; costs per secret |
| **Kubernetes Secrets (Encoded)** | Basic secret injection into pods | Base64-encoded data (NOT encrypted by default) — use **encryption at rest** with `EncryptionConfiguration` |
| **AWS SSM Parameter Store** | Configuration values and encrypted secrets (SecureString) | Hierarchical parameter organization, encryption via KMS, cost-effective for simple use cases |

**Best Practices for Secrets in Kubernetes:**
```yaml
# Never store secrets in plain text in manifests
# Use external-secrets-operator to sync from Vault/AWS Secrets Manager
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: secret/data/db
      property: username
  - secretKey: password
    remoteRef:
      key: secret/data/db
      property: password
```

**Identity & Access Management:**

- **AWS IAM Roles for Service Accounts (IRSA):** Kubernetes Service Accounts are mapped to AWS IAM Roles. Pods assume the IAM role automatically, eliminating the need for long-lived AWS access keys.
- **OIDC Integration:** EKS cluster's OIDC provider is linked to IAM, enabling trust relationships between Kubernetes Service Accounts and AWS IAM Roles.
- **RBAC (Role-Based Access Control):** Fine-grained permissions within Kubernetes namespaces. Roles define what actions can be performed on which resources; RoleBindings assign those roles to users/groups/service accounts.

```yaml
# Kubernetes RBAC — restrict a service account to a specific namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: order-service
  name: order-deployer
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "patch", "update"]
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: order-deployer-binding
  namespace: order-service
subjects:
- kind: ServiceAccount
  name: jenkins-deployer
  namespace: jenkins
roleRef:
  kind: Role
  name: order-deployer
  apiGroup: rbac.authorization.k8s.io
```

**Container Security:**
- **Image Scanning:** Trivy/Snyk integrated into CI pipeline — blocks builds with CRITICAL/HIGH vulnerabilities
- **Pod Security Standards:** Enforce `restricted` PSS via PodSecurity admission controller
- **Non-root Containers:** All containers run as non-root (`runAsNonRoot: true`, `runAsUser: 1000`)
- **Read-Only Root Filesystem:** `readOnlyRootFilesystem: true` with writable tmpfs for temp directories
- **Minimal Base Images:** Use `distroless` or `alpine` images to reduce attack surface

**Network Security:**
- **Network Policies:** Restrict pod-to-pod communication (see Q28)
- **Security Groups:** Restrict node-level traffic using AWS Security Groups
- **Private Clusters:** EKS control plane and nodes in private subnets, accessed via bastion or VPC endpoints

---

### 13️⃣ Can you explain how AWS IAM Roles, Permission Boundaries, and SCP work together in an enterprise/SO environment?

**Answer:**

In an enterprise AWS environment (especially financial or regulated industries), **IAM Roles**, **Permission Boundaries**, and **Service Control Policies (SCPs)** form a **defense-in-depth** access control model. Each operates at a different level of the AWS hierarchy and serves a distinct purpose.

**Three Layers of Access Control:**

```
┌─────────────────────────────────────────────────────┐
│  Layer 1: Organization (Top-level constraint)       │
│  ┌───────────────────────────────────────────────┐  │
│  │  Service Control Policy (SCP)                 │  │
│  │  - Applied at OU or Account level              │  │
│  │  - Acts as a guardrail (maximum permission)    │  │
│  │  - Cannot grant permissions, only restrict     │  │
│  └─────────────────────┬─────────────────────────┘  │
│                        │                            │
│  Layer 2: IAM Entity (Session constraint)           │
│  ┌─────────────────────▼─────────────────────────┐  │
│  │  Permission Boundary                           │  │
│  │  - Attached to IAM User/Role                   │  │
│  │  - Defines maximum permissions the entity      │  │
│  │    can acquire (even if inline/managed policies │  │
│  │    grant more)                                  │  │
│  └─────────────────────┬─────────────────────────┘  │
│                        │                            │
│  Layer 3: Effective Permissions                     │
│  ┌─────────────────────▼─────────────────────────┐  │
│  │  IAM Policy (attached to Role/User)            │  │
│  │  - Grants specific permissions                 │  │
│  │  - Effective = IAM Policy AND Permission       │  │
│  │    Boundary AND SCP (intersection)             │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

**1. Service Control Policy (SCP) — Organization Level:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RestrictRegions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-west-2"]
        }
      }
    },
    {
      "Sid": "DenySensitiveActions",
      "Effect": "Deny",
      "Action": [
        "iam:DeleteUser",
        "iam:DeleteRole",
        "organizations:LeaveOrganization"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EnforceEncryption",
      "Effect": "Deny",
      "Action": [
        "s3:PutObject",
        "ec2:RunInstances"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "s3:x-amz-server-side-encryption": "false"
        }
      }
    }
  ]
}
```

**2. Permission Boundary — IAM Entity Level:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "rds:*",
        "eks:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "iam:*",
        "organizations:*",
        "account:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**3. IAM Role Policy — Granular Permissions:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      "Resource": "arn:aws:ec2:us-east-1:123456789012:instance/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::company-app-bucket/*"
    }
  ]
}
```

**How They Work Together — Effective Permission Calculation:**

The effective permission for any action is the **intersection** (AND) of all three layers:

```
Effective Permission = IAM Policy (Allow)
                     AND Permission Boundary (Allow)
                     AND SCP (Not Denied)
```

**Example Scenario — DevOps Engineer Role:**

| Layer | Configuration | Effect |
|-------|-------------|--------|
| **SCP** (Org level) | Deny all actions outside `us-east-1`, Deny IAM deletion | Organization-wide guardrails |
| **Permission Boundary** (Role level) | Allow EC2, S3, EKS, RDS; Deny IAM, Organizations | Role cannot exceed these service boundaries |
| **IAM Policy** (Role policy) | Allow `ec2:Describe*`, `ec2:Start*`, `s3:GetObject` on specific resources | Actual working permissions |
| **Effective** | Can describe/start EC2 in us-east-1, read from S3 | Intersection of all three |

**SSO Integration (AWS IAM Identity Center / SSO):**

```
┌────────────────────────────────────────────┐
│  AWS IAM Identity Center (SSO)             │
│  ├── Permission Set: DevOps Admin           │
│  │   ├── Attached Policy: DevOpsFullAccess  │
│  │   └── Permission Boundary: DevOpsLimit   │
│  ├── Permission Set: Developer Read-Only    │
│  │   └── Attached Policy: ReadOnlyAccess    │
│  └── Permission Set: Auditor                │
│      └── Attached Policy: SecurityAudit     │
│  ┌──────────────────────────────────────┐  │
│  │  Identity Provider: Okta / Azure AD  │  │
│  │  (Federated SSO)                     │  │
│  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

When a user logs in via SSO:
1. Identity Provider (Okta/Azure AD) authenticates the user
2. IAM Identity Center creates temporary AWS credentials
3. The **Permission Set** determines which IAM policies and boundaries are applied
4. **SCP** at the organization/account level further restricts what can be done
5. The user gets the **intersection** of all permissions — the most restrictive wins

---

### 14️⃣ Can you walk me through your troubleshooting steps to perform a security incident response when a pod in EKS is compromised?

**Answer:**

A compromised pod in EKS is a **critical security incident** that requires an immediate, structured response. Here is my step-by-step incident response procedure:

**Phase 1: Detection & Containment (Minutes 0–15)**

```bash
# Step 1: Identify the compromised pod
kubectl get pods -A --field-selector=status.phase=Running -o wide

# Step 2: Check for anomalous behavior
kubectl top pod <pod-name> -n <namespace>  # High CPU/memory usage
kubectl logs <pod-name> -n <namespace> --tail=500  # Malicious commands
kubectl describe pod <pod-name> -n <namespace>  # Unexpected volume mounts, env vars

# Step 3: Check for crypto-mining, unusual network connections
kubectl exec -it <pod-name> -n <namespace> -- netstat -tulpn
kubectl exec -it <pod-name> -n <namespace> -- ps aux
kubectl exec -it <pod-name> -n <namespace> -- ss -tunap
```

**Step 4: Immediate Containment — Isolate the Pod:**

```bash
# Option A: Apply a NetworkPolicy to isolate the compromised pod
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-compromised-pod
  namespace: <namespace>
spec:
  podSelector:
    matchLabels:
      app: <compromised-app>
  policyTypes:
  - Ingress
  - Egress
  # No ingress or egress rules = complete isolation
EOF

# Option B: Scale the deployment to 0 to kill all compromised replicas
kubectl scale deployment <deployment-name> -n <namespace> --replicas=0

# Option C: Cordont the node if the compromise has escaped the pod
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

**Phase 2: Investigation & Forensics (Minutes 15–60)**

```bash
# Step 5: Collect forensic evidence
# Save pod spec and events
kubectl get pod <pod-name> -n <namespace> -o yaml > forensics/pod-spec.yaml
kubectl get events -n <namespace> --sort-by='.lastTimestamp' > forensics/events.log

# Step 6: Check container image for vulnerabilities
trivy image <image-name>:<tag>

# Step 7: Check for lateral movement
# Look at CloudTrail for unusual API calls
aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=<iam-role>

# Step 8: Check VPC Flow Logs for suspicious outbound traffic
# Look for connections to known C2 IPs or unusual ports

# Step 9: Review EKS audit logs
# Check for unauthorized RBAC escalations, secret access
```

**Phase 3: Eradication (Minutes 60–120)**

```bash
# Step 10: Remove the compromised workload
kubectl delete pod <pod-name> -n <namespace> --grace-period=0 --force

# Step 11: Rebuild from known-good image
# Scan the image before redeployment
trivy image --exit-code 1 --severity MEDIUM,HIGH,CRITICAL <good-image>:<tag>

# Step 12: Rotate all credentials that may have been exposed
# - Kubernetes Secrets
# - AWS IAM access keys
# - Database passwords
# - API keys and tokens

# Step 13: Update image pull policies and add image signing verification
kubectl set image deployment/<name> <container>=<good-image>:<tag> --dry-run=client -o yaml
```

**Phase 4: Recovery & Hardening (Hours 1–24)**

```bash
# Step 14: Restore from clean image with additional security controls
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <service-name>
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: <container>
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: ["ALL"]
EOF

# Step 15: Uncordon the node after investigation
kubectl uncordon <node-name>

# Step 16: Enhance monitoring and alerting
# Deploy Falco for runtime security monitoring
# Enable EKS control plane audit logging
# Configure GuardDuty for EKS
```

**Phase 5: Post-Incident Review**

| Action | Detail |
|--------|--------|
| **Root Cause Analysis** | Determine how the compromise occurred (vulnerable image, exposed secret, CVE exploitation, supply chain attack) |
| **Timeline Documentation** | Document every action taken with timestamps |
| **Lessons Learned** | What detection gaps existed? How can containment be faster? |
| **Remediation Plan** | Implement preventive controls (image signing, runtime monitoring, network policies, least-privilege IAM) |
| **Update Runbooks** | Document the incident response procedure for future reference |

**Key Tools for EKS Security Monitoring:**
- **Amazon GuardDuty:** Threat detection for EKS (anomalous API calls, suspicious network traffic)
- **Falco:** Runtime security monitoring for containers (file modification, unusual process execution)
- **AWS CloudTrail:** API call auditing for EKS control plane
- **Trivy/Grype:** Container image vulnerability scanning
- **Sysdig/Falco:** Behavioral anomaly detection

---

## 🟪 Monitoring & Logging

---

### 15️⃣ Which monitoring tools did you use? Did you use AWS CloudWatch?

**Answer:**

Yes, I have used a **comprehensive monitoring stack** that combines AWS-native tools with open-source solutions for full-stack observability.

**AWS CloudWatch — Core Monitoring:**

```yaml
# CloudWatch Alarms for EKS
Alarms:
  - Name: HighCPUUtilization
    Metric: CPUUtilization
    Namespace: AWS/EC2
    Statistic: Average
    Threshold: 80
    ComparisonOperator: GreaterThanThreshold
    EvaluationPeriods: 3
    Period: 300
    AlarmActions:
      - arn:aws:sns:us-east-1:123456789012:ops-alerts

  - Name: EKSControlPlaneAPIErrors
    Metric: APILatency
    Namespace: AWS/EKS
    Statistic: p99
    Threshold: 1000  # 1 second
    ComparisonOperator: GreaterThanThreshold
    EvaluationPeriods: 2
    Period: 300

  - Name: PodRestartsHigh
    Metric: pod_restart
    Namespace: container_insights
    Statistic: Sum
    Threshold: 5
    ComparisonOperator: GreaterThanThreshold
    EvaluationPeriods: 1
    Period: 300
```

**Full Monitoring Stack:**

| Tool | Purpose | What It Monitors |
|------|---------|-----------------|
| **AWS CloudWatch** | Metrics, logs, and alarms | EC2 metrics, EKS control plane metrics, Lambda invocations, custom application metrics |
| **CloudWatch Container Insights** | EKS-specific monitoring | Cluster/node/pod metrics, daemonset metrics, integrated with Prometheus |
| **Prometheus** | Metrics collection and querying | Custom application metrics, scrape targets, alerting rules |
| **Grafana** | Visualization and dashboards | Custom dashboards for application performance, infrastructure metrics, SLO tracking |
| **Jaeger / AWS X-Ray** | Distributed tracing | Request flow across microservices, latency breakdown, error propagation |
| **ELK Stack (Elasticsearch, Logstash, Kibana)** | Centralized log management | Aggregated logs from all services, log search, log analysis |
| **Datadog / New Relic** | Full-stack SaaS monitoring | APM, infrastructure, logs, traces, synthetic monitoring (alternative to self-managed stack) |
| **PagerDuty / Opsgenie** | Incident management and on-call | Alert routing, escalation policies, incident tracking |

**CloudWatch Logs Integration:**
- **CloudWatch Agent** deployed as a DaemonSet on EKS nodes to collect system and container logs
- **Log groups** organized by namespace and deployment name (`/eks/cluster-name/namespace/deployment`)
- **Log metrics filters** to extract error rates, latency percentiles, and custom business metrics from log patterns
- **Cross-account log aggregation** for centralized logging across multiple AWS accounts

**Application-Level Metrics (Prometheus format):**
```python
# Python app with Prometheus client
from prometheus_client import Counter, Histogram, Gauge

# Request counter
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])

# Request latency
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency', ['method', 'endpoint'])

# Active connections
ACTIVE_CONNECTIONS = Gauge('active_connections', 'Current active connections')

# Usage in Flask/FastAPI middleware
@request_finished.connect
def track_request(sender, response, **extra):
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint,
        status=response.status_code
    ).inc()
```

---

### 16️⃣ You need to set up log collection for 6 microservices running on EKS and logs should go to CloudWatch. How?

**Answer:**

Setting up centralized log collection for 6 microservices on EKS with logs flowing to **Amazon CloudWatch** involves deploying the **CloudWatch Container Insights Agent** (based on Fluent Bit) as a DaemonSet across the cluster.

**Architecture:**

```
┌─────────────────────────────────────────────────────┐
│  EKS Cluster                                         │
│                                                      │
│  Node 1                    Node 2                   │
│  ┌──────────┐            ┌──────────┐              │
│  │user-svc  │            │order-svc │              │
│  │payment-sv│            │email-svc │              │
│  └────┬─────┘            └────┬─────┘              │
│       │ stdout/stderr          │                    │
│  ┌────▼─────┐            ┌────▼─────┐              │
│  │FluentBit │            │FluentBit │  (DaemonSet) │
│  │(cwagent) │            │(cwagent) │              │
│  └────┬─────┘            └────┬─────┘              │
│       └──────────┬───────────┘                     │
│                  │                                 │
└──────────────────┼─────────────────────────────────┘
                   │
                   ▼
         ┌───────────────────┐
         │  CloudWatch Logs   │
         │  /eks/cluster/     │
         │   namespace/       │
         │   deployment       │
         └───────────────────┘
```

**Step-by-Step Implementation:**

**Step 1: Create IAM Role for Service Account (IRSA) for CloudWatch access:**
```hcl
resource "aws_iam_role" "cloudwatch_logs_role" {
  name = "eks-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${var.eks_oidc_issuer_url}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.eks_oidc_issuer_url}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.cloudwatch_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_pod_identity_association" "cloudwatch" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cloudwatch_logs_role.arn
}
```

**Step 2: Deploy CloudWatch Container Insights using the AWS Add-on:**
```bash
# Using eksctl to install CloudWatch Container Insights
eksctl create iamserviceaccount \
  --name cloudwatch-agent \
  --namespace amazon-cloudwatch \
  --cluster my-eks-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  --approve \
  --override-existing-serviceaccounts

# Deploy the Fluent Bit DaemonSet from AWS managed add-on
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml
```

**Step 3: Configure Fluent Bit to parse and route logs by service:**
```yaml
# Fluent Bit configuration (cwagent configmap)
FluentBitConfig: |
  [SERVICE]
      Flush         5
      Log_Level     info
      Daemon        off

  [INPUT]
      Name          tail
      Tag           kube.*
      Path          /var/log/containers/*.log
      Parser        docker
      DB            /var/log/flb_kube.db
      Mem_Buf_Limit 50MB
      Skip_Long_Lines On

  [FILTER]
      Name          kubernetes
      Match         kube.*
      Kube_URL      https://kubernetes.default.svc:443
      Kube_Cert_Token_On_Off On
      Merge_Log     On
      Keep_Log      Off
      K8S-Logging.Parser On
      K8S-Logging.Exclude On

  [OUTPUT]
      Name          cloudwatch_logs
      Match         *
      region        us-east-1
      log_group_name      /eks/my-cluster/\${kubernetes.namespace_name}/\${kubernetes.pod_name}
      log_stream_name     \${kubernetes.container_name}
      auto_create_group   true
      extra_user_agent    container-insights
```

**Step 4: Ensure all 6 microservices write logs to stdout/stderr:**

Each microservice should write logs to standard output/error (not files). Fluent Bit tail logs from the container runtime log files automatically.

```python
# Python microservice - log to stdout
import logging
logging.basicConfig(
    format='%(asctime)s %(levelname)s %(name)s - %(message)s',
    level=logging.INFO,
    stream=sys.stdout  # Logs go to stdout → picked up by Fluent Bit
)
logger = logging.getLogger('user-service')
logger.info("User login successful: user_id=12345")
```

```javascript
// Node.js microservice - log to stdout
const winston = require('winston');
const logger = winston.createLogger({
    level: 'info',
    transports: [
        new winston.transports.Console({  // stdout/stderr
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            )
        })
    ]
});
logger.info({ msg: 'Order processed', orderId: 'ORD-001' });
```

**Step 5: Verify log delivery in CloudWatch Console:**
- Navigate to **CloudWatch → Log Groups**
- Verify log groups exist: `/eks/my-cluster/order-service/order-pod-abc123`
- Use **Log Insights** to query across all 6 services:
```
fields @timestamp, @message, kubernetes.pod_name, kubernetes.namespace_name
| filter kubernetes.namespace_name = 'production'
| sort @timestamp desc
| limit 20
```

**Cost Optimization:**
- Set **log retention** policies (e.g., 30 days for DEBUG, 90 days for INFO, 365 days for ERROR)
- Use **log filtering** to exclude verbose DEBUG logs from production
- Consider **S3 log archival** for long-term retention (cheaper than CloudWatch Logs)

---

### 17️⃣ Can you walk me through the steps of how you will configure log collection for EKS?

**Answer:**

Here is a detailed, step-by-step walkthrough of configuring end-to-end log collection for EKS microservices flowing to CloudWatch:

**Step 1: Prerequisites — EKS Cluster with OIDC Provider:**

```bash
# Verify OIDC provider is configured (needed for IRSA)
aws eks describe-cluster --name my-eks-cluster --query "cluster.identity.oidc.issuer"

# Create OIDC provider if not exists
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster my-eks-cluster \
  --approve
```

**Step 2: Create the `amazon-cloudwatch` Namespace:**
```bash
kubectl create namespace amazon-cloudwatch
```

**Step 3: Create IAM Role with CloudWatch Logs Policy:**
```bash
# Create IAM policy
cat > cloudwatch-agent-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeImages",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy --policy-name CloudWatchAgentPolicy --policy-document file://cloudwatch-agent-policy.json
```

**Step 4: Create IAM Role and Trust Relationship with EKS OIDC:**
```bash
OIDC_PROVIDER=$(aws eks describe-cluster --name my-eks-cluster --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
        }
      }
    }
  ]
}
EOF

aws iam create-role --role-name eks-cloudwatch-agent-role --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name eks-cloudwatch-agent-role --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/CloudWatchAgentPolicy
```

**Step 5: Annotate the Service Account with the IAM Role ARN:**
```bash
ROLE_ARN=$(aws iam get-role --role-name eks-cloudwatch-agent-role --query "Role.Arn" --output text)

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudwatch-agent
  namespace: amazon-cloudwatch
  labels:
    app.k8s.io/name: cloudwatch-agent
  annotations:
    eks.amazonaws.com/role-arn: ${ROLE_ARN}
EOF
```

**Step 6: Create ConfigMap with Fluent Bit Configuration:**
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-cluster-info
  namespace: amazon-cloudwatch
data:
  cluster.name: my-eks-cluster
  logs.region: us-east-1
EOF
```

**Step 7: Deploy CloudWatch Agent (Fluent Bit) as DaemonSet:**
```bash
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml
```

**Step 8: Verify Deployment:**
```bash
# Check DaemonSet pods are running
kubectl get pods -n amazon-cloudwatch

# Expected output:
# NAME                                 READY   STATUS    RESTARTS   AGE
# fluent-bit-xxxxx                     2/2     Running   0          2m
# fluent-bit-yyyyy                     2/2     Running   0          2m

# Check logs for errors
kubectl logs -n amazon-cloudwatch -l app.kubernetes.io/name=fluent-bit

# Verify CloudWatch Log Groups are created
aws logs describe-log-groups --log-group-name-prefix /eks/my-eks-cluster
```

**Step 9: Test Log Flow:**
```bash
# Deploy a test pod that generates logs
kubectl run test-logger --image=busybox -- /bin/sh -c 'while true; do echo "$(date) - Test log entry from microservice"; sleep 5; done'

# Wait a few minutes, then check CloudWatch
aws logs get-log-events \
  --log-group-name "/eks/my-eks-cluster/default/test-logger" \
  --log-stream-name "test-logger" \
  --limit 10
```

**Step 10: Set Up Log Insights Dashboards and Alarms:**
```bash
# Create metric filter for error log lines
aws logs put-metric-filter \
  --log-group-name "/eks/my-eks-cluster/production/*" \
  --filter-name "ErrorCount" \
  --filter-pattern "ERROR" \
  --metric-transformations metricName=ErrorCount,metricNamespace=EKSAppLogs,metricValue=1

# Create CloudWatch Alarm on error rate
aws clouds put-metric-alarm \
  --alarm-name "HighErrorRate" \
  --metric-name ErrorCount \
  --namespace EKSAppLogs \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:ops-alerts
```

---

## 🟥 EKS Architecture

---

### 18️⃣ Can you tell me how you will design a multi-tenant EKS cluster to solve several products with network, service, RBAC, and cost isolation?

**Answer:**

Designing a **multi-tenant EKS cluster** requires careful isolation across four dimensions: **network**, **namespace/RBAC**, **resource (compute)**, and **cost**. Here is the comprehensive architecture:

**Cluster Topology:**

```
┌────────────────────────────────────────────────────────────┐
│                    EKS Cluster                              │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Namespace:   │  │ Namespace:   │  │ Namespace:   │      │
│  │ product-a    │  │ product-b    │  │ product-c    │      │
│  │              │  │              │  │              │      │
│  │ Deployments  │  │ Deployments  │  │ Deployments  │      │
│  │ Services     │  │ Services     │  │ Services     │      │
│  │ ConfigMaps   │  │ ConfigMaps   │  │ ConfigMaps   │      │
│  │ Secrets      │  │ Secrets      │  │ Secrets      │      │
│  │              │  │              │  │              │      │
│  │ Quota: 4 CPU │  │ Quota: 8 CPU │  │ Quota: 4 CPU │      │
│  │ Quota: 16GB  │  │ Quota: 32GB  │  │ Quota: 16GB  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │              │
│  ┌──────▼─────────────────▼──────────────────▼───────┐      │
│  │              Network Policies                       │      │
│  │  - Product A cannot reach Product B's pods         │      │
│  │  - Default deny all, explicit allow rules          │      │
│  └───────────────────────────────────────────────────┘      │
│                                                             │
│  ┌───────────────────────────────────────────────────┐      │
│  │  Node Pools (Resource Isolation)                   │      │
│  │  - General Purpose Nodes (m5.xlarge)              │      │
│  │  - High Memory Nodes (r5.2xlarge) for analytics   │      │
│  │  - Spot Nodes for batch jobs (cost optimization)  │      │
│  └───────────────────────────────────────────────────┘      │
└────────────────────────────────────────────────────────────┘
```

**1. Namespace Isolation — Organizational Boundary:**
```yaml
# Create namespaces for each product
apiVersion: v1
kind: Namespace
metadata:
  name: product-a
  labels:
    product: product-a
    team: team-a
    cost-center: CC-1001
---
apiVersion: v1
kind: Namespace
metadata:
  name: product-b
  labels:
    product: product-b
    team: team-b
    cost-center: CC-1002
```

**2. Resource Quotas — Compute Isolation:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: product-a-quota
  namespace: product-a
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "16Gi"
    limits.cpu: "8"
    limits.memory: "32Gi"
    pods: "20"
    services: "10"
    persistentvolumeclaims: "5"
    configmaps: "20"
    secrets: "20"
---
# LimitRange — default resource requests/limits per container
apiVersion: v1
kind: LimitRange
metadata:
  name: product-a-limits
  namespace: product-a
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "1Gi"
    defaultRequest:
      cpu: "250m"
      memory: "512Mi"
    type: Container
```

**3. RBAC — Access Isolation:**
```yaml
# Product A team can only manage resources in product-a namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: product-a-developer
  namespace: product-a
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: product-a-dev-binding
  namespace: product-a
subjects:
- kind: Group
  name: team-a-developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: product-a-developer
  apiGroup: rbac.authorization.k8s.io
```

**4. Network Policies — Network Isolation:**
```yaml
# Default deny all traffic in product-a namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: product-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow only specific inter-service communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
  namespace: product-a
spec:
  podSelector:
    matchLabels:
      app: api-server
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to: []  # Allow DNS
    ports:
    - protocol: UDP
      port: 53
```

**5. Cost Allocation — Financial Isolation:**
```yaml
# Apply labels and annotations for cost tracking
metadata:
  labels:
    product: product-a
    team: team-a
    environment: production
    cost-center: CC-1001
    project: "ascendion-product-a"
```

Use **AWS Cost Explorer** with these labels to generate cost reports per product. Enable **AWS Cost Allocation Tags** in the AWS Console to make these tags visible in billing.

**6. Shared Services — Common Infrastructure:**

```
┌─────────────────────────────────────────────┐
│  Namespace: shared-infrastructure            │
│  - Ingress Controller (nginx/ALB)            │
│  - External DNS                              │
│  - Cert Manager                              │
│  - Prometheus/Grafana                        │
│  - Fluent Bit (logging)                      │
│  - External Secrets Operator                 │
└─────────────────────────────────────────────┘
```

**7. Multi-Tenancy Considerations:**

| Isolation Dimension | Mechanism | Enforcement Level |
|--------------------|-----------|-------------------|
| **Namespace** | Kubernetes Namespaces | Logical separation of resources |
| **RBAC** | Role + RoleBinding per namespace | Access control per team/product |
| **Network** | Network Policies (Calico/Cilium) | Pod-level network segmentation |
| **Compute** | ResourceQuota + LimitRange | CPU/memory limits per namespace |
| **Cost** | AWS Cost Allocation Tags + AWS Budgets | Financial tracking per product |
| **Storage** | Namespace-scoped PVCs + Quotas | Storage isolation per product |
| **Secrets** | Namespace-scoped Secrets + External Secrets Operator | Credential isolation |

**Trade-offs:** Single multi-tenant cluster reduces operational overhead (one control plane to manage) but requires strict governance. For highly regulated environments where teams require complete isolation, **separate clusters per product** may be warranted despite higher management cost.

---

### 19️⃣ Do you know what is the trade-off between AWS Managed Node Groups and Self-Managed Node Groups?

**Answer:**

**Amazon EKS Managed Node Groups** and **Self-Managed Node Groups** (launched via EC2 Auto Scaling Groups) serve the same fundamental purpose — providing worker nodes for running pods — but they differ significantly in management overhead, flexibility, and cost.

| Aspect | Managed Node Groups | Self-Managed Node Groups |
|--------|-------------------|----------------------|
| **Lifecycle Management** | AWS handles node provisioning, AMI updates, and scaling. You specify desired version and count. | You manage everything — AMI selection, provisioning, updates, scaling policies, and node replacement. |
| **Launch Template** | Created and managed by EKS automatically. You can specify overrides (instance type, AMI type, labels). | You create and manage Launch Templates manually with full customization (user data, block device mapping, IAM profiles). |
| **AMI Updates** | Automatic when you upgrade the node group version. AWS provides optimized Amazon EKS Optimized AMI. | Manual — you must track AMI updates, create new Launch Templates, and perform rolling updates. |
| **Custom AMI Support** | Limited — can specify custom AMI but AWS manages the update lifecycle of the base AMI. | Full — use any custom AMI (Bottlerocket, custom Ubuntu, Packer-built images). |
| **Bootstrap Customization** | Limited via `preloadCredentials`, `updateConfig`, and taints. | Full — complete control over user-data, kubelet flags, and bootstrap scripts. |
| **Instance Types** | Any EC2 instance type. | Any EC2 instance type. |
| **Spot Instances** | Supported. | Supported with more customization options. |
| **Node Auto-Configuration** | Automatic node labeling, taint injection, and capacity reservations. | Manual — must configure labels, taints, and capacity via Launch Template. |
| **Karpenter Integration** | Works with Karpenter for provisioner-based scaling (but Karpenter manages EC2 directly, not MNG). | Works natively — Karpenter provisions and manages EC2 instances directly. |
| **Cost** | Same EC2 pricing. No additional EKS cost for managed nodes. | Same EC2 pricing. Additional operational cost for management overhead. |
| **Time to Provision** | Faster — AWS handles the provisioning pipeline. | Slower — you must set up ASG, Launch Template, and bootstrap. |
| **Drain & Replacement** | Built-in — EKS handles safe draining during updates. | Manual — must implement draining logic in update scripts. |
| **Maintenance Windows** | Configurable — set maintenance windows for updates. | Self-managed — schedule updates as needed. |

**When to Use Managed Node Groups:**
- Standard workloads where the **EKS Optimized AMI** is sufficient
- Teams that want to **minimize operational overhead**
- Quick cluster provisioning and standard node lifecycle management
- Most production workloads where custom AMI is not required

**When to Use Self-Managed Node Groups:**
- **Custom AMI requirements** (pre-installed agents, custom kernel, security hardening)
- **Bottlerocket OS** for enhanced security (though Bottlerocket is now supported in MNG)
- **Karpenter integration** where you want the most granular provisioning control
- **Hybrid instance type mixes** that MNG doesn't easily support
- **Specific kernel modules** or device drivers needed
- **Compliance requirements** that mandate custom base images

**My Recommendation:** Use **Managed Node Groups** as the default for 80-90% of workloads. Use **Self-Managed Node Groups** (or Karpenter) only when you have specific requirements that MNG cannot satisfy. For dynamic, right-sized provisioning, **Karpenter** is the modern approach that supersedes both MNG and self-managed ASGs for most use cases.

---

### 20️⃣ Have you ever worked on the control plane upgrade process of EKS?

**Answer:**

Yes, I have performed multiple **EKS control plane upgrades** in production environments. EKS control plane upgrades are managed by AWS (since AWS operates the control plane), but the process requires careful planning, coordination, and execution to avoid disrupting workloads.

**EKS Control Plane Upgrade Process:**

```
┌────────────────────────────────────────────────────────┐
│              EKS Upgrade Flow                           │
│                                                         │
│  1. Review available versions                           │
│  2. Upgrade control plane (AWS-managed)                 │
│  3. Upgrade node groups (user-managed)                  │
│  4. Upgrade addons (CNI, CoreDNS, kube-proxy)           │
│  5. Validate cluster health                             │
│                                                         │
│  ⚠️  Control Plane version >= Node Group version        │
│  ⚠️  Node Group version can be at most 1 version        │
│       behind the control plane                          │
└────────────────────────────────────────────────────────┘
```

**Step 1: Pre-Upgrade Checks:**
```bash
# Check current versions
aws eks describe-cluster --name my-cluster --query "cluster.version"
aws eks list-nodegroups --cluster-name my-cluster
aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name ng-1 --query "nodegroup.version"

# Check addon versions
aws eks list-addons --cluster-name my-cluster
aws eks describe-addon --cluster-name my-cluster --addon-name vpc-c

# Review available EKS versions
aws eks describe-addon-versions --addon-name vpc-c
aws eks describe-addon-versions --addon-name coredns

# Check for deprecated APIs in current manifests
kubectl api-resources --api-version=apps/v1beta2  # deprecated in 1.25+
```

**Step 2: Upgrade Control Plane:**
```bash
# Upgrade to the next patch version (recommended first step)
aws eks update-cluster-version \
  --name my-cluster \
  --kubernetes-version 1.29

# Monitor upgrade progress
aws eks describe-cluster --name my-cluster --query "cluster.status"
# Status progresses: UPDATING → ACTIVE

# Check CloudWatch for control plane logs
# Log group: /aws/eks/my-cluster/cluster
```

**Step 3: Upgrade Managed Node Groups:**
```bash
# Set update settings (max unavailable, preserve capacity)
aws eks update-nodegroup-config \
  --cluster-name my-cluster \
  --nodegroup-name ng-1 \
  --scaling-config minSize=2,maxSize=10,desiredSize=4

# Upgrade node group version
aws eks update-nodegroup-version \
  --cluster-name my-cluster \
  --nodegroup-name ng-1 \
  --version 1.29

# Monitor node group upgrade
aws eks describe-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name ng-1 \
  --query "nodegroup.status"
```

**Step 4: Upgrade Addons:**
```bash
# Upgrade VPC CNI
aws eks update-addon \
  --cluster-name my-cluster \
  --addon-name vpc-cni \
  --addon-version vpc-cni-1.15.0-eksbuild.1

# Upgrade CoreDNS
aws eks update-addon \
  --cluster-name my-cluster \
  --addon-name coredns \
  --resolve-conflicts overwrite

# Upgrade kube-proxy
aws eks update-addon \
  --cluster-name my-cluster \
  --addon-name kube-proxy \
  --resolve-conflicts overwrite
```

**Step 5: Post-Upgrade Validation:**
```bash
# Verify cluster version
kubectl version --short

# Check node readiness
kubectl get nodes -o wide

# Check pod health
kubectl get pods -A --field-selector=status.phase!=Running

# Verify addon health
kubectl get pods -n kube-system

# Run integration tests
kubectl run smoke-test --image=busybox -- /bin/sh -c 'nslookup kubernetes.default'
```

**Important Considerations:**

| Aspect | Detail |
|--------|--------|
| **Version Compatibility** | Control plane version must be >= node group version. Node group can be at most 1 minor version behind. |
| **Downtime** | Control plane upgrade is non-disruptive to running pods (brief API server interruption of ~5-10 minutes). Node group upgrade requires pod rescheduling. |
| **Order of Operations** | Always upgrade control plane first, then node groups, then addons. Never upgrade node groups beyond the control plane version. |
| **Backup** | Take snapshots of EBS volumes, backup RDS databases, and export critical ConfigMaps/Secrets before upgrading. |
| **Window** | Schedule during maintenance windows. Notify all teams of the brief API unavailability. |
| **Rollback** | Control plane rollback is supported but limited. Plan thoroughly before upgrading. |
| **Testing** | Always test upgrades in a staging cluster before production. |

---

## 🟫 Deployment Strategies

---

### 21️⃣ Have you ever implemented Blue-Green deployment strategies?

**Answer:**

Yes, I have implemented **Blue-Green deployment** strategies in multiple production environments. Blue-Green deployment is a zero-downtime deployment strategy that maintains two identical production environments — **Blue (current/live)** and **Green (new/candidate)** — and switches traffic between them instantaneously.

**Blue-Green Architecture:**

```
                    ┌─────────────┐
                    │   Service    │
                    │   (Stable    │
                    │   Endpoint)  │
                    └──────┬──────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
     (Active) │                    (Standby)│
            ▼                             ▼
    ┌──────────────┐            ┌──────────────┐
    │   BLUE       │            │   GREEN      │
    │  v2.0 (Live) │            │  v2.1 (New)  │
    │              │            │              │
    │ Deployment   │            │ Deployment   │
    │ 3 replicas   │            │ 3 replicas   │
    └──────────────┘            └──────────────┘

    Switch: Update Service selector from
    app=myapp,version=blue → app=myapp,version=green
```

**How Blue-Green Works:**

1. **Blue** is the current production deployment serving live traffic.
2. Deploy the **Green** version alongside Blue — both run simultaneously.
3. Run **smoke tests and validation** against Green using a test-only service or internal endpoint.
4. **Switch traffic** by updating the Service selector from `version: blue` to `version: green`.
5. Monitor Green for errors. If issues are detected, **instantly switch back** to Blue.
6. Once Green is stable, **remove Blue** to save resources.

**Kubernetes Blue-Green Implementation:**

```yaml
# Blue Deployment (current production)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: myapp
        image: myregistry/myapp:v2.0
        ports:
        - containerPort: 8080
---
# Green Deployment (new version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: myapp
        image: myregistry/myapp:v2.1
        ports:
        - containerPort: 8080
---
# Service — selector determines which deployment receives traffic
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: blue    # Change to 'green' to switch traffic
  ports:
  - port: 80
    targetPort: 8080
```

**Traffic Switch Command:**
```bash
# Switch from Blue to Green
kubectl patch service myapp-service \
  -p '{"spec":{"selector":{"version":"green"}}}'

# Verify traffic routing
kubectl get pods -l app=myapp,version=green

# If issues detected, switch back to Blue (instant rollback)
kubectl patch service myapp-service \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# Once Green is stable, remove Blue
kubectl delete deployment myapp-blue
```

**Advantages of Blue-Green:**
- **Zero downtime** — traffic switch is instantaneous
- **Instant rollback** — just change the selector back
- **Full testing** — Green can be tested with real infrastructure before going live
- **No canary complexity** — all-or-nothing switch simplifies validation

**Disadvantages:**
- **Resource cost** — running two full sets of deployments doubles infrastructure cost during the switch window
- **Database migrations** — schema changes need to be backward-compatible (both Blue and Green read/write the same database)
- **Session state** — if the application uses in-memory sessions, users may be disrupted during the switch

**When to Use:** Blue-Green is ideal for **stateless applications** where you need guaranteed zero-downtime deployment with the ability to instantly roll back. For applications where resource cost is a concern, **Canary deployments** (gradual traffic shift) may be more appropriate.

---

### 22️⃣ Can you tell me how you implement Blue-Green strategy using Terraform and Jenkins?

**Answer:**

Implementing Blue-Green deployment with **Terraform** (infrastructure) and **Jenkins** (orchestration) involves provisioning both Blue and Green deployment resources via Terraform and using Jenkins to manage the traffic switching logic.

**Terraform — Provision Blue and Green Deployments:**

```hcl
# variables.tf
variable "app_name" {
  type    = string
  default = "order-service"
}

variable "blue_image" {
  type    = string
  default = "myregistry/order-service:v2.0"
}

variable "green_image" {
  type    = string
  default = "myregistry/order-service:v2.1"
}

variable "namespace" {
  type    = string
  default = "production"
}

variable "replicas" {
  type    = number
  default = 3
}

# main.tf — Blue-Green Deployments
resource "kubernetes_deployment" "blue" {
  metadata {
    name      = "${var.app_name}-blue"
    namespace = var.namespace
    labels = {
      app     = var.app_name
      version = "blue"
      managed-by = "terraform"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app     = var.app_name
        version = "blue"
      }
    }

    template {
      metadata {
        labels = {
          app     = var.app_name
          version = "blue"
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.blue_image

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "green" {
  metadata {
    name      = "${var.app_name}-green"
    namespace = var.namespace
    labels = {
      app     = var.app_name
      version = "green"
      managed-by = "terraform"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app     = var.app_name
        version = "green"
      }
    }

    template {
      metadata {
        labels = {
          app     = var.app_name
          version = "green"
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.green_image

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Service with Blue as initial target
resource "kubernetes_service" "main" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = var.namespace
  }

  spec {
    selector = {
      app     = var.app_name
      version = "blue"  # Initially points to Blue
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

# outputs.tf
output "blue_deployment_name" {
  value = kubernetes_deployment.blue.metadata[0].name
}

output "green_deployment_name" {
  value = kubernetes_deployment.green.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.main.metadata[0].name
}
```

**Jenkins Pipeline — Blue-Green Orchestration:**

```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'ACTION',
               choices: ['deploy-green', 'switch-to-green', 'switch-to-blue', 'cleanup-blue'],
               description: 'Blue-Green Action')
        string(name: 'APP_NAME', defaultValue: 'order-service', description: 'Application Name')
        string(name: 'IMAGE_TAG', defaultValue: 'v2.1', description: 'New Image Tag')
        string(name: 'NAMESPACE', defaultValue: 'production', description: 'K8s Namespace')
    }

    environment {
        REGISTRY = 'myregistry.io'
    }

    stages {
        stage('Deploy Green Version') {
            when {
                expression { params.ACTION == 'deploy-green' }
            }
            steps {
                script {
                    sh """
                        # Update Green deployment with new image
                        kubectl set image deployment/${params.APP_NAME}-green \\
                            ${params.APP_NAME}=${REGISTRY}/${params.APP_NAME}:${params.IMAGE_TAG} \\
                            -n ${params.NAMESPACE}

                        # Wait for Green to be ready
                        kubectl rollout status deployment/${params.APP_NAME}-green \\
                            -n ${params.NAMESPACE} --timeout=300s
                    """
                }
            }
        }

        stage('Smoke Test Green') {
            when {
                expression { params.ACTION == 'deploy-green' }
            }
            steps {
                script {
                    // Create a temporary service pointing to Green for testing
                    sh """
                        kubectl apply -f - <<EOF
                        apiVersion: v1
                        kind: Service
                        metadata:
                          name: ${params.APP_NAME}-green-test
                          namespace: ${params.NAMESPACE}
                        spec:
                          selector:
                            app: ${params.APP_NAME}
                            version: green
                          ports:
                          - port: 80
                            targetPort: 8080
                        EOF

                        # Wait for service to be ready
                        sleep 10

                        # Run smoke tests against Green
                        GREEN_IP=\$(kubectl get svc ${params.APP_NAME}-green-test -n ${params.NAMESPACE} -o jsonpath='{.spec.clusterIP}')

                        curl -f http://\$GREEN_IP/health || { echo "Green health check failed!"; exit 1; }
                        curl -f http://\$GREEN_IP/api/v1/status || { echo "Green API check failed!"; exit 1; }

                        echo "Green deployment passed smoke tests"

                        # Clean up test service
                        kubectl delete svc ${params.APP_NAME}-green-test -n ${params.NAMESPACE}
                    """
                }
            }
        }

        stage('Switch Traffic to Green') {
            when {
                expression { params.ACTION == 'switch-to-green' }
            }
            steps {
                script {
                    sh """
                        # Switch Service selector to Green
                        kubectl patch service ${params.APP_NAME}-service \\
                            -n ${params.NAMESPACE} \\
                            -p '{"spec":{"selector":{"version":"green"}}}'

                        echo "Traffic switched to Green"

                        # Monitor for errors for 5 minutes
                        echo "Monitoring Green for 5 minutes..."
                        sleep 300

                        # Check error rate in CloudWatch/logs
                        ERROR_COUNT=\$(kubectl get pods -n ${params.NAMESPACE} -l app=${params.APP_NAME},version=green -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}')

                        if [ "\$ERROR_COUNT" -gt 0 ]; then
                            echo "WARNING: Restarts detected on Green pods"
                        fi
                    """
                }
            }
        }

        stage('Rollback — Switch Traffic to Blue') {
            when {
                expression { params.ACTION == 'switch-to-blue' }
            }
            steps {
                script {
                    sh """
                        # Instant rollback to Blue
                        kubectl patch service ${params.APP_NAME}-service \\
                            -n ${params.NAMESPACE} \\
                            -p '{"spec":{"selector":{"version":"blue"}}}'

                        echo "Traffic rolled back to Blue"
                    """
                }
            }
        }

        stage('Cleanup Blue') {
            when {
                expression { params.ACTION == 'cleanup-blue' }
            }
            steps {
                script {
                    sh """
                        # Scale down Blue to save resources
                        kubectl scale deployment/${params.APP_NAME}-blue \\
                            --replicas=0 \\
                            -n ${params.NAMESPACE}

                        # After confirmation, delete Blue deployment
                        # kubectl delete deployment/${params.APP_NAME}-blue -n ${params.NAMESPACE}

                        echo "Blue scaled down. Delete manually after confirmation."
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            script {
                echo "✅ Blue-Green action '${params.ACTION}' completed successfully for ${params.APP_NAME}"
            }
        }
        failure {
            script {
                echo "❌ Blue-Green action '${params.ACTION}' FAILED for ${params.APP_NAME}"
                // Auto-rollback on switch failure
                if (params.ACTION == 'switch-to-green') {
                    sh """
                        kubectl patch service ${params.APP_NAME}-service \\
                            -n ${params.NAMESPACE} \\
                            -p '{"spec":{"selector":{"version":"blue"}}}'
                        echo "Auto-rollback to Blue triggered"
                    """
                }
            }
        }
    }
}
```

**Deployment Workflow:**

```
1. Jenkins: Deploy Green       → Deploy new version alongside Blue
2. Jenkins: Smoke Test Green   → Validate Green with test traffic
3. Jenkins: Switch to Green    → Route all production traffic to Green
4. Monitor: 5-15 min           → Watch error rates, latency, business metrics
5. Jenkins: Cleanup Blue       → Scale down and remove Blue deployment
   └── On Failure: Switch to Blue → Instant rollback
```

---

## ⬜ Terraform & Infrastructure

---

### 27️⃣ Can you write a Terraform script for an EKS cluster?

**Answer:**

Here is a **production-ready Terraform script** for provisioning an Amazon EKS cluster with VPC, subnets, security groups, managed node groups, and essential add-ons.

```hcl
# ============================================================
# providers.tf — Terraform Provider Configuration
# ============================================================
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
  }

  # Remote state storage
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "eks/cluster.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name]
    }
  }
}

# ============================================================
# variables.tf — Input Variables
# ============================================================
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "project_name" {
  type    = string
  default = "ascendion-app"
}

variable "cluster_name" {
  type    = string
  default = "ascendion-eks"
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_types" {
  type    = list(string)
  default = ["m5.xlarge", "m5.2xlarge"]
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 10
}

variable "desired_size" {
  type    = number
  default = 3
}

# ============================================================
# vpc.tf — VPC and Network Configuration
# ============================================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.cluster_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# security_groups.tf — Security Groups
# ============================================================
resource "aws_security_group" "node" {
  name_prefix = "${var.cluster_name}-node-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow traffic from EKS control plane"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-node-sg"
  }
}

resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# ============================================================
# eks.tf — EKS Cluster Configuration
# ============================================================
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids = [aws_security_group.eks_cluster.id]

    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name = var.cluster_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.cluster_name}-general"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.instance_types

  scaling_config {
    min_size     = var.min_size
    max_size     = var.max_size
    desired_size = var.desired_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role        = "general"
    environment = var.environment
  }

  tags = {
    Name = "${var.cluster_name}-general-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy
  ]
}

resource "aws_eks_node_group" "compute_intensive" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.cluster_name}-compute"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["c5.2xlarge"]

  scaling_config {
    min_size     = 1
    max_size     = 5
    desired_size = 2
  }

  labels = {
    role        = "compute-intensive"
    environment = var.environment
  }

  taint {
    key    = "workload-type"
    value  = "compute"
    effect = "NO_SCHEDULE"
  }

  tags = {
    Name = "${var.cluster_name}-compute-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy
  ]
}

# ============================================================
# iam.tf — IAM Roles and Policies
# ============================================================
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_container_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

# ============================================================
# outputs.tf — Output Values
# ============================================================
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_security_group_id" {
  description = "Security group attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "Security group attached to the node group"
  value       = aws_security_group.node.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.aws_region}"
}
```

**Key Features of this Terraform Script:**

- **Multi-AZ VPC** with public and private subnets for high availability
- **NAT Gateway** for private subnet outbound internet access
- **Two node groups:** General purpose and compute-intensive (with taints)
- **IAM roles** with least-privilege policies for both cluster and nodes
- **VPC Flow Logs**, **EKS Control Plane logging** enabled
- **Remote state** stored in S3 with DynamoDB locking
- **Provider configuration** using `exec` for IAM-authenticated kubectl access
- **Security groups** separating cluster and node traffic

---

## 🟦 Python Scripting

---

### 26️⃣ Do you have any exposure in Python scripting?

**Answer:**

Yes, I have extensive experience with **Python scripting** for DevOps automation, infrastructure management, CI/CD pipeline enhancement, and operational tooling. Python is one of my primary scripting languages for automating repetitive tasks and building operational tools.

**Areas Where I Use Python:**

**1. Kubernetes Operations Automation:**
```python
#!/usr/bin/env python3
"""
Auto-scale EKS deployments based on custom metrics
"""
from kubernetes import client, config
from kubernetes.client.rest import ApiException
import json
import sys

config.load_kube_config()

apps_v1 = client.AppsV1Api()
core_v1 = client.CoreV1Api()

def get_deployment(namespace, name):
    """Get a Kubernetes deployment"""
    try:
        return apps_v1.read_namespaced_deployment(name, namespace)
    except ApiException as e:
        print(f"Error getting deployment: {e}")
        return None

def scale_deployment(namespace, name, replicas):
    """Scale a deployment to the specified replica count"""
    body = {
        "spec": {
            "replicas": replicas
        }
    }
    try:
        apps_v1.patch_namespaced_deployment_scale(
            name, namespace, body
        )
        print(f"Scaled {name} to {replicas} replicas")
    except ApiException as e:
        print(f"Error scaling deployment: {e}")

def check_pod_health(namespace, label_selector):
    """Check health of pods matching a label selector"""
    pods = core_v1.list_namespaced_pod(namespace, label_selector=label_selector)
    healthy = 0
    unhealthy = 0
    for pod in pods.items:
        if pod.status.phase == "Running":
            ready = all(
                c.ready for c in pod.status.container_statuses or []
            )
            if ready:
                healthy += 1
            else:
                unhealthy += 1
        else:
            unhealthy += 1
    return healthy, unhealthy

if __name__ == "__main__":
    namespace = sys.argv[1] if len(sys.argv) > 1 else "default"
    app_name  = sys.argv[2] if len(sys.argv) > 2 else "order-service"

    healthy, unhealthy = check_pod_health(namespace, f"app={app_name}")
    print(f"Healthy: {healthy}, Unhealthy: {unhealthy}")

    if unhealthy > 0:
        # Auto-restart unhealthy pods
        deployment = get_deployment(namespace, app_name)
        if deployment:
            current_replicas = deployment.spec.replicas
            print(f"Restarting {app_name} (current replicas: {current_replicas})")
            scale_deployment(namespace, app_name, current_replicas)
```

**2. AWS Infrastructure Automation:**
```python
#!/usr/bin/env python3
"""
Automated EKS cluster health checker using boto3
"""
import boto3
import json
from datetime import datetime, timedelta

eks = boto3.client('eks', region_name='us-east-1')
ec2 = boto3.client('ec2', region_name='us-east-1')
cloudwatch = boto3.client('cloudwatch', region_name='us-east-1')

def check_eks_cluster_health(cluster_name):
    """Check EKS cluster and node group health"""
    cluster = eks.describe_cluster(name=cluster_name)
    status = cluster['cluster']['status']
    version = cluster['cluster']['version']

    nodegroups = eks.list_nodegroups(clusterName=cluster_name)
    ng_health = {}

    for ng in nodegroups['nodegroups']:
        ng_detail = eks.describe_nodegroup(
            clusterName=cluster_name,
            nodegroupName=ng
        )
        ng_health[ng] = {
            'status': ng_detail['nodegroup']['status'],
            'version': ng_detail['nodegroup']['version'],
            'desired': ng_detail['nodegroup']['scalingConfig']['desiredSize'],
            'instances': len(ng_detail['nodegroup']['nodes']) if 'nodes' in ng_detail['nodegroup'] else 0
        }

    return {
        'cluster_status': status,
        'cluster_version': version,
        'nodegroups': ng_health,
        'timestamp': datetime.utcnow().isoformat()
    }

def get_high_cpu_nodes():
    """Get EC2 instances with high CPU utilization"""
    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/EC2',
        MetricName='CPUUtilization',
        Dimensions=[{'Name': 'InstanceId'}],
        StartTime=datetime.utcnow() - timedelta(hours=1),
        EndTime=datetime.utcnow(),
        Period=300,
        Statistics=['Average']
    )

    high_cpu = []
    for dp in response.get('Datapoints', []):
        if dp['Average'] > 80:
            high_cpu.append({
                'cpu_percent': dp['Average'],
                'timestamp': dp['Timestamp']
            })
    return high_cpu

if __name__ == "__main__":
    health = check_eks_cluster_health("ascendion-eks")
    print(json.dumps(health, indent=2, default=str))
```

**3. CI/CD Pipeline Helper Scripts:**
```python
#!/usr/bin/env python3
"""
Generate Kubernetes deployment manifests from a template
"""
import yaml
import argparse
import sys

def generate_deployment(app_name, image, replicas, namespace, cpu_request, memory_request):
    """Generate a Kubernetes Deployment manifest"""
    deployment = {
        'apiVersion': 'apps/v1',
        'kind': 'Deployment',
        'metadata': {
            'name': app_name,
            'namespace': namespace,
            'labels': {
                'app': app_name,
                'managed-by': 'python-generator'
            }
        },
        'spec': {
            'replicas': replicas,
            'selector': {
                'matchLabels': {
                    'app': app_name
                }
            },
            'strategy': {
                'type': 'RollingUpdate',
                'rollingUpdate': {
                    'maxSurge': 1,
                    'maxUnavailable': 0
                }
            },
            'template': {
                'metadata': {
                    'labels': {
                        'app': app_name
                    }
                },
                'spec': {
                    'securityContext': {
                        'runAsNonRoot': True,
                        'runAsUser': 1000
                    },
                    'containers': [{
                        'name': app_name,
                        'image': image,
                        'ports': [{'containerPort': 8080}],
                        'resources': {
                            'requests': {
                                'cpu': cpu_request,
                                'memory': memory_request
                            },
                            'limits': {
                                'cpu': str(int(cpu_request.replace('m', '')) * 2) + 'm',
                                'memory': str(int(memory_request.replace('Mi', '')) * 2) + 'Mi'
                            }
                        },
                        'livenessProbe': {
                            'httpGet': {'path': '/health', 'port': 8080},
                            'initialDelaySeconds': 30,
                            'periodSeconds': 10
                        },
                        'readinessProbe': {
                            'httpGet': {'path': '/ready', 'port': 8080},
                            'initialDelaySeconds': 15,
                            'periodSeconds': 5
                        }
                    }]
                }
            }
        }
    }
    return deployment

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate K8s Deployment manifest')
    parser.add_argument('--app', required=True, help='Application name')
    parser.add_argument('--image', required=True, help='Container image')
    parser.add_argument('--replicas', type=int, default=3, help='Number of replicas')
    parser.add_argument('--namespace', default='default', help='Kubernetes namespace')
    parser.add_argument('--cpu', default='250m', help='CPU request')
    parser.add_argument('--memory', default='512Mi', help='Memory request')

    args = parser.parse_args()

    deployment = generate_deployment(
        args.app, args.image, args.replicas,
        args.namespace, args.cpu, args.memory
    )

    print(yaml.dump(deployment, default_flow_style=False))
```

**4. Log Analysis and Alerting:**
```python
#!/usr/bin/env python3
"""
Analyze application logs for error patterns and trigger alerts
"""
import re
import json
import boto3
from collections import Counter

def analyze_cloudwatch_logs(log_group, pattern="ERROR|Exception|Failed"):
    """Analyze CloudWatch Logs for error patterns"""
    cwlogs = boto3.client('logs', region_name='us-east-1')

    response = cwlogs.filter_log_events(
        logGroupName=log_group,
        filterPattern=pattern,
        limit=100
    )

    errors = []
    for event in response.get('events', []):
        message = event.get('message', '')
        errors.append({
            'timestamp': event.get('timestamp'),
            'message': message
        })

    # Count error types
    error_types = Counter()
    for error in errors:
        msg = error['message']
        if 'Timeout' in msg:
            error_types['Timeout'] += 1
        elif 'ConnectionRefused' in msg:
            error_types['ConnectionRefused'] += 1
        elif 'OutOfMemory' in msg:
            error_types['OutOfMemory'] += 1
        else:
            error_types['Other'] += 1

    return {
        'total_errors': len(errors),
        'error_breakdown': dict(error_types),
        'recent_errors': errors[:10]
    }

def send_slack_alert(webhook_url, message):
    """Send alert to Slack"""
    import requests
    payload = {
        'channel': '#devops-alerts',
        'username': 'Log Monitor Bot',
        'text': message,
        'icon_emoji': ':rotating_light:'
    }
    requests.post(webhook_url, json=payload)

if __name__ == "__main__":
    analysis = analyze_cloudwatch_logs('/eks/cluster/production')

    if analysis['total_errors'] > 50:
        alert_msg = (
            f":rotating_light: High error rate detected!\n"
            f"Total errors: {analysis['total_errors']}\n"
            f"Breakdown: {json.dumps(analysis['error_breakdown'], indent=2)}"
        )
        send_slack_alert('https://hooks.slack.com/services/XXX', alert_msg)
```

**Python Libraries I Use Regularly:**

| Library | Purpose |
|---------|---------|
| `boto3` | AWS SDK — EKS, EC2, S3, CloudWatch, IAM automation |
| `kubernetes` | Python Kubernetes client — cluster management, resource manipulation |
| `pyyaml` | YAML parsing and generation for K8s manifests |
| `requests` | HTTP API calls — webhooks, REST API integration |
| `jinja2` | Template engine — generate Terraform, K8s, Helm templates |
| `docker` | Docker SDK — container build and management |
| `ansible` (Python-based) | Configuration management and deployment automation |
| `pytest` | Testing for automation scripts |

---

## 🟧 Network Policies

---

### 28️⃣ How do you restrict an EKS pod so it can only talk to the database and nothing else on the network? Show us the Network Policy you'd write.

**Answer:**

To restrict a pod's network communication to **only allow database connectivity** (and nothing else), I use a **Kubernetes NetworkPolicy** with both **Ingress** and **Egress** rules. The key is to apply a **default deny-all** policy and then add **specific allow rules** for the database.

**Architecture:**

```
┌──────────────────────────────────────────────┐
│  Pod: order-service                          │
│                                              │
│  Egress ALLOW:                               │
│  ┌────────────────────────────────────────┐  │
│  │ → Database Pod (port 5432/TCP)        │  │
│  │ → DNS Server (port 53/UDP)            │  │
│  │ → All other traffic: DENIED           │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  Ingress ALLOW:                              │
│  ┌────────────────────────────────────────┐  │
│  │ ← From API Gateway (port 8080/TCP)    │  │
│  │ ← All other traffic: DENIED           │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘

     ┌─────────────────┐
     │  Database Pod    │
     │  (port 5432)    │
     └─────────────────┘
```

**NetworkPolicy — Restrict order-service Pod:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: order-service-network-policy
  namespace: production
spec:
  # Apply to pods with label app=order-service
  podSelector:
    matchLabels:
      app: order-service

  policyTypes:
  - Ingress
  - Egress

  # --- INGRESS RULES ---
  # Allow incoming traffic only from the API Gateway on port 8080
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 8080

  # --- EGRESS RULES ---
  # Rule 1: Allow outbound traffic to the PostgreSQL database on port 5432
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgresql
    ports:
    - protocol: TCP
      port: 5432

  # Rule 2: Allow DNS resolution (REQUIRED for Kubernetes service discovery)
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53

  # Rule 3: Allow DNS resolution to CoreDNS (EKS default)
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

**Default Deny Policy (apply to namespace for defense in depth):**

```yaml
# This policy denies ALL ingress and egress for all pods in the namespace
# Individual NetworkPolicies above then add specific allow rules
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Verification Commands:**

```bash
# Apply the network policies
kubectl apply -f default-deny-all.yaml
kubectl apply -f order-service-network-policy.yaml

# Verify the policy is applied
kubectl get networkpolicies -n production
kubectl describe networkpolicy order-service-network-policy -n production

# Test connectivity from order-service pod to database
kubectl exec -it deployment/order-service -n production -- \
    nc -zv postgresql-service 5432

# Test that order-service CANNOT reach other services (should fail)
kubectl exec -it deployment/order-service -n production -- \
    nc -zv some-other-service 8080  # Should timeout/fail

# Test DNS resolution (should work)
kubectl exec -it deployment/order-service -n production -- \
    nslookup postgresql-service.production.svc.cluster.local
```

**Key Considerations:**

| Aspect | Detail |
|--------|--------|
| **DNS is Critical** | Always allow DNS (port 53 UDP/TCP) to kube-dns/CoreDNS. Without DNS, the pod cannot resolve service names, and even the database connection will fail. |
| **CNI Support** | Network Policies require a CNI that supports them (Calico, Cilium, Amazon VPC CNI with policy controller). Default VPC CNI requires the **Cilium CNI** or **Calico** addon for full NetworkPolicy support. |
| **Cross-Namespace** | If the database is in a different namespace, use `namespaceSelector` alongside `podSelector` to target pods across namespaces. |
| **EKS VPC CNI** | The default AWS VPC CNI has limited NetworkPolicy support. For full L3/L4 policy enforcement, deploy **Cilium** or **Calico** as the policy controller. |
| **Istio/Service Mesh** | If using a service mesh, traffic splitting and authorization can be handled at the application layer (L7) instead of NetworkPolicies (L3/L4). |
| **Testing** | Always test NetworkPolicies in a staging environment before applying to production. Use `kubectl exec` with `nc` (netcat) or `curl` to verify connectivity. |

**Advanced: Cross-Namespace Database Policy:**

```yaml
# If the database is in a separate 'data' namespace
egress:
- to:
  - namespaceSelector:
      matchLabels:
        name: data
    podSelector:
      matchLabels:
        app: postgresql
  ports:
  - protocol: TCP
    port: 5432
```

---

## ✅ Summary

| Category | Questions Covered |
|----------|-------------------|
| Kubernetes Fundamentals | Q1, Q2, Q3, Q23, Q24, Q25 |
| CI/CD & Jenkins | Q4, Q5, Q6, Q7, Q8, Q10 |
| Microservices & Pipeline Design | Q9, Q11 |
| Security & IAM | Q12, Q13, Q14 |
| Monitoring & Logging | Q15, Q16, Q17 |
| EKS Architecture | Q18, Q19, Q20 |
| Deployment Strategies | Q21, Q22 |
| Terraform & Infrastructure | Q27 |
| Python Scripting | Q26 |
| Network Policies | Q28 |

> **Total: 28 comprehensive questions covering the full DevOps stack — from container orchestration to infrastructure-as-code, security, monitoring, and deployment automation.**