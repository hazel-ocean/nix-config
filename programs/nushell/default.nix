{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (pkgs)
    runCommandLocal
    zoxide
    nushell
    nufmt
    ;
  inherit (pkgs.stdenv) isDarwin;

  inherit (pkgs.nushellPlugins) polars;

  zoxideInit = runCommandLocal "zoxide-init-nushell" { buildInputs = [ zoxide ]; } ''
    mkdir $out
    zoxide init nushell > $out/init.nu
  '';

  overlays = [
    {
      name = "admin";
      src = ./overlays/admin;
      enable = isDarwin;
      prefix = true;
    }
    {
      name = "task";
      src = "${pkgs.nu-scripts}/modules/background_task";
      file = "task.nu";
      enable = config.services.pueue.enable;
      prefix = true;
    }
    {
      name = "time-machine";
      src = ./overlays/time-machine;
      enable = isDarwin;
      prefix = true;
    }
    (
      let
        hostname = osConfig.networking.hostName;
        user = config.home.username;
      in
      {
        name = "workspace";
        src =
          if hostname == "espeon" then
            "/Users/${user}/OneSignal/workbench"
          # else if hostname == "pigeon" then
          #   "...todo"
          # else if hostname == "korriban" then
          #   "...todo"
          else
            throw ''
              Nushell overlay (workspace) is not configured for current host: ${hostname}
            '';

        enable = builtins.elem hostname [
          "espeon"
          "pigeon"
          "korriban"
        ];
        prefix = false;
      }
    )
  ];

  overlayLoads = lib.concatMapStringsSep "\n" (
    o:
    "overlay use ${lib.optionalString o.prefix "--prefix "}${o.src}/${o.file or "mod.nu"} as ${o.name}"
  ) (lib.filter (o: o.enable) overlays);

  configText = lib.concatLines [
    (builtins.readFile ./config.nu)
    overlayLoads
    "source ${zoxideInit}/init.nu"
  ];

  # Homebrew shellenv, re-expressed natively (Nushell can't `eval` the POSIX
  # output of `brew shellenv`). env.nu runs for every session before config.nu,
  # so PATH is ready early. No-op when brew is absent; idempotent via `uniq`.
  brewEnv = ''
    const brew_prefix = "/opt/homebrew"
    if ($brew_prefix | path exists) {
      $env.HOMEBREW_PREFIX = $brew_prefix
      $env.HOMEBREW_CELLAR = ($brew_prefix | path join Cellar)
      $env.HOMEBREW_REPOSITORY = $brew_prefix
      $env.PATH = ($env.PATH | prepend [($brew_prefix | path join bin) ($brew_prefix | path join sbin)] | uniq)
      $env.MANPATH = $"($brew_prefix)/share/man:($env.MANPATH? | default "")"
      $env.INFOPATH = $"($brew_prefix)/share/info:($env.INFOPATH? | default "")"
    }
  '';
in
{
  programs.nushell = {
    enable = true;
    package = nushell;
    configFile.text = configText;
    extraEnv = lib.optionalString isDarwin brewEnv;
    plugins = [ polars ];
  };

  # Multi-shell argument completer — nushell's external completer, covering the
  # long tail of CLIs (kubectl, terraform, docker, gh, git, …). Its integration
  # appends to programs.nushell.extraConfig, so it composes with configText above.
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  home.packages = [ nufmt ];
}
