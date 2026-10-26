# Validation after review fixes — 27 October 2026

**Validated code revision: `c9de28d7067c9da6e90504fe324eae3d9289768c`.** The final evidence-recording commit changes documentation/artifacts only. This supersedes the earlier `c923e86` acceptance record; historical root-level evidence files remain as historical snapshots.

## Acceptance results

| Check | Observed result |
|---|---|
| Clean Golden Rule | Fresh public clone, deleted cluster/kubeconfig volume, `docker compose up -d` followed by `./scripts/run-all.sh`; exit 0, verifier PASS. Docker image-layer cache retained. Host Buildx state redirected to a writable directory for the Codex sandbox. No cluster intervention during this final run. |
| Registry path | Final clean run pulled the published SHA image successfully. Kubernetes pulled from GHCR directly; no multi-platform archive import. |
| Git ownership | Linux container repository owned by UID/GID 12345: clearing safe.directory reproduces exit 128; toolbox system exception `/workspace` succeeds (exit 0). This validates Linux ownership semantics inside Docker, not a separate native-Linux-host end-to-end run. |
| Independent deploy | `20-deploy.sh` ran successfully after bootstrap, without running `10-build.sh`; it derives HEAD itself. Recorded at code revision ca8c2df, with the same deploy script as the final code. |
| Clean working tree | `git status --porcelain` empty after final run; runtime logs are in ignored `.runs/`. Scripts do not write tracked evidence. |
| Traefik selector | Actual pod labels include `app.kubernetes.io/name=traefik`. |
| Targeted drill | In a separate disposable fixture, Traefik was moved onto agent-0. Drill excluded agent-0 (and the old terminating Traefik node), selected agent-1, and passed: 20 HTTP successes / 0 failures. |
| Final default-config drill | 11 HTTP successes / 0 failures; replacement pod Ready, on-demand replica Ready, drained node uncordoned. |
| SIGTERM timing | `kubectl delete pod --wait=true`: old image 32.919 s; revised image 1.913 s. Both exit 0. Idle standalone pods, default 30 s grace; one sample each, not a performance benchmark or proof under sustained in-flight load. |
| Local-build fallback | Forced only `docker pull` to fail using a test-local command wrapper. Actual build, single-platform export, import and `crictl inspecti` checks on all five nodes succeeded. Wrapper not shipped in the repository. |
| Troubleshooting | Original broken manifests applied, original scheduler diagnostics captured, fixed manifests applied, unchanged verifier PASS. DNS/HTTP failure descriptions are explicitly labeled inference. |
| CI | [Run 40420130376](https://github.com/sonqn/elsa/actions/runs/40420130376): quality and multi-platform publish succeeded for the validated code SHA. Final documentation HEAD is checked separately before delivery. |
| Documentation | OPS answers: 540 words; Q1 and Q3 are numbered. AI disclosure separates candidate actions from delegated verification and includes three actual follow-up prompts. |

Raw review evidence: [`review-20261027/`](review-20261027/). `git-status-after.txt` is intentionally empty. All recorded pod timing/HTTP observations are local; no production reliability claim is made.

## Boundaries and corrections

- The singleton Traefik ingress remains a lab SPOF. Excluding its node makes this an app-node reclaim drill, not a test of ingress HA or arbitrary spot-node loss. The script fails clearly if no eligible target remains.
- SIGTERM shutdown runs on a separate thread; active handler threads finish before server close. Slow/incomplete clients can still consume the Kubernetes termination budget.
- Public images use direct pulls. Only local fallback images pass through k3d. Verification found and corrected BusyBox's rejection of the initial suffixed mktemp template and the need to invoke `crictl` directly in this environment.
- Git trusts only `/workspace`, not all directories. The ownership regression was independently reproduced, rather than inferred from macOS behavior.
- Scripts preserve committed evidence. New evidence is deliberately copied/committed after review, not overwritten during a normal run.
- HPA configuration is present; load-induced scale-out, Parts 5/6 and production AWS infrastructure remain outside the selected scope.
