{ pkgs, ... }:
{
  home.packages = [ pkgs.mcp-things ];

  programs.claude-code.mcpServers.things = {
    type = "stdio";
    command = "${pkgs.mcp-things}/bin/mcp-things";
    args = [ ];
  };
}
