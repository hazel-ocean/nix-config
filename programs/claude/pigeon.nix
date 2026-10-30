# Pigeon-specific Claude config: personal Obsidian vault, the personal project
# skills, and Craft.
{ config, ... }:
{
  imports = [
    ./shared
    ./shared/craft.nix
    ./shared/personal-projects
  ];

  local.claude.obsidianVault = "${config.home.homeDirectory}/Obsidian/Personal/";
}
