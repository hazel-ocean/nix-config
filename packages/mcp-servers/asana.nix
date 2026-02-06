{
  lib,
  buildNpmPackage,
  src,
}:

buildNpmPackage {
  pname = "mcp-asana";
  version = src.shortRev;

  inherit src;

  npmDepsHash = "sha256-Ir6V9JC1Z8r4sbhAfJ73+5f7HlfKbbzOhgwS9GYYO0w=";

  npmBuildScript = "build";

  # Rename for naming consistency with other MCP servers
  postInstall = ''
    mv $out/bin/mcp-server-asana $out/bin/mcp-asana
  '';

  meta = with lib; {
    description = "MCP Server for Asana - interact with Asana via Claude";
    homepage = "https://github.com/roychri/mcp-server-asana";
    license = licenses.mit;
    mainProgram = "mcp-asana";
  };
}
