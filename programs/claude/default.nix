{ ... }:

{
  programs.claude-code = {
    context = ./memory.md;
    skills = ./.agents/skills;
  };
}
