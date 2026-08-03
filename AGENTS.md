# Agent notes (Mad Skills)

## Skill scope: stay generic

Skills in this repository are for **generic** agent workflows. They must never be bound to a specific project or company.

- Do **not** hard-code project names, company names, internal codenames, or other identifying data.
- Examples, paths, ticket IDs, and URLs in skills must stay illustrative and reusable across contexts — or use placeholders.
- If guidance only applies to one org or repo, keep it out of Mad Skills (put it in that project’s `AGENTS.md` / rules instead).

## Commits for skill changes

This repository is a collection of agent skills. Updates to a skill’s `SKILL.md` (or other skill files) are product changes, not documentation.

- Prefer `feat:` for new or expanded skill behavior.
- Use `fix:` when correcting broken or incorrect skill guidance.
- Do **not** use `docs:` for `SKILL.md` updates.
