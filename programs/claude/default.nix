{ config, pkgs, ... }:
let
  settings = import ./settings.nix { stdenv = pkgs.stdenv; };
in
{
  programs.claude-code = {
    context = ./CLAUDE.md;
    skills = ./.agents/skills;
    commands.nu = ./commands/nu.md;
  };

  # Pretty-printed, because Claude Code's own writers (/effort, /config, /model,
  # /permissions) rewrite this file in place.
  home.file.".claude/settings.json" = {
    source = (pkgs.formats.json { }).generate "claude-settings.json" settings;
  };
}
