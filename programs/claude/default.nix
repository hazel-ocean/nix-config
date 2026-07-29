{ pkgs, config, lib, ... }:

let
  # Platform-specific notify command, spliced into the script below. On macOS,
  # post via the notifier .app installed in ~/Applications by the activation
  # script below; `open` propagates the ZELLIJ_* env, so the app captures the
  # session/pane to return to. On Linux, fall back to notify-send.
  notifyCmd =
    if pkgs.stdenv.isDarwin then ''
      (^open ($env.HOME | path join "Applications" "ClaudeZellijWhip.app") --args notify --title $title --message $body --folder $dir)
    '' else ''
      (^${pkgs.libnotify}/bin/notify-send $title $"($subtitle) — ($body)")
    '';

  # Fired by Claude's Stop + Notification hooks. Reads the hook's JSON
  # payload on stdin and the zellij env vars present in the hook's process
  # (the hook runs inside your ghostty/zellij pane, so they're inherited).
  notify = pkgs.writeScript "claude-notify.nu" ''
    #!${pkgs.nushell}/bin/nu
    let input = (try { $in | from json } catch { {} })

    let event   = ($input.hook_event_name? | default "")
    let message = ($input.message? | default "")
    let cwd     = ($input.cwd? | default $env.PWD)
    let dir     = ($cwd | path basename)

    let session = ($env.ZELLIJ_SESSION_NAME? | default "")
    let pane    = ($env.ZELLIJ_PANE_ID? | default "")

    let tb = (match $event {
      "Notification" => { title: "Claude needs you", body: (if ($message | is-empty) { "Waiting for input" } else { $message }) }
      "Stop"         => { title: "Claude is done",   body: $"Finished in ($dir)" }
      _              => { title: "Claude",           body: $dir }
    })

    let title = $tb.title
    mut subtitle = $dir
    mut body = $tb.body
    if not ($session | is-empty) {
      $subtitle = $"($dir) · ($session)"
      if not ($pane | is-empty) {
        $body = $"($body) [pane ($pane)]"
      }
    }

    ${notifyCmd}
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

  # Install the notifier where LaunchServices can find it: a real copy in
  # ~/Applications (not a /nix/store symlink, whose path rotates each rebuild),
  # chmod'd writable, ad-hoc re-signed, and registered so a notification click
  # relaunches it by bundle id.
  home.activation.installClaudeZellijWhip = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/Applications/ClaudeZellijWhip.app"
    run rm -rf "$dest"
    run mkdir -p "$HOME/Applications"
    run cp -RL ${pkgs.claude-zellij-whip}/Applications/ClaudeZellijWhip.app "$dest"
    run chmod -R u+w "$dest"
    run /usr/bin/codesign --force --sign - "$dest"
    run /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$dest"
  '';
}
