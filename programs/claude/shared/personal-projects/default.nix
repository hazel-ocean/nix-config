# Personal project loop: new-project, checkpoint and close-project, over
# beads, the workbench and the Obsidian vault.
{ config, ... }:
{
  # One database for all work. bd stops searching at a git repo boundary, so
  # it cannot find this from a repo outside the workbench.
  home.sessionVariables.BEADS_DIR = "${config.home.homeDirectory}/workbench/.beads";

  local.claude = {
    contextFragments = [ ./context.md ];
    extraSkills = {
      checkpoint = ./skills/checkpoint;
      new-project = ./skills/new-project;
      close-project = ./skills/close-project;
    };
  };
}
