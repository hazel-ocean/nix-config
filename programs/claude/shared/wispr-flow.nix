{ ... }:
{
  programs.claude-code.mcpServers.wispr-flow = {
    type = "http";
    url = "https://api.wisprflow.ai/connect/mcp";
  };
}
