{
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

  zoxideInit = runCommandLocal "zoxide-init-nushell" { buildInputs = [ zoxide ]; } ''
    mkdir $out
    zoxide init nushell > $out/init.nu
  '';

  # Orthogonal, self-contained Nushell overlays (each an `overlays/<name>/mod.nu`
  # module). `enable` decides whether an overlay is auto-loaded into every
  # session via an injected `overlay use` line below; disabled ones remain
  # available to `overlay use` on demand. `prefix` namespaces the overlay's
  # commands (e.g. `time-machine backup`).
  overlays = [
    { name = "time-machine"; src = ./overlays/time-machine; enable = isDarwin; prefix = true; }
    { name = "admin"; src = ./overlays/admin; enable = isDarwin; prefix = true; }
    # `job` is intentionally omitted — load on demand with `overlay use`.
  ];

  overlayLoads = lib.concatMapStringsSep "\n" (
    o: "overlay use ${lib.optionalString o.prefix "--prefix "}${o.src}/mod.nu as ${o.name}"
  ) (lib.filter (o: o.enable) overlays);

  config = lib.concatLines [
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
    configFile.text = config;
    extraEnv = lib.optionalString isDarwin brewEnv;
    plugins = [ polars ];
  };

  home.packages = [ nufmt ];
}
