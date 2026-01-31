{ pkgs }:

{
  mcp-things = pkgs.callPackage ./things.nix { };
  mcp-obsidian = pkgs.callPackage ./obsidian.nix { };
}
