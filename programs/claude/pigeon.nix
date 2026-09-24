# Pigeon-specific Claude config: personal Obsidian vault and Craft.
{ config, ... }:
{
  imports = [
    ./shared
    ./shared/craft.nix
  ];

  local.claude.obsidianVault = "${config.home.homeDirectory}/Obsidian/Personal/";
}
