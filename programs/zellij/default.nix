{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) strings;
  inherit (pkgs) stdenv theme zellijPlugins room;

  configText = ''
    theme "${theme.zellij}"
    ${strings.optionalString stdenv.hostPlatform.isDarwin ''copy_command "pbcopy"''}
    ${builtins.readFile ./config.kdl}

    plugins {
      room location="file:${room}/lib/zellij/plugins/room.wasm"
      zjstatus location="file:${zellijPlugins.zjstatus}" {
        format_left  "{mode} #[fg=#89B4FA,bold]{session} {tabs}"
        // format_right "{command_git_branch} {datetime}"
        format_right "{datetime}"
        format_space ""

        border_enabled  "false"
        border_char     "─"
        border_format   "#[fg=#6C7086]{char}"
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

        tab_normal   "#[fg=#6C7086] {name} "
        tab_active   "#[fg=#9399B2,bold,italic] {name} "

        command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
        command_git_branch_format      "#[fg=blue] {stdout} "
        command_git_branch_interval    "10"
        command_git_branch_rendermode  "static"

        datetime        "#[fg=#6C7086,bold] {format} "
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
