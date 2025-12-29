{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) theme;
  inherit (theme) variant terminal;
  inherit (lib) lists;

  defaults = {
    size = 14;
    line_height = 1.4;
    light.normal = {
      weight = 500;
      stretch = "Normal";
    };
    dark.normal = {
      weight = 500;
      stretch = "Normal";
    };
  };

  font =
    defaults
    // {
      "Menlo" = {
        family = "MesloLGL Nerd Font";
        line_height = 1.0;
        light.normal.weight = 600;
      };
      "Monaco" = {
        family = "Monaco";
      };
      "DejaVu" = {
        family = "DejaVuSansM Nerd Font";
      };
      "Go" = {
        family = "GoMono Nerd Font";
      };
      "ShureTech" = {
        family = "ShureTechMono Nerd Font";
        size = defaults.size + 1.5;
      };
      "SF Mono" = {
        family = "SF Mono";
      };
      "Fira Mono" = {
        family = "Fira Mono";
      };
      "Fira Code" = {
        family = "FiraCode Nerd Font Mono";
      };
      "IBM Plex Mono" = {
        family = "BlexMono Nerd Font Mono";
        size = defaults.size + 0.5;
      };
      "Comic Mono" = {
        family = "Comic Mono";
      };
      "Intel Mono" = {
        family = "IntoneMono Nerd Font Propo";
        line_height = 1.0;
        light.normal = defaults.light.normal // {
          weight = 500;
        };
        dark.normal = defaults.dark.normal // {
          weight = 400;
        };
      };
      "DM Mono" = {
        family = "DM Mono";
      };
      "Hack" = {
        family = "Hack Nerd Font Mono";
      };
      "Victor Mono" = {
        family = "Victor Mono";
      };
      "JetBrains Mono" = {
        family = "JetBrainsMono Nerd Font Mono";
        size = 13;
        light.normal = defaults.light.normal // {
          weight = 600;
        };
        dark.normal = defaults.dark.normal // {
          weight = 500;
        };
      };
      "Cascadia Code" = {
        family = "CaskaydiaCove Nerd Font";
        size = defaults.size + 1.0;
      };
      "Zed Mono" = {
        family = "ZedMono Nerd Font";
        dark.normal = defaults.dark.normal // {
          weight = "Bold";
          stretch = "Expanded";
        };
        light.normal = defaults.light.normal // {
          weight = "Medium";
          stretch = "Expanded";
        };
      };
      "Inconsolata" = {
        family = "Inconsolata Nerd Font Mono";
        size = 15;
      };
    }
    .${theme.font.monospace};

  font_config =
    font:
    let
      normalVariant = if variant == "light" then font.light.normal else font.dark.normal;

      weight =
        if builtins.isString normalVariant.weight then
          "'${normalVariant.weight}'"
        else
          toString normalVariant.weight;

      options = "{weight=${weight}, stretch='${normalVariant.stretch}'}";
    in
    "wezterm.font('${font.family}', ${options})";

  fancy_tab_bar = use_custom: if use_custom then null else "config.use_fancy_tab_bar = false";

  background_variant_override =
    variant: if variant == "black" then "config.colors = { background = '#000000' }" else null;

  background_transparency =
    enabled:
    let
      text_opacity = "0.91";
      background_opacity = "0.81";
    in
    if enabled then
      ''
        config.window_background_opacity = ${background_opacity}
        config.text_background_opacity = ${text_opacity}
      ''
    else
      null;

  window_decorations =
    if pkgs.stdenv.isDarwin then "RESIZE|INTEGRATED_BUTTONS" else "RESIZE|INTEGRATED_BUTTONS";

  window_padding = {
    left = "'1cell'";
    right = "'1cell'";
    top = "'0.5cell'";
    bottom = "'0.0cell'";
  }
  // (if pkgs.stdenv.isDarwin then { top = "'65px'"; } else { });

  recompute_window_padding = ''
    function recompute_padding(window)
      local window_dims = window:get_dimensions()
      local overrides = window:get_config_overrides() or {}

      if not window_dims.is_full_screen then
        if
          overrides.window_padding
          and overrides.window_padding.left == ${window_padding.left}
        then
          -- padding is same, avoid triggering further changes
          return
        end

        overrides.window_padding = {
          left = ${window_padding.left},
          right = ${window_padding.right},
          top = ${window_padding.top},
          bottom = ${window_padding.bottom},
        }
      else
        overrides.window_padding = nil
      end

      window:set_config_overrides(overrides)
    end

    wezterm.on('window-resized', function(window, pane)
      recompute_padding(window)
    end)

    wezterm.on('window-config-reloaded', function(window)
      recompute_padding(window)
    end)
  '';

  color_scheme = ''
    -- wezterm.gui is not available to the mux server, so take care to
    -- do something reasonable when this config is evaluated by the mux
    function get_appearance()
      if wezterm.gui then
        return wezterm.gui.get_appearance()
      end
      return 'Dark'
    end

    function scheme_for_appearance(appearance)
      if appearance:find 'Dark' then
        return '${theme.wezterm.dark}'
      else
        return '${theme.wezterm.light}'
      end
    end

    config.color_scheme = scheme_for_appearance(get_appearance())
  '';
in
{
  programs.wezterm = {
    enable = true;
    colorSchemes = { };
    extraConfig = builtins.concatStringsSep "\n" (
      lists.filter (e: e != null) [
        ''
          local act = wezterm.action
          local config = {}
          config.initial_cols = 116
          config.initial_rows = 30
          config.font = ${font_config font}
          config.font_size = ${toString font.size}
          config.line_height = ${toString font.line_height}
          config.adjust_window_size_when_changing_font_size = false
          config.hide_tab_bar_if_only_one_tab = true
          config.tab_bar_at_bottom = true
          config.native_macos_fullscreen_mode = true
          config.window_decorations = "${window_decorations}"
          config.keys = {
            { key = '+', mods = 'SUPER', action = act.IncreaseFontSize },
            { key = 'f', mods = 'SUPER|CTRL', action = act.ToggleFullScreen },
          }
          config.window_close_confirmation = 'NeverPrompt'
        ''
        color_scheme
        (fancy_tab_bar true)
        (background_variant_override variant)
        (background_transparency terminal.transparency)
        recompute_window_padding
        "return config"
      ]
    );
  };
}
