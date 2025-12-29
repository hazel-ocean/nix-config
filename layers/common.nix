{
  pkgs,
  lib,
  ...
}:
with pkgs;
let
  inherit (pkgs.stdenv) isDarwin isLinux;

  packages = [
    # Files & Text

    # Felix alternative
    yazi

    # felix-fm
    # chafa # required for felix-fm file previews

    file
    eza
    fd
    ripgrep
    ack
    sd
    grex
    fzf
    zoxide
    bat
    ijq
    jq
    yq-go
    # mdcat
    glow
    icdiff
    tokei
    entr
    pv
    wget
    rsync
    unzip
    dua
    duf
    dust
    hexyl
    iconv
    zstd

    # Multimedia
    ffmpeg

    # Shells and Unix Environment
    # (pkgs.callPackage ../packages/dingus.nix { })
    # (pkgs.callPackage ../packages/itm { })

    # Chat & Browsing
    # irssi
    w3m

    # Identity Management
    gnupg

    ## Writing Tools
    mdbook

    # Process Management
    killall
    htop
    btop
    procs
    bandwhich
    bottom

    # Device Management
    smartmontools

    # Networking
    nmap
    # See https://github.com/NixOS/nixpkgs/issues/175875
    # httpie
    inetutils

    # Content
    yt-dlp

    # Build Tools
    autoconf
    pkg-config
    gnumake
    just

    # BEAM Languages
    # next-ls

    # Languages
    exercism

    # Nix
    cachix
    alejandra
    nixfmt-rfc-style
    nil
    nixd
    nix-tree

    # Kubernetes
    k9s

    # LLMs
    claude-code
  ]
  ++ lib.optionals isLinux [
    xsel # rmesg
    xclip
    usbutils # lsusb and others
  ];

  lsdAliases = {
    er = "clear; ls -l";
    r = "clear; ls";
    ra = "clear; ls -a";
    e = "clear";
    era = "clear; ls -la";
    err = "clear; ls -lR";
    erra = "clear; ls -lRa";
    et = "clear; ls --tree --depth 1";
    eta = "clear; ls -a --tree --depth 1";
    et0 = "clear; ls --tree --depth 0";
    et1 = "clear; ls --tree --depth 1";
    et2 = "clear; ls --tree --depth 2";
    et3 = "clear; ls --tree --depth 3";
    et4 = "clear; ls --tree --depth 4";
    etr = "clear; ls --tree";
    re = "clear; ls *";
    rea = "clear; ls -a *";
  };

  shellFor = program: {
    sessionVariables = {
      CARGO_TARGET_DIR = "$HOME/.cargo/target";
    }
    // lib.optional isLinux {
      PATH = "$HOME/.local/bin:$HOME/.cargo/bin:$PATH";
    }
    // lib.optional isDarwin {
      PATH = "$HOME/.cargo/bin:$PATH";
      TMUX_TMPDIR = "$XDG_RUNTIME_DIR";
    };

    init = ''
      set -o vi

      function purge_docker() {
        docker system prune --force
        docker volume prune --force
        docker image prune --force
        docker container prune --force
      }

      if test -x "$(which direnv)"; then
        eval "$(direnv hook ${program})"
      fi

      if test -x "$(which zoxide)"; then
        eval "$(zoxide init ${program})"
      fi
    ''
    + lib.optionalString isDarwin ''
      if ! test -d $TMUX_TMPDIR; then
        mkdir -p $TMUX_TMPDIR
      fi

      if [ "$(uname)" = "Darwin" -a -n "$NIX_LINK" -a -f $NIX_LINK/etc/X11/fonts.conf ]; then
        export FONTCONFIG_FILE=$NIX_LINK/etc/X11/fonts.conf
      fi
    '';

    aliases = {
      # Git
      eg = "clear; git status";
      egg = "clear; git status; echo; git diff";
      egc = "clear; git status; echo; git diff --cached";

      # Tmux
      te = "tmux list-sessions";
      ta = "tmux attach";

      # Zellij
      za = "zellij attach";
      ze = "zellij list-sessions";
      zd = "zellij delete-all-sessions --yes";
      zw = "zellij -l welcome";
      zri = "zellij run --in-place";

      tf = "terraform";

      zvi = ''nvim $(fzf --preview 'bat --style=numbers --color=always {}')'';
      zhx = ''hx $(fzf --preview 'bat --style=numbers --color=always {}')'';
      zgc = "git checkout $(git branch | fzf)";

      k = "kubectl";

      fe = "yazi";

      system-config = ''$SHELL -c "cd \"\$HOME/.config/nix-config\" && just edit"'';
      sys = "system-config";
      config = "system-config";
      conf = "system-config";

      # `git` helpers
      gan = ''git add -N flake.* nix'';
      grn = ''git reset -- flake.* nix'';

      # Docker
      dsprune = "docker system prune --all --volumes --force";
      diprune = "docker image prune --all --force";
      dcprune = "docker container prune --force";
      dnprune = "docker network prune --force";
      dvprune = "docker volume prune --all --force";
      daprune = "dsprune && diprune && dcprune && dnprune && dvprune && dsprune";
    }
    // lsdAliases
    // lib.optionalAttrs isLinux {
      open = "xdg-open";
      cdcopy = "pwd | xsel -ib";
      cdpaste = "cd \"$(xsel -ob)\"";
    }
    // lib.optionalAttrs isDarwin {
      cdcopy = "pwd | pbcopy";
      cdpaste = "cd \"$(pbpaste)\"";
      # code = "/opt/homebrew/bin/code-insiders";
      code-stable = "/opt/homebrew/bin/code";
    };
  };
in
{
  home.packages = packages;

  home.file.".config/bat/config".text = lib.optionalString (theme.bat != null) ''
    --theme=${
      # if isDarwin then "auto:system" else "auto"
      "auto"
    } --theme-dark="${theme.bat.dark}" --theme-light="${theme.bat.light}" --plain
  '';

  home.shell.enableShellIntegration = true;

  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
    mise.enable = true;
  };

  # Program Definition
  # - https://github.com/rycee/home-manager/blob/master/modules/programs/zsh.nix
  programs.zsh =
    let
      shell = shellFor "zsh";
    in
    {
      enable = true;
      enableVteIntegration = true;
      shellAliases = shell.aliases;
      initContent = shell.init;
      defaultKeymap = "viins";

      # enableFzfCompletion = true;
      # enableFzfGit = true;
      # enableFzfHistory = true;

      oh-my-zsh = {
        enable = true;
        plugins = [
          "vi-mode"
          "history-substring-search"
        ];
      };
    };

  programs.fzf.enable = true;

  programs.bash =
    let
      shell = shellFor "bash";
    in
    {
      enable = false;
      shellAliases = shell.aliases;
      historyControl = [
        "erasedups"
        "ignoredups"
        "ignorespace"
      ];
      historyIgnore = [
        "ls"
        "cd"
        "exit"
      ];
      initExtra = shell.init;
    };

  programs.lsd = {
    enable = true;
    # enableAliases = true;
    settings.color.when = "never";
  };
}
