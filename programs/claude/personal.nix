# Personal (non-OneSignal) Claude config: import this from personal hosts
# (currently pigeon). Mirrors work.nix's shape for the personal Obsidian vault.
{ lib, pkgs, config, ... }:
let
  vault = "${config.home.homeDirectory}/Obsidian/Personal/";
in
{
  home.packages = with pkgs; [
    mcp-obsidian
    obsidian-agent-client
  ];

  programs.claude-code = {
    mcpServers = {
      obsidian = {
        type = "stdio";
        command = "${pkgs.mcp-obsidian}/bin/mcp-obsidian";
        args = [ vault ];
      };
    };
  };

  # Obsidian plugin symlink for the personal vault.
  home.activation.personalObsidianPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $VERBOSE_ARG \
      "${vault}.obsidian/plugins/agent-client"

    run ln -fsn $VERBOSE_ARG \
      ${pkgs.obsidian-agent-client}/* \
      "${vault}.obsidian/plugins/agent-client/"
  '';
}
