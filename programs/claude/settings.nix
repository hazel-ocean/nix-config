{ stdenv }:
let
  hook = command: {
    hooks = [
      {
        type = "command";
        inherit command;
      }
    ];
  };

  capture = hook "/Users/hazel/.claude/hooks/capture";
  cleanup = hook "/Users/hazel/.claude/hooks/cleanup";
  notify = hook "/Users/hazel/.claude/hooks/notify";

  darwinHooks = {
    SessionStart = [ capture ];
    UserPromptSubmit = [ capture ];
    SessionEnd = [ cleanup ];
    Notification = [ notify ];
    Stop = [ notify ];
  };
in
{
  "$schema" = "https://json.schemastore.org/claude-code-settings.json";
  permissions = {
    allow = [
      # Entering plan mode is harmless; ExitPlanMode is the real approval gate.
      "EnterPlanMode"
      # The plan file is a scratch artifact. ExitPlanMode is the gate that matters.
      "Edit(/Users/hazel/.claude/plans/**)"
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
      "Bash(git status:*)"
      "Bash(git diff:*)"
      "Bash(git log:*)"
      "Bash(git show:*)"
      "Bash(git branch:*)"
      "Bash(git blame:*)"
      "Bash(git remote -v)"
      # Beads is the work tracker. History-destroying and raw-SQL
      # subcommands are denied below.
      "Bash(bd:*)"
      "mcp__plugin_hm_obsidian__get_note_outline"
      "mcp__plugin_hm_obsidian__read_note_lines"
      "mcp__plugin_hm_obsidian__wiki_link"
      "mcp__plugin_hm_things__get_tag_usage"
    ];
    deny = [
      "Bash(bd sql:*)"
      "Bash(bd purge:*)"
      "Bash(bd prune:*)"
      "Bash(bd flatten:*)"
      "Bash(bd gc:*)"
      "Bash(bd delete:*)"
      "Bash(bd admin:*)"
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
  hooks = if stdenv.hostPlatform.isDarwin then darwinHooks else { };
  enabledPlugins = {
    "github@claude-plugins-official" = false;
    "rust-analyzer-lsp@claude-plugins-official" = true;
    "typescript-lsp@claude-plugins-official" = true;
    "swift-lsp@claude-plugins-official" = true;
  };
  # Codex reads AGENTS.md only. Loading both keeps the user-scope CLAUDE.md,
  # which has no AGENTS.md equivalent, alongside the per-repo AGENTS.md.
  pluginConfigs."agents-md@builtin".options.instructionFiles = "claude-md-and-agents-md";
  effortLevel = "medium";
  tui = "fullscreen";
  voice = {
    enabled = false;
    mode = "tap";
  };
  theme = "auto";
  editorMode = "vim";
  # The default injects a Co-Authored-By trailer and a PR footer, which the
  # attribution rule in CLAUDE.md forbids.
  includeCoAuthoredBy = false;
  preferredNotifChannel = "notifications_disabled";
  inputNeededNotifEnabled = false;
  agentPushNotifEnabled = false;
}
