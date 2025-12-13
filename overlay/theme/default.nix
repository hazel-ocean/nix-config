{
  source ? null,
  name ? "standard",
  variant ? "dark",
  font ? {
    monospace = "DejaVu";
  },
  terminal ? {
    transparency = false;
  },
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
    # standard.light = "_flatwhite";
    standard.light = "_papercolor-light";
    standard.dark = "_dracula";
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
    standard.light = "catppuccin-latte";
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

      helix = opt.helix or (selectTheme "helix" helix-themes name variant);
      zellij = selectTheme "zellij" zellij-themes name variant;
      bat = {
        dark = selectTheme "bat" bat-themes name "dark";
        light = selectTheme "bat" bat-themes name "light";
      };
      wezterm = selectTheme "wezterm" wezterm-themes name variant;
      delta = selectTheme "bat" bat-themes name variant;
      difftastic = difftasticTheme variant;
    };

  settings = if source != null then config // import source else config;
in
self: super: {
  theme = configuredTheme settings;
}
