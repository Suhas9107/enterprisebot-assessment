# Enterprise Bot DevOps Assignment

This repository contains the implementation for the Enterprise Bot DevOps take-home assignment.

## Prerequisites

Install the following tools before running the setup:

* Docker
* kind
* kubectl
* Helm
* Bash, WSL, or Git Bash

Verify the installations:

```bash
docker --version
kind --version
kubectl version --client
helm version
```

## Setup

Clone the repository and navigate to the project directory.

Make the setup script executable:

```bash
chmod +x setup.sh
```

Run the setup:

```bash
./setup.sh
```

The setup script will:

* Create or reuse the kind cluster `enterprisebot`
* Install ingress-nginx
* Build the `demo-service` Docker image
* Load the image into the kind cluster
* Deploy the Helm release `demo`
* Create/use the `demo` namespace
* Wait for the application to become ready

The script can be run multiple times safely.

## Verify the Deployment

Check the application pods:

```bash
kubectl get pods -n demo
```

Check the Service and Ingress:

```bash
kubectl get svc -n demo
kubectl get ingress -n demo
```

Check the Helm release:

```bash
helm list -n demo
```

## Test the Application

The local kind cluster maps host port `8080` to the ingress controller.

Test the application through Ingress:

```bash
curl -H "Host: demo.local" http://127.0.0.1:8080/
```

Expected response:

```json
{
  "app": "demo-service",
  "pod": "demo-service-xxxxxxxxxx-xxxxx",
  "version": "0.1.0"
}
```

Test the health endpoint:

```bash
curl -i -H "Host: demo.local" http://127.0.0.1:8080/healthz
```

The health endpoint should return HTTP `200`.

### Windows PowerShell

In Windows PowerShell, use `curl.exe`:

```powershell
curl.exe -H "Host: demo.local" http://127.0.0.1:8080/
curl.exe -i -H "Host: demo.local" http://127.0.0.1:8080/healthz
```

## Browser Access

To access the application from a browser, add the following entry to your hosts file:

```text
127.0.0.1 demo.local
```

On Windows, the hosts file is located at:

```text
C:\Windows\System32\drivers\etc\hosts
```

Then open:

```text
http://demo.local:8080/
```

## Resource Requests and Limits

For the application workloads I used:

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi

These are small services running in a local kind environment, so I kept the resource requests low. 50m CPU and 64Mi memory give the scheduler a reasonable minimum requirement without reserving unnecessary resources.

For a production environment, I would not use these values without testing. I would check actual CPU and memory usage over time and adjust the requests and limits based on application metrics and load testing.

## Production-Ready Changes


For production, I would make the following changes:

-Run multiple replicas for services that require high availability.
-Configure Horizontal Pod Autoscaling based on application requirements.
-Add PodDisruptionBudgets.
-Store secrets in a proper secret-management solution instead of keeping sensitive values in Helm configuration.
-Configure TLS and certificate management.
-Add centralized application and Kubernetes logging.
-Add monitoring and alerting for pod health, resource usage, application errors and availability.
-Use CI/CD for image build, security checks, Helm validation and deployment.
-Define rollback procedures and validate them before production releases.

## How I Used AI


I used AI as a supporting tool during the assignment mainly for troubleshooting suggestions, understanding some Kubernetes error messages and reviewing commands while debugging.

I used AI for troubleshooting suggestions and to better understand some of the errors during the assessment. I used actual pod logs, Kubernetes events, Helm configuration, and verification output to identify the issues. I ran the suggested commands myself, reviewed the output, and validated the changes before applying them.

AI was also used to help organize and review the documentation. The final configuration changes and verification were done against the running local environment.