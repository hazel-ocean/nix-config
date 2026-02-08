{ pkgs, ... }:
let
  HOST_NAME = "pigeon";
  USER = "ocean";
  HOME = "/Users/${USER}";
in
{
  nix = {
    linux-builder = {
      enable = false;
      ephemeral = true;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 40 * 1024;
            memorySize = 8 * 1024;
          };
          cores = 10;
        };
      };
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
    };

    extraOptions = ''
      build-users-group = nixbld
      experimental-features = nix-command flakes pipe-operators
      extra-platforms = x86_64-darwin aarch64-darwin x86_64-linux aarch64-linux
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
      trusted-users = [
        USER
        "@admin" # Required for nix-darwin's `nix.linux-builder`
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  networking = {
    computerName = HOST_NAME;
    hostName = HOST_NAME;
    applicationFirewall = {
      enable = true; # Prevent unauthorized incoming requests
      enableStealthMode = true; # Ignore incoming ICMP traffic (pings, etc.)
    };

    # hosts = {
    #   # Required by Docker Desktop
    #   # Allows the same kube context to work on the host and the container
    #   # "127.0.0.1" = [ "kubernetes.docker.internal" ];
    # };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.primaryUser = USER;
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

  fonts.packages = import ../../layers/fonts.nix { inherit pkgs; };

  users.users.${USER} = {
    home = HOME;
    isHidden = false;
    shell = pkgs.zsh;

    packages = (
      with pkgs;
      [
        imagemagick
        poppler-utils
      ]
    );

    openssh.authorizedKeys.keyFiles = [
      ../espeon/ssh/id_ed25519.pub
      ../korriban/ssh/id_ed25519.pub
    ];
  };

  homebrew = {
    enable = true;

    onActivation = {
      # extraFlags = [ "--verbose" ];
      cleanup = "zap";
      # autoUpdate = true;
      # upgrade = true;
    };

    taps = [ ];

    masApps = {
      "1Password for Safari" = 1569813296;
      # "Audible" = 379693831;
      "Craft" = 1487937127;
      "Kindle" = 302584613;
      "Prime Video" = 545519333;
      "reMarkable" = 1276493162; # (3.19.0)
      "Tailscale" = 1475387142;
      "Things" = 904280696;
      "WhatsApp" = 310633997;

      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
    };

    brews = [
      "cocoapods"
      "mas"
      "mise"
    ];

    casks = [
      "1password"
      "android-studio"
      "anytype"
      "brave-browser"
      "calibre"
      "chatgpt"
      "claude"
      "discord"
      "firefox"
      "focusrite-control"
      "gog-galaxy"
      {
        name = "ghostty@tip";
        greedy = true;
      }
      "granola"
      "handbrake-app"
      "jordanbaird-ice"
      "librewolf"
      "logi-options+"
      # "lunar"
      "macwhisper"
      "musescore"
      "monocle-app"
      "moonlight"
      # "notion"
      "nvidia-geforce-now"
      "obsidian"
      "orbstack"
      "plex"
      "protonvpn"
      "qbittorrent"
      "raspberry-pi-imager"
      "raycast"
      "rectangle-pro"
      "rio"
      "signal"
      "slack"
      "spotify"
      "steam"
      "swiftformat-for-xcode"
      "tableplus"
      "thingsmacsandboxhelper"
      "utm"
      "visual-studio-code"
      "vlc"
      {
        name = "wezterm@nightly";
        greedy = true;
      }
      "zed"
      "zen"
      "zoom"
    ];
  };

  environment = with pkgs; {
    systemPackages = [
      ncurses
      nushell
      zsh

      # Apple Shortcuts
      # - "Set the default browser"
      defaultbrowser
    ];
    shells = [
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

  services = {
    lorri.enable = true;
  };

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
