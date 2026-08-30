use ../util.nu *
use ./util.nu *

const AP_IFACE = "wlp11s0"

# Report the access point's radio, clients and rfkill state.
export def "access-point status" []: nothing -> record {
  {
    hostapd: (unit-state)
    rfkill: (rfkill-state)
    country: (reg-country)
    radio: (radio-info)
    clients: (station-dump)
  }
}

# Clear the rfkill block and start the access point.
export def "access-point enable" []: nothing -> nothing {
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
