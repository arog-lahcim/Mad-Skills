---
name: mad-check-connections
description: >-
  Probe MCP auth for GitLab, GitHub, Jira, and Notion and emit a simple
  connection report. Use when the user asks to check connections, test MCP
  auth, verify integrations, diagnose missing GitLab/GitHub/Jira/Notion
  access, or run mad-check-connections.
---

# Check connections

Verify the agent can reach the four required MCP services and report the result.

If the active host is ambiguous, ask once: **Cursor**, **Claude Desktop**, or
**Hermes Agent**.

## Services under test

| Service | MCP server id (typical) | Probe |
|---------|-------------------------|--------|
| GitHub | `user-github` / `github` | `get_me` |
| GitLab | `user-gitlab` / `gitlab` | `get_current_user` |
| Jira | `user-mcp-atlassian` / `mcp-atlassian` | `jira_get_all_projects` (`include_archived: false`) |
| Notion | `user-notion` / `notion` | `notion-get-users` (`user_id: "self"`) |

### Cursor (agent MCP introspection available)

Resolve the real server id with `GetMcpTools` (pattern search or catalog) before
calling tools. Prefer the smallest whoami-style probe above; do not create, edit,
or delete anything.

### Claude Desktop (no agent-side MCP probe API)

Do **not** invent passing statuses. When running inside Claude Desktop (or when
`GetMcpTools` / `mcp_auth` are unavailable):

1. Confirm preferred servers were merged into `claude_desktop_config.json` (see
   **mad-install-mcp-servers** / [mcp.claude.json](../mad-install-mcp-servers/mcp.claude.json)).
2. Confirm the user fully quit and relaunched Claude Desktop after config/env changes.
3. Report each service as:
   - `:white_circle: missing` — server key absent from config
   - `:boom: error` — config present but user reports load failure / logs show startup errors
   - `:closed_lock_with_key: needsAuth` — connector/OAuth still required (Notion, etc.)
   - Otherwise ask the user to trigger a tiny read-only action in chat that would
     use that MCP; only then mark `:white_check_mark: ok` or `:x: fail` from the observed result
4. Prefer naming expected `CLAUDE_*` env vars when tokens look unset.

### Hermes Agent (no Cursor MCP probe API)

Do **not** invent Cursor-style probes. When the host is Hermes:

1. Confirm preferred servers were merged under `mcp_servers` in
   `~/.hermes/config.yaml` (see **mad-install-mcp-servers** /
   [mcp.hermes.json](../mad-install-mcp-servers/mcp.hermes.json)).
2. Confirm `/reload-mcp` (or Hermes restart) after config/env changes.
3. Confirm `HERMES_*` stubs are filled in `~/.hermes/.env` (or process env) when
   tokens look unset.
4. Report each service as:
   - `:white_circle: missing` — server key absent from `mcp_servers`
   - `:boom: error` — config present but Hermes reports load/connect failure
   - `:closed_lock_with_key: needsAuth` — OAuth still required (e.g. Notion:
     `hermes mcp login notion`)
   - Otherwise ask the user to run a tiny read-only MCP action in Hermes; only
     then mark `:white_check_mark: ok` or `:x: fail` from the observed result

## Workflow (Cursor)

1. Discover which of the four servers are present and their `serverStatus`.
2. For each service, in parallel when possible:
   - **Missing** — server not in the MCP catalog → `missing`
   - **needsAuth** — call `mcp_auth` for that server once, then re-inspect
   - **error / loading** — record as `error` or wait briefly and re-check once
   - **ready** — call the probe tool; success → `ok`, failure → `fail`
3. Do not retry auth loops. One `mcp_auth` attempt per server max.
4. Emit the report below. Keep it short — no dump of full API payloads.

## Status values

Always render Status as `emoji label` using this fixed map (never omit the emoji):

| Status | Render as | Meaning |
|--------|-----------|---------|
| `ok` | `:white_check_mark: ok` | Probe succeeded; include a short identity hint (login, display name, or account id) |
| `fail` | `:x: fail` | Server present but probe errored (auth, permission, or API) |
| `needsAuth` | `:closed_lock_with_key: needsAuth` | Server requires authentication and is not usable yet |
| `missing` | `:white_circle: missing` | MCP server not available in this session |
| `error` | `:boom: error` | Server listed but in error/unavailable state |

## Report format

Use this exact structure (Markdown). Status column must include the emoji from the map above:

```markdown
# Connection report

| Service | Status | Detail |
|---------|--------|--------|
| GitHub | :white_check_mark: ok | <short detail> |
| GitLab | :x: fail | <short detail> |
| Jira | :closed_lock_with_key: needsAuth | <short detail> |
| Notion | :white_circle: missing | <short detail> |

**Summary:** <N>/4 ok
```

Detail examples:

- `:white_check_mark: ok` — `login=octocat` or `user=Jane Doe`
- `:x: fail` — one-line error reason (no stack traces)
- `:closed_lock_with_key: needsAuth` — `authenticate MCP server`
- `:white_circle: missing` — `MCP server not configured — run mad-install-mcp-servers`
- `:boom: error` — `serverStatus=error`

Optional one-liner after the table only if something is blocked: what the user should fix (enable MCP, re-auth, check token). No essays.

## When missing or misconfigured

If any service is `:white_circle: missing`, or `:x: fail` / `:boom: error` looks like absent MCP config or bad server setup (not merely expired auth):

- Point the user to **mad-install-mcp-servers** for the **same host**:
  - Cursor → `~/.cursor/mcp.json` + `CURSOR_*` vars
  - Claude Desktop → `claude_desktop_config.json` + `CLAUDE_*` vars
  - Hermes Agent → `~/.hermes/config.yaml` (`mcp_servers`) + `HERMES_*` vars
    (prefer `~/.hermes/.env`)
- For `:closed_lock_with_key: needsAuth` alone on Cursor, prefer `mcp_auth` — do not treat that as an install problem.
- For Hermes OAuth (e.g. Notion), prefer `hermes mcp login <server>`.
- For token/URL env issues after the server is present, name the host-specific
  vars (`CURSOR_*`, `CLAUDE_*`, or `HERMES_*`) rather than inventing new ones or
  crossing hosts.

## Do not

- Skip a listed service
- Write data to any service as part of the check
- Invent a passing status without a successful probe (Cursor) or observed
  evidence (Claude Desktop / Hermes Agent)
- Expand the report with unrelated diagnostics unless the user asks
