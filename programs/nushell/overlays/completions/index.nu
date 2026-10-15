# Build-time index of nu_scripts custom-completions: how each module loads and
# which commands it completes. Modules that fail to parse are left out.

# Each probe runs in its own nu, because a parse error is fatal to the parser.
def probe [load: string, file: string]: nothing -> list<string> {
  let import = match $load {
    'use' => $"use '($file)' *"
    'source' => $"source '($file)'"
  }
  let result = do {
    ^$nu.current-exe -n --no-std-lib -c $"($import); scope externs | get name | to json"
  } | complete
  if $result.exit_code != 0 {
    return []
  }
  $result.stdout
  | from json
  | each { split row ' ' | first }
  | uniq
}

# Some modules declare a bare `extern`, which only `source` brings into scope.
def entry [dir: path]: nothing -> any {
  let name = $dir | path basename
  let file = $dir | path join $"($name)-completions.nu"
  if not ($file | path exists) {
    return null
  }
  ['use' 'source']
  | each {|load| { name: $name, path: $file, load: $load, commands: (probe $load $file) } }
  | where { $in.commands | is-not-empty }
  | first 1
  | get 0?
}

def main [root: path, ...excluded: string] {
  ls $root
  | where type == dir
  | get name
  | where { ($in | path basename) not-in $excluded }
  | each {|dir| entry $dir }
  | compact
  | to json
}
