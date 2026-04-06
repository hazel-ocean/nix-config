{ pkgs, ... }:
let
  helix-themes-dir = "${pkgs.helix-unwrapped.HELIX_DEFAULT_RUNTIME}/themes";

  mkTransCustomThemes =
    pkgs.runCommandLocal "helix-transcust-themes"
      {
        buildInputs = [
          pkgs.nushell
          pkgs.helix
        ];
      }
      ''
        mkdir $out
        echo ${helix-themes-dir}
        nu ${./setup/make-custom-themes.nu} ${helix-themes-dir} $out
      '';
in
{
  home.file.".config/helix/themes" = {
    source = mkTransCustomThemes;
    # target = ".config/helix";
    recursive = true;
    force = true;
  };

  xdg.configFile."helix/languages.toml".text = ''
    [[language]]
    name = "sql"
    formatter = { command = "sleek", args = ["--indent-spaces=2"] }

    [language-server.nextls]
    command = "nextls"
    args = ["--stdio=true"]

    [language-server.nixd]
    command = "nixd"

    [language-server.nushell]
    command = "nu"
    args = ["--lsp"]

    [[language]]
    name = "nix"
    language-servers = ["nixd"]
    formatter = { command = "nixfmt" }

    [[language]]
    name = "elixir"
    indent = { tab-width = 2, unit = "  " }

    [[language]]
    name = "java"
    language-servers = ["jdtls"]

    [[language]]
    name = "nu"
    language-servers = ["nushell"]
    ## Super broken
    # formatter = { command = "nufmt", args = ["--stdin"] }

    ## NextLS seems to not work in VSCode or Helix for me :(
    # [[language]]
    # name = "elixir"
    # scope = "source.elixir"
    # language-servers = ["nextls"]
  '';

  programs.helix = {
    enable = true;
    package = pkgs.helix-latest;
    defaultEditor = true;

    settings = {
      theme = {
        light = pkgs.theme.helix.light;
        dark = pkgs.theme.helix.dark;
        fallback = pkgs.theme.helix.fallback;
      };

      editor = {
        line-number = "relative";
        soft-wrap.enable = true;
        bufferline = "multiple";

        # Minimum severity to show a diagnostic after the end of a line:
        end-of-line-diagnostics = "hint";
        inline-diagnostics = {
          # Minimum severity to show a diagnostic on the primary cursor's line.
          # Note that `cursor-line` diagnostics are hidden in insert mode.
          cursor-line = "error";
          # Minimum severity to show a diagnostic on other lines:
          other-lines = "error";
        };
      };

      keys.normal = {
        "A-l" = "goto_next_buffer";
        "A-h" = "goto_previous_buffer";
        "A-backspace" = ":buffer-close";
        "A-w" = ":buffer-close";

        space = {
          "=" = ":format";
          "f" = "file_picker_in_current_directory";
          "F" = "file_picker";
        };
      };
    };
  };

  home.packages = with pkgs; [
    alejandra
    buf
    docker-compose-language-service
    gopls
    marksman
    nixd
    # nixfmt
    nixfmt-tree
    vscode-langservers-extracted
    ruby-lsp
    solargraph
    terraform-ls
    typescript-language-server

    sleek # SQL formatter
  ];
}
