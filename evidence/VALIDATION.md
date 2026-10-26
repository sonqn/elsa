# Validation record

## Review-fix validation

Code has changed after the original c923e86 validation. The original results below are historical, not acceptance evidence for the revised implementation. A fresh clean-clone run and final CI check are in progress.

Confirmed so far: Linux-container ownership reproduction fails with exit 128 before the scoped `/workspace` Git fix and succeeds afterwards; actual Traefik labels include `app.kubernetes.io/name=traefik`; old-image pod deletion took 32.919 seconds. Runtime logs now use ignored `.runs/`, and deployment derives SHA directly from Git.

## Historical baseline (26–27 October 2026)

CORE + Part 4 + Part 7; the original clean-clone run passed.

Validated implementation revision: `c923e86e7b4047fa4b15f6240467391da3dfd7ea`. This historical revision predates the portability, shutdown and drill corrections.
Environment: Apple Silicon; Docker 29.6.1; 12 CPUs / 8 GiB Docker RAM; k3s v1.33.5+k3s1. Docker layer cache was retained; the cluster and kubeconfig volume were deleted before the clean-clone run.

| Check | Observed result |
|---|---|
| Clean-clone Golden Rule | New clone from public GitHub, `docker compose up -d`, then `./scripts/run-all.sh`: exit 0, ending with PASS. Full output: `golden-rule.txt`. Buildx metadata was redirected to a writable host directory solely for the Codex sandbox. No application/cluster intervention during the run. |
| API tests | 3 passed: health/readiness, quote JSON and >=95ms CPU work, metrics, 404. |
| Helm/shell | Helm lint and syntax validation passed locally and in CI. |
| Toolbox | kubectl, Helm, Terraform and k6 execute; `toolbox-versions.txt`. |
| Bootstrap | 1 server + 4 Ready workers; original prepare.sh gives 2 spot / 1 on-demand / 1 GPU with original taint. |
| GitOps | Argo CD Application reads public repo at the validated SHA; Synced and Healthy. No manual Helm app installation. |
| Placement | Initially 3 Ready pods: one on each non-GPU worker; HPA min 3. |
| Reclaim | Saved clean-run log: 39 HTTP samples, zero failures; replacement on remaining spot worker; on-demand stays Ready; original node uncordoned. Earlier repeat drill also drained a worker hosting TWO quote replicas; PDB deferred the second eviction until recovery, and the drill passed. |
| Troubleshooting | Original defects applied and diagnostics captured, then fixed manifests; original verify.sh PASS. GPU inference runs on tainted GPU node. Default-deny retained. |
| Negative traffic | Separate client lacking the allowed label could not reach the web Service by IP (curl exit 7). The allowed smoke-client passed. k3s can reject rather than time out; initial negative-test assertion expecting only timeout 28 was too narrow, and is not represented as a passed assertion. |
| SAST | Tested Semgrep container: 187 rules / 3 targets / 0 findings. Deliberate shell=True fixture produced a blocking finding. |
| GitHub Actions | [Run 40365133773](https://github.com/sonqn/elsa/actions/runs/40365133773) passed quality and publish for the validated SHA. |
| Public GHCR | Anonymous toolbox pull succeeded. Image `ghcr.io/sonqn/elsa:c923e86e7b4047fa4b15f6240467391da3dfd7ea`, index digest `sha256:a1f870a85490ef66d954519d425ca1b0e9dacb66736c016ef96ba24c8e2d5c9b`, amd64 + arm64 published. Direct container run with read-only rootfs, no capabilities and no-new-privileges returned HTTP 200 on /api/quote. |

The clean run began while its CI publish was still finishing, so `10-build.sh` exercised the documented source-build fallback and imported that image. The public GHCR pull and runtime smoke test were then verified separately; the clean-run pod image is not misrepresented as a registry-pulled artifact.

## Failures investigated

- First workflow failed before scanning: pip-installed Semgrep's transitive MCP dependency imported `eval_type_backport`, unavailable from the resolved Pydantic version. Reproduced in fresh Python 3.13 and confirmed in authenticated GitHub logs. Replaced pip installation with the tested digest-pinned Semgrep container; retained the hard-fail gate. Later workflow passed.
- A repeated local k3d import overlapped another import and one attempt failed. Subsequent execution was serialized; clean Golden Rule passed without that race.
- Git Keychain rejected a subsequent push after the initial push succeeded. User completed `gh auth login`; all final code and evidence were then pushed normally.

UTC timestamps appear in raw container logs; dates above use local time. No Parts 5/6, cloud deployment, measured load-test RPS, or production availability is claimed. The single on-demand worker cannot remain available during its own outage.
