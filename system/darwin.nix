# Shared configuration for Darwin (macOS) hosts
{ pkgs, config, lib, ... }:
{
  imports = [ ./packages.nix ];

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
      "/etc/profiles/per-user/${config.system.primaryUser}/bin/nu"
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

    interactiveShellInit = ''
      exec nu
    '';
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
