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
