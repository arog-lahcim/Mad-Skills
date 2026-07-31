---
name: mad-draft-code-review
description: >-
  Leave unpublished draft code-review comments on GitLab MRs (or GitHub PRs)
  with team-friendly voice, Nit labeling, cross-linked threads, and natural
  closers (Wdyt?, Does it make sense?). Grounds the review in the linked
  ticket's acceptance criteria and the specs it references. On re-review,
  resolve fixed threads (award ✅ only when the author replied); do not leave
  acknowledgment replies. When a review leaves no drafts and the MR looks
  ready to merge, award ✅ on the MR itself.
  Use when the user asks to review a merge request or pull request, open a
  draft review, add review comments without publishing, or refine pending
  draft notes.
---

# Draft Code Review

Perform a technical review and leave **unpublished draft** comments for the user to edit and submit. Do **not** publish, approve, request changes, or submit the review unless the user explicitly asks.

Default comment language: **English** (unless the user requests otherwise).

## Workflow

1. Load MR/PR context: title, description, commits, CI, changed files, full diffs.
2. Load the ticket and the docs it references — see [Ticket and documentation context](#ticket-and-documentation-context).
3. Check out the branch (shallow clone is enough) and read the changed files whole, plus the code paths they contract with — writers of a field a resolver reads, callers of a changed signature. Diff-only review misses mismatches that live in unchanged code.
4. Review for correctness, edge cases, API contracts, tests, and unmet acceptance criteria.
5. Create **draft** inline notes on concrete lines plus an optional general overview note.
6. If this review left **no draft comments** and the MR looks ready to merge, follow [Ready-to-merge signal](#ready-to-merge-signal).
7. Show the user a short summary of what was left as draft (or that none were needed, and whether ✅ was awarded on the MR). Keep drafts unpublished.
8. Iterate on wording when the user gives style feedback — update drafts in place; still do not publish unless asked.
9. On a **re-review** (new commits and/or author replies): verify prior threads against the current diff, then follow [Resolved threads on re-review](#resolved-threads-on-re-review). If that re-review also leaves no new drafts and the MR looks ready to merge, follow [Ready-to-merge signal](#ready-to-merge-signal).

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

## Ticket and documentation context

A diff can be internally consistent and still not deliver what was asked for. Ground the review in the ticket before reading code.

### Find the ticket

- Ticket key from the branch name (`CPL-1024-…`), the MR/PR title, or a `Closes CPL-1024` / `Fixes #123` line in the description.
- Jira: read it with the `mcp-atlassian` MCP (`jira_get_issue`) — read-only MCP use is fine.
- GitLab/GitHub issues: the MR context already lists what it closes; fetch those issues.
- No ticket reference anywhere: review against the diff alone and say so in the summary to the user. Do not draft a comment about the missing reference.

### Follow the ticket's references

Read what the ticket points at, not just its summary:

- The `References` links — specs, ADRs, runbooks, related tickets, incidents.
- Notion via the `notion` MCP (`notion-fetch` takes the page **id** from the URL, not the URL).
- Confluence via `confluence_get_page`.
- Read the **sections the ticket names** (e.g. "sections 3.1, 3.2, 8.2"), plus the glossary and changelog of the spec.

### What this context is for

- **Acceptance criteria vs the diff.** Each criterion: met, partly met, or untestable as written. An unmet AC is a finding — comment on the line that would have to change, not in the overview.
- **Prerequisites the ticket declares.** "Documentation update committed before implementation", "depends on CPL-995 merged" — check whether it actually happened. A spec's changelog / last revision date tells you if the agreed update landed.
- **Spec citations in the code.** When a docstring or comment cites a spec section, open that section. Code claiming a contract the spec does not state — or states for a different level of the model — is a real finding, and often the most valuable one in the review.
- **Decisions already settled in the ticket.** Architectural decisions and answered questions are not open for re-litigation in review comments. Do not suggest an approach the ticket explicitly rejected without acknowledging that it was rejected.
- **Open questions the ticket flags.** If the ticket leaves a question open and the diff quietly answers it, that answer deserves a comment.

Reference the ticket and spec precisely in drafts: ticket key, section number, revision or date. `Quark §8.2` and `CPL-1024 lists this as a prerequisite` are actionable; "per the spec" is not.

### Documentation links in drafts

Whenever a draft cites documentation (Notion, Confluence, ADRs, runbooks, API specs), include a **visible deep link** to the exact section or paragraph whenever one exists — not only the document title or a bare `§7.3`.

Format per `mad-visible-links`: human title (with section) then the full URL as plaintext (clickable). Prefer a heading / block fragment over the page root.

```text
Platform Data Query API §7.3 (Data Object Queries) https://app.notion.com/p/34c0f2e73c5b80a6a335e9b59bced433#34c0f2e73c5b81e7aa86d16674f9c948
```

Resolve the fragment from the fetched doc (in-page TOC links, "Copy link to block", or cross-links that already carry `#…`). If no block/heading URL is available after a reasonable look, link the page and keep the section name in the title — do not invent hashes.

## What to comment on

- Concrete technical findings with enough context to act on.
- Open design choices and real edge cases.
- Acceptance criteria the diff does not meet, and contracts the cited spec does not actually state.
- Relationships between findings (see below).
- Process notes that are not duplicated inline — only in the overview (and only when they affect this change’s correctness or reviewability beyond what the UI already shows).

### Do not comment on

- Sparse or missing MR/PR descriptions, or a missing ticket reference — not a review problem.
- The ticket's own wording or formatting — review the code, not the ticket.
- Scope the ticket explicitly excludes, unless the diff silently depends on it.
- Praise or blame of the author’s work (“Nice work”, “This is sloppy”, etc.). Overall judgment is for the human reviewer to write.
- That the review is a draft / unpublished — the UI already shows that.
- Merge conflicts between the source/current branch and the base/target branch — the UI already shows them and blocks merging until they are resolved.
- That the source branch is behind the target, or asking the author to rebase / merge target into the branch — GitLab/GitHub already surface divergence; it is not a review finding for this MR unless a concrete correctness issue in the diff depends on it (comment on that issue inline, not as a rebase ask).
- Priority labels (`Low`, `Medium`, `High`, “nitpick priority”, etc.) except the `Nit:` prefix below.

## Overview (general) note

- No title or heading — it is already a review of this MR/PR.
- No praise or criticism of the work.
- Do **not** restate topics covered by inline comments.
- Keep only items that have no inline home.
- Do **not** use the overview to request a rebase or to note that the branch is behind the target (see [Do not comment on](#do-not-comment-on)).
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
| Uncertainty about current behavior or understanding | `Does it make sense?`, `Makes sense?`, or `Am I correct?` | Short sentences OK here. |

Vary the closer across a review — do not reuse the same phrase (e.g. `Does it make sense?`) on every comment; rotate through the options above as fits each one.

**Do not use:** `LMK`, long closing sentences for decisions (`Curious what you'd prefer.`, `Thoughts?`, etc.), or closers on clear consistency fixes / soft docs asks where the decision already lives on a related thread.

### Emoji (optional, off by default)

Only add emoji in comment **bodies** if the user asks for a friendlier tone. When enabled:

- Not on every comment — leave plain the ones on serious findings (security, auth, data loss, migrations/infra risk).
- At most one emoji per comment, placed at the very end (after the closer, or after the last sentence if there's no closer) — never mid-paragraph.
- Vary the emoji across comments; do not reuse the same one every time (e.g. don't default to `:thinking:` everywhere).
- Match the emoji to the comment's nature: `:thinking:` for genuine uncertainty/doubt, `:bulb:` for a suggestion, `:slightly_smiling_face:` for a light nit or casual aside.
- Use GitLab/GitHub emoji shortcodes (`:thinking:`, not a raw Unicode character).
- When editing an existing draft note via the GitLab Draft Notes `PUT` endpoint, always resend the full `position` object together with `note` — sending `note` alone wipes the note's inline position.

The ✅ awards below (MR-level ready signal, and thread awards on re-review) are separate from this optional body-emoji mode — apply each only when its section says to.

## Ready-to-merge signal

After finishing the review (first pass or re-review), if **both** are true:

1. This review left **no draft comments** — no inline notes and no overview note.
2. The MR looks ready to merge — acceptance criteria met, no correctness / contract / test / merge-risk findings worth raising.

…then award the check mark button emoji (`white_check_mark` / ✅) on the **merge request itself** (not on a note). Tell the user in the summary that you awarded it.

GitLab:

```text
POST  /projects/:id/merge_requests/:iid/award_emoji
      form: name=white_check_mark
```

**Do not** award MR-level ✅ if you left any drafts, or if the change is not merge-ready (even if you somehow left no comments). This is only an emoji reaction — it is **not** an approval, publish, or merge. Still do not approve / request changes / submit unless the user asks.

GitHub PRs have no `white_check_mark` issue reaction — skip the MR-level award there; say so in the summary if the review was otherwise clean.

## Resolved threads on re-review

When re-reviewing after author replies and/or new commits, check each open thread from prior review rounds against the current code.

Ignore system notes when judging thread contents (e.g. GitLab “changed this line in version N”) — they are not author replies.

**If the finding is properly resolved** (fix or agreed approach is in the diff / reply, nothing left to ask):

- Do **not** leave an acknowledgment reply (“Looks good”, “Works for me”, etc.).
- Resolve the discussion.
- Award the check mark button emoji (`white_check_mark` / ✅) on the **latest non-system note** in that discussion **only if the author (or another participant) replied** in the thread. That is usually the author’s reply.
- If the thread still has only the reviewer’s own comment(s) — the fix landed in new commits with no discussion reply — **resolve only**; do **not** award ✅ on the reviewer’s own note.

GitLab:

```text
# When an author/participant reply exists:
POST  /projects/:id/merge_requests/:iid/notes/:note_id/award_emoji
      form: name=white_check_mark

# Always when fully resolved:
PUT   /projects/:id/merge_requests/:iid/discussions/:discussion_id
      form: resolved=true
```

**If the finding is only partly addressed**, leave a new draft (reply or fresh inline note) on what remains — do not resolve, do not award ✅.

**If a residual nit is distinct from the original ask**, keep it as a new draft on the relevant line; still resolve the original thread when that original ask is done (and award ✅ on the author’s reply only if one exists).

## Example shapes

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
- [ ] Ticket read (or its absence noted to the user); referenced spec sections opened, not assumed
- [ ] Every acceptance criterion checked against the diff; unmet ones raised inline
- [ ] Spec citations in the code verified against the actual section; prerequisites the ticket declares confirmed as done
- [ ] Ticket key, section number and revision/date cited precisely in drafts — no vague "per the spec"
- [ ] Doc citations use visible deep links to the exact section/paragraph when available (title + full URL; no title-only links)
- [ ] No praise/blame overview; no draft meta; no MR-description or missing-ticket nags; no source/base conflict or rebase/behind-target comments
- [ ] Overview does not duplicate inline topics; no overview title; no rebase asks
- [ ] Nits use `Nit: `; no other priority labels; bold used sparingly
- [ ] Inclusive `we` voice; varied phrasing
- [ ] Related threads cross-linked; mutual invalidation called out when relevant
- [ ] Closers only when natural; `Wdyt?` / doubt sentences on their own line; no `LMK`; varied across the review, not the same phrase every time
- [ ] Emoji in comment bodies only if requested; not on every comment; varied, not repeated; skipped on serious findings; `PUT` updates include `position` alongside `note`
- [ ] No drafts + merge-ready → ✅ (`white_check_mark`) on the MR itself; otherwise skip; never treat that as approval
- [ ] Re-review: properly resolved threads are resolved with no acknowledgment reply; ✅ (`white_check_mark`) only on an author/participant reply — not when the thread is still only the reviewer’s comment(s)
