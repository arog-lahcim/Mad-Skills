---
name: mad-process-code-review-inbox
description: >-
  Triage and process code reviews awaiting the current user's reaction:
  discover pending GitLab/GitHub review requests and open mention threads,
  set and keep an inbox chat title for the whole thread, run unpublished
  draft reviews in parallel via mad-draft-code-review, draft replies to
  replies to open questions from Jira/Notion/spec context, never publish
  unless asked, and finish with a verification summary (authors, assignees
  when different, draft ids, links).
  Use when the user asks what reviews await them, to clear their review
  inbox, process pending MRs/PRs in parallel, draft replies to review
  comments, or summarize unpublished draft review work.
---

# Process code review inbox

Discover what needs the current user's reaction, process it with unpublished drafts, and report back with links to verify. Do **not** publish, approve, request changes, or submit unless the user explicitly asks.

Default comment / reply language: **English** (unless the user requests otherwise).

Depends on [mad-draft-code-review](../mad-draft-code-review/SKILL.md) for per-MR/PR review drafts. Follow that skill's voice, Nit rules, closers, and ticket/spec grounding when reviewing. Prefer [mad-visible-links](../mad-visible-links/SKILL.md) in the final summary.

When this skill runs, **own the chat title** for the whole thread — including later per-MR work (re-review, apply feedback) in the same conversation. See [Chat title](#chat-title).

## Workflow

Copy and track:

```
Process code review inbox:
- [ ] 0. Set inbox chat title (keep for whole thread)
- [ ] 1. Identify current user (GitLab + GitHub if both used)
- [ ] 2. Collect awaiting items
- [ ] 3. Apply filters (bots / user exclusions)
- [ ] 4. Classify: review vs reply-needed mention
- [ ] 5. Process in parallel
- [ ] 6. Full summary with verification links
```

## Chat title

Standing authorization to call `rename_chat` at the start of inbox processing — without asking first.

Format:

```
Code review inbox — <short scope>
```

Examples: `Code review inbox — 3 GitLab MRs`, `Code review inbox — mentions only`.

- Set once when processing begins (or when listing if the user will continue in-thread).
- **Do not** retitle per MR when the user later re-reviews or applies draft feedback on one item in this chat.
- When delegating review work to [mad-draft-code-review](../mad-draft-code-review/SKILL.md) (parallel subagents or later single-MR follow-ups in this thread), add an explicit instruction: **do not call `rename_chat`** — keep the inbox title. Identify each MR in reply text only.
- If a follow-up pass would normally invoke `mad-draft-code-review` and its chat-rename step, skip that step here; the inbox title stays unless the user explicitly asks to retitle.

### 1. Identify current user

- GitLab: authenticated user (`glab` / MCP `get_current_user`).
- GitHub: authenticated user (`gh` / MCP `get_me`) when GitHub is in scope.

### 2. Collect awaiting items

**GitLab (preferred sources):**

- Pending todos (`list_my_todos` / todos API): especially `review_requested` and `mentioned` on `MergeRequest`.
- Open MRs where the user is a reviewer and still `UNREVIEWED` / not approved (todos can lag; cross-check).

**GitHub (when relevant):**

- Open PRs with `review-requested:@me` (or the authenticated login).

For each item capture: project, IID/number, title, URL, state (`opened` / `merged`), author, assignee(s), action type (`review_requested` / `mentioned`), and for mentions the discussion URL / note id.

Skip already-handled noise: snoozed todos the user did not ask to clear, and todos whose only target is a fully resolved thread with nothing left to answer — unless the user asked for a full inbox dump.

### 3. Filters

- **Default:** include human-authored review requests and @-mentions that ask a question or need a decision.
- **Ignore Dependabot / Renovate / similar bot dependency PRs** unless the user explicitly wants them.
- Honor extra exclusions from the user (e.g. skip a project, skip merged MRs except open mention threads).

If the user only asked "what awaits me", stop after listing filtered items (with author; assignee only when different from author) and wait — do not start drafts until they ask to process.

### 4. Classify

| Kind | When | Action |
| --- | --- | --- |
| **Review** | Open MR/PR, user requested as reviewer, review incomplete | Run `mad-draft-code-review` |
| **Reply** | Open thread @-mention / question awaiting the user (MR may already be merged) | Draft unpublished reply on that discussion; do not re-review the whole diff unless asked |
| **Skip** | Bot-only dependency bumps (after filter), or nothing actionable left | Omit from processing; mention briefly in the summary if they were filtered |

### 5. Process in parallel

When two or more items need work, process them **in parallel** (separate subagents or concurrent tool batches). Each review item follows `mad-draft-code-review` end-to-end (ticket, referenced Notion/Confluence/spec sections, branch checkout, draft notes only), with the [chat-title override](#chat-title) (no `rename_chat`).

**Reply drafts:**

1. Load the full discussion thread (not only the mentioning note).
2. Load the linked ticket and the docs it cites (same grounding rules as draft code review).
3. Resolve conflicts explicitly (ticket AC vs Notion/spec vs prior comments) and pick a stance with citations (`CPL-997`, `Quark §3.4`, comment dates).
4. Leave an **unpublished** draft reply (`in_reply_to_discussion_id` on GitLab draft notes, or GitHub pending-review reply equivalent).
5. If older unpublished drafts on the same MR already ask the same open question, note them in the summary so the user can delete or edit before publish — do not silently delete others' or prior drafts unless asked.

**Never** `publish` / `bulk_publish` / submit the review.

### 6. Full summary

After processing (or when the user asks for the full summary), report every processed item. Include:

- MR/PR title + URL
- **Author** (name + username)
- **Assignee** only when assignee is a different person from the author (if several assignees, list those that differ)
- Ticket + key spec/doc links used
- Draft note ids with file:line (or `overview` / `reply to discussion …`) and one-line intent
- Short AC checklist when a full review was done (met / partial / unmet)
- How to verify: MR *Pending / Finish review* UI, plus `glab api` / `gh` draft-list command
- Explicit reminder that nothing was published

Omit assignee lines when author and assignee are the same.

## Discovery-only listing

When listing without processing, keep it short:

- Group by platform
- One bullet per item: title link, author (assignee if different), why it awaits reaction (`review`, `mention`), age or created date if useful
- Call out merged MRs that still have an open question thread

## Checklist before finishing

- [ ] Inbox chat title set; per-MR draft-review passes in this thread were told not to call `rename_chat`
- [ ] Current user identified on each platform used
- [ ] Bot dependency PRs filtered unless requested
- [ ] Reviews and reply-needed mentions classified separately
- [ ] Parallelism used when 2+ items were processed
- [ ] Each review followed `mad-draft-code-review` (ticket + referenced docs)
- [ ] Reply drafts grounded in ticket/spec with precise citations
- [ ] Nothing published / approved / submitted
- [ ] Summary includes author; assignee only when different
- [ ] Summary includes draft ids and verification links
