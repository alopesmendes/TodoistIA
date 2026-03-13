---
description: Update project documentation across three axes — technical (architecture, modules, data flows), functional (business rules, user stories, DDD glossary), and articles (ideas, drafts, published posts). Supports insert, update, delete, and correct operations.
---

# Update Docs Command

This command invokes the **doc-updater** agent to maintain documentation across three independent axes.

## The Three Axes

| Axis           | Audience                                    | Location           | Purpose                                                           |
|----------------|---------------------------------------------|--------------------|-------------------------------------------------------------------|
| **Technical**  | Developers                                  | `docs/technical/`  | Architecture, modules, data flows, API contracts, file references |
| **Functional** | Whole team (PO, Dev, QA, Designer, Manager) | `docs/functional/` | Business rules, features, user stories, DDD glossary              |
| **Articles**   | External community                          | `docs/articles/`   | Blog posts, tutorials, lessons learned, community content         |

## Operations per Axis

Each axis supports a specific set of operations:

### Technical Documentation

| Operation  | When to Use                                                         |
|------------|---------------------------------------------------------------------|
| **Insert** | New module, service, dependency, or data flow added to the codebase |
| **Update** | Architecture refactor, dependency upgrade, file structure change    |
| **Delete** | Module removed, deprecated service decommissioned, dead docs        |

### Functional Documentation

| Operation   | When to Use                                                            |
|-------------|------------------------------------------------------------------------|
| **Insert**  | New feature specified, new business rule defined, new DDD term emerged |
| **Update**  | Business rule changed, feature scope refined, persona evolved          |
| **Delete**  | Feature dropped, business rule deprecated, term retired                |
| **Correct** | Wrong rule documented, inaccurate user story, inconsistent DDD term    |

### Articles

| Operation   | When to Use                                                             |
|-------------|-------------------------------------------------------------------------|
| **Insert**  | New idea to `ideas.md`, new draft in `drafts/`, publish to `published/` |
| **Update**  | Refine a draft, improve a published article, add a section              |
| **Delete**  | Abandon an idea, remove an outdated draft, unpublish                    |
| **Correct** | Fix factual errors, update outdated information, fix tone issues        |

## Usage

```
/update-docs <axis> <operation> <target>
```

### Examples

```
# Technical
/update-docs technical insert new shared module "task-ai" for AI-powered task suggestions
/update-docs technical update architecture diagram — added Ktor WebSocket support
/update-docs technical delete old auth module docs — module was removed

# Functional
/update-docs functional insert business rules for recurring tasks
/update-docs functional update user story for task creation — now supports labels
/update-docs functional delete feature spec for "gamification" — dropped from roadmap
/update-docs functional correct business rule #3 — downgrade is immediate, not delayed

# Articles
/update-docs articles insert idea about how we handle offline sync in KMP
/update-docs articles update draft "kmp-shared-viewmodels" — add code examples
/update-docs articles delete draft "old-architecture" — no longer relevant
/update-docs articles correct published "ktor-setup" — Ktor 3.x API changed
```

## How It Works

The doc-updater agent will:

1. **Identify the axis** — Technical, Functional, or Articles
2. **Identify the operation** — Insert, Update, Delete, or Correct
3. **Explore the current state** — Read existing docs in the target directory
4. **Execute the operation** — Apply the change following the axis-specific format
5. **Cross-check** — Verify consistency (DDD terms, file paths, glossary references)
6. **Timestamp** — Add or update `Last Updated: YYYY-MM-DD` on every modified document

## Axis Details

### Technical — `docs/technical/`

```
docs/technical/
├── README.md              # Technical overview and entry points
├── architecture.md        # High-level architecture (Mermaid diagrams)
├── modules/
│   ├── shared.md          # Shared KMP module
│   ├── server.md          # Ktor server module
│   └── compose-app.md     # Compose Multiplatform UI module
└── data-flow.md           # How data moves through the system
```

**Rules:**
- All file paths must be verified with Glob/Grep before referencing
- Use Mermaid diagrams (`graph TD`, `sequenceDiagram`, `classDiagram`, `erDiagram`)
- List dependencies with actual package names from `libs.versions.toml`
- No assumptions — only documented reality
- Every doc has a `Last Updated` timestamp

### Functional — `docs/functional/`

```
docs/functional/
├── README.md              # Product overview and target audience
├── glossary.md            # DDD Ubiquitous Language Glossary
├── features/
│   └── [feature-name].md  # Per-feature functional spec
└── business-rules.md      # All business rules consolidated
```

**Rules:**
- No technical implementation details (no code, no file paths, no frameworks)
- Every business rule has: condition, behavior, and exception
- DDD glossary terms must have: term, definition, context, example, synonyms to avoid
- User stories follow: **As a** [persona], **I want to** [action], **so that** [outcome]
- Must be readable by PO, Dev, QA, Designer, and Manager alike

### Articles — `docs/articles/`

```
docs/articles/
├── ideas.md               # Backlog of article ideas
├── drafts/
│   └── [slug].md          # Work-in-progress articles
└── published/
    └── [slug].md          # Finalized, ready-to-publish articles
```

**Rules:**
- Always confirm the language (French or English) before writing
- Hook the reader in the opening sentence
- One idea per article — go deep, not wide
- Short paragraphs (2-4 sentences), simple words, conversational tone
- Every article ends with a clear takeaway
- Status tracking: `Draft` → `Ready for Review` → `Published`

## Decision Matrix

Not sure which axis to use? Follow this:

```
Was code changed?
├── Yes → Was it an architecture/structural change?
│   ├── Yes → Technical (insert or update)
│   └── No → Does it affect business behavior?
│       ├── Yes → Functional (update or correct)
│       └── No → Probably no doc update needed
└── No → Is it a business/product decision?
    ├── Yes → Functional (insert, update, or correct)
    └── No → Is it a shareable insight or lesson?
        ├── Yes → Articles (insert idea or draft)
        └── No → No doc update needed
```

## Proactive Triggers

The doc-updater agent should be invoked automatically after:

| Event                                | Axis                   | Operation            |
|--------------------------------------|------------------------|----------------------|
| New feature implemented              | Technical + Functional | Insert               |
| Architecture refactored              | Technical              | Update               |
| Business rule defined or changed     | Functional             | Insert or Update     |
| New DDD term used in conversation    | Functional             | Insert into glossary |
| Module added or removed              | Technical              | Insert or Delete     |
| Dependency added or upgraded         | Technical              | Update               |
| Interesting insight during a session | Articles               | Insert idea          |
| User says "write about this"         | Articles               | Insert draft         |

## Quality Checklists

### Technical
- [ ] All file paths verified to exist (Glob/Grep confirmed)
- [ ] Mermaid diagrams have valid syntax
- [ ] Dependencies match actual `libs.versions.toml` entries
- [ ] `Last Updated` timestamp present
- [ ] A new developer could understand the component from the doc alone

### Functional
- [ ] Zero technical implementation details
- [ ] Every business rule has condition + behavior + exception
- [ ] DDD terms consistent with `docs/functional/glossary.md`
- [ ] Target audiences identified
- [ ] Readable by all roles (PO, Dev, QA, Designer, Manager)

### Articles
- [ ] Language confirmed (French or English)
- [ ] Opening hooks the reader immediately
- [ ] Short paragraphs, simple words, no jargon
- [ ] Single focused idea throughout
- [ ] Ends with a clear takeaway

## Integration with Other Commands

- After `/tdd` or `/plan` → use `/update-docs technical` to document new architecture
- After defining business rules → use `/update-docs functional` to capture them
- After shipping a feature → use `/update-docs functional` + `/update-docs technical`
- When an insight emerges → use `/update-docs articles insert idea`
- After `/code-review` reveals undocumented patterns → use `/update-docs technical update`

## Related

- **Agent**: `doc-updater` (`.claude/agents/doc-updater.md`)
- **Skills**: `technical-docs`, `functional-docs`, `article-writing` (`.claude/skills/`)
