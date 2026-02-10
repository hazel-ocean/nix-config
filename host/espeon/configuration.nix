{
  pkgs,
  ...
}:
let
  HOST_NAME = "espeon";
  USER = "hazel";
  HOME = "/Users/${USER}";
in
{
  imports = [ ../../system/darwin.nix ];

  nix.settings.trusted-users = [ USER ];

  networking = {
    computerName = HOST_NAME;
    hostName = HOST_NAME;
  };

  system.primaryUser = USER;

  users.users.${USER} = {
    home = HOME;
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
    };

    taps = [ ];

    masApps = {
      "1Password for Safari" = 1569813296;
      "Craft" = 1487937127;
      "reMarkable" = 1276493162;
      "Screen Focus" = 1337028713;
      "Tailscale" = 1475387142;
      "Things" = 904280696;
      "Xcode" = 497799835;
    };

    brews = [
      "mas" # Required for `masApps` above

      # OneSignal Repos
      "coreutils"
      "docker"
      "docker-compose"
      "graphviz"
      "helm"
      "helmfile"
      "imagemagick"
      "jemalloc"
      "libomp"
      "libpq"
      "libsodium"
      "libyaml"
      "mise"
      "mkcert"
      "node"
      "postgresql@15"
      "protobuf"
      "readline"
      "shellcheck"
      "zsh"
    ];

    casks = [
      "1password"
      "asana"
      "bitwarden"
      "brave-browser"
      "chatgpt"
      "claude"
      "claude-code"
      "cursor"
      "docker-desktop"
      {
        name = "ghostty@tip";
        greedy = true;
      }
      "granola"
      "handbrake-app"
      "jordanbaird-ice"
      "logi-options+"
      "macwhisper"
      "mimestream"
      "miro"
      "monocle-app"
      "orion"
      "obsidian"
      "raycast"
      "rectangle-pro"
      "slack"
      "spotify"
      "tableplus"
      "thingsmacsandboxhelper"
      "vlc"
      {
        name = "wezterm@nightly";
        greedy = true;
      }
      "zed"
      "zoom"
    ];
  };

  environment.systemPackages = with pkgs; [
    duti
    ncurses
    nushell
    zsh

    # From overlays
    tuios

    # OneSignal
    (google-cloud-sdk.withExtraComponents (
      with google-cloud-sdk.components;
      [
        gke-gcloud-auth-plugin
      ]
    ))
    kubectl
    kubectx

    # Apple Shortcuts
    # - "Set the default browser"
    defaultbrowser
  ];
}
