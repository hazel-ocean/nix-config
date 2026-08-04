---
name: triage-review
description: One sweep across Slack, Linear, and GitHub to surface anything actionable since the last check — DMs/@mentions, Linear stories assigned to you with new comments or review activity, newly assigned stories (prompt to spin up as a project), and open PRs awaiting your review or where you're pinged. Files each into the Things "Triage" project with its direct link, tracking per-source watermarks so repeated runs never reprocess the same thing. Does NOT mark Slack read on triage; that's a separate `mark-read` step. Use to catch up without babysitting.
---

# Triage / Review

Sweep three sources in one pass, file the worthwhile items into the Things
**Triage** project (each carrying its direct link), and advance per-source
watermarks so nothing is triaged twice:

- **Slack** — unreads worth Hazel's attention.
- **Linear** — stories assigned to her with new comments/review activity, newly
  assigned stories, and comment @mentions, all since the last check.
- **GitHub** — open PRs awaiting her review, PRs where she's @mentioned, and her
  own PRs with new activity.

Filing never marks Slack read; the badge stays until you run `mark-read` after
reviewing.

**Modes** (by argument): no arg = **triage** (all three sources); `mark-read` =
mark Slack channels read up to the watermark.

## State — `~/.local/state/claude/triage-review.json`

```json
{
  "watermark_ts": "1737936000.123456",
  "linear_checked_at": "2026-08-04T09:00:00Z",
  "known_issue_ids": ["ENG-123", "SMS-456"],
  "last_triaged_at": "2026-08-04T09:05:00Z",
  "runs": 3
}
```

- `watermark_ts` — Slack `ts` (global epoch, comparable across channels) of the
  newest message handled; everything ≤ it is done. Compare `ts` numerically, never
  wall-clock.
- `linear_checked_at` — ISO instant of the last run's start; the cutoff for "new"
  Linear comments and GitHub PR activity. Capture *now* at the start of the run and
  advance to it at the end (so nothing landing mid-run is skipped next time).
- `known_issue_ids` — Linear issue identifiers assigned to Hazel seen on prior runs;
  an assigned issue whose id is absent is *newly assigned*.

`Read` at start, `Write` at end (create the dir if needed). Missing file = first
run: if a legacy `~/.local/state/claude/slack-triage.json` exists, read
`watermark_ts`/`runs` from it once to carry the Slack watermark forward; otherwise
bound Slack to ~last 7 days and Linear/GitHub to ~last 3 days so a backlog doesn't
flood, and say so in the report.

---

## Source 1 — Slack

1. **Fetch** in two passes to keep the output small (most volume is bot/social noise):
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
2. **Filter:** keep `ts` > `watermark_ts` (first run: within the 7-day bound). Count
   what you considered.
3. **Judge:** *surface* DMs, @mentions, direct asks/questions to Hazel, threads she's
   in, mentions of **@sms-team** (`S09E6JX65P0`) or any of its current members, asks
   routed to the SMS team, anything time-sensitive/blocking; *skip* announcements,
   automated/FYI posts, noise she isn't part of.
4. **Resolve channel IDs** for permalinks: `conversations_unreads` gives names, no
   permalink — one `channels_me` call maps `name` → `Cxxxx`. DM/app channels
   (`@incident`, `@linear`) have no ID, so lean on the message's own links.
5. **File** surfaced items (see **Filing**). Slack permalink for a `ts`:
   `https://onesignal.slack.com/archives/<channel_id>/p<ts-sans-dot>`
   (`1737936000.123456` → `p1737936000123456`).

## Source 2 — Linear

Resolve Hazel once per run: `get_user` `"me"` → her id/name (used to exclude her own
comments and to detect @mentions of her). "Since" = `linear_checked_at` (first run:
~last 3 days).

1. **Assigned stories:** `list_issues` `assignee: "me"`, `orderBy: updatedAt`,
   `updatedAt: <since>` (ISO or a duration like `-P3D`). Fields should include
   `identifier`/`url`/`title`/`updatedAt`/`state`/`project`. This is the working set.
2. **Newly assigned → prompt as a project.** Any assigned issue whose identifier is
   **not** in `known_issue_ids` is new to Hazel. Surface it prominently and, per her
   convention (a new project = a Things Project under the OneSignal Area, journal in
   Obsidian, Linear link), **ask whether to spin it up as a project** — do not create
   the project automatically. File a Triage todo for it regardless so it isn't lost.
3. **New comments / review activity:** for each assigned issue touched since `since`,
   `list_comments` `orderBy: createdAt` and keep comments with `createdAt > since`
   authored by someone other than Hazel. Surface if anyone commented on, asked about,
   or requested changes on her work. Treat a comment whose body @mentions Hazel as a
   **ping** (higher priority) even on issues not assigned to her — catch these from the
   same comment scan on issues she's involved in.
4. **File** each surfaced Linear item (see **Filing**); the issue `url` is the required
   link. After filing, set `known_issue_ids` to the *current* full assigned set (so
   today's new ones aren't re-flagged tomorrow, and un-assignments drop off).

Read-only: never post Linear comments or change issue state from this skill.

## Source 3 — GitHub PRs

Hazel resolves server-side as `@me` in search — no username lookup needed. "Since" =
`linear_checked_at` (the shared last-check instant; first run ~last 3 days).

Run `search_pull_requests` scoped to `org:OneSignal is:pr is:open`:

1. **Awaiting her review:** `review-requested:@me` — the core "should I look at this"
   set. File each.
2. **Pinged:** `mentions:@me updated:>=<since>` — PRs where she's been @mentioned
   recently (review threads, "can you take a look", follow-ups).
3. **Her own PRs with new activity:** `author:@me updated:>=<since>` — surface only
   when there's something to act on (a review left, changes requested, unresolved
   threads); skip her own PRs that merely got a green check. Use `pull_request_read`
   to check review/comment state when the title alone is ambiguous.
4. **Dedupe.** These PRs frequently *also* arrive via Slack `#sms-pr-reviews`
   (`C0A4VJ9MGSV`) and via Linear review requests. Key by PR URL: if a PR is already
   surfaced this run, or an existing open Triage todo already links it, don't file a
   duplicate — merge into the one item.
5. **File** each (see **Filing**); the PR URL is the required link.

---

## Filing

Everything surfaced lands in the Things **Triage** project via `add_todo`,
`list_id: "H5WBBFFgYhksuLmNVhc43R"` (stable across renames; the project was formerly
"From Slack"). Per item:

- `title`: concise summary of the ask, not a raw paste. Prefix by source when it
  aids scanning (e.g. `Review PR:`, `Linear:`, `Slack:`).
- `notes`: who + where (channel / issue / repo); the source permalink; **and the
  direct actionable link.**
- **Rule: never file a review/approval item without its link.** If the item asks
  Hazel to review, approve, look at, or unblock something (a PR, a Linear issue, a
  GitHub issue/commit, a doc), the `notes` MUST carry the direct link to that thing.
  A Slack permalink or an issue reference alone is not enough — an item she can't act
  on without hunting for the link is a broken item. If the link isn't in the message,
  follow the thread (`conversations_replies`) or channel/issue context to recover it
  before filing. If it genuinely can't be found, say so explicitly in the `notes`
  (e.g. "PR link not in thread, ask <author>") so the gap is visible, never silently
  missing.
- `tags`: `["✨ OS/Priorities"]` if time-sensitive/blocking/a direct ask/ping;
  `["Bug"]` for defects (both allowed); else none.
- **Dedup across sources and against existing todos** by the direct link: one PR or
  issue = one Triage item, even if it showed up in Slack *and* Linear *and* GitHub.

## Advance state

- **Slack watermark, only over what you fully covered.** Not truncated → max `ts`
  across all fetched unreads (incl. skipped). Truncated → do **not** jump to that max
  (unscanned channels may hold older-than-max messages you'd lose forever); advance
  only to the min across channels of each channel's oldest fetched `ts`, or leave it
  and say so.
- **`linear_checked_at`** → the instant captured at the start of this run (covers
  both Linear and GitHub). If a source was skipped or errored, leave it and report so
  next run re-covers the window.
- **`known_issue_ids`** → current assigned set (Linear step 4).
- Bump `runs`, set `last_triaged_at`, Write. **Never mark Slack read here.**

## Report

With counters, per source: Slack (channels scanned, considered, filed, skipped,
`truncated` if tripped); Linear (assigned reviewed, new comments, **newly assigned →
project?**, pings); GitHub (awaiting-review, pinged, own-PR activity, deduped). Then:
new watermark + human time; project link
`things:///show?id=H5WBBFFgYhksuLmNVhc43R`; and *"reviewed in Things? run
`/triage-review mark-read`."*

## mark-read

Run after reviewing filed items. Load state; no watermark → nothing to do, stop.
Enumerate unread channels (`conversations_unreads`, `include_messages: false`), call
`conversations_mark` `ts: watermark_ts` on each (marks read only up to the triaged
point; newer stays unread). Report how many channels were marked. Linear/GitHub have
no read-state side effects here — this step is Slack-only.

Limitation (v1): all-or-nothing up to the watermark; can't mark read "just the items
you reviewed" if you've only reviewed some.

## Notes

- No tool allow-list is declared on purpose. Slack/Linear/GitHub/Things/Task grants
  are managed centrally in `programs/claude/default.nix`; look there for what's
  permitted. This skill is read-only against Linear and GitHub; it only writes to
  Things (and Slack read-state in `mark-read`).
