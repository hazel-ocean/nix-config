{
  lib,
  buildNpmPackage,
  src,
}:

buildNpmPackage {
  pname = "mcp-obsidian";
  version = src.shortRev;

  inherit src;

  npmDepsHash = "sha256-gDcG8axrutOv4kLDrHtUdO7oh9YmGhrKErFtN5ZUu1k=";

  npmBuildScript = "build";

  meta = with lib; {
    description = "A universal AI bridge for Obsidian vaults using the Model Context Protocol";
    homepage = "https://github.com/bitbonsai/mcp-obsidian";
    license = licenses.mit;
    mainProgram = "mcp-obsidian";
  };
}
