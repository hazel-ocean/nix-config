# Shared configuration for all hosts
{ ... }:
{
  nix = {
    extraOptions = ''
      build-users-group = nixbld
      experimental-features = nix-command flakes pipe-operators
      keep-outputs = true
      keep-derivations = true
    '';

    gc.automatic = true;
    optimise.automatic = true;

    settings = {
      download-buffer-size = 134217728; # 2^27
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
