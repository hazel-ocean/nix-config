---
name: close-project
description: Close out a finished personal project. Verifies the beads epic has no open children, archives the remaining Task notes, closes the epic, drafts the final journal entry and the project note's Outcome section, and appends to the daily note. Use when a piece of work is done and the project should be wrapped up.
allowed-tools: Read, Grep, Bash, search_notes, read_note, read_multiple_notes, write_note, patch_note, move_note, list_directory, get_frontmatter, update_frontmatter, manage_tags, now
---

# Close a Project

Wrap up a finished project. The point of this skill is that the work leaves a record a human can cite months later without opening beads.

## Input

The project: a beads epic id, a Project Name, or the workspace you are in. Resolve it from the `project` and `beads-epic` keys of `.workspace.meta.yaml` when you are inside a workspace.

## Steps

### 1. Verify the work is actually done

```bash
bd list --parent <epic-id> --all --json
```

List anything still open. **Stop and report it** rather than closing over the top of unfinished work. Ask whether those items should be closed, moved to a follow-up project, or left open with the epic staying open too.

Then list `Projects/<Project Name>/Tasks/`. Every note there must belong to a closed bead. Archive those notes, as in `checkpoint` step 4:

1. `move_note` to `Projects/<Project Name>/Task Archive/<Task Name>.md`.
2. Set `status: closed`.
3. Swap the tag `tasks` for `task-archive`.
4. Patch every link to the old path. `move_note` may not rewrite links, so search the vault for `[[Projects/<Project Name>/Tasks/<Task Name>` and replace the folder part, keeping the display name.

A note whose bead is open, or whose bead does not exist, stops the close. Report it.

### 2. Close the epic

```bash
bd close <epic-id> --reason "<one or two sentences on what shipped>"
```

The reason is read by agents later. Say what the work delivered, not that it is finished.

### 3. Draft the final journal entry

Gather the record:

```bash
bd list --parent <epic-id> --all --json
```

Draft an entry at `Projects/<Project Name>/Journal/YYYY.MM.DD.md`, following the vault's conventions:

- Frontmatter tags are `projects`, `<project-tag>`, `journal`. Templater derives these from the path, so match the path exactly.
- The H1 is a **claim about the outcome**, not a date and not the file name. "The loader ships fonts from SD and the remount bug is still open upstream" beats "Project complete".
- H2s are assertions, not labels.
- Decision Log / ADR-lite. Capture problems encountered, decisions made, solutions implemented.
- **No TODOs or next steps.** Those are beads.
- Hard-wrap around 78 columns. State uncertainty plainly.

**Always ask before writing the journal.** Show the draft first.

### 4. Fill the project note's Outcome

Patch `## Outcome` in `Projects/<Project Name>/<Project Name>.md` with:

- What shipped, in two or three sentences
- The dates: started, shipped
- PR links
- Anything deliberately not done, and why

This section exists so nobody has to reconstruct a project from thirty journal entries.

Update the links under `## Tasks` to the `Task Archive/` paths if step 1 did not already.

### 5. Mark the project done

Update the project note's frontmatter:

- Add the tag `projects/done`
- Add `closed: YYYY.MM.DD`

**Do not move the project folder.** A folder move breaks every wiki-link into the project and corrupts the path-derived tags on every note inside it. The status tag is the marker. Task notes are the exception: they move within the project folder, and their links get patched.

When the project has a workspace, update `.workspace.meta.yaml` too, with `Edit` so keys added by hand survive:

- Set `status: done`.
- Make sure `pr-url` lists every shipped PR, each as a bare URL.

### 6. Append to the daily note

Append to `Daily Notes/YYYY.MM.DD.md` with `mode: append`, never overwrite:

- A line under `## Projects Worked On`: `<Project Name>: <one-sentence outcome>`
- A link under `## Links` whose display text is the journal entry's H1

### 7. Report

```
✅ Closed: **<Project Name>**

- Epic: <epic-id>, closed
- Task notes: <n archived in this run, n total in Task Archive>
- Journal: Projects/<Project Name>/Journal/YYYY.MM.DD.md
- Outcome written to the project note
- Workspace metadata: <status done, n PRs listed, or no workspace>

Workspace ~/workbench/workspaces/<name> is still on disk. Remove it with `workspace trash <name>` when you no longer need the checkouts.
```

## Notes

- Never close an epic whose children are open without saying so first
- The journal entry and the Outcome section are the deliverables. The beads close is bookkeeping
- Offer to archive the workspace, never do it unprompted. The checkouts may still hold unpushed branches
