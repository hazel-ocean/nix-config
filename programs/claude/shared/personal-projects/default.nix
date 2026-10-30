# Personal project loop: new-project, checkpoint and close-project, over
# beads, the workbench and the Obsidian vault.
{
  local.claude = {
    contextFragments = [ ./context.md ];
    extraSkills = {
      checkpoint = ./skills/checkpoint;
      new-project = ./skills/new-project;
      close-project = ./skills/close-project;
    };
  };
}
