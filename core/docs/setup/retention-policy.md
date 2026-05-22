# Retention Policy

How long to keep the artifacts the AI-Workflows control plane
produces. Defaults tuned for "good for a real audit without crushing
disk budgets." Override per project as compliance requires.

This file is the central reference; sibling docs link here instead of
re-stating the matrix.

## What we retain

| Artifact | Default | Lower bound | Upper bound | Compliance driver |
|---|---|---|---|---|
| `docs/spec/audit/*.jsonl` (agent dispatches + gate events) | **12 months** | 3 months (pre-prod, no compliance) | 6+ years (HIPAA) | SOC2 / ISO 27001 / HIPAA / FedRAMP |
| `docs/spec/sprints/sprint-S<N>.md` | indefinite (in-repo) | last 3 sprints active, older → `sprints/historical/` | indefinite | change-management evidence |
| `docs/spec/retros/sprint-S<N>.md` | indefinite (in-repo) | last 3 sprints active, older archived | indefinite | learning record + audit |
| `docs/spec/retros/sprint-S<N>-tasks.md` (live mini-retros) | until sprint close | aggregated into `sprint-S<N>.md` and can be archived | indefinite | learning record |
| `docs/spec/STATUS.md` | live only (single-pane) | n/a | n/a | latest state — moved to `STATUS-archive.md` at sprint close |
| `docs/spec/STATUS-archive.md` | indefinite (append-only) | n/a | n/a | historical narrative |
| `docs/spec/FOLLOWUPS.md` | indefinite | n/a | n/a | open items stay scannable; closed items are the audit trail |
| `docs/designs/sprint-S<N>/D<NNN>-*.md` | indefinite (in-repo) | last 3 sprints active, older archived | indefinite | design-decision record |
| `.claude/agent-memory/<agent>/MEMORY.md` | indefinite | n/a | n/a | accumulated learning per agent |

## Audit log specifics (`audit.jsonl`)

The audit hook writes structured events to
`docs/spec/audit/YYYY-MM.jsonl`. Retention tiers depend on what the
project ships:

| Tier | Default | Why |
|---|---|---|
| Operational (default) | **12 months** | Sprint retros + quarterly review window |
| SOC2 / compliance | 24-36 months | Common SOC2 audit scope is 12 months + a buffer for the auditor |
| HIPAA | 6+ years | Statutory minimum where applicable |
| FedRAMP Moderate | 3 years for AU-11 family | Maps to "audit record retention" |
| Greenfield / pre-prod | 1-3 months OK | Disk is cheap; default to operational anyway |

### Rotation

Pick **one** of the three patterns; do not stack them.

**1. Cron / system timer (recommended for in-repo audit logs):**

```bash
# Monthly cron — delete .jsonl older than 12 months from
# docs/spec/audit/. Runs in the repo root.
0 3 1 * * find docs/spec/audit -name '*.jsonl' -type f -mtime +365 -delete
```

**2. GitHub Actions (if audit logs are git-tracked):**

```yaml
# .github/workflows/audit-rotate.yml
name: Rotate audit logs
on:
  schedule: [{cron: '0 3 1 * *'}]   # 03:00 UTC on the 1st
  workflow_dispatch: {}
jobs:
  rotate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Delete audit JSONL > 365 days
        run: |
          find docs/spec/audit -name '*.jsonl' -type f -mtime +365 -delete
      - name: Commit
        run: |
          git config user.email actions@github.com
          git config user.name "audit-rotate"
          git add -A
          git diff --staged --quiet || git commit -m "chore(audit): rotate logs older than 365d"
          git push
```

**3. External SIEM (large teams / multi-project):**

Forward each `audit.jsonl` line to your SIEM, then keep the in-repo
copy ephemeral (`docs/spec/audit/` in `.gitignore`). Retention then
follows your SIEM's policy. See
[`audit-trail.md`](./audit-trail.md) for the SIEM-ingestion shape.

## Sprint archival

After 3 sprints close, move older sprint files to
`docs/spec/sprints/historical/`:

```bash
/archive   # the canonical skill — see core/.claude/skills/archive/SKILL.md
```

Archival is purely organizational — **never delete** sprint files. The
retro records, FOLLOWUPS references, and design-doc links all assume
the sprint file is reachable from the same repo. Loss of a closed
sprint file breaks the audit chain.

## PII / redaction

The audit hook only captures **metadata** from the harness event:
`task_id`, file paths, subagent type, timing, agent id. It does NOT
capture:

- Prompt bodies
- File contents (input or output)
- Tool stdout / stderr
- Environment variable values
- User-typed text

Things to watch:

- **File paths may leak naming**. `secrets/staging-creds.yaml` in the
  `files_touched` array is a leak class. Redact in the SIEM forwarder,
  not at the hook (the hook is fail-open and must stay simple).
- **`project` field is the directory basename**. Usually safe; redact
  if you mount audit logs into a multi-tenant dashboard with leaky
  naming.
- **`agent_id` is harness-generated** and not PII.

For projects under GDPR scope, document in
[`compliance-mapping.md`](./compliance-mapping.md) which controls map
to the redaction posture above (typically Art. 5 minimization +
Art. 32 security).

## Deletion vs archival

| Action | When | What happens |
|---|---|---|
| **Delete** | `audit.jsonl` past retention; **never** for sprints / retros / design docs | File removed; not recoverable |
| **Archive** | Sprint older than 3 sprints back | Move to `sprints/historical/`; reachable but out of the way |
| **Tomb** | Compliance asks for "record we can prove was retained until date X" | Move to a read-only branch / S3 cold-storage bucket with object-lock |

If your project has a "right to be forgotten" / GDPR Art. 17 request,
the deletion target is usually the user-facing system, not the audit
log — audit logs are the **record that the deletion happened** and
must persist. Coordinate with legal before scrubbing audit lines.

## See also

- [`audit-trail.md`](./audit-trail.md) — the audit hook schema + jq
  query recipes (this doc is the retention slice extracted from there)
- [`compliance-mapping.md`](./compliance-mapping.md) — SOC2 / HIPAA /
  ISO / GDPR / FedRAMP crosswalk; retention rows there link back here
- [`../../.claude/skills/archive/SKILL.md`](../../.claude/skills/archive/SKILL.md)
  — the canonical `/archive` skill for sprint rotation
- [`../../.claude/skills/audit-query/SKILL.md`](../../.claude/skills/audit-query/SKILL.md)
  — `/audit-query` skill for digesting `audit.jsonl` before rotation
