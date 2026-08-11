# Mad Skills

Personal [Cursor Agent Skills](https://cursor.com/docs/skills.md) — available across all projects when linked under `~/.cursor/skills/`.

## Install with Cursor agent

Paste this prompt into a new Cursor agent chat:

```text
Install Mad Skills from https://github.com/arog-lahcim/Mad-Skills — fetch
https://raw.githubusercontent.com/arog-lahcim/Mad-Skills/main/INSTALL.md and
follow it interactively.
```

The agent loads and follows [INSTALL.md](INSTALL.md) (interactive: skills symlink and/or MCP).

## Manual install (global)

```bash
mkdir -p ~/.cursor/skills
ln -s /path/to/Mad-Skills ~/.cursor/skills/Mad-Skills
```

Reload Cursor, then check **Customize → Skills** (user scope).

## Sync

```bash
cd ~/.cursor/skills/Mad-Skills && git pull
```

Or ask the agent to run **mad-update-skills**.
