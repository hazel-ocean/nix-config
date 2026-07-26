{
  lib,
  stdenv,
  src,
  makeWrapper,
  uv,
  python312,
}:

stdenv.mkDerivation {
  pname = "mcp-things";
  version = src.shortRev;

  inherit src;

  nativeBuildInputs = [
    makeWrapper
    uv
    python312
  ];

  buildPhase = ''
    runHook preBuild

    # Use uv to create a virtual environment and install dependencies
    # This happens in the build directory which is writable
    export HOME=$TMPDIR
    export UV_CACHE_DIR=$TMPDIR/.uv-cache
    export UV_PYTHON=${python312}/bin/python
    ${uv}/bin/uv sync --frozen

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install the application and its virtualenv
    mkdir -p $out/share/mcp-things

    # Copy the package source (upstream moved to a src/ layout with the
    # things_mcp package and a things_mcp.server:main entry point)
    cp -r src pyproject.toml uv.lock $out/share/mcp-things/

    # Copy the built virtual environment
    cp -r .venv $out/share/mcp-things/.venv

    # Wrapper runs the package entry point via the pre-built virtualenv.
    # PYTHONPATH points at our copied src so imports resolve regardless of how
    # uv installed the project into the venv.
    mkdir -p $out/bin
    makeWrapper $out/share/mcp-things/.venv/bin/python $out/bin/mcp-things \
      --add-flags "-m things_mcp.server" \
      --prefix PYTHONPATH : $out/share/mcp-things/src

    runHook postInstall
  '';

  meta = with lib; {
    description = "Things.app MCP Server - interact with Things 3 via Claude";
    homepage = "https://github.com/hald/things-mcp";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "mcp-things";
  };
}
