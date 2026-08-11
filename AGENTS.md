# Agent notes (Mad Skills)

## Skill scope: stay generic

Skills in this repository are for **generic** agent workflows. They must never be
bound to a specific project or company.

- Do **not** hard-code project names, company names, internal codenames, or other identifying data.
- Examples, paths, ticket IDs, and URLs in skills must stay illustrative and reusable across contexts — or use placeholders.
- If guidance only applies to one org or repo, keep it out of Mad Skills (put it in that project’s `AGENTS.md` / rules instead).

## Dual host (Cursor + Claude Desktop)

Mad Skills target **Cursor** and **Claude Desktop** (including Claude cloud Skills uploads).

- Keep host-specific install paths and MCP config in separate files or clearly labeled sections. Do not hard-code only Cursor paths when MCP/install guidance is shared.
- Cursor skills: global symlink under `~/.cursor/skills/Mad-Skills`.
- Claude / cloud skills: per-skill zip artifacts from GitHub Releases (see `scripts/package-skill-zips.sh`); upload via Customize → Skills.
- MCP templates: `mad-install-mcp-servers/mcp.cursor.json` and `mad-install-mcp-servers/mcp.claude.json`.

## Env var independence

- Cursor MCP uses `CURSOR_*` variables.
- Claude Desktop MCP uses `CLAUDE_*` variables.
- Never treat them as interchangeable. When renaming or adding a var, update the matching host template, `scripts/ensure-env-exports.sh` (`CURSOR_VARS` / `CLAUDE_VARS`), and the skill env tables together.

## Releases and versioning

- Conventional commits on `main` drive [semantic-release](https://github.com/semantic-release/semantic-release) versions and GitHub Releases.
- Do **not** hand-create version tags for normal releases.
- The version lives in git: CI commits the bumped `package.json` and `package-lock.json` as `chore(release): <version> [skip ci]`. Never bump those versions by hand.
- The release commit must stay non-releasing (`chore`) and carry `[skip ci]`, so it cannot start another release run.
- Skill zip packaging lives in `scripts/package-skill-zips.sh` (invoked by semantic-release `prepareCmd`).
- Side branches and PRs run `semantic-release --dry-run` in CI to validate config and report the would-be next version without publishing.
- Real publish (tag + release assets) happens only from `main`.

## Commits for skill changes

This repository is a collection of agent skills. Updates to a skill’s `SKILL.md`
(or other skill files) are product changes, not documentation.

- Prefer `feat:` for new or expanded skill behavior.
- Use `fix:` when correcting broken or incorrect skill guidance.
- Do **not** use `docs:` for `SKILL.md` updates.
- Release chore commits are CI-owned when used; agents should not invent manual release commits.
