{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.shairport-sync;
in
{
  options.services.shairport-sync = {
    enable = lib.mkEnableOption "Shairport Sync AirPlay receiver";

    name = lib.mkOption {
      type = lib.types.str;
      default = config.home.username;
      description = "The name that appears in AirPlay device lists.";
    };

    package = lib.mkPackageOption pkgs "shairport-sync" { };

    driftTolerance = lib.mkOption {
      type = lib.types.number;
      default = 0.002;
      description = ''
        How much drift (in seconds) is tolerated before corrections are applied.
        Lower values keep sync tighter but may cause more frequent corrections.
        Default upstream is 0.002.
      '';
    };

    resyncThreshold = lib.mkOption {
      type = lib.types.number;
      default = 0.050;
      description = ''
        If the sync drift exceeds this value (in seconds), a full resync is triggered
        rather than gradual correction. Lower values resync sooner.
        Default upstream is 0.050.
      '';
    };

    bufferLength = lib.mkOption {
      type = lib.types.number;
      default = 0.350;
      description = ''
        Desired audio backend buffer length in seconds. Shorter buffers reduce latency
        but increase the chance of dropouts on slower networks.
        Default upstream is 0.350.
      '';
    };

    latencyOffset = lib.mkOption {
      type = lib.types.float;
      default = 0.0;
      description = ''
        Offset in seconds added to the audio backend latency. Use a negative value to
        play earlier (if the receiver lags behind the source device) or a positive value
        to play later. Adjust in small increments (e.g. 0.005) while playing on both
        source and receiver simultaneously until they sound aligned.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional settings to append to the shairport-sync configuration file.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."shairport-sync/shairport-sync.conf".text = ''
      general = {
        name = "${cfg.name}";
        output_backend = "alsa";
        drift_tolerance_in_seconds = ${toString cfg.driftTolerance};
        resync_threshold_in_seconds = ${toString cfg.resyncThreshold};
        audio_backend_buffer_desired_length_in_seconds = ${toString cfg.bufferLength};
        audio_backend_latency_offset_in_seconds = ${toString cfg.latencyOffset};
      };
      sessioncontrol = {
        allow_session_interruption = "yes";
        session_timeout = 60;
      };
      ${cfg.settings}
    '';

    systemd.user.services.shairport-sync = {
      Unit = {
        Description = "Shairport Sync - AirPlay Audio Receiver";
        After = [
          "network.target"
          "avahi-daemon.target"
          "pipewire.service"
          "pipewire-pulse.service"
        ];
        Requires = [ "pipewire.service" ];
      };
      Service = {
        ExecStart = "${lib.getExe cfg.package} --configfile=%h/.config/shairport-sync/shairport-sync.conf";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
