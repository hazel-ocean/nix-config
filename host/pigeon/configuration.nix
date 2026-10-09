{ pkgs, ... }:
let
  HOST_NAME = "pigeon";
  USER = "hazel";
  HOME = "/Users/${USER}";
in
{
  imports = [
    ../../system/common.nix
    ../../system/darwin.nix
  ];

  determinateNix.customSettings = {
    extra-platforms = [ "x86_64-darwin" ];
    trusted-users = [ USER ];
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
      "Apple Developer" = 640199958;
      "Craft" = 1487937127;
      "Kindle" = 302584613;
      "Prime Video" = 545519333;
      "reMarkable" = 1276493162;
      "Steam Link" = 1246969117;
      "Tailscale" = 1475387142;
      "Things" = 904280696;
      "WhatsApp" = 310633997;
      "Xcode" = 497799835;

      "GarageBand" = 682658836;
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
      "arduino-ide"
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
      "homebrew-app"
      "mimestream"
      # "musescore"
      "monocle-app"
      # "moonlight" # built from source via moonlight-qt-latest instead
      # "nvidia-geforce-now"
      "obsidian"
      "orion"
      "plex"
      "protonvpn"
      "qlmarkdown"
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
      "thaw@beta"
      "thingsmacsandboxhelper"
      "transmission"
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
