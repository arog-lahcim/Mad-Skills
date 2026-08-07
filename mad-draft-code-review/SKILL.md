---
name: mad-draft-code-review
description: >-
  Leave unpublished draft code-review comments on GitLab MRs (or GitHub PRs)
  with team-friendly voice, Nit labeling, cross-linked threads, and natural
  closers (Wdyt?, Does it make sense?). Grounds the review in the linked
  ticket's acceptance criteria and the specs it references. After posting,
  summarize drafts, explain how to steer them (bullets under drafts), and end
  every pass by asking the user what to do next as an interactive
  multiple-choice question instead of listing options in prose. Never recreate
  drafts the user deleted
  unless they explicitly ask. On re-review, resolve fixed threads (award ✅
  only when the author replied); do not leave acknowledgment replies. When a
  review leaves no drafts and the MR looks ready to merge, award ✅ on the MR
  itself. If a re-review instead leaves new required-change drafts, remove any
  prior MR-level ✅ and replace it with 💬 (`speech_balloon`). Renames the chat
  to a fixed MR title format as soon as the MR is identified.
  Use when the user asks to review a merge request or pull request, open a
  draft review, add review comments without publishing, refine pending draft
  notes, or apply edits / decisions left under existing drafts.
---

# Draft Code Review

Perform a technical review and leave **unpublished draft** comments for the user to edit and submit. Do **not** publish, approve, request changes, or submit the review unless the user explicitly asks.

Default comment language: **English** (unless the user requests otherwise).

## Workflow

1. Load MR/PR context: title, description, commits, CI, changed files, full diffs.
2. Rename the chat — see [Chat title](#chat-title). Do this as soon as the MR `iid` and author are known; do not wait for the review to finish.
3. Load the ticket and the docs it references — see [Ticket and documentation context](#ticket-and-documentation-context).
4. Check out the branch (shallow clone is enough) and read the changed files whole, plus the code paths they contract with — writers of a field a resolver reads, callers of a changed signature. Diff-only review misses mismatches that live in unchanged code.
5. Review for correctness, edge cases, API contracts, tests, and unmet acceptance criteria.
6. Create **draft** inline notes on **diff lines only** (see [Anchor on diff lines](#anchor-on-diff-lines)) plus an optional general overview note.
7. If this review left **no draft comments** and the MR looks ready to merge, follow [Ready-to-merge signal](#ready-to-merge-signal). If this is a **re-review** that left new drafts for required changes, follow [Needs-work signal](#needs-work-signal) instead.
8. Show the user a **short summary** of what was left as draft (or that none were needed, and whether ✅ / 💬 was set on the MR). Keep drafts unpublished.
9. After that summary, say briefly how to steer the drafts, then **ask what to do next as an interactive question** — see [After posting drafts](#after-posting-drafts).
10. On a **follow-up apply pass** (user re-invokes this skill to process draft edits): follow [Apply draft feedback](#apply-draft-feedback). Do **not** republish deleted drafts.
11. On a **re-review** (new commits and/or author replies): verify prior threads against the current diff, then follow [Resolved threads on re-review](#resolved-threads-on-re-review). If that re-review also leaves no new drafts and the MR looks ready to merge, follow [Ready-to-merge signal](#ready-to-merge-signal). If it leaves new drafts for required changes, follow [Needs-work signal](#needs-work-signal).

## Chat title

This skill is standing authorization to call `rename_chat` — do it without asking the user first.

As soon as the MR is identified (and after the first user prompt of the chat has been sent — Cursor auto-naming overwrites titles set earlier), rename the chat to:

```
MR !<iid> (<JIRA-KEY>) - <MR author name> - <context>
```

- `<iid>` — GitLab MR `iid`, always prefixed with `!`.
- `<JIRA-KEY>` — Jira key from the MR title, source branch, or description. Omit the parentheses entirely when the MR references no ticket.
- `<MR author name>` — `author.name` of the MR (its creator); never the reviewer or the current user.
- `<context>` — a few words for the work in this chat, e.g. `review`, `re-review`, `apply draft feedback`, `fix failing CI`.

Separator is ` - ` (space, hyphen, space). Example: `MR !482 (PROJ-123) - Anna Kowalska - review`.

Also rename on apply-feedback and re-review passes if the title is still wrong or missing the MR prefix.

### GitLab (preferred when `glab` is available)

Use the Draft Notes API via `glab api` (authenticated as the current user). Draft notes are visible only to their author until published.

```text
GET/POST    /projects/:id/merge_requests/:iid/draft_notes
PUT/DELETE  /projects/:id/merge_requests/:iid/draft_notes/:draft_note_id
```

- General note: `{ "note": "…" }` (no `position`).
- Inline note: include `position` with `base_sha`, `start_sha`, `head_sha`, `position_type: "text"`, `old_path`, `new_path`, and `new_line` (and/or `old_line`). The line must be a **changed** line in the MR diff — see [Anchor on diff lines](#anchor-on-diff-lines).
- Prefer JSON body: `glab api --method POST … -H "Content-Type: application/json" --input <file.json>`.
- Resolve SHAs from the MR `diff_refs`.
- **Never** call publish / `bulk_publish` unless the user explicitly asks to submit.
- When editing an existing draft via `PUT`, always resend the full `position` object together with `note` — sending `note` alone wipes the inline position.

### GitHub

If the review target is GitHub, use `gh` pending-review APIs equivalently: create a pending review and comments; do not submit until asked. Same rule: only comment on lines in the PR diff ([Anchor on diff lines](#anchor-on-diff-lines)).

## After posting drafts

End the user-facing reply with three parts, in this order:

1. **Summary** — brief list of draft topics / files (or “no drafts; ✅ on MR” when applicable).
2. **How to steer the drafts** — two short lines, no more:

- Edit or **delete** any draft in the MR UI; deleted drafts stay gone.
- Under a draft you want changed, append **bullet points** with decisions or rewrite instructions (e.g. `- yes, require ContainerSource — rewrite as a firm ask`). Free-form notes at the end of a draft also count.

3. **Closing question** — ask what to do next interactively; do **not** list next steps as prose bullets.

### Closing question

Every pass (first review, apply-feedback, re-review) ends by **asking**, never with a bare list of options. Prefer the multiple-choice question tool (`AskQuestion`) so the user picks instead of retyping a command. If that tool is unavailable in the current environment, ask the same question in the chat reply as a short numbered choice the user can answer by number or label — still a question, not a prose bullet list of “what you can do”.

Offer only the steps that apply to this pass, e.g.:

- `Apply my draft edits now` — re-run [Apply draft feedback](#apply-draft-feedback) in this chat. Recommended whenever drafts exist.
- `Re-review the latest commits` — fresh pass against the current diff.
- `Publish the drafts as a review` — picking this **is** the explicit go-ahead to publish; without it, never publish.
- `Nothing for now — I'll edit in the MR UI`.

Rules:

- One question, single choice, at most four options; recommended option first, suffixed `(Recommended)`.
- Drop options that make no sense for the pass — no apply/publish option when nothing was drafted, no re-review option when no new commits are plausible yet.
- Act on the answer in the same chat rather than restating it: an apply choice runs the apply pass, a re-review choice starts a new round.
- Keep the typed equivalent working for users who prefer text:

```text
/mad-draft-code-review apply draft feedback on <MR URL>
```

Other valid phrasings: “apply my draft edits”, “update drafts from my bullets”, “process draft feedback” + the MR/PR link. Attaching this skill and pointing at the same MR is enough when the intent is clearly to apply feedback rather than start a full new review.

Beyond the single publish option, do **not** pad the closing question or the reply with publish/approve guidance unless the user asked how to submit.

## Apply draft feedback

When the user re-invokes this skill to apply feedback on existing drafts:

1. `GET` current draft notes for the MR/PR. Treat that list as authoritative.
2. **Never recreate** drafts the user deleted, and do not re-add topics from an earlier pass that are no longer present — unless the user **explicitly** asks to restore a specific comment.
3. For each remaining draft that has user-added bullets or trailing notes:
   - Read them as instructions/decisions for **that** comment.
   - Rewrite the draft body to match (firm ask vs open question, scope, links, tone).
   - **Remove** the instructional bullets / “update this comment” meta from the published-facing text.
   - End the rewritten body with the correct signature alone on its final line — `🧑‍💻` if the body is fully the human's substance, otherwise `🤖+🧑‍💻` (see [Comment signature](#comment-signature-required)).
   - `PUT` the updated note **with full `position`** (GitLab) so the inline anchor is preserved.
4. Leave drafts without new user marks unchanged.
5. Do not start a full re-review of the diff unless the user also asked for one (new commits / re-review).
6. Reply with a short summary of which drafts were updated (and which deleted ones were left deleted), then close with the interactive question — see [Closing question](#closing-question).

Example: a draft ends with `- yes we do want to use ContainerSource … Update this comment.` → rewrite the body into a direct ask to use `ContainerSource` (with the cited links), drop the bullet, keep the same line anchor.

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

- **Acceptance criteria vs the diff.** Each criterion: met, partly met, or untestable as written. An unmet AC is a finding — anchor the draft on a related **changed** line (name the untouched symbol/path in the body if needed), not on an unchanged line and not only in the overview when a diff anchor exists.
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

### Anchor on diff lines

GitLab and GitHub only surface inline comments on lines that appear in the MR/PR **Changes** diff. A draft pinned to an **unchanged** line (including unchanged context around a hunk) is easy to create via the API but often **invisible** in the review UI.

- Before posting an inline note, confirm the target line is **added, removed, or modified** in the current MR/PR diff (not merely present in the file or in hunk context).
- Prefer `new_line` for added/modified lines on the new side; use `old_line` (alone or with the matching deletion) for removed lines.
- Still **read** unchanged callers, writers, and contracts (workflow step 3). When the finding lives there, pin the draft to the **nearest related changed line** and name the unchanged symbol/path/line in the comment body. If no related changed line exists in any touched file, use a general overview note instead of an invisible inline.
- Do **not** pick an arbitrary nearby context line just because it is close in the file — only lines that are themselves changed.
- On re-review, new inline drafts follow the same rule against the **current** diff.

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

### Comment signature (required)

Every draft this skill writes — inline and overview, first pass and apply-feedback rewrite — ends with a signature alone on its **own final line**, after a blank line (same spacing as a closer).

| When | Signature |
| --- | --- |
| Agent-only draft (no human edit of this comment yet) | `🤖` |
| Shared authorship — agent finding refined with human bullets/decisions, or a discussion follow-up that still mixes agent analysis with human steering | `🤖+🧑‍💻` |
| Human content — the body is **100%** the person's statement, decision, or wording (agent only posted / lightly formatted it for MR voice). Includes: "write this answer…", paste-my-words replies, and apply-feedback rewrites that replace the draft with the human's substance rather than merging it into an agent finding | `🧑‍💻` |

```text
🤖
```

```text
🤖+🧑‍💻
```

```text
🧑‍💻
```

- Do **not** put the signature mid-paragraph, on the same line as a closer, or omit it.
- Use the Unicode emoji (`🤖`, `🧑‍💻`) — not `:robot:` / `:technologist:` shortcodes.
- Apply-feedback `PUT`s: strip instructional bullets, then pick `🤖+🧑‍💻` or `🧑‍💻` from the table (never leave a bare `🤖` after a human-steered rewrite). Prefer `🧑‍💻` when the rewritten body is essentially the human's decision in full; prefer `🤖+🧑‍💻` when the agent finding remains and the human only steered tone/scope/firmness.
- Re-review drafts that only restate an unresolved agent finding stay `🤖`; mixed or human-owned wording uses the rows above.
- When editing a **published** note the same rules apply.

### Emoji in the body (optional, off by default)

Only add emoji in comment **bodies** (aside from the required signature) if the user asks for a friendlier tone. When enabled:

- Not on every comment — leave plain the ones on serious findings (security, auth, data loss, migrations/infra risk).
- At most one body emoji per comment, placed just before the signature line (after the closer, or after the last sentence if there's no closer) — never mid-paragraph, never after the signature.
- Vary the body emoji across comments; do not reuse the same one every time (e.g. don't default to `:thinking:` everywhere).
- Match the emoji to the comment's nature: `:thinking:` for genuine uncertainty/doubt, `:bulb:` for a suggestion, `:slightly_smiling_face:` for a light nit or casual aside.
- Use GitLab/GitHub emoji shortcodes for body emoji (`:thinking:`, not a raw Unicode character). The required signature stays `🤖`, `🤖+🧑‍💻`, or `🧑‍💻`.

The ✅ awards below (MR-level ready signal, and thread awards on re-review) are separate from body emoji and from the signature — apply each only when its section says to.

## Ready-to-merge signal

After finishing the review (first pass or re-review), if **both** are true:

1. This review left **no draft comments** — no inline notes and no overview note.
2. The MR looks ready to merge — acceptance criteria met, no correctness / contract / test / merge-risk findings worth raising.

…then award the check mark button emoji (`white_check_mark` / ✅) on the **merge request itself** (not on a note). If a prior `speech_balloon` / 💬 is present from [Needs-work signal](#needs-work-signal), **delete that award first**, then award ✅. Tell the user in the summary that you awarded it.

GitLab:

```text
# If a prior needs-work balloon exists, remove it first:
GET     /projects/:id/merge_requests/:iid/award_emoji
DELETE  /projects/:id/merge_requests/:iid/award_emoji/:award_id
        # only for name=speech_balloon awarded by the current user

POST  /projects/:id/merge_requests/:iid/award_emoji
      form: name=white_check_mark
```

**Do not** award MR-level ✅ if you left any drafts, or if the change is not merge-ready (even if you somehow left no comments). This is only an emoji reaction — it is **not** an approval, publish, or merge. Still do not approve / request changes / submit unless the user asks.

GitHub PRs have no `white_check_mark` issue reaction — skip the MR-level award there; say so in the summary if the review was otherwise clean.

## Needs-work signal

After a **re-review**, if this pass left **new draft comments for required changes** (the MR is no longer merge-ready — any draft that would block [Ready-to-merge signal](#ready-to-merge-signal), including non-`Nit:` findings; pure optional nits alone do not trigger this), and the MR currently has a `white_check_mark` / ✅ from an earlier ready signal:

1. **Delete** the current user's MR-level `white_check_mark` award.
2. **Award** the speech balloon button emoji (`speech_balloon` / 💬) on the **merge request itself**.
3. Tell the user in the summary that ✅ was replaced with 💬 because new required changes were drafted.

Do **not** leave both ✅ and 💬 on the MR. Do **not** add 💬 on a first-pass review that never had ✅ — only when clearing a prior ready signal after a re-review found more required work.

GitLab:

```text
GET     /projects/:id/merge_requests/:iid/award_emoji
DELETE  /projects/:id/merge_requests/:iid/award_emoji/:award_id
        # only for name=white_check_mark awarded by the current user

POST  /projects/:id/merge_requests/:iid/award_emoji
      form: name=speech_balloon
```

If there was no prior ✅, skip the delete; still skip adding 💬 unless a prior ready signal is being withdrawn. GitHub: skip MR-level reaction swap (same limitation as ready-to-merge).

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

🤖
```

Open choice with related thread:

```text
Nit: Nested child `name`s are resolved with `apply_path(root, child.name)`, so they need to be relative to the parent.

Related to the nit on `Projection.projections` in `types.py`: documenting relative `name`s there may be enough. Alternatively, we could reject parent-prefixed paths here — if we do that, the docs-only nit becomes less important.

Wdyt?

🤖
```

## Checklist before finishing

- [ ] Chat renamed to `MR !<iid> (<JIRA-KEY>) - <author> - <context>` (or without `(<JIRA-KEY>)` when none); author is MR creator
- [ ] Comments are drafts only (not published) unless the user asked to submit
- [ ] Every inline draft is on an added/removed/modified diff line (unchanged-code findings re-anchored or overview); no invisible unchanged-line pins
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
- [ ] Every draft (inline and overview) ends with `🤖`, `🤖+🧑‍💻`, or `🧑‍💻` alone on its final line after a blank line — `🧑‍💻` when the body is 100% human substance; `🤖+🧑‍💻` for shared authorship; apply-feedback never leaves bare `🤖`
- [ ] Body emoji only if requested; not on every comment; varied, not repeated; skipped on serious findings; never after the signature; `PUT` updates include `position` alongside `note`
- [ ] After posting: short draft summary **plus** two lines on steering drafts (edit/delete in UI, bullets under a draft)
- [ ] Pass ends with an interactive `AskQuestion` (single choice, ≤4 applicable options, recommended first) — not a prose list of next steps; answer acted on in the same chat
- [ ] Apply-feedback pass: only update drafts that still exist; never recreate user-deleted drafts unless explicitly asked; strip instructional bullets from the final draft text
- [ ] No drafts + merge-ready → ✅ (`white_check_mark`) on the MR itself (remove prior 💬 first if present); otherwise skip; never treat that as approval
- [ ] Re-review left required-change drafts after a prior ✅ → delete MR-level `white_check_mark`, award `speech_balloon` / 💬 instead; do not leave both
- [ ] Re-review: properly resolved threads are resolved with no acknowledgment reply; ✅ (`white_check_mark`) only on an author/participant reply — not when the thread is still only the reviewer’s comment(s)
