---
name: article-writing
description: Write engaging, publishable articles and blog posts related to the TodoistIA project or its technical topics. Use this skill when the user wants to share insights, write tutorials, document lessons learned, or create community content. Supports French and English — always ask for the language if not specified. Triggers proactively when the user mentions writing, publishing, sharing, blogging, or creating content for the community — even if they don't say "article" or "blog post" explicitly.
---

# Article Writing

Articles target an **external audience**: community members, developers, potential users, industry peers — readers of a blog or publication. Write with a clear, human voice. No jargon, no corporate speak, no robotic prose.

## When to Activate

- User wants to write a blog post, tutorial, or community piece
- An interesting technical insight or lesson emerged from a session
- User wants to share the project's approach to a problem
- A topic comes up that would benefit external readers
- User says "write something about", "I'd like to publish", "let's draft an article"

## Language Selection

**Always determine the language before writing.**

- If the user specifies a language (e.g., "en francais", "in English", "en anglais") — use it.
- If the language is not specified — ask: "In which language should I write this article? (French or English)"
- Default priority: **English** if context suggests an international audience, **French** if the user writes to you in French or mentions a French-speaking audience.
- Once the language is set for a session, keep it for all subsequent content unless the user changes it.
- Write the entire article — title, sections, takeaway — in the chosen language. Do not mix languages.

## Article Writing Principles

1. **Hook first** — Open with something interesting, a question, or a surprising insight. The first sentence must earn the reader's attention.
2. **One idea per article** — Don't try to cover everything. Pick one clear topic and go deep.
3. **Simple words win** — If a simpler word works, use it. Avoid complexity for its own sake.
4. **Short paragraphs** — 2-4 sentences max per paragraph. White space is your friend.
5. **Tell a story** — Even technical topics benefit from narrative structure. Show a problem, walk through the journey, land on the insight.
6. **End with a takeaway** — What should the reader do or think differently now?

## Output Structure

```
docs/articles/
├── ideas.md               # Backlog of article ideas
├── drafts/
│   └── [slug].md          # Work-in-progress articles
└── published/
    └── [slug].md          # Finalized articles
```

## Article Format

```markdown
# [Compelling Title]

**Topic:** [One-line description]
**Language:** French | English
**Status:** Draft | Ready for Review | Published
**Last Updated:** YYYY-MM-DD

---

[Opening hook — 1-2 sentences that grab attention]

## [Section Title]

[Content — conversational, clear, simple]

## [Section Title]

[Content]

---

**Takeaway**: [One clear sentence on what the reader should remember or do]
```

## Quality Checklist

- [ ] Language confirmed before writing
- [ ] Entire article written in the chosen language (no mixing)
- [ ] Opening hook grabs attention immediately
- [ ] No unnecessary jargon or complex words
- [ ] Paragraphs are short and scannable (2-4 sentences)
- [ ] Single focused idea throughout
- [ ] Ends with a clear takeaway
- [ ] Reads naturally — test by reading aloud
