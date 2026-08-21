# System administration helpers.
#
# Auto-loaded on every host, with `--prefix`, so commands are namespaced:
#   system config     # open the nix-config Justfile menu
#   system jellyfin   # drop into the Jellyfin volume (pigeon)
#   system edit-me    # edit this overlay's source in the repo
#   system moonshine pair 1234  # answer a Moonlight pairing request (korriban)

const REPO = "~/.config/nix-config"
const PAIR_WINDOW = "-10 minutes"

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

# Answer moonshine's pending Moonlight pairing request (korriban only).
export def "moonshine pair" [
  pin: string # the four-digit PIN shown by the Moonlight client
]: nothing -> nothing {
  if (which journalctl | is-empty) {
    error make { msg: "moonshine runs on korriban; no journal to read here" }
  }
  if ($pin !~ '^\d{4}$') {
    error make { msg: $"PIN must be four digits, got '($pin)'" }
  }

  # A request expires, so only the recent journal counts, and a later
  # "registered" line means the last request is already answered.
  let last_event = (
    journalctl --unit moonshine --no-pager --output cat --since $PAIR_WINDOW
    | lines
    | where {|line| $line =~ 'Waiting for pin to be sent at|PIN registered successfully' }
    | last 1
  )
  if ($last_event | is-empty) or ($last_event.0 !~ 'Waiting for pin') {
    error make { msg: "No pairing request is waiting. Pair from Moonlight, then retry." }
  }

  let url = (
    $last_event.0
    | parse --regex 'sent at (?<url>http\S+)'
    | get url.0
    | url parse
  )
  let uniqueid = ($url.params | where key == uniqueid | get value.0)

  (http post
    --content-type application/x-www-form-urlencoded
    $"($url.scheme)://($url.host):($url.port)/submit-pin"
    { uniqueid: $uniqueid, pin: $pin })

  magenta $"Paired client ($uniqueid)."
}

# Edit this overlay's source file in the repo.
export def edit-me []: nothing -> nothing {
  let file = ($REPO | path expand | path join programs nushell overlays admin mod.nu)
  ^$env.EDITOR $file
}

def magenta [msg: string]: nothing -> nothing { print $"(ansi magenta)($msg)(ansi reset)" }
