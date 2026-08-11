---
name: mad-install-mcp-servers
description: >-
  Install GitHub, GitLab, Atlassian (Jira/Confluence), and Notion into the
  user MCP config for Cursor (~/.cursor/mcp.json) and/or Claude Desktop
  (claude_desktop_config.json), verify required env vars and CLI tools, then
  run mad-check-connections. Use when the user asks to install MCP servers,
  set up favourite MCPs, fix missing GitHub/GitLab/Jira/Notion MCP, or run
  mad-install-mcp-servers.
---

# Install MCP servers

Ensure the four preferred MCP servers are present in the **user-global** MCP
config for the chosen host(s), then verify connectivity.

When **editing** this skill, read [CONTRACT.md](CONTRACT.md).

## Host selection (always)

Stop and ask the user to choose **one** (or both) before mutating anything:

- **Cursor** — `~/.cursor/mcp.json` + `CURSOR_*` env vars
- **Claude Desktop** — `claude_desktop_config.json` + `CLAUDE_*` env vars
- **Both** — run the full workflow once per host (Cursor first, then Claude)

Env var sets are **independent**. Do not reuse `CURSOR_*` values for Claude or
the reverse; someone may configure each host separately.

## Target files

| Host | Config path |
|------|-------------|
| Cursor | `~/.cursor/mcp.json` |
| Claude Desktop (macOS) | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Claude Desktop (Windows) | `%APPDATA%\Claude\claude_desktop_config.json` |
| Claude Desktop (Linux) | `~/.config/Claude/claude_desktop_config.json` |

Do **not** write project `.cursor/mcp.json` unless the user explicitly asks.
Preserve any existing unrelated `mcpServers` entries.

## Server templates

| Host | Template |
|------|----------|
| Cursor | [mcp.cursor.json](mcp.cursor.json) |
| Claude Desktop | [mcp.claude.json](mcp.claude.json) |

**Read the skill file** for the chosen host and merge its `mcpServers` keys into
the target. Do not invent alternate packages or URLs; do not copy templates from
memory when the skill file is available.

Cursor uses `${env:NAME}` interpolation. Claude Desktop uses `${NAME}` (or
literal values in `env`) and prefers **stdio** `command`/`args`/`env` shapes;
GitHub on Claude is `@modelcontextprotocol/server-github`. Notion may use a
remote `url` entry — if the host rejects `url` keys, tell the user to add Notion
via Customize → Connectors instead of inventing a package.

If `GITLAB_URL` in the skill template should not be `https://gitlab.com`, ask
once and use the user's value for that field only.

## Required environment variables

### Cursor (`CURSOR_*`)

Cursor interpolates `${env:NAME}` from the **process environment** of the Cursor
app (shell profile / login env / macOS launch agent — not only the current chat
shell).

| Server | Env vars |
|--------|----------|
| GitHub | `CURSOR_GITHUB_TOKEN` |
| GitLab | `CURSOR_GITLAB_TOKEN` (and `GITLAB_URL` in the server block) |
| Atlassian | `CURSOR_JIRA_URL`, `CURSOR_JIRA_USERNAME`, `CURSOR_JIRA_API_TOKEN`, `CURSOR_CONFLUENCE_URL`, `CURSOR_CONFLUENCE_USERNAME`, `CURSOR_CONFLUENCE_API_TOKEN` |
| Notion | none in JSON (OAuth via `mcp_auth` when needed) |

### Claude Desktop (`CLAUDE_*`)

Claude Desktop does not reliably inherit terminal-only env. Prefer login-shell
exports (`~/.zshenv` on macOS) and fully quit/reopen Claude Desktop after edits.
GUI apps may still need vars set system-wide; the template maps `CLAUDE_*` into
each server’s expected names via `${CLAUDE_…}`.

| Server | Env vars |
|--------|----------|
| GitHub | `CLAUDE_GITHUB_TOKEN` |
| GitLab | `CLAUDE_GITLAB_TOKEN` (and `GITLAB_URL` in the server block) |
| Atlassian | `CLAUDE_JIRA_URL`, `CLAUDE_JIRA_USERNAME`, `CLAUDE_JIRA_API_TOKEN`, `CLAUDE_CONFLUENCE_URL`, `CLAUDE_CONFLUENCE_USERNAME`, `CLAUDE_CONFLUENCE_API_TOKEN` |
| Notion | none in JSON (OAuth / Connectors when needed) |

## Required CLIs

| Server | CLI |
|--------|-----|
| GitLab | `npx` (Node.js) |
| Atlassian | `uvx` (Astral uv) |
| GitHub (Cursor) / Notion | none (HTTP MCP) |
| GitHub (Claude Desktop) | `npx` (stdio `@modelcontextprotocol/server-github`) |

## Scripts

Resolve this skill directory (repo, `~/.cursor/skills/Mad-Skills/mad-install-mcp-servers`,
or a released zip unpack). **Execute** the script; do not re-implement its logic.

```bash
SCRIPT="$SKILL_DIR/scripts/ensure-env-exports.sh"
HOST=cursor   # or claude
```

| Command | Purpose |
|---------|---------|
| `"$SCRIPT" --host "$HOST" status` | `set` / `MISSING` per var (never prints values) + `missing_count` |
| `"$SCRIPT" --host "$HOST" suggest` | shell, recommended path, candidate files (exists/missing) |
| `"$SCRIPT" --host "$HOST" append --file PATH [--dry-run]` | append empty `export NAME=` stubs for missing undeclared vars |

## Workflow

For **each** chosen host:

1. **Read** the host template ([mcp.cursor.json](mcp.cursor.json) or
   [mcp.claude.json](mcp.claude.json)) and the host target config. If the target
   is missing, start from `{"mcpServers": {}}`.
2. **Diff** each key under `mcpServers` in the skill template:
   - **Missing** in the target → add that key’s object from the skill template.
   - **Already present** → leave untouched; note `already present`.
   - **Overwrite** — only if the user **directly asked** to update/replace/reset
     that server (or all four). Then replace that key from the skill template
     (keep unrelated servers). Note `updated`.
3. **Write** the **target** config when any key was added or explicitly updated
   (valid JSON, 2-space indent). Never overwrite the skill templates. If nothing
   changed, skip writing.
4. **Check CLIs** with `command -v npx` and `command -v uvx`. If either is
   missing, tell the user how to install (Node for `npx`,
   [uv](https://github.com/astral-sh/uv) for `uvx`) before expecting
   GitLab/Atlassian (and Claude GitHub) to work.
5. **Check env vars** via the script (not a hand-rolled loop):

```bash
"$SCRIPT" --host "$HOST" status
"$SCRIPT" --host "$HOST" suggest
```

### When `missing_count` > 0

Actively help the user plant stubs — do not only paste a list of names.

1. From `suggest`, propose the **recommended** file (e.g. `~/.zshenv` on zsh)
   and list **candidates**.
2. **Prompt the user to pick a file** (recommended default, another candidate,
   or a custom path). Wait for their choice before writing.
3. Optional: `"$SCRIPT" --host "$HOST" append --file PATH --dry-run`.
4. Run: `"$SCRIPT" --host "$HOST" append --file PATH` (needs write access
   outside the repo; expand `~`).
5. Tell the user to fill the empty `export NAME=` values, save, then **fully
   quit and reopen** the host app (`Cursor` or `Claude Desktop`) so MCP sees the
   env. A var set only in the chat shell still counts as missing for GUI apps.

If `missing_count` is 0, skip prompting and append.

6. **Reload**: tell the user to reload MCP servers / restart the host app if
   servers were added or changed.
7. **Verify**: follow **mad-check-connections** for this host and emit its
   connection report. On Cursor, if Notion/GitHub need interactive auth, one
   `mcp_auth` per server is enough (same rules as that skill).

## Short install report

Before the connection report, print a brief install summary per host:

```markdown
# MCP install (<Cursor|Claude Desktop>)

| Server key | Config | Env / CLI |
|------------|--------|-----------|
| github | added / already present / updated | <HOST>_GITHUB_TOKEN set\|MISSING |
| gitlab | … | token + npx |
| mcp-atlassian | … | jira/confluence vars + uvx |
| notion | … | OAuth when prompted |
```

Include env-file action when relevant: `env stubs appended → ~/.zshenv` or
`env ok (no stubs)`.

`updated` only when the user directly asked to overwrite that entry.

Then run the connection check report from mad-check-connections.

## Do not

- Overwrite an existing server key on a normal install (missing-only); do
  overwrite when the user directly asks
- Overwrite unrelated `mcpServers` entries in the target
- Edit or overwrite this skill’s [mcp.cursor.json](mcp.cursor.json) or
  [mcp.claude.json](mcp.claude.json)
- Mix `CURSOR_*` and `CLAUDE_*` sets, or assume one host’s tokens work for the other
- Commit tokens or write raw secrets into files (stubs are empty `export NAME=`
  only; user fills values)
- Append env stubs without the user choosing a file path
- Re-implement `ensure-env-exports.sh` logic ad hoc in the agent
- Skip the post-install connection check
- Invent alternate packages or URLs, or hard-code the template instead of
  reading this skill’s host template file
