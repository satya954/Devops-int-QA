
---
## How do you design an end-to-end CI/CD pipeline?

A production-grade CI/CD pipeline automates the entire journey from **code commit** to **production deployment** with quality gates at each stage:

**Pipeline Stages:**

1. **Source:** Developer pushes code or creates a pull request → triggers the pipeline via webhook.
2. **Checkout:** Pipeline clones the repository and checks out the specific commit.
3. **Pre-Build (Static Analysis):**
   - Linting (ESLint, Checkstyle, Pylint)
   - SAST scanning (SonarQube, Semgrep) for code vulnerabilities
   - Secret detection (GitLeaks, TruffleHog)
4. **Build:** Compile the application, resolve dependencies, and create build artifacts.
5. **Unit Tests:** Run unit tests with code coverage reporting (target: 80%+ coverage).
6. **Container Build:** Build a Docker image from the build artifact using a multi-stage Dockerfile.
7. **Security Scanning:**
   - Container image scan (Trivy, Clair) for CVEs
   - Dependency vulnerability scan (OWASP Dependency-Check, Snyk)
8. **Publish:** Push the Docker image to the container registry (ECR, ACR, GCR) and store build artifacts in Nexus/Artifactory.
9. **Deploy to Staging:** Deploy the application to a staging Kubernetes cluster using `kubectl` or Helm.
10. **Integration Tests:** Run API and end-to-end tests against the staging environment.
11. **Manual Approval:** QA sign-off gate for production deployment.
12. **Deploy to Production:** Execute a **blue-green** or **canary** deployment to minimize risk.
13. **Post-Deploy Verification:** Run smoke tests and verify health endpoints.
14. **Monitoring & Alerting:** Monitor application metrics and set up alerts for any degradation.

**Key Principles:**
- **Immutable artifacts:** Build once, promote the same artifact through all environments.
- **Fail-fast:** Surface failures within 5–10 minutes.
- **Rollback capability:** Every deployment has an automated rollback path.

---

## How do you store and manage credentials in Jenkins?

Credentials are managed using **Jenkins Credentials Plugin** integrated with external secret management systems:

- **Jenkins Built-in Credentials Store:** Store usernames, passwords, secret texts, SSH keys, and certificates in Jenkins' encrypted credential store. Reference them in pipelines using `${CREDENTIAL_ID}`.
- **AWS Secrets Manager / SSM Parameter Store:** For AWS-based deployments, use the **HashiCorp Vault Plugin** or **AWS Secrets Manager Plugin** to fetch secrets at runtime.
- **HashiCorp Vault:** Integrate Jenkins with Vault using the **Vault Plugin**. Jenkins authenticates to Vault via AppRole or Kubernetes authentication, and secrets are injected as environment variables into pipeline steps.
- **Kubernetes Secrets (for EKS):** Use **IRSA (IAM Roles for Service Accounts)** so that the Jenkins agent pod assumes an IAM role with permissions to access AWS Secrets Manager.
- **OIDC Federation:** For cloud logins (AWS CLI, `az login`), use OIDC federation to obtain short-lived tokens instead of storing long-lived credentials.

```groovy
pipeline {
    agent any
    environment {
        DB_PASSWORD = credentials('db-password-from-vault')
        AWS_CREDENTIALS = credentials('aws-credentials-id')
    }
    stages {
        stage('Deploy') {
            steps {
                sh 'echo $DB_PASSWORD'  # Masked in console output
            }
        }
    }
}
```

**Best Practices:**
- **Never hardcode** credentials in Jenkinsfiles or shared libraries.
- Use **binding steps** (`withCredentials`) to limit secret exposure to specific stages.
- Enable **audit logging** to track who accessed which credentials.
- **Rotate credentials** on a regular schedule.

---

## How do you troubleshoot a failed Jenkins pipeline?

I follow a systematic approach:

**Step 1 — Check the Console Output:**
- Navigate to the failed build → **Console Output** to identify the stage and step that failed.
- Look for **error messages, stack traces, and exit codes**.

**Step 2 — Identify the Failure Type:**
- **Build Failure:** Compilation errors, missing dependencies, or incorrect build commands.
- **Test Failure:** Failing unit/integration tests — review test output for assertions that failed.
- **Deployment Failure:** Kubernetes errors (`CrashLoopBackOff`, `ImagePullBackOff`), permission denied, or connectivity issues.
- **Plugin/Agent Failure:** Jenkins agent went offline, plugin version incompatibility, or workspace issues.

**Step 3 — Check Agent Logs:**
```bash
# If using Kubernetes agent pods
kubectl logs jenkins-agent-<pod-name> -n jenkins
# Check if the agent pod crashed or ran out of resources
```

**Step 4 — Review Environment and Credentials:**
- Verify that environment variables and credentials are correctly bound.
- Check for expired certificates, rotated API keys, or revoked IAM roles.

**Step 5 — Test the Failing Step Manually:**
- SSH into the Jenkins agent and run the failing command manually to reproduce the issue.

**Step 6 — Check Resource Constraints:**
- Verify that the Jenkins agent has sufficient **CPU, memory, and disk space**.
- Check for **OOMKilled** events on agent pods.

**Step 7 — Review Recent Changes:**
- Check if the failure correlates with a recent code change, plugin update, or infrastructure modification.
- Use the **Pipeline Graph** to compare the failed run with the last successful run.

---

## What is the difference between Freestyle and Pipeline jobs?

| Aspect | Freestyle Job | Pipeline Job |
|--------|--------------|--------------|
| **Definition** | Configured through Jenkins **web UI** (forms, dropdowns) | Defined as **code** in a `Jenkinsfile` (stored in version control) |
| **Version Control** | Not version-controlled; configuration is stored in Jenkins server | Fully version-controlled; changes are tracked via Git |
| **Complexity** | Limited to simple, linear builds | Supports complex workflows — parallel stages, conditional logic, loops, error handling |
| **Reusability** | Hard to reuse; must be manually duplicated | Reusable via **Shared Libraries** and **Pipeline Templates** |
| **Visualization** | No visual representation | **Blue Ocean** or **Pipeline Graph** provides a visual stage view |
| **Scalability** | Not suitable for large, multi-stage projects | Designed for multi-stage, multi-branch CI/CD |
| **Agent Support** | Runs on a single assigned node | Can distribute stages across different agents/labels |
| **Maintenance** | Configuration drift over time; no audit trail | Infrastructure-as-Code approach; easy to review, audit, and migrate |

**Recommendation:** Use **Pipeline jobs** for all new projects. Freestyle jobs should only be used for simple, one-off tasks or legacy systems.

---

## How do you implement approval before production deployment?

In a Jenkins Declarative Pipeline, use the **`input`** step to pause execution and require manual approval:

```groovy
pipeline {
    agent any
    stages {
        stage('Deploy to Staging') {
            steps {
                sh 'kubectl apply -f k8s/ -n staging'
                sh 'sleep 60 && curl -f http://staging-app/health'
            }
        }

        stage('Approve Production Deployment') {
            steps {
                input message: 'Deploy to production?',
                      ok: 'Deploy',
                      submitter: 'release-managers'
            }
        }

        stage('Deploy to Production') {
            steps {
                sh 'kubectl apply -f k8s/ -n production'
                sh 'kubectl rollout status deployment/myapp -n production --timeout=300s'
            }
        }
    }
}
```

**Additional Controls:**
- **`submitter` field:** Restrict approval to specific users or groups (e.g., `release-managers`).
- **`submitterParameter`:** Capture who approved the deployment for audit trails.
- **Jenkins Environments/RBAC:** Use Role-Based Access Control so that only authorized users can approve production deployments.
- **Timeout:** Set a timeout for the approval step to prevent pipelines from hanging indefinitely.

---

## How do you integrate SonarQube and Trivy into Jenkins?

**SonarQube Integration (Code Quality & SAST):**

```groovy
pipeline {
    agent any
    tools {
        maven 'Maven-3.9'
        jdk 'Java-17'
    }
    stages {
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh 'mvn sonar:sonar ' +
                       '-Dsonar.projectKey=myapp ' +
                       '-Dsonar.sources=src/ ' +
                       '-Dsonar.tests=test/'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        def qualityGate = waitForQualityGate()
                        if (qualityGate.status != 'OK') {
                            error "SonarQube Quality Gate failed: ${qualityGate.status}"
                        }
                    }
                }
            }
        }
    }
}
```

**Trivy Integration (Container Vulnerability Scanning):**

```groovy
pipeline {
    agent any
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t myapp:${BUILD_NUMBER} .'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    trivy image --exit-code 0 --severity HIGH,CRITICAL \
                                --format table \
                                myapp:${BUILD_NUMBER} > trivy-report.txt
                '''
                sh '''
                    trivy image --exit-code 1 --severity CRITICAL \
                                --format json \
                                --output trivy-results.json \
                                myapp:${BUILD_NUMBER}
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.txt, trivy-results.json'
                }
            }
        }

        stage('Push to Registry') {
            when {
                expression {
                    // Only push if no CRITICAL vulnerabilities found
                    !fileExists('trivy-results.json') ||
                    readJSON(file: 'trivy-results.json').Results.size() == 0
                }
            }
            steps {
                sh 'docker push myregistry.com/myapp:${BUILD_NUMBER}'
            }
        }
    }
}
```

**Setup Requirements:**
- Install **SonarQube Scanner** and **Trivy** on Jenkins agents (or install them within the pipeline using a setup step).
- Configure **SonarQube Server** connection in Jenkins Global Tool Configuration and add the SonarQube authentication token in Jenkins Credentials.
- Use **`--exit-code 1`** in Trivy to fail the pipeline when critical vulnerabilities are found, and **`--exit-code 0`** for informational scans.
