# TODO

## ~~MCP Servers Sub-Flake: Flexible nixpkgs Follows~~ ✅ DONE

### Problem (Resolved)

The `mcp-servers` sub-flake originally had a `nixpkgs` input that required `follows` configuration, which would have been different for each host (darwin vs linux, stable vs unstable).

### Solution Implemented: Option 3

Removed the `nixpkgs` input entirely from the sub-flake. The sub-flake now only:

1. Declares source inputs for MCP server repos (tracked in its own `flake.lock`)
2. Exports an overlay that works with any nixpkgs version

```nix
# packages/mcp-servers/flake.nix
{
  inputs = {
    # No nixpkgs - only MCP server sources
    mcp-server-asana-src = {
      url = "github:roychri/mcp-server-asana/v1.6.0";
      flake = false;
    };
    # ...
  };

  outputs = { mcp-server-asana-src, ... }: {
    # Overlay uses final.callPackage - works with ANY nixpkgs
    overlays.default = final: prev: {
      mcp-asana = final.callPackage ./asana.nix { src = mcp-server-asana-src; };
      # ...
    };
  };
}
```

```nix
# Root flake.nix - no follows needed
mcp-servers.url = "path:./packages/mcp-servers";
```

### Benefits

- Sub-flake's `flake.lock` only tracks MCP sources—not nixpkgs
- No `follows` needed—works with any host's nixpkgs automatically
- Cleaner separation: sources managed separately from nixpkgs versions
- Faster updates: `cd packages/mcp-servers && nix flake update` only updates MCP sources

### Trade-off

Can't do standalone builds in the sub-flake directory. Testing must go through the parent:

```bash
# Instead of: cd packages/mcp-servers && nix build .#mcp-asana
# Use: nix build .#darwinConfigurations.espeon.pkgs.mcp-asana
```

### Completed Action Items

- [x] Removed nixpkgs from sub-flake
- [x] Removed `follows` from root flake.nix
- [x] Sub-flake only exports overlay
- [x] Update `packages/mcp-servers/CLAUDE.md` with the final pattern
- [ ] Test on a non-unstable host (korriban or ghastly) to confirm
