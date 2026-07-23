---
name: mad-git-commit
description: >-
  Create git commits using Cledar conventional-commit message rules. Use when
  the user asks to commit, write a commit message, stage and commit, or amend
  a commit message.
---

# Git Commit

Follow [Guidelines for Version Control](https://app.notion.com/p/Guidelines-for-Version-Control-2400f2e73c5b80c18aebf6cc839cc782) for commit messages. Commits (especially those reaching `main`) must match the conventional-commit pattern so semantic release can derive versions.

## Message format

```
type: subject
type(TICKET-123): subject
```

Allowed forms (must match):

```
^(build|ci|docs|feat|fix|perf|refactor|test)(\([A-Z][A-Z0-9]+-\d+\))?: .+
^Merge \w+
^Initial commit$
^Notes added by 'git notes add'$
```

| Part | Rules |
| --- | --- |
| `type` | One of: `build`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `test` |
| `scope` | Jira-style key only: `PROJ-123` (`[A-Z][A-Z0-9]+-\d+`). Wrap in parentheses with no spaces: `feat(ABC-123): …`. **Required** when the current branch name contains a ticket id — extract that id and put it in the scope. Omit scope only when the branch has no ticket id |
| `subject` | Required. Concise summary after `: ` (space required). Prefer imperative mood; match the repo’s existing commit style when one exists |

**Do not** use types outside the list (`chore`, `style`, `revert`, etc.). **Do not** invent free-form scopes (folder names, package names) — scope is only a ticket key, or omit it.

**Create a clean commit on the first attempt.** The commit message must contain only the intended conventional-commit subject and body. Do not record Cursor or any other AI/agent as a co-author or contributor, including trailers such as `Co-authored-by` or `Made-with`.

Before running `git commit` in Cursor IDE, ensure **Cursor Settings → Agent → Attribution → Commit Attribution** is disabled. If the environment is known to inject attribution and this cannot be confirmed, stop before committing and ask the user to disable it. Do not create a commit and then amend or rewrite it solely to remove attribution.

### Examples

```
feat: add mad-update-skills skill
feat(ABC-123): add new feature
fix(DATA-1284): handle empty Spark input objects
docs: clarify global skills install symlink
refactor(API-90): extract artifact registry client
```

Branch `ABC-123-new-widget` → message must use scope `ABC-123`, e.g. `feat(ABC-123): add new feature`.

### Merge requests into `main`

MR titles into `main` may use only these prefixes: `fix`, `feature`, or `BREAKING CHANGE` (per the same guidelines). Prefer aligning the MR title with the release intent; commit messages still use the `type:` forms above (`feat` / `fix`, etc.).

## Commit workflow

Only commit when the user asks. Never update git config, never `--force` push, never skip hooks unless explicitly requested.

1. In parallel, inspect state:
   - `git status`
   - `git branch --show-current` (or `git status -sb`) — if the branch name matches `[A-Z][A-Z0-9]+-\d+`, that ticket **must** be the message scope
   - `git diff` and `git diff --cached`
   - `git log -5 --oneline` (match message style)
2. Draft a message that matches the format above. Prefer why/impact in the subject when it still fits one line; keep it short. No agent attribution in the message or trailers.
3. Stage relevant files only (no secrets: `.env`, credentials, tokens).
4. Commit with a HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
feat(ABC-123): short subject here

EOF
)"
```

5. Run `git status` after and confirm success. Verify the full message has no agent attribution in subject, body, or trailers (`git log -1 --format=%B`).

If a pre-commit hook fails, fix the issue and create a **new** commit — do not amend unless the user asked to amend and the amend safety rules below are met.

### Amend (rare)

Use `--amend` only when all are true:

- User explicitly requested amend, **or** the commit succeeded but a hook auto-modified files that must be included
- `HEAD` was created by you in this conversation
- Commit has **not** been pushed

Otherwise create a new commit.
