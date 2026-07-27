set shell := ["nu", "-c"]

z_session := "nix-config"

_default:
    @clear; just --list --unsorted

# Start a Zellij session to make quick edits
edit: && _cleanup
    @zellij \
          --config-dir=($"($env.HOME)/.config/zellij") \
          --layout=zellij-layout.kdl \
        attach {{ z_session }} \
          --force-run-commands \
          --create

alias switch := apply

# Applies the host's config
apply:
    @just $"_switch_(hostname)"

# Creates a new boot entry for the host's config
boot:
    @just $"_boot_(hostname)"

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

# Rebuilds on file changes, debouncing bursts and restarting on interrupting edits
watch:
    @watchexec \
        --postpone \
        --restart \
        --debounce=500ms \
        --clear \
        --ignore='programs/zed/config/**' \
        --ignore='host/*/scripts/**' \
        --ignore='justfile' \
      -- 'sudo --reset-timestamp; just apply; echo Done'

_cleanup:
    zellij delete-session {{ z_session }}

_switch_pigeon:
    sudo darwin-rebuild switch --flake .#pigeon

_switch_espeon:
    sudo darwin-rebuild switch --flake .#espeon

_switch_korriban:
    sudo nixos-rebuild switch --flake .#korriban

_boot_korriban:
    sudo nixos-rebuild boot --flake .#korriban
