{ pkgs }:
let
  nerd-fonts = pkgs.nerd-fonts;
in
(with pkgs; [
  maple-mono.NF-unhinted
  monocraft
  victor-mono
  inter
])
++ (with nerd-fonts; [
  _0xproto
  bigblue-terminal
  blex-mono
  caskaydia-cove
  dejavu-sans-mono
  fantasque-sans-mono
  fira-code
  go-mono
  hack
  inconsolata
  intone-mono
  jetbrains-mono
  meslo-lg
  zed-mono
])
