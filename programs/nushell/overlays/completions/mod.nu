# nu_scripts custom-completions, loaded for the commands on PATH.

# config.nu sources this file, so its path must match there.
const active_file = $nu.data-dir | path join "completions-active.nu"

def index []: nothing -> table {
  open --raw $env.NU_COMPLETIONS_INDEX | from json
}

def installed-commands [modules: table]: nothing -> list<string> {
  which ...($modules | get commands | flatten | uniq)
  | where type == external
  | get command
}

# Write the loader that config.nu sources, for modules with an installed command.
export def write-startup [] {
  let modules = index
  let found = installed-commands $modules
  mkdir ($active_file | path dirname)
  $modules
  | where { $in.commands | any {|c| $c in $found } }
  | each {|m|
    match $m.load {
      'use' => $"use '($m.path)' *"
      'source' => $"source '($m.path)'"
    }
  }
  | str join "\n"
  | save --force $active_file
}

# List the completion modules and whether a command of each is installed.
export def list []: nothing -> table {
  let modules = index
  let found = installed-commands $modules
  $modules
  | insert installed { $in.commands | any {|c| $c in $found } }
  | select name commands load installed
}
