# Part 5 — Written Answer

## Q1. Migrating from ingress-nginx to Kubernetes Gateway API without downtime

- **Inventory first:** export all 40 Ingress objects, annotations, TLS settings, rewrite rules, authentication integrations, timeouts, and traffic patterns. Identify features that are controller-specific and may not map directly to Gateway API.
- **Choose and validate a Gateway implementation:** install the selected Gateway controller in a non-production environment and confirm support for `GatewayClass`, `Gateway`, `HTTPRoute`, TLS, redirects, rewrites, and observability.
- **Build the new path in parallel:** create a Gateway and equivalent HTTPRoutes without removing the existing Ingress resources. Use separate listener addresses or an internal test entry point for validation.
- **Migrate incrementally:** move applications in small groups. Test routing, TLS, headers, authentication, WebSockets, redirects, and backend health. Keep rollback manifests ready.
- **Shift traffic safely:** use DNS or a load-balancer mechanism that supports controlled cutover. Reduce DNS TTL in advance and monitor error rates, latency, and 4xx/5xx responses.
- **Expect breakage:** unsupported annotations, path matching differences, rewrite behavior, TLS configuration differences, controller-specific authentication, and missing Gateway API features may require redesign.
- **Decommission last:** retain ingress-nginx until all routes have been validated and rollback is no longer required.
