# Part 5 — Written Answer

## Q1. Migrating from ingress-nginx to Kubernetes Gateway API without downtime

I would do the migration in phases instead of replacing all 40 Ingress objects at once.

-First, I would review all existing Ingress objects and identify the hosts, paths, TLS certificates, annotations, rewrites, timeouts, and other ingress-nginx-specific configurations.
-Next, I would install a Gateway API controller and create the required GatewayClass and Gateway resources. I would keep ingress-nginx running during the migration.
-I would start with a few low-risk applications and convert their Ingress rules into HTTPRoute resources.
-Before moving production traffic, I would test routing, TLS, health checks, redirects, path rewrites, headers, and application connectivity through the new Gateway.
-Once testing is successful, I would gradually move traffic to the Gateway. I would not migrate all 40 applications together.
-During the migration, I would monitor application errors, HTTP status codes, latency, pod logs, and Gateway/controller logs.

I would keep the old ingress-nginx configuration running until the migrated applications are stable. If any major issue occurs, traffic can be moved back to ingress-nginx. After all applications are migrated and verified, I would remove the old Ingress resources and decommission ingress-nginx.
