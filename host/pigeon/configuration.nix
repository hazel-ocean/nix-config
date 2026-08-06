{ pkgs, ... }:
let
  HOST_NAME = "pigeon";
  USER = "hazel";
  HOME = "/Users/${USER}";
in
{
  imports = [ ../../system/darwin.nix ];

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

    settings = {
      trusted-users = [
        USER
        "@admin" # Required for nix-darwin's `nix.linux-builder`
      ];
    };
  };

  networking = {
    computerName = HOST_NAME;
    hostName = HOST_NAME;
  };

  system.primaryUser = USER;

  users.users.${USER} = {
    home = HOME;
    isHidden = false;
    shell = pkgs.zsh;

    packages = with pkgs; [
      imagemagick
      poppler-utils
    ];

    openssh.authorizedKeys.keyFiles = [
      ../espeon/ssh/id_ed25519.pub
      ../korriban/ssh/id_ed25519.pub
    ];
  };

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
      extraFlags = [
        "--force"
        "--force-cleanup"
      ];
    };

    taps = [
      # "frankea/whisky"
    ];

    masApps = {
      "1Password for Safari" = 1569813296;
      "Craft" = 1487937127;
      "Kindle" = 302584613;
      "Prime Video" = 545519333;
      "reMarkable" = 1276493162;
      "Tailscale" = 1475387142;
      "Things" = 904280696;
      "WhatsApp" = 310633997;

      # "GarageBand" = 682658836;
      # "iMovie" = 408981434;
      # "Keynote" = 409183694;
      # "Numbers" = 409203825;
      # "Pages" = 409201541;
    };

    brews = [
      "cocoapods"
      "mas"
      "mise"
    ];

    casks = [
      "1password"
      # "android-studio"
      "brave-browser"
      "calibre"
      "chatgpt"
      "claude"
      "discord"
      "drawio"
      "firefox"
      "focusrite-control"
      # "frankea/whisky/whisky"
      "gog-galaxy"
      "google-chrome"
      "ghostty"
      "handbrake-app"
      "mimestream"
      # "musescore"
      "monocle-app"
      # "moonlight"
      # "nvidia-geforce-now"
      "obsidian"
      "plex"
      "protonvpn"
      "qbittorrent"
      # "raspberry-pi-imager"
      "raycast"
      "rectangle-pro"
      "rio"
      "signal"
      "slack"
      "spotify"
      "steam"
      "swiftformat-for-xcode"
      "tableplus"
      "thaw"
      "thingsmacsandboxhelper"
      "visual-studio-code"
      "vlc"
      "wezterm"
      "wispr-flow"
      "zed"
      "zoom"
    ];
  };

  environment.systemPackages = with pkgs; [
    ncurses
    nushell
    zsh

    # Apple Shortcuts
    # - "Set the default browser"
    defaultbrowser
  ];
}
