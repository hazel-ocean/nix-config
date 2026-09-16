# Software KVM. Peers are symmetric: every machine runs the same daemon and lists
# the others as clients in its own mutable config.toml, which the GUI and CLI
# write. Capture and emulation are per-direction, so neither end is a server.
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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # On darwin the menu bar app carries the daemon. Elsewhere it follows
    # graphical-session.target, started by niri-session and by Plasma. A nested
    # niri (moonshine) runs bare niri, so it never starts a second daemon.
    systemd.user.services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
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
