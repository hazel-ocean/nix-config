{ lib, pkgs, ... }:
{
  imports = [
    ../../services/shairport-sync.nix
    ../../programs/claude/shared/github.nix
    ./home-niri.nix
  ];

  services.shairport-sync = {
    enable = true;
    name = "Korriban";
    bufferLength = 10;
  };

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
      ~/.config/nix-config/programs/ghostty/config \
      ~/.config/ghostty
  '';

}
