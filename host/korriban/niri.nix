# Niri both as a login session and as a moonshine-streamed app.
# Plasma is the default session; niri is selectable at the greeter.
{ config, pkgs, ... }:
let
  # GTK reads its point size from gtk-xft-dpi, which KDE writes from Plasma's
  # 2.35 display scale. That suits the 4K panel, not the stream, so ghostty
  # takes an extra config file here and nowhere else.
  streamedGhostty = pkgs.writeShellScriptBin "ghostty" ''
    exec ${pkgs.ghostty}/bin/ghostty --config-file="$HOME/.config/ghostty.moonshine" "$@"
  '';

  streamedNiri = pkgs.writeShellScriptBin "moonshine-niri" ''
    export PATH=${streamedGhostty}/bin:$PATH
    exec ${config.programs.niri.package}/bin/niri
  '';
in
{
  programs.niri.enable = true;

  # System-wide, not home.packages: niri runs under moonshine's service PATH.
  environment.systemPackages = [
    pkgs.xwayland-satellite
    pkgs.gnome-font-viewer
  ];

  # programs.niri mkDefaults this to "niri", conflicting with plasma6's own.
  services.displayManager.defaultSession = "plasma";

  services.moonshine.settings.application = [
    {
      title = "Niri Desktop";
      # niri-session forces --session (DRM backend); bare niri nests instead.
      command = [ "${streamedNiri}/bin/moonshine-niri" ];
      stdout = "journal";
      stderr = "journal";
    }
  ];
}
