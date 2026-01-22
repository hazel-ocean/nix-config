{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  uv,
  python312,
}:

stdenv.mkDerivation rec {
  pname = "things-mcp";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "hald";
    repo = "things-mcp";
    rev = "v${version}";
    hash = "sha256-SLvyDOFWuXBKzVk/rhIuvudM+1iFQdc0W4YhhgISRWc=";
  };

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
    mkdir -p $out/share/things-mcp

    # Copy source files
    cp -r *.py pyproject.toml uv.lock $out/share/things-mcp/

    # Copy the built virtual environment
    cp -r .venv $out/share/things-mcp/.venv

    # Create wrapper that uses the pre-built virtualenv
    mkdir -p $out/bin
    makeWrapper $out/share/things-mcp/.venv/bin/python $out/bin/things-mcp \
      --add-flags "$out/share/things-mcp/things_server.py"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Things.app MCP Server - interact with Things 3 via Claude";
    homepage = "https://github.com/hald/things-mcp";
    license = licenses.mit;
    platforms = platforms.darwin; # Things is macOS only
    mainProgram = "things-mcp";
  };
}
