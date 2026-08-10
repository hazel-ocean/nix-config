{
  lib,
  src,
  callPackage,
  runCommand,
  makeWrapper,
  python312,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}:

let
  python = python312;

  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };

  # Prefer prebuilt wheels; uv2nix fetches each as its own fixed-output
  # derivation, so the build is hermetic and needs no network.
  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    (callPackage pyproject-nix.build.packages {
      inherit python;
    }).overrideScope
      (lib.composeManyExtensions [
        pyproject-build-systems.overlays.default
        overlay
      ]);

  venv = pythonSet.mkVirtualEnv "mcp-things-env" workspace.deps.default;
in
# Expose the upstream `things-mcp` console script under our `mcp-things`
# naming convention.
runCommand "mcp-things-${src.shortRev}"
  {
    nativeBuildInputs = [ makeWrapper ];
    passthru = { inherit venv; };
    meta = {
      description = "Things.app MCP Server - interact with Things 3 via Claude";
      homepage = "https://github.com/hald/things-mcp";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
      mainProgram = "mcp-things";
    };
  }
  ''
    mkdir -p $out/bin
    makeWrapper ${venv}/bin/things-mcp $out/bin/mcp-things
  ''
