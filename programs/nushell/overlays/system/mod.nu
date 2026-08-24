# System administration helpers.
#
# Auto-loaded on every host, with `--prefix`, so commands are namespaced:
#   system admin      # open the nix-config session in zellij
#   system apply      # switch this host to the current nix-config
#   system jellyfin   # drop into the Jellyfin volume (pigeon)
#   system edit-me    # edit this overlay's source in the repo
#   system moonshine pair 1234  # answer a Moonlight pairing request (korriban)
#   system access-point status  # radio, clients, country and rfkill (korriban)

const REPO = "~/.config/nix-config"
const AP_IFACE = "wlp11s0"
const PAIR_WINDOW = "-10 minutes"

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

# Report the access point's radio, clients and rfkill state (korriban only).
export def "access-point status" []: nothing -> record {
  access-point-guard

  {
    hostapd: (unit-state)
    rfkill: (rfkill-state)
    country: (reg-country)
    radio: (radio-info)
    clients: (station-dump)
  }
}

# Clear the rfkill block and start the access point (korriban only).
export def "access-point enable" []: nothing -> nothing {
  access-point-guard

  ^sudo systemctl reset-failed hostapd
  ^sudo systemctl start hostapd

  match (settled-state) {
    'active' => { magenta $'Access point up on ($AP_IFACE), country (reg-country).' }
    $state => {
      error make { msg: $'hostapd is ($state); see journalctl --unit hostapd' }
    }
  }
}

# systemctl start returns as soon as hostapd forks, several hundred
# milliseconds before it gives up on the radio.
def settled-state []: nothing -> string {
  for _ in 1..10 {
    sleep 300ms
    let state = (unit-state)
    if $state != 'active' { return $state }
  }
  'active'
}

def reg-country []: nothing -> string {
  let reg = (^iw reg get | complete)
  if $reg.exit_code != 0 { return 'unknown' }

  $reg.stdout
  | split row --regex '(?m)^phy#'
  | last
  | field 'country (?<v>\w{2})'
  | default 'unknown'
}

def access-point-guard []: nothing -> nothing {
  if not ($'/sys/class/net/($AP_IFACE)' | path exists) {
    error make { msg: $'($AP_IFACE) not found; the access point runs on korriban' }
  }
}

def unit-state []: nothing -> string {
  (^systemctl is-active hostapd | complete).stdout | str trim
}

def rfkill-state []: nothing -> string {
  let wlan = (
    ^rfkill --json
    | from json
    | get rfkilldevices
    | where type == wlan
  )
  if ($wlan | is-empty) { 'unknown' } else { $wlan.0.soft }
}

def radio-info []: nothing -> record {
  let info = (^iw dev $AP_IFACE info | complete)
  if $info.exit_code != 0 { return {} }

  {
    ssid: ($info.stdout | field 'ssid (?<v>.+)')
    mode: ($info.stdout | field 'type (?<v>\w+)')
    channel: ($info.stdout | field 'channel (?<v>.+)')
    txpower: ($info.stdout | field 'txpower (?<v>.+)')
  }
}

def station-dump []: nothing -> table {
  let dump = (^iw dev $AP_IFACE station dump | complete)
  if $dump.exit_code != 0 { return [] }

  $dump.stdout
  | split row --regex '(?m)^Station '
  | skip 1
  | each {|station|
      {
        mac: ($station | field '(?<v>[0-9a-f:]{17})')
        tx: ($station | field r#'tx bitrate:\s+(?<v>[\d.]+ MBit/s)'#)
        rx: ($station | field r#'rx bitrate:\s+(?<v>[\d.]+ MBit/s)'#)
        signal: ($station | field r#'last ack signal:\s*(?<v>-?\d+ dBm)'#)
        connected: (
          $station
          | field r#'connected time:\s+(?<v>\d+)'#
          | default '0'
          | $'($in)sec'
          | into duration
        )
      }
    }
}

def field [pattern: string]: string -> any {
  $in | parse --regex $pattern | get v.0?
}

# Edit this overlay's source file in the repo.
export def edit-me []: nothing -> nothing {
  let file = ($REPO | path expand | path join programs nushell overlays system mod.nu)
  ^$env.EDITOR $file
}

def magenta [msg: string]: nothing -> nothing { print $"(ansi magenta)($msg)(ansi reset)" }
