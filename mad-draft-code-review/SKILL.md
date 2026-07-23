---
name: mad-draft-code-review
description: >-
  Leave unpublished draft code-review comments on GitLab MRs (or GitHub PRs)
  with team-friendly voice, Nit labeling, cross-linked threads, and natural
  closers (Wdyt?, Does it make sense?). Use when the user asks to review a
  merge request or pull request, open a draft review, add review comments
  without publishing, or refine pending draft notes.
---

# Draft Code Review

Perform a technical review and leave **unpublished draft** comments for the user to edit and submit. Do **not** publish, approve, request changes, or submit the review unless the user explicitly asks.

Default comment language: **English** (unless the user requests otherwise).

## Workflow

1. Load MR/PR context: title, description, commits, CI, changed files, full diffs.
2. Review for correctness, edge cases, API contracts, tests, and merge risks (e.g. branch behind target).
3. Create **draft** inline notes on concrete lines plus an optional general overview note.
4. Show the user a short summary of what was left as draft. Keep drafts unpublished.
5. Iterate on wording when the user gives style feedback — update drafts in place; still do not publish unless asked.

### GitLab (preferred when `glab` is available)

Use the Draft Notes API via `glab api` (authenticated as the current user). Draft notes are visible only to their author until published.

```text
GET/POST    /projects/:id/merge_requests/:iid/draft_notes
PUT/DELETE  /projects/:id/merge_requests/:iid/draft_notes/:draft_note_id
```

- General note: `{ "note": "…" }` (no `position`).
- Inline note: include `position` with `base_sha`, `start_sha`, `head_sha`, `position_type: "text"`, `old_path`, `new_path`, and `new_line` (and/or `old_line`).
- Prefer JSON body: `glab api --method POST … -H "Content-Type: application/json" --input <file.json>`.
- Resolve SHAs from the MR `diff_refs`.
- **Never** call publish / `bulk_publish` unless the user explicitly asks to submit.

### GitHub

If the review target is GitHub, use `gh` pending-review APIs equivalently: create a pending review and comments; do not submit until asked.

## What to comment on

- Concrete technical findings with enough context to act on.
- Open design choices and real edge cases.
- Relationships between findings (see below).
- Process notes that are not duplicated inline (e.g. rebase needed) — only in the overview.

### Do not comment on

- Sparse or missing MR/PR descriptions — not a review problem.
- Praise or blame of the author’s work (“Nice work”, “This is sloppy”, etc.). Overall judgment is for the human reviewer to write.
- That the review is a draft / unpublished — the UI already shows that.
- Priority labels (`Low`, `Medium`, `High`, “nitpick priority”, etc.) except the `Nit:` prefix below.

## Overview (general) note

- No title or heading — it is already a review of this MR/PR.
- No praise or criticism of the work.
- Do **not** restate topics covered by inline comments.
- Keep only items that have no inline home (e.g. rebase / conflict with target branch).
- Omit the overview entirely if there is nothing left to say.

## Inline comments

### Nit vs non-nit

- True nits (docs, naming clarity, optional polish): start with `Nit: ` then the content. No other priority wording.
- Non-nits: no priority prefix, no severity labels.

### Voice

- Inclusive team pronouns: `we could`, `could we`, `would it make sense to…`.
- Vary phrasing — do **not** lean on one template (avoid repeating `How about we…` every time).
- Collaborative, not accusatory. Describe behavior and options; do not “call out” mistakes.
- Prefer light formatting. Do not overuse bold. Use inline code for identifiers, paths, types.

### Related comments

- If two threads address the same decision space, **cross-link** them (file/symbol is enough).
- State clearly when addressing one suggestion may cover or invalidate the other.
- Do not duplicate the same ask in overview and inline.

### Closers (optional, only when natural)

Put the closer alone on its **own line** after a blank line. Do not force a closer on every comment.

| Situation | Closer | Notes |
| --- | --- | --- |
| Open decision / choice of approaches | `Wdyt?` | Acronym only; write `Wdyt?` not `WDYT?`. |
| Uncertainty about current behavior or understanding | `Does it make sense?` or `Am I correct?` | Short sentences OK here. |

**Do not use:** `LMK`, long closing sentences for decisions (`Curious what you'd prefer.`, `Thoughts?`, etc.), or closers on clear consistency fixes / soft docs asks where the decision already lives on a related thread.

## Example shapes

Overview (process only):

```text
We could rebase onto current `master` (`pyproject` is already at `1.43.0` there; this branch locks `1.41.0`).
```

Doubt + suggestion:

```text
`_decode_projected_value` runs on every projected field here, including plain leaf projections.

That fits computed `array_map` / `named_struct` results, but it also rewrites leaf `VARCHAR` values that happen to start with `{` or `[`.

We could decode only when the projection used a nested reshape, and leave plain path projections alone.

Does it make sense?
```

Open choice with related thread:

```text
Nit: Nested child `name`s are resolved with `apply_path(root, child.name)`, so they need to be relative to the parent.

Related to the nit on `Projection.projections` in `types.py`: documenting relative `name`s there may be enough. Alternatively, we could reject parent-prefixed paths here — if we do that, the docs-only nit becomes less important.

Wdyt?
```

## Checklist before finishing

- [ ] Comments are drafts only (not published) unless the user asked to submit
- [ ] English (unless user requested another language)
- [ ] No praise/blame overview; no draft meta; no MR-description nags
- [ ] Overview does not duplicate inline topics; no overview title
- [ ] Nits use `Nit: `; no other priority labels; bold used sparingly
- [ ] Inclusive `we` voice; varied phrasing
- [ ] Related threads cross-linked; mutual invalidation called out when relevant
- [ ] Closers only when natural; `Wdyt?` / doubt sentences on their own line; no `LMK`
