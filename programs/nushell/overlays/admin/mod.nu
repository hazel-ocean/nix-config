# System administration helpers.
#
# Auto-loaded on Darwin hosts, with `--prefix`, so commands are namespaced:
#   admin config     # open the nix-config Justfile menu
#   admin jellyfin   # drop into the Jellyfin volume (pigeon)
#   admin edit-me    # edit this overlay's source in the repo

const REPO = "~/.config/nix-config"

# Change directories and edit nix-config.
export def nix-config []: nothing -> nothing {
  cd ($REPO | path expand)
  clear -k
  zellij attach --create nix-config
}

# Drop into the Jellyfin volume with its Justfile listed (pigeon only).
export def jellyfin []: nothing -> nothing {
  let volume = "/Volumes/Jellyfin"
  if not ($volume | path exists) {
    error make { msg: $"Jellyfin volume not mounted at ($volume)" }
  }
  cd $volume
  clear -k
  magenta "Starting interactive shell..."
  ^nu --execute 'just --list'
}

# Edit this overlay's source file in the repo.
export def edit-me []: nothing -> nothing {
  let file = ($REPO | path expand | path join programs nushell overlays admin mod.nu)
  ^$env.EDITOR $file
}

def magenta [msg: string]: nothing -> nothing { print $"(ansi magenta)($msg)(ansi reset)" }
