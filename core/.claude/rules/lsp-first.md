# LSP-First Code Navigation (auto-loaded · MANDATORY)

Use LSP tools for **semantic** code understanding. Fall back to grep / glob
for **text** search. Applies to the main session, every subagent, and
every reviewer.

## Decision matrix

| Need | Best tool |
|---|---|
| Type info / method list for a symbol | LSP `hover` |
| Jump to definition (cross-file) | LSP `goToDefinition` |
| All usages of a symbol | LSP `findReferences` |
| Interface → implementations | LSP `goToImplementation` |
| Call hierarchy | LSP `incomingCalls` / `outgoingCalls` |
| File structure overview | LSP `documentSymbol` |
| Search symbol by name across workspace | LSP `workspaceSymbol` |
| Regex / pattern / string in configs / YAML / JSON / Markdown | Grep |
| Cross-language search (e.g. backend ↔ frontend referring to the same event topic) | Grep |
| File discovery by name pattern | Glob |
| First exploration of an unknown service | Grep / Glob first (LSP needs file + line) |

**Rule of thumb:** understand *what something IS* → LSP. Find *where a
string appears* → Grep.

## Fallback cascade

```
1. Built-in LSP (hover, documentSymbol, diagnostics — always works)
      ↓ if empty
2. MCP lsp-bridge (goToDefinition, findReferences, workspaceSymbol — needs proper init)
      ↓ if still empty
3. Grep / Glob
```

Do NOT retry the same LSP operation more than once per level. If
built-in LSP returns empty for `goToDefinition` / `findReferences` → go
directly to MCP lsp-bridge. If that also fails → grep and move on.

## Reliability

**Always works** (built-in LSP): `hover`, `documentSymbol`,
`incomingCalls` / `outgoingCalls`, `diagnostics`.

**Needs warm-up** (prefer MCP lsp-bridge): `goToDefinition`,
`findReferences`, `goToImplementation`, `workspaceSymbol`.

## Cross-stack questions

LSP usually does NOT cross language boundaries. For backend ↔ frontend
or service ↔ service, use Grep + the contract files (e.g.
`contracts/events/*.json`, `contracts/openapi/*.yaml`) as the bridge.

## Stale process cleanup

If LSP starts returning incorrect data:

```bash
pkill -f gopls       # for Go
pkill -f tsserver    # for TypeScript
# then restart the editor / re-init
```

A common failure mode: a long-lived `gopls` process holds onto a stale
view after a composition-root rewire. Symptom: diagnostics flag imports
the build accepts. Fix: kill + re-init. If diagnostics look wrong, also
run the real build (`make build` / `go build ./...`) to confirm actual
compile state.

## Related

- Built-in LSP is via the harness's diagnostics + hover.
- MCP lsp-bridge: see `.claude/.mcp.json` if you configured one.
- For deep navigation, the global guide at `~/.claude/docs/lsp-detail.md`
  has the full tool-signature reference (read on demand).
