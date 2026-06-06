// @ts-nocheck — runs under the Claude Code Workflow runtime (top-level
// `export const meta` + `await`/`return` is wrapped by the runtime, not a plain
// ES module), so standalone type-checking reports false positives. Not type-checked.
//
// fd-review-changes — Workflow-backed adversarial review of a diff.
//
// Why this exists: at-scale review (large diff / many files / pre-merge audit)
// benefits from parallel breadth + adversarial verification — find candidate
// issues across dimensions, then make each finding survive independent skeptics
// before it is reported. This is the substrate behind `/review ultra`.
//
// RIGOR SEAM (do not remove): this workflow AUGMENTS the 6-gate, it does NOT
// replace it. It returns a high-confidence *findings list*, never a merge
// verdict. The orchestrator still re-runs build/test (Gate 2) and owns the merge
// decision. See ../rules/sub-agent-workflow.md §1.6 and ./README.md.
//
// Invoked by core/.claude/skills/review/SKILL.md §5. Placeholder-free + writes
// nothing (the skill writes the report) so it ships to every install unchanged.

export const meta = {
  name: 'fd-review-changes',
  description: 'Review a diff across dimensions and adversarially verify each finding (augments the 6-gate; returns findings, not a merge verdict)',
  phases: [
    { title: 'Review', detail: 'one read-only agent per dimension finds candidate issues in the diff' },
    { title: 'Verify', detail: 'each finding is refuted by 3 perspective-diverse skeptics; survives if <2 refute' },
  ],
}

const base = (args && args.base) || 'HEAD~1'

// Dimensions mirror the project's review lenses (Gate 4b quality + Phase-7
// security + boundary). Override via args.dimensions.
const DIMENSIONS = (args && args.dimensions) || [
  { key: 'bugs', lens: 'correctness, logic errors, unhandled edge cases, off-by-one, null/undefined' },
  { key: 'security', lens: 'Phase-7 triggers — injection, authN/Z (IDOR/privilege), secrets/PII in logs, weak crypto, deserialization, SSRF, and any new manifest dependency (slopsquatting: confirm it exists + is the intended package)' },
  { key: 'types', lens: 'type design, nullability, making illegal states unrepresentable, contract drift' },
  { key: 'tests', lens: 'missing coverage for the change, test theater (asserting mocks/tautologies), happy-path-only' },
  { key: 'perf', lens: 'accidentally-quadratic loops, N+1 queries, unbounded growth, needless allocation' },
  { key: 'boundary', lens: 'architecture/convention boundary violations vs .claude/rules/code-style.md and area CLAUDE.md' },
]

const FINDINGS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          title: { type: 'string' },
          file: { type: 'string' },
          line: { type: 'string', description: 'line or range, e.g. "42" or "42-58"' },
          severity: { type: 'string', enum: ['P1', 'P2', 'P3'] },
          evidence: { type: 'string', description: 'the concrete source→sink / reachable path, not a guess' },
          fix: { type: 'string' },
        },
        required: ['title', 'file', 'severity', 'evidence'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string' },
  },
  required: ['refuted', 'reason'],
}

// pipeline: each dimension flows find → verify independently (no barrier) — a
// dimension's findings start verifying while other dimensions are still finding.
const perDimension = await pipeline(
  DIMENSIONS,
  // Stage 1 — FIND (read-only Explore agent, one per dimension)
  d => agent(
    `Review ONLY the diff \`git diff ${base}...HEAD\` for the **${d.key}** dimension (${d.lens}).
     Read the changed files for context first. Report concrete, reachable findings with file:line,
     the evidence (source→sink / caller path), and a concrete fix. Prefer FEWER, higher-confidence
     findings — no speculative or pure-style nits. If nothing real, return an empty findings list.`,
    { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS_SCHEMA, agentType: 'Explore' },
  ),
  // Stage 2 — VERIFY (3 perspective-diverse skeptics refute each finding)
  (review, d) => parallel(
    (review.findings || []).map(f => () =>
      parallel(['correctness', 'reachability', 'spec'].map(angle => () =>
        agent(
          `Adversarially REFUTE this ${d.key} finding through the **${angle}** lens. Try to prove it is
           NOT a real, reachable defect — already handled, misread code, no attacker/caller path, or out
           of scope for this diff. Default refuted=true if you cannot establish a concrete path.
           Finding: ${JSON.stringify(f)}`,
          { label: `verify:${d.key}:${angle}`, phase: 'Verify', schema: VERDICT_SCHEMA },
        ),
      )).then((votes) => {
        const refutes = votes.filter(Boolean).filter((v) => v.refuted).length
        // survives only if a majority FAILS to refute (fewer than 2 of 3 refute)
        return { ...f, dimension: d.key, confirmed: refutes < 2, refutes }
      }),
    ),
  ),
)

const confirmed = perDimension.flat().filter(Boolean).filter((f) => f.confirmed)
const dropped = perDimension.flat().filter(Boolean).filter((f) => !f.confirmed).length
log(`fd-review-changes: ${confirmed.length} confirmed / ${dropped} refuted, across ${DIMENSIONS.length} dimensions (base ${base})`)

return { base, dimensions: DIMENSIONS.map((d) => d.key), confirmed }
