# This overlay is now provided by the mcp-servers sub-flake.
# Import it in flake.nix as: mcp-servers.overlays.default
#
# This file exists for backwards compatibility and documentation.
# It takes the mcp-servers flake input and returns its overlay.

{ mcp-servers }:

mcp-servers.overlays.default