# Findings — Part 4 debug lab

Fill in one entry per defect you find. Paste the *actual* output you saw —
we cross-check it against your session recording and your git diff, and the
diagnostic path matters more to us than the fix itself.

Before you start investigating, begin recording:
`script -q part4-session.log` (or `asciinema rec part4-session.cast`), and
commit that file alongside this one.

# Findings — Part 4 debug lab

## Defect 1

Symptom:

When I ran:

./scenario.sh up


the migrate job failed with:

Error: 1 error occurred:
        * Job.batch "migrate" is invalid: spec.template.spec.restartPolicy: Required value: valid values: "OnFailure", "Never"


Cause:
In migrate-job.yaml, the Job had:

restartPolicy: Always

Always is not supported for Kubernetes Jobs. A Job pod can use only Never or OnFailure.

Fix:

Changed:

restartPolicy: Always

to:

restartPolicy: Never

How I found it:

I found this while running:

./scenario.sh up

The error pointed to the restartPolicy in the migrate Job. I checked migrate-job.yaml and saw that it was set to Always. Since this is a migration Job which should run and complete, I changed it to Never.

After the fix, verification showed:

PASS migrate Job completed
---

## Defect 2

Symptom:

After fixing the migrate Job, the pods were still not starting. In the pod events I found:


Error: container has runAsNonRoot and image has non-numeric user (nonroot), cannot verify user is non-root


I checked the image user:


docker image inspect docker.io/ebinterview/eb-debug-app:1.0.1 --format '{{json .Config.User}}'


Output:

"nonroot"


Cause:

runAsNonRoot was enabled, but the Docker image was using the named user nonroot. Kubernetes could not verify the numeric UID.

Fix:

I checked the UID of the `nonroot` user from `/etc/passwd` inside the image:

nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin


Then added:

runAsUser: 65532


to the container security context.

How I found it:

First I checked the pod events using `kubectl describe pod`. Then I checked the image configuration using `docker image inspect`. Since the image did not contain commands like `id`, I exported the image filesystem and checked `/etc/passwd` to get the UID.

---

## Defect 3

Symptom:

The worker was starting but failed with:


FATAL: worker could not initialise its cache: mkdir /var/cache/app: read-only file system — the process needs a writable directory at /var/cache/app (mount a volume there, or set CACHE_DIR)


Cause:

The container had `readOnlyRootFilesystem: true`, but the worker needs to write cache files under `/var/cache/app`.

Fix:

Added an emptyDir volume and mounted it to /var/cache/app:


volumeMounts:
  - name: cache
    mountPath: /var/cache/app



volumes:
  - name: cache
    emptyDir: {}



How I found it:

I checked the worker logs using kubectl logs. The application itself showed that it was failing while creating /var/cache/app.

---

## Defect 4

Symptom:

The readiness probe was failing on port `8080`.

The application log showed:

listening on :8081 (image default is 8081; set PORT to override)


But the chart was configured with:


common:
  port: 8080


Cause:

The application was listening on its default port `8081`, while the Kubernetes Service and probes were using `8080`.

Fix:

Added:


PORT: "8080"


to the application environment values.

After this, the application started listening on the same port used by the Service and readiness probe.

How I found it:

I checked the readiness probe failure and compared it with the application logs. The probe was checking `8080`, but the application log clearly showed that it was listening on `8081`.

---

## Defect 5

Symptom:

The gateway was not able to connect to the backend.

Gateway logs showed:


lookup backend.default.svc on 10.96.0.10:53: no such host
GET /healthz -> 503


The backend URL was configured as:


http://backend.default.svc:8080


Cause:

The backend is running in the `debug-lab` namespace, but the gateway was trying to find it in the `default` namespace.

Fix:

Changed the backend URL to:


BACKEND_URL: "http://backend.debug-lab.svc:8080"


How I found it:

I checked the gateway logs and saw the DNS lookup failure for `backend.default.svc`. Then I checked where the backend Service was actually running and found it under `debug-lab`.

After fixing it, verification showed:

PASS gateway /status reports backend=ok


---

## Defect 6

Symptom:

The reporter was not able to list pods and the logs initially showed:


pod list failed: kubernetes API returned HTTP 403


Cause:

The reporter Deployment was running with:


serviceAccountName: reporter


but the RoleBinding was giving the permissions to the `default` ServiceAccount instead of `reporter`.

Fix:

Changed the RoleBinding subject from:


name: default


to:


name: reporter


How I found it:

I first checked the reporter logs and found the HTTP 403 error.

Then I compared the ServiceAccount used in `reporter.yaml` with the ServiceAccount configured in `rbac.yaml` and found the mismatch.

After fixing it, the permission check passed:

## Current status
Pending defect:
The reporter was able to access the Kubernetes API, but it failed while parsing the pod list response. Because the pod list could not be parsed, the reporter health check returned 503 and the pod remained Not Ready.

reporter logs shows 2026/09/19 09:32:11 GET /healthz -> 503 (from 10.244.0.1:44564)
2026/09/19 09:32:16 GET /healthz -> 503 (from 10.244.0.1:44566)
2026/09/19 09:32:21 pod list failed: parse pod list: unexpected end of JSON input
2026/09/19 09:32:21 GET /healthz -> 503 (from 10.244.0.1:33776)
2026/09/19 09:32:26 GET /healthz -> 503 (from 10.244.0.1:33790)

Fix:

Still under investigation. The reporter ServiceAccount permission was verified successfully, and the same Kubernetes API pod-list request returned valid JSON when tested manually.

So the reporter parsing issue is still under investigation.

---


I also found that the metrics container CPU request/limit was above the namespace `LimitRange`. I changed the metrics resources from:

```yaml
requests:
  cpu: "2"
  memory: "64Mi"
limits:
  cpu: "4"
  memory: "128Mi"
```

to:

```yaml
requests:
  cpu: "50m"
  memory: "64Mi"
limits:
  cpu: "200m"
  memory: "128Mi"
```

After this change the metrics Deployment became `1/1 Ready`.

The remaining issue is the reporter JSON parsing failure. I am continuing the investigation before finalising the findings.


