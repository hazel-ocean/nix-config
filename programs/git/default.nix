{
  pkgs,
  lib,
  ...
}:
with pkgs;
{
  home.packages = [
    act
    difftastic
    delta
    git-crypt
    jujutsu
    riffdiff
    tuicr
  ];

  programs.gh = {
    enable = true;
    extensions = [
      gh-dash
      gh-pr-review
    ];

    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };

  # Program Definition
  # - https://github.com/rycee/home-manager/blob/master/modules/programs/git.nix
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Hazel Ocean Lewis";
        email = "6754950+hazel-ocean@users.noreply.github.com";
      };

      aliases = {
        lg1-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";

        lg2-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";

        lg3-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";

        lg1 = "lg1-specific --all";
        lg2 = "lg2-specific --all";
        lg3 = "lg3-specific --all";
        lg = "lg1";
      };

      core.editor = "hx";
      init.defaultBranch = "main";
      pull.ff = "only";
      push.autoSetupRemote = true;

      interactive.diffFilter = "riff --color=on";
      pager = {
        difftool = true;
        diff = "riff";
        show = "riff";
        log = "riff";
      };

      diff.tool = "difftastic";
      difftool.prompt = false;
      "difftool \"difftastic\"".cmd = ''difft "$LOCAL" "$REMOTE"'';
      alias.difft = "difftool";
    };

    ignores = [
      ## from programs.git.ignores in ../default.nix
      # Elixir
      ".env.local"

      # JVM
      "**/.idea"
      "/.classpath"
      "/.project"
      "/.settings"

      # VSCode
      ".vscode"

      # macOS
      ".DS_Store"
      "**/.DS_Store"

      # clangd
      ".cache"

      # Nix
      ".direnv"
      ".envrc"
      ".nix-mix"
      ".nix-hex"

      # Claude
      ".claude"
    ];

    includes = [
      {
        path = ./onesignal/includes;
        condition = "gitdir:~/OneSignal/";
      }
    ];
  };

  programs.delta = {
    enable = false;
    options = {
      syntax-theme = lib.optionalString (theme.delta != null) theme.delta;
    };
  };

  programs.difftastic = {
    enable = false;
    options.background = theme.difftastic;
  };
}
