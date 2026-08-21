{ lib, pkgs, ... }:
{
  imports = [
    ../../programs/claude
    ../../programs/claude/darwin.nix
    ../../programs/claude/pigeon.nix
  ];

  home.packages = with pkgs; [
    moonlight-qt-latest
    # mcp-nixos # TODO: use flake from github repo
  ];

  programs.claude-code.enable = true;

  programs.direnv.mise.enable = true;
  programs.mise = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  home.activation.makeSymbolicLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/host/pigeon/scripts \
      ~/.local/scripts

    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/programs/ghostty/config \
      ~/.config/ghostty
  '';
}
