# System administration helpers, namespaced as `system *` on every host.
# Host-specific commands live in <hostname>.nu beside this file and join the
# same namespace on that host only.

const REPO = "~/.config/nix-config"

# Open the nix-config session in zellij.
export def admin []: nothing -> nothing {
  cd ($REPO | path expand)
  clear -k
  zellij attach --create nix-config
}

# Build and switch this host to the current nix-config.
export def apply []: nothing -> nothing {
  cd ($REPO | path expand)
  just apply
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

# Edit this overlay's sources in the repo.
export def edit-me []: nothing -> nothing {
  let dir = ($REPO | path expand | path join programs nushell overlays system)
  ^$env.EDITOR $dir
}
