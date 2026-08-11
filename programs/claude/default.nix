{ config, ... }:
{
  programs.claude-code = {
    context = ./memory.md;
    skills = ./.agents/skills;
    commands.nu = ./commands/nu.md;
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
  #   - Linear:  read-only (get/list/search)
  #   - Slack:   read-only (list/history/search) + deferred conversations_mark
  #              (`/triage-review mark-read`, run after review)
  #   - Things:  read-only (get/search/show) + create (add_project/add_todo)
  #   - onesignal-repos: read-only only (check/list/read/search/file_exists/
  #                      get_repo_path); write_* and refresh/index excluded
  # enabledPlugins disables github@claude-plugins-official: the hosted GitHub MCP
  # (api.githubcopilot.com) is Copilot-gated (HTTP 400); the self-hosted
  # read-only github server in the host mcpServers config replaces it.
  #
  # settings.json's hook commands point at /Users/hazel/.claude/hooks/{notify,
  # capture,cleanup} — those files come from programs/claude/darwin.nix, which
  # every current importer of this module also imports.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nix-config/programs/claude/settings.json";
}
