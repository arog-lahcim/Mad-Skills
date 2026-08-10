# Contract: mad-install-mcp-servers

Stable facts for agents **editing** this skill. Install-time agents follow `SKILL.md` only.

## Scope

- Prefer GitHub, GitLab, Atlassian (`mcp-atlassian`), and Notion only.
- Stay generic: no org-specific hosts, tokens, or project names in templates.
- Default target is user-global `~/.cursor/mcp.json`. Project `.cursor/mcp.json` only when the user asks.

## Sources of truth

| Concern | File |
|---------|------|
| MCP server templates (`mcpServers` shape) | [mcp.json](mcp.json) |
| Required env var names + stub append behavior | [scripts/ensure-env-exports.sh](scripts/ensure-env-exports.sh) (`REQUIRED_VARS`) |
| Install / check / prompt workflow | [SKILL.md](SKILL.md) |
| Connectivity probes after install | `mad-check-connections` |

When adding or renaming an env var: update `REQUIRED_VARS`, the skill `mcp.json` `${env:…}` refs, and the SKILL.md env table together.

When adding or changing a server: edit skill `mcp.json` first; do not invent packages or URLs only in prose.

## Behavioral invariants

- Do not overwrite an existing target server key unless the user directly asks to update/replace/reset it.
- Preserve unrelated `mcpServers` entries in the target.
- Never write secret values into config or env files; stubs are empty `export NAME=` only.
- Never append env stubs without the user choosing a file path (`suggest` → prompt → `append`).
- Do not edit or overwrite this skill’s [mcp.json](mcp.json) during an install run.
- Post-install verification always goes through **mad-check-connections**.

## Related

- Missing / misconfigured MCP in a connection report → point at this skill (`mad-check-connections`).
