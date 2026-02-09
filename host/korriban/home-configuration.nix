{ lib, pkgs, ... }:
{

  # AirPlay receiver via shairport-sync (PipeWire backend, user service)
  xdg.configFile."shairport-sync/shairport-sync.conf".text = ''
    general = {
      name = "Korriban";
      output_backend = "pw";
      drift_tolerance_in_seconds = 0.002;
    };
    sessioncontrol = {
      allow_session_interruption = "yes";
      session_timeout = 20;
    };
  '';

  systemd.user.services.shairport-sync = {
    Unit = {
      Description = "Shairport Sync - AirPlay Audio Receiver";
      After = [ "pipewire.service" "pipewire-pulse.service" ];
      Requires = [ "pipewire.service" ];
    };
    Service = {
      ExecStart = "${pkgs.shairport-sync}/bin/shairport-sync --configfile=%h/.config/shairport-sync/shairport-sync.conf";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  programs.claude-code.enable = true;

  programs.direnv.mise.enable = true;
  programs.mise = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  home.activation.makeSymbolicLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/programs/ghostty/config \
      ~/.config/ghostty
  '';

}
