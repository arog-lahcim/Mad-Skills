# Mad Skills

Personal [Agent Skills](https://agentskills.io) for **Cursor**, **Claude Desktop**
(also uploadable to Claude cloud Skills), and **Hermes Agent**. Workflows stay
generic; install paths and MCP config differ by host.

## Install with an agent

Paste this prompt into a new agent chat (Cursor, Claude, or Hermes):

```text
Install Mad Skills from https://github.com/arog-lahcim/Mad-Skills — fetch
https://raw.githubusercontent.com/arog-lahcim/Mad-Skills/main/INSTALL.md and
follow it interactively.
```

The agent loads and follows [INSTALL.md](INSTALL.md) (interactive: host choice,
skills install, and/or MCP).

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

Prefixes are independent so each app can be configured separately. Hermes
secrets prefer `~/.hermes/.env`.

## Sync

**Cursor** (symlink install):

```bash
cd ~/.cursor/skills/Mad-Skills && git pull
```

Or ask the agent to run **mad-update-skills**.

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
