{ config, pkgs, ... }:
let
  settings = import ./settings.nix { stdenv = pkgs.stdenv; };
in
{
  programs.claude-code = {
    context = ./memory.md;
    skills = ./.agents/skills;
    commands.nu = ./commands/nu.md;
  };

  home.packages = [ pkgs.beads ];

  # ~/.claude/settings.json is generated from settings.nix with platform-aware
  # conditionals (hooks only on Darwin). Runtime writers (/effort, /config,
  # /model, /permissions) can modify it directly; edits persist across rebuilds.
  home.file.".claude/settings.json" = {
    text = builtins.toJSON settings;
  };
}
