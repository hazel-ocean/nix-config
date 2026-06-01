{ ... }:

{
  programs.claude-code = {
    context = ./memory.md;
    skills = ./skills;
  };
}
