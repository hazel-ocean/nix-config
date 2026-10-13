# Shared configuration for all hosts
{
  config,
  lib,
  options,
  inputs,
  pkgs,
  ...
}:
let
  settings = {
    lazy-trees = true;
    extra-experimental-features = [ "pipe-operators" ];
    keep-outputs = true;
    keep-derivations = true;
    download-buffer-size = 134217728; # 2^27
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # A darwin host without the Determinate module runs upstream Nix, which needs
  # flakes turned on and does not know lazy-trees.
  upstreamSettings = removeAttrs settings [ "lazy-trees" ] // {
    extra-experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];
  };

  # Roots every input, so GC keeps evaluation-only sources.
  registry = lib.mapAttrs (_: flake: { inherit flake; }) (removeAttrs inputs [ "self" ]);
in
{
  config = lib.mkMerge [
    (lib.optionalAttrs (options ? determinateNix) {
      determinateNix = {
        customSettings = settings;
        # Determinate on darwin turns off nix.*, which drops the nixpkgs entry
        # that nixpkgs.flake.setFlakeRegistry adds.
        registry = registry // {
          nixpkgs.to = {
            type = "path";
            path = config.nixpkgs.flake.source;
          };
        };
      };
    })
    (lib.mkIf (!options ? determinateNix && !pkgs.stdenv.hostPlatform.isDarwin) {
      nix = { inherit settings registry; };
    })
    (lib.mkIf (!options ? determinateNix && pkgs.stdenv.hostPlatform.isDarwin) {
      nix = {
        inherit registry;
        settings = upstreamSettings;
        gc.automatic = true;
        optimise.automatic = true;
      };
    })
  ];
}
