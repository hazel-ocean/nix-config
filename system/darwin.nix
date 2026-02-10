# Shared configuration for Darwin (macOS) hosts
{ pkgs, lib, ... }:
{
  imports = [ ./packages.nix ];
  nix = {
    extraOptions = ''
      build-users-group = nixbld
      experimental-features = nix-command flakes pipe-operators
      keep-outputs = true
      keep-derivations = true
    '';

    optimise = {
      automatic = true;
      interval = [
        {
          Hour = 7;
          Minute = 0;
        }
      ];
    };

    settings = {
      download-buffer-size = 134217728; # 2^27
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  networking.applicationFirewall = {
    enable = true; # Prevent unauthorized incoming requests
    enableStealthMode = true; # Ignore incoming ICMP traffic (pings, etc.)
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

    trackpad = {
      Clicking = true; # Tap-to-click
      TrackpadThreeFingerDrag = true;
    };

    NSGlobalDomain = {
      "com.apple.trackpad.scaling" = 3.0; # Trackpad tracking speed (0-3f)

      # Keyboard Settings
      InitialKeyRepeat = 15;
      KeyRepeat = 2;

      # Grammatical Help Settings
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    dock = {
      autohide = true;
      mineffect = "scale"; # Minimize to dock settings
      mru-spaces = false; # Don't automatically rearrange spaces
    };
  };

  fonts.packages = import ./font-packages.nix { inherit pkgs; };

  environment = {
    shells = with pkgs; [
      nushell
      zsh
    ];
    shellAliases = { };
    variables = { };

    loginShellInit = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    systemPath = [ "$HOME/.cargo/bin" ];
  };

  services.lorri.enable = true;

  programs.zsh = {
    enable = true;

    loginShellInit = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
