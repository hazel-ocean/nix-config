---
name: slack-triage
description: Sweep Slack unreads and surface anything actionable into the Things "From Slack" project, tracking a watermark so repeated runs never reprocess the same messages. Does NOT mark Slack read on triage; marking read is a separate `mark-read` step run after you've reviewed. Use when you want to catch up on Slack without babysitting it.
allowed-tools: Read, Write, conversations_unreads, conversations_history, conversations_mark, channels_list, add_todo, get_projects
---

# Slack Triage

Sweep Slack unreads, file the ones worth acting on into Things, and keep a
**watermark** so nothing gets triaged twice, even as unreads pile up between runs.

Marking messages read is deliberately **decoupled** from triage: filing a message
does not mark it read, so the unread badge stays until you've actually reviewed the
filed items. A separate `mark-read` step clears them once you're caught up.

## Modes

Selected by argument:

- (no argument) => **triage**: scan unreads newer than the watermark, file the
  worthwhile ones, advance the watermark. Read state is left untouched.
- `mark-read` => **catch-up**: mark channels read *up to the watermark*, run after
  you've reviewed what triage filed.

## State

Canonical watermark lives at `~/.local/state/claude/slack-triage.json`:

```json
{
  "watermark_ts": "1737936000.123456",
  "last_triaged_at": "2026-07-27T02:09:00Z",
  "runs": 3
}
```

- `watermark_ts`: Slack `ts` (global epoch, comparable across channels) of the
  newest message seen at the last triage. Everything at or below it is considered
  already handled.
- `runs`: cumulative triage-run counter (bump every triage run).

`Read` this file at the start of every run. If it's missing, this is the first run
(see below). `Write` it back at the end of a triage run. Create the parent
directory if needed.

## Triage mode

1. **Load state.** Read the state file. If absent, this is the first run: there's no
   watermark, so bound candidates to roughly the **last 7 days** of unreads so an
   old backlog doesn't flood the triage. Say so in the report.

2. **Fetch unreads.** Call `conversations_unreads` with `include_messages: true`.
   Raise `max_channels` and `max_messages_per_channel` well above the defaults (50 /
   10) so results aren't silently truncated. If the response still looks truncated
   (channels or messages hit the caps), set a `truncated` flag and call it out in
   the report. Never let a cap read as "all clear."

3. **Filter by watermark.** Keep only messages with `ts` **>** `watermark_ts`
   (on a first run, only those within the ~7-day bound). Track how many messages
   you considered.

4. **Triage with judgment.** Decide what deserves Hazel's attention:
   - **Surface**: DMs, @mentions, direct questions or asks aimed at Hazel, threads
     Hazel is participating in, anything time-sensitive or blocking.
   - **Skip**: broadcast announcements, FYI/automated posts, general channel noise,
     chatter Hazel isn't part of.

5. **File surfaced items** into the **"From Slack"** project via `add_todo` with
   `list_id: "H5WBBFFgYhksuLmNVhc43R"`. For each:
   - `title`: a concise summary of the ask/message (not a raw paste).
   - `notes`: brief context (who, which channel) plus a permalink built as
     `https://onesignal.slack.com/archives/<channel_id>/p<ts-with-the-dot-removed>`
     (e.g. `ts` `1737936000.123456` becomes `p1737936000123456`).
   - `tags`: for items that are **super important** (time-sensitive, blocking, or a
     direct ask that needs prompt attention), apply the existing
     `["✨ OS/Priorities"]` tag. Leave ordinary items untagged.

6. **Advance the watermark.** Set `watermark_ts` to the **max `ts` across all
   fetched unreads**, including skipped ones, so noise isn't reconsidered next
   run. Bump `runs`, set `last_triaged_at`, and Write the state file. **Do not mark
   anything read.**

7. **Report.** Include, using counters:
   - channels scanned, messages considered, items filed, items skipped, and
     `truncated` if it tripped;
   - the new watermark and its human-readable time;
   - a link to the destination project: `things:///show?id=H5WBBFFgYhksuLmNVhc43R`;
   - a reminder: *"When you've reviewed these in Things, run `/slack-triage
     mark-read` to clear them from Slack unreads."*

## mark-read mode

Run this once you've come back and reviewed the filed items.

1. **Load state** and read `watermark_ts`. If there's no state/watermark, there's
   nothing to do; say so and stop.
2. **Enumerate channels with unreads** via `conversations_unreads`
   (`include_messages: false` is enough).
3. For each such channel, call `conversations_mark` with `ts: watermark_ts`. This
   marks the channel read **only up to the triaged point**, leaving any
   newer-than-watermark messages still unread for the next triage.
4. **Report** how many channels were marked read up to the watermark.

Limitation (v1): mark-read is all-or-nothing up to the watermark. It can't mark
read "just the items you've reviewed" if you've only reviewed some.

## Notes

- Watermark comparisons use Slack `ts` directly (string-safe as long as you compare
  numerically); never rely on wall-clock for dedup.
