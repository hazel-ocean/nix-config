# Niri as a moonshine-streamed desktop. Plasma stays the physical session.
{ config, ... }:
{
  programs.niri.enable = true;

  # programs.niri mkDefaults this to "niri", conflicting with plasma6's own.
  services.displayManager.defaultSession = "plasma";

  services.moonshine.settings.application = [
    {
      title = "Niri Desktop";
      # niri-session forces --session (DRM backend); bare niri nests instead.
      command = [ "${config.programs.niri.package}/bin/niri" ];
      stdout = "journal";
      stderr = "journal";
    }
  ];
}
