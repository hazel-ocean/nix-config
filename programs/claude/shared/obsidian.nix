# Obsidian MCP server + agent-client plugin symlink. Inert until a host sets
# `local.claude.obsidianVault`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  vault = config.local.claude.obsidianVault;
in
lib.mkIf (vault != null) {
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
