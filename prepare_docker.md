# Docker Interview Preparation

---

## ENTRYPOINT vs CMD

**ENTRYPOINT** defines the main executable of the container, while **CMD** provides default arguments to that executable. At runtime, arguments passed to `docker run` replace CMD but are **appended** to ENTRYPOINT.

| Aspect | ENTRYPOINT | CMD |
|--------|-----------|-----|
| **Purpose** | Sets the main command | Sets default arguments |
| **Override behavior** | Requires `--entrypoint` flag to override | Replaced by runtime arguments |
| **Combined use** | ENTRYPOINT + CMD = executable + default args | CMD alone can be overridden entirely |

---

## Example Dockerfile (Multi-Stage Build)

```dockerfile
FROM node:20 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=build /app/package.json ./
COPY --from=build /app/package-lock.json ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist
CMD ["npm", "run", "start-production"]
# Alternatively:
# CMD ["node", "dist/server.js"]
```

---

## How do you implement `runAsNonRoot` with Pod Security Standards without breaking legacy containers?

I use a **gradual, layered approach** to enforce `runAsNonRoot` without disrupting existing workloads:

- **Pod Security Admission (PSA):** Apply the **`baseline`** profile at the namespace level as a default, which does not block `runAsNonRoot` violations. Use the **`restricted`** profile as an `audit` or `warn` level initially, so that violations are logged or warned about but not rejected.
- **Default Security Context:** Set `runAsNonRoot: true` at the **namespace or deployment template level**, so new pods inherit it automatically.
- **Legacy Container Handling:** For legacy containers that run as root, I either:
  - Modify the Dockerfile to add a non-root user (`USER appuser`) and rebuild the image.
  - Use an **init container** to fix file permissions before the main container starts.
  - Apply a **Pod Security Admission exception** (using a `priority` label) for specific namespaces, and work with the application team to remediate over time.
- **DefaultAdmissionController:** Configure a default security context at the cluster level using an admission controller (e.g., **OPA Gatekeeper** or **Kyverno**) to inject `runAsNonRoot: true` into pods that do not specify it.

---

## Suppose you have a container which was built long ago, and you don't have the Dockerfile for it. How do you rebuild it by making some changes? Can you get the Dockerfile from it?

You cannot directly extract the original Dockerfile from a built image, but you can **reconstruct** it using the following tools and techniques:

- **`docker history`**: Shows the layered commands that were executed during the build:
  ```bash
  docker history --no-trunc <image_name>:<tag>
  ```
  This outputs the commands and the size of each layer, giving you a starting point to reconstruct the Dockerfile.
- **`dockerfile-parser` or `dfimage`**: Third-party tools that attempt to reverse-engineer a Dockerfile from an image:
  ```bash
  npx dfimage <image_name>:<tag>
  ```
- **`docker inspect`**: Provides metadata about the image, including environment variables, entrypoint, and exposed ports:
  ```bash
  docker inspect <image_name>:<tag>
  ```
- **Dive or `docker diff`**: Inspect the filesystem changes in each layer to understand what packages or files were added.

Once you have a reconstructed Dockerfile, you can modify it, add the required changes, and rebuild the image.

---

## What is the difference between an image and a container?

An **image** is a **read-only template** built from a Dockerfile. It contains the application code, runtime, system tools, libraries, and dependencies required to run an application. Images are immutable and are stored in a registry (Docker Hub, ECR, GCR).

A **container** is a **running instance** of an image. When you execute `docker run`, Docker creates a writable layer on top of the read-only image layers and starts the process defined by the image's ENTRYPOINT or CMD. Containers are ephemeral — they can be started, stopped, and deleted, but the underlying image remains unchanged.

| Aspect | Image | Container |
|--------|-------|-----------|
| **State** | Read-only, immutable | Runnable, has a writable layer |
| **Analogy** | Class (blueprint) | Object (instance) |
| **Storage** | Registry (ECR, Docker Hub) | Local Docker host |
| **Lifecycle** | Built once, reused many times | Created, started, stopped, removed |

---

## How do you troubleshoot a container that keeps restarting?

I follow a systematic approach:

**Step 1 — Check container status and exit code:**
```bash
docker ps -a | grep <container_name>
docker inspect <container_name> | jq '.[0].State'
```

**Step 2 — Review container logs:**
```bash
docker logs <container_name> --tail 100 -t
```

**Step 3 — Identify common causes based on exit code:**

| Exit Code | Meaning | Troubleshooting |
|-----------|---------|-----------------|
| 0 | Normal exit | Container may be designed to exit; check if it should be long-running |
| 1 | Application error | Check application logs for exceptions, missing config, or connection failures |
| 126 | Permission denied | Ensure entrypoint has execute permissions (`chmod +x`) |
| 127 | Command not found | Verify the ENTRYPOINT/CMD binary exists in the image |
| 137 | OOM Killed | Increase memory limits; check for memory leaks |
| 139 | Segmentation fault | Application crash; check binary compatibility or native libraries |

**Step 4 — Check for OOM kills:**
```bash
docker inspect <container_name> | jq '.[0].State.OOMKilled'
dmesg -T | grep -i 'oom\|killed'
```

**Step 5 — Run interactively to reproduce the issue:**
```bash
docker run -it --entrypoint /bin/sh <image_name>
# Manually test the entrypoint command inside the container
```

**Step 6 — Verify environment variables and mounted volumes:**
```bash
docker run --rm <image_name> env
# Check if required config files are mounted correctly
```

---

## How do you optimize a Dockerfile?

I apply the following optimization techniques:

- **Use multi-stage builds:** Keep build tools, compilers, and source code out of the final image. Only copy the compiled artifacts to a minimal runtime image.
- **Choose minimal base images:** Use `alpine`, `distroless`, or `slim` variants instead of full OS images (e.g., `node:20-alpine` instead of `node:20`).
- **Leverage layer caching:** Order instructions from **least-changing to most-changing**. Copy dependency files (`package.json`, `pom.xml`) before source code, so dependency installation layers are cached.
- **Combine RUN commands:** Reduce the number of layers by chaining commands with `&&` and cleaning up in the same layer:
  ```dockerfile
  RUN apt-get update && \
      apt-get install -y --no-install-recommends curl && \
      rm -rf /var/lib/apt/lists/*
  ```
- **Use `.dockerignore`:** Exclude unnecessary files (`.git`, `node_modules`, `logs/`, `*.md`) from the build context to reduce transfer time and image size.
- **Avoid unnecessary packages:** Use `--no-install-recommends` (Debian/Ubuntu) or minimal package managers (Alpine's `apk`).
- **Run as non-root user:** Improve security by creating and switching to a non-root user.

---

## How do you push Docker images to Amazon ECR?

```bash
# Step 1: Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account_id>.dkr.ecr.us-east-1.amazonaws.com

# Step 2: Tag the local image
docker tag myapp:latest <account_id>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest

# Step 3: Push to ECR
docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

In CI/CD pipelines, this is automated using **OIDC federation** (for EKS/GitHub Actions) or **IAM role-based authentication**, so that long-lived credentials are not stored.


##Docker image with a non root user.
FROM python:3.12-slim
WORKDIR /app
USER account1
COPY . . 
RUN useradd -ms /bin/bash account1
RUN chown account1:account1 /app
USER account1
CMD [ "python", "-m", "app.py" ]


lets say you have a docker container which is running , but you dont have a dockerfile of it. How do you retrive it ? 
. You cannot directly recover the original Dockerfile from a running container. But you can, inspect the container and reconstruct an approximate Dockerfile.
	docker inspect <container-id>

This can tell you things such as:
Image used
Environment variables
Entrypoint
CMD
Working directory
User
Ports
Volumes
Mounts
Network configuration
Labels

	Based on the above, you can reconstruct an approximate Dockerfile.
	We can also pass the environment variables & commands run-time, have a note of it.

Docker commit captures the container's filesystem changes.

Docker Snapshot: 
taking the current state of a running container and preserving it so you can create another container from that state, Docker provides this through docker commit

Eg:	docker run -it --name mycontainer ubuntu:24.04 /bin/bash
		#Now make the cahanges inside the container
	docker commit mycontainer my-ubuntu:snapshot1
	docker images
		
		#Now started by making anonther from the commited one after making changes
	docker run -it --name restored-container my-ubuntu:snapshot1 /bin/bash	

Now you can save it.
	docker commit employee-app employee-app:recovered
	docker save -o employee-app.tar employee-app:recovered

Now move this .tar file to anonther server and there start it.
	docker load -i employee-app.tar
	docker run employee-app:recovered

