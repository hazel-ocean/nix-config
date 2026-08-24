# Home-manager side of the niri session. Actual niri config lives in
# ./niri-config.kdl, symlinked in (not store-built) so edits hot-reload.
{ config, lib, ... }:
{
  wayland.windowManager.niri = {
    enable = true;
  };

  home.activation.niriConfigSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $VERBOSE_ARG ~/.config/niri
    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/host/korriban/niri-config.kdl \
      ~/.config/niri/config.kdl
  '';

  # systemd.enable left off; niri-config.kdl spawns it directly instead.
  programs.noctalia = {
    enable = true;

    settings = {
      bar = {
        density = "compact";
        position = "right";
        showCapsule = false;
        widgets = {
          left = [
            { id = "ControlCenter"; useDistroLogo = true; }
            { id = "Bluetooth"; }
          ];
          center = [
            { hideUnoccupied = false; id = "Workspace"; labelMode = "none"; }
          ];
          right = [
            { alwaysShowPercentage = false; id = "Battery"; warningThreshold = 30; }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      colorSchemes.predefinedScheme = "Monochrome";
      wallpaper = {
        directory = "${config.home.homeDirectory}/.local/share/wallpapers";
        automation.recursive = true;
      };
    };
  };
}
