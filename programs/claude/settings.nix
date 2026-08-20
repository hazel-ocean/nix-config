{ stdenv, beads }:
let
  hook = command: { hooks = [ { type = "command"; inherit command; } ]; };

  # `bd prime` reinjects the beads issue graph on a new session and after a
  # compaction. Outside a repo with .beads/ it prints nothing and exits 0, so
  # it is safe to run globally. v1.0.3 has no --hook-json flag; cobra would
  # exit non-zero on it.
  beadsPrime = hook "${beads}/bin/bd prime";

  capture = hook "/Users/hazel/.claude/hooks/capture";
  cleanup = hook "/Users/hazel/.claude/hooks/cleanup";
  notify = hook "/Users/hazel/.claude/hooks/notify";

  darwinHooks = {
    SessionStart = [
      beadsPrime
      capture
    ];
    UserPromptSubmit = [ capture ];
    SessionEnd = [ cleanup ];
    Notification = [ notify ];
    Stop = [ notify ];
  };

  linuxHooks = {
    SessionStart = [ beadsPrime ];
  };
in
{
  "$schema" = "https://json.schemastore.org/claude-code-settings.json";
  permissions = {
    allow = [
      "WebSearch"
      "WebFetch"
      "mcp__plugin_hm_obsidian__search_notes"
      "mcp__plugin_hm_obsidian__list_directory"
      "mcp__plugin_hm_obsidian__read_note"
      "mcp__plugin_hm_obsidian__read_multiple_notes"
      "mcp__plugin_hm_obsidian__get_frontmatter"
      "mcp__plugin_hm_obsidian__get_notes_info"
      "mcp__plugin_hm_obsidian__get_vault_stats"
      "mcp__plugin_hm_obsidian__list_all_tags"
      "mcp__plugin_hm_obsidian__patch_note"
      "mcp__plugin_hm_obsidian__write_note"
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
      "mcp__plugin_hm_slack__channels_list"
      "mcp__plugin_hm_slack__channels_me"
      "mcp__plugin_hm_slack__conversations_history"
      "mcp__plugin_hm_slack__conversations_replies"
      "mcp__plugin_hm_slack__conversations_search_messages"
      "mcp__plugin_hm_slack__conversations_unreads"
      "mcp__plugin_hm_slack__saved_list"
      "mcp__plugin_hm_slack__usergroups_list"
      "mcp__plugin_hm_slack__usergroups_me"
      "mcp__plugin_hm_slack__users_search"
      "mcp__plugin_hm_slack__conversations_mark"
      "mcp__claude_ai_Slack__slack_read_canvas"
      "mcp__claude_ai_Slack__slack_read_channel"
      "mcp__claude_ai_Slack__slack_read_thread"
      "mcp__claude_ai_Slack__slack_read_user_profile"
      "mcp__claude_ai_Slack__slack_search_channels"
      "mcp__claude_ai_Slack__slack_search_public"
      "mcp__claude_ai_Slack__slack_search_public_and_private"
      "mcp__claude_ai_Slack__slack_search_users"
      "mcp__plugin_hm_things__get_anytime"
      "mcp__plugin_hm_things__get_areas"
      "mcp__plugin_hm_things__get_headings"
      "mcp__plugin_hm_things__get_inbox"
      "mcp__plugin_hm_things__get_logbook"
      "mcp__plugin_hm_things__get_projects"
      "mcp__plugin_hm_things__get_recent"
      "mcp__plugin_hm_things__get_someday"
      "mcp__plugin_hm_things__get_tagged_items"
      "mcp__plugin_hm_things__get_tags"
      "mcp__plugin_hm_things__get_today"
      "mcp__plugin_hm_things__get_todos"
      "mcp__plugin_hm_things__get_trash"
      "mcp__plugin_hm_things__get_upcoming"
      "mcp__plugin_hm_things__search_advanced"
      "mcp__plugin_hm_things__search_items"
      "mcp__plugin_hm_things__search_todos"
      "mcp__plugin_hm_things__show_item"
      "mcp__plugin_hm_things__add_project"
      "mcp__plugin_hm_things__add_todo"
      "mcp__plugin_hm_github__get_commit"
      "mcp__plugin_hm_github__get_file_contents"
      "mcp__plugin_hm_github__get_label"
      "mcp__plugin_hm_github__get_latest_release"
      "mcp__plugin_hm_github__get_me"
      "mcp__plugin_hm_github__get_release_by_tag"
      "mcp__plugin_hm_github__get_tag"
      "mcp__plugin_hm_github__get_team_members"
      "mcp__plugin_hm_github__get_teams"
      "mcp__plugin_hm_github__issue_read"
      "mcp__plugin_hm_github__list_branches"
      "mcp__plugin_hm_github__list_commits"
      "mcp__plugin_hm_github__list_issue_fields"
      "mcp__plugin_hm_github__list_issue_types"
      "mcp__plugin_hm_github__list_issues"
      "mcp__plugin_hm_github__list_pull_requests"
      "mcp__plugin_hm_github__list_releases"
      "mcp__plugin_hm_github__list_repository_collaborators"
      "mcp__plugin_hm_github__list_tags"
      "mcp__plugin_hm_github__pull_request_read"
      "mcp__plugin_hm_github__search_code"
      "mcp__plugin_hm_github__search_commits"
      "mcp__plugin_hm_github__search_issues"
      "mcp__plugin_hm_github__search_pull_requests"
      "mcp__plugin_hm_github__search_repositories"
      "mcp__plugin_hm_github__search_users"
      "mcp__plugin_hm_onesignal-repos__check_remote_access"
      "mcp__plugin_hm_onesignal-repos__file_exists"
      "mcp__plugin_hm_onesignal-repos__get_repo_path"
      "mcp__plugin_hm_onesignal-repos__list_all_repos"
      "mcp__plugin_hm_onesignal-repos__list_files"
      "mcp__plugin_hm_onesignal-repos__list_repos"
      "mcp__plugin_hm_onesignal-repos__read_file"
      "mcp__plugin_hm_onesignal-repos__read_knowledge"
      "mcp__plugin_hm_onesignal-repos__search_files"
      "mcp__plugin_hm_wispr-flow__get_account_info"
      "mcp__plugin_hm_wispr-flow__get_calendar_event"
      "mcp__plugin_hm_wispr-flow__get_meeting"
      "mcp__plugin_hm_wispr-flow__get_meeting_attendee_emails"
      "mcp__plugin_hm_wispr-flow__get_meeting_by_calendar_id"
      "mcp__plugin_hm_wispr-flow__get_scratchpad_note"
      "mcp__plugin_hm_wispr-flow__get_upcoming_meeting"
      "mcp__plugin_hm_wispr-flow__list_meeting_series"
      "mcp__plugin_hm_wispr-flow__list_upcoming_meetings"
      "mcp__plugin_hm_wispr-flow__resolve_calendar_link"
      "mcp__plugin_hm_wispr-flow__resolve_share_link"
      "mcp__plugin_hm_wispr-flow__search_calendar_events"
      "mcp__plugin_hm_wispr-flow__search_meetings"
      "mcp__plugin_hm_wispr-flow__search_scratchpad_notes"
      "Bash(gh pr view:*)"
      "Bash(gh pr list:*)"
      "Bash(gh pr diff:*)"
      "Bash(gh pr checks:*)"
      "Bash(gh pr status:*)"
      "Bash(gh issue view:*)"
      "Bash(gh issue list:*)"
      "Bash(gh issue status:*)"
      "Bash(gh repo view:*)"
      "Bash(gh release view:*)"
      "Bash(gh release list:*)"
      "Bash(gh run view:*)"
      "Bash(gh run list:*)"
      "Bash(gh workflow view:*)"
      "Bash(gh workflow list:*)"
      "Bash(gh label list:*)"
      "Bash(gh search:*)"
      "Bash(gh api --method GET:*)"
    ];
    deny = [
      "Bash(brew style:*)"
      "Bash(brew audit:*)"
      "Bash(brew tests:*)"
      "Bash(brew typecheck:*)"
      "Bash(brew prof:*)"
      "Bash(brew ruby:*)"
      "Bash(brew sh:*)"
      "Bash(brew rubocop:*)"
      "Bash(brew bump:*)"
      "Bash(brew pr-:*)"
      "Bash(brew vendor-:*)"
      "Bash(brew install-bundler-gems:*)"
      "Bash(brew update-python-resources:*)"
      "Bash(brew generate-:*)"
      "Bash(brew contributions:*)"
      "Bash(brew dispatch-build-bottle:*)"
      "Bash(brew developer:*)"
    ];
    ask = [ "Write" ];
    defaultMode = "default";
  };
  model = "opus[1m]";
  hooks = if stdenv.hostPlatform.isDarwin then darwinHooks else linuxHooks;
  enabledPlugins = {
    "github@claude-plugins-official" = false;
    "rust-analyzer-lsp@claude-plugins-official" = true;
    "typescript-lsp@claude-plugins-official" = true;
    "swift-lsp@claude-plugins-official" = true;
  };
  effortLevel = "medium";
  tui = "fullscreen";
  voice = {
    enabled = false;
    mode = "tap";
  };
  theme = "auto";
  editorMode = "vim";
  preferredNotifChannel = "notifications_disabled";
  inputNeededNotifEnabled = false;
  agentPushNotifEnabled = false;
}
