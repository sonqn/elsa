# Observed validation — 2026-10-26 (Asia/Ho_Chi_Minh)

Environment: Apple Silicon, Docker 29.6.1, 12 CPUs / 8 GiB Docker RAM; k3s v1.33.5+k3s1.

| Check | Observed result |
|---|---|
| API unit tests | 3 passed: health/readiness, JSON quote + >=95ms process CPU, metrics, 404. |
| Helm lint and shell syntax | Passed. |
| Toolbox | kubectl, Helm, Terraform and k6 execute; see `toolbox-versions.txt`. |
| Cluster bootstrap | 1 server + 4 Ready workers; unchanged prepare.sh assigns 2 spot / 1 on-demand / 1 tainted GPU. |
| Argo CD | Application Synced/Healthy; remote chart revision ee66f0c64aedaa470a4c98b1d7c5df58a05bb6f1. |
| App | 3 Ready replicas: initially one per non-GPU worker. Host GET localhost:8080/api/quote returns JSON. |
| Reclaim | Two sequential drills passed. Second drill drains spot worker hosting TWO app replicas; PDB temporarily rejects a second concurrent eviction until replacement is ready. 42 HTTP samples, zero failures in the saved second-run log. Both replacements on remaining spot worker; on-demand stays Ready; drained worker uncordoned. |
| Troubleshooting | Original broken manifests applied, diagnostic snapshots collected, fixed manifests applied; unchanged verifier PASS, repeated successfully. |
| Denied traffic | An unlabeled-for-allow client in troubleshoot could not reach web Service by IP (curl exit 7; k3s can reject rather than time out). Allowed smoke-client passes. Initial negative-test assertion expected only timeout 28 and was too narrow; no claim that this failed assertion itself passed. |
| SAST local | Semgrep 1.140.0: 187 rules, 3 targets, zero findings. Separate deliberate shell=True fixture produces one blocking finding. |
| GitHub CI | Initial public run failed at Semgrep; publication skipped as designed. Root cause pending access to full job logs. |
| Public GHCR | Not yet verified or published; local image was built and imported, not downloaded from GHCR. |

The remote chart tree used by the observed deployment matches the local chart template. The image was locally built as `ghcr.io/sonqn/elsa:6a1e4384ded2d5d34713f9344dcc620447740ce9`. That commit was not yet pushed because Keychain rejected the subsequent Git authentication. This is explicitly not evidence of the final clean-clone Golden Rule or a successful remote CI run. Both need rerunning once authentication is available.

Raw local evidence in this directory records actual commands/results. Runtime output uses UTC timestamps; the validation date above is local time. No Parts 5/6, cloud deployment, load-test RPS, or production availability claim is made.
