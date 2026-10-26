---
name: record-meeting
description: |
  Record a meeting into the Obsidian vault from any recording tool: a Wispr
  Flow share link, a Granola note, a Zoom recording, or a pasted transcript or
  summary. Files a meeting note beside earlier notes of the same series, lists
  the participants, and links the note from the daily note. Triggers on
  "record this meeting", "record <meeting link>", "save these meeting notes",
  "/record-meeting".
---

# Record a meeting

Works in any vault that the Obsidian MCP server serves, from any recording
tool. Read conventions from the vault itself. Do not assume a folder layout.

## Workflow

1. **Fetch the meeting.** Identify the tool from the link or the user's words,
   and read the meeting through that tool's MCP server.
   - Wispr Flow (`notes.wisprflow.ai/shared/...`): `resolve_share_link`. Do not
     fetch the page.
   - Granola (`notes.granola.ai/...`): `get_meetings`, and
     `get_meeting_transcript` when the summary is thin.
   - Any other tool: search the loaded MCP tools for one that reads it. If none
     reads it, ask the user to paste the summary or the transcript.
   - Get the title, the date, and the summary. Convert every UTC time to local
     time.

2. **Get the participants.** Speaker labels ("Speaker 1", "Microphone") from
   any tool are not reliable.
   - Never attribute a statement, a decision, or a next step to a speaker label.
   - Ask the user who attended, unless they said so already.
   - Attribute a statement to a person only when the user names who said it.

3. **Find the series.** Search `Meetings/` for earlier notes with the same
   title.
   - A match is a recurring series. Use its folder and copy its frontmatter
     tags, its section style, and its file name form.
   - No match is a one-off. Ask the user which `Meetings/` subfolder fits.
     Name the file `YYYY.MM.DD – <Title>.md`, with an en dash.
   - Read the most recent note of the series before writing.
   - Check that the target file does not exist. Never overwrite a note.

4. **Write the meeting note.**
   ```markdown
   ---
   tags: [meetings, <series tags>]
   <tool>-link: <link to the recording>
   ---

   # <Meeting title>

   Mon, 26 Oct 26

   ### Participants

   - <Name>, <role in the meeting if the user gave one>

   ### <One section per summary heading>

   ### Next Steps
   ```
   - Name the link key after the tool: `wispr-link`, `granola-link`,
     `zoom-link`. Omit the key when the source has no link.
   - Rewrite the summary in the user's voice rules. Do not paste it.
   - Keep names that the summary states as fact, such as a DM recipient.
   - Next steps have no owner unless the user names one.

5. **Link it from the daily note** at `Daily Notes/YYYY.MM.DD.md`, if the vault
   has that folder.
   - If the note exists, read it and add to it. Never overwrite it.
   - If it does not exist, create it from `Templates/Daily Note.md`.
   - Add one bullet under `## Projects Worked On`: `<Meeting title>: <one-line
     outcome>`.
   - Add a wiki link under `## Links`:
     `[[Meetings/<path>/<file stem>|<Meeting title>]]`.

6. **Report back.** Give the note paths. Offer to file beads for next steps
   that belong to the user. Do not file them unasked.
