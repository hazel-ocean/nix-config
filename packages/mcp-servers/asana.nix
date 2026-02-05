{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "mcp-server-asana";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "roychri";
    repo = "mcp-server-asana";
    rev = "v${version}";
    hash = "sha256-FD23+mVGcxQrFxBOZh8Oo2XNAFveGR8jEeZS2a6mb9E=";
  };

  npmDepsHash = "sha256-Ir6V9JC1Z8r4sbhAfJ73+5f7HlfKbbzOhgwS9GYYO0w=";

  npmBuildScript = "build";

  # Create mcp-asana symlink for naming consistency with other MCP servers
  postInstall = ''
    ln -s $out/bin/mcp-server-asana $out/bin/mcp-asana
  '';

  meta = with lib; {
    description = "MCP Server for Asana - interact with Asana via Claude";
    homepage = "https://github.com/roychri/mcp-server-asana";
    license = licenses.mit;
    mainProgram = "mcp-asana";
  };
}