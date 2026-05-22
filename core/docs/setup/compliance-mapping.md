# Compliance Mapping

> Per-framework cross-walk from common controls to the AI-Workflows
> artifacts that **produce evidence for that control**. Hand this to
> an auditor with the relevant repo paths filled in.
>
> **What this is**: a starting point. Every control needs concrete
> evidence in your repo; this table tells you where that evidence is
> generated and where it lives. Where the table says "—", the control
> sits outside the AI-Workflows scope (e.g., physical access logs,
> background checks).
>
> **What this is NOT**: a certification. SOC2 / HIPAA / ISO / GDPR /
> FedRAMP need a human auditor to attest. This file is the mechanical
> bridge between auditor questions and template artifacts.

## How to read the tables

| Column | Meaning |
|---|---|
| Control | The clause from the framework (e.g. SOC2 CC6.1) |
| What it asks | One-sentence translation of the control |
| Evidence | What you show the auditor |
| Where it lives | Repo path that produces / stores that evidence |

## SOC 2 (Trust Services Criteria)

| Control | What it asks | Evidence | Where it lives |
|---|---|---|---|
| **CC1.4** | Workforce competence & accountability | Role-based agent definitions; named human approvers via CODEOWNERS | `.claude/agents/*.md`; `.github/CODEOWNERS`; `docs/setup/separation-of-duties.md` |
| **CC2.1** | Internal communication of policies | Auto-loaded rule files; non-negotiables in CLAUDE.md | `.claude/rules/brain-hot.md`; `CLAUDE.md` §N1–N6 |
| **CC2.3** | External communication (clients) | Sprint retros + release notes | `docs/spec/retros/sprint-S*.md`; `CHANGELOG.md` |
| **CC3.1** | Risk assessment process | Live mini-retros + sprint retros surface risks | `docs/spec/retros/sprint-S*-tasks.md`; `docs/spec/FOLLOWUPS.md` |
| **CC5.1** | Control activities through policy | The 10 A-rules + Phase Matrix | `.claude/rules/brain-hot.md`; `.claude/rules/phase-matrix.md` |
| **CC5.3** | Deployment of control activities | 6-gate post-delegation review | `docs/playbooks/post-delegation-review.md` |
| **CC6.1** | Logical access — restrict access | Permission profiles + allow-list | `.claude/settings.json`; `docs/setup/permission-profiles.md` |
| **CC6.2** | Logical access — register & authorize | Agent definitions + named tool allowlists | `.claude/agents/*.md` (each agent declares scope) |
| **CC6.3** | Logical access — modify & remove access | Soft-merge preserves allow-list edits + audit log | `docs/setup/settings-merge.md`; `docs/spec/audit/*.jsonl` |
| **CC6.6** | Logical access — system credentials | Secret redaction rule + PreToolUse hook | `docs/setup/secret-handling.md`; `.claude/hooks/secret-redact.sh` |
| **CC6.7** | Restrict transmission, movement, removal of data | Same secret redaction + agent egress controls | `.claude/hooks/secret-redact.sh`; permission profiles deny network egress patterns |
| **CC6.8** | Prevent / detect unauthorized software | Lint hook + audit trail of every agent invocation | `.claude/hooks/lint.sh`; `.claude/hooks/audit.sh`; `docs/spec/audit/*.jsonl` |
| **CC7.1** | System monitoring — detect anomalies | Audit JSONL ingested into SIEM (Splunk / Datadog / ELK) | `docs/spec/audit/*.jsonl`; `docs/setup/audit-trail.md` |
| **CC7.2** | Monitoring of system components | Same audit JSONL + observability mini-retros (A009) | `docs/spec/audit/*.jsonl`; `docs/spec/retros/sprint-S*-tasks.md` |
| **CC7.3** | Evaluate security events | Sprint retro reviews audit anomalies | `docs/spec/retros/sprint-S*.md` (Section "Audit findings") |
| **CC7.4** | Respond to security incidents | Failure-recovery playbook + retro action items | `docs/playbooks/post-delegation-review.md` (failure paths) |
| **CC8.1** | Change management — authorize changes | Design-doc-first (A005) + 6-gate review + CODEOWNERS | `docs/designs/sprint-S*/`; `docs/playbooks/post-delegation-review.md`; `.github/CODEOWNERS` |
| **CC9.1** | Risk mitigation — recovery | Integration-branch + worktree isolation playbook | `docs/setup/integration-branch-strategy.md`; `docs/playbooks/parallel-conflict-prevention.md` |
| **CC9.2** | Vendor / third-party risk management | Preset boundaries declare external dependencies; supply-chain lint in CI | `presets/<name>/docs/`; `.github/workflows/ai-workflow-validation.yml` |

## HIPAA (45 CFR Part 164)

| Control | What it asks | Evidence | Where it lives |
|---|---|---|---|
| **§164.308(a)(1)(ii)(A)** | Risk analysis | Sprint retro + FOLLOWUPS register | `docs/spec/retros/sprint-S*.md`; `docs/spec/FOLLOWUPS.md` |
| **§164.308(a)(1)(ii)(B)** | Risk management | Live mini-retros (A009) + sprint close audit (A017) | `docs/spec/retros/sprint-S*-tasks.md` |
| **§164.308(a)(2)** | Assigned security responsibility | CODEOWNERS + agent role definitions | `.github/CODEOWNERS`; `.claude/agents/*.md` |
| **§164.308(a)(3)** | Workforce security | Permission profiles + Separation of Duties (N6) | `docs/setup/permission-profiles.md`; `docs/setup/separation-of-duties.md` |
| **§164.308(a)(4)** | Information access management | Permission profiles allow-list | `.claude/settings.json` |
| **§164.308(a)(5)** | Security awareness & training | Onboarding tour + rules auto-load | `docs/getting-started-tour.md`; `.claude/rules/brain-hot.md` |
| **§164.308(a)(6)** | Security incident procedures | Failure paths in 6-gate playbook | `docs/playbooks/post-delegation-review.md` |
| **§164.308(a)(7)** | Contingency plan | Integration-branch strategy + backup-on-install behavior | `docs/setup/integration-branch-strategy.md`; `install.sh` (backup logic) |
| **§164.308(a)(8)** | Evaluation | Sprint retro audit step (A017) | `docs/spec/retros/sprint-S*.md` |
| **§164.310(a)** | Physical safeguards — facility access | — _(out of scope — physical infra)_ |
| **§164.310(c)** | Workstation security | Permission profiles + secret redaction enforce least privilege at the workstation | `.claude/settings.json`; `.claude/hooks/secret-redact.sh` |
| **§164.310(d)** | Device & media controls | Secret redaction + `.gitignore` discipline | `docs/setup/secret-handling.md` |
| **§164.312(a)(1)** | Access controls (technical) | Permission profiles | `.claude/settings.json` |
| **§164.312(a)(2)(iv)** | Encryption / decryption | sops + age recipe (where applicable) | `docs/setup/secret-handling.md` |
| **§164.312(b)** | Audit controls | Agent audit JSONL | `docs/spec/audit/*.jsonl` |
| **§164.312(c)(1)** | Integrity (PHI not altered improperly) | 6-gate review Gate 1 (Inspect) + Gate 4 (Quality) | `docs/playbooks/post-delegation-review.md` |
| **§164.312(d)** | Person / entity authentication | OIDC + workload identity recipes | `docs/setup/secret-handling.md` (CI section) |
| **§164.312(e)(1)** | Transmission security | Network egress denylist; no secrets in tool prompts | `docs/setup/secret-handling.md`; permission profiles |
| **§164.314(a)** | Business associate contracts | — _(legal — outside template)_ |
| **§164.316(a)** | Policies & procedures | This file + the brain-hot rules | `.claude/rules/brain-hot.md`; `docs/setup/*` |
| **§164.316(b)(1)** | Documentation | Design docs, retros, FOLLOWUPS, sprint files | `docs/designs/`; `docs/spec/` |
| **§164.316(b)(2)(iii)** | Documentation availability | All in repo; readable to anyone with checkout | (entire `docs/` tree) |

## ISO/IEC 27001 (Annex A controls)

| Control | What it asks | Evidence | Where it lives |
|---|---|---|---|
| **A.5.1** | Policies for information security | Brain-hot.md A-rules + CLAUDE.md non-negotiables | `.claude/rules/brain-hot.md`; `CLAUDE.md` |
| **A.5.2** | Roles & responsibilities | Agent definitions + CODEOWNERS | `.claude/agents/*.md`; `.github/CODEOWNERS` |
| **A.5.7** | Threat intelligence | Lessons (L###) library; sprint retros | `.claude/rules/brain-hot.md` (L-section) |
| **A.5.10** | Acceptable use of information | Permission profiles + secret-handling | `docs/setup/permission-profiles.md`; `docs/setup/secret-handling.md` |
| **A.5.12** | Classification of information | Sensitive-var regex + secret redaction hook | `.claude/hooks/secret-redact.sh` |
| **A.5.15** | Access control | Permission profiles | `.claude/settings.json` |
| **A.5.17** | Authentication information (secrets) | Secret handling guide + redaction hook | `docs/setup/secret-handling.md` |
| **A.5.23** | Cloud service use | OIDC + workload identity recipes | `docs/setup/secret-handling.md` |
| **A.5.30** | ICT readiness for business continuity | Integration-branch + worktree isolation | `docs/setup/integration-branch-strategy.md` |
| **A.6.1** | Screening | — _(HR — outside template)_ |
| **A.6.3** | Awareness, education, training | Onboarding tour + rule auto-load | `docs/getting-started-tour.md` |
| **A.6.6** | Confidentiality / NDA | — _(legal — outside template)_ |
| **A.8.2** | Privileged access rights | Restricted/standard/permissive profile selection | `docs/setup/permission-profiles.md` |
| **A.8.3** | Information access restriction | Permission profiles + agent scope | `.claude/settings.json`; `.claude/agents/*.md` |
| **A.8.4** | Access to source code | CODEOWNERS gates `.claude/` and `docs/playbooks/` | `.github/CODEOWNERS` |
| **A.8.5** | Secure authentication | Secret handling — workload identity recipes | `docs/setup/secret-handling.md` |
| **A.8.7** | Protection against malware | Lint hook + secret redaction + CI placeholder lint | `.claude/hooks/lint.sh`; `.claude/hooks/secret-redact.sh`; `.github/workflows/ai-workflow-validation.yml` |
| **A.8.8** | Management of technical vulnerabilities | 6-gate review Gate 4 (Quality reviewers) | `docs/playbooks/post-delegation-review.md` |
| **A.8.15** | Logging | Agent audit JSONL | `docs/spec/audit/*.jsonl` |
| **A.8.16** | Monitoring activities | Audit JSONL → SIEM | `docs/spec/audit/*.jsonl`; `docs/setup/audit-trail.md` |
| **A.8.21** | Network security | OIDC + permission profiles + secret redaction | `docs/setup/secret-handling.md` |
| **A.8.24** | Use of cryptography | sops + age recipe | `docs/setup/secret-handling.md` |
| **A.8.25** | Secure development life cycle | Workflow-master pipeline + Phase Matrix | `docs/setup/workflow-master.md`; `.claude/rules/phase-matrix.md` |
| **A.8.26** | Application security requirements | Phase Matrix Phase 7 (Security review trigger) | `.claude/rules/phase-matrix.md` |
| **A.8.27** | Secure system architecture | Preset boundary rules (e.g. hex direction, FSD layers) | `presets/<name>/rules/` |
| **A.8.28** | Secure coding | Programming-fundamentals + brain-hot A001/A002/A010 | `.claude/rules/programming-fundamentals.md`; `.claude/rules/brain-hot.md` |
| **A.8.29** | Security testing | Phase Matrix Phase 4 (TDD) + Phase 7 (security review) | `.claude/rules/phase-matrix.md` |
| **A.8.30** | Outsourced development | — _(contract — outside template)_ |
| **A.8.31** | Separation of dev / test / prod | Integration-branch strategy | `docs/setup/integration-branch-strategy.md` |
| **A.8.32** | Change management | Design-doc-first (A005) + 6-gate review | `docs/designs/`; `docs/playbooks/post-delegation-review.md` |
| **A.12** | Operations security | Audit hook + lint hook + secret redaction hook | `.claude/hooks/*.sh` |
| **A.14** | System acquisition, development & maintenance | Workflow-master + preset architectural rules | `docs/setup/workflow-master.md`; `presets/*/rules/` |
| **A.16** | Information security incident management | Failure paths in 6-gate playbook + FOLLOWUPS | `docs/playbooks/post-delegation-review.md`; `docs/spec/FOLLOWUPS.md` |

## GDPR (EU 2016/679)

| Control | What it asks | Evidence | Where it lives |
|---|---|---|---|
| **Art. 5(1)(a)** | Lawfulness, fairness, transparency | Design-doc-first surfaces purpose before code lands | `docs/designs/sprint-S*/` |
| **Art. 5(1)(b)** | Purpose limitation | Discovery doc declares the use; sprint retro confirms scope | `docs/spec/discovery/`; `docs/spec/retros/sprint-S*.md` |
| **Art. 5(1)(c)** | Data minimisation | 6-gate review Gate 4 (type-design-analyzer flags over-broad types) | `docs/playbooks/post-delegation-review.md` |
| **Art. 5(1)(d)** | Accuracy | Zero-bug discipline (A002) + verification before completion (A003) | `.claude/rules/brain-hot.md` |
| **Art. 5(1)(e)** | Storage limitation | sprint-S<N>-tasks retros + STATUS-archive lifecycle | `docs/spec/retros/`; `docs/spec/STATUS-archive.md` |
| **Art. 5(1)(f)** | Integrity & confidentiality | Secret redaction hook + permission profiles | `.claude/hooks/secret-redact.sh`; `docs/setup/permission-profiles.md` |
| **Art. 5(2)** | Accountability | Audit JSONL + CODEOWNERS + named approvers | `docs/spec/audit/*.jsonl`; `.github/CODEOWNERS` |
| **Art. 25** | Data protection by design | Brain-hot A005 (design-doc-first) + Phase 7 (security trigger) | `.claude/rules/brain-hot.md`; `.claude/rules/phase-matrix.md` |
| **Art. 25(2)** | Data protection by default | Permission profile defaults to `standard`; restricted available | `install.sh` (default profile); `docs/setup/permission-profiles.md` |
| **Art. 28(3)** | Processor obligations / sub-processors | — _(legal — outside template)_ |
| **Art. 30** | Records of processing activities | Sprint files + discovery docs + design docs constitute the activity record | `docs/spec/sprints/`; `docs/spec/discovery/`; `docs/designs/` |
| **Art. 32(1)(a)** | Pseudonymisation / encryption | sops + age recipe | `docs/setup/secret-handling.md` |
| **Art. 32(1)(b)** | Ongoing confidentiality, integrity, availability | Permission profiles + 6-gate review + integration-branch strategy | `.claude/settings.json`; `docs/playbooks/post-delegation-review.md`; `docs/setup/integration-branch-strategy.md` |
| **Art. 32(1)(d)** | Regular testing of effectiveness | Sprint retro audit; CI placeholder lint | `docs/spec/retros/sprint-S*.md`; `.github/workflows/ai-workflow-validation.yml` |
| **Art. 33** | Breach notification | FOLLOWUPS + sprint retro action items capture incidents | `docs/spec/FOLLOWUPS.md`; `docs/spec/retros/sprint-S*.md` |
| **Art. 35** | Data Protection Impact Assessment (DPIA) | Discovery doc + design doc for high-risk processing | `docs/spec/discovery/`; `docs/designs/sprint-S*/` |

## FedRAMP Moderate (NIST SP 800-53 baseline)

Selected families. Full baseline contains ~325 controls; this is the
subset that AI-Workflows artifacts directly produce evidence for.

### AC — Access Control

| Control | What it asks | Evidence | Where it lives |
|---|---|---|---|
| **AC-2** | Account management | Agent definitions + CODEOWNERS | `.claude/agents/*.md`; `.github/CODEOWNERS` |
| **AC-3** | Access enforcement | Permission profiles allow / deny | `.claude/settings.json` |
| **AC-5** | Separation of duties | N6 + separation-of-duties doc | `CLAUDE.md` §N6; `docs/setup/separation-of-duties.md` |
| **AC-6** | Least privilege | Profile = `restricted` baseline; escalate per task | `docs/setup/permission-profiles.md` |
| **AC-6(9)** | Audit use of privileged functions | Agent audit JSONL | `docs/spec/audit/*.jsonl` |
| **AC-17** | Remote access | OIDC + workload identity for CI / remote runners | `docs/setup/secret-handling.md` |

### AU — Audit & Accountability

| Control | What it asks | Evidence | Where it lives |
|---|---|---|---|
| **AU-2** | Audit events (what to record) | Audit hook records every Agent dispatch + SubagentStop | `.claude/hooks/audit.sh`; `docs/spec/audit/*.jsonl` |
| **AU-3** | Content of audit records | JSONL schema includes ts, event, tool, agent_id, subagent_type, task_id, files_touched, reason | `docs/setup/audit-trail.md` |
| **AU-6** | Audit review, analysis & reporting | Sprint retro reviews audit anomalies | `docs/spec/retros/sprint-S*.md` (audit findings section) |
| **AU-9** | Protection of audit information | `docs/spec/audit/` is git-tracked + checksummed at sprint close | `docs/spec/audit/*.jsonl` |
| **AU-12** | Audit record generation | Hook fires on every PostToolUse(Agent) + SubagentStop | `.claude/hooks/audit.sh` |

### CM — Configuration Management

| Control | What it asks | Evidence | Where it lives |
|---|---|---|---|
| **CM-2** | Baseline configuration | Install manifest captures version + profile + presets | `.ai-workflows/manifest.json` |
| **CM-3** | Configuration change control | Design-doc-first (A005) + 6-gate review | `docs/designs/`; `docs/playbooks/post-delegation-review.md` |
| **CM-4** | Security impact analysis | Phase 7 (security review trigger) in phase matrix | `.claude/rules/phase-matrix.md` |
| **CM-5** | Access restrictions for change | CODEOWNERS gates `.claude/`, `docs/playbooks/`, `docs/spec/` | `.github/CODEOWNERS` |
| **CM-6** | Configuration settings | Permission profile templates | `core/.claude/settings.<profile>.json.tmpl` |
| **CM-7** | Least functionality | `restricted` profile allow-list = read-only | `docs/setup/permission-profiles.md` |
| **CM-8** | System component inventory | Install manifest + workflow-validation CI | `.ai-workflows/manifest.json`; `.github/workflows/ai-workflow-validation.yml` |

### SI — System & Information Integrity

| Control | What it asks | Evidence | Where it lives |
|---|---|---|---|
| **SI-2** | Flaw remediation | Zero-bug discipline (A002) + FOLLOWUPS | `.claude/rules/brain-hot.md`; `docs/spec/FOLLOWUPS.md` |
| **SI-3** | Malicious code protection | Lint hook + secret redaction hook + CI scan | `.claude/hooks/*.sh`; `.github/workflows/ai-workflow-validation.yml` |
| **SI-4** | System monitoring | Audit JSONL ingested into SIEM | `docs/spec/audit/*.jsonl` |
| **SI-7** | Software, firmware, information integrity | Lint hook + 6-gate review Gate 2 (Build+Test) | `.claude/hooks/lint.sh`; `docs/playbooks/post-delegation-review.md` |
| **SI-10** | Information input validation | 6-gate Gate 4 (type-design-analyzer + silent-failure-hunter) | `docs/playbooks/post-delegation-review.md` |
| **SI-11** | Error handling | Programming-fundamentals rule 4 + silent-failure-hunter reviewer | `.claude/rules/programming-fundamentals.md` |

## How to use this file with an auditor

1. **Pick the framework you're being audited against.**
2. For each control, open the cited path and **show the actual file**
   (not a screenshot, not a description — the live file in the repo).
3. For controls marked `—` _(outside template)_, point to your
   organisation's policy document; AI-Workflows doesn't substitute for
   HR, legal, or physical-infra controls.
4. **Sprint retros are critical** — many controls reference retros as
   the place periodic reviews happen. If you don't write them, you
   lose the evidence.
5. **The audit JSONL is non-negotiable.** Every framework above
   credits the audit hook. If you've disabled the hook, that's a
   finding before the auditor even arrives.

## Related

- [`secret-handling.md`](./secret-handling.md) — the credential
  controls referenced under SOC2 CC6.6, HIPAA §164.312(a)(2)(iv),
  ISO A.5.17, GDPR Art. 32, FedRAMP IA-5
- [`permission-profiles.md`](./permission-profiles.md) — the access
  controls referenced under SOC2 CC6.1, ISO A.8.2, FedRAMP AC-3/AC-6
- [`separation-of-duties.md`](./separation-of-duties.md) — SOC2 CC8.1,
  ISO A.5.4, FedRAMP AC-5
- [`audit-trail.md`](./audit-trail.md) — audit JSONL schema +
  SIEM integration recipes
- [`../../.github/workflows/ai-workflow-validation.yml`](../../.github/workflows/ai-workflow-validation.yml)
  — the CI gate that backs many of the configuration-management
  controls
