# Shared configuration for Darwin (macOS) hosts
{ pkgs, config, ... }:
{
  imports = [ ./packages.nix ];

  networking.applicationFirewall = {
    enable = true; # Prevent unauthorized incoming requests
    enableStealthMode = true; # Ignore incoming ICMP traffic (pings, etc.)
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      ChallengeResponseAuthentication no
    '';
  };

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

    CustomUserPreferences = {
      "com.apple.GameController" = {
        longPressShareGesture_mac = -1; # Disable Home-button long-press overlay
        doublePressShareGesture_mac = 0; # Disable Home-button double-press action
      };
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

    # Let root (sudo darwin-rebuild) authenticate to GitHub for private
    # git+ssh flake inputs using the primary user's key. Only the path is
    # referenced; the key never enters the world-readable Nix store.
    etc."ssh/ssh_config.d/100-github-primary-user.conf".text = ''
      Host github.com
        IdentityFile /Users/${config.system.primaryUser}/.ssh/id_ed25519
        IdentitiesOnly yes
    '';

    loginShellInit = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    systemPath = [ "$HOME/.cargo/bin" ];
  };

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
