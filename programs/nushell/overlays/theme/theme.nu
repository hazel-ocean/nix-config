# Theme management over the nu_scripts themes at $env.NU_THEMES_DIR.
#
# Full-fidelity apply needs a parse-time `source`, so new shells source a written
# snippet ($nu.data-dir/theme-active.nu). Live switches instead go through a child
# `nu` and lose the theme's closure colors (bool/datetime/filesize), which can't
# cross a process boundary; the next shell restores them.
#
# Loaded with `--prefix`: `main` -> `theme`, subcommands -> `theme <sub>`.

def themes-dir []: nothing -> string { $env.NU_THEMES_DIR }
def state-file []: nothing -> string { $nu.data-dir | path join 'theme-state.nuon' }
def active-file []: nothing -> string { $nu.data-dir | path join 'theme-active.nu' }
def theme-path [name: string]: nothing -> string { themes-dir | path join $'($name).nu' }
def screenshots-dir []: nothing -> string { themes-dir | path dirname | path join 'screenshots' }

def defaults []: nothing -> record {
  { light: $env.NU_THEME_DEFAULT_LIGHT, dark: $env.NU_THEME_DEFAULT_DARK }
}

# Persisted per-polarity choices merged over the Nix defaults.
def read-state []: nothing -> record {
  let f = (state-file)
  if ($f | path exists) { defaults | merge (open $f) } else { defaults }
}

# Write the snippet config.nu sources at startup (full-fidelity apply).
def write-active [name: string] {
  mkdir $nu.data-dir
  $'source "(theme-path $name)"(char nl)' | save -f (active-file)
}

# Apply a theme to the *current* shell. Closure-valued colors are dropped (they
# can't be serialized out of the child `nu`); the next shell restores them.
def --env apply-live [name: string] {
  let path = (theme-path $name)
  if not ($path | path exists) {
    error make { msg: $'unknown theme: ($name)' }
  }
  let strip = (r#'| items {|k, v| {k: $k, v: $v} } | where ($in.v | describe) != closure | transpose -rd | to nuon'#)
  $env.config.color_config = (^nu --no-config-file -c $"use '($path)'; ($name) ($strip)" | from nuon)
  ^nu --no-config-file -c $"use '($path)'; ($name) update terminal"
  $env.NU_THEME_ACTIVE = $name
  $env.NU_THEME_ACTIVE_POLARITY = (detect-polarity)
}

# Current light/dark polarity:
#   1. $env.NU_THEME_POLARITY override (light|dark), for Linux / other DEs
#   2. macOS system appearance
#   3. Nix host variant (dark/black -> dark, light -> light)
export def 'detect-polarity' []: nothing -> string {
  let override = ($env.NU_THEME_POLARITY? | default '' | str lowercase)
  if $override in ['light' 'dark'] { return $override }

  if $nu.os-info.name == 'macos' {
    let r = (^defaults read -g AppleInterfaceStyle | complete)
    return (if $r.exit_code == 0 and ($r.stdout | str trim) == 'Dark' { 'dark' } else { 'light' })
  }

  if ($env.NU_THEME_HOST_VARIANT? | default 'dark') == 'light' { 'light' } else { 'dark' }
}

# Every installable theme name.
export def 'list' []: nothing -> list<string> {
  glob $'(themes-dir)/*.nu' | path parse | get stem | sort
}

# Browse the per-theme screenshots in the system file manager.
export def 'explore' []: nothing -> nothing {
  if $nu.os-info.name == 'macos' {
    ^open (screenshots-dir)
  } else {
    ^xdg-open (screenshots-dir)
  }
}

# Theme name that should be active for a polarity (persisted choice or default).
export def 'resolve' [polarity?: string]: nothing -> string {
  read-state | get ($polarity | default (detect-polarity))
}

# Regenerate the startup snippet for the resolved theme. Called from env.nu
# before config.nu is parsed, so the file always exists to be sourced.
export def 'write-startup' [] {
  write-active (resolve)
}

# Switch this shell to a theme and persist it for the current polarity.
export def --env 'set' [name: string] {
  if not ((theme-path $name) | path exists) {
    error make { msg: $'unknown theme: ($name)' }
  }
  let p = (detect-polarity)
  mkdir $nu.data-dir
  read-state | upsert $p $name | save -f (state-file)
  write-active $name
  apply-live $name
}

# Fuzzy-pick a theme, then set it.
export def --env 'choose' []: nothing -> nothing {
  let pick = (list | input list --fuzzy 'theme')
  if ($pick | is-not-empty) { set $pick }
}

# Drop the current polarity's override and revert to the Nix default.
export def --env 'reset' [] {
  let p = (detect-polarity)
  let f = (state-file)
  if ($f | path exists) { open $f | reject $p | save -f $f }
  let name = (defaults | get $p)
  write-active $name
  apply-live $name
}

# DEC mode 2031 / DSR 996-997 (https://vtdn.dev/docs/decset/mode2031-color-scheme).
# Ghostty answers this; Zellij proxies it to inner panes as of 0.44.2.
# `trap` guarantees tty mode is restored even on failure: a stuck raw/no-echo
# terminal would be its own visible bug.
def query-terminal-polarity []: nothing -> string {
  if not (is-terminal --stdout) { return '' }
  let script = '
    old=$(stty -g 2>/dev/null) || exit 1
    trap '"'"'stty "$old" 2>/dev/null'"'"' EXIT
    stty raw -echo 2>/dev/null
    printf "\033[?996n" > /dev/tty 2>/dev/null
    IFS= read -r -t 0.2 -d n reply < /dev/tty 2>/dev/null
    printf "%s" "$reply"
  '
  let result = (^bash -c $script | complete)
  if $result.exit_code != 0 { return '' }
  if ($result.stdout | str contains ';1n') { 'dark' }
  else if ($result.stdout | str contains ';2n') { 'light' }
  else { '' }
}

# Re-theme when the polarity flipped since the last prompt (pre_prompt hook).
# Prefers the live terminal query above; falls back to detect-polarity's
# defaults-read/host-variant logic when the terminal doesn't answer.
export def --env 'sync' [] {
  let queried = (query-terminal-polarity)
  let p = if $queried != '' { $queried } else { detect-polarity }
  if $p != ($env.NU_THEME_ACTIVE_POLARITY? | default '') {
    let name = (resolve $p)
    write-active $name
    apply-live $name
  }
}

# Show the active theme and polarity.
export def 'main' []: nothing -> record {
  {
    active: ($env.NU_THEME_ACTIVE? | default '(startup default)')
    polarity: (detect-polarity)
    resolved: (resolve)
    state-file: (state-file)
  }
}
