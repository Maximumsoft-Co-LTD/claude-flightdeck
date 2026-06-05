# Separation of Duties

> The agent-driven workflow concentrates a lot of authority in a single
> session. Separation of Duties (SoD) is the human-in-the-loop guard
> that keeps any single actor — human or agent — from authoring,
> reviewing, and approving the same change.
>
> **Core principle**: for regulated work, the human who **acknowledges**
> a Gate 4 finding cannot be the same actor (human or agent) that
> **produced** it. The acknowledgement lands in PR metadata, the audit
> JSONL, and the merge gate.

## What N6 says

Root [`CLAUDE.md`](../../CLAUDE.md) §N6 (non-negotiable):

> **Separation of Duties.** For regulated work (auth, secrets, RBAC,
> financial), Gate 4 reviewer findings must be acknowledged by a human
> approver named in `PR-APPROVER` metadata.

Mechanically:

1. The 6-gate review's Gate 4 runs `pr-review-toolkit:{code-reviewer,
   silent-failure-hunter, type-design-analyzer}` and produces findings.
2. The findings land in the PR description (or an attached review log).
3. Before merge, a human approver named in the PR's `PR-APPROVER:`
   trailer reviews the findings and either fixes them or records a
   deferral with justification.
4. The CODEOWNERS rule on `.claude/rules/` and `docs/playbooks/`
   forces the approver to come from the right team (platform / security
   / PM).

## When SoD is mandatory

| Regime | SoD required for | Why |
|---|---|---|
| **FedRAMP Moderate** | All changes to `.claude/`, `docs/playbooks/`, anything in scope of AC-5 | NIST 800-53 AC-5 is explicit |
| **SOC 2 — CC8.1** | All change-management activity | The trust services criteria require it |
| **PCI DSS** (if your project handles cards) | Code paths touching cardholder data | PCI 6.4.2 |
| **SOX / financial reporting** | Any code path producing financial figures | SOX §404 |
| **Banking / brokerage regulations** | Trade execution, settlement, custody code | Per-regulator (e.g. FINRA, FCA) |
| **HIPAA** _(strongly recommended, not strictly required)_ | Auth, audit, PHI-touching paths | §164.308(a)(3) workforce security |

## When SoD is optional

For non-regulated, internal-tools work — landing pages, dev tooling,
internal dashboards — SoD adds review latency without commensurate
risk reduction. Use the standard 6-gate review without the
`PR-APPROVER` trailer.

The default state of a project is "regulated work happens here";
explicit declaration is required to **opt out**. Put the opt-out in
your project's `CLAUDE.md` §N6 customisation so it's visible to every
reviewer.

## The `PR-APPROVER` trailer

In the PR description (last block), add:

```
PR-APPROVER: @alice
PR-APPROVER-TEAM: @{{PROJECT_SLUG}}-security
PR-APPROVER-ACK-COMMIT: <sha>
```

Meaning:

- `PR-APPROVER` — the human (not the agent that authored the code,
  not the agent that ran the review). Must have an entry in the
  CODEOWNERS for the touched paths.
- `PR-APPROVER-TEAM` — the team alias the approver represents.
  Required for FedRAMP / SOC2 evidence (proves the approver had the
  right role, not just a personal acknowledgement).
- `PR-APPROVER-ACK-COMMIT` — the commit SHA where the approver pushed
  their acknowledgement (typically the final review-fix commit, or
  a dedicated `chore: ack gate-4 findings` commit). This is the
  artifact an auditor cross-references against the JSONL audit log.

## How to record approvals

### Step 1 — Authorship is logged

When the implementation agent commits, `audit.sh` writes a
`PostToolUse` line to `docs/project/audit/YYYY-MM.jsonl` with the
`agent_id`, `subagent_type`, `task_id`, and `files_touched`. This is
the **author** record.

### Step 2 — Review findings are logged

When Gate 4 reviewers complete, their findings are committed to the
PR description (or attached as a review log file at
`docs/project/reviews/sprint-S<N>-<task-id>.md`). The audit hook
records the dispatch.

### Step 3 — Acknowledgement lands as PR-APPROVER

The human approver:

1. Reads the Gate 4 findings.
2. Either: fixes the findings (commits land on the branch), OR
   accepts the deferral (adds a `Deferred:` row to the backlog's Follow-ups section
   (`docs/project/backlog.md` `## Follow-ups`) with severity + reasoning).
3. Adds the `PR-APPROVER:` / `PR-APPROVER-TEAM:` /
   `PR-APPROVER-ACK-COMMIT:` trailer to the PR description.
4. Approves the PR through GitHub's review UI (so CODEOWNERS gate
   is satisfied).

### Step 4 — Merge

The branch protection rule requires:

- CODEOWNERS approval (the right team approved)
- Passing CI (`ai-workflow-validation.yml`)
- Required-status checks green

Merge proceeds. The audit trail now has: author dispatch → review
dispatch → reviewer findings → approver ack → merge commit. An
auditor can walk this chain end-to-end from `audit.jsonl` + PR
metadata + git log.

## What happens if no human approver is available

This is the edge case. If you can't find an approver for the work
within the sprint window:

- **Block the PR.** Do not merge. SoD violations are not "we'll fix
  it next sprint" — they're "this work waits for an approver."
- **Annotate the backlog's Follow-ups section** (`docs/project/backlog.md` `## Follow-ups`) with the PR + the blocking
  reason.
- **In the sprint retro**, surface the blockage as a process issue.
  Recurring SoD blockages mean the approver pool is too small;
  escalate the staffing.

## Mapping to CODEOWNERS

Your project's [`CODEOWNERS`](../../.github/CODEOWNERS) decides who
**can** approve. The `PR-APPROVER` trailer decides who **did**
approve. Both must agree for a regulated change to merge:

| Path touched | CODEOWNERS team | Typical `PR-APPROVER-TEAM` |
|---|---|---|
| `.claude/rules/*.md` | `@{{PROJECT_SLUG}}-platform @{{PROJECT_SLUG}}-security` | `@{{PROJECT_SLUG}}-security` |
| `.claude/hooks/**` | `@{{PROJECT_SLUG}}-platform` | `@{{PROJECT_SLUG}}-platform` |
| `docs/playbooks/**` | `@{{PROJECT_SLUG}}-platform` | `@{{PROJECT_SLUG}}-platform` |
| `docs/project/audit/**` | `@{{PROJECT_SLUG}}-security` | `@{{PROJECT_SLUG}}-security` |
| `docs/project/**` (general) | `@{{PROJECT_SLUG}}-pm` | `@{{PROJECT_SLUG}}-pm` |

## Related

- [`compliance-mapping.md`](./compliance-mapping.md) — SOC2 CC8.1,
  HIPAA §164.308(a)(3), ISO A.5.4, FedRAMP AC-5 all reference this
  pattern
- [`permission-profiles.md`](./permission-profiles.md) — restricted
  profile is the right starting baseline for regulated work
- [`secret-handling.md`](./secret-handling.md) — secret-touching
  changes are always regulated work (N6 applies)
- [`../../.github/CODEOWNERS`](../../.github/CODEOWNERS) — the
  team membership that gates merge
- [`../playbooks/post-delegation-review.md`](../playbooks/post-delegation-review.md)
  Gate 4 — what the reviewer findings look like that the approver
  acknowledges
