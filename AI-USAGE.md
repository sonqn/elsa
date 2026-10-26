# AI usage disclosure

OpenAI Codex assisted with the HTTP service, Compose/k3d harness, Helm placement, troubleshooting, CI migration and documentation. The following first-person account describes the candidate's recorded actions; execution delegated to Codex is explicitly identified.

## My review and corrections

I cloned the public repository and ran the Golden Rule myself. My terminal output exposed missing-content-digest errors during k3d image import, even though the application later ran and the troubleshooting verifier printed PASS. I asked why those errors appeared rather than treating PASS as proof that every step was correct.

In my follow-up review, I reported reproducing Git's `dubious ownership` failure on Linux and identified the SHA handoff file, tracked evidence being overwritten, and the single Traefik replica as problems to address. I asked Codex to independently verify ownership, inspect actual Traefik labels, measure pod deletion before changing SIGTERM handling, and repeat clean-clone validation. I did not personally perform every command in Codex's verification; their results are attributed below and in VALIDATION.md.

## Representative prompts actually used

1. “Please help me implement the attached challenge” (English translation of my original Vietnamese request) — established the implementation scope and the need to read both the assignment and supplied package.
2. “Why the terminal show some errors … ctr: content digest … not found” — supplied my complete run output, exposing the published-image import path missed by the earlier local-build test.
3. “Lỗi git trên máy Linux … dubious ownership … 20-deploy.sh không chạy riêng được … Hãy tự đo bằng kubectl delete pod trước khi sửa.” — excerpts from my review message requesting portability, independent deployment, clean working trees, Traefik-aware selection, and measured SIGTERM validation.

## Where the AI was wrong or suboptimal

The initial design imported every image through k3d, including multi-platform registry indexes, while its recorded clean-clone validation exercised the local-build fallback rather than that published-image archive path. My logs showed per-node errors despite k3d's success summary. The revised script lets Kubernetes pull published images directly and restricts fallback imports to a single platform, checking each node afterwards.

The initial toolbox omitted safe.directory for Linux ownership differences. Codex independently reproduced exit 128 with a repository owned by UID 12345 inside a Linux container. The fix trusts `/workspace` only, not `*`.

The initial drill did not protect its singleton ingress from eviction, and the API lacked SIGTERM handling. The revised drill excludes nodes hosting Traefik and explicitly limits its claim to app-node resilience. Codex measured old pod deletion before adding a shutdown thread; the final timings and label evidence are in VALIDATION.md.

The first CI attempt also failed before scanning because pip resolved incompatible MCP/Pydantic dependencies for Semgrep. A tested digest-pinned Semgrep container fixed that without disabling `--error`. A deliberate unsafe shell=True fixture demonstrated a blocking finding.

I will use the source and recorded evidence to prepare for the live code walkthrough. This disclosure does not claim that AI-generated code or local tests prove production reliability.

During independent fallback-path verification, Codex also found two implementation mistakes before acceptance: BusyBox rejected a suffixed mktemp template, and this k3d environment required invoking `crictl` directly rather than through `k3s crictl`. Both were corrected and the forced-pull-failure fallback was rerun, including image inspection on all five nodes.
