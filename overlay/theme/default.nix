{
  source ? null,
  ...
}@config:
let
  bat-themes = rec {
    standard.light = "GitHub";
    standard.dark = "Dracula";
    standard.black = "ansi";
    high-contrast.light = standard.light;
    high-contrast.dark = standard.dark;
    high-contrast.black = high-contrast.dark;
    gruvbox.light = "gruvbox-light";
    gruvbox.dark = "gruvbox-dark";
    gruvbox.black = gruvbox.dark;
    monalisa.dark = "base16";
    monalisa.black = monalisa.dark;
    nord.dark = "Nord";
  };

  helix-themes = rec {
    standard.light = "_papercolor-light";
    standard.dark = "_dracula";
    # standard.light = "_base16_terminal";
    # standard.dark =  "_base16_terminal";
    # standard.black = "_varua";
    # standard.black = "_papercolor-dark";
    # standard.black = "_base16_default_dark";
    # standard.black = "_pop-dark";
    # standard.black = "_iroaseta";
    standard.black = standard.dark;
    # standard.black = "_ayu_dark";
    high-contrast.light = "_papercolor-light";
    # high-contrast.dark = "curzon";
    high-contrast.dark = "_starlight";
    high-contrast.black = high-contrast.dark;
    gruvbox.light = "_gruvbox_light";
    gruvbox.dark = "_gruvbox";
    gruvbox.black = gruvbox.dark;
    monalisa.dark = "base16_parent";
    monalisa.black = monalisa.dark;
    nord.dark = "nord";
  };

  zellij-themes = rec {
    standard.light = "catppuccin-latte-custom";
    standard.dark = "one-half-dark-custom";
    standard.black = "dracula-custom";
    high-contrast.light = standard.light;
    high-contrast.dark = "dracula-custom";
    high-contrast.black = high-contrast.dark;
    gruvbox.light = "kanagawa";
    gruvbox.dark = "gruvbox-dark-medium";
    gruvbox.black = "gruvbox-dark-black";
    monalisa.dark = gruvbox.dark;
    monalisa.black = gruvbox.dark;
    nord.dark = "nord";
  };

  # nu_scripts theme stems (themes/nu-themes/<stem>.nu). Every host `name` must
  # map both light and dark, since Nushell resolves polarity at runtime;
  # `configuredTheme` throws on an unmapped name/variant.
  nushell-themes = rec {
    standard.light = "cupertino";
    standard.dark = "catppuccin-mocha";
    # standard.dark = "amora";
    # standard.dark = "dark-pastel";
    standard.black = "dark-pastel";
    high-contrast.light = standard.light;
    high-contrast.dark = standard.dark;
    high-contrast.black = high-contrast.dark;
    gruvbox.light = "gruvbox-light-medium";
    gruvbox.dark = "gruvbox-dark-medium";
    gruvbox.black = "gruvbox-dark-hard";
    monalisa.dark = "gruvbit";
    monalisa.black = monalisa.dark;
    nord.dark = "nord";
  };

  wezterm-themes = rec {
    standard.light = "Humanoid light (base16)";
    # standard.light = "Mexico Light (base16)";
    # standard.light = "iA Light (base16)";
    # standard.light = "Heetch Light (base16)";

    standard.dark = "Dracula+";
    # standard.dark = "Kolorit";

    # standard.dark = "Invisibone (terminal.sexy)";
    # standard.dark = "laserwave (Gogh)";
    # standard.dark = "hund (terminal.sexy)";
    # standard.dark = "Chalk (base16)";
    # standard.dark = "Horizon Dark (base16)";
    # standard.dark = "Sequoia Moonlight";
    # standard.dark = "Erebus (terminal.sexy)";

    standard.black = "Classic Dark (base16)";
    ## standard.black = "astromouse (terminal.sexy)";
    # standard.black = standard.dark;
    # standard.black = "Chalk (dark) (terminal.sexy)";
    # standard.black = "Bitmute (terminal.sexy)";

    high-contrast.light = standard.light;
    high-contrast.dark = "Bitmute (terminal.sexy)";
    high-contrast.black = high-contrast.dark;

    # gruvbox.light = "Gruvbox (Gogh)";
    gruvbox.light = "Gruvbox Light";
    # gruvbox.light = "Gruvbox light, hard (base16)";

    # gruvbox.dark = "Darktooth (base16)";
    # gruvbox.dark = "Gruvbox dark, pale (base16)";
    gruvbox.dark = "Gruvbox dark, medium (base16)";
    gruvbox.black = "Gruvbox dark, hard (base16)";

    monalisa.dark = "IC_Orange_PPL";
    monalisa.black = monalisa.dark;

    nord.dark = "nord";
  };

  selectTheme =
    programName: themeMap: name: variant:
    themeMap.${name}.${variant} or (
      let
        themeNames = builtins.attrNames themeMap;
        availableOptions = builtins.foldl' (
          acc: name:
          let
            nameVariants = builtins.attrNames themeMap.${name};
            expanded = builtins.map (variant: "  - ${name}.${variant}") nameVariants;
          in
          acc ++ expanded
        ) [ ] themeNames;
      in
      throw ''
        Unsupported name-variant combination for ${programName} theme: ${name}.${variant}
        Supported combinations:
        ${builtins.concatStringsSep "\n" availableOptions}
      ''
    );

  difftasticTheme =
    variant:
    let
      themeMap = {
        dark = "dark";
        black = "dark";
        light = "light";
      };
    in
    themeMap.${variant} or (throw ''
      Unsupported name-variant combination for difftastic theme: ${variant}
      Supported combinations:
      ${builtins.concatStringsSep "\n" (
        builtins.map (attrName: "  - ${attrName}") (builtins.attrNames themeMap)
      )}
    '');

  configuredTheme =
    opt@{
      name,
      variant,
      font,
      terminal,
      ...
    }:
    {
      inherit
        name
        variant
        font
        terminal
        ;

      helix = {
        dark = selectTheme "helix" helix-themes name "dark";
        light = selectTheme "helix" helix-themes name "light";
        fallback = opt.helix or (selectTheme "helix" helix-themes name variant);
      };
      zellij = selectTheme "zellij" zellij-themes name variant;
      bat = {
        dark = selectTheme "bat" bat-themes name "dark";
        light = selectTheme "bat" bat-themes name "light";
      };
      wezterm = {
        dark = selectTheme "wezterm" wezterm-themes name "dark";
        light = selectTheme "wezterm" wezterm-themes name "light";
      };
      # Nushell picks light vs dark at runtime, so both must resolve; an
      # unmapped name/variant throws (via selectTheme) like the other maps.
      nushell = {
        dark = selectTheme "nushell" nushell-themes name "dark";
        light = selectTheme "nushell" nushell-themes name "light";
      };
      delta = selectTheme "bat" bat-themes name variant;
      difftastic = difftasticTheme variant;
    };

  settings = if source != null then config // import source else config;
in
self: super: {
  theme = configuredTheme settings;
}
