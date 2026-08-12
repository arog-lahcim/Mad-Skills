# Mad Skills — agent install

One-shot bootstrap for a fresh agent. This is **not** a skill (so it never appears
under Customize → Skills). Follow the workflow interactively, narrate every
mutating step, and do not invent alternate remotes or install layouts.

## Canonical remote

```text
git@github.com:arog-lahcim/Mad-Skills.git
```

Browser / HTTPS URL (docs, Releases): https://github.com/arog-lahcim/Mad-Skills

Prefer **SSH** clone. Use HTTPS (`https://github.com/arog-lahcim/Mad-Skills.git`)
only when the user asks for it, or when SSH to GitHub is unavailable.

## Workflow

### 1. Ask host (always)

Stop and ask the user to choose **one or more**:

- **Cursor**
- **Claude Desktop** (includes Claude cloud Skills upload)
- **Hermes Agent**
- **Multiple** (run skills/MCP steps once per chosen host)

Wait for their answer before mutating anything.

### 2. Ask install scope (always)

Stop and ask the user to choose **one**:

- **Skills only** — install skills for the chosen host(s)
- **Skills + MCP** — skills, then MCP servers
- **MCP only** — skip skills install; run MCP install from an existing clone/tree if available

Wait for their answer before mutating anything.

### 3. Skills path (Skills only or Skills + MCP)

#### Shared clone (Cursor and/or Hermes)

**Clone directory**

- Recommend `~/Mad-Skills`.
- If missing or ambiguous, ask once; reuse an existing Mad-Skills git checkout when
  present (same remote / clearly this repo).

**Before cloning or linking**, tell the user the exact paths you will use.

**Clone** (if needed):

```bash
git clone git@github.com:arog-lahcim/Mad-Skills.git ~/Mad-Skills
```

(Adjust destination to the user’s chosen path. Switch to the HTTPS URL only if
the user prefers it or SSH fails.)

#### Cursor

**Symlink**

```bash
mkdir -p ~/.cursor/skills
ln -sfn /absolute/path/to/Mad-Skills ~/.cursor/skills/Mad-Skills
```

**Conflicts:** if `~/.cursor/skills/Mad-Skills` already exists and does **not**
resolve to the intended clone, stop and ask before replacing. Do not silently overwrite.

After linking, confirm with `ls -la ~/.cursor/skills/Mad-Skills` and list skill
dirs (`*/SKILL.md` under the clone). Tell the user to reload Cursor / check
**Customize → Skills** (user scope) if skills were newly linked.

#### Hermes Agent

Do **not** create a Cursor skills symlink for Hermes-only installs (unless Cursor
was also chosen).

Prefer **`skills.external_dirs`** so Hermes scans the Mad-Skills clone (each
`mad-*/SKILL.md` child folder is a skill):

1. Ensure the clone exists (shared clone steps above).
2. Read `~/.hermes/config.yaml` (create a minimal file only if missing — never wipe
   unrelated Hermes keys).
3. Under `skills.external_dirs`, add the **absolute** clone path if absent. Example:

```yaml
skills:
  external_dirs:
    - /absolute/path/to/Mad-Skills
```

Preserve any existing `external_dirs` entries. Expand `~` if writing a home-relative path.

4. Confirm with `hermes skills list` (or `/skills`) that Mad Skills names appear.
   New sessions pick up external skills; mention `/reset` if the current session
   still looks stale.

Optional alternative (only if the user asks): copy or symlink individual skill
folders into `~/.hermes/skills/` instead of `external_dirs`.

#### Claude Desktop / cloud

Do **not** create a Cursor skills symlink for Claude-only installs.

Prefer one of:

1. **Release zips** — open the latest GitHub Release for this repo, download
   `mad-*.zip` (or `mad-skills-all.zip` and unpack). Each zip’s root folder must
   contain `SKILL.md`. Guide the user to **Customize → Skills → upload**.
2. **Local checkout** — if a clone already exists (or the user approved cloning
   to e.g. `~/Mad-Skills`), zip each skill dir locally with
   `scripts/package-skill-zips.sh` (or point them at the skill folders) and upload.

Remind the user that Claude Skills need **code execution** enabled when Skills
appear greyed out.

### 4. MCP path (MCP only or Skills + MCP)

Resolve `mad-install-mcp-servers/SKILL.md` from:

- the clone just linked / used, or
- `~/.cursor/skills/Mad-Skills/mad-install-mcp-servers/SKILL.md` if already installed, or
- a Hermes `external_dirs` Mad-Skills clone, or
- the local checkout used for this install

**Read that skill and follow it fully** for the chosen host(s) (merge into the
host config, env stubs, CLIs, then verification). Do not re-implement MCP install
here.

For **MCP only** without any Mad-Skills tree available: clone (or fetch) enough
of the repo to read `mad-install-mcp-servers/`, then follow that skill — ask
before cloning if the user has not already approved a path.

### 5. Final report

Always print this structure (fill in real values; omit MCP/connection sections if
that path was skipped):

```markdown
# Mad Skills install

| Item | Value |
|------|--------|
| Host | Cursor / Claude Desktop / Hermes Agent / Multiple |
| Scope | Skills only / Skills + MCP / MCP only |
| Remote | git@github.com:arog-lahcim/Mad-Skills.git (or HTTPS if the user chose that) |
| Clone | <path or n/a> |
| Cursor symlink | ~/.cursor/skills/Mad-Skills → <target or n/a / unchanged> |
| Hermes external_dirs | <path listed or n/a / unchanged> |
| Claude skills | uploaded from release zips / local zips / n/a |
| Skills | <comma-separated skill folder names, or n/a> |

<If MCP ran: include the MCP install table and connection/verification notes from those skills.>
```

## Do not

- Create a `mad-install` skill or put this guide under a `SKILL.md`
- Skip the host or scope prompt
- Force-replace an existing skills symlink or wipe Hermes `config.yaml` without asking
- Write secrets into files (MCP skill handles empty env stubs only)
- Push, commit, or edit skills as part of install
- Assume `CURSOR_*`, `CLAUDE_*`, and `HERMES_*` env vars are interchangeable
