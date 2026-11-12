# Load a project's `.env.nu` while the shell is inside the project.
#
# A project is a directory with a `.env.nu`. Projects nest: before every
# prompt, the hook loads each allowed project that contains the current
# directory, outermost first. It unloads a project when the directory
# leaves it, or when its `.env.nu` is removed, edited or disallowed.
#
# The hook sources `.env.nu` into the shell, so its top-level definitions
# stay after you leave. If it returns `{overlays: [...]}`, the hook loads
# each entry as an overlay and hides it when you leave. An entry is a
# record:
#   {path: mod.nu, name: tools}
# `path` is relative to the project root, and `name` is the overlay name.
# Any other return value means a procedural `.env.nu`. To read the return
# value before it writes the hook code, the hook also evaluates `.env.nu`
# in a child `nu`, so a `.env.nu` runs twice on entry.
#
# Re-entering a project shows its hidden overlays again. Edits to an
# overlay's module take effect after `overlay use <path> --reload as <name>`.
#
# Overlays that load in the same prompt share one env frame. If an outer
# project unloads while an inner one stays, the outer project's commands
# go, but its `export-env` values stay until the inner project unloads.
#
# Trust comes from nu_scripts' nuenv: run `nuenv allow` in the root.
#
# Register the hooks in config.nu:
#   let nuenv_hooks = nuenv hooks
#   $env.config.hooks.pre_prompt = (
#       $env.config.hooks.pre_prompt? | default [] | append $nuenv_hooks.pre_prompt
#   )
#   $env.config.hooks.env_change.PWD = (
#       $env.config.hooks.env_change.PWD? | default [] | append $nuenv_hooks.pwd
#   )
#   $env.config.hooks.env_change.NUENV_TICK = $nuenv_hooks.tick
#   $env.NUENV_TICK = 0
#
# Needs nu_scripts' `nu-hooks` directory on NU_LIB_DIRS.

export use nu-hooks/nuenv/hook.nu ["nuenv allow" "nuenv disallow"]

const env_file = '.env.nu'

# nuenv keeps this path private, so it is repeated here.
def allowed-hashes []: nothing -> list<string> {
    let file = $nu.cache-dir | path join nuenv allowed.txt
    if ($file | path exists) { open $file | lines } else { [] }
}

def allowed-file [file: string, allowed: list<string>]: nothing -> bool {
    ($file | path exists) and ((open $file | hash sha256) in $allowed)
}

def base-type []: any -> string {
    describe | str replace --regex '<.*' ''
}

def within [dir: string, root: string]: nothing -> bool {
    let prefix = if ($root | str ends-with '/') { $root } else { $root + '/' }
    $dir == $root or ($dir | str starts-with $prefix)
}

# `/a/b` gives `[/ /a /a/b]`.
def ancestors []: string -> list<string> {
    let parts = $in | path split
    0..<($parts | length) | each {|i| $parts | first ($i + 1) | path join }
}

def fail [msg: string]: nothing -> any {
    error make --unspanned {msg: $'nuenv: ($msg)'}
}

def is-entry []: any -> bool {
    let entry = $in
    (
        ($entry | base-type) == record
        and ($entry.path? | base-type) == string
        and ($entry.name? | base-type) == string
    )
}

def conforms []: record -> bool {
    let output = $in
    (
        ($output.overlays? | base-type) in [list table]
        and ($output.overlays | all {|entry| $entry | is-entry })
    )
}

# A record return must be `{overlays: [{path: ..., name: ...}]}`, so no
# overlay is dropped without a word. Any other value means the `.env.nu`
# is procedural.
def overlay-entries [root: string, output: any]: nothing -> list<record> {
    if ($output | base-type) != record {
        return []
    }
    if not ($output | conforms) {
        let expected = 'record<overlays: table<path: string, name: string>>'
        let got = $output | describe
        fail $'($root)/.env.nu returned a record that is not (ansi blue)($expected)(ansi reset), but (ansi blue)($got)(ansi reset)'
    }
    let entries = $output.overlays | each {|entry|
        {path: ($root | path join $entry.path), name: $entry.name}
    }
    let bad = $entries | where name !~ '^[A-Za-z0-9_-]+$'
    if ($bad | is-not-empty) {
        fail $'an overlay name is not a bare word: ($bad.0.name)'
    }
    let names = $entries | each {|e| $e.name }
    if ($names | uniq | length) != ($names | length) {
        fail $'two overlays in ($root) share a name'
    }
    $entries
}

# The return value of `.env.nu`, from a child `nu`. A closure cannot
# `source` a path that is only known at run time.
def evaluate [file: string]: nothing -> any {
    let script = $'let output = source ($file | to nuon); $output | to nuon'
    let result = ^$nu.current-exe --no-config-file --commands $script | complete
    if $result.exit_code != 0 {
        fail $'($file) failed in a child nu: ($result.stderr | str trim)'
    }
    $result.stdout | from nuon
}

def check-active [name: string]: nothing -> string {
    let quoted = $name | to nuon
    let msg = $'nuenv: overlay ($name) did not activate' | to nuon
    [
        'if (overlay list | where {|o| $o.name == '
        $quoted
        ' and $o.active } | is-empty) { print -e '
        $msg
        ' }'
    ]
    | str join
}

# Hiding an overlay drops the env set while it was on top, so the code
# sets the whole stack as a literal after its overlay lines.
def set-active [stack: list]: nothing -> string {
    $'$env.NUENV_ACTIVE = ($stack | to nuon)'
}

# The lines that load one project, and its stack entry.
def enter [root: string, dir: string, known: list<string>]: nothing -> record {
    let file = $root | path join $env_file
    let entries = overlay-entries $root (evaluate $file)
    # Showing a hidden overlay restores the PWD it stored, so the code
    # changes back to the current directory afterwards.
    let loads = $entries | each {|e|
        if $e.name in $known {
            [$'overlay use ($e.name)' $'cd ($dir | to nuon)']
        } else {
            [$'overlay use ($e.path | to nuon) as ($e.name)']
        }
    }
    {
        lines: (
            [$'let nuenv_output = source ($file | to nuon)']
            | append ($loads | flatten)
            | append ($entries | each {|e| check-active $e.name })
        )
        entry: {root: $root, overlays: ($entries | each {|e| $e.name })}
    }
}

# `overlay` and `source` act at parse time and a closure's scope ends with
# it, so the plan runs as a string hook. The code cannot come from a
# sourced file: in nushell 0.116.1, overlay commands in a sourced file
# leave the overlay half active once it has been hidden and shown again.
# So this hook (env_change.NUENV_TICK) writes the plan as literal code into
# the marked pre_prompt entry. Every hook ends with `merge_env`, and
# pre_prompt reads its list after env_change, so the code runs in the same
# prompt.
def --env plan [dir: string]: nothing -> nothing {
    let allowed = allowed-hashes
    let active = $env.NUENV_ACTIVE? | default []
    let stays = {|e|
        let file = $e.root | path join $env_file
        (within $dir $e.root) and (allowed-file $file $allowed)
    }
    let keep = $active | where $stays
    let leave = $active | where {|e| not (do $stays $e) }

    let hide = $leave
    | reverse
    | each {|e| $e.overlays | reverse }
    | flatten
    | each {|name| $'overlay hide ($name) --keep-env [PWD NUENV_TICK]' }

    let kept_roots = $keep | each {|e| $e.root }
    let known = overlay list | each {|o| $o.name }
    let projects = $dir
    | ancestors
    | where {|root| $root not-in $kept_roots }
    | where {|root| allowed-file ($root | path join $env_file) $allowed }
    | each {|root|
        try {
            enter $root $dir $known
        } catch {|err|
            print -e $'(ansi red)($err.msg)(ansi reset)'
            null
        }
    }
    | compact

    let stack = $keep ++ ($projects | each {|p| $p.entry })
    let code = if ($hide | is-empty) and ($projects | is-empty) {
        ''
    } else {
        $hide
        | append ($projects | each {|p| $p.lines } | flatten)
        | append (set-active $stack)
        | str join (char nl)
    }

    # Always overwrite, so the last plan does not run again.
    $env.config.hooks.pre_prompt = (
        $env.config.hooks.pre_prompt
        | each {|hook|
            if ($hook | base-type) == record and $hook.__nuenv? == true {
                $hook | upsert code $code
            } else {
                $hook
            }
        }
    )
}

# Warns once per entry into a project whose `.env.nu` is not allowed.
def advise [before: any, after: string]: nothing -> nothing {
    let allowed = allowed-hashes
    $after
    | ancestors
    | where {|root| $before == null or not (within $before $root) }
    | each {|root| $root | path join $env_file }
    | where {|file| ($file | path exists) and not (allowed-file $file $allowed) }
    | each {|file|
        print $"(ansi yellow)($file) is not allowed. To allow, please run `nuenv allow`.(ansi reset)"
    }
    | ignore
}

# The hooks to register. `tick` (for env_change.NUENV_TICK) writes the
# plan, `pre_prompt` runs it and bumps the tick so `tick` fires before the
# next prompt, and `pwd` (for env_change.PWD) prints the advisory.
export def "nuenv hooks" []: nothing -> record {
    {
        tick: [
            {|_, _| plan $env.PWD }
        ]
        pre_prompt: [
            {__nuenv: true, code: ''}
            {|| $env.NUENV_TICK = ($env.NUENV_TICK? | default 0) + 1 }
        ]
        pwd: [
            {|before, after| advise $before $after }
        ]
    }
}
