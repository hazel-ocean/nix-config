{ pkgs }:
{
  obsidian-agent-client = pkgs.callPackage ./agent-client.nix { };
  claude-code-acp = pkgs.callPackage ./claude-code-acp.nix { };
}