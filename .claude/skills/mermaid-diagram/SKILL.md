---
name: mermaid-diagram
description: Create Mermaid diagrams for the TodoistIA KMP project. Use this skill proactively when a diagram is explicitly requested, when the technical-docs skill reaches its diagram step, or when complex system relationships, flows, or architecture would genuinely benefit from visual representation. Trigger whenever the user says "diagram", "visualize", "chart", "show the flow", "draw the architecture", "sequence diagram", or "class diagram" — even if they don't say "mermaid" explicitly. Also trigger when documenting multi-component data flows, sealed class state machines, coroutine sequences, or module boundaries. Do NOT use for simple one-class utilities or prose that already communicates the structure clearly.
---

# Mermaid Diagram Skill

This skill orchestrates diagram creation for the TodoistIA project. It decides *whether* a diagram adds value, determines *which type* fits best, then delegates production to the `diagram-architect` agent with a precise brief.

The goal is purposeful diagrams — not decoration. Every diagram produced here must help a developer or stakeholder understand something they couldn't grasp as quickly from prose alone.

## When a Diagram Is Warranted

Create a diagram when at least one of these is true:
- Three or more components interact and the relationships are hard to follow in prose
- There is a time-ordered sequence of events between distinct actors (API calls, coroutine chains)
- A state machine (sealed class, ViewModel state) needs to be communicated
- An architecture decision needs to be understood by someone new to the codebase
- A data flow spans multiple layers (domain → data → presentation)
- The user or another skill explicitly requests one

Skip the diagram when:
- A single class or utility function is being documented
- A numbered list already communicates the flow clearly
- The relationship is a simple 1:1 with nothing to visualize

## Workflow

### Step 1: Assess need
Before generating anything, confirm the diagram adds value. If prose is sufficient, state this briefly and stop.

### Step 2: Select diagram type

Use `.claude/rules/mermaid-format.md` as the formatting authority. Choose the type based on what needs to be communicated:

| Context                                           | Diagram Type       |
|---------------------------------------------------|--------------------|
| Domain models, use cases, repository interfaces   | `classDiagram`     |
| API calls, coroutine flows, event sequences       | `sequenceDiagram`  |
| Sealed class states, ViewModel state machines     | `stateDiagram-v2`  |
| Database schema, entity relationships             | `erDiagram`        |
| Business logic, decision trees, user journeys     | `flowchart`        |
| Module dependencies, component graphs             | `graph`            |
| System-level architecture, component boundaries   | `C4Context`        |
| Project phases, release history                   | `timeline`         |
| Feature breakdowns, concept maps                  | `mindmap`          |

### Step 3: Build a brief for the diagram-architect agent

Prepare a clear brief before launching the agent. A good brief includes:
- **Subject**: what the diagram represents
- **Type**: which Mermaid type and why
- **Actors / entities**: the key nodes to include
- **Relationships**: the connections between them, and their direction
- **Layer context**: which architectural layer(s) are involved (domain/data/presentation)
- **Formatting notes**: any layer-specific color coding or split requirements

### Step 4: Delegate to the diagram-architect agent

Launch the `diagram-architect` agent with the brief from Step 3. The agent will:
- Apply all rules from `.claude/rules/mermaid-format.md`
- Produce a titled, properly routed Mermaid block
- Add a purpose statement and type rationale
- Split into sub-diagrams if the scope is too large

### Step 5: Integrate the result

Once the agent returns the diagram:
- Embed it at the correct location in the document
- Ensure surrounding prose references and contextualizes the diagram
- Add a short caption if the document format supports it
- Update the `Last Updated` timestamp on the document

## KMP Project Conventions

These conventions apply to all technical diagrams for this project:

| Layer         | Diagram type preferred                   | Color class |
|---------------|------------------------------------------|-------------|
| Domain        | `classDiagram` for models and interfaces | `domain` (blue) |
| Data          | `classDiagram` for implementations       | `data` (green) |
| Presentation  | `stateDiagram-v2` for ViewModel states   | `ui` (yellow) |
| Cross-layer   | `sequenceDiagram` for data flows         | —           |
| System-wide   | `graph` for module dependencies          | —           |

Always reflect the clean architecture flow: domain → data → presentation. Never show a domain entity depending on a data layer class.

## Integration with technical-docs

When triggered from the `technical-docs` skill's diagram step:
1. `technical-docs` identifies the component or flow that needs a diagram
2. This skill evaluates the need and selects the type
3. This skill builds the brief and launches the `diagram-architect` agent
4. The resulting diagram is embedded in the technical doc with an updated timestamp

## Quality Checklist

Before considering a diagram done:
- [ ] Diagram has a `title` in its frontmatter block
- [ ] No text written on connecting lines — notes used instead
- [ ] No long descriptions inside node boxes or class cells
- [ ] Architectural layers color-coded with `classDef` where applicable
- [ ] Diagram fits without horizontal scrolling, or has been split into sub-diagrams
- [ ] Diagram type matches the communication goal
- [ ] All formatting rules from `.claude/rules/mermaid-format.md` applied
- [ ] Diagram is embedded in the document with surrounding prose that references it
