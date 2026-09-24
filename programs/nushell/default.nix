{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = config.local.nushell;

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

  hostname = osConfig.networking.hostName;

  systemDir = ./overlays/system;

  nuRecord =
    attrs: "{ ${lib.concatStringsSep ", " (lib.mapAttrsToList (k: v: ''${k}: "${v}"'') attrs)} }";

  # Retire an alias: `ze = deprecated.error { from = "ze"; to = "zl"; };`.
  # `warn` runs `to` verbatim as the replacement.
  deprecated = {
    error = opts: "deprecated error ${nuRecord opts}";
    warn = opts: "deprecated warn ${nuRecord opts} { ${opts.to} }";
  };

  builtinOverlays = [
    # Loaded first so every later overlay and alias can retire a name.
    {
      name = "deprecated";
      src = ./overlays/deprecated;
      enable = true;
      prefix = true;
    }
    {
      name = "system";
      src = systemDir;
      file = "shared.nu";
      enable = true;
      prefix = true;
    }
    # A second overlay of the same name merges into it, so the host commands join
    # the `system` namespace.
    {
      name = "system";
      src = systemDir;
      file = "${hostname}.nu";
      enable = builtins.pathExists (systemDir + "/${hostname}.nu");
      prefix = true;
    }
    {
      name = "theme";
      src = themeSrc;
      file = "theme.nu";
      enable = true;
      prefix = true;
      # write-startup generates the file extraConfig sources at parse time, so it
      # has to run here. probe-terminal precedes it to seed the cache resolve reads.
      extraEnv = ''
        $env.NU_THEMES_DIR = "${themesDir}"
        $env.NU_THEME_DEFAULT_LIGHT = "${pkgs.theme.nushell.light}"
        $env.NU_THEME_DEFAULT_DARK = "${pkgs.theme.nushell.dark}"
        $env.NU_THEME_HOST_VARIANT = "${pkgs.theme.variant}"

        $env.NU_THEME_TERM_QUERY = (theme probe-terminal)
        theme write-startup
      '';
      # Sourced, not inlined: it carries no Nix values, so it stays a real .nu
      # that nufmt formats and editors highlight.
      extraConfig = "source ${themeSrc}/startup.nu";
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
    {
      name = "workspace";
      src = cfg.workspaceRoot;
      enable = cfg.workspaceRoot != null;
      # mod.nu already exports `workspace <sub>`; --prefix would double it.
      prefix = false;
      aliases = {
        en = "do { clear; exec nu }";

        wa = "workspace attach";
        we = "workspace enter";
        wl = "workspace list";
        wr = "workspace rename";
        wi = "workspace info";

        k = "kubectl";

        za = "zellij attach";
        ze = deprecated.error {
          from = "ze";
          to = "zl";
        };
        zl = "zellij list-sessions";

        fg = "job unfreeze";

        fe = "yazi";

        te = "tmux list-sessions";
        ta = "tmux attach";

        cr = "claude --resume";
      };
    }
  ];

  overlays = builtinOverlays ++ cfg.extraOverlays;

  # Entry schema. Every consumer below can read every field.
  enabledOverlays = map (
    o:
    {
      file = "mod.nu";
      aliases = { };
      extraEnv = "";
      extraConfig = "";
    }
    // o
  ) (lib.filter (o: o.enable) overlays);

  overlayLoad =
    o: "overlay use ${lib.optionalString o.prefix "--prefix "}${o.src}/${o.file} as ${o.name}";

  overlayLoads = lib.concatMapStringsSep "\n" overlayLoad enabledOverlays;

  # env.nu has no overlay in scope, so each snippet loads its own and drops it:
  # two active frames of one module double every entry in the completion menu.
  overlayEnvs = lib.concatMapStrings (
    o:
    lib.optionalString (o.extraEnv != "") ''
      ${overlayLoad o}
      ${o.extraEnv}
      overlay hide ${o.name}
    ''
  ) enabledOverlays;

  # config.nu loaded every overlay already, so these run bare.
  overlayConfigs = lib.concatMapStrings (o: o.extraConfig) enabledOverlays;

  # Aliases contributed by overlays; defined after overlay loads so their
  # target commands are in scope.
  aliasLoads = lib.concatLists (
    map (o: lib.mapAttrsToList (name: cmd: "alias ${name} = ${cmd}") o.aliases) enabledOverlays
  );

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
      "source ${userConfig}"
    ]
  );

  # config.nu minus the prompt/completion machinery, for `nu -c` callers such as
  # Claude Code's /nu command. overlayConfigs is the reason this can't just be
  # config.nu: it writes OSC colour escapes to stdout ahead of any real output.
  nonInteractiveText = lib.concatLines ([ overlayLoads ] ++ aliasLoads ++ [ "source ${userConfig}" ]);

  # Only forward known-safe home.sessionVariables; other modules (e.g.
  # programs.starship) also write to this set, and blindly forwarding
  # STARSHIP_CONFIG clobbers the nushell-specific one extraEnv sets below.
  sessionVars = lib.filterAttrs (
    name: _:
    builtins.elem name [
      "EDITOR"
      "VISUAL"
      "PAGER"
      "FZF_DEFAULT_COMMAND"
      "BAT_CONFIG_PATH"
    ]
  ) config.home.sessionVariables;

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
  overlayModule = {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Overlay name, as `overlay use ... as <name>` binds it.";
      };
      src = lib.mkOption {
        type = lib.types.either lib.types.path lib.types.str;
        description = "Directory holding the module.";
      };
      file = lib.mkOption {
        type = lib.types.str;
        default = "mod.nu";
        description = "Module entry point, relative to `src`.";
      };
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      prefix = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Load with `--prefix`, so commands are namespaced under `name`. Set
          false when the module already exports its own prefix.
        '';
      };
      aliases = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Aliases defined after the overlay loads, so targets are in scope.";
      };
      extraEnv = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Nushell run in env.nu, with the overlay loaded and then hidden.";
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Nushell run in config.nu, with the overlay already in scope.";
      };
    };
  };
in
{
  options.local.nushell = {
    extraOverlays = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule overlayModule);
      default = [ ];
      description = ''
        Nushell modules to load on top of the built-in set. Each entry is
        sourced in config.nu and non-interactive.nu alike.
      '';
    };

    workspaceRoot = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "${config.home.homeDirectory}/workbench";
      description = ''
        Directory holding the `workspace` nushell module. Null disables the
        overlay and the aliases that come with it.
      '';
    };
  };

  config = {
    programs.nushell = {
      enable = true;
      package = nushell;
      configFile.text = configText;

      # Child shells inherit STARSHIP_CONFIG and lose their λ; rare enough to accept.
      extraEnv = lib.concatLines (
        [
          ''$env.STARSHIP_CONFIG = "${starshipNuConfig}"''
          overlayEnvs
        ]
        ++ lib.optional isDarwin darwinEnv
      );

      # mkBefore so these land ahead of the other nushell integrations, which use
      # plain priority or mkAfter.
      extraConfig = lib.mkBefore overlayConfigs;

      environmentVariables = sessionVars;
      plugins = [ polars ];
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
  };
}
