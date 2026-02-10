{ pkgs, nix-darwin }:
let
  inherit (pkgs) lib stdenv mkShell;
in
mkShell {
  buildInputs = with pkgs; [
    helix
    ripgrep
    yazi
    fd
    bat
    tmux
    just
    ncurses
    git
    entr
  ] ++ lib.optionals stdenv.isDarwin [ nix-darwin.packages.${stdenv.hostPlatform.system}.default ];
}
