{
  pkgs,
  config,
  lib,
  ...
}:
let
  USER = "armstrong";
  HOME = "/home/${USER}";
in
{
  programs.home-manager.enable = true;

  imports = [
    ../../home/common.nix
    ../../services/lorri.nix
    ../../programs/nushell.nix
    ../../programs/tmux.nix
    ../../programs/starship.nix
    ../../programs/git
    ../../programs/neovim
    ../../programs/alacritty
    #../../programs/vscode.nix
  ];

  home = {
    stateVersion = "21.11";

    username = USER;
    homeDirectory = HOME;

    sessionVariables = {
      PAGER = "less -R";
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERM = "xterm-256color";

      # TODO: Refactor
      FZF_DEFAULT_COMMAND = "fd --type f";
      BAT_CONFIG_PATH = "${HOME}/.config/bat/config";
    };

    file.".gdbinit".text = ''
      define hook-quit
        set confirm off
      end
    '';
  };
}
