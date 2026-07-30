{ lib, pkgs, ... }:
{
  imports = [
    ../../programs/claude
  ];

  home.packages = with pkgs; [
    mcp-things
    mcp-obsidian
    mcp-slack
    github-mcp-server
    obsidian-agent-client
    claude-code-acp
    prettier
    # mcp-nixos # TODO: use flake from github repo
  ];

  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    force = true;
    text = builtins.toJSON {
      mcpServers = {
        obsidian = {
          command = lib.getExe pkgs.mcp-obsidian;
          args = [ "/Users/hazel/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/" ];
        };
        things = {
          command = "${pkgs.mcp-things}/bin/mcp-things";
          args = [ ];
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
      slack = {
        type = "stdio";
        command = "/bin/sh";
        args = [
          "-c"
          "export SLACK_MCP_XOXC_TOKEN=$(cat ~/.config/mcp-slack/xoxc-token) && export SLACK_MCP_XOXD_TOKEN=$(cat ~/.config/mcp-slack/xoxd-token) && exec ${pkgs.mcp-slack}/bin/mcp-slack"
        ];
      };
      # Official GitHub MCP server, self-hosted over stdio. --read-only makes
      # the server refuse every mutating tool, so no write action can be
      # exposed regardless of the token's scopes (defense in depth: pair with
      # a read-only fine-grained PAT).
      github = {
        type = "stdio";
        command = "/bin/sh";
        args = [
          "-c"
          "export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ~/.config/mcp-github/access-token) && exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio --read-only"
        ];
      };
      craft = {
        type = "http";
        url = "https://mcp.craft.do/my/mcp";
      };
    };
  };

  # pueued daemon (launchd agent) backing the nushell `task` overlay.
  services.pueue.enable = true;

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
