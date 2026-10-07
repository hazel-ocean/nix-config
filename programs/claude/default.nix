{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.local.claude;

  # The file stem must match the output style's frontmatter `name`, which is
  # the value `outputStyle` selects.
  personas = lib.mapAttrs' (file: _: {
    name = lib.removeSuffix ".md" file;
    value = ./personas + "/${file}";
  }) (builtins.readDir ./personas);

  baseSettings =
    import ./settings.nix { stdenv = pkgs.stdenv; }
    // lib.optionalAttrs (cfg.persona != null) { outputStyle = cfg.persona; };

  # recursiveUpdate replaces lists wholesale; the permission lists are the one
  # place a fragment needs to add to what the base set already allows.
  settings =
    let
      merged = lib.recursiveUpdate baseSettings cfg.extraSettings;
      mergeList =
        name:
        lib.unique (
          (baseSettings.permissions.${name} or [ ]) ++ (cfg.extraSettings.permissions.${name} or [ ])
        );
    in
    merged
    // {
      permissions =
        merged.permissions or { }
        // lib.filterAttrs (_: v: v != [ ]) (lib.genAttrs [ "allow" "deny" "ask" ] mergeList);
    };

  # One source feeds both tools. Claude Code has no AGENTS.md at user scope, so
  # it still gets CLAUDE.md; Codex reads only AGENTS.md.
  agentContext = lib.concatMapStringsSep "\n" builtins.readFile (
    [ ./AGENTS.md ] ++ cfg.contextFragments
  );

  # The upstream module only takes the `source` branch for a real path, so
  # fragments have to be concatenated into a string rather than a derivation.
  context = if cfg.contextFragments == [ ] then ./AGENTS.md else agentContext;

  vendoredSkills = lib.genAttrs (builtins.attrNames (builtins.readDir ./.agents/skills)) (
    name:
    let
      src = ./.agents/skills + "/${name}";
      supplement = ./supplements + "/${name}.md";
    in
    if builtins.pathExists supplement then
      "${pkgs.runCommand "${name}-skill" { } ''
        cp -r ${src} $out
        chmod -R u+w $out
        { echo; cat ${supplement}; } >> $out/SKILL.md
      ''}"
    else
      src
  );

  beads-skill = "${pkgs.beads.src}/plugins/beads/skills/beads";

  # The packaged 1.6.2 tree carries no SKILL.md, so the skill comes from a main
  # rev of the same repo. Drop the rev once nixpkgs ships a release with it.
  gh-pr-review-skill =
    let
      src = pkgs.fetchFromGitHub {
        inherit (pkgs.gh-pr-review.src) owner repo;
        rev = "d2c86f61c5709c567e8487ba82f04112a456c221";
        hash = "sha256-1TINm9rMckjAG7nyBR5AqSqWpzVp6ey7c1wm98s488w=";
      };
    in
    pkgs.runCommandLocal "gh-pr-review-skill" { } ''
      mkdir -p $out
      cp ${src}/SKILL.md $out/SKILL.md
      cp -R ${src}/docs $out/docs
    '';
in
{
  imports = [ ./shared/obsidian.nix ];

  options.local.claude = {
    obsidianVault = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Obsidian vault the MCP server serves. Null disables it.";
    };

    persona = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (builtins.attrNames personas));
      default = null;
      description = "Output style from ./personas that sets the voice. Null keeps the default.";
    };

    extraSkills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Skill directories to install alongside the vendored set.";
    };

    contextFragments = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Markdown appended to the agent context, in order.";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Settings merged over settings.nix. `permissions.allow`, `.deny` and
        `.ask` concatenate; every other key is replaced.
      '';
    };
  };

  config = {
    programs.claude-code = {
      inherit context;
      skills =
        vendoredSkills
        // cfg.extraSkills
        // {
          gh-pr-review = gh-pr-review-skill;
          beads = beads-skill;
        };
      commands.nu = ./commands/nu.md;
      outputStyles = personas;
    };

    home.packages = [ pkgs.beads ];
    # Opts into the `{schema_version, data}` JSON shape before bd makes it the default.
    home.sessionVariables.BD_JSON_ENVELOPE = "1";

    # Pretty-printed, because Claude Code's own writers (/effort, /config, /model,
    # /permissions) rewrite this file in place.
    home.file.".claude/settings.json" = {
      source = (pkgs.formats.json { }).generate "claude-settings.json" settings;
    };

    home.file.".codex/AGENTS.md".text = agentContext;
  };
}
