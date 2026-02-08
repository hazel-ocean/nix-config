{
  username,
  homeDirectory,
  stateVersion,
  imports ? [ ],
  ...
}:
{
  imports = imports ++ [
    ../layers/common.nix
    ../programs/nushell
    ../programs/tmux.nix
    ../programs/starship.nix
    ../programs/git
    ../programs/helix
    ../programs/zellij
  ];

  programs.home-manager.enable = true;

  home = {
    inherit stateVersion username homeDirectory;

    sessionVariables = {
      PAGER = "less -R";
      EDITOR = "hx";
      VISUAL = "hx";
      TERM = "xterm-256color";

      FZF_DEFAULT_COMMAND = "fd --type f";
      BAT_CONFIG_PATH = "${homeDirectory}/.config/bat/config";
    };
  };
}
