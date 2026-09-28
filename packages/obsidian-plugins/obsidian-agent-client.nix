{
  lib,
  buildNpmPackage,
  src,
}:

buildNpmPackage {
  inherit src;
  pname = "obsidian-agent-client";
  version = "0.13.0";

  npmDepsHash = "sha256-1yWfV6sMdYX+8isJVA57s/JGQWpN1v1XIUnMrThOh4s=";
  npmBuildScript = "build";
  dontNpmPack = true; # Don't try to run npm pack

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
