{
  lib,
  buildGoModule,
  src,
}:

buildGoModule {
  pname = "mcp-slack";
  version = src.shortRev;

  inherit src;

  vendorHash = "sha256-CEg7OHriwCD1XM4lOCNcIPiMXnHuerramWp4//9roOo=";

  subPackages = [ "cmd/slack-mcp-server" ];

  # Rename for naming consistency with other MCP servers
  postInstall = ''
    mv $out/bin/slack-mcp-server $out/bin/mcp-slack
  '';

  meta = with lib; {
    description = "MCP Server for Slack - interact with Slack workspaces via Claude";
    homepage = "https://github.com/korotovsky/slack-mcp-server";
    license = licenses.mit;
    mainProgram = "mcp-slack";
  };
}
