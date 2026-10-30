# ClawdBack notification/window-tracking hooks. Darwin-only: relies on
# ~/Applications/ClawdBack.app to remember which window/tab/Zellij pane
# Claude was running in, so a notification click can jump back to it. Import
# from Darwin hosts alongside programs/claude (currently espeon, pigeon).
{ pkgs, config, lib, ... }:

let
  hooks = "${pkgs.clawd-back.hooks.nushell}/libexec/clawd-back";
in
{
  # Stable paths so the committed settings.json (programs/claude/default.nix)
  # holds no rotating /nix/store hash; Nix refreshes the targets on each
  # switch. Both current importers (espeon, pigeon) use the "hazel" username,
  # so settings.json's hardcoded /Users/hazel/.claude/hooks/* paths hold for
  # either.
  home.file.".claude/hooks/notify".source = "${hooks}/notify";
  home.file.".claude/hooks/capture".source = "${hooks}/capture";
  home.file.".claude/hooks/cleanup".source = "${hooks}/cleanup";

  # Install the notifier where LaunchServices can find it: a real copy in
  # ~/Applications (not a /nix/store symlink, whose path rotates each rebuild),
  # chmod'd writable, ad-hoc re-signed, and registered so a notification click
  # relaunches it by bundle id.
  home.activation.installClawdBack = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/Applications/ClawdBack.app"
    run rm -rf "$dest"
    run mkdir -p "$HOME/Applications"
    run cp -RL ${pkgs.clawd-back}/Applications/ClawdBack.app "$dest"
    run chmod -R u+w "$dest"
    run /usr/bin/codesign --force --sign - "$dest"
    run /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$dest"
  '';
}
