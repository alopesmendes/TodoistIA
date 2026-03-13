---
name: functional-docs
description: Write and update functional documentation for the TodoistIA project. Use this skill when documenting business rules, product features, DDD ubiquitous language, user scenarios, or anything that needs to be understood by the whole team (PO, Dev, QA, Designer, Manager). Triggers proactively when business rules are defined or changed, new domain terms emerge, features are specified, or when someone says "document the feature", "write the specs", or "define the business rules" — even if they don't say "functional documentation" explicitly. Never includes technical implementation details.
---

# Functional Documentation

Functional docs target **the entire team**: Product Owners, Developers, Managers, QA, and Designers. The goal is to define what the product does, why it exists, and establish a shared DDD (Domain-Driven Design) language everyone uses consistently.

Never include implementation details (no code, no file paths, no frameworks). Focus on **what** and **why**, not **how**.

## When to Activate

- New product feature being defined or specified
- Business rule added, changed, or clarified
- New domain term or concept needs to be defined
- Feature behavior needs to be documented for QA or onboarding
- A stakeholder asks "what does X do?" or "what are the rules for Y?"
- DDD glossary needs a new entry or update

## Workflow

1. **Identify scope** — Which feature, domain, or business rule needs documenting?
2. **Gather business rules** — Ask the user to clarify conditions, behaviors, and exceptions if unclear.
3. **Define DDD terms** — Capture any new domain concepts in the ubiquitous language glossary.
4. **Write for all roles** — Every section should be readable by a PO, Dev, QA, Designer, and Manager.
5. **Cross-check** — Verify new terms against the existing glossary (`docs/functional/glossary.md`) for consistency.
6. **Timestamp** — Every document gets `Last Updated: YYYY-MM-DD`.

## DDD Language Glossary Standards

Every term in the glossary must include:

| Field                 | Description                                      |
|-----------------------|--------------------------------------------------|
| **Term**              | The canonical name — use this everywhere, always |
| **Definition**        | Clear, jargon-free explanation                   |
| **Context**           | Which bounded context this belongs to            |
| **Example**           | A real usage example from the product            |
| **Synonyms to avoid** | Terms that must NOT be used to prevent confusion |

## Output Structure

```
docs/functional/
├── README.md              # Product overview and target audience
├── glossary.md            # DDD Ubiquitous Language Glossary
├── features/
│   └── [feature-name].md  # Per-feature functional spec
└── business-rules.md      # All business rules consolidated
```

## Document Format

```markdown
# [Feature/Domain] — Functional Documentation

**Last Updated:** YYYY-MM-DD

## Overview
[What this feature/domain is about in 2-3 sentences — no technical detail]

## Target Audience
- **Primary**: [Who mainly uses this]
- **Secondary**: [Who is indirectly affected]

## Business Rules
1. **Rule Name**: Clear statement of the rule
   - Condition: When X...
   - Behavior: ...then Y happens
   - Exception: Unless Z

## DDD Language

| Term  | Definition  | Context  | Avoid Using  |
|---|---|---|---|
| Term  | What it means  | Bounded Context  | Synonyms  |

## User Scenarios
**As a** [persona], **I want to** [action], **so that** [outcome].
```

## Quality Checklist

- [ ] No technical implementation details (no code, no file paths, no framework names)
- [ ] Every business rule has: condition, behavior, and exception
- [ ] All DDD terms are consistent with the existing glossary
- [ ] Target audiences clearly identified
- [ ] A PO, Dev, Manager, QA, and Designer could all read and understand this
- [ ] `Last Updated` timestamp present
