# Plasma 6 as the physical session. Niri streams over it, see ./niri.nix.
{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;
  services.displayManager.plasma-login-manager = {
    enable = true;
    # Overrides the stateful /etc/plasmalogin.conf the Login Screen KCM writes.
    settings.Autologin = {
      User = "";
      Session = "";
    };
  };

  environment.systemPackages = with pkgs.kdePackages; [
    discover
    kcalc
    ksystemlog
    sddm-kcm
    isoimagewriter
    partitionmanager
  ];
}
