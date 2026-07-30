{ pkgs, config, lib, ... }:

let
  # Platform-specific notify command, spliced into the script below. On macOS,
  # post via the notifier .app installed in ~/Applications by the activation
  # script below; `open` propagates the ZELLIJ_* env, so the app captures the
  # session/pane to return to. On Linux, fall back to notify-send.
  notifyCmd =
    if pkgs.stdenv.isDarwin then ''
      (^open ($env.HOME | path join "Applications" "ClawdBack.app") --args notify --title $title --message $body --session-id $session_id)
    '' else ''
      (^${pkgs.libnotify}/bin/notify-send $title $"($subtitle): ($body)")
    '';

  # Fired by Claude's Stop + Notification hooks. Reads the hook's JSON
  # payload on stdin and the zellij env vars present in the hook's process
  # (the hook runs inside your ghostty/zellij pane, so they're inherited).
  notify = pkgs.writeScript "claude-notify.nu" ''
    #!${pkgs.nushell}/bin/nu --stdin
    let input = (try { $in | from json } catch { {} })

    let event   = ($input.hook_event_name? | default "")
    let message = ($input.message? | default "")

    let session = ($env.ZELLIJ_SESSION_NAME? | default "")
    let session_id = ($input.session_id? | default "")
    let transcript = ($input.transcript_path? | default "")

    # Label the session by its zellij name, or "Ghostty" for a bare session.
    let name = (if ($session | is-empty) { "Ghostty" } else { $session })
    let need = (if ($message | is-empty) { "Claude needs your input" } else { $message })

    let title = (match $event {
      "Notification" => $need
      "Stop" | _     => "Claude has finished and is waiting..."
    })
    let subtitle = $name

    # Body: the session name plus Claude's last text message. Scan the tail of
    # the transcript (the final assistant entry is often a tool_use, not text).
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
    let body = (if ($last_said | is-empty) { $name } else { $"($name) > ($last_said)" })

    ${notifyCmd}
  '';

  # Fired by Claude's SessionStart + UserPromptSubmit hooks. Records Claude's
  # window/tab (via the notifier's `capture` mode) so notify/click can return to
  # the exact window. On SessionStart only for session initiation
  # (startup/resume/clear/fork) — never background compaction, which could run
  # while the terminal isn't frontmost. UserPromptSubmit (no `source` field)
  # re-captures every turn so a Zellij reattach into a different window refreshes
  # the stale ids; the app only saves when the terminal is frontmost, which both
  # events guarantee. Guarded on the app existing, so it's a no-op on hosts
  # without it (e.g. Linux).
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
  programs.claude-code = {
    context = ./memory.md;
    skills = ./.agents/skills;
  };

  # ~/.claude/settings.json is an out-of-store symlink to the committed file at
  # programs/claude/settings.json, so Claude Code's runtime writers (/effort,
  # /config, /model, /permissions) can write it and the edits surface as
  # committable repo changes. Nix owns this pointer and the notify hook, not the
  # file's contents; `just apply` re-asserts only the symlink, never the values.
  # Edit the JSON directly (or let Claude write it) to change settings. Leaving
  # programs.claude-code.settings unset stops the module rendering its own
  # read-only settings.json, freeing this slot. See task "Fix Claude Settings
  # being readonly".
  #
  # Permission allowlist groups the committed file carries:
  #   - Built-in read-only: WebSearch, WebFetch
  #   - Obsidian: read-only (search/read/get) + note edits (patch/write)
  #   - Granola: read-only (get/list/query)
  #   - Linear:  read-only (get/list/search)
  #   - Slack:   read-only (list/history/search) + deferred conversations_mark
  #              (`/slack-triage mark-read`, run after review)
  #   - Things:  read-only (get/search/show) + create (add_project/add_todo)
  # enabledPlugins disables github@claude-plugins-official: the hosted GitHub MCP
  # (api.githubcopilot.com) is Copilot-gated (HTTP 400); the self-hosted
  # read-only github server in the host mcpServers config replaces it.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix-config/programs/claude/settings.json";

  # Stable path for the notify hook so the committed settings.json holds no
  # rotating /nix/store hash; Nix refreshes the target on each switch. The hook
  # references /Users/hazel/.claude/hooks/notify (espeon is the sole importer).
  home.file.".claude/hooks/notify".source = notify;

  # SessionStart + UserPromptSubmit hook: capture Claude's window/tab while it's
  # reliably frontmost.
  home.file.".claude/hooks/capture".source = capture;

  # SessionEnd hook: drop this session's saved window/tab state.
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
