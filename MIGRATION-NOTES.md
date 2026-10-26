# GitLab → GitHub Actions

The migrated scope is test, SAST gate and image publication. GitOps owns deployment; the CI job no longer stores kubeconfig or mutates live Deployments with `kubectl set image`.

- Tests run on PRs and main and propagate failure; removed `npm test || echo ...`. The app is Python, so the inherited Node 16/npm steps were replaced, not copied.
- Semgrep scans Python/security and secret rules with `--error`. Findings or scan errors fail the quality job. Publish depends on quality; removed Sonar's `allow_failure: true` and main-only checks.
- Publish runs only on main pushes, with job-scoped `packages: write` and ephemeral `GITHUB_TOKEN`; fork PRs cannot push packages. No password on the CLI, privileged Docker-in-Docker service, stored cloud credentials or broad global write permissions.
- GHCR tags are full git SHAs; buildx publishes amd64 and arm64. OCI source labels connect the package to this repository. The package must be public for anonymous reviewers; a public GitHub repo does not itself guarantee package visibility.
- Source chart, probes and placement are reviewed in Git. Release automation should promote a verified SHA by PR into environment values, followed by Argo CD reconciliation. This take-home pins each local run to its repository HEAD.

For a real migration: inventory GitLab variable scopes, masking/protection and environment approvals; classify config vs secrets; move non-secret config to repository/environment variables. Use GitHub environment secrets only when federation is unavailable. Replace AWS keys with OIDC and an IAM trust policy restricted to repo and deployment environment, least-privilege roles and short sessions. Move application runtime secrets to Secrets Manager with workload-scoped IAM. Rotate old credentials, revoke old CI access after dual-run validation, audit logs, and test rollback. Never transfer secret values through source files or logs.

The supplied legacy file contains AWS documentation examples, not live credentials; they are retained only as original challenge input. No operational secrets are committed. No Trivy/cosign bonus is claimed. Pinning Actions by immutable commit and pinning reviewed Semgrep rules would further strengthen supply-chain reproducibility; currently Actions use maintained major tags and Semgrep rule registry references.
