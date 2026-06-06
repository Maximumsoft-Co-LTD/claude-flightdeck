// @ts-nocheck — runs under the Claude Code Workflow runtime (top-level
// `export const meta` + `await`/`return` is wrapped by the runtime, not a plain
// ES module), so standalone type-checking reports false positives. Not type-checked.
//
// fd-understand-codebase — parallel read-only Explore → one architecture map.
//
// Why this exists: building the architecture orientation a new agent needs
// (areas, boundaries, stack, integrations, conventions) is a breadth-first,
// read-heavy, disjoint task — the ideal shape for fan-out. This is the reusable
// primitive `/onboard` will lean on for large repos (see ./README.md "Deferred").
//
// Returns structured data and writes NOTHING — the caller (a skill) decides where
// to persist (e.g. docs/setup/codebase-orientation.md). Placeholder-free.

export const meta = {
  name: 'fd-understand-codebase',
  description: 'Parallel read-only Explore over codebase areas → a structured architecture map (returns data, writes nothing)',
  phases: [
    { title: 'Map', detail: 'discover the top-level source areas' },
    { title: 'Read', detail: 'one Explore agent per area, in parallel' },
    { title: 'Synthesize', detail: 'merge per-area maps into one architecture overview' },
  ],
}

const AREAS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    areas: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          path: { type: 'string' },
          purpose: { type: 'string' },
        },
        required: ['path'],
      },
    },
  },
  required: ['areas'],
}

const AREA_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    responsibility: { type: 'string' },
    entryPoints: { type: 'array', items: { type: 'string' } },
    keyTypes: { type: 'array', items: { type: 'string' } },
    boundaries: { type: 'string', description: 'internal layering / what it may and may not import' },
    integrations: { type: 'array', items: { type: 'string' }, description: 'db, queue, http, 3rd-party' },
    testLayout: { type: 'string' },
    idioms: { type: 'string', description: 'naming / error-handling / style conventions observed' },
  },
  required: ['responsibility'],
}

const MAP_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    systemPurpose: { type: 'string' },
    areas: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          area: { type: 'string' },
          responsibility: { type: 'string' },
          stack: { type: 'string' },
          integrations: { type: 'string' },
        },
        required: ['area', 'responsibility'],
      },
    },
    crossCuttingBoundaries: { type: 'string' },
    conventions: { type: 'string', description: 'what a new engineer must follow' },
  },
  required: ['systemPurpose', 'areas'],
}

// Stage 1 — discover areas (unless the caller supplied args.areas)
phase('Map')
let areas = (args && args.areas) || null
if (!areas) {
  const disc = await agent(
    `List the top-level source areas of this repo (services, packages, apps, major source dirs).
     Ignore vendored / build / node_modules / .git. Return up to 12 areas, each with a one-line purpose.`,
    { label: 'map:areas', schema: AREAS_SCHEMA, agentType: 'Explore' },
  )
  areas = (disc.areas || []).map((a) => a.path)
}

// Stage 2 — read each area in parallel (read-only)
phase('Read')
const maps = await parallel(
  areas.map((area) => () =>
    agent(
      `Explore the area \`${area}\`. Report its responsibility, entry points, key types, internal
       layering/boundaries, external integrations (db, queue, http, 3rd-party), test layout, and the
       naming/error/style idioms you observe. Read representative files only — do not read everything.`,
      { label: `read:${area}`, phase: 'Read', schema: AREA_SCHEMA, agentType: 'Explore' },
    ).then((m) => ({ area, ...m })),
  ),
)

// Stage 3 — synthesize one overview (returned to the caller; this workflow
// writes nothing — the calling skill decides where to persist).
phase('Synthesize')
log(`fd-understand-codebase: mapped ${areas.length} area(s)`)
return await agent(
  `Merge these per-area maps into ONE architecture overview: the system's purpose, an area table
   (area | responsibility | stack | integrations), the cross-cutting boundaries, and the conventions a
   new engineer must follow. Be concrete and concise. Per-area maps: ${JSON.stringify(maps.filter(Boolean))}`,
  { label: 'synthesize:map', schema: MAP_SCHEMA },
)
