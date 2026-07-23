---
name: mad-jira-tickets
description: Create and update Jira tickets with action-verb summaries and ADF descriptions (user story, References, Acceptance Criteria); set Blocks links and Rank order via REST. Use when creating, updating, or reformatting Jira issues, writing ticket descriptions, linking dependencies, ranking backlog order, or submitting descriptions via the Jira Cloud REST API.
---

# Jira Tickets

## Writing documents and tickets

All descriptions produced as documents, notes, specifications, or Jira tickets must be **maximally concise** — no filler, repetition, or vague generalities. Every sentence should carry concrete information. Prefer short sentences, bullet lists, and precise wording over narrative prose.

Wrap all code-like text in inline code marks: variable names, field names, table/column names, API paths, GraphQL types, enum values, file paths, config keys, CLI flags, and similar identifiers (e.g. `artifacts`, `ArtifactMode`, `/data/graphql`, `customfield_10010`). In ADF descriptions, use the `code` text mark — not bare text or HTML.

**Default language: English.** Write tickets, task descriptions, acceptance criteria, and agent-produced documents in English unless the user explicitly requests another language.

## Jira tickets

Every Jira ticket must have a `Summary` (title) and a `Description` built according to the schema below.

### Ticket title (Summary)

Start the title with an action verb — what someone will do on this ticket. Use verbs such as `Implement`, `Check`, `Validate`, `Research`, `Fix`, `Add`, `Remove`, `Update`, `Document`.

**Good:** `Implement GraphQL schema + Postgres Artifact Registry`, `Validate JWT auth on artifact queries`, `Research StarRocks table lifecycle options`

**Bad:** `GraphQL schema + Postgres Artifact Registry`, `Artifact Registry`, `JWT auth`

Keep titles short and specific. No leading ticket keys, no trailing punctuation.

### Submitting descriptions (REST API, not MCP)

**Use the Jira Cloud REST API v3** to create or update ticket descriptions. **Do not use the Atlassian MCP** (`jira_create_issue` / `jira_update_issue`) for description bodies — it accepts Markdown or wiki markup but stores them as plain-text ADF paragraphs. Headings (`# References`, `h1. References`), links, and checkboxes do not render correctly.

Submit descriptions as **Atlassian Document Format (ADF)** via:

```
PUT /rest/api/3/issue/{issueKey}
{"fields": {"description": <adf doc>}}
```

Auth: Basic auth with `JIRA_USERNAME` + `JIRA_API_TOKEN` from the `mcp-atlassian` MCP config (`JIRA_URL` is the site base, e.g. `https://cledar.atlassian.net`).

**ADF mapping** from the schema below:

| Schema element | ADF node |
| --- | --- |
| User story (3 lines, one block) | `paragraph` with `hardBreak` between lines; labels `As a`, `I want`, `So that` use `strong` marks; label and rest of line in the same text run — no `hardBreak` after a label |
| `# References` | `heading` attrs `level: 1`, text `References` |
| Reference bullet + link | `bulletList` → `listItem` → `paragraph` with `text` + `link` mark |
| `# Acceptance Criteria` | `heading` attrs `level: 1`, text `Acceptance Criteria` |
| `- [ ] Criterion` | `taskList` → `taskItem` attrs `state: "TODO"` (each needs a unique `localId`); **`taskItem.content` is inline `text` nodes — do not wrap in `paragraph`** (paragraph wrapper returns `INVALID_INPUT`) |
| Inline code (names, paths, types) | `text` with `code` mark — e.g. `artifacts`, `ArtifactMode`, `/data/graphql` |

Root document: `{"version": 1, "type": "doc", "content": [...]}`.

MCP is fine for read-only operations (search, get issue) and non-description fields (summary, epic link, transitions, issue links metadata). **Do not use MCP to set description bodies.**

### Issue links — Blocks / is blocked by (Cledar Jira)

Use link type `Blocks` so prerequisites show **blocks** dependents, and dependents show **is blocked by** prerequisites.

**Create via REST** (`POST /rest/api/3/issueLink`). For “A blocks B” (A must finish before B) on **cledar.atlassian.net**, use:

```json
{
  "type": { "name": "Blocks" },
  "inwardIssue": { "key": "A" },
  "outwardIssue": { "key": "B" }
}
```

This is **intentional for this site’s UI**. Do **not** follow the common Atlassian doc example that puts the blocker in `outwardIssue` — that reverses labels in Cledar’s Linked work items UI.

**Meaning:**

| Intent | `inwardIssue` | `outwardIssue` | UI on A | UI on B |
| --- | --- | --- | --- | --- |
| A blocks B | A (blocker / prerequisite) | B (blocked / dependent) | **blocks** B | **is blocked by** A |

**Verify after create** (do not “fix” from memory or from Atlassian docs alone):

1. Open the prerequisite ticket in UI (or ask the user): Linked work must list dependents under **blocks**.
2. Open a dependent ticket: Linked work must list the prerequisite under **is blocked by**.
3. When reading `GET /rest/api/3/issue/{key}?fields=issuelinks` on this site, map fields to UI as follows (matches Cledar UI; opposite of many Atlassian blog examples):
   - `outwardIssue: Y` on X → UI on X shows **blocks** Y
   - `inwardIssue: Y` on X → UI on X shows **is blocked by** Y
4. If UI is wrong, delete the link (`DELETE /rest/api/3/issueLink/{linkId}`) and recreate with the table above. Do not flip again based on docs without a UI check.

**Do not** invent a second “fix” after a correct UI state. Trust the Cledar UI checklist above.

### Rank / backlog order (execution sequence)

**Prefer create order over re-rank.** When creating a set of tickets from scratch, create them **sequentially in the intended execution order** (first ticket first). Jira assigns Rank roughly by creation time, so natural create order usually matches backlog order without a second pass. Do **not** create tickets out of order and plan to fix Rank afterward unless creation order was wrong or the user asks to reorder an existing set.

When the user asks to reorder **existing** tickets (or create order was wrong), set **Rank** via the Agile REST API — not by issue key order alone.

**Endpoint (only this works here):**

```
PUT /rest/agile/1.0/issue/rank
{"issues": ["CPL-1107"], "rankBeforeIssue": "CPL-1106"}
```

or

```
PUT /rest/agile/1.0/issue/rank
{"issues": ["CPL-1107"], "rankAfterIssue": "CPL-1105"}
```

- Use **`PUT /rest/agile/1.0/issue/rank`** with body `issues` + `rankBeforeIssue` / `rankAfterIssue`.
- Do **not** use `POST` to that path (405).
- Do **not** use `PUT /rest/agile/1.0/issue/{key}/rank` (wrong path).

**Reliable procedure** for a desired ordered list `[T1, T2, …, Tn]`:

1. Decide execution order first (dependencies + critical path; independent / nice-to-have last).
2. Apply ranks **from the end of the list toward the start** with `rankBeforeIssue`:
   - For `i` from `n-2` down to `0`: rank `order[i]` **before** `order[i+1]`.
3. Verify with JQL: `key in (...) ORDER BY Rank ASC` (search API). Confirm the printed order matches the intended sequence.
4. If a middle item is still wrong, re-run the backward `rankBeforeIssue` chain; a single `rankAfterIssue` pass alone can leave LexoRank gaps inconsistent.

**Example intent:** contract → skeleton → Redis store → immediate → timestamped/cron → update/cancel → multi-dispatch → iteration depth → replay recovery.

### Updating existing tickets

When reformatting a ticket to match this schema — ADF structure, bold user-story labels, checkboxes, inline code, section headings — **preserve all existing content**. Change formatting only; do not drop, shorten, or rewrite sections, bullets, links, instructions, or acceptance criteria unless the user explicitly asks for content changes.

Before submitting an update, compare the new description against the current issue and confirm every fact, link, and criterion is still present.

### User story at the start of the description

The description starts **directly** with the user story formula. Nothing may precede it — no heading, intro, or other content.

The three user story lines form **one block** — a single paragraph in Jira. Use exactly one newline (`\n`) between lines. **Never** insert a blank line between them; a blank line becomes `\n\n` in Jira and splits the block into separate paragraphs.

Bold the user story labels exactly as `**As a**`, `**I want**`, and `**So that**`. In ADF, apply the `strong` mark only to the labels.

Each user story line is **one line** — the bold label and its text stay together. **Never** break after the label; do not put `As a` / `I want` / `So that` on a separate line from the rest of that sentence. In ADF: one `hardBreak` only **between** complete lines (after the persona text, after the want text) — never immediately after a `strong` label.

**Correct** (label + text on the same line; single `\n` between lines):

```
**As a** platform engineering team
**I want** Workflow Stage Artifact support in the Artifacts API
**So that** continuous agent pipelines are tracked alongside Data View artifacts
```

**Wrong** — label split from its text (do not submit):

```
**As a**
platform engineering team
**I want**
Workflow Stage Artifact support in the Artifacts API
**So that**
continuous agent pipelines are tracked alongside Data View artifacts
```

**Wrong** — blank lines between lines (do not submit):

```
As a <role / persona>

I want <what should be done>

So that <problem solved / business value>
```

Logical layout (implement in ADF as described above — do not send this Markdown string via MCP):

```
**As a** <role / persona>
**I want** <what should be done>
**So that** <problem solved / business value>

# References
...
# Acceptance Criteria
...
```

Use `I want` for a single person or user perspective; `We want` when the ticket concerns a team, system, or broader organizational context.

The formula must answer **why** the work is needed — not only **what** should be done.

### Source links and references

When possible, add a level-one heading after the user story and before Acceptance Criteria:

```
# References
```

Under the heading, list links and pointers that help a developer understand **why** the ticket exists — not only what to build. Include only items that add context; omit the section if nothing useful is available.

Typical sources:

- Internal or external documentation (specs, ADRs, runbooks, API docs)
- Related Jira/Linear/GitHub issues or merge requests
- Slack threads, incident reports, or postmortems
- Logs, dashboards, or monitoring alerts that surfaced the problem
- Design files (Figma) or product briefs

Use descriptive link text or a short label per item (e.g. `ADR-12: Spark empty-file handling`). One line per reference; no narrative between items.

Only include references reachable via a URL. Do not list transcripts added manually to the LLM context, or any other source that cannot be accessed through a URL.

Do not list the parent ticket or parent item — Jira already links it.

### Acceptance Criteria at the end of the description

At the end of the description, add a level-one heading:

```
# Acceptance Criteria
```

Under the heading, list acceptance criteria as Jira action items (checkboxes). Each line must use `[ ]` with a space inside the brackets — `[]` renders as plain text. Prefix each item with `-`:

```
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

Each criterion must be unambiguous and verifiable. Describe the expected outcome, not the implementation — unless implementation details are part of the requirements.

In instructions, references, and acceptance criteria, format every identifier as inline code (`code` mark in ADF): table names, GraphQL types, API paths, env vars, migration names, enum values, etc. Do not leave them as plain text.

### Example of a complete description

```
**As a** data platform engineer
**I want** Spark offloading jobs to skip empty objects instead of failing
**So that** nightly pipelines complete reliably when upstream sends zero-byte files

# References

- [INC-4521](https://jira.example.com/browse/INC-4521) — nightly job failed on zero-byte S3 objects
- [Spark offloading runbook](https://wiki.example.com/spark-offload) — current empty-file behavior

# Acceptance Criteria

- [ ] Job processes a batch containing an empty object without error
- [ ] Empty object is logged with source identifier
- [ ] Existing behavior for non-empty objects is unchanged
- [ ] Unit tests cover the empty-object case
```

### Checklist before creating or updating a ticket

- [ ] Text is in English (unless the user specified otherwise)
- [ ] Summary starts with an action verb (`Implement`, `Check`, `Validate`, `Research`, etc.)
- [ ] Description submitted via REST API v3 as ADF — not via MCP description field
- [ ] Description is concise with high information density — no fluff
- [ ] Description starts with `**As a**...` / `**I want**...` / `**So that**...` with no preceding heading
- [ ] User story labels use `strong` marks in ADF
- [ ] Each user story line keeps label and text on one line — no line break after `As a` / `I want` / `So that`
- [ ] User story is one ADF paragraph with `hardBreak` between complete lines — not three separate paragraphs
- [ ] User story explains the business rationale
- [ ] `References` H1 and linked bullet list present when useful (omitted otherwise)
- [ ] Description ends with `Acceptance Criteria` H1 and `taskList` checkboxes
- [ ] All code-like identifiers use inline code marks (`code` in ADF) — not plain text
- [ ] On updates: all prior description content preserved — styling-only changes unless user requested edits
- [ ] `taskItem` content is inline `text` (no nested `paragraph`)
- [ ] If linking dependencies: `Blocks` created with `inwardIssue`=prerequisite, `outwardIssue`=dependent; UI verified (prerequisite **blocks**, dependent **is blocked by**)
- [ ] If ordering stories: create new tickets in execution order when possible; otherwise Rank via `PUT /rest/agile/1.0/issue/rank` (backward `rankBeforeIssue` chain) and verify with `ORDER BY Rank ASC`
