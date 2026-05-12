{ ... }:

{
  programs.claude-code = {
    memory.source = ./memory.md;
    skillsDir = ./skills;
  };
}
