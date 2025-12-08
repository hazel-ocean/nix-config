{ pkgs }:
let
  nerd-fonts = pkgs.nerd-fonts;
in
(with pkgs; [
  victor-mono
  inter
])
++ (with nerd-fonts; [
  bigblue-terminal
  blex-mono
  caskaydia-cove
  dejavu-sans-mono
  fira-code
  go-mono
  hack
  inconsolata
  intone-mono
  jetbrains-mono
  meslo-lg
  zed-mono
])
