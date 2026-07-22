{
  config,
  pkgs,
  lib,
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

  # Our pinned nixpkgs marks this plugin Linux-only, but the build has no
  # Linux-specific deps (nixos-unstable already lists darwin too), so widen
  # meta.platforms to allow it on macOS.
  desktop_notifications = pkgs.nushellPlugins.desktop_notifications.overrideAttrs (o: {
    meta = o.meta // {
      platforms = o.meta.platforms ++ lib.platforms.darwin;
    };
  });

  zoxideInit = runCommandLocal "zoxide-init-nushell" { buildInputs = [ zoxide ]; } ''
    mkdir $out
    zoxide init nushell > $out/init.nu
  '';

  # Orthogonal, self-contained Nushell overlays. `src` is a directory holding the
  # module file (`file`, default `mod.nu`); local overlays vendor it, tracked ones
  # point at a pinned store path (see AWESOME-NUSHELL.md). `enable` decides whether
  # an overlay is auto-loaded into every session via an injected `overlay use` line
  # below; disabled ones remain available to `overlay use` on demand. `prefix`
  # namespaces the overlay's commands (e.g. `time-machine backup`).
  overlays = [
    { name = "time-machine"; src = ./overlays/time-machine; enable = isDarwin; prefix = true; }
    { name = "admin"; src = ./overlays/admin; enable = isDarwin; prefix = true; }
    # pueue-backed background tasks, pinned from nushell/nu_scripts. Named `task` to
    # match upstream and avoid colliding with Nushell's native `job` builtin.
    # Auto-loaded exactly on hosts that run the daemon (`services.pueue.enable`, e.g.
    # host/espeon/home-configuration.nix); a no-op elsewhere since it needs `pueued`.
    { name = "task"; src = "${pkgs.nu-scripts}/modules/background_task"; file = "task.nu"; enable = config.services.pueue.enable; prefix = true; }
  ];

  overlayLoads = lib.concatMapStringsSep "\n" (
    o: "overlay use ${lib.optionalString o.prefix "--prefix "}${o.src}/${o.file or "mod.nu"} as ${o.name}"
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
    plugins = [
      polars
      desktop_notifications
    ];
  };

  home.packages = [ nufmt ];
}
