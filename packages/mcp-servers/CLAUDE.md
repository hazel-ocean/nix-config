# MCP Servers - Project Guidelines

This document provides context and conventions for Claude Code when working on MCP server packages.

## Naming Conventions

All MCP server packages MUST follow this naming pattern:

| Component        | Convention                 | Example                |
| ---------------- | -------------------------- | ---------------------- |
| Nix package name | `mcp-<service>`            | `mcp-asana`            |
| Binary name      | `mcp-<service>`            | `mcp-asana`            |
| Nix file name    | `<service>.nix`            | `asana.nix`            |
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

## Secrets Management

For MCP servers requiring API tokens or credentials:

1. Store tokens in `~/.config/mcp-<service>/access-token`
2. Set directory permissions to `700` (owner only)
3. Set file permissions to `600` (owner read/write only)
4. Use a shell wrapper to read the token at startup:

```nix
command = "/bin/sh";
args = [
  "-c"
  "export API_TOKEN=$(cat ~/.config/mcp-<service>/access-token) && exec ${pkgs.mcp-<service>}/bin/mcp-<service>"
];
```

## Build Patterns

### TypeScript/npm packages

Use `buildNpmPackage`:

```nix
buildNpmPackage rec {
  pname = "mcp-<service>";
  version = "x.y.z";

  src = fetchFromGitHub { ... };
  npmDepsHash = "sha256-...";
  npmBuildScript = "build";

  meta = with lib; {
    mainProgram = "mcp-<service>";
  };
}
```

### Python packages

Use `stdenv.mkDerivation` with `uv`:

```nix
stdenv.mkDerivation rec {
  pname = "mcp-<service>";
  version = "x.y.z";

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
}
```

## Adding a New MCP Server

1. Create `<service>.nix` using the appropriate build pattern
2. Add to `default.nix`:
   ```nix
   mcp-<service> = pkgs.callPackage ./<service>.nix { };
   ```
3. Add to host's `home-configuration.nix`:
   - Add package to `home.packages`
   - Add MCP server config to `programs.claude-code.mcpServers`
4. Update `README.md` with:
   - Entry in the "Available Servers" table
   - Server-specific setup instructions
5. Run `just apply` to rebuild

## Getting Hashes

When creating a new package:

1. Use `lib.fakeHash` for both `hash` and `npmDepsHash`
2. Build with `nix-build -E 'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./<service>.nix {}'`
3. Copy the correct hash from the error message
4. Repeat for the second hash

## Testing

Verify MCP server connectivity:

```bash
claude mcp list
```

All servers should show `✓ Connected`.

## File Structure

```
packages/mcp-servers/
├── CLAUDE.md        # This file - conventions and guidelines
├── README.md        # User-facing documentation
├── default.nix      # Package exports
├── asana.nix        # Individual server packages
├── obsidian.nix
└── things.nix
```
