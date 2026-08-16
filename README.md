# Mad Skills

Personal [Agent Skills](https://agentskills.io) for **Cursor**, **Claude Desktop**
(also uploadable to Claude cloud Skills), **Hermes Agent**, and **Warp**.
Workflows stay generic; install paths and MCP config differ by host.

## Install with an agent

Paste this prompt into a new agent chat (Cursor, Claude, Hermes, or Warp):

```text
Install Mad Skills from https://github.com/arog-lahcim/Mad-Skills — fetch
https://raw.githubusercontent.com/arog-lahcim/Mad-Skills/main/INSTALL.md and
follow it interactively.
```

The agent loads and follows [INSTALL.md](INSTALL.md) (interactive: host choice,
skills install, and/or MCP).

## Warp (manual)

Warp discovers skills from global home-folder directories where each `SKILL.md`
sits at `<dir>/<skill-name>/SKILL.md` (not nested under a `Mad-Skills/` folder):

- `~/.warp/skills/` — Warp-dedicated (recommended for Warp-only **and** for
  Warp + Cursor)
- `~/.agents/skills/` — universal cross-tool path. **Duplication warning:**
  Cursor also scans this directory. If you already use
  `~/.cursor/skills/Mad-Skills` for Cursor, linking the same `mad-*` skills
  into `~/.agents/skills/` shows them twice in Cursor. Prefer
  `~/.warp/skills/` for Warp when Cursor is also installed.
- also: `~/.claude/skills/`, `~/.codex/skills/`, `~/.cursor/skills/`,
  `~/.copilot/skills/`, `~/.factory/skills/`, `~/.gemini/skills/`,
  `~/.github/skills/`, `~/.opencode/skills/`

Pick a target directory, then from the Mad-Skills clone root link each
`mad-*/` skill folder individually with `scripts/link-skills.sh` (idempotent;
re-running replaces existing symlinks; only `mad-*` skill dirs are linked).
For Cursor alongside Warp, keep the Cursor `~/.cursor/skills/Mad-Skills`
symlink (below) and use `~/.warp/skills/` for Warp — do not also link Mad
Skills into `~/.agents/skills/` or as per-skill `~/.cursor/skills/mad-*`
unless you intentionally want a second discovery path in Cursor.

```bash
cd /path/to/Mad-Skills
./scripts/link-skills.sh --target ~/.warp/skills
# or: ./scripts/link-skills.sh --target ~/.agents/skills
# dry-run: ./scripts/link-skills.sh --target ~/.warp/skills --dry-run
# additional repo: ./scripts/link-skills.sh --target ~/.warp/skills \
#   --source /path/to/Other-Skills
```

Fully quit and reopen Warp, then confirm with `oz agent skills` (or ask the
Warp agent what skills it sees). Do not use `oz agent list` for this check —
it lists named/cloud agents, not skill folders.

## Cursor (manual)

```bash
mkdir -p ~/.cursor/skills
ln -s /path/to/Mad-Skills ~/.cursor/skills/Mad-Skills
```

Reload Cursor, then check **Customize → Skills** (user scope).

## Claude Desktop / cloud (manual)

1. Open the latest [GitHub Release](https://github.com/arog-lahcim/Mad-Skills/releases).
2. Download individual `mad-*.zip` files, or `mad-skills-all.zip` and unpack.
3. In Claude: **Customize → Skills** → upload each skill zip (folder must contain
   `SKILL.md`). Enable **code execution** if Skills are greyed out.

## Hermes Agent (manual)

1. Clone this repo (e.g. `~/Mad-Skills`) if needed.
2. Add the absolute clone path under `skills.external_dirs` in
   `~/.hermes/config.yaml` (preserve other Hermes keys):

```yaml
skills:
  external_dirs:
    - /absolute/path/to/Mad-Skills
```

3. Confirm with `hermes skills list` (or `/skills`). Start a new session or
   `/reset` if skills do not appear yet.

## MCP

Ask the agent to run **mad-install-mcp-servers** and choose host:

| Host | Config | Env prefix |
|------|--------|------------|
| Cursor | `~/.cursor/mcp.json` | `CURSOR_*` |
| Claude Desktop | `claude_desktop_config.json` | `CLAUDE_*` |
| Hermes Agent | `~/.hermes/config.yaml` (`mcp_servers`) | `HERMES_*` |
| Warp | `~/.warp/.mcp.json` (GUI / one-off `--mcp` as fallbacks) | `WARP_*` |

Prefixes are independent so each app can be configured separately. Hermes
secrets prefer `~/.hermes/.env`. Warp file installs show under Settings ->
Agents -> MCP servers; `oz mcp list` covers account/Drive servers and may omit
keys that exist only in `~/.warp/.mcp.json`.

## Sync

**Cursor** (symlink install):

```bash
cd ~/.cursor/skills/Mad-Skills && git pull
```

Or ask the agent to run **mad-update-skills**.

**Warp** (per-skill symlink install): `git pull` in the Mad-Skills clone;
existing symlinks pick up content updates. Re-run
`./scripts/link-skills.sh --target <dir>` when the pull adds new `mad-*`
skill folders. Or ask **mad-update-skills**.

**Hermes Agent** (`external_dirs` clone): `git pull` in that clone, or ask
**mad-update-skills** for host-specific steps.

**Claude Desktop / cloud:** download newer zips from Releases and re-upload/replace
skills (or ask **mad-update-skills** for host-specific steps).

## Releases

Pushes to `main` run [semantic-release](https://github.com/semantic-release/semantic-release)
and publish a GitHub Release with skill zips when conventional commits warrant a
version bump. Side branches and PRs run `semantic-release --dry-run` (no tag or
assets) to validate config and show the would-be next version.

The released version is kept in git: CI pushes a `chore(release): <version> [skip ci]`
commit with the bumped `package.json` (and lockfile) alongside the `v<version>` tag,
so the tag, the release, and `package.json` never drift apart.
