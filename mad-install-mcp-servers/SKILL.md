---
name: mad-install-mcp-servers
description: >-
  Install GitHub, GitLab, Atlassian (Jira/Confluence), and Notion into the
  user Cursor MCP config (~/.cursor/mcp.json), verify required env vars and
  CLI tools, then run mad-check-connections. Use when the user asks to install
  MCP servers, set up favourite MCPs, fix missing GitHub/GitLab/Jira/Notion
  MCP, or run mad-install-mcp-servers.
---

# Install MCP servers

Ensure the four preferred MCP servers are present in the **user-global** Cursor MCP config, then verify connectivity.

When **editing** this skill, read [CONTRACT.md](CONTRACT.md).

## Target file

```text
~/.cursor/mcp.json
```

Do **not** write project `.cursor/mcp.json` unless the user explicitly asks. Preserve any existing unrelated `mcpServers` entries.

## Server templates

Canonical entries live in this skill’s [mcp.json](mcp.json) (same shape as Cursor’s user config). **Read the skill file** and merge its `mcpServers` keys into the **target** `~/.cursor/mcp.json`. Do not invent alternate packages or URLs; do not copy templates from memory when the skill file is available.

If `GITLAB_URL` in the skill template should not be `https://gitlab.com`, ask once and use the user's value for that field only.

## Required environment variables

Cursor interpolates `${env:NAME}` from the **process environment** of the Cursor app (shell profile / login env / macOS launch agent — not only the current chat shell).

| Server | Env vars |
|--------|----------|
| GitHub | `CURSOR_GITHUB_TOKEN` |
| GitLab | `CURSOR_GITLAB_TOKEN` (and `GITLAB_URL` in the server block) |
| Atlassian | `CURSOR_JIRA_URL`, `CURSOR_JIRA_USERNAME`, `CURSOR_JIRA_API_TOKEN`, `CURSOR_CONFLUENCE_URL`, `CURSOR_CONFLUENCE_USERNAME`, `CURSOR_CONFLUENCE_API_TOKEN` |
| Notion | none in JSON (OAuth via `mcp_auth` when needed) |

## Required CLIs

| Server | CLI |
|--------|-----|
| GitLab | `npx` (Node.js) |
| Atlassian | `uvx` (Astral uv) |
| GitHub / Notion | none (HTTP MCP) |

## Scripts

Resolve this skill directory (repo or `~/.cursor/skills/Mad-Skills/mad-install-mcp-servers`). **Execute** the script; do not re-implement its logic in the chat.

```bash
SCRIPT="$SKILL_DIR/scripts/ensure-env-exports.sh"
```

| Command | Purpose |
|---------|---------|
| `"$SCRIPT" status` | `set` / `MISSING` per var (never prints values) + `missing_count` |
| `"$SCRIPT" suggest` | shell, recommended path, candidate files (exists/missing) |
| `"$SCRIPT" append --file PATH [--dry-run]` | append empty `export NAME=` stubs for missing undeclared vars |

## Workflow

1. **Read** this skill’s [mcp.json](mcp.json) (templates) and the target `~/.cursor/mcp.json`. If the target is missing, start from `{"mcpServers": {}}`.
2. **Diff** each key under `mcpServers` in the skill template:
   - **Missing** in the target → add that key’s object from the skill template.
   - **Already present** → leave untouched; note `already present`.
   - **Overwrite** — only if the user **directly asked** to update/replace/reset that server (or all four). Then replace that key from the skill template (keep unrelated servers). Note `updated`.
3. **Write** the **target** `~/.cursor/mcp.json` when any key was added or explicitly updated (valid JSON, 2-space indent). Never overwrite the skill’s [mcp.json](mcp.json). If nothing changed, skip writing.
4. **Check CLIs** with `command -v npx` and `command -v uvx`. If either is missing, tell the user how to install (Node for `npx`, [uv](https://github.com/astral-sh/uv) for `uvx`) before expecting GitLab/Atlassian to work.
5. **Check env vars** via the script (not a hand-rolled loop):

```bash
"$SCRIPT" status
"$SCRIPT" suggest
```

### When `missing_count` > 0

Actively help the user plant stubs — do not only paste a list of names.

1. From `suggest`, propose the **recommended** file (e.g. `~/.zshenv` on zsh) and list **candidates**.
2. **Prompt the user to pick a file** (recommended default, another candidate, or a custom path). Wait for their choice before writing.
3. Optional: `"$SCRIPT" append --file PATH --dry-run` to show what would be added.
4. Run: `"$SCRIPT" append --file PATH` (needs write access outside the repo; expand `~`).
5. Tell the user to fill the empty `export NAME=` values, save, then **fully quit and reopen Cursor** so MCP sees the env. A var set only in the chat shell still counts as missing for Cursor.

If `missing_count` is 0, skip prompting and append.

6. **Reload**: tell the user to reload MCP servers / restart Cursor if servers were added or changed so they appear in the session catalog.
7. **Verify**: follow **mad-check-connections** and emit its connection report. If Notion/GitHub need interactive auth, one `mcp_auth` per server is enough (same rules as that skill).

## Short install report

Before the connection report, print a brief install summary:

```markdown
# MCP install

| Server key | Config | Env / CLI |
|------------|--------|-----------|
| github | added / already present / updated | CURSOR_GITHUB_TOKEN set\|MISSING |
| gitlab | … | token + npx |
| mcp-atlassian | … | jira/confluence vars + uvx |
| notion | … | OAuth when prompted |
```

Include env-file action when relevant: `env stubs appended → ~/.zshenv` or `env ok (no stubs)`.

`updated` only when the user directly asked to overwrite that entry.

Then run the connection check report from mad-check-connections.

## Do not

- Overwrite an existing server key on a normal install (missing-only); do overwrite when the user directly asks
- Overwrite unrelated `mcpServers` entries in the target
- Edit or overwrite this skill’s [mcp.json](mcp.json)
- Commit tokens or write raw secrets into files (stubs are empty `export NAME=` only; user fills values)
- Append env stubs without the user choosing a file path
- Re-implement `ensure-env-exports.sh` logic ad hoc in the agent
- Skip the post-install connection check
- Invent alternate packages or URLs, or hard-code the template instead of reading this skill’s [mcp.json](mcp.json)
