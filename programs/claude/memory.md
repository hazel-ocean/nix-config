# Personal Workflow Conventions

## Voice

How I write, in every medium, with no exceptions and no per-surface carve-outs. This is not a coding rule. It applies to chat replies, code comments, doc comments, commit messages, PR and issue descriptions, Slack, Linear, docs, journals, and anything else with words in it. If you catch yourself deciding a surface is "different", it isn't.

- **Terse by default.**
  - *Default to nothing.* Add a comment only to record **why**: a non-obvious constraint, gotcha, or decision the code can't show. Never restate what the code does, label sections, or narrate steps. When unsure, delete it. Exception: a one-line doc on a public or exported command.
  - *Describe what is, never what was.* No "unlike X", "previously", "rather than", "deliberately separate from", "this replaces". The reader never saw the earlier iteration and does not need to. Design history belongs in the PR description or the project journal.
  - *Bullets over blobs.* Prefer bulleted or numbered lists to paragraphs. Reserve a paragraph for sentences that genuinely depend on each other, and keep it to two or three. Numbered when order matters.
  - *Shorter is the tiebreak.* Given two versions that convey the same thing, ship the shorter one.
- **Punctuation**: Never use em dashes. Use commas, colons, semicolons, or hyphens instead.
- **Attribution**: Omit "Co-Authored-By: Claude" (and any AI attribution) from all copy: commits, PRs, and other output.
- **Commit messages**: A concise subject line, then bullet points (`- `) for the body; no multi-sentence prose paragraphs.

## Coding & Agent Standards

- **Counters**: Use counters proactively to aid future debugging. Examples: did an event occur? did an operation succeed or fail? how many times did a thing happen to an entity?
- **Layout**: Prefer vertical code over horizontal for legibility in 80-column windows. Break long chains, argument lists, and expressions across lines rather than packing them wide. (Coming from Elixir, where verticality, e.g. piped `|>` chains one call per line, is idiomatic most of the time.)

## Rust

- Prefer `match` over `if`/`else if` chains, unless the condition is already a plain boolean. Matching on an enum also makes the compiler flag new variants instead of letting them fall into a silent default.

## Workspaces

- **Only ever work in repos checked out inside the active workspace** (`~/OneSignal/workbench/workspaces/<name>/<repo>`). Never edit, branch, or commit in the shared checkouts under `~/OneSignal/src`: those are shared across every workspace, so work done there leaks between unrelated tasks.
- If a repo you need isn't in the workspace, stop and ask me before running anything against it, reads included. `workspace clone <repo>` is how it gets there.
- Exception: `~/.config/nix-config`, which the `nix-config-setting` skill edits by design.

## Public Communication & Approvals

- **Never post publicly without a drafted approval.** Do not reply to, comment on, or open anything outward-facing (GitHub issues/PRs/reviews, Slack, Linear, and any other public or shared channel) until you have shown me a draft of the exact wording and I have explicitly approved it. This covers opening PRs, posting review comments, sending Slack messages, and adding Linear comments. Draft first, wait for my go-ahead, then send.

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
