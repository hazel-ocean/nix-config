# OneSignal-specific Claude config: import this from hosts used for OneSignal
# work (currently espeon; korriban once that's set up). Kept out of
# programs/claude/default.nix so personal-only hosts (pigeon) don't pull in
# OneSignal repo paths, plugins, or workspace credentials.
{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    mcp-obsidian
    mcp-slack
    obsidian-agent-client
  ];

  programs.claude-code = {
    mcpServers = {
      obsidian = {
        type = "stdio";
        command = "${pkgs.mcp-obsidian}/bin/mcp-obsidian";
        args = [ "/Users/hazel/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/" ];
      };
      slack = {
        type = "stdio";
        command = "/bin/sh";
        args = [
          "-c"
          "export SLACK_MCP_XOXC_TOKEN=$(cat ~/.config/mcp-slack/xoxc-token) && export SLACK_MCP_XOXD_TOKEN=$(cat ~/.config/mcp-slack/xoxd-token) && exec ${pkgs.mcp-slack}/bin/mcp-slack"
        ];
      };
      onesignal-repos = {
        type = "stdio";
        command = "${pkgs.onesignal-repos-mcp}/bin/onesignal-repos-mcp";
        env.ONESIGNAL_WORKSPACE_ROOT = "/Users/hazel/OneSignal/src";
      };
    };
    plugins = with pkgs.onesignal-plugins; [
      epd-ops
      housekeeping
      onesignal-org
    ];
  };

  # Obsidian plugin symlink for the OneSignal vault.
  home.activation.onesignalObsidianPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $VERBOSE_ARG \
      "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/.obsidian/plugins/agent-client"

    run ln -fsn $VERBOSE_ARG \
      ${pkgs.obsidian-agent-client}/* \
      "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/.obsidian/plugins/agent-client/"
  '';
}
