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
  imports = [
    ../../system/common.nix
    ../../system/darwin.nix
  ];

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
      extraFlags = [
        "--force"
        "--force-cleanup"
      ];
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
      "docker-desktop"
      "ghostty"
      "google-drive"
      "granola"
      "handbrake-app"
      "linear"
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
      "tableplus"
      "thaw"
      "thingsmacsandboxhelper"
      "vlc"
      "wezterm"
      "wispr-flow"
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

    # Rust
    sccache

    # Apple Shortcuts
    # - "Set the default browser"
    defaultbrowser
  ];

  environment.variables = {
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
  };
}
