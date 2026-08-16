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
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  inherit (pkgs.nushellPlugins) polars;

  zoxideInit = runCommandLocal "zoxide-init-nushell" { buildInputs = [ zoxide ]; } ''
    mkdir $out
    zoxide init nushell > $out/init.nu
  '';

  # Shared Starship config minus `[character]`, so Nushell can draw a vi-mode-aware
  # λ itself (config.nu). Wired via STARSHIP_CONFIG; other shells keep the λ.
  starshipNuConfig = (pkgs.formats.toml { }).generate "starship-nushell.toml" (
    config.programs.starship.settings
    // {
      character = {
        disabled = true;
      };
    }
  );

  themeSrc = ./overlays/theme;
  themesDir = "${pkgs.nu-scripts}/themes/nu-themes";

  overlays = [
    {
      name = "system";
      src = ./overlays/system;
      enable = true;
      prefix = true;
    }
    {
      name = "theme";
      src = themeSrc;
      file = "theme.nu";
      enable = true;
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
          else if hostname == "pigeon" then
            "/Users/${user}/workbench"
          else if hostname == "korriban" then
            "/home/hazel/workbench"
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
        aliases = {
          cr = "claude --resume";

          wa = "workspace attach";
          we = "workspace enter";
          wl = "workspace list";
          wr = "workspace rename";

          k = "kubectl";

          za = "zellij attach";
          ze = "zellij list-sessions";

          fg = "job unfreeze";

          fe = "yazi";

          te = "tmux list-sessions";
          ta = "tmux attach";
        };
      }
    )
  ];

  enabledOverlays = lib.filter (o: o.enable) overlays;

  overlayLoads = lib.concatMapStringsSep "\n" (
    o:
    "overlay use ${lib.optionalString o.prefix "--prefix "}${o.src}/${o.file or "mod.nu"} as ${o.name}"
  ) enabledOverlays;

  # Aliases contributed by overlays; defined after overlay loads so their
  # target commands are in scope.
  aliasLoads = lib.concatLists (
    map (o: lib.mapAttrsToList (name: cmd: "alias ${name} = ${cmd}") (o.aliases or { })) enabledOverlays
  );

  # Appended after the overlay loads so `theme` is in scope. `source` needs a
  # parse-time const path; env.nu writes the snippet before config.nu is parsed.
  themeStartup = ''
    const nu_theme_active_file = ($nu.data-dir | path join "theme-active.nu")
    source $nu_theme_active_file

    # Record the boot polarity so the pre_prompt hook only re-themes on a flip.
    $env.NU_THEME_ACTIVE = (theme resolve)
    $env.NU_THEME_ACTIVE_POLARITY = (theme detect-polarity)
    $env.config.hooks.pre_prompt = (
      $env.config.hooks.pre_prompt? | default [] | append {|| theme sync }
    )
  '';

  # home-manager owns config.nu (it also carries the mise/carapace/direnv nushell
  # inits appended by those modules), so we can't make it a bare symlink. Instead
  # the generated config.nu ends by sourcing the working-tree config.nu, exposed
  # as an out-of-store symlink at user-config.nu. Editing programs/nushell/config.nu
  # then reflects in new shells without a rebuild, the way ~/.claude/settings.json
  # is editable. Sourced after the overlay + alias loads so its `zd`/`zda` see the
  # `workspace` overlay.
  userConfig = "${config.home.homeDirectory}/.config/nushell/user-config.nu";

  configText = lib.concatLines (
    [ overlayLoads ]
    ++ aliasLoads
    ++ [
      "source ${zoxideInit}/init.nu"
      themeStartup
      "source ${userConfig}"
    ]
  );

  # config.nu minus the prompt/completion machinery, for `nu -c` callers such as
  # Claude Code's /nu command. themeStartup is the reason this can't just be
  # config.nu: it writes OSC colour escapes to stdout ahead of any real output.
  nonInteractiveText = lib.concatLines (
    [ overlayLoads ] ++ aliasLoads ++ [ "source ${userConfig}" ]
  );

  # Into env.nu (runs before config.nu parse): theme data + the write-startup that
  # generates the snippet config.nu sources. Child shells inherit STARSHIP_CONFIG
  # and lose their λ; rare enough to accept.
  themeEnv = ''
    $env.STARSHIP_CONFIG = "${starshipNuConfig}"
    $env.NU_THEMES_DIR = "${themesDir}"
    $env.NU_THEME_DEFAULT_LIGHT = "${pkgs.theme.nushell.light}"
    $env.NU_THEME_DEFAULT_DARK = "${pkgs.theme.nushell.dark}"
    $env.NU_THEME_HOST_VARIANT = "${pkgs.theme.variant}"

    use ${themeSrc}/theme.nu
    theme write-startup
  '';

  # Homebrew shellenv, re-expressed natively (Nushell can't `eval` the POSIX
  # output of `brew shellenv`). env.nu runs for every session before config.nu,
  # so PATH is ready early. No-op when brew is absent; idempotent via `uniq`.
  darwinEnv = ''
    $env.SHELL = "${nushell}/bin/nu"

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
    extraEnv = lib.concatLines ([ themeEnv ] ++ lib.optional isDarwin darwinEnv);
    plugins = [
      # polars   # broken atm
    ];
  };

  # Out-of-store symlink to the working-tree config.nu, which the generated
  # config.nu sources last (see userConfig). Editing programs/nushell/config.nu
  # then reflects in new shells without a rebuild, like ~/.claude/settings.json.
  home.file.".config/nushell/user-config.nu".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/programs/nushell/config.nu";

  home.file.".config/nushell/non-interactive.nu".text = nonInteractiveText;

  # Required for the task module
  services.pueue.enable = true;

  # Multi-shell argument completer — nushell's external completer, covering the
  # long tail of CLIs (kubectl, terraform, docker, gh, git, …). Its integration
  # appends to programs.nushell.config, so it composes with configText above.
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  home.packages = [ nufmt ];
}
