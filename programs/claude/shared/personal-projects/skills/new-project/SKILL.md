---
name: new-project
description: Set up a new personal project from a description (and optional links). Gathers context, proposes a plan for validation, then creates the workspace, a beads epic with its tasks, a Task note per task, and the Obsidian project note. Use when the user wants to start working on a new piece of work.
allowed-tools: Read, Grep, Bash, search_notes, write_note, read_note, read_multiple_notes, list_directory, fetch, now
---

# New Project Setup

Set up a complete project from a description of the work. Gather context from what the user provides and from existing Obsidian notes, then propose a plan for the user to validate before creating anything.

## Input

**Required:**
- A description of the work from the user (prose is fine: their thinking, goals, scope)

**Optional:**
- Links for extra context: a GitHub repo or issue, docs, an article
- Any other verbal context the user provides

## Philosophy

The local setup represents **your own mental model** of the work.

- **beads** holds status, dependencies, and decisions
- **Task notes** hold what each task is and how to tell it is done, one per child bead
- **The project note** holds context and narrative. It is not a task list

## Steps

### 1. Gather Context

#### User Description
Start from what the user told you: their framing of the work, goals, scope, and any constraints or priorities. This is the primary source.

#### Links (if provided)
Fetch each link and extract what bears on the work: requirements, prior decisions, technical details, open questions. For a GitHub URL, prefer the GitHub MCP tools over `fetch`.

#### Obsidian
Search for related existing notes:
- Prior work on the same system or feature area
- Related notes under `Library/`
- Any previous project that provides useful context

### 2. Propose a Plan (validation stage)

**Stop and present the following to the user before creating anything:**

```
📋 **Project Setup Proposal: <Project Name>**

**My understanding of the work:**
<2-3 sentence summary synthesized from all sources>

**Proposed project name:** `<Project Name>`  (tag: `<project-tag>`)

**Workspace description:** `<one line, 60 characters or fewer>`

**Proposed tasks:**
1. **<Task Name>**: <bead title, a claim>
   - Done when: <acceptance criteria>
2. ...

**Sequencing I can see:**
- <Task 3> is blocked by <Task 1>
- ... or "none yet" if the order is not clear

**Repos involved:**
- <repo-1>, <repo-2>, or "none, so no workspace"

**Key context I'll capture in Obsidian:**
- <context-point-1>

**Related Obsidian notes found:**
- <note-1>

Does this look right? Want to adjust the tasks, the sequencing, or rename anything?
```

Wait for the user to confirm or adjust before proceeding.

### 3. Generate the Names

- **Project Name**: Title Case with spaces, 2-5 words. Names the Obsidian folder and note. Example: `Proffie Sound Font Loader`.
- **project-tag**: the Project Name dash-cased and lowercased. Used as the Obsidian tag and the beads `project:` label. Example: `proffie-sound-font-loader`.
- **workspace name**: a short slug. Example: `font-loader`.
- **Task Name**: Title Case, a few words, unique within the project. Names the Task note file. Example: `Parse Font Index`.

If the Project Name might collide with an existing folder under `Projects/`, ask before proceeding.

### 4. Create the Workspace

Skip this step when the project touches no repo.

```bash
workspace new <workspace-name>
workspace clone <repo>        # once per repo, from inside the workspace
```

Create the branch `hazel/<workspace-name>` in each repo.

Write `.workspace.meta.yaml` in the workspace root now, with the keys known so far. The workspace then shows its context in `workspace list` even if a later step fails. See [Workspace metadata](#workspace-metadata) for the keys.

```yaml
description: <the validated description>
project: <Project Name>
```

### 5. Create the Beads Epic

The database is at `~/workbench/.beads`; `BEADS_DIR` is already set under the workbench root.

```bash
EPIC=$(bd create "<Project Name>" -t epic -p 1 \
  -l "project:<project-tag>" --silent)

bd create "<bead title>" -t task --parent "$EPIC" \
  -l "project:<project-tag>,repo:<repo>" --silent
```

Omit the `repo:` label for a task that touches no repo.

Then record the sequencing the user validated. **`bd dep add A B` means A depends on B**, so the blocked task comes first:

```bash
bd dep add <blocked-task-id> <prerequisite-task-id>
```

### 6. Create the Task Notes

For each child bead, create `Projects/<Project Name>/Tasks/<Task Name>.md` from [task-template.md](task-template.md):

- `{{project-name}}`, `{{project-tag}}`: as above
- `{{bead-id}}`, `{{bead-title}}`: from step 5
- `{{task-summary}}`: what the task is, in two or three sentences
- `{{acceptance-criteria}}`: the validated "done when", as a bullet list
- `{{task-context}}`: context specific to this task; omit the section body if there is none

The tags are the path-derived ones Templater would write. Keep them exact.

A Task note holds no status narrative and no work log. Those are `bd note`. It holds no next steps either.

### 7. Create the Obsidian Project Note

Create at `Projects/<Project Name>/<Project Name>.md` using [project-template.md](project-template.md). Fill in:

- `{{type}}`: `feature`, `bug`, or `tech-debt` based on the work
- `{{project-name}}`: the Title Case Project Name
- `{{project-tag}}`: the dash-cased tag
- `{{beads-epic}}`: the epic id from step 5
- `{{task-summary}}`: brief summary synthesized from all sources
- `{{acceptance-criteria}}`: from the description, or "To be defined"
- `{{technical-context}}`: synthesized from the Obsidian search and the links
- `{{context-and-discussions}}`: summary of relevant discussions; omit if there were none
- `{{task-links}}`: one bullet per Task note, `[[Projects/<Project Name>/Tasks/<Task Name>|<Task Name>]]`
- `{{related-notes}}`: wiki-links to relevant existing notes

Leave `## Outcome` empty. `close-project` fills it.

### 8. Complete the Metadata

Skip this step when there is no workspace.

Add the keys that exist now to `.workspace.meta.yaml`. Use `Edit`, not a full rewrite, so keys added by hand survive.

```yaml
notes-uri: "[<Project Name>](obsidian://open?vault=Personal&file=Projects%2F<Project Name>%2F<Project Name>)"
beads-epic: <epic-id>
```

#### Workspace metadata

`workspace info` and `workspace list` read this file. `checkpoint` and `close-project` keep it current. The full set of keys, in file order:

```yaml
description: <one line, 60 characters or fewer>
project: <Project Name>
notes-uri: "[<Project Name>](obsidian://open?vault=Personal&file=<path>)"
beads-epic: <epic-id>
pr-url:
  - https://github.com/<org>/<repo>/pull/<PR number>
```

- `description`: one line, 60 characters or fewer, so it fits a terminal column. A claim about the work, not a label.
- `project`: the Project Name. Other skills resolve the Obsidian folder from it.
- `notes-uri`: the Obsidian project note.
- `beads-epic`: the epic id.
- `pr-url`: added once a PR exists. Write each entry as a bare URL. A markdown label hides the state that `workspace info` paints.
- Write a key only when it has a real value. No placeholders.

A key ending in `-url`, `-uri` or `-link` renders as a clickable link.

### 9. Report Back

```
✅ Project created: **<Project Name>**

**Links:**
- Beads epic: <epic-id>
- Obsidian: obsidian://open?vault=Personal&file=Projects%2F<Project Name>%2F<Project Name>
- Workspace: ~/workbench/workspaces/<workspace-name>   (omit if there's none)

**Workspace metadata:**
<the contents of .workspace.meta.yaml>

**Your tasks:**
1. <Task Name>  (<id>)
2. ...

Run `bd ready --parent <epic-id>` to see what is unblocked.
```

## Notes

- Always search Obsidian for related notes before creating the project note
- Status and dependencies belong in beads. Task notes and the project note are context
- When decomposing the work, think about what logical steps make sense from an engineer's perspective
- Record sequencing as dependencies rather than as an ordered list. A dependency graph is the thing beads can act on
