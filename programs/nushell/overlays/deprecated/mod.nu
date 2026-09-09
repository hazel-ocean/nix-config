# Retirement notices for aliases and commands.
#
# Both commands take a record of optional keys: `from`, `to`, `help`, and `msg`
# to replace the default copy.

# Fail with a pointer to the replacement.
export def error [opts: record] {
  error make --unspanned {
    msg: ($opts.msg? | default $"(ansi red)deprecated(ansi reset) from: (ansi magenta)($opts.from?)(ansi reset) to: (ansi magenta)($opts.to?)(ansi reset)")
    help: $opts.help?
  }
}

# Point at the replacement, then run it.
export def --env warn [
  opts: record
  cmd: closure   # what to run in its place
  ...rest        # arguments forwarded to `cmd`
]: any -> any {
  let input = $in
  print --stderr ($opts.msg? | default $"(ansi red)Deprecated!(ansi reset) - use (ansi magenta)($opts.to?)(ansi reset) instead.")
  if ($opts.help? | is-not-empty) { print --stderr $"(ansi cyan)help(ansi reset): ($opts.help)" }
  $input | do --env $cmd ...$rest
}
