# System administration helpers, namespaced as `system *` on every host.
# Host-specific commands live in <hostname>.nu beside this file and join the
# same namespace on that host only.

const REPO = "~/.config/nix-config"
const KORRIBAN_LAN = "192.168.5.83"
const INITRD_SSH_PORT = 2222

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

def port-open [host: string, port: int]: nothing -> bool {
  let args = match $nu.os-info.name {
    "macos" => [-z -G 2 $host $port]
    _ => [-z -w 2 $host $port]
  }
  (^nc ...$args | complete).exit_code == 0
}

def ssh-ready [host: string]: nothing -> bool {
  let result = (
    ^ssh -o BatchMode=yes -o ConnectTimeout=5 $host true
    | complete
  )
  $result.exit_code == 0
}

# Wait for korriban's initrd on the LAN, then enter the LUKS passphrase.
export def "korriban unlock" [
  --host: string = $KORRIBAN_LAN
  --ssh-host: string = "korriban"
  --timeout: duration = 5min
]: nothing -> nothing {
  let deadline = (date now) + $timeout
  print $"Waiting for ($host):($INITRD_SSH_PORT)..."
  while not (port-open $host $INITRD_SSH_PORT) {
    if (date now) > $deadline {
      error make {
        msg: $"korriban initrd not reachable after ($timeout)"
      }
    }
    sleep 2sec
  }
  # The initrd sshd drops the session when it switches root.
  # The exit code is non-zero either way, so a real login is the signal.
  try {
    ^ssh -t -p $INITRD_SSH_PORT $"root@($host)"
  }
  # sshd.socket listens on the LAN seconds after switch-root, long before
  # Tailscale is up, so an open port 22 does not mean `ssh korriban` works.
  print $"Waiting for ssh ($ssh_host)..."
  let boot_deadline = (date now) + 2min
  mut booted = (ssh-ready $ssh_host)
  while not $booted and (date now) < $boot_deadline {
    sleep 2sec
    $booted = (ssh-ready $ssh_host)
  }
  if $booted {
    print $"(ansi green)korriban unlocked and booted(ansi reset)"
  } else {
    print $"(ansi red)ssh ($ssh_host) failed for 2min after unlock(ansi reset)"
  }
}
