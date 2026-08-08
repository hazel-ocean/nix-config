# Espeon-specific Claude config: OneSignal Obsidian vault, Slack, and the
# self-hosted onesignal-repos MCP server + OneSignal Claude plugins. Kept out
# of shared/ since only espeon uses OneSignal repo paths, plugins, or
# workspace credentials.
{ pkgs, ... }:
{
  imports = [
    ./shared
    ./shared/slack.nix
    (import ./shared/obsidian.nix {
      vault = "/Users/hazel/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/";
    })
  ];

  programs.claude-code = {
    mcpServers.onesignal-repos = {
      type = "stdio";
      command = "${pkgs.onesignal-repos-mcp}/bin/onesignal-repos-mcp";
      env.ONESIGNAL_WORKSPACE_ROOT = "/Users/hazel/OneSignal/src";
    };
    plugins = with pkgs.onesignal-plugins; [
      epd-ops
      housekeeping
      onesignal-org
    ];
  };
}
