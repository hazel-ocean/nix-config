# Personal Workflow Conventions

## Coding & Agent Standards

- **Comments**: Default to none. Add one only to record *why*: a non-obvious constraint, gotcha, or decision the code can't show. Never restate *what* the code does, label sections, or narrate steps. One line unless a real gotcha needs more; when unsure, delete it. Exception: a one-line doc on a public or exported command is fine.
- **Punctuation**: Never use em dashes in any output (code comments, commit messages, prose). Use commas, colons, semicolons, or hyphens instead.
- **Attribution**: Omit "Co-Authored-By: Claude" (and any AI attribution) from all copy: commits, PRs, and other output.
- **Counters**: Use counters proactively to aid future debugging. Examples: did an event occur? did an operation succeed or fail? how many times did a thing happen to an entity?
- **Layout**: Prefer vertical code over horizontal for legibility in 80-column windows. Break long chains, argument lists, and expressions across lines rather than packing them wide. (Coming from Elixir, where verticality, e.g. piped `|>` chains one call per line, is idiomatic most of the time.)

## Nushell

- Don't use underscores to denote private vs public.
- Prefer nushell (`nu`) for non-trivial scripts and workspace tooling, invoked as a subprocess (`nu -c '...'` or `nu script.nu`). Keep simple one-shot commands (`grep`, `git`, `ls`) as plain POSIX shell.

## Task Management (Things.app)

- **Things.app** is my task management system
- When I refer to "task list", "todos", or "my tasks", I mean the Things project associated with the current work
- MCP server: `mcp-things`

### Conventions
- Starting a new project always mean creating a Project in Things underneath the OneSignal Area
- Update todos as work progresses (mark complete, add notes)
- Create new todos for discovered work
- When backing out changes, update relevant todos accordingly
- When referring to a repo, we generally use the repo name in backticks omitting the organization.

## Progress Logging (Obsidian)

- **Obsidian** is used for keeping detail progress notes
- MCP server: `mcp-obsidian`
- Vault: `OneSignal` (work-related)

### Journal Structure
- Location: `Linear/<Project Name>/Journal/YYYY.MM.DD.md`
- The `Project Name` is a concice name that, if dash-cased, would be suitable for a `git branch`
- The `project-tag` is the `Project Name` converted to dash-casing whose format is suitable for a `git branch`
- Title (H1) should be a brief summary of the session's outcome, never mirror the name of the file in the Title
- Format: Decision Log / ADR-lite style
- Tags: `linear`, `<project-tag>`, `journal`

### Project Journal Conventions
- Capture: problems encountered, decisions made, solutions implemented
- **Never put TODOs or next steps in journal entries** — those belong exclusively in Things.app
- **Always ask before updating the journal** - never auto-update
- If we back out a change, document that with reasoning
- Periodically prompt me to update the journal after completing a problem/solution cycle

### Daily Note Conventions
- Location: `Daily Notes/YYYY.MM.DD.md`
- Daily Notes capture a chronological timeline of what's been worked on
- Links are kept to relevant Project Journal documents
- When appending to an existing daily note, use `mode: append` — never
overwrite

## Work Management (Linear)

- **Linear** tracks work items and projects at the team level
- MCP server: `Linear` (claude.ai connector)
- Things projects often link to Linear issues
- Estimates are made by the team during Story Time — unless told otherwise, newly created Linear tickets get **No Estimate**

## Keeping Things in Sync

The three systems should tell a coherent story:
1. **Linear** - What needs to be done (team-visible)
2. **Things** - My personal breakdown of the work (todos)
3. **Obsidian** - Detailed log of how the work was done (journal)

## Session Start

When beginning work on a task, offer to:
1. Load the relevant Things project todos
2. Read recent daily notes and project journal entries for context
3. Check Linear for any updates

## Session End / Checkpoints

Periodically (or when prompted), offer to:
1. Update completed todos in Things
2. Draft entries for both:
  - Daily note (lightweight summary with links)
  - Project journal (detailed technical decisions)
3. Identify any new todos discovered during work
