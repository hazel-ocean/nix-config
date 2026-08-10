# MCP servers + base tooling common to every host regardless of identity.
# Host-specific Claude config (pigeon.nix, espeon.nix, ...) imports this
# directory (`./shared`) plus whichever optional shared/<component>.nix
# pieces (obsidian.nix, slack.nix) and host-only bits it needs on top.
{ pkgs, ... }:
{
  imports = [
    ./things.nix
    ./github.nix
    ./craft.nix
    ./wispr-flow.nix
  ];

  home.packages = with pkgs; [
    claude-agent-acp
    prettier
  ];
}
