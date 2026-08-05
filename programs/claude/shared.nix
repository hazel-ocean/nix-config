# MCP servers common to every host regardless of work/personal context.
# Import from any host alongside programs/claude (infra) and either
# work.nix or personal.nix (identity-specific servers).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    mcp-things
    github-mcp-server
    claude-code-acp
    prettier
  ];

  programs.claude-code = {
    mcpServers = {
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
      wispr-flow = {
        type = "http";
        url = "https://api.wisprflow.ai/connect/mcp";
      };
    };
  };
}
