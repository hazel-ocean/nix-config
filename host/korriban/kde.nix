# Plasma 6 as the physical session. Niri streams over it, see ./niri.nix.
{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;
  services.displayManager.plasma-login-manager.enable = true;

  environment.systemPackages = with pkgs.kdePackages; [
    discover
    kcalc
    ksystemlog
    sddm-kcm
    isoimagewriter
    partitionmanager
  ];
}
