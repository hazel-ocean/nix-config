final: prev:

let
  mcp-servers = import ../packages/mcp-servers { pkgs = prev; };
in
mcp-servers
