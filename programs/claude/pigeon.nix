# Pigeon-specific Claude config: personal (non-OneSignal) Obsidian vault and
# the Craft MCP server.
{ config, ... }:
{
  imports = [
    ./shared
    ./shared/craft.nix
    (import ./shared/obsidian.nix { vault = "${config.home.homeDirectory}/Obsidian/Personal/"; })
  ];
}
