final: prev:

let
  obsidian-plugins = import ../packages/obsidian-plugins { pkgs = prev; };
in
obsidian-plugins