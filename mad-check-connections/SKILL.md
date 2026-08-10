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

## Services under test

| Service | MCP server id (typical) | Probe |
|---------|-------------------------|--------|
| GitHub | `user-github` / `github` | `get_me` |
| GitLab | `user-gitlab` / `gitlab` | `get_current_user` |
| Jira | `user-mcp-atlassian` / `mcp-atlassian` | `jira_get_all_projects` (`include_archived: false`) |
| Notion | `user-notion` / `notion` | `notion-get-users` (`user_id: "self"`) |

Resolve the real server id with `GetMcpTools` (pattern search or catalog) before calling tools. Prefer the smallest whoami-style probe above; do not create, edit, or delete anything.

## Workflow

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
| `ok` | `✅ ok` | Probe succeeded; include a short identity hint (login, display name, or account id) |
| `fail` | `❌ fail` | Server present but probe errored (auth, permission, or API) |
| `needsAuth` | `🔐 needsAuth` | Server requires authentication and is not usable yet |
| `missing` | `⚪ missing` | MCP server not available in this session |
| `error` | `💥 error` | Server listed but in error/unavailable state |

## Report format

Use this exact structure (Markdown). Status column must include the emoji from the map above:

```markdown
# Connection report

| Service | Status | Detail |
|---------|--------|--------|
| GitHub | ✅ ok | <short detail> |
| GitLab | ❌ fail | <short detail> |
| Jira | 🔐 needsAuth | <short detail> |
| Notion | ⚪ missing | <short detail> |

**Summary:** <N>/4 ok
```

Detail examples:

- `✅ ok` — `login=octocat` or `user=Jane Doe`
- `❌ fail` — one-line error reason (no stack traces)
- `🔐 needsAuth` — `authenticate MCP server`
- `⚪ missing` — `MCP server not configured — run mad-install-mcp-servers`
- `💥 error` — `serverStatus=error`

Optional one-liner after the table only if something is blocked: what the user should fix (enable MCP, re-auth, check token). No essays.

## When missing or misconfigured

If any service is `⚪ missing`, or `❌ fail` / `💥 error` looks like absent MCP config or bad server setup (not merely expired auth):

- Point the user to **mad-install-mcp-servers** to write the preferred entries into `~/.cursor/mcp.json`, check env vars / CLIs, and re-run this report.
- For `🔐 needsAuth` alone, prefer `mcp_auth` — do not treat that as an install problem.
- For token/URL env issues after the server is present, name the expected `CURSOR_*` vars (see mad-install-mcp-servers) rather than inventing new ones.

## Do not

- Skip a listed service
- Write data to any service as part of the check
- Invent a passing status without a successful probe
- Expand the report with unrelated diagnostics unless the user asks
