{ pkgs, ... }:
{
  home.packages = [ pkgs.github-mcp-server ];

  # Official GitHub MCP server, self-hosted over stdio. --read-only makes
  # the server refuse every mutating tool, so no write action can be
  # exposed regardless of the token's scopes (defense in depth: pair with
  # a read-only fine-grained PAT).
  programs.claude-code.mcpServers.github = {
    type = "stdio";
    command = "/bin/sh";
    args = [
      "-c"
      "export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ~/.config/mcp-github/access-token) && exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio --read-only"
    ];
  };
}
