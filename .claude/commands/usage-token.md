# Token Usage Summary

Analyze the current session's token and context usage, then provide a structured report.

## Instructions

1. **Context Window Status**: Report the approximate context window usage (how much has been used vs remaining capacity). Use any available signals — compressed messages, conversation length, tool call volume.

2. **Project Usage Breakdown**: List what tokens were spent on *within this project* (`TodoistIA`), grouped by category:
   - Code reading / exploration
   - Code writing / editing
   - Tool calls (Bash, Grep, Glob, Read, Write, Edit, Agent, etc.)
   - Planning / architecture discussion
   - Testing
   - Documentation
   - Other project-related activity

3. **Non-Project Usage**: If any part of the conversation was spent on topics unrelated to this project (general questions, other projects, off-topic), list those separately with approximate token cost.

4. **Summary Table**: Present a markdown table with:
   | Category | Estimated % of tokens | Details |
   |----------|----------------------|---------|

5. **Recommendations**: If context is running low, suggest whether to start a new session or continue.

Format the output clearly with headers and the summary table. Be honest when estimates are approximate.
