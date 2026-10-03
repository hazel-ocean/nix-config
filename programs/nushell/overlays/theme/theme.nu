# Theme management over the nu_scripts themes at $env.NU_THEMES_DIR.
#
# Applying a theme needs `source` to keep its closure colors (bool/datetime/
# filesize), so every apply goes through a written snippet
# ($nu.data-dir/theme-active.nu). New shells source it from startup.nu. Live
# switches bump $env.NU_THEME_GENERATION, whose env_change string hook re-parses
# and sources the snippet before the next prompt.
#
# Two scopes per polarity. Global is the state file over the Nix defaults.
# Local is $env.NU_THEME_LOCAL_LIGHT/DARK: this shell and its children only.
# `reset` drops one scope's override at either level.
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

# Write the snippet config.nu sources at startup (full-fidelity apply). The
# block scopes the import: a bare `source` leaks the theme's `main`,
# `set color_config` and `update terminal` into the shell.
def write-active [name: string] {
  mkdir $nu.data-dir
  [
    'do --env {'
    $"  use \"(theme-path $name)\" ['set color_config' 'update terminal']"
    '  set color_config'
    '  update terminal'
    '}'
    ''
  ]
  | str join (char nl)
  | save -f (active-file)
}

# Apply the written snippet to the *current* shell at the next prompt. The
# env_change hook in startup.nu does the `source`.
def --env apply-live [name: string] {
  assert-theme $name
  $env.NU_THEME_ACTIVE_POLARITY = (detect-polarity)
  # A child nu inherits the counter from its parent as a string.
  $env.NU_THEME_GENERATION = (
    ($env.NU_THEME_GENERATION? | default 0 | into int) + 1
  )
}

# Current light/dark polarity:
#   1. $env.NU_THEME_POLARITY override (light|dark)
#   2. macOS: system appearance (defaults), which always answers
#   3. Terminal's own report, so a light terminal on a dark desktop themes light
#   4. Linux XDG colour-scheme
#   5. Nix host variant (dark/black -> dark, light -> light)
export def 'detect-polarity' []: nothing -> string {
  let override = ($env.NU_THEME_POLARITY? | default '' | str lowercase)
  if $override in ['light' 'dark'] { return $override }

  # The key is absent in light mode, so a failed read means light.
  if $nu.os-info.name == 'macos' {
    let r = (^defaults read -g AppleInterfaceStyle | complete)
    return (if $r.exit_code == 0 and ($r.stdout | str trim) == 'Dark' { 'dark' } else { 'light' })
  }

  let queried = (query-terminal-polarity)
  if $queried != '' { return $queried }

  # dconf is absent on darwin and on minimal Linux hosts.
  if (which dconf | is-not-empty) {
    let r = (^dconf read /org/gnome/desktop/interface/color-scheme | complete)
    let v = (if $r.exit_code == 0 { $r.stdout | str trim } else { '' })
    if ($v | str contains 'light') { return 'light' }
    if ($v | str contains 'dark') { return 'dark' }
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

def local-var [polarity: string]: nothing -> string {
  $'NU_THEME_LOCAL_($polarity | str uppercase)'
}

# Theme name that should be active for a polarity: local, else global.
export def 'resolve' [polarity?: string]: nothing -> string {
  let p = ($polarity | default (detect-polarity))
  $env
  | get -o (local-var $p)
  | default (read-state | get $p)
}

# Re-apply whatever `resolve` now returns, polarity flip or not.
def --env retheme [] {
  $env.NU_THEME_ACTIVE_POLARITY = ''
  sync
}

# Regenerate the startup snippet for the resolved theme. Called from env.nu
# before config.nu is parsed, so the file always exists to be sourced.
export def 'write-startup' [] {
  write-active (resolve)
}

def assert-theme [name: string] {
  if not ((theme-path $name) | path exists) {
    error make --unspanned { msg: $'unknown theme: ($name)' }
  }
}

# Persist a theme for the current polarity in every shell. A local theme for
# this polarity still wins in this shell.
export def --env 'global set' [name: string@list] {
  assert-theme $name
  let p = (detect-polarity)
  mkdir $nu.data-dir
  read-state | upsert $p $name | save -f (state-file)
  retheme
}

# Fuzzy-pick a theme, then set it globally.
export def --env 'global choose' []: nothing -> nothing {
  let pick = (list | input list --fuzzy 'theme')
  if ($pick | is-not-empty) { global set $pick }
}

# Drop the current polarity's global choice and revert to the Nix default.
export def --env 'global reset' [] {
  let p = (detect-polarity)
  let f = (state-file)
  if ($f | path exists) { open $f | reject -o $p | save -f $f }
  retheme
}

# Theme this shell and its children for the current polarity. Not persisted.
export def --env 'local set' [name: string@list] {
  assert-theme $name
  load-env { (local-var (detect-polarity)): $name }
  retheme
}

# Fuzzy-pick a theme, then set it locally.
export def --env 'local choose' []: nothing -> nothing {
  let pick = (list | input list --fuzzy 'theme')
  if ($pick | is-not-empty) { local set $pick }
}

# Drop this shell's local themes, so it follows the global ones.
export def --env 'reset' [] {
  hide-env -i NU_THEME_LOCAL_LIGHT NU_THEME_LOCAL_DARK
  retheme
}

# Pin this shell's polarity, or `auto` to resume detection.
export def --env 'polarity' [mode: string@[light dark auto]] {
  match $mode {
    'light' | 'dark' => { $env.NU_THEME_POLARITY = $mode }
    'auto' => { hide-env -i NU_THEME_POLARITY }
    _ => { error make --unspanned { msg: $'unknown polarity: ($mode)' } }
  }
  retheme
}

# DEC mode 2031 / DSR 996-997 (https://vtdn.dev/docs/decset/mode2031-color-scheme).
# Ghostty answers this; Zellij proxies it to inner panes as of 0.44.2.
# `trap` guarantees tty mode is restored even on failure: a stuck raw/no-echo
# terminal would be its own visible bug.
def query-terminal-raw []: nothing -> string {
  if not (is-terminal --stdout) { return '' }
  let script = r#'
    old=$(stty -g 2>/dev/null) || exit 1
    trap 'stty "$old" 2>/dev/null' EXIT
    stty raw -echo 2>/dev/null
    printf "\033[?996n" > /dev/tty 2>/dev/null
    IFS= read -r -t 0.2 -d n reply < /dev/tty 2>/dev/null
    printf "%s" "$reply"
  '#
  let result = (^bash -c $script | complete)
  if $result.exit_code != 0 { return '' }
  # `read -d n` eats the terminator: the reply arrives as `[?997;N`.
  (if ($result.stdout | str contains ';1') { 'dark' }
  else if ($result.stdout | str contains ';2') { 'light' }
  else { '' })
}

# A terminal that ignores DSR 996 never starts answering it, so the query costs
# the full read timeout on every prompt. env.nu probes once and caches the
# verdict; unset means query, so a shell that skipped env.nu still works.
def query-terminal-polarity []: nothing -> string {
  if ($env.NU_THEME_TERM_QUERY? | default 'yes') == 'no' { return '' }
  query-terminal-raw
}

# Seed the cache query-terminal-polarity reads. Called from env.nu, before the
# first `resolve`, so a shell pays the timeout once rather than once per prompt.
export def 'probe-terminal' []: nothing -> string {
  if (query-terminal-raw) == '' { 'no' } else { 'yes' }
}

# Zellij themes itself from the terminal's own colour-scheme notification, which
# Ghostty 1.3.1 does not deliver to every surface (ghostty-org/ghostty#8906). Its
# attach-time probe is sound, so only a live flip needs the nudge. Push the
# polarity we already resolved, which carries the desktop fallback zellij lacks.
def sync-zellij [polarity: string] {
  if ($env.ZELLIJ? | is-empty) or (which zellij | is-empty) { return }
  let action = if $polarity == 'light' { 'set-light-theme' } else { 'set-dark-theme' }
  ^zellij action $action | complete | ignore
}

# Re-theme when the polarity flipped since the last prompt (pre_prompt hook).
export def --env 'sync' [] {
  let p = (detect-polarity)
  if $p != ($env.NU_THEME_ACTIVE_POLARITY? | default '') {
    let name = (resolve $p)
    write-active $name
    apply-live $name
    sync-zellij $p
  }
}

# Show the active theme and polarity.
export def 'main' []: nothing -> record {
  {
    resolved: (resolve)
    polarity: (detect-polarity)
    global: (
      if ((state-file) | path exists) {
        open (state-file)
      } else {
        $'(ansi yellow)missing(ansi reset)'
      }
    )
    local: {
      light: ($env.NU_THEME_LOCAL_LIGHT? | default '')
      dark: ($env.NU_THEME_LOCAL_DARK? | default '')
    }
  }
}
