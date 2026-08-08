{ pkgs, ... }:
{
  home.packages = [ pkgs.mcp-slack ];

  programs.claude-code.mcpServers.slack = {
    type = "stdio";
    command = "/bin/sh";
    args = [
      "-c"
      "export SLACK_MCP_XOXC_TOKEN=$(cat ~/.config/mcp-slack/xoxc-token) && export SLACK_MCP_XOXD_TOKEN=$(cat ~/.config/mcp-slack/xoxd-token) && exec ${pkgs.mcp-slack}/bin/mcp-slack"
    ];
  };
}
