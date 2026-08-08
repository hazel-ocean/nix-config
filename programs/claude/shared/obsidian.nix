# Obsidian MCP server + agent-client plugin symlink, parameterized by vault
# path. Import as `(import ./shared/obsidian.nix { vault = "..."; })` from a
# host's Claude config — used by both pigeon.nix (personal vault) and
# espeon.nix (OneSignal vault).
{ vault }:
{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    mcp-obsidian
    obsidian-agent-client
  ];

  programs.claude-code.mcpServers.obsidian = {
    type = "stdio";
    command = "${pkgs.mcp-obsidian}/bin/mcp-obsidian";
    args = [ vault ];
  };

  home.activation.obsidianAgentClientPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $VERBOSE_ARG \
      "${vault}.obsidian/plugins/agent-client"

    run ln -fsn $VERBOSE_ARG \
      ${pkgs.obsidian-agent-client}/* \
      "${vault}.obsidian/plugins/agent-client/"
  '';
}
