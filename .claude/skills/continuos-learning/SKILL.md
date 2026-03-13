---
name: continuous-learning
description: "Analyze the current session to extract reusable patterns, detect repetitive prompts across sessions, and study coding conventions — then save learnings to a categorized library. Use this skill proactively at the end of every session, or when the user says 'learn', 'extract patterns', 'what did we learn', 'save this for next time', or 'analyze the session' — even if they don't say 'continuous learning' explicitly."
---

# Continuous Learning

A living knowledge library that grows smarter with every session. This skill analyzes conversations to extract what worked, what failed, and what keeps coming up — then organizes those insights by category so future sessions start with accumulated wisdom instead of a blank slate.

This skill builds on the extraction logic from `/learn` and the quality evaluation from `/learn-eval`. Where those commands produce individual pattern files, this skill maintains a **structured, categorized library** and tracks patterns across sessions.

## When This Skill Runs

| Trigger                    | How                                                  |
|----------------------------|------------------------------------------------------|
| End of session (automatic) | Stop hook calls the analysis agent                   |
| Explicit invocation        | User runs `/learn` or asks to analyze the session    |
| Mid-session insight        | User says "remember this", "save this pattern", etc. |

## Library Structure

All learnings are stored under `.claude/skills/continuos-learning/library/`:

```
library/
├── index.json                    # Master index of all learnings with metadata
├── error-patterns/               # Recurring errors and their fixes
│   └── *.md
├── workflow/                     # Process improvements and effective sequences
│   └── *.md
├── anti-patterns/                # Things that wasted time or caused regressions
│   └── *.md
├── prompt-templates/             # Effective prompt patterns detected across sessions
│   └── *.md
├── tool-usage/                   # Better tool combinations and usage patterns
│   └── *.md
├── coding-conventions/           # Project naming, file structure, and code style patterns
│   └── *.md
└── project-specific/             # Architecture decisions, integration quirks, config gotchas
    └── *.md
```

## Categories Explained

### error-patterns
Recurring errors and their root causes. Not one-off typos — patterns that will bite again.

**Save when:** The same class of error appeared before, or the fix was non-obvious enough that rediscovering it would waste time.

**Example:** "Ktor serialization fails silently when a `@Serializable` data class has a property with no default and the JSON field is missing — use `@Required` or provide defaults."

### workflow
Effective sequences of actions that solved problems faster than the naive approach.

**Save when:** A multi-step process worked well and could be reused (e.g., "run tests → check coverage → review diff → commit" as a verified flow).

### anti-patterns
Things that wasted time, caused regressions, or led to dead ends.

**Save when:** A mistake was made that cost significant time, and understanding why it was wrong prevents repeating it.

**Example:** "Don't run `./gradlew clean` between every test run — it triples build time and the incremental cache is reliable for this project."

### prompt-templates
Prompt patterns the user gives repeatedly across sessions. Instead of re-interpreting each time, capture the intent and optimal response shape.

**Save when:** The analysis script detects a prompt that is semantically similar to prompts from 2+ previous sessions.

**Example:** "User frequently asks 'fix the build' — this means: run `./gradlew build`, read errors, fix root cause, verify with a clean build. Don't ask clarifying questions."

### tool-usage
Effective tool combinations and non-obvious tool usage that improved results.

**Save when:** A tool was used in a way that wasn't the first instinct but worked better (e.g., using Grep with multiline instead of multiple single-line searches).

### coding-conventions
Patterns observed in how the project is actually coded — file naming, function naming, package structure, import ordering, comment style, test organization.

**Save when:** A convention is observed consistently across 3+ files or the user corrects Claude to follow a convention.

**What to capture:**
- File naming patterns (e.g., `*UseCase.kt`, `*Repository.kt`, `*ViewModel.kt`)
- Function naming patterns (e.g., `getAll()` vs `findAll()` vs `list()`)
- Package structure conventions (e.g., `domain/usecase/`, `data/repository/`)
- Test file placement and naming
- Import ordering preferences
- Whether the project uses trailing commas, expression bodies, etc.

### project-specific
Architecture decisions, library quirks, configuration gotchas — things that are unique to this codebase.

**Save when:** Knowledge about the project was discovered that isn't documented elsewhere and would help in future sessions.

## How Analysis Works

### Step 1: Scan the Session

The analysis agent reviews the current conversation and extracts:

1. **Corrections** — moments where the user said "no", "not that", "instead do..." (these often become `anti-patterns` or `coding-conventions`)
2. **Errors encountered** — build failures, test failures, runtime errors and their fixes
3. **Multi-step solutions** — sequences of actions that solved a problem
4. **Tool usage** — which tools were used, in what combination, and whether it was effective
5. **Code patterns** — naming conventions, file organization, architectural patterns observed in the codebase

### Step 2: Cross-Session Repetition Detection

Read `library/index.json` and compare:

- Are any of the extracted patterns **already known**? If so, increment their `seen_count` and update `last_seen`
- Are any current prompts **semantically similar** to known `prompt-templates`? If so, update the template with new context
- Are there patterns that appeared in 2+ sessions but aren't saved yet? Flag them as high-priority saves

### Step 3: Quality Gate (from /learn-eval)

For each candidate learning, run the quality evaluation:

1. **Grep** existing library files for content overlap
2. **Check** if appending to an existing entry would be better than creating a new one
3. **Confirm** the pattern is reusable (not a one-off fix)
4. **Verdict**: Save / Improve then Save / Absorb into existing / Drop

### Step 4: Save to Library

For new entries, create a file in the appropriate category:

```markdown
---
name: descriptive-pattern-name
category: error-patterns | workflow | anti-patterns | prompt-templates | tool-usage | coding-conventions | project-specific
seen_count: 1
first_seen: 2026-03-11
last_seen: 2026-03-11
source: auto-extracted | user-requested
---

# [Descriptive Pattern Name]

## Context
[When this applies — be specific]

## Pattern
[The actual learning — with code examples when relevant]

## Why This Matters
[Brief explanation of why this saves time or prevents errors]
```

Then update `library/index.json`:

```json
{
  "learnings": [
    {
      "id": "error-patterns/ktor-serialization-missing-field",
      "name": "Ktor serialization fails on missing fields",
      "category": "error-patterns",
      "seen_count": 2,
      "first_seen": "2026-03-11",
      "last_seen": "2026-03-12",
      "tags": ["ktor", "serialization", "kotlinx"]
    }
  ],
  "session_count": 5,
  "last_analysis": "2026-03-12"
}
```

## Analysis Agent Instructions

When spawned (either by Stop hook or explicit trigger), the analysis agent should:

1. Read the full conversation transcript
2. Read `library/index.json` to know what's already learned
3. Run the session analysis script: `bash .claude/skills/continuos-learning/scripts/analyze-session.sh`
4. For each extracted insight:
   - Determine the correct category
   - Check for duplicates or near-duplicates in the library
   - Apply the quality gate
   - Save or merge as appropriate
5. Update `library/index.json` with new/updated entries
6. Report a brief summary to the user:
   - How many new learnings were saved
   - How many existing learnings were reinforced (seen_count bumped)
   - Any repetitive prompts detected

Keep the summary to 3-5 lines. The user doesn't need a lecture — just confirmation that knowledge was captured.

## Using the Library

In future sessions, the library is available as context. When starting work:

1. Check `library/index.json` for relevant entries based on the user's request
2. Read the most relevant learning files before proceeding
3. Apply known conventions from `coding-conventions/` when writing code
4. Avoid known `anti-patterns/` proactively
5. Use known `workflow/` patterns instead of reinventing approaches

The library is a reference, not a constraint. If a learning is outdated or wrong, update or remove it.

## Maintenance

Over time, the library should be pruned:

- **Merge** entries that overlap significantly
- **Archive** entries not seen in 10+ sessions (move to `library/_archive/`)
- **Update** entries when the project evolves and conventions change
- **Delete** entries that turned out to be wrong

The analysis agent should flag maintenance opportunities during each run.
