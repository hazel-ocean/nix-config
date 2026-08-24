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

  # ~/.claude/settings.json is generated from settings.nix with platform-aware
  # conditionals (hooks only on Darwin). Runtime writers (/effort, /config,
  # /model, /permissions) can modify it directly; edits persist across rebuilds.
  # pkgs.formats.json pretty-prints it, so those edits stay diffable.
  home.file.".claude/settings.json" = {
    source = (pkgs.formats.json { }).generate "claude-settings.json" settings;
  };
}
