{ lib, ... }:
let
  source = "$HOME/.config/nix-config/programs/zed/config";
  target = "$HOME/.config/zed";
in
{
  home.activation.linkZedConfiguration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${source}

    run ln -fsn $VERBOSE_ARG \
        ${source}/* ${target}/
  '';
}
