# Mad Skills

Personal [Agent Skills](https://agentskills.io) for **Cursor** and **Claude Desktop**
(also uploadable to Claude cloud Skills). Workflows stay generic; install paths and
MCP config differ by host.

## Install with an agent

Paste this prompt into a new agent chat (Cursor or Claude):

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

## MCP

Ask the agent to run **mad-install-mcp-servers** and choose host:

| Host | Config | Env prefix |
|------|--------|------------|
| Cursor | `~/.cursor/mcp.json` | `CURSOR_*` |
| Claude Desktop | `claude_desktop_config.json` | `CLAUDE_*` |

Prefixes are independent so each app can be configured separately.

## Sync

**Cursor** (symlink install):

```bash
cd ~/.cursor/skills/Mad-Skills && git pull
```

Or ask the agent to run **mad-update-skills**.

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
