z_session := "nix-config"

_default:
    @clear -x; just --list --unsorted

# Start a Zellij session to make quick edits
edit: && _cleanup
    @zellij \
    		--config-dir=$HOME/.config/zellij \
    		--layout=zellij-layout.kdl \
    	attach {{ z_session }} \
    		--force-run-commands \
    		--create

alias rebuild := apply

# Runs the `just` target for the current host to apply the current config
apply target=`hostname`:
    just {{ target }} apply

# Runs the `just` target for the current host to create a new boot entry
boot target=`hostname`:
    just {{ target }} boot

# Runs the `just` target for the current host to apply the NixOS configuration
switch target=`hostname`:
    just {{ target }} switch

dev *recipe:
    nix develop --command just {{ recipe }}

# Update flake.lock
update:
    nix flake update

# Download and start a NixOS builder container
darwin-builder:
    nix run nixpkgs#darwin.builder

# Upgrade installed Homebrew formulas
brew-upgrade:
    brew update --force
    brew upgrade --greedy-latest

_theme host=`hostname`:
    @hx --config ./programs/helix/basic-config.toml \
        --hsplit \
    	./host/{{ host }}/configuration.nix \
    	./host/{{ host }}/theme.nix:3:14

# Runs the `just` target when file changes are detected
watch:
    @echo "Watching for changes..."
    @fd --exclude=programs/zed/config \
        --exclude=host/*/scripts \
        --exclude=Justfile \
      | entr -pc sh -c 'just apply && echo Done'

_cleanup:
    zellij delete-session {{ z_session }}

[private]
pigeon cmd:
    sudo darwin-rebuild {{ cmd }} --flake .#pigeon

[private]
espeon cmd:
    sudo darwin-rebuild {{ cmd }} --flake .#espeon

[private]
korriban cmd:
    sudo nixos-rebuild {{ cmd }} --flake .#korriban

[private]
ghastly cmd:
    sudo nixos-rebuild {{ cmd }} --flake .#ghastly
