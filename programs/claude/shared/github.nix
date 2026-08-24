{ pkgs, ... }:
{
  home.packages = [ pkgs.github-mcp-server ];

  # Official GitHub MCP server, self-hosted over stdio. The token comes from
  # the gh CLI because that one is authorized against the OneSignal org; a
  # PAT without org resource access sees public repos only, which reads as
  # an empty result set rather than an error. --read-only is the write
  # guard: the server refuses every mutating tool whatever the token allows.
  programs.claude-code.mcpServers.github = {
    type = "stdio";
    command = "/bin/sh";
    args = [
      "-c"
      "export GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.gh}/bin/gh auth token) && exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio --read-only"
    ];
  };
}
