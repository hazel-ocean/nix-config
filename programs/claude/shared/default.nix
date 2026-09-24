# MCP servers + base tooling common to every host regardless of identity.
# Host-specific Claude config imports this directory (`./shared`) plus
# whichever optional shared/<component>.nix pieces it needs on top.
{ pkgs, ... }:
{
  imports = [
    ./things.nix
    ./github.nix
    ./wispr-flow.nix
  ];

  home.packages = with pkgs; [
    claude-agent-acp
    prettier
  ];
}
