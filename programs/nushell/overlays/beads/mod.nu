# Commands for the beads (`bd`) issue tracker. Run `help td` for the list.

def groupings [] { [repo deps] }

# Runs bd with --json and returns the envelope's `data`. Help runs bd as is.
# Needs BD_JSON_ENVELOPE=1.
export def --wrapped bd [...args]: nothing -> any {
  # `help` counts only as the subcommand: `--label help` is data. Bare `bd`
  # prints usage.
  let help = (
    ($args | is-empty)
    or ($args | any {|arg| $arg in [--help -h] })
    or ($args | first 1) == [help]
  )
  if $help {
    return (^bd ...$args)
  }

  let flags = if "--json" in $args { [] } else { [--json] }
  let result = ^bd ...$args ...$flags | complete
  let command = $"bd ($args | str join ' ')"

  let parsed = try {
    $result.stdout | from json
  } catch {
    error make {msg: $"($command) did not return JSON: ($result.stderr | str trim)"}
  }

  # A failed command still prints an envelope, with the error under `data`.
  if $result.exit_code != 0 {
    error make {
      msg: ($parsed.data.error? | default ($result.stderr | str trim))
      help: $parsed.data.hint?
    }
  }

  $parsed.data
}

# Open beads, optionally grouped.
export def list [
  --by (-b): string@groupings  # Group by `repo` label, or draw `deps` as a graph
  --all (-a)                   # Include closed beads
]: nothing -> any {
  match $by {
    null => (rows list $all)
    "repo" => (rows list $all | by-repo)
    "deps" => {
      if $all { error make {msg: "--by deps shows open beads only"} }
      ^bd graph --all --compact
    }
    _ => (error make {msg: $"unknown grouping: ($by)"})
  }
}

# Unblocked beads, optionally grouped.
export def ready [
  --by (-b): string@groupings  # Group by `repo` label
]: nothing -> any {
  match $by {
    null => (rows ready false)
    "repo" => (rows ready false | by-repo)
    "deps" => (error make {msg: "--by deps is not supported for ready yet"})
    _ => (error make {msg: $"unknown grouping: ($by)"})
  }
}

# Beads as a table, epics dropped: they carry `project:` labels, never `repo:`.
def rows [command: string, all: bool]: nothing -> table {
  let flags = if $all { [--all] } else { [] }

  bd $command ...$flags --limit 0
  | where issue_type != epic
  | each {|bead|
    $bead
    | select id status priority title
    | insert repos (
      $bead.labels?
      | default []
      | where $it starts-with "repo:"
    )
  }
}

# A bead with two `repo:` labels appears under both; none gives `unscoped`.
def by-repo []: table -> record {
  each {|bead|
    let repos = if ($bead.repos | is-empty) { [unscoped] } else { $bead.repos }
    $repos | each {|repo| $bead | reject repos | insert repo $repo }
  }
  | flatten
  | group-by repo
  | items {|repo, beads| {$repo: ($beads | reject repo)} }
  | into record
}
