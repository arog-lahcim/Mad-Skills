---
name: mad-agentic
description: >-
  Ensure work leaves durable context and instructions for future LLM agents
  (AGENTS.md, CONTRACT/domain docs, Cursor rules). Use when creating or
  scaffolding a project, starting a new repo/package, handing off work to
  agents, or when the user asks for agentic readiness, agent guidelines,
  AGENTS.md, or mad-agentic.
---

# Mad Agentic

Future LLM agents must be able to continue this project without the original chat. Every scaffolding or substantial project change must leave durable, in-repo instructions and domain context.

## When to apply

Apply automatically when:

- Creating a new project, package, or repo (e.g. `uv init`, new service, new harness)
- Substantial greenfield work in a directory that lacks agent guidance
- The user asks to prepare the project for agents / LLM handoff / agentic readiness

Do **not** spam docs on tiny one-line fixes. Prefer update-in-place when files already exist.

## Required deliverables (project scope)

Create or update these **inside the project root** (not only the workspace root):

| Artifact | Purpose |
|----------|---------|
| `AGENTS.md` | Standing rules for agents: purpose, tooling, conventions, safety, key paths, external links |
| Domain contract doc | Stable facts agents must not invent — prefer `CONTRACT.md`, or an existing equivalent (`SPEC.md`, `DOMAIN-KNOWLEDGE.md`) |
| `.cursor/rules/<project>.mdc` | Short always-on Cursor rule pointing at `AGENTS.md` / contract; `alwaysApply: true` |
| `README.md` link | One line pointing agents to `AGENTS.md` (+ contract) |

Optional when useful:

- `.env.example` aligned with documented env vars
- Pointers to epic/ticket URLs, Notion/GitLab sources of truth

Match sibling-repo style when present (e.g. `platform-data-lakehouse/AGENTS.md`).

## `AGENTS.md` contents

Maximally concise. English unless the user requests another language. Include:

1. **Project purpose** — what / not what (scope boundaries)
2. **Tooling** — package manager (`uv` / `pnpm` / …), how to run tests, env file rules
3. **Code conventions** — layout, imports, asserts, secrets
4. **Non-negotiable safety** — isolation, prod data, forbidden destructive ops
5. **Implementation guidance** — layering, stubs, what not to invent
6. **Key paths** — table of important files
7. **External references** — Jira/Notion/GitLab URLs with stable meaning

Do not paste the whole design chat. Link tickets/docs instead.

## Contract / domain doc

Capture decisions that must stay consistent across agent sessions:

- Schemas, markers, IDs, naming
- SLAs / timeouts
- Cleanup / safety ordering
- Explicit out-of-scope items

Update the contract when those facts change; do not leave them only in chat or ticket comments.

## Cursor rule (`.mdc`)

```markdown
---
description: <project> agent conventions
alwaysApply: true
---

# <project>

- Read `AGENTS.md` and `<CONTRACT.md|equivalent>` before changing core behavior.
- <3–8 bullets: tooling, safety, scope boundaries>
```

Keep under ~20 lines. Details live in `AGENTS.md` / contract.

## Workflow checklist

When scaffolding or enabling agentic readiness:

1. Detect project root and existing `AGENTS.md` / contract / `.cursor/rules/`.
2. Create missing files; update stale sections if the new work changes purpose, tooling, or safety.
3. Link `README.md` → `AGENTS.md` (+ contract).
4. Ensure `.gitignore` keeps secrets out (`.env`, credentials) while `.env.example` stays committed when env-driven.
5. Briefly tell the user which agent files were added or updated.

## Do not

- Put agent guidance only in chat, scratchpads, or uncommitted notes
- Duplicate large README trees or stale file listings (see `mad-repo-readme`)
- Invent conflicting conventions when a sibling `AGENTS.md` already defines the house style — extend, don’t fork
- Commit secrets into agent docs or examples

## Reference example

`platform-e2e` handoff pattern:

- `AGENTS.md` — harness purpose, uv, marker isolation, layer names, links to CPL-728 / Notion
- `CONTRACT.md` — markers, assertion layers, SLAs, cleanup, out of scope
- `.cursor/rules/platform-e2e.mdc` — always-on short rules
- `README.md` — points agents at those files
