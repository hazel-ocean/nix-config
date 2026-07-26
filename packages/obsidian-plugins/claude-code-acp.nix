{
  lib,
  buildNpmPackage,
  src,
}:

buildNpmPackage {
  inherit src;
  pname = "claude-code-acp";
  version = "0.14.0";

  npmDepsHash = "sha256-Cq5eurS4BgP4h+ASXe+bJiyLzJ27H0S21Dsusw/c+gc=";
  npmBuildScript = "build";
  dontNpmPack = true; # Don't try to run npm pack

  meta = with lib; {
    description = "An ACP-compatible coding agent powered by the Claude Code SDK";
    homepage = "https://github.com/zed-industries/claude-code-acp";
    license = licenses.asl20;
    mainProgram = "claude-code-acp";
    platforms = platforms.all;
  };
}
