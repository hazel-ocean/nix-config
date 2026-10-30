
# Personal Projects

Project conventions, layered over the personal ones above.

## Workspaces

- A project's repos are checked out in its workspace,
  `~/workbench/workspaces/<name>/<repo>`. `workspace new` creates one and
  `workspace clone <repo>` adds a repo to it.
- A project that touches no repo has no workspace.

## Task Tracking (beads)

- One database for all work, at `~/workbench/.beads`. `BEADS_DIR` is set by mise at the workbench root, because `bd` discovery stops at a git repo boundary and cannot find the database from inside a checkout.
- Run `bd prime` for the current command surface. The bundled skill text is older than the binary.
- **No bead id in external communication.** GitHub and anything else outward-facing state the fact and the date. A bead id is an internal cross-reference, and nobody else can dereference it.

### Loop
1. `bd ready` to find unblocked work
2. `bd show <id>` for full context
3. `bd update <id> --claim` to claim and start
4. `bd note <id> "..."` as you work. The notes are what survives compaction
5. `bd close <id> --reason "..."`

### Structure
- One epic per project. Every child has the label `project:<project-tag>`, plus `repo:<name>` for the repo it touches.
- Every child task has a Task note in Obsidian. See [Task Notes](#task-notes).
- Decisions are issues of type `decision` with the same `project:` label. A decision is superseded, never edited in place.

### Two traps
- `bd dep add A B` means **A depends on B**. Reversing it inverts the dependency graph.
- `bd update --notes` replaces the notes field. Use `bd note`, which appends.

### Voice
Titles, descriptions, notes and close reasons are writing. The voice rules cover them, with no carve-out for being inside a tool.
- Bullets over paragraphs. A note is a list of findings.
- One idea per sentence. Use the active voice.
- State uncertainty plainly. Write "not verified", never "probably".
- A title is a claim, not a label. "The filter fails open on a short timeout" beats "Timeout handling".
- Describe the finding, the reason, and what it blocks. Notes are read by an agent that has lost the conversation.

## Progress Logging (Obsidian)

- MCP server: `mcp-obsidian`
- Vault: `Personal`, at `$OBSIDIAN_VAULT`. Obsidian Sync keeps it current across machines.
- Templater derives one tag per folder segment of a note's path, slugified. An MCP write does not run Templater, so write the same tags by hand.

### Names
- The `Project Name` is Title Case, 2-5 words. It names the project folder and the project note.
- The `project-tag` is the `Project Name` dash-cased and lowercased, suitable for a `git branch`.

### Project Note
- Location: `Projects/<Project Name>/<Project Name>.md`. The folder-notes plugin opens it as the folder's page.
- A reference document: context, decisions, requirements. Not a task list.
- `## Tasks` links each Task note. `## Outcome` is filled at close.

### Task Notes
- Location: `Projects/<Project Name>/Tasks/<Task Name>.md`, one per child bead. The epic has no Task note.
- The Task Name is a short Title Case file name. The H1 is the bead title.
- Frontmatter: tags `projects`, `<project-tag>`, `tasks`; `bead: <id>`; `status:` one of `open`, `in_progress`, `blocked`, `closed`.
- The note holds the context and the acceptance criteria. The bead holds status, dependencies and work notes. `status` mirrors the bead.
- When the bead closes, move the note to `Projects/<Project Name>/Task Archive/<Task Name>.md`, set `status: closed`, and swap the tag `tasks` for `task-archive`.
- Link a Task note by its full path with a display name, `[[Projects/<Project Name>/Tasks/<Task Name>|<Task Name>]]`. After a move, patch every link to the old path.

### Journal
- Location: `Projects/<Project Name>/Journal/YYYY.MM.DD.md`
- Title (H1) is a brief summary of the session's outcome. Never mirror the file name in the title.
- Format: Decision Log / ADR-lite
- Tags: `projects`, `<project-tag>`, `journal`
- Capture: problems encountered, decisions made, solutions implemented
- **Never put TODOs or next steps in a journal entry or a Task note.** Those belong in beads
- **Always ask before updating the journal.** Never auto-update
- If we back out a change, document that with reasoning
- Periodically prompt me to update the journal after completing a problem/solution cycle

### Daily Notes
- Location: `Daily Notes/YYYY.MM.DD.md`
- A chronological timeline of what's been worked on, with links to the relevant journal entries
- When appending to an existing daily note, use `mode: append`. Never overwrite

## Keeping Things in Sync

1. **Task notes**: what needs to be done, and how to tell it is done
2. **beads**: status, dependencies, and decisions
3. **Journal**: how the work was done
4. **Project note `## Outcome`**: what the work produced
5. **Things**: personal life and the triage inbox (macOS only)

The journal is the record of account. A bead id is not a citation.

- beads drafts the journal and never substitutes for it. `bd list --closed-after <date> --json` gives the chronology spine. The prose still gets written to a dated note.
- Every decision bead gets a journal counterpart narrating why.

## Session Start

When beginning work on a project, offer to:
1. Run `bd ready` for unblocked work, and `bd show` on anything already claimed
2. Read recent daily notes, journal entries, and the open Task notes

## Session End / Checkpoints

Periodically (or when prompted), offer `checkpoint`:
1. Close completed beads, archive their Task notes, and add notes to the beads still open
2. Draft entries for both the daily note and the project journal
3. File work discovered during the session as beads, each with a Task note
4. Flag any bead closed since the last journal entry that no entry yet covers
