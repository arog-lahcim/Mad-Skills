---
name: mad-update-skills
description: >-
  Sync Mad Skills from the remote git repository or from GitHub Releases. Use
  when the user asks to update global skills, sync Mad Skills, pull Mad Skills,
  refresh skills under ~/.cursor/skills/Mad-Skills, Hermes external_dirs, or
  refresh Claude Desktop / cloud skill uploads.
---

# Update Mad Skills

Refresh Mad Skills on the chosen host.

## Host selection

If unclear, ask once: **Cursor**, **Claude Desktop**, **Hermes Agent**, or
**multiple**.

## Cursor

Prefer the global install:

```bash
~/.cursor/skills/Mad-Skills
```

That path should be a symlink to the Mad-Skills clone. If it is missing, stop and
tell the user to install first via
[INSTALL.md](https://raw.githubusercontent.com/arog-lahcim/Mad-Skills/main/INSTALL.md)
(repo: https://github.com/arog-lahcim/Mad-Skills). Do not create a new clone or
symlink unless the user asks you to follow that install guide.

### Steps

1. `cd` into `~/.cursor/skills/Mad-Skills` (resolve the symlink; work in the real repo).
2. Check status: `git status -sb`. If there are local commits ahead of origin,
   uncommitted changes, or an unexpected branch, report that and ask before
   continuing — do not discard or overwrite local work.
3. Pull with network access:

```bash
git pull
```

4. Confirm success with `git status -sb` and list installed skills (`*/SKILL.md`
   under the Mad-Skills root).
5. Tell the user the result briefly: already up to date, or what changed. Mention
   reloading Cursor / **Customize → Skills** only if skills were added or removed.

## Hermes Agent

Hermes does not use the Cursor skills symlink. Prefer the Mad-Skills clone listed
under `skills.external_dirs` in `~/.hermes/config.yaml`.

### Steps

1. Read `~/.hermes/config.yaml` and resolve the Mad-Skills path from
   `skills.external_dirs` (or ask the user if none is listed — point them at
   INSTALL.md rather than inventing a path).
2. `cd` into that clone. Check `git status -sb`; ask before discarding local work.
3. `git pull` with network access.
4. Confirm with `hermes skills list` (or `/skills`) that Mad Skills still appear.
5. Tell the user briefly: already up to date, or what changed. Mention a new
   session or `/reset` if skills were added/removed and the current session looks
   stale.

Do not wipe unrelated Hermes config keys while syncing.

## Claude Desktop / cloud

Claude does not use the Cursor skills symlink. Sync by replacing uploaded skills
from the latest GitHub Release:

1. Open https://github.com/arog-lahcim/Mad-Skills/releases and identify the latest
   release (or the version the user named).
2. Download individual `mad-*.zip` assets, or `mad-skills-all.zip` and unpack so
   each skill folder contains `SKILL.md`.
3. Guide the user to **Customize → Skills** and upload/replace each skill.
4. If a local Mad-Skills clone exists and the user prefers local packaging,
   run `bash scripts/package-skill-zips.sh` from the repo root after `git pull`,
   then upload from `dist/`.
5. Tell the user briefly which release/version was used and that they may need to
   re-enable skills after upload.

## Do not

- Force-pull, reset, or stash unless the user explicitly asks
- Push, commit, or edit skills as part of this sync
- Install or re-link the Cursor symlink / Hermes `external_dirs` unless the user asks
- Assume Claude Desktop or Hermes reads `~/.cursor/skills/`
- Assume Cursor reads `~/.hermes/skills/`
