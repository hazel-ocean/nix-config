# System administration helpers.
#
# Auto-loaded on Darwin hosts, with `--prefix`, so commands are namespaced:
#   system config     # open the nix-config Justfile menu
#   system jellyfin   # drop into the Jellyfin volume (pigeon)
#   system edit-me    # edit this overlay's source in the repo

const REPO = "~/.config/nix-config"

# Change directories and edit nix-config.
export def nix-config []: nothing -> nothing {
  cd ($REPO | path expand)
  clear -k
  zellij attach --create nix-config
}

def aliases-for []: nothing -> list<string> {[ nushell ]}

# Edit aliases available to the shell to be available on next session
export def aliases [--shell: string@aliases-for]: nothing -> nothing {
  cd ($REPO | path expand)
  let config_file = fd --full-path 'nushell/default.nix'
  let location = (
    rg 'aliases = \{' $config_file --line-number --column
    | split row ':'
    | take 2
    | str join ':'
  )
  hx $"($config_file):($location)"

  let key = do {
    print --no-newline "Apply changes? (y/N) > "
    (input listen --timeout 20sec --types [key]).code
  }
  print $key
  match $key {
    'y' => { just apply },
    _ => { }
  }
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
