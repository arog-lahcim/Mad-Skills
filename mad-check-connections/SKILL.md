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

| Status | Meaning |
|--------|---------|
| `ok` | Probe succeeded; include a short identity hint (login, display name, or account id) |
| `fail` | Server present but probe errored (auth, permission, or API) |
| `needsAuth` | Server requires authentication and is not usable yet |
| `missing` | MCP server not available in this session |
| `error` | Server listed but in error/unavailable state |

## Report format

Use this exact structure (Markdown):

```markdown
# Connection report

| Service | Status | Detail |
|---------|--------|--------|
| GitHub | ok / fail / needsAuth / missing / error | <short detail> |
| GitLab | … | … |
| Jira | … | … |
| Notion | … | … |

**Summary:** <N>/4 ok
```

Detail examples:

- `ok` — `login=octocat` or `user=Jane Doe`
- `fail` — one-line error reason (no stack traces)
- `needsAuth` — `authenticate MCP server`
- `missing` — `MCP server not configured`
- `error` — `serverStatus=error`

Optional one-liner after the table only if something is blocked: what the user should fix (enable MCP, re-auth, check token). No essays.

## Do not

- Skip a listed service
- Write data to any service as part of the check
- Invent a passing status without a successful probe
- Expand the report with unrelated diagnostics unless the user asks
