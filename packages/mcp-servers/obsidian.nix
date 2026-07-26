{
  lib,
  buildNpmPackage,
  src,
}:

buildNpmPackage {
  pname = "mcp-obsidian";
  version = src.shortRev;

  inherit src;

  npmDepsHash = "sha256-JiQXpqyqoF6X+8QXob4hWzbLwiN4GnuFAeEM9xZGu0o=";

  npmBuildScript = "build";

  # Upstream renamed the package to @bitbonsai/mcpvault (bin: mcpvault).
  # Rename for naming consistency with other MCP servers.
  postInstall = ''
    mv $out/bin/mcpvault $out/bin/mcp-obsidian
  '';

  meta = with lib; {
    description = "A universal AI bridge for Obsidian vaults using the Model Context Protocol";
    homepage = "https://github.com/bitbonsai/mcp-obsidian";
    license = licenses.mit;
    mainProgram = "mcp-obsidian";
  };
}
