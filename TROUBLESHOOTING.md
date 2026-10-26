# Troubleshooting record

The original `prepare.sh`, `verify.sh`, `smoke-job.yaml` and broken manifest are preserved. `30-troubleshoot.sh` captures the original pod descriptions/events before applying the fixes. Initial failures can mask later ones; manifest inspection complements runtime diagnosis. The commands below are reproducible diagnostic commands; runtime results actually captured are identified in `evidence/VALIDATION.md`, not invented terminal transcripts.

| Symptom | Exact diagnostic command | Root cause | Fix |
|---|---|---|---|
| Web Pending | `kubectl -n troubleshoot describe pods -l app=web` | Each pod requests 16Gi, larger than this Docker VM. | Request/limit 64Mi for small static nginx service. |
| Image pull failure after scheduling | `kubectl -n troubleshoot get events --sort-by=.lastTimestamp` | `nginx:1.25.99` is not a released tag. | Use `nginx:1.28.0-alpine`. |
| FailedMount | `kubectl -n troubleshoot get cm; kubectl -n troubleshoot describe pods -l app=web` | Volume names `web-conf`, actual ConfigMap is `web-config`. | Correct volume reference. |
| Unready/restarting nginx | `kubectl -n troubleshoot describe deployment web; kubectl -n troubleshoot logs deployment/web` | HTTP probes use 8080; stock nginx listens on 80. | Both probes use 80. |
| Service has no ready endpoints | `kubectl -n troubleshoot get svc web-svc -o yaml; kubectl -n troubleshoot get pods --show-labels; kubectl -n troubleshoot get endpointslices -l kubernetes.io/service-name=web-svc` | Selector `app=webapp` does not match `app=web`. | Correct selector. |
| Service connection refused after selector fix | `kubectl -n troubleshoot get svc web-svc -o yaml; kubectl -n troubleshoot get deploy web -o yaml` | Service targetPort 8080 is not nginx's listening port. | Set targetPort 80. |
| Inference Pending (selector) | `kubectl get nodes --show-labels; kubectl -n troubleshoot describe pods -l app=ai-inference` | `node-type` misses the `acme.io/` prefix. | Select `acme.io/node-type=gpu`. |
| Inference Pending (taint) | `kubectl get nodes -l acme.io/node-type=gpu -o jsonpath='{.items[*].spec.taints}'; kubectl -n troubleshoot describe pods -l app=ai-inference` | GPU taint has no matching toleration. | Add exact key/value/effect toleration; preserve taint and labels. |
| DNS failure (inferred from policy; not captured before fix) | `kubectl -n troubleshoot logs job/smoke-test; kubectl -n troubleshoot get networkpolicy -o yaml; kubectl -n kube-system get pods -l k8s-app=kube-dns --show-labels` | Default-deny egress blocks DNS. | Allow only smoke-client to kube-system CoreDNS pods on UDP/TCP 53. |
| HTTP failure (inferred from policy; not captured before fix) | `kubectl -n troubleshoot logs job/smoke-test; kubectl -n troubleshoot get networkpolicy -o yaml` | Both client egress and server ingress are denied. | Allow smoke-client egress to web TCP/80 and reciprocal web ingress from smoke-client. Same-namespace selectors avoid namespace-wide access. |

The namespace-wide deny policy remains intact. No web egress permission is needed to serve a response; stateful NetworkPolicy implementations allow replies to established allowed connections. The simulated inference workload needs neither network access nor a real GPU device request.

Acceptance: `kubectl -n troubleshoot rollout status deployment/web`, `kubectl -n troubleshoot rollout status deployment/ai-inference`, then `sh troubleshoot/verify.sh`. The verifier checks node labels, GPU taint/placement, endpoints and the complete DNS → Service → nginx → ConfigMap response path. Its PASS alone does not prove disallowed traffic is blocked; negative connectivity checks are recorded separately when run.

## Actual scheduler evidence

The committed `evidence/broken-events.txt` contains these excerpts:

> `4 Insufficient memory`

> `1 node(s) had untolerated taint {nvidia.com/gpu: true}, 4 node(s) didn't match Pod's node affinity/selector`

These are observed scheduler errors. DNS/HTTP failures in the table are deductions from the default-deny policy, not claimed pre-fix smoke logs. New script runs write diagnostics to ignored `.runs/`; committed `evidence/` is a reviewed snapshot and is never overwritten by scripts.
