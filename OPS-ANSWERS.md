# Operations answers

## 1. EKS 1.33 → 1.35

1. Upgrade **1.33 → 1.34 → 1.35**, validating each hop. Check upgrade insights, deprecated APIs, webhooks, backups, IP quota, readiness, multi-AZ replicas and PDBs.
2. Check add-on compatibility on both sides of each hop; update prerequisites such as VPC CNI first when required. Upgrade the control plane, then compatible vpc-cni, CoreDNS, kube-proxy and EBS/EFS CSI versions with staged checks.
3. Add new-version worker capacity, canary a node group, and drain/replace old workers within PDBs. Test DNS, networking, storage and user traffic before the next hop. Blue/green workers support rollback; control-plane downgrades are unavailable.
4. Top risks: removed APIs/webhooks; inadequate surge/IP capacity or incorrect PDBs/probes; CNI/DNS/CSI and volume/AZ incompatibility. Zero downtime is an application SLO to verify, not an unconditional platform guarantee.

## 2. Spot reclaim alert storms

I would keep node-state telemetry for every pool, but page on sustained user impact (availability/error-budget burn) or lost required capacity, not every expected spot exit. Route expected spot interruptions correlated with a recent interruption/termination event to a low-noise notification channel. Group alerts by cluster/pool and inhibit duplicate pod/node symptoms only while a time-bounded, correlated reclaim/replacement workflow is active. A starting node-unreachable delay could be five minutes, tuned to measured replacement times. Page when replacement misses its deadline, Pending pods persist, baseline on-demand capacity is lost, too many nodes disappear together, or service SLOs burn. Unknown spot failures still alert after the delay; do not silence all spot nodes by label. Maintain independent black-box/service alerts so event-pipeline failure cannot conceal real impact. Test voluntary reclaim, unexpected node loss and failed replacement separately.

## 3. Cloudflare HTML caching and LCP 5s

1. Reproduce an anonymous mobile URL. Inspect the waterfall, TTFB and LCP element: images or blocking JavaScript can cause slow LCP despite cache hits.
2. Repeat GETs at the same URL/edge. Inspect `CF-Cache-Status`, `Age`, cache-control headers, `Set-Cookie`, `Vary` and redirects. Distinguish MISS→HIT from repeated DYNAMIC/BYPASS.
3. Verify proxied DNS, development mode, matching Cache Rules/Workers and precedence. HTML needs explicit cache eligibility. Check origin private/no-store, cookies, authentication and query-string cache keys; correlate origin logs.
4. Cache only public anonymous HTML; bypass authenticated/personalized routes. Set appropriate TTL/purge behavior, warm the cache, verify HIT/Age and fewer origin requests, then remeasure mobile TTFB/LCP.

## 4. EKS application secrets

Option A: External Secrets Operator (ESO) retrieves Secrets Manager values using scoped workload IAM and reconciles Kubernetes Secrets. It supports existing env/file consumers and centralized rotation, but values also exist in Kubernetes and need restrictive RBAC, encryption controls and refresh/restart handling. Option B: Secrets Store CSI with the AWS provider mounts secrets at pod runtime without a Kubernetes Secret unless sync is enabled. It reduces API-stored copies but adds node/provider dependencies and requires file-aware apps and tested rotation/reload behavior; env vars do not update automatically. For a startup with several production clusters I would choose Secrets Manager + ESO for compatibility and standardized GitOps ExternalSecret definitions, separate stores/roles per cluster/environment, and least privilege per application. Keep values out of Git/CI, audit reads, test rotation and provider outage behavior, and use a controlled reload strategy. Use CSI for workloads with a strict requirement to avoid Kubernetes Secret persistence.

Sources: [EKS upgrade process](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html); [Cloudflare uncached responses](https://developers.cloudflare.com/cache/troubleshooting/investigating-uncached-responses/); [AWS secrets CSI integration](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_ascp.html); [ESO AWS provider](https://external-secrets.io/latest/provider/aws-secrets-manager/).
