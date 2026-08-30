use ../util.nu *
use ./util.nu *

# korriban has no sysfs backlight, and niri runs both on DRM and nested under
# moonshine, so the backend is chosen per keypress rather than configured.

const VCP_BRIGHTNESS = "10"
const CACHE_FILE = "niri-brightness-ddc.json"
# A display that answers, either way, is answering about itself and is believed
# until it is unplugged. A failed read says nothing, so it expires.
const UNREACHABLE_TTL = 5min

# Raise the focused output's brightness.
export def "brightness up" [step: int = 5]: nothing -> nothing {
  step-brightness $step
}

# Lower the focused output's brightness.
export def "brightness down" [step: int = 5]: nothing -> nothing {
  step-brightness (0 - $step)
}

# Probe DDC/CI on every connected output so the first keypress is not slow.
export def "brightness warm-cache" []: nothing -> nothing {
  connectors | each {|connector| ddc-target $connector } | ignore
}

# Report which backend each connected output would use.
export def "brightness status" []: nothing -> table {
  if (backlight-present) {
    return [{ output: "*", backend: "backlight", support: null, bus: null }]
  }

  connectors | each {|connector|
    let ddc = (ddc-support $connector)
    {
      output: $connector
      backend: (if $ddc.support == "supported" { "ddc" } else { "gamma" })
      support: $ddc.support
      bus: $ddc.bus
    }
  }
}

def step-brightness [delta: int]: nothing -> nothing {
  if (backlight-present) {
    return (backlight-step $delta)
  }

  let ddc = (
    match (focused-connector) {
      null => null
      $connector => (ddc-target $connector)
    }
  )

  match $ddc {
    null => (gamma-step $delta)
    $target => (ddc-step $target $delta)
  }
}

def backlight-present []: nothing -> bool {
  ("/sys/class/backlight" | path exists) and (glob "/sys/class/backlight/*" | is-not-empty)
}

# Noctalia already drives sysfs backlights, OSD included.
def backlight-step [delta: int]: nothing -> nothing {
  let command = if $delta > 0 { "brightness-up" } else { "brightness-down" }
  noctalia $command ($delta | math abs | into string)
}

def focused-connector []: nothing -> any {
  let focused = (^niri msg --json focused-output | complete)
  if $focused.exit_code != 0 { return null }

  $focused.stdout | from json | get -o name
}

# Connected DRM connectors, named as niri names its outputs.
def connectors []: nothing -> list<string> {
  glob --follow-symlinks "/sys/class/drm/card*-*/status"
  | where {|status| (open --raw $status | str trim) == "connected" }
  | each {|status|
      $status
      | path dirname
      | path basename
      | str replace --regex '^card\d+-' ''
    }
}

# The connector's ddc symlink points straight at its i2c bus, so the bus is
# cheap to resolve and never cached: only DDC support is.
def connector-bus [connector: string]: nothing -> any {
  glob --follow-symlinks $"/sys/class/drm/card*-($connector)/ddc"
  | each {|link| $link | path expand | path basename | field 'i2c-(?<v>\d+)' }
  | compact
  | get -o 0
}

# Keying the cache on the EDID makes a swapped display a miss, so hotplug needs
# no udev rule.
def connector-key [connector: string]: nothing -> any {
  let edid = (glob --follow-symlinks $"/sys/class/drm/card*-($connector)/edid" | get -o 0)
  if $edid == null { return null }

  let bytes = (open --raw $edid)
  if ($bytes | is-empty) { return null }

  $"($connector):($bytes | hash sha256)"
}

def ddc-target [connector: string]: nothing -> any {
  match (ddc-support $connector) {
    { support: "supported", bus: $bus } => ({ bus: $bus })
    _ => null
  }
}

# "asleep" and "no-bus" say nothing about the display, so neither is cached.
def ddc-support [connector: string]: nothing -> record {
  if not (installed ddcutil) { return ({ support: "no-bus", bus: null }) }

  let bus = (connector-bus $connector)
  let key = (connector-key $connector)
  if ($bus == null) or ($key == null) { return ({ support: "no-bus", bus: null }) }
  if not (awake $connector) { return ({ support: "asleep", bus: $bus }) }

  let support = (
    match (cached-support $key) {
      null => {
        let probed = (ddc-probe $bus)
        cache-write $key $probed
        $probed
      }
      $cached => $cached
    }
  )

  { support: $support, bus: $bus }
}

def ddc-probe [bus: string]: nothing -> string {
  let fields = (ddc-fields $bus)

  match ($fields | get -o 2) {
    "ERR" => "unreachable"
    _ => (if (vcp-value $fields) == null { "unsupported" } else { "supported" })
  }
}

# ddcutil exits 0 on a failed read, so its output is the only signal.
# --brief prints "VCP 10 C <current> <max>", or "VCP 10 ERR".
def ddc-fields [bus: string]: nothing -> list<string> {
  ^ddcutil --bus $bus --brief getvcp $VCP_BRIGHTNESS
  | complete
  | get stdout
  | str trim
  | split row --regex '\s+'
}

def vcp-value [fields: list<string>]: nothing -> any {
  if ($fields | length) < 5 { return null }

  try { { current: ($fields.3 | into int), max: ($fields.4 | into int) } } catch { null }
}

def ddc-read [bus: string]: nothing -> any {
  vcp-value (ddc-fields $bus)
}

def awake [connector: string]: nothing -> bool {
  let dpms = (glob --follow-symlinks $"/sys/class/drm/card*-($connector)/dpms" | get -o 0)
  if $dpms == null { return true }

  (open --raw $dpms | str trim) == "On"
}

def ddc-step [target: record, delta: int]: nothing -> nothing {
  let vcp = (ddc-read $target.bus)
  if $vcp == null { return (gamma-step $delta) }

  let percent = (clamp ((($vcp.current * 100) // $vcp.max) + $delta))
  ^ddcutil --bus $target.bus setvcp $VCP_BRIGHTNESS (
    ($percent * $vcp.max) // 100 | into string
  )
  noctalia brightness-osd ($percent | into string)
}

# The gamma daemon is the fallback that always works, including nested under
# moonshine where no output is a physical panel.
def gamma-step [delta: int]: nothing -> nothing {
  if not (gamma-ensure) { return }

  let percent = (clamp ((gamma-percent) + $delta))
  (^busctl --user --
    set-property rs.wl-gammarelay / rs.wl.gammarelay
    Brightness d ($percent / 100 | into string))
  noctalia brightness-osd ($percent | into string)
}

def gamma-percent []: nothing -> int {
  let property = (
    (^busctl --user --json=short --
      get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness)
    | complete
  )
  if $property.exit_code != 0 { return 100 }

  ($property.stdout | from json | get -o data | default 1.0) * 100 | math round
}

def gamma-ensure []: nothing -> bool {
  if not (installed wl-gammarelay-rs) { return false }
  if (gamma-running) { return true }

  ^setsid --fork wl-gammarelay-rs run
  # The daemon must own its bus name before the first set-property.
  for _ in 1..20 {
    sleep 50ms
    if (gamma-running) { return true }
  }
  false
}

def gamma-running []: nothing -> bool {
  (^busctl --user -- status rs.wl-gammarelay | complete).exit_code == 0
}

def installed [command: string]: nothing -> bool {
  which $command | is-not-empty
}

def clamp [percent: int]: nothing -> int {
  [([$percent, 0] | math max), 100] | math min
}

# The OSD is decoration; a missing shell must not fail the keypress.
def noctalia [...args: string]: nothing -> nothing {
  ^noctalia msg ...$args | complete | ignore
}

def cache-path []: nothing -> string {
  $env.XDG_RUNTIME_DIR? | default "/tmp" | path join $CACHE_FILE
}

def cache-read []: nothing -> record {
  let path = (cache-path)
  if not ($path | path exists) { return {} }

  try { open $path } catch { {} }
}

# Anything that is not a probe record is a miss, so a cache written by an older
# shape is ignored rather than trusted.
def cached-support [key: string]: nothing -> any {
  let entry = (cache-read | get -o $key)
  if ($entry | describe) !~ '^record' { return null }

  match ($entry | get -o support) {
    "unreachable" => (
      if ((date now) - ($entry.probed | into datetime)) > $UNREACHABLE_TTL { null } else { "unreachable" }
    )
    $support => $support
  }
}

def cache-write [key: string, support: string]: nothing -> nothing {
  cache-read
  | upsert $key ({ support: $support, probed: (date now) })
  | to json
  | save --force (cache-path)
}
