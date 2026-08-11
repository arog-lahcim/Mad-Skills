# Contract: mad-install-mcp-servers

Stable facts for agents **editing** this skill. Install-time agents follow `SKILL.md` only.

## Scope

- Prefer GitHub, GitLab, Atlassian (`mcp-atlassian`), and Notion only.
- Stay generic: no org-specific hosts, tokens, or project names in templates.
- Dual host: Cursor (`~/.cursor/mcp.json`) and Claude Desktop
  (`claude_desktop_config.json`). Project `.cursor/mcp.json` only when the user asks.
- Env prefixes stay independent: `CURSOR_*` vs `CLAUDE_*`. Never merge them.

## Sources of truth

| Concern | File |
|---------|------|
| Cursor MCP server templates | [mcp.cursor.json](mcp.cursor.json) |
| Claude Desktop MCP server templates | [mcp.claude.json](mcp.claude.json) |
| Required env var names + stub append behavior | [scripts/ensure-env-exports.sh](scripts/ensure-env-exports.sh) (`CURSOR_VARS` / `CLAUDE_VARS`, `--host`) |
| Install / check / prompt workflow | [SKILL.md](SKILL.md) |
| Connectivity probes after install | `mad-check-connections` |

When adding or renaming an env var: update the matching `*_VARS` array, the host
template `${…}` refs, and the SKILL.md env table together.

When adding or changing a server: edit the host template JSON first; do not invent
packages or URLs only in prose. Keep Cursor and Claude templates in sync on
*which* servers exist, even when shapes differ (HTTP vs stdio).

## Behavioral invariants

- Do not overwrite an existing target server key unless the user directly asks to update/replace/reset it.
- Preserve unrelated `mcpServers` entries in the target.
- Never write secret values into config or env files; stubs are empty `export NAME=` only.
- Never append env stubs without the user choosing a file path (`suggest` → prompt → `append`).
- Do not edit or overwrite this skill’s templates during an install run.
- Post-install verification always goes through **mad-check-connections**.

## Related

- Missing / misconfigured MCP in a connection report → point at this skill (`mad-check-connections`).
