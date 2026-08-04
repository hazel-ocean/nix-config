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
2. **Fetch** in two passes to keep the output small (most volume is bot/social noise):
   - *Pass 1 (default):* `conversations_unreads` with `mentions_only: true`, plus a
     separate call scoped to `channel_types: "dm,group_dm"`. This is the high-signal
     surface (DMs + @mentions of Hazel) and is almost always small enough to read
     inline.
   - *Pass 2 (SMS domain sweep):* targeted `conversations_history` (or a scoped
     `conversations_unreads`) over Hazel's core channels — `#product-sms`,
     `#eng-sms`, `#sms-pumping-prevention`, `#sms-onboarding-implementation`, and any
     thread she's in — since domain asks there often don't @-mention her by name. Run
     this every time; on quick daily runs it can be skipped if Pass 1 is empty and the
     report says so.
     - *Team mentions:* also surface messages that tag the SMS team or a teammate, not
       just Hazel.
       - *The team handle (reliable, always current):* **@sms-team** is `S09E6JX65P0`;
         a message tags it via the raw token `<!subteam^S09E6JX65P0>`. Match that token
         in fetched message text. Since tagging @sms-team notifies all nine members,
         this catches most team-directed asks without any roster.
       - *Individual members (maintained list):* this MCP's `usergroups_list` does NOT
         return member IDs (even with `include_users: true` the CSV omits them), so the
         roster can't be resolved live — it must be listed here and refreshed
         periodically as the team changes. Current @sms-team members (source of truth:
         the usergroup in Slack, 9 members as of 2026-08-03):
         <!-- ROSTER:sms-team — usergroup S09E6JX65P0 (9 members). This MCP can't
              enumerate the group, so reconstructed 2026-08-03 from message evidence
              plus Hazel's corrections: 8 of 9 identified. VERIFY against the Slack
              usergroup and fill the 1 unknown; drop anyone who has since left. -->
         - `U09TD059N1Y` Hazel Lewis      — Senior Eng — SMS       (self)
         - `U04ATCN7HGT` Maggie Zhang     — PM, SMS/RCS
         - `U09JG9WRT5Y` Dean Slama       — SWE — SMS
         - `U0B04V8KB7W` Tyler Schoppe    — Software Engineer
         - `U0B0H1SDKSS` Scott Li         — Software Engineer
         - `U0A3JMUT4VC` Alex Ispa-Cowan  — Senior Software Engineer
         - `U08BFJU56R0` Blaine Muri      — Eng Manager, Email + SMS
         - `U0ADW8ZTCM9` Rya Sciban       — Product
         - (1 member not yet identified — add them)
         Treat an @mention of any listed member, in Hazel's domain channels, as
         surface-worthy.
       - Related on-call handle: **@sms-eoc** `S07GACAF3RU`.
   - *Fallback (wide sweep):* if the user asks for a full catch-up, fall back to the
     broad `conversations_unreads` with `include_messages: true` and `max_channels` /
     `max_messages_per_channel` above defaults (50 / 10). Muted channels stay excluded
     (`include_muted: false`), so noise the user has muted never appears.
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
   in, mentions of **@sms-team** (`S09E6JX65P0`) or any of its current members, asks
   routed to the SMS team, anything time-sensitive/blocking; *skip* announcements,
   automated/FYI posts, noise she isn't part of.
5. **File** surfaced items via `add_todo`, `list_id: "H5WBBFFgYhksuLmNVhc43R"` (stable
   across renames). First resolve channel IDs (`conversations_unreads` gives names, no
   permalink) via one `channels_me` call (`name` → `Cxxxx`); DM/app channels
   (`@incident`, `@linear`) have no ID, so lean on the message's own links. Per item:
   - `title`: concise summary, not a raw paste.
   - `notes`: who + channel; Slack permalink
     `https://onesignal.slack.com/archives/<channel_id>/p<ts-sans-dot>` (`1737936000.123456`
     → `p1737936000123456`); and any URLs the message references (PRs, Linear, Docs,
     incident.io, calendar), which are usually the actionable destination.
   - **Rule: never file a review/approval item without its link.** If the item is
     asking Hazel to review, approve, look at, or unblock something (a PR, a Linear
     issue, a GitHub issue/commit, a doc), the `notes` MUST carry the direct link to
     that thing, not just the Slack permalink. The Slack permalink alone is not enough:
     an item you can't act on without hunting for the link is a broken item. If the
     link isn't in the message text, follow the thread (`conversations_replies`) or the
     channel context to recover it before filing. If it genuinely can't be found, say so
     explicitly in the `notes` (e.g. "PR link not in thread, ask <author>") so the gap
     is visible rather than silently missing.
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
