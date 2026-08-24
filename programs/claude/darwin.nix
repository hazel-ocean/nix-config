# ClawdBack notification/window-tracking hooks. Darwin-only: relies on
# ~/Applications/ClawdBack.app to remember which window/tab/Zellij pane
# Claude was running in, so a notification click can jump back to it. Import
# from Darwin hosts alongside programs/claude (currently espeon, pigeon).
{ pkgs, config, lib, ... }:

let
  # Fired by Claude's Stop + Notification hooks. Reads the hook's JSON
  # payload on stdin and the zellij env vars present in the hook's process
  # (the hook runs inside your ghostty/zellij pane, so they're inherited).
  notify = pkgs.writeScript "claude-notify.nu" ''
    #!${pkgs.nushell}/bin/nu --stdin
    let input = (try { $in | from json } catch { {} })

    let event   = ($input.hook_event_name? | default "")
    let message = ($input.message? | default "")
    let session_id = ($input.session_id? | default "")
    let transcript = ($input.transcript_path? | default "")
    let cwd = ($input.cwd? | default ($env.PWD? | default ""))

    # Claude's last text message, from the tail of the transcript (the final
    # assistant entry is often a tool_use, not text, so scan back a bit).
    let last_said = (
      if ($transcript | is-not-empty) and ($transcript | path exists) {
        let texts = (open $transcript | lines | last 150
          | each { |l| try { $l | from json } catch { null } } | compact
          | where type? == "assistant"
          | each { |e| try { $e.message.content | where type? == "text" | get text | str join " " } catch { "" } }
          | where ($it | str trim | is-not-empty))
        if ($texts | is-empty) { "" } else { $texts | last | str trim | str replace -a (char newline) " " | str substring 0..180 }
      } else { "" }
    )

    # Lead the title with the zellij session name when present, so a glance
    # tells you which workspace wants you.
    let workspace = ($env.ZELLIJ_SESSION_NAME? | default "")
    let title = (match [$event $workspace] {
      ["Notification" ""]  => (if ($message | str trim | is-empty) { "Claude needs your input" } else { $message })
      ["Stop" ""]          => "Claude has finished and is waiting"
      ["Notification" $ws] => $"[($ws)] needs your input."
      ["Stop" $ws]         => $"[($ws)] is waiting."
      [$other _]           => (error make { msg: $"unknown hook event: ($other)" })
    })
    let body = (if ($last_said | str trim | is-empty) { "Click to go check on Clawd." } else { $last_said })

    # `open` propagates the ZELLIJ_* env, so the app captures the
    # session/pane to return to.
    (^open ($env.HOME | path join "Applications" "ClawdBack.app") --args notify --title $title --message $body --session-id $session_id --cwd $cwd)
  '';

  # Fired by Claude's SessionStart + UserPromptSubmit hooks. Re-derives Claude's
  # window/tab and Zellij pane (via the notifier's `capture` mode) so notify/click
  # can return to the exact window, and clears any banner the session left
  # behind. On SessionStart only for session initiation (startup/resume/clear/
  # fork), never background compaction. UserPromptSubmit (no `source` field) runs
  # every turn: the app re-reads what it can and drops any target that no longer
  # resolves, so a Zellij reattach into a different window refreshes the stale
  # ids. Guarded on the app existing, so it's a no-op if activation hasn't
  # installed it yet.
  capture = pkgs.writeScript "claude-capture.nu" ''
    #!${pkgs.nushell}/bin/nu --stdin
    let input = (try { $in | from json } catch { {} })
    let source = ($input.source? | default "")
    let event = ($input.hook_event_name? | default "")
    let session_id = ($input.session_id? | default "")
    let app = ($env.HOME | path join "Applications" "ClawdBack.app")
    let wanted = (($source in ["startup" "resume" "clear" "fork"]) or ($event == "UserPromptSubmit"))
    if ($session_id | is-not-empty) and $wanted and ($app | path exists) {
      ^open $app --args capture --session-id $session_id
    }
  '';

  # Fired by Claude's SessionEnd hook. Drops this session's saved window/tab
  # state (~/.cache/clawd-back/<id>.json) via the notifier's `cleanup` mode.
  cleanup = pkgs.writeScript "claude-cleanup.nu" ''
    #!${pkgs.nushell}/bin/nu --stdin
    let input = (try { $in | from json } catch { {} })
    let session_id = ($input.session_id? | default "")
    let app = ($env.HOME | path join "Applications" "ClawdBack.app")
    if ($session_id | is-not-empty) and ($app | path exists) {
      ^open $app --args cleanup --session-id $session_id
    }
  '';
in
{
  # Stable paths so the committed settings.json (programs/claude/default.nix)
  # holds no rotating /nix/store hash; Nix refreshes the targets on each
  # switch. Both current importers (espeon, pigeon) use the "hazel" username,
  # so settings.json's hardcoded /Users/hazel/.claude/hooks/* paths hold for
  # either.
  home.file.".claude/hooks/notify".source = notify;
  home.file.".claude/hooks/capture".source = capture;
  home.file.".claude/hooks/cleanup".source = cleanup;

  # Install the notifier where LaunchServices can find it: a real copy in
  # ~/Applications (not a /nix/store symlink, whose path rotates each rebuild),
  # chmod'd writable, ad-hoc re-signed, and registered so a notification click
  # relaunches it by bundle id.
  home.activation.installClawdBack = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/Applications/ClawdBack.app"
    run rm -rf "$dest"
    run mkdir -p "$HOME/Applications"
    run cp -RL ${pkgs.clawd-back}/Applications/ClawdBack.app "$dest"
    run chmod -R u+w "$dest"
    run /usr/bin/codesign --force --sign - "$dest"
    run /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$dest"
  '';
}
