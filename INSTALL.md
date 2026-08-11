# Mad Skills — agent install

One-shot bootstrap for a fresh Cursor agent. This is **not** a skill (so it never appears under Customize → Skills). Follow the workflow interactively, narrate every mutating step, and do not invent alternate remotes or install layouts.

## Canonical remote

```text
https://github.com/arog-lahcim/Mad-Skills
```

Prefer HTTPS clone. Use SSH (`git@github.com:arog-lahcim/Mad-Skills.git`) only if the user’s environment already has GitHub SSH working.

## Workflow

### 1. Ask install scope (always)

Stop and ask the user to choose **one**:

- **Skills only** — clone + global symlink
- **Skills + MCP** — skills, then MCP servers
- **MCP only** — skip skills linking; run MCP install from an existing clone/tree if available

Wait for their answer before mutating anything.

### 2. Skills path (Skills only or Skills + MCP)

**Clone directory**

- Recommend `~/Mad-Skills`.
- If missing or ambiguous, ask once; reuse an existing Mad-Skills git checkout when present (same remote / clearly this repo).

**Before cloning or linking**, tell the user the exact paths you will use.

**Clone** (if needed):

```bash
git clone https://github.com/arog-lahcim/Mad-Skills.git ~/Mad-Skills
```

(Adjust destination to the user’s chosen path.)

**Symlink**

```bash
mkdir -p ~/.cursor/skills
ln -sfn /absolute/path/to/Mad-Skills ~/.cursor/skills/Mad-Skills
```

**Conflicts:** if `~/.cursor/skills/Mad-Skills` already exists and does **not** resolve to the intended clone, stop and ask before replacing. Do not silently overwrite.

After linking, confirm with `ls -la ~/.cursor/skills/Mad-Skills` and list skill dirs (`*/SKILL.md` under the clone). Tell the user to reload Cursor / check **Customize → Skills** (user scope) if skills were newly linked.

### 3. MCP path (MCP only or Skills + MCP)

Resolve `mad-install-mcp-servers/SKILL.md` from:

- the clone just linked, or
- `~/.cursor/skills/Mad-Skills/mad-install-mcp-servers/SKILL.md` if already installed, or
- the local checkout used for this install

**Read that skill and follow it fully** (merge into `~/.cursor/mcp.json`, env stubs, CLIs, then mad-check-connections). Do not re-implement MCP install here.

For **MCP only** without any Mad-Skills tree available: clone (or fetch) enough of the repo to read `mad-install-mcp-servers/`, then follow that skill — ask before cloning if the user has not already approved a path.

### 4. Final report

Always print this structure (fill in real values; omit MCP/connection sections if that path was skipped):

```markdown
# Mad Skills install

| Item | Value |
|------|--------|
| Scope | Skills only / Skills + MCP / MCP only |
| Remote | https://github.com/arog-lahcim/Mad-Skills |
| Clone | <path or n/a> |
| Symlink | ~/.cursor/skills/Mad-Skills → <target or n/a / unchanged> |
| Skills | <comma-separated skill folder names, or n/a> |

<If MCP ran: include the MCP install table and connection report from those skills.>
```

## Do not

- Create a `mad-install` skill or put this guide under a `SKILL.md`
- Skip the scope prompt
- Force-replace an existing skills symlink without asking
- Write secrets into files (MCP skill handles empty env stubs only)
- Push, commit, or edit skills as part of install
