---
name: new-project
description: Set up a new project from a Linear issue link (and optional Slack links). Gathers context from all sources, proposes a plan for validation, then creates linked entries in Things (task management) and Obsidian (documentation). Use when the user provides a Linear issue URL and wants to start working on it.
allowed-tools: Read, Grep, get_issue, list_issues, list_comments, get_project, get_team, get_milestone, add_project, add_todo, get_areas, get_projects, search_notes, write_note, read_note, read_multiple_notes, fetch, now
---

# New Project Setup

Set up a complete project workspace from a Linear issue. Gathers context from Linear, Slack discussions, and existing Obsidian notes, then proposes a plan for the user to validate before creating anything.

## Input

**Required:**
- A Linear issue URL, e.g.: `https://linear.app/<workspace>/issue/ENG-123/some-slug`

**Optional:**
- One or more Slack message/thread links for relevant discussions
- Any verbal context the user provides about their thinking

## Philosophy

The local workspace (Things + Obsidian) represents **your own mental model** of the work — not a mirror of how issues and projects are structured in Linear. The person who wrote the Linear issues has their own way of decomposing work; you have yours. The Things project should contain tasks that make sense for how *you* want to approach the work, which may differ significantly from the Linear sub-issue structure.

- **Things** is the sole place for task tracking and work breakdown
- **Obsidian** is for context, documentation, and reference — not task tracking
- Linear is the upstream source of truth for requirements, but not for your personal workflow

## Steps

### 1. Gather Context (all sources)

#### Linear
Extract the issue identifier from the URL (e.g. `ENG-123` from `https://linear.app/<workspace>/issue/ENG-123/...`) and fetch details with `get_issue`:
- Title and description
- Status, priority, and assignee
- Due/target date
- Acceptance criteria (often in the description or sub-issues)
- Parent issue, project, team, and milestone for broader context (`get_project`, `get_team`, `get_milestone`)
- Comments (`list_comments`) for discussion and decisions
- Related (blocking, blocked-by) issues for additional context

Read sub-issues and related items to understand the full scope, but do **not** treat Linear's structure as a template for local organization.

#### Slack (if links provided)
Fetch each Slack link and extract:
- Key discussion points and decisions made
- Questions raised and answers given
- Any technical details, edge cases, or concerns mentioned
- Who was involved and what perspectives they brought

Synthesize the Slack discussions into a concise summary of what was discussed and any conclusions reached.

#### Obsidian
Search for related existing notes:
- Prior work on the same system or feature area
- Related technical documentation
- Any previous project notes that provide useful context

#### User Context
Incorporate anything the user has said about their thinking, approach, or priorities.

### 2. Propose a Plan (validation stage)

**Stop and present the following to the user before creating anything:**

```
📋 **Project Setup Proposal: <project-name>**

**My understanding of the work:**
<2-3 sentence summary synthesized from all sources>

**Proposed project name:** `<project-name>`

**Proposed Things tasks:**
1. <task-1> — <brief rationale>
2. <task-2> — <brief rationale>
3. <task-3> — <brief rationale>
...

**Key context I'll capture in Obsidian:**
- <context-point-1>
- <context-point-2>
- <slack-discussion-summary if applicable>

**Related Obsidian notes found:**
- <note-1>
- <note-2>

Does this look right? Want to adjust the tasks, rename anything, or add/remove items?
```

Wait for the user to confirm or adjust before proceeding.

### 3. Generate the Project Name

Create a concise name that:
- Works as an Obsidian tag (lowercase, hyphens instead of spaces)
- Is descriptive but short (2-4 words)
- Will be used identically in both Obsidian and Things

Example: "fix-webhook-retry-logic" or "user-export-feature"

### 4. Create Things Project

Create under the **"✨ Priorities"** area with:

| Field | Value |
|-------|-------|
| Title | The project name |
| When | Today |
| Deadline | From Linear (if present) |
| Notes | See format below |
| Todos | Tasks from the validated proposal |

**Notes format:**
```
**Linear:** <linear-url>
**Obsidian:** obsidian://open?vault=OneSignal&file=Linear%2F<project-name>%2F<project-name>
```

The todos should reflect **your own decomposition** of the work — how you plan to approach it, what you want to tackle first, what logical chunks make sense to you. This is explicitly **not** a copy of the Linear sub-issue list.

### 5. Create Obsidian Context Note

Create at `Linear/<Project Name>/<Project Name>.md`

Use the template at [obsidian-template.md](obsidian-template.md) with these values:
- `{{type}}`: `feature`, `bug`, or `tech-debt` based on the issue
- `{{linear-url}}`: The original Linear issue URL
- `{{things-uuid}}`: UUID from the Things project you just created
- `{{date}}`: Today's date in YYYY.MM.DD format
- `{{project-name}}`: The generated project name
- `{{task-summary}}`: Brief summary synthesized from all sources
- `{{acceptance-criteria}}`: From the Linear issue or "To be defined"
- `{{technical-context}}`: Synthesized from Obsidian search, Slack discussions, and Linear details
- `{{slack-summary}}`: Summary of Slack discussions (omit section if no Slack links)
- `{{related-notes}}`: Wiki-links to relevant existing notes

This note is a **reference document** — it captures context, decisions, and requirements. It is not a task list.

### 6. Report Back

Confirm what was created:

```
✅ Project created: **<project-name>**

**Links:**
- Things: things:///show?id=<uuid>
- Obsidian: obsidian://open?vault=OneSignal&file=Linear%2F<project-name>%2F<project-name>
- Linear: <original-url>

**Your tasks in Things:**
1. <task-1>
2. <task-2>
...
```

## Notes

- Always search Obsidian for related notes before creating the context note
- If the project name might conflict with existing projects, ask before proceeding
- The Obsidian note is purely for reference and context — all task tracking belongs in Things
- Slack summaries should capture decisions and context, not full transcripts
- When decomposing work into Things tasks, think about what logical steps make sense from an engineer's perspective, not what sub-issues exist in Linear
