{ pkgs }:
let
  inherit (pkgs.lib) attrValues filter isDerivation;
in
(with pkgs; [
  google-fonts
  inter
  maple-mono.NF-unhinted
  monocraft
  victor-mono
])
# nerd-fonts also carries override/overrideDerivation/recurseForDerivations.
++ filter isDerivation (attrValues pkgs.nerd-fonts)
