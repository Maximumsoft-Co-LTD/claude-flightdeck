# Secret Handling

> How secrets enter, move through, and never escape an AI-driven workflow.
> The agent-redaction rule below is enforced by
> [`.claude/hooks/secret-redact.sh`](../../.claude/hooks/secret-redact.sh)
> (PreToolUse). The decision matrix tells you which provider to reach
> for in which environment.
>
> **Core principle**: a secret is anything the project would rotate if
> it leaked. Treat AI agents like any other automated actor — they can
> read what your shell can read; assume any value passed through a
> prompt or tool call is logged somewhere downstream.

## The agent-redaction rule (template-level — A011 candidate)

> **Agents never log, echo, or print the values of environment
> variables matching:** `*_TOKEN`, `*_KEY`, `*_SECRET`,
> `PASSWORD*`, `AWS_*`, `GCP_*`, `AZURE_*`, `OPENAI_*`,
> `ANTHROPIC_*`, `STRIPE_*`, `SLACK_*`, `GH_*`, `GITHUB_TOKEN`.

This is non-negotiable. Use the **name** (`$AWS_SECRET_ACCESS_KEY`) in
command construction, never substitute the value into a log line, a
commit message, a chat reply, or a tool prompt. The `secret-redact.sh`
PreToolUse hook scans Bash + Write + Edit tool input and blocks the
call (`exit 2`) on a pattern match. It fails open if `jq` is missing
so the rule never blocks dev on machines without the toolchain.

## Decision matrix — which provider for which environment

| Environment | Preferred provider | When | Anti-pattern to avoid |
|---|---|---|---|
| Local dev (single dev, one machine) | `.env` (gitignored) + `direnv` | Day-to-day local work | Committing `.env`; sourcing into the shell rc file |
| Local dev (shared team secrets) | `vault read` + cached env | Multiple devs need the same dev creds | Slack-sharing `.env`; storing in 1Password "team notes" |
| Pre-prod / staging | Cloud-native param store (SSM, GCP Secret Manager, Azure Key Vault) | Anything that runs in the cloud | A `.env.staging` committed to the repo |
| Production | Cloud-native param store + workload identity (IRSA / GKE WI / Azure AD WI) | Anything that runs in prod | Long-lived IAM users with static keys |
| CI / CD | GitHub OIDC (`id-token: write`) → cloud federation | Any CI step that touches cloud | GitHub repo secrets with long-lived AWS keys |
| Kubernetes cluster | `sealed-secrets` or `external-secrets-operator` | Cluster-bound secrets that need GitOps | Plain `kind: Secret` committed to a Helm chart |
| Repo-encrypted config | `sops` + `age` keys (per-team or per-env) | Secrets that must live in git (rare — usually config, not secrets) | Encrypting with PGP keys you can't rotate |
| Agent-driven deploy | Workload identity inherited from the runner | An agent that writes to cloud | Passing a long-lived token via prompt |

**Default**: cloud-native (SSM / Secret Manager / Key Vault) with
workload identity. Reach for `.env` only for local dev; reach for
`sops` only when GitOps demands the secret live in the repo.

## Worked example — a deploy step needs `DB_PASSWORD`

The wrong pattern (agent-visible secret on the prompt surface):

```bash
# DON'T — the value flows through the agent's tool input
DB_PASSWORD="hunter2-prod" make deploy
# DON'T — the value lands in your shell history and likely the agent's log
make deploy DB_PASSWORD="$(cat ~/.secrets/db)"
```

The right pattern (the **name** crosses the surface, the value is
fetched at the leaf by an authenticated process):

```bash
# Local dev — direnv loads .env once per directory; the var name flows, not the value
make deploy

# CI — GitHub OIDC + cloud federation; the runner pulls the value, agent never sees it
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123:role/deploy
- run: make deploy   # the make target reads DB_PASSWORD from SSM at runtime

# Production runtime — workload identity reads from Secret Manager
# at app start; nothing in the deploy pipeline ever sees the value
```

The pattern: **values are pulled by the process that needs them, at
the lowest possible layer; only the variable name and the parameter
path travel across logged surfaces.**

## Per-tier matrix — when to use each

| Tier | Provider | Rotation | Audit | Cost |
|---|---|---|---|---|
| Dev (local) | `.env` (gitignored), `direnv` | manual, when stale | git history of `.env.example` | $0 |
| Dev (team) | `vault read` (HashiCorp Vault) | TTL-bound leases | Vault audit log | OSS / Vault Enterprise tier |
| CI | GitHub OIDC → cloud STS | per-job (15min default) | cloud CloudTrail + GitHub job logs | $0 with GitHub Actions |
| Pre-prod | AWS SSM Parameter Store / GCP Secret Manager / Azure Key Vault | per-secret, scripted | CloudTrail / Cloud Audit Logs / Activity Log | <$1/month per secret |
| Production | Same + workload identity | automated, scheduled | Same | Same |
| K8s cluster | `sealed-secrets` (Bitnami) or `external-secrets-operator` (ESO) | depends on backing store | controller logs + audit ring | OSS |
| Repo-encrypted | `sops` + `age` | manual key rotation | git history of recipients | OSS |

## Anti-patterns (auto-reject in code review)

- ❌ `echo "$AWS_SECRET_ACCESS_KEY"` — never. The redaction hook
  blocks this; if it slips, the value is in shell history + the
  agent's tool log.
- ❌ `git log -- .env` — even reading the history surfaces older
  values. If `.env` ever landed in a commit, treat it as leaked,
  rotate, and **purge the history** (`git filter-repo`).
- ❌ Pasting a secret into a chat / prompt — even to "test that the
  agent has it". Use the name; the agent's leaf process resolves it.
- ❌ `curl -H "Authorization: Bearer $TOKEN"` printed via `set -x`
  or `bash -x`. Disable `xtrace` in scripts that handle secrets.
- ❌ Long-lived IAM users with static keys for CI. Use OIDC + STS.
- ❌ Committing `.env*` (use `.gitignore` + a pre-commit secret-scan
  like `gitleaks` or `trufflehog`).
- ❌ `.env` files at the repo root that aren't `*.example`. The only
  safe `.env*` to commit is `.env.example` with placeholder values.
- ❌ Storing secrets in `~/.bashrc` / `~/.zshrc`. They leak via
  `env`, `set`, and any `bash -x` script.
- ❌ Sealed-secrets / sops with the encryption key in the same repo.
  The key lives in a separate, access-controlled location.
- ❌ `ANTHROPIC_BASE_URL` (or any `*_BASE_URL` model-API redirect) set
  from committed `.claude/settings.json`. It reroutes API traffic +
  auth headers to attacker infrastructure (CVE-2025-59536 class). See
  [`agent-config-security.md`](./agent-config-security.md).

## Hook — what it does, what it doesn't

`secret-redact.sh` is a **conservative PreToolUse hook**. It:

- Scans Bash `command` strings for: literal `echo` / `printf` / `cat`
  of a sensitive env var name; redirection of a sensitive var to a
  file; piping a sensitive var to `curl` / `nc` / `wget` without
  `-H Authorization` quoting.
- Scans Write / Edit `content` for: file path matching
  `.env*` / `secret*` / `credentials*` + non-placeholder values
  (anything that looks like an actual key, not `<your-key-here>`).
- Blocks (exit 2) with `"blocked: potential secret leak — see
  docs/setup/secret-handling.md"` on match.
- Fails open (exit 0) if `jq` is missing — the rule never blocks
  dev on a machine without the toolchain.

It does NOT:

- Run entropy-based scanning on every file write (false positive
  rate too high). It only flags `.env*` / `secret*` /
  `credentials*` paths.
- Inspect outbound network traffic (out of scope for a PreToolUse
  hook — use `gitleaks` / network egress controls for that).
- Substitute for `gitleaks` / `trufflehog` in CI. Run those as a
  separate pre-commit / pre-push gate.

## Related

- [`compliance-mapping.md`](./compliance-mapping.md) — SOC2 / HIPAA /
  ISO 27001 / GDPR controls that map to this file's enforcement
- [`permission-profiles.md`](./permission-profiles.md) — restricted /
  standard / permissive Bash allow-lists
- [`separation-of-duties.md`](./separation-of-duties.md) — when a
  human approver must acknowledge a secret-touching change
- [`agent-config-security.md`](./agent-config-security.md) — committed
  `.claude/` config (hooks / MCP / env) as a code-execution surface
- [`../playbooks/post-delegation-review.md`](../playbooks/post-delegation-review.md)
  Gate 1 — the diff inspector that catches a committed `.env`
- [`../../.claude/hooks/secret-redact.sh`](../../.claude/hooks/secret-redact.sh)
  — the PreToolUse hook that enforces the redaction rule
