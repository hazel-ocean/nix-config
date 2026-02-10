# MCP Servers - Project Guidelines

This document provides context and conventions for Claude Code when working on MCP server packages.

## Architecture

MCP servers are managed as a **sub-flake** at `packages/mcp-servers/flake.nix` that:

1. Declares source inputs for each MCP server repository
2. Exports an overlay (no `packages` output, no `nixpkgs` dependency)
3. Maintains its own `flake.lock` tracking only MCP server sources

This design allows the overlay to work with **any nixpkgs version**—the consuming flake (root `flake.nix`) provides nixpkgs, and the overlay uses `final.callPackage` which inherits from that.

```
packages/mcp-servers/
├── flake.nix        # Sub-flake: declares sources, exports overlay
├── flake.lock       # Tracks MCP server source versions only
├── CLAUDE.md        # This file
├── README.md        # User-facing documentation
├── default.nix      # Deprecated - see flake.nix
├── asana.nix        # Package definitions (receive `src` as parameter)
├── obsidian.nix
└── things.nix
```

## Naming Conventions

All MCP server packages MUST follow this naming pattern:

| Component        | Convention                 | Example                |
| ---------------- | -------------------------- | ---------------------- |
| Nix package name | `mcp-<service>`            | `mcp-asana`            |
| Binary name      | `mcp-<service>`            | `mcp-asana`            |
| Nix file name    | `<service>.nix`            | `asana.nix`            |
| Flake input name | `mcp-<service>-src`        | `mcp-server-asana-src` |
| Config directory | `~/.config/mcp-<service>/` | `~/.config/mcp-asana/` |

If the upstream package produces a differently-named binary (e.g., `mcp-server-asana`), create a symlink in `postInstall`:

```nix
postInstall = ''
  ln -s $out/bin/mcp-server-asana $out/bin/mcp-asana
'';
```

And set `mainProgram` to the consistent name:

```nix
meta = with lib; {
  mainProgram = "mcp-asana";
};
```

## Adding a New MCP Server

### 1. Add source input to `flake.nix`

```nix
inputs = {
  # ... existing inputs ...

  mcp-newservice-src = {
    url = "github:owner/repo/v1.0.0";  # Pin to tag or branch
    flake = false;  # Fetch source only, not a flake
  };
};
```

### 2. Add to overlay in `flake.nix`

```nix
outputs = { mcp-newservice-src, ... }: {
  overlays.default = final: prev: {
    # ... existing packages ...
    mcp-newservice = final.callPackage ./newservice.nix { src = mcp-newservice-src; };
  };
};
```

### 3. Create the package file

```nix
# newservice.nix
{
  lib,
  buildNpmPackage,  # or stdenv.mkDerivation for Python
  src,
}:

buildNpmPackage {
  pname = "mcp-newservice";
  version = src.shortRev or "unknown";

  inherit src;

  npmDepsHash = lib.fakeHash;  # Will be filled in after first build attempt
  npmBuildScript = "build";

  meta = with lib; {
    description = "MCP Server for NewService";
    homepage = "https://github.com/owner/repo";
    license = licenses.mit;
    mainProgram = "mcp-newservice";
  };
}
```

### 4. Update the sub-flake lock

```bash
cd packages/mcp-servers
nix flake update
```

### 5. Build to get the correct hash

```bash
# From repo root
just apply  # Will fail with correct hash
```

Copy the hash from the error message and update `npmDepsHash` in the package file.

### 6. Add to host configuration

In `host/<hostname>/home-configuration.nix`:

```nix
home.packages = with pkgs; [
  mcp-newservice
];

programs.claude-code.mcpServers = {
  newservice = {
    type = "stdio";
    command = "${pkgs.mcp-newservice}/bin/mcp-newservice";
    args = [ ];
  };
};
```

### 7. Update documentation

- Add entry to `README.md` "Available Servers" table
- Add server-specific setup instructions to `README.md`

## Secrets Management

For MCP servers requiring API tokens or credentials:

1. Store tokens in `~/.config/mcp-<service>/access-token`
2. Set directory permissions to `700` (owner only)
3. Set file permissions to `600` (owner read/write only)
4. Use a shell wrapper to read the token at startup:

```nix
programs.claude-code.mcpServers = {
  servicename = {
    type = "stdio";
    command = "/bin/sh";
    args = [
      "-c"
      "export API_TOKEN=$(cat ~/.config/mcp-<service>/access-token) && exec ${pkgs.mcp-<service>}/bin/mcp-<service>"
    ];
  };
};
```

## Updating MCP Server Versions

To update all MCP server sources:

```bash
cd packages/mcp-servers
nix flake update
```

To update a specific source:

```bash
cd packages/mcp-servers
nix flake update mcp-server-asana-src
```

After updating, rebuild and fix any hash mismatches:

```bash
just apply
# If npmDepsHash changed, update it in the package file and rebuild
```

## Build Patterns

### TypeScript/npm packages

```nix
{ lib, buildNpmPackage, src }:

buildNpmPackage {
  pname = "mcp-<service>";
  version = src.shortRev or "unknown";

  inherit src;

  npmDepsHash = "sha256-...";
  npmBuildScript = "build";

  meta = with lib; {
    mainProgram = "mcp-<service>";
  };
}
```

### Python packages (using uv)

```nix
{ lib, stdenv, src, makeWrapper, uv, python312 }:

stdenv.mkDerivation {
  pname = "mcp-<service>";
  version = src.shortRev or "unknown";

  inherit src;

  nativeBuildInputs = [ makeWrapper uv python312 ];

  buildPhase = ''
    export HOME=$TMPDIR
    export UV_PYTHON=${python312}/bin/python
    ${uv}/bin/uv sync --frozen
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/mcp-<service>
    cp -r .venv *.py $out/share/mcp-<service>/
    makeWrapper $out/share/mcp-<service>/.venv/bin/python $out/bin/mcp-<service> \
      --add-flags "$out/share/mcp-<service>/server.py"
  '';

  meta = with lib; {
    mainProgram = "mcp-<service>";
    platforms = platforms.darwin;  # if macOS-only
  };
}
```

### Go packages

```nix
{ lib, buildGoModule, src }:

buildGoModule {
  pname = "mcp-<service>";
  version = src.shortRev or "unknown";

  inherit src;

  vendorHash = "sha256-...";

  subPackages = [ "cmd/<upstream-binary-name>" ];

  postInstall = ''
    mv $out/bin/<upstream-binary-name> $out/bin/mcp-<service>
  '';

  meta = with lib; {
    mainProgram = "mcp-<service>";
  };
}
```

## Testing

Verify MCP server connectivity:

```bash
claude mcp list
```

All servers should show `✓ Connected`.

Note: Standalone builds (`nix build .#mcp-asana` from within the sub-flake) are not supported since the sub-flake doesn't have a nixpkgs input. Test through the parent flake instead.

## Why No nixpkgs in the Sub-Flake?

The sub-flake intentionally omits a `nixpkgs` input because:

1. **Universal compatibility**: The overlay works with any nixpkgs version the consuming host uses
2. **Cleaner lock file**: `packages/mcp-servers/flake.lock` only tracks MCP sources
3. **No `follows` needed**: Root flake doesn't need to specify `inputs.nixpkgs.follows`
4. **Faster updates**: Updating MCP sources doesn't touch nixpkgs

The trade-off is no standalone `nix build` in the sub-flake directory, but this is acceptable since testing goes through the main configuration anyway.
