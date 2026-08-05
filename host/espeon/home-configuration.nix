{ lib, pkgs, ... }:
{
  imports = [
    ../../programs/claude
    ../../programs/claude/shared.nix
    ../../programs/claude/work.nix
  ];

  home.packages = with pkgs; [
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

  programs.claude-code.enable = true;

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
  '';

}
