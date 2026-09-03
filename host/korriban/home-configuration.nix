{ lib, pkgs, ... }:
{
  imports = [
    ../../programs/claude
    ../../programs/claude/shared/github.nix
    ../../services/shairport-sync.nix
    ./home-niri.nix
  ];

  home.packages = with pkgs; [
    libreoffice
    sidra
  ];

  # The whole default-application set, since home-manager replaces mimeapps.list
  # wholesale rather than merging into it.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "x-scheme-handler/itms" = "sidra.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };

  home.sessionVariables.BROWSER = "firefox";

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
    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/host/korriban/ghostty.local \
      ~/.config/ghostty.local
    run ln -fsn $VERBOSE_ARG \
      ~/.config/nix-config/host/korriban/ghostty.moonshine \
      ~/.config/ghostty.moonshine
  '';

}
