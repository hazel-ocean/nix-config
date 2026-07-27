---
name: slack-triage
description: Sweep Slack unreads and surface anything actionable into the Things "From Slack" project, tracking a watermark so repeated runs never reprocess the same messages. Does NOT mark Slack read on triage; marking read is a separate `mark-read` step run after you've reviewed. Use when you want to catch up on Slack without babysitting it.
---

# Slack Triage

Sweep unreads, file the worthwhile ones into Things, advance a **watermark** so
nothing is triaged twice. Filing never marks read; the badge stays until you run
`mark-read` after reviewing.

**Modes** (by argument): no arg = **triage**; `mark-read` = mark channels read up to
the watermark.

## State — `~/.local/state/claude/slack-triage.json`

```json
{ "watermark_ts": "1737936000.123456", "last_triaged_at": "2026-07-27T02:09:00Z", "runs": 3 }
```

`watermark_ts` is the Slack `ts` (global epoch, comparable across channels) of the
newest message handled; everything ≤ it is done. Compare `ts` numerically, never
wall-clock. `Read` at start, `Write` at end of a triage run (create the dir if
needed); missing file = first run.

## Triage

1. **Load state.** Missing → first run: bound candidates to ~last 7 days so a backlog
   doesn't flood, and say so in the report.
2. **Fetch** `conversations_unreads`, `include_messages: true`, `max_channels` /
   `max_messages_per_channel` above defaults (50 / 10).
   - *Oversized:* with messages this often exceeds the output limit (~315k chars seen)
     and offloads to a file; spawn a `Task` subagent to read it in chunks and return a
     digest (per message: channel name, `ts`, author, text, URLs); use the inline
     result if it fit. Backlog alternative: `include_messages: false` to enumerate,
     then targeted `conversations_history`.
   - *Truncation:* caps hit → set a `truncated` flag and report it; never read a cap as
     "all clear."
3. **Filter:** keep `ts` > `watermark_ts` (first run: within the 7-day bound). Count
   what you considered.
4. **Judge:** *surface* DMs, @mentions, direct asks/questions to Hazel, threads she's
   in, anything time-sensitive/blocking; *skip* announcements, automated/FYI posts,
   noise she isn't part of.
5. **File** surfaced items via `add_todo`, `list_id: "H5WBBFFgYhksuLmNVhc43R"` (stable
   across renames). First resolve channel IDs (`conversations_unreads` gives names, no
   permalink) via one `channels_me` call (`name` → `Cxxxx`); DM/app channels
   (`@incident`, `@linear`) have no ID, so lean on the message's own links. Per item:
   - `title`: concise summary, not a raw paste.
   - `notes`: who + channel; Slack permalink
     `https://onesignal.slack.com/archives/<channel_id>/p<ts-sans-dot>` (`1737936000.123456`
     → `p1737936000123456`); and any URLs the message references (PRs, Linear, Docs,
     incident.io, calendar), which are usually the actionable destination.
   - `tags`: `["✨ OS/Priorities"]` if time-sensitive/blocking/a direct ask; `["Bug"]`
     for defects (both allowed); else none.
6. **Advance watermark, only over what you fully covered.** Not truncated → max `ts`
   across all fetched unreads (incl. skipped). Truncated → do **not** jump to that max
   (unscanned channels may hold older-than-max messages you'd lose forever); advance
   only to the min across channels of each channel's oldest fetched `ts`, or leave it
   and say so. Bump `runs`, set `last_triaged_at`, Write. **Never mark read here.**
7. **Report** (with counters): channels scanned, messages considered, filed, skipped,
   `truncated` if tripped; new watermark + human time; project link
   `things:///show?id=H5WBBFFgYhksuLmNVhc43R`; and *"reviewed in Things? run
   `/slack-triage mark-read`."*

## mark-read

Run after reviewing filed items. Load state; no watermark → nothing to do, stop.
Enumerate unread channels (`conversations_unreads`, `include_messages: false`), call
`conversations_mark` `ts: watermark_ts` on each (marks read only up to the triaged
point; newer stays unread). Report how many channels were marked.

Limitation (v1): all-or-nothing up to the watermark; can't mark read "just the items
you reviewed" if you've only reviewed some.

## Notes

- No tool allow-list is declared on purpose. Slack/Things/Task grants are managed
  centrally in `programs/claude/default.nix`; look there for what's permitted.
