# System-wide packages available to all users (including root).
# This is a NixOS / nix-darwin module -- not a Home Manager module.
# Import from host configuration.nix or from darwin-common.nix.
{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv) isLinux;
in
{
  environment.systemPackages =
    with pkgs;
    [
      # Core file & text utilities
      file
      eza
      fd
      ripgrep
      sd
      fzf
      bat
      jq
      yq-go
      wget
      rsync
      unzip
      zstd
      pv
      hexyl
      iconv

      # Disk & filesystem inspection
      dua
      duf
      dust

      # Process & system monitoring
      killall
      htop
      btop
      procs
      bottom
      bandwhich

      # Networking
      nmap
      inetutils

      # Device management
      smartmontools
    ]
    ++ lib.optionals isLinux [
      xsel
      xclip
      usbutils # lsusb and others
    ];
}
