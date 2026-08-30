{ lib, pkgs, ... }:
{
  imports = [
    ../../programs/claude
    ../../programs/claude/shared/github.nix
    ../../services/shairport-sync.nix
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

  # Wheel scrolling under niri overshoots at ghostty's default of 3.
  home.file.".config/ghostty.local".text = ''
    mouse-scroll-multiplier = discrete:1
  '';

  home.activation.makeSymbolicLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/programs/ghostty/config \
      ~/.config/ghostty
  '';

}
