# Software KVM: one daemon both captures and emulates, and the role is decided by
# the mutable config.toml that its GUI and CLI write.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.lan-mouse;
in
{
  options.programs.lan-mouse = {
    enable = lib.mkEnableOption "Lan Mouse software KVM";

    package = lib.mkPackageOption pkgs "lan-mouse" { };

    service.enable = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.hostPlatform.isLinux;
      description = ''
        Run the daemon unattended for the whole graphical session, so the host can
        be driven without anyone opening the app. Wants a machine that is a target.
        Linux only: darwin has no systemd, and the menu bar app carries the daemon
        there.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # graphical-session.target is started by niri-session and by Plasma. A nested
    # niri (moonshine) runs bare niri, so it never starts a second daemon.
    systemd.user.services = lib.mkIf cfg.service.enable {
      lan-mouse = {
        Unit = {
          Description = "Lan Mouse - software KVM";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe cfg.package} daemon";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
