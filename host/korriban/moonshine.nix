# Moonshine game streaming server, its control panel and browser streaming.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Steam is single-instance per user: if a desktop Steam is already running
  # when moonshine launches its own, steam:// actions get forwarded to that
  # existing instance instead of running in moonshine's session, and only the
  # first action (e.g. opening Big Picture) reliably lands. Upstream has no
  # fix; this is the workaround from its TIPS.md, per
  # https://github.com/hgaiser/moonshine/issues/134
  steamShutdownPreCommand = [
    "${pkgs.bash}/bin/bash"
    "-c"
    ''
      if pgrep -x steam >/dev/null; then
        ${pkgs.steam}/bin/steam -shutdown &>/dev/null
        for i in $(seq 1 30); do
          pgrep -x steam >/dev/null || break
          sleep 1
        done
      fi
    ''
  ];
in
{
  imports = [ inputs.moonshine.nixosModules.default ];

  services.moonshine = {
    enable = true;
    user = "hazel";
    uid = 1000; # users.users.hazel has no fixed uid declared; `id -u hazel`
    openFirewall = true; # LAN/tailscale-facing only, per the module's own warning

    settings = {
      name = config.networking.hostName;
      application = [
        {
          title = "Steam";
          command = [
            "${pkgs.steam}/bin/steam"
            "steam://open/bigpicture"
          ];
          steam_integration = true;
          pre_command = [ steamShutdownPreCommand ];
        }
      ];
      # The Host check accepts only IPs, localhost, <hostname> and <hostname>.local.
      ui.allowed_hosts = [ "${config.networking.hostName}.tail6b27c3.ts.net" ];
      # The control panel has no password: anyone in these ranges can pair
      # and stream. Its settings edits fail, because the config is in the store.
      ui.allowed_networks = [
        "127.0.0.1/32"
        "::1/128"
        "192.168.4.0/22"
        "100.64.0.0/10"
      ];
    };
  };

  # Control panel page (TCP) and browser stream (UDP). openFirewall omits it.
  networking.firewall.allowedTCPPorts = [ 47990 ];
  networking.firewall.allowedUDPPorts = [ 47990 ];

  users.users.hazel.extraGroups = [
    # hardware.uinput.enable's 99-local.rules overrides moonshine's GROUP="input";
    # moonshine streams are headless, so the uaccess ACL is not there to fall back on.
    "uinput"
    # Lets moonshine inhibit sleep during a stream.
    "moonshine"
  ];

  # Environment only: any mount option makes the user manager wrap the
  # session in a user namespace, where setuid binaries such as sudo fail.
  systemd.user.services.moonshine-session = {
    overrideStrategy = "asDropin"; # the unit itself is transient, made by moonshine
    # mkForce also keeps the generator from clobbering the session PATH.
    environment = lib.mkForce {
      GTK_THEME = "Adwaita:dark";
    };
  };
}
