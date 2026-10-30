---
name: checkpoint
description: Mid-project checkpoint. Summarises the stretch of work as a categorised outline for approval, then brings beads, the Task notes, the Obsidian journal, and the daily note back into agreement without closing the project. Files discovered work, records decisions, archives the Task notes of closed beads, and flags any bead closed since the last journal entry that no entry covers. Use at a natural pause, at session end, or when asked to checkpoint.
allowed-tools: Read, Grep, Bash, search_notes, read_note, read_multiple_notes, write_note, patch_note, move_note, list_directory, get_frontmatter, update_frontmatter, manage_tags, now
---

# Checkpoint

Bring the systems back into agreement partway through a project. The project stays open. Use `close-project` when the work is actually done.

The journal is the record of account. A bead id is not a citation, so anything worth citing later gets prose in a dated note.

## Input

The project, resolved from the `project` and `beads-epic` keys of `.workspace.meta.yaml` when inside a workspace, or from the epic id or Project Name. If the session has been working on one thing, that is the project. Do not ask.

## Steps

### 1. Establish what changed

```bash
bd list --parent <epic-id> --status open,in_progress,blocked
bd list --parent <epic-id> --closed-after <date of the last journal entry>
```

The last journal entry's date is the watermark. Find it by listing `Projects/<Project Name>/Journal/`.

That gives the chronology spine. The prose still gets written.

With no journal entry yet, the epic's creation date is the watermark.

#### Task notes

Compare the beads against the notes under `Projects/<Project Name>/Tasks/` and `Projects/<Project Name>/Task Archive/`. Read each note's `bead` and `status` frontmatter.

```bash
nu -c '
let project = "<Project Name>"
cd $env.OBSIDIAN_VAULT
glob $"Projects/($project)/{Tasks,Task Archive}/*.md"
| each { |p|
    let fm = open --raw $p
      | parse -r "(?s)^---\n(?<fm>.*?)\n---"
      | get fm.0
      | from yaml
    {
      path: ($p | path relative-to $env.OBSIDIAN_VAULT)
      bead: $fm.bead?
      status: $fm.status?
    }
  }
'
```

Drift is any of:

- A child bead with no Task note
- A Task note whose `bead` does not exist
- A `status` that differs from the bead's status
- A closed bead whose note is still under `Tasks/`
- An open, in-progress or blocked bead whose note is under `Task Archive/`

#### Meeting notes

A meeting note is unseen when no daily note and no journal entry links to it. List the unseen notes modified since the watermark:

```bash
nu -c '
let project = "<Project Name>"
let since = "<watermark>" | into datetime --format "%Y.%m.%d"
cd $env.OBSIDIAN_VAULT
let links = glob "{Daily Notes/*.md,Projects/*/Journal/*.md}"
  | each { open --raw }
  | str join "\n"
glob $"{Meetings/**/*.md,Projects/($project)/Meetings/**/*.md}"
| each { ls -l $in | first }
| where modified >= $since
| get name
| path relative-to $env.OBSIDIAN_VAULT
| where { |p| not ($links | str contains ($p | str replace -r "\\.md$" "")) }
'
```

The mtime bound catches a note filed days after its meeting. It also keeps old notes that were never linked from surfacing.

Read each unseen note. Keep every note under the project's own `Meetings/`. Keep a note under the global `Meetings/` only when its content bears on the project. Do not match on the Project Name alone: a note can bear on the project without naming it.

A shortest-form link such as `[[2026.10.09]]` does not match, so its note shows as unseen. Treat that as seen once you confirm the link.

#### Workspace metadata

Skip this when the project has no workspace.

Read `.workspace.meta.yaml` at the workspace root. Offer a metadata update in two cases, and only then:

- **No metadata.** The file is missing, or lacks keys from the set `new-project` defines under "Workspace metadata".
- **Evidence of change.** Compare the file against the session and the beads:
  - A PR exists that `pr-url` does not list.
  - The work no longer matches `description`, for example after a decision changed the scope.

With no missing keys and no evidence, say nothing about metadata.

### 2. Present the outline, then stop

**Nothing is written until this is approved.** No bead is closed, no note is moved or appended, no journal entry is drafted. The outline is how the session's account of itself gets checked before it becomes the record.

Keep it high level. One line per item, with the bead id inline so each claim is traceable.

```markdown
**Completed**
- The font index parser handles nested directories (hz-a1b.3, proffie#12)

**Decided**
- Sound fonts load from SD at boot, not on demand (hz-a1b.5, 10-21)

**In Flight**
- Playback mixer, two of three channels wired (hz-a1b.4)

**Discovered**
- The SD driver drops the first read after a remount (not yet filed)

**Blocked**
- Volume curve, on a datasheet I do not have (hz-a1b.6)

**Unverified**
- The parser has not run on hardware. Only the host tests ran (hz-a1b.3)

**Backed Out**
- <what was reverted, and why>

**Tasks**
- Archive `Parse Font Index` (hz-a1b.3 closed)
- `Playback Mixer`: status open -> in_progress (hz-a1b.4)
- New Task note `SD Remount Read` for the discovered bead

**Meetings**
- <title>, 10-09: <what it settled> (`Meetings/<series>/2026.10.09.md`)
- Skipped as not relevant: <paths>

**Metadata**
- pr-url: add https://github.com/<org>/<repo>/pull/<PR number>
- description: <current> -> <proposed> (scope changed by hz-xxx.n)
```

Rules:

- **Omit a category with nothing in it.** An empty heading is noise.
- Every item carries its bead id, or says it is not yet filed.
- **Unverified** is not a softer Completed. Name the gate that did not run. Work that was never proven belongs here even when the code is written.
- **Decided** says who settled it, when it involved anyone else, and when. A decision with no attribution is hard to defend later.
- **Tasks** lists every drift item from step 1 and the fix for it, plus a Task note for each discovered bead.
- **Meetings** lists each unseen note kept, with its path. Its decisions also go under **Decided** and its new work under **Discovered**. Name the skipped notes in one line, so the user can overrule the relevance call.
- Say plainly where the session is unsure. Do not smooth it.
- **Metadata** shows each change as `current -> proposed`, with the evidence for it. When no file exists, show the full drafted file. Draft missing keys from the epic, the project note, and the session.

Ask whether the outline is right, and whether anything in it should be dropped or recategorised. Act on the answer before step 3.

### 3. Update the beads

- **Note the ones still open.** `bd note <id> "..."` appends. `bd update --notes` replaces the field and loses history, so never reach for it here.
- **Close what is done**, with `--reason` saying what it delivered.
- **File discovered work** as new child beads, with `project:<project-tag>` and `repo:<name>`.
- **File decisions** as `--type decision`, same `project:` label. A decision is superseded by a new bead, never edited in place.

Notes are what survives compaction. Write them for an agent that has lost the conversation: the finding, the reason, and what it blocks.

**Never close a bead on an assumption.** If a validation step may or may not have run, ask which ones did. Closing over the top of unverified work is the one failure this skill can cause.

### 4. Update the Task notes

Apply the **Tasks** items the user approved.

- **New bead**: create `Projects/<Project Name>/Tasks/<Task Name>.md` from the `new-project` task template, and add its link under `## Tasks` in the project note.
- **Status change**: set `status` in the frontmatter to the bead's status.
- **Closed bead**: archive the note.

#### Archive a Task note

1. Move `Projects/<Project Name>/Tasks/<Task Name>.md` to `Projects/<Project Name>/Task Archive/<Task Name>.md` with `move_note`.
2. Set `status: closed`.
3. Swap the tag `tasks` for `task-archive`. This is the tag Templater derives from the new path.
4. Patch every link to the old path. `move_note` may not rewrite links, so search for them:

   ```bash
   nu -c '
   let old = "Projects/<Project Name>/Tasks/<Task Name>"
   cd $env.OBSIDIAN_VAULT
   glob "**/*.md"
   | where { |p| open --raw $p | str contains $"[[($old)" }
   | path relative-to $env.OBSIDIAN_VAULT
   '
   ```

   In each file, replace `[[<old>` with `[[Projects/<Project Name>/Task Archive/<Task Name>`. Keep the display name.

### 5. Update the metadata

Skip this step when the outline had no **Metadata** section.

Write only the changes the user approved to `.workspace.meta.yaml`. Use `Edit`, not a full rewrite, so keys added by hand survive. A declined change leaves the file as it is.

### 6. Flag the gap

Any bead closed since the watermark that no journal entry covers is a gap. Name them. They are the reason this skill exists.

### 7. Draft the journal entry

`Projects/<Project Name>/Journal/YYYY.MM.DD.md`.

- Frontmatter tags: `projects`, `<project-tag>`, `journal`. Templater derives these from the path, so match the path exactly.
- The H1 is a claim about what was learned or shipped, never the file name and never the date.
- H2s are assertions, not labels.
- Decision Log / ADR-lite. Problems encountered, decisions made, solutions implemented. If something was backed out, say so and why.
- Link a Task note by its current full path with a display name.
- **No TODOs and no next steps.** Those are beads, and putting them here is the most common mistake.
- Hard-wrap around 78 columns. State uncertainty plainly: "I did not verify this", not "probably".

Append to today's entry if one already exists. Do not open a second file for the same day.

**Always ask before writing the journal.** Show the draft first. This holds even when the checkpoint itself was requested.

### 8. Draft the daily note

`Daily Notes/YYYY.MM.DD.md`, with `mode: append`. Never overwrite.

- A line under `## Projects Worked On`
- Findings under `## Notes`, one bullet each
- A link under `## Links` whose display text is the journal entry's H1
- A full-path link under `## Links` to each meeting note kept in the outline. That link marks the note as seen for the next checkpoint

Lightweight. The detail lives in the journal.

### 9. Report

```
Checkpoint: **<Project Name>**

- Beads: <n closed, n noted, n filed>
- Task notes: <n created, n updated, n archived>
- Decisions: <ids, or "none">
- Journal: Projects/<Project Name>/Journal/YYYY.MM.DD.md
- Daily note: appended
- Metadata: <updated, created, declined, unchanged, or no workspace>
- Meetings: <n reviewed, n linked, n skipped>
- Uncovered: <any bead closed before this entry that no entry narrates>
```

## Notes

- The project stays open. Closing the epic is `close-project`.
- `bd dep add A B` means A depends on B. Reversing it inverts the graph.
- Anything outward-facing that comes out of a checkpoint, such as a PR body or a GitHub comment, is drafted for approval and not posted.
- A decision reached in a meeting counts. Record it as a decision bead and narrate it in the journal, with the date it was settled, who settled it, and the meeting note path as the source.
