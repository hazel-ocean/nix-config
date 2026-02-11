# Personal Workflow Conventions

## Task Management (Things.app)

- **Things.app** is my task management system
- When I refer to "task list", "todos", or "my tasks", I mean the Things project associated with the current work
- MCP server: `mcp-things`

### Conventions
- Update todos as work progresses (mark complete, add notes)
- Create new todos for discovered work
- When backing out changes, update relevant todos accordingly

## Progress Logging (Obsidian)

- **Obsidian** is used for detailed work journals
- MCP server: `mcp-obsidian`
- Vault: `OneSignal` (work-related)

### Journal Structure
- Location: `Asana/<Project Name>/Journal/YYYY.MM.DD.md`
- Title (H1) should be a brief summary of the session's outcome, not the date (the date is already in the filename)
- Format: Decision Log / ADR-lite style
- Tags: `asana`, `<project-tag>`, `journal`

### Journal Conventions
- Capture: problems encountered, decisions made, solutions implemented
- **Always ask before updating the journal** - never auto-update
- If we back out a change, document that with reasoning
- Periodically prompt me to update the journal after completing a problem/solution cycle

## Work Management (Asana)

- **Asana** tracks work items and projects at the team level
- MCP server: `mcp-asana`
- Things projects often link to Asana tasks

## Keeping Things in Sync

The three systems should tell a coherent story:
1. **Asana** - What needs to be done (team-visible)
2. **Things** - My personal breakdown of the work (todos)
3. **Obsidian** - Detailed log of how the work was done (journal)

## Session Start

When beginning work on a task, offer to:
1. Load the relevant Things project todos
2. Read recent journal entries for context
3. Check Asana for any updates

## Session End / Checkpoints

Periodically (or when prompted), offer to:
1. Update completed todos in Things
2. Draft a journal entry summarizing progress
3. Identify any new todos discovered during work
