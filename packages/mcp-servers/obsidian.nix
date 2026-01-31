{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  pname = "mcp-obsidian";
  version = "0.7.4";

  src = fetchFromGitHub {
    owner = "bitbonsai";
    repo = "mcp-obsidian";
    rev = "main";
    hash = "sha256-yoRsDD+RkuyqNCakz/GZsLEP/1b9OM7/4XwyByYtPNU=";
  };

  npmDepsHash = "sha256-gDcG8axrutOv4kLDrHtUdO7oh9YmGhrKErFtN5ZUu1k=";

  npmBuildScript = "build";

  meta = with lib; {
    description = "A universal AI bridge for Obsidian vaults using the Model Context Protocol";
    homepage = "https://github.com/bitbonsai/mcp-obsidian";
    license = licenses.mit;
    mainProgram = "mcp-obsidian";
  };
}
