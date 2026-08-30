use ../util.nu *
use ./util.nu *

# korriban has no sysfs backlight, and niri runs both on DRM and nested under
# moonshine, so the backend is chosen per keypress rather than configured.

const VCP_BRIGHTNESS = "10"
const CACHE_FILE = "niri-brightness-ddc.json"

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
    return [{ output: "*", backend: "backlight", bus: null }]
  }

  connectors | each {|connector|
    let ddc = (ddc-target $connector)
    {
      output: $connector
      backend: (if $ddc == null { "gamma" } else { "ddc" })
      bus: ($ddc | get -o bus)
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
  if not (installed ddcutil) { return null }

  let bus = (connector-bus $connector)
  let key = (connector-key $connector)
  if ($bus == null) or ($key == null) { return null }

  let supported = (
    match (cache-read | get -o $key) {
      null => {
        let probed = ((ddc-read $bus) != null)
        cache-write $key $probed
        $probed
      }
      $cached => $cached
    }
  )

  if $supported { { bus: $bus } } else { null }
}

def ddc-read [bus: string]: nothing -> any {
  let vcp = (^ddcutil --bus $bus --brief getvcp $VCP_BRIGHTNESS | complete)
  if $vcp.exit_code != 0 { return null }

  # --brief prints "VCP 10 C <current> <max>".
  let fields = ($vcp.stdout | str trim | split row --regex '\s+')
  if ($fields | length) < 5 { return null }

  { current: ($fields.3 | into int), max: ($fields.4 | into int) }
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

def cache-write [key: string, supported: bool]: nothing -> nothing {
  cache-read | upsert $key $supported | to json | save --force (cache-path)
}
