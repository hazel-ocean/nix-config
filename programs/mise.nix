{ config, ... }:
{
  programs.direnv.mise.enable = config.programs.direnv.enable;
  programs.mise = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
}
