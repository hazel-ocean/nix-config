# Niri both as a login session and as a moonshine-streamed app.
# Plasma is the default session; niri is selectable at the greeter.
{ config, pkgs, ... }:
{
  programs.niri.enable = true;

  # System-wide, not home.packages: niri runs under moonshine's service PATH.
  environment.systemPackages = [ pkgs.xwayland-satellite ];

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
