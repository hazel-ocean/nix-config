{ lib, pkgs, ... }:
{
  # home.packages = with pkgs; [
  # ];

  # programs.claude-code = {
  #   enable = true;
  #   mcpServers = {
  #     obsidian = {
  #       type = "stdio";
  #       command = "${pkgs.mcp-obsidian}/bin/mcp-obsidian";
  #       args = [ "/Users/hazel/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/OneSignal/" ];
  #     };
  #     things = {
  #       type = "stdio";
  #       command = "${pkgs.mcp-things}/bin/things-mcp";
  #       args = [ ];
  #     };
  #   };
  # };

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
