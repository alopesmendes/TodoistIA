---
description: Write or update project documentation. Select the type (technical/functional/article), specify the file to create or update, and define the change intent (--clean, --easier, --detailed, or a custom description).
---

# /docs — Documentation Writer

Write or update a specific documentation file with clear intent. Unlike `/update-docs` which operates on documentation structure (insert/delete/correct), this command focuses on the *quality and content* of a document — creating it from scratch or reshaping what's already there.

## Syntax

```
/docs <type> <file> [mode]
```

| Argument | Values                                                            | Description                    |
|----------|-------------------------------------------------------------------|--------------------------------|
| `type`   | `technical` \| `functional` \| `article`                          | Which documentation axis       |
| `file`   | File path relative to project root, or `new "<title>"`            | Target doc to create or update |
| `mode`   | `--clean` \| `--easier` \| `--detailed` \| `"custom description"` | What kind of change to make    |

## Modes

| Mode                   | What it does                                                                                                                    |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| `--clean`              | Remove redundancy, fix structure and formatting, trim unnecessary prose. Content stays the same, presentation improves.         |
| `--easier`             | Simplify language, add missing context, reduce jargon. Target: someone joining the project for the first time.                  |
| `--detailed`           | Expand thin sections, add examples, add diagrams, surface edge cases. Target: a developer debugging or extending the component. |
| `"custom description"` | Follow the user's specific instruction exactly. Can combine any of the above or describe something entirely different.          |

If no mode is given and the file exists, ask the user which mode they want before proceeding.

## Examples

```bash
# Create a new technical doc for a module
/docs technical new "shared module"

# Clean up an existing architecture doc
/docs technical docs/technical/architecture.md --clean

# Make a functional feature spec easier to read
/docs functional docs/functional/features/tasks.md --easier

# Expand a module doc with more detail and diagrams
/docs technical docs/technical/modules/server.md --detailed

# Custom instruction
/docs technical docs/technical/modules/shared.md "add a sequence diagram for the sync flow and expand the data flow section"

# New article draft
/docs article new "how we handle offline sync in KMP"

# Update an existing article draft
/docs article docs/articles/drafts/kmp-shared-viewmodels.md "add code examples for StateFlow and SharedFlow"
```

## Workflow

### For `new` files

1. **Explore** — Use Glob/Grep to understand the surrounding context (related modules, existing patterns, sibling docs)
2. **Invoke the matching skill** — delegate to `technical-docs`, `functional-docs`, or `article-writing` skill based on `type`
3. **Create the file** — follow the skill's format and quality checklist
4. **Diagrams** — if type is `technical` and the component warrants a diagram, invoke the `mermaid-diagram` skill
5. **Timestamp** — add `Last Updated: YYYY-MM-DD`

### For existing files

1. **Read the file** — understand its current state fully before changing anything
2. **Apply the mode**:
   - `--clean`: reorganize, trim, fix formatting — no content changes
   - `--easier`: rewrite dense passages, add a glossary of terms if needed, use shorter sentences
   - `--detailed`: identify thin sections, research the actual code, add examples and diagrams
   - `"custom"`: follow the instruction literally, ask if anything is ambiguous
3. **Diagrams** — if mode is `--detailed` or the custom instruction mentions diagrams, invoke `mermaid-diagram` skill
4. **Update timestamp** — always update `Last Updated: YYYY-MM-DD`

## Type-Specific Rules

### technical
- All file paths must be verified with Glob/Grep before referencing
- Dependencies must match actual entries in `libs.versions.toml`
- Use the `mermaid-diagram` skill for all diagrams (never inline ad-hoc Mermaid)
- Output goes in `docs/technical/`

### functional
- Zero technical implementation details (no code, no file paths, no framework names)
- Every business rule needs: condition, behavior, and exception
- DDD terms must be consistent with `docs/functional/glossary.md`
- Readable by PO, Dev, QA, Designer, and Manager alike
- Output goes in `docs/functional/`

### article
- Confirm language (French or English) before writing
- Hook the reader in the first sentence
- One focused idea — go deep, not wide
- Short paragraphs (2–4 sentences), conversational tone
- Ends with a clear takeaway
- Output goes in `docs/articles/drafts/` for new drafts

## Skills Used

| Condition | Skill invoked |
|-----------|--------------|
| `type` is `technical` | `technical-docs` |
| `type` is `functional` | `functional-docs` |
| `type` is `article` | `article-writing` |
| Mode is `--detailed` or diagram requested | `mermaid-diagram` |

## Related Commands

- `/update-docs` — structural operations (insert/delete/correct) across all axes
- `/verify` — verify that code changes are reflected in docs
- `/plan` — use before creating technical docs for a new feature
