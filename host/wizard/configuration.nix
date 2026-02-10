{
  config,
  pkgs,
  lib,
  ...
}:
let
  HOST_NAME = "Wizard";
  USER = "armstrong";
  HOME = "/Users/${USER}";
in
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixFlakes;
    # Sandbox seems to interfere with Rust builds on macOS Moterey 12.0.1
    # - https://github.com/NixOS/nixpkgs/issues/144704
    useSandbox = false;
    extraOptions = ''
      experimental-features = nix-command flakes pipe-operators
    '';
  };

  imports = [
    <home-manager/nix-darwin>
  ];

  networking = {
    computerName = HOST_NAME;
    hostName = HOST_NAME;
  };

  fonts = {
    enableFontDir = true;
    fonts = import ../../system/font-packages.nix { inherit pkgs; };
  };

  users.users."${USER}" = {
    home = HOME;
    isHidden = false;
    shell = pkgs.zsh;
  };

  environment = {
    # $ darwin-rebuild switch -I darwin-config=$HOME/.nixpkgs/host/wizard/configuration.nix
    darwinConfig = "$HOME/.config/nixpkgs/host/wizard/configuration.nix";

    # Append paths to the system PATH
    #systemPath = [
    #  ''/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin''
    #];

    systemPackages = with pkgs; [
      m-cli
      xquartz
      alacritty
      vscode
    ];
  };

  services = {
    lorri.enable = true;

    redis = {
      enable = true;
      dataDir = "${HOME}/.redis";
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      dataDir = "${HOME}/.postgresql_14";
    };
  };

  programs.zsh.enable = true;
  programs.bash.enable = true;
  homebrew.enable = true;

  home-manager = {
    users."${USER}" =
      { pkgs, ... }:
      {
        imports = [
          ../../home/common.nix
          ../../programs/nushell.nix
          ../../programs/zoxide.nix
          ../../programs/tmux.nix
          ../../programs/starship.nix
          ../../programs/git
          ../../programs/neovim
          ../../programs/alacritty
        ];

        programs.home-manager.enable = true;

        home = {
          stateVersion = "21.11";
          username = USER;
          homeDirectory = HOME;
          packages = [ pkgs.direnv ];

          sessionVariables = {
            PAGER = "less -R";
            EDITOR = "nvim";
            VISUAL = "nvim";
            TERM = "xterm-256color";

            XDG_CONFIG_HOME = "${HOME}/.config";
            XDG_DATA_HOME = "${HOME}/.local/share";
            XDG_DATA_DIRS = "${HOME}/.local/data";
            XDG_RUNTIME_DIR = "${HOME}/.local/run";

            # TODO: Refactor
            FZF_DEFAULT_COMMAND = "fd --type f";
            BAT_CONFIG_PATH = "${HOME}/.config/bat/config";
            GOPATH = "${HOME}/Developer/go/";
          };

          file.".ideavimrc".text = ''
            " Enable relative line numbers
            set relativenumber
            set number

            " Integrate with system clipboard
            set clipboard=unnamedplus,unnamed
            let mapleader = " "
            " yank to system clipboard
            set clipboard=unnamed
            set clipboard+=ideaput

            "" Tab navigation
            nnoremap <A-l> :tabnext<CR>
            nnoremap <A-h> :tabprevious<CR>
            nnoremap <A-BS> :tabclose<CR>

            "" Code Navigation
            nnoremap <S-CR> :action GotoDeclaration<CR>
          '';

          file."${HOME}/.config/nu/config.toml".onChange = ''
            echo Linking in nushell config file
            ln -sfv "${HOME}/.config/nu/config.toml" "${HOME}/Library/Application Support/org.nushell.nu/config.toml"
          '';
        };
      };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
