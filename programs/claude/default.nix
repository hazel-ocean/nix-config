{ pkgs, ... }:

let
  # Platform-specific notify command, spliced into the script below. osascript's
  # `display notification` is native at any arch (it's Apple's scripting bridge),
  # unlike the x86_64 terminal-notifier binary; on Linux fall back to notify-send.
  # The dynamic strings are passed as argv so quotes/newlines in them can't break
  # the AppleScript. Tradeoff vs terminal-notifier: no per-session grouping.
  notifyCmd =
    if pkgs.stdenv.isDarwin then ''
      (^osascript
        -e "on run argv"
        -e 'display notification (item 3 of argv) with title (item 1 of argv) subtitle (item 2 of argv) sound name "Pong"'
        -e "end run"
        $title $subtitle $body)
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

    settings = {
      permissions = {
        allow = [
          # Obsidian: read-only (search / read / get) actions
          "mcp__plugin_claude-code-home-manager_obsidian__search_notes"
          "mcp__plugin_claude-code-home-manager_obsidian__list_directory"
          "mcp__plugin_claude-code-home-manager_obsidian__read_note"
          "mcp__plugin_claude-code-home-manager_obsidian__read_multiple_notes"
          "mcp__plugin_claude-code-home-manager_obsidian__get_frontmatter"
          "mcp__plugin_claude-code-home-manager_obsidian__get_notes_info"
          "mcp__plugin_claude-code-home-manager_obsidian__get_vault_stats"

          # Obsidian: note edits
          "mcp__plugin_claude-code-home-manager_obsidian__patch_note"
          "mcp__plugin_claude-code-home-manager_obsidian__write_note"

          # Granola: read-only (get / list / query) actions
          "mcp__claude_ai_Granola__get_account_info"
          "mcp__claude_ai_Granola__get_meeting_transcript"
          "mcp__claude_ai_Granola__get_meetings"
          "mcp__claude_ai_Granola__list_meeting_folders"
          "mcp__claude_ai_Granola__list_meetings"
          "mcp__claude_ai_Granola__query_granola_meetings"

          # Linear: read-only (get / list / search) actions
          "mcp__claude_ai_Linear__get_attachment"
          "mcp__claude_ai_Linear__get_diff"
          "mcp__claude_ai_Linear__get_diff_threads"
          "mcp__claude_ai_Linear__get_document"
          "mcp__claude_ai_Linear__get_initiative"
          "mcp__claude_ai_Linear__get_issue"
          "mcp__claude_ai_Linear__get_issue_status"
          "mcp__claude_ai_Linear__get_milestone"
          "mcp__claude_ai_Linear__get_project"
          "mcp__claude_ai_Linear__get_status_updates"
          "mcp__claude_ai_Linear__get_team"
          "mcp__claude_ai_Linear__get_user"
          "mcp__claude_ai_Linear__list_comments"
          "mcp__claude_ai_Linear__list_customers"
          "mcp__claude_ai_Linear__list_cycles"
          "mcp__claude_ai_Linear__list_diffs"
          "mcp__claude_ai_Linear__list_documents"
          "mcp__claude_ai_Linear__list_initiatives"
          "mcp__claude_ai_Linear__list_issue_labels"
          "mcp__claude_ai_Linear__list_issue_statuses"
          "mcp__claude_ai_Linear__list_issues"
          "mcp__claude_ai_Linear__list_milestones"
          "mcp__claude_ai_Linear__list_project_labels"
          "mcp__claude_ai_Linear__list_projects"
          "mcp__claude_ai_Linear__list_teams"
          "mcp__claude_ai_Linear__list_users"
          "mcp__claude_ai_Linear__search_documentation"

          # Slack: read-only (list / history / search) actions
          "mcp__plugin_claude-code-home-manager_slack__channels_list"
          "mcp__plugin_claude-code-home-manager_slack__channels_me"
          "mcp__plugin_claude-code-home-manager_slack__conversations_history"
          "mcp__plugin_claude-code-home-manager_slack__conversations_replies"
          "mcp__plugin_claude-code-home-manager_slack__conversations_search_messages"
          "mcp__plugin_claude-code-home-manager_slack__conversations_unreads"
          "mcp__plugin_claude-code-home-manager_slack__saved_list"
          "mcp__plugin_claude-code-home-manager_slack__usergroups_list"
          "mcp__plugin_claude-code-home-manager_slack__usergroups_me"
          "mcp__plugin_claude-code-home-manager_slack__users_search"

          # Slack: mark channels read after a triage scan-through
          "mcp__plugin_claude-code-home-manager_slack__conversations_mark"

          # Things: read-only (get / search / show) actions
          "mcp__plugin_claude-code-home-manager_things__get_anytime"
          "mcp__plugin_claude-code-home-manager_things__get_areas"
          "mcp__plugin_claude-code-home-manager_things__get_headings"
          "mcp__plugin_claude-code-home-manager_things__get_inbox"
          "mcp__plugin_claude-code-home-manager_things__get_logbook"
          "mcp__plugin_claude-code-home-manager_things__get_projects"
          "mcp__plugin_claude-code-home-manager_things__get_recent"
          "mcp__plugin_claude-code-home-manager_things__get_someday"
          "mcp__plugin_claude-code-home-manager_things__get_tagged_items"
          "mcp__plugin_claude-code-home-manager_things__get_tags"
          "mcp__plugin_claude-code-home-manager_things__get_today"
          "mcp__plugin_claude-code-home-manager_things__get_todos"
          "mcp__plugin_claude-code-home-manager_things__get_trash"
          "mcp__plugin_claude-code-home-manager_things__get_upcoming"
          "mcp__plugin_claude-code-home-manager_things__search_advanced"
          "mcp__plugin_claude-code-home-manager_things__search_items"
          "mcp__plugin_claude-code-home-manager_things__search_todos"
          "mcp__plugin_claude-code-home-manager_things__show_item"

          # Things: create actions (non-destructive — add new items only)
          "mcp__plugin_claude-code-home-manager_things__add_project"
          "mcp__plugin_claude-code-home-manager_things__add_todo"
        ];
        ask = [ "Write" ];
        defaultMode = "default";
      };
      model = "opus[1m]";
      enabledPlugins = {
        "typescript-lsp@claude-plugins-official" = true;
        "rust-analyzer-lsp@claude-plugins-official" = true;
        # Hosted GitHub MCP (api.githubcopilot.com) — Copilot-gated, returns
        # HTTP 400. Replaced by the self-hosted read-only github server in the
        # host mcpServers config.
        "github@claude-plugins-official" = false;
      };
      effortLevel = "high";
      theme = "dark-ansi";
      editorMode = "vim";
      tui = "fullscreen";

      # Native voice dictation. tap = tap once to record, tap again to send
      # (works alongside vim editorMode; hold-to-talk would fight the Space key).
      voice = {
        enabled = true;
        mode = "tap";
      };

      hooks = {
        Stop = [
          { hooks = [ { type = "command"; command = "${notify}"; } ]; }
        ];
        Notification = [
          { hooks = [ { type = "command"; command = "${notify}"; } ]; }
        ];
      };
    };
  };
}
