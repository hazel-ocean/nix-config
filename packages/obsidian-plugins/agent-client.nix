{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  pname = "obsidian-agent-client";
  version = "0.7.5";

  src = fetchFromGitHub {
    owner = "RAIT-09";
    repo = "obsidian-agent-client";
    rev = "master";
    hash = "sha256-dp7vegEHJhF/GF6V0lVinn6NpoEZ/O2DRIhIP/fr5zU=";
  };

  npmDepsHash = "sha256-xIUVigOXLbN3g0FyKiOANt89U3aitbrq8dk1YiGLNQk=";

  npmBuildScript = "build";

  # Don't try to run npm pack
  dontNpmPack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp main.js $out/
    cp manifest.json $out/
    cp styles.css $out/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Bring AI agents into Obsidian via Agent Client Protocol (ACP), such as Claude Code, Codex and Gemini CLI";
    homepage = "https://github.com/RAIT-09/obsidian-agent-client";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}