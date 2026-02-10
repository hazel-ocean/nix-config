{ lib, pkgs, ... }:
{
  imports = [
    ../../programs/claude
  ];

  home.packages = with pkgs; [
    mcp-things
    mcp-obsidian
    mcp-asana
    mcp-slack
    obsidian-agent-client
    claude-code-acp
    prettier
    # mcp-nixos # TODO: use flake from github repo
  ];

  home.file."Library/Application Support/Claude/claude_desktop_config.json".text = builtins.toJSON {
    mcpServers = {
      obsidian = {
        command = "${pkgs.mcp-obsidian}/bin/mcp-obsidian";
        args = [ "/Users/hazel/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/" ];
      };
      things = {
        command = "${pkgs.mcp-things}/bin/mcp-things";
        args = [ ];
      };
      asana = {
        command = "/bin/sh";
        args = [
          "-c"
          "export ASANA_ACCESS_TOKEN=$(cat ~/.config/mcp-asana/access-token) && exec ${pkgs.mcp-asana}/bin/mcp-asana"
        ];
      };
      slack = {
        command = "/bin/sh";
        args = [
          "-c"
          "export SLACK_MCP_XOXC_TOKEN=$(cat ~/.config/mcp-slack/xoxc-token) && export SLACK_MCP_XOXD_TOKEN=$(cat ~/.config/mcp-slack/xoxd-token) && exec ${pkgs.mcp-slack}/bin/mcp-slack"
        ];
      };
    };
  };

  programs.claude-code = {
    enable = true;
    mcpServers = {
      obsidian = {
        type = "stdio";
        command = "${pkgs.mcp-obsidian}/bin/mcp-obsidian";
        args = [ "/Users/hazel/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/" ];
      };
      things = {
        type = "stdio";
        command = "${pkgs.mcp-things}/bin/mcp-things";
        args = [ ];
      };
      asana = {
        type = "stdio";
        command = "/bin/sh";
        args = [
          "-c"
          "export ASANA_ACCESS_TOKEN=$(cat ~/.config/mcp-asana/access-token) && exec ${pkgs.mcp-asana}/bin/mcp-asana"
        ];
      };
      slack = {
        type = "stdio";
        command = "/bin/sh";
        args = [
          "-c"
          "export SLACK_MCP_XOXC_TOKEN=$(cat ~/.config/mcp-slack/xoxc-token) && export SLACK_MCP_XOXD_TOKEN=$(cat ~/.config/mcp-slack/xoxd-token) && exec ${pkgs.mcp-slack}/bin/mcp-slack"
        ];
      };
    };
  };

  programs.direnv.mise.enable = true;
  programs.mise = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  home.activation.makeSymbolicLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/host/espeon/scripts \
      ~/.local/scripts

    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/programs/ghostty/config \
      ~/.config/ghostty

    # Obsidian plugins
    run mkdir -p $VERBOSE_ARG \
      "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/.obsidian/plugins/agent-client"

    run ln -fsn $VERBOSE_ARG \
      ${pkgs.obsidian-agent-client}/* \
      "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/.obsidian/plugins/agent-client/"
  '';

}
