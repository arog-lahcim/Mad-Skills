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

## Character safety (Cursor + GitHub/GitLab)

Incompatible characters in skills have crashed Cursor (protobuf decode error on
`CursorRuleTypeAgentFetched.description`: “invalid UTF8”). Treat this as a hard
constraint when **creating or editing** any skill in this repo.

### Frontmatter `description` — ASCII only

The YAML `description` field is loaded into Cursor’s skill/rule metadata path.

- Use **ASCII only** in `name`, `description`, and other frontmatter values.
- **Never** put raw emoji, ZWJ sequences (e.g. technologist `U+1F9D1 U+200D U+1F4BB`),
  or other non-ASCII symbols in `description`.
- Prefer plain words or GitHub/GitLab shortcode *names without colons* only if you
  must mention a reaction (`white_check_mark`, `robot`) — still ASCII.
- Keep descriptions concise; long emoji-heavy blurbs belong in the markdown body,
  not in frontmatter.

Before finishing a skill edit, confirm the frontmatter block has no codepoints
above U+007F.

### Skill body — emoji shortcodes, not raw Unicode

In `SKILL.md` bodies (and sibling markdown in a skill folder):

- Do **not** insert raw emoji characters (`✅`, `🤖`, `🧑‍💻`, …).
- Use GitHub/GitLab-compatible shortcodes instead, e.g. `:white_check_mark:`,
  `:robot:`, `:technologist:`, `:dart:`, `:compass:`, `:grey_question:`,
  `:speech_balloon:`, `:x:`, `:boom:`, `:white_circle:`,
  `:closed_lock_with_key:`.
- Source of truth for names:
  [ikatyang/emoji-cheat-sheet](https://github.com/ikatyang/emoji-cheat-sheet)
  (generated from the [GitHub Emoji API](https://api.github.com/emojis)).
- Only use a shortcode that appears on that sheet / in the GitHub API so GitLab
  and GitHub both render and accept it.
- Combined signatures stay as adjacent shortcodes plus ASCII, e.g.
  `:robot:+:technologist:` (not a raw ZWJ glyph).
- Reaction **API** names stay bare (`white_check_mark`, `robot`, `technologist`)
  without surrounding colons — that is separate from markdown shortcodes.

Typography that is not emoji (em dash, arrows, curly quotes) is discouraged in
frontmatter; in bodies, prefer ASCII (`-`, `->`, `...`, straight quotes) when
practical so agents and tools do not reintroduce risky bytes near descriptions.

### Checklist for agents editing skills

```
Skill character safety:
- [ ] Frontmatter description/name are ASCII-only
- [ ] No raw emoji or ZWJ sequences anywhere in new/edited skill text
- [ ] Any emoji intent uses :shortcode: from the GitHub emoji cheat sheet
- [ ] Reaction API examples use bare names where the host API requires them
```

## Commits for skill changes

This repository is a collection of agent skills. Updates to a skill’s `SKILL.md`
(or other skill files) are product changes, not documentation.

- Prefer `feat:` for new or expanded skill behavior.
- Use `fix:` when correcting broken or incorrect skill guidance.
- Do **not** use `docs:` for `SKILL.md` updates.
- Release chore commits are CI-owned when used; agents should not invent manual release commits.
