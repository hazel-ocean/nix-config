{
  config,
  lib,
  pkgs,
  ...
}:
let
  settings = import ./settings.nix { stdenv = pkgs.stdenv; };

  vendoredSkills = lib.genAttrs (builtins.attrNames (builtins.readDir ./.agents/skills)) (
    name: ./.agents/skills + "/${name}"
  );

  # The packaged 1.6.2 tree carries no SKILL.md, so the skill comes from a main
  # rev of the same repo. Drop the rev once nixpkgs ships a release with it.
  gh-pr-review-skill =
    let
      src = pkgs.fetchFromGitHub {
        inherit (pkgs.gh-pr-review.src) owner repo;
        rev = "d2c86f61c5709c567e8487ba82f04112a456c221";
        hash = "sha256-1TINm9rMckjAG7nyBR5AqSqWpzVp6ey7c1wm98s488w=";
      };
    in
    pkgs.runCommandLocal "gh-pr-review-skill" { } ''
      mkdir -p $out
      cp ${src}/SKILL.md $out/SKILL.md
      cp -R ${src}/docs $out/docs
    '';
in
{
  programs.claude-code = {
    context = ./CLAUDE.md;
    skills = vendoredSkills // {
      gh-pr-review = gh-pr-review-skill;
    };
    commands.nu = ./commands/nu.md;
  };

  # Pretty-printed, because Claude Code's own writers (/effort, /config, /model,
  # /permissions) rewrite this file in place.
  home.file.".claude/settings.json" = {
    source = (pkgs.formats.json { }).generate "claude-settings.json" settings;
  };
}
