---
name: mad-visible-links
description: >-
  Format hyperlinks as a human title followed by a visible, clickable plaintext
  URL. Use when writing or editing any content that includes links (Markdown,
  Notion, Jira ADF, comments, docs, chat replies) so the URL is readable and
  copyable, not hidden behind title-only link text.
---

# Visible links

## Rule

Every hyperlink must show the **URL as plaintext** and remain clickable.

Format:

```
<title> <url>
```

- `<title>` — human-readable label (not the sole clickable target)
- space separator
- `<url>` — full URL, visible in the text, and clickable when the medium supports links

**Do not** hide the URL behind title-only linked text (e.g. only `Fan-Out Architecture` as the clickable node with no visible `https://…`).

## Mediums

### Markdown / chat / docs

```markdown
Fan-Out and Fan-In Architecture https://app.notion.com/p/38b0f2e73c5b81c384effa2525884123
```

If the renderer needs an explicit markdown link, make the **link text the URL itself**:

```markdown
Fan-Out and Fan-In Architecture [https://app.notion.com/p/38b0f2e73c5b81c384effa2525884123](https://app.notion.com/p/38b0f2e73c5b81c384effa2525884123)
```

Wrong:

```markdown
[Fan-Out and Fan-In Architecture](https://app.notion.com/p/38b0f2e73c5b81c384effa2525884123)
```

### Jira / Confluence ADF

Two adjacent text nodes:

1. Plain title + trailing space
2. URL text with `link` mark whose `href` equals that URL text

```json
[
  {"type": "text", "text": "Fan-Out and Fan-In Architecture "},
  {
    "type": "text",
    "text": "https://app.notion.com/p/38b0f2e73c5b81c384effa2525884123",
    "marks": [{"type": "link", "attrs": {"href": "https://app.notion.com/p/38b0f2e73c5b81c384effa2525884123"}}]
  }
]
```

Helper:

```python
def visible_link(title: str, url: str) -> list:
    return [
        {"type": "text", "text": f"{title} "},
        {"type": "text", "text": url, "marks": [{"type": "link", "attrs": {"href": url}}]},
    ]
```

Prefix labels when needed: `[text("Repo: "), *visible_link("dummy-fan-service-api", "https://…")]`.

For Jira bodies that drop markdown link marks, submit ADF via REST (not MCP markdown description/comment fields).

### Notion

Prefer title then full URL on the same line. If using a mention/page link that hides the URL, also include the plain URL next to it.

### GitLab notes (MR / issue comments)

GitLab auto-discovers bare `!N` (merge requests) and `#N` (issues) and resolves them in the **project of the note**, ignoring nearby project names in prose. `custom-resource-webhook !5` posted on a `platform-api` MR becomes a link to `platform-api!5`.

- Do **not** use bare `!N` / `#N` in GitLab comment bodies for cross-project targets.
- Prefer prose without the trigger character (`MR 5`, `issue 12`) plus a full visible URL.
- When pointing at the change itself, prefer the `/diffs` URL:

```text
custom-resource-webhook MR 5 diffs https://gitlab.com/cledar/cledar-platform/platform-integrations/custom-resource-webhook/-/merge_requests/5/diffs
```

`mad-draft-code-review` owns the full review checklist for this trap; apply the same rule whenever writing GitLab note text outside that skill.

## Do not

- Use title-only linked text that conceals the URL
- Use bare URLs without a title when a clear document/repo name exists
- Wrap the URL in inline code (hurts click/copy affordance)
- Shorten or omit the scheme/`https://` when the full URL is known
- Rely on GitLab bare `!N` / `#N` (or project-name + `!N` without a full URL) for cross-project references in comment bodies
