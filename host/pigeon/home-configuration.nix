{ lib, pkgs, ... }:
{

  home.packages = with pkgs; [
    mcp-things
    mcp-obsidian
    obsidian-agent-client
    claude-code-acp
    # mcp-nixos # TODO: use flake from github repo
    github-mcp-server
    prettier
  ];


  programs.claude-code = {
    enable = true;
    mcpServers = {
      # obsidian = {
      #   type = "stdio";
      #   command = "${pkgs.mcp-obsidian}/bin/mcp-obsidian";
      #   args = [ "/path/to/vault" ];
      # };
      things = {
        type = "stdio";
        command = "${pkgs.mcp-things}/bin/mcp-things";
        args = [ ];
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

  programs.direnv.mise.enable = true;
  programs.mise = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  home.activation.makeSymbolicLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/host/pigeon/scripts \
      ~/.local/scripts

    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/programs/ghostty/config \
      ~/.config/ghostty
  '';
}
