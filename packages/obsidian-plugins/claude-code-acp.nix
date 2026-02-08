{
  lib,
  buildNpmPackage,
  src,
}:

buildNpmPackage {
  inherit src;
  pname = "claude-code-acp";
  version = "0.14.0";

  npmDepsHash = "sha256-CNzG/TS9I06s9LTzu10PITUEFgyiTt4Qp2wa53+Lj5c=";
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
