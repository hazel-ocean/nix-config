# Time Machine backup management (macOS `tmutil`).
#
# Auto-loaded on Darwin hosts, with `--prefix`, so commands are namespaced:
#   time-machine backup                                  # blocking backup
#   time-machine backup --thin --volume "/Volumes/X"     # ...then thin old ones

# Start a Time Machine backup, optionally thinning old snapshots afterward.
export def backup [
  --volume (-v): string   # Backup volume to thin (required with --thin)
  --thin (-t)             # After backing up, delete all but the latest backup
  --skip (-s)             # Skip the backup itself (useful with --thin)
]: nothing -> nothing {
  if $skip {
    red "Skipping backup..."
  } else {
    tmutil-backup
  }

  if $thin {
    if ($volume | is-empty) {
      error make { msg: "--thin requires --volume <backup volume>" }
    }
    tmutil-thin-backups $volume
  }
}

# Run a single blocking Time Machine backup.
def tmutil-backup []: nothing -> nothing {
  yellow "Starting backup..."
  ^tmutil startbackup --block
}

# Delete every backup on a volume except the most recent.
def tmutil-thin-backups [volume: string]: nothing -> nothing {
  yellow "Thinning backups..."
  let removed = (
    ^tmutil listbackups -d $volume -t
    | lines
    | drop 1
    | each {|ts| ^sudo tmutil delete -d $volume -t $ts }
    | length
  )
  print $"Removed ($removed) backup\(s\)"
}

def yellow [msg: string]: nothing -> nothing { print $"(ansi yellow)($msg)(ansi reset)" }
def red [msg: string]: nothing -> nothing { print $"(ansi red)($msg)(ansi reset)" }
