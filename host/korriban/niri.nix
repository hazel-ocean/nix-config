# Niri both as a login session and as a moonshine-streamed app.
# Plasma is the default session; niri is selectable at the greeter.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  programs.niri.enable = true;

  # Nested niri 26.04 shows its host cursor, which moonshine draws next to
  # niri's own. Upstream main hides it (803462c7), and no release has it yet.
  programs.niri.package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri;
  warnings = lib.optional (lib.versionOlder "26.04" pkgs.niri.version) ''
    nixpkgs has niri ${pkgs.niri.version}. If it includes niri 803462c7,
    remove the niri flake input and programs.niri.package from
    host/korriban/niri.nix.
  '';

  # System-wide, not home.packages: niri runs under moonshine's service PATH.
  environment.systemPackages = [
    pkgs.xwayland-satellite
    pkgs.gnome-font-viewer
    pkgs.gnome-themes-extra # Adwaita-dark for GTK3
  ];

  # programs.niri mkDefaults this to "niri", conflicting with plasma6's own.
  services.displayManager.defaultSession = "plasma";

  services.moonshine.settings.application = [
    {
      title = "Niri Desktop";
      # niri-session forces --session (DRM backend); bare niri nests instead.
      command = [ "${config.programs.niri.package}/bin/niri" ];
      # Plasma writes gtk-xft-dpi as 96 x its 2.35 scale, and GTK has no
      # portal here to override it, so fonts scale again on top of niri's.
      # Plasma rewrites the key at its next login.
      pre_command = [
        [
          "${pkgs.gnused}/bin/sed"
          "-i"
          "/^gtk-xft-dpi=/d"
          "/home/hazel/.config/gtk-3.0/settings.ini"
          "/home/hazel/.config/gtk-4.0/settings.ini"
        ]
      ];
      stdout = "journal";
      stderr = "journal";
    }
  ];
}
