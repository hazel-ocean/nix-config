# Pigeon-specific Claude config: personal (non-OneSignal) Obsidian vault.
{ config, ... }:
{
  imports = [
    ./shared
    (import ./shared/obsidian.nix { vault = "${config.home.homeDirectory}/Obsidian/Personal/"; })
  ];
}
