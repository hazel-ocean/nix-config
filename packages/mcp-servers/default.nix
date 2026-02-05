# DEPRECATED: This file exists for backwards compatibility.
# MCP server packages are now managed by the sub-flake at ./flake.nix
#
# The flake manages source inputs via flake.lock, so versions are updated with:
#   cd packages/mcp-servers && nix flake update
#
# For new code, use the overlay from the flake:
#   mcp-servers.overlays.default

{ pkgs, sources ? { } }:

throw ''
  packages/mcp-servers/default.nix is deprecated.

  MCP servers are now provided via a sub-flake. Use mcp-servers.overlays.default
  in your flake.nix overlays instead of importing this file directly.

  See packages/mcp-servers/flake.nix for details.
''