# ClawdBack notification/window-tracking hooks. Darwin-only: relies on
# ~/Applications/ClawdBack.app to remember which window/tab/Zellij pane
# Claude was running in, so a notification click can jump back to it. Import
# from Darwin hosts alongside programs/claude (currently espeon, pigeon).
{ ... }:

{
  # Links ~/.claude/hooks/{capture,notify,cleanup}. Stable paths so the
  # committed settings.json (programs/claude/default.nix) holds no rotating
  # /nix/store hash. Both current importers (espeon, pigeon) use the "hazel"
  # username, so settings.json's hardcoded /Users/hazel/.claude/hooks/* paths
  # hold for either.
  programs.clawd-back = {
    enable = true;
    hooks = "nushell";
  };
}
