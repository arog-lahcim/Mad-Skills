---
name: mad-update-skills
description: >-
  Sync Mad Skills from the remote git repository. Use when the user asks to
  update global skills, sync Mad Skills, pull Mad Skills, or refresh skills
  under ~/.cursor/skills/Mad-Skills.
---

# Update Mad Skills

Pull the latest Mad Skills from remote into the global skills install.

## Path

Prefer the global install:

```bash
~/.cursor/skills/Mad-Skills
```

That path should be a symlink to the Mad-Skills clone. If it is missing, stop and tell the user to install first via [INSTALL.md](https://raw.githubusercontent.com/arog-lahcim/Mad-Skills/main/INSTALL.md) (repo: https://github.com/arog-lahcim/Mad-Skills). Do not create a new clone or symlink unless the user asks you to follow that install guide.

## Steps

1. `cd` into `~/.cursor/skills/Mad-Skills` (resolve the symlink; work in the real repo).
2. Check status: `git status -sb`. If there are local commits ahead of origin, uncommitted changes, or an unexpected branch, report that and ask before continuing — do not discard or overwrite local work.
3. Pull with network access:

```bash
git pull
```

4. Confirm success with `git status -sb` and list installed skills (`*/SKILL.md` under the Mad-Skills root).
5. Tell the user the result briefly: already up to date, or what changed. Mention reloading Cursor / **Customize → Skills** only if skills were added or removed.

## Do not

- Force-pull, reset, or stash unless the user explicitly asks
- Push, commit, or edit skills as part of this sync
- Install or re-link the symlink unless the user asks
