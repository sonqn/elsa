# AI usage disclosure

OpenAI Codex assisted with reading the assignment, implementation of the HTTP service, Compose/k3d harness, Helm placement, troubleshooting fixes, GitHub Actions and documentation. The candidate must review and be able to explain this work; this document does not claim unaided authorship.

Actual user prompts in this session:
1. “Hãy giúp tôi thực hiện challenge ở file đính kèm” (help me implement the attached challenge).
2. Repository destination supplied in response to the publication question: `https://github.com/sonqn/elsa`.

Only these two user inputs were received; a third prompt is not fabricated. The assistant's concrete verification questions were: does capacity-level spread retain an on-demand replica during a spot drain, and does the unchanged troubleshooting verifier pass with default-deny preserved?

Correction example: the initial AI design proposed one on-demand Deployment plus an autoscaled spot-preferred Deployment. Review against the requirement exposed a mismatch: HPA minReplicas 3 plus one fixed replica produces at least four total. Before deployment this was replaced by one Deployment with hard capacity-type spread and soft hostname spread, keeping HPA minimum 3. A hard hostname spread would have unnecessarily constrained replacement scheduling when a worker disappears.

Another practical correction: the initial Docker build tried writing Buildx state outside the sandbox and failed. Buildx state was redirected into the authorized work directory rather than claiming a successful build. Runtime evidence and outstanding external checks are kept in `evidence/VALIDATION.md`.

Validation includes API behavior/CPU-work tests, Helm rendering, actual local cluster deployment and the supplied verifier where recorded. No successful GitHub run, GHCR publication or production behavior is inferred from local linting.

CI correction: the first workflow installed Semgrep 1.140.0 through pip. Reproducing that in a fresh Python 3.13 container exposed a transitive MCP/Pydantic ImportError (`eval_type_backport`). The workflow now uses the tested Semgrep container pinned by digest, preserving `--error` instead of weakening the gate.
