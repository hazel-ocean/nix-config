{
  hostname,
  username,
  homeDirectory,
  stateVersion,
  imports ? [ ],
  ...
}:
{ lib, pkgs, ... }:
{
  imports = imports ++ [
    ./common.nix
    ../programs/nushell
    ../programs/tmux.nix
    ../programs/starship.nix
    ../programs/git
    ../programs/helix
    ../programs/zellij
    ../programs/wezterm
  ];

  xdg.enable = true;
  programs.home-manager.enable = true;

  home = {
    inherit stateVersion username homeDirectory;

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/scripts"
      "$HOME/.docker/bin"
    ];

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      TERM = "xterm-256color";

      # TODO: Refactor
      FZF_DEFAULT_COMMAND = "fd --type f";
      BAT_CONFIG_PATH = "${homeDirectory}/.config/bat/config";
    };

    # Bootstrap the key that system git+ssh flake auth expects at
    # ~/.ssh/id_ed25519, copying the fresh pubkey back into the repo. No-op
    # when the key already exists, so a committed pubkey is never clobbered.
    activation.ensureSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${lib.makeBinPath [ pkgs.openssh pkgs.coreutils ]}:$PATH"
      run ${pkgs.nushell}/bin/nu ${./scripts/ensure-ssh-key.nu} \
        --home ${homeDirectory} \
        --user ${username} \
        --host ${hostname} \
        --repo "${homeDirectory}/.config/nix-config"
    '';
  };
}
