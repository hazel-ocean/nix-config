{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) strings;
  inherit (pkgs) stdenv theme zellijPlugins room;

  configText = ''
    theme_dark "${theme.zellij.dark}"
    theme_light "${theme.zellij.light}"
    ${strings.optionalString stdenv.hostPlatform.isDarwin ''copy_command "pbcopy"''}
    ${builtins.readFile ./config.kdl}

    plugins {
      room location="file:${room}/lib/zellij/plugins/room.wasm"
      // Palette names, not hex: zjstatus cannot read the zellij theme
      // (dj95/zjstatus#12), but index 7/8 track the terminal foreground and dim
      // grey, which Ghostty repaints on a light/dark switch.
      zjstatus location="file:${zellijPlugins.zjstatus}" {
        format_left  "{mode} #[fg=blue,bold]{session} {tabs}"
        // format_right "{command_git_branch} {datetime}"
        format_right "{datetime}"
        format_space ""

        border_enabled  "false"
        border_char     "─"
        border_format   "#[fg=bright_black]{char}"
        border_position "top"

        mode_normal        "#[bg=] {name} "
        mode_locked        "#[bg=] {name} "
        mode_resize        "#[bg=] {name} "
        mode_pane          "#[bg=] {name} "
        mode_tab           "#[bg=] {name} "
        mode_scroll        "#[bg=] {name} "
        mode_enter_search  "#[bg=] {name} "
        mode_search        "#[bg=] {name} "
        mode_rename_tab    "#[bg=] {name} "
        mode_rename_pane   "#[bg=] {name} "
        mode_session       "#[bg=] {name} "
        mode_move          "#[bg=] {name} "
        mode_prompt        "#[bg=] {name} "
        mode_tmux          "#[bg=] {name} "

        tab_normal   "#[fg=bright_black] {name} "
        tab_active   "#[fg=white,bold,italic] {name} "

        command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
        command_git_branch_format      "#[fg=blue] {stdout} "
        command_git_branch_interval    "10"
        command_git_branch_rendermode  "static"

        datetime        "#[fg=bright_black,bold] {format} "
        datetime_format "%A, %d %b %Y %H:%M"
        datetime_timezone "America/Los_Angeles"
      }
    }
  '';
in
{
  programs.zellij.enable = true;

  xdg.configFile = {
    "zellij/layouts/default.kdl".source = ./zjstatus_layout.kdl;
    "zellij/config.kdl".text = configText;
  };
}
