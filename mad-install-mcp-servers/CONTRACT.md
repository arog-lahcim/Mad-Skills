# Contract: mad-install-mcp-servers

Stable facts for agents **editing** this skill. Install-time agents follow `SKILL.md` only.

## Scope

- Prefer GitHub, GitLab, Atlassian (`mcp-atlassian`), and Notion only.
- Stay generic: no org-specific hosts, tokens, or project names in templates.
- Triple host: Cursor (`~/.cursor/mcp.json`), Claude Desktop
  (`claude_desktop_config.json`), Hermes Agent (`~/.hermes/config.yaml` →
  `mcp_servers`). Project `.cursor/mcp.json` only when the user asks.
- Env prefixes stay independent: `CURSOR_*` vs `CLAUDE_*` vs `HERMES_*`.
  Never merge them.

## Sources of truth

| Concern | File |
|---------|------|
| Cursor MCP server templates | [mcp.cursor.json](mcp.cursor.json) |
| Claude Desktop MCP server templates | [mcp.claude.json](mcp.claude.json) |
| Hermes Agent MCP server templates | [mcp.hermes.json](mcp.hermes.json) |
| Required env var names + stub append behavior | [scripts/ensure-env-exports.sh](scripts/ensure-env-exports.sh) (`CURSOR_VARS` / `CLAUDE_VARS` / `HERMES_VARS`, `--host`) |
| Install / check / prompt workflow | [SKILL.md](SKILL.md) |
| Connectivity probes (Cursor/Claude) | `mad-check-connections` |

When adding or renaming an env var: update the matching `*_VARS` array, the host
template `${…}` / `${env:…}` refs, and the SKILL.md env table together.

When adding or changing a server: edit each host template that should carry it;
do not invent packages or URLs only in prose. Keep hosts in sync on *which*
servers exist, even when shapes differ (HTTP vs stdio, JSON vs Hermes YAML).

Hermes template stays JSON (`mcpServers`) for edit parity; install writes YAML
`mcp_servers` in `~/.hermes/config.yaml`. Hermes secrets prefer stubs in
`~/.hermes/.env`.

## Behavioral invariants

- Do not overwrite an existing target server key unless the user directly asks to update/replace/reset it.
- Preserve unrelated server entries in the target (and non-MCP keys in Hermes YAML).
- Never write secret values into config or env files; stubs are empty only.
- Never append env stubs without the user choosing a file path (`suggest` → prompt → `append`).
- Do not edit or overwrite this skill’s templates during an install run.
- Post-install: Cursor/Claude → **mad-check-connections**; Hermes → `/reload-mcp`
  (and OAuth login when needed).

## Related

- Missing / misconfigured MCP in a Cursor/Claude connection report → point at this skill (`mad-check-connections`).
