{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage {
  pname = "claude-code-acp";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "claude-code-acp";
    rev = "v0.14.0";
    hash = "sha256-6z0929OquI1s6EtQFjxel1p5dF/ep2hnVGLgKjudj88=";
  };

  npmDepsHash = "sha256-6DS1e9KxM+E6dj49xucxwXJnXbw2ILLe3fNLQyDpt0w=";

  npmBuildScript = "build";

  # Don't try to run npm pack
  dontNpmPack = true;

  meta = with lib; {
    description = "An ACP-compatible coding agent powered by the Claude Code SDK";
    homepage = "https://github.com/zed-industries/claude-code-acp";
    license = licenses.asl20;
    mainProgram = "claude-code-acp";
    platforms = platforms.all;
  };
}