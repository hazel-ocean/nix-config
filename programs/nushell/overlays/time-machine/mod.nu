# Time Machine backup management (macOS `tmutil`).

# Removes past backups. Requires specifying the volume of the backup.
export def thin-backups [
  --keeping (-k): int = 1  # Keep the last `k` backups
  --volume (-v): string        # Backup volume to target
]: nothing -> nothing {
    let keeping = [0, $keeping] | math max
    yellow $"Thinning backups, keeping last ($keeping)..."

    let removed = (
      ^tmutil listbackups -d $volume -t
      | lines
      | drop $keeping
      | each {|ts| ^sudo tmutil delete -d $volume -t $ts }
      | length
    )

    print $"Removed ($removed) backup\(s\)"
}

# Run a single Time Machine backup.
export def start-backup [
  --blocking = false
]: nothing -> nothing {
  yellow "Starting backup..."
  let args = if $blocking { [--block]  } else { [] }
  ^tmutil startbackup ..args
}

def yellow [msg: string]: nothing -> nothing { print $"(ansi yellow)($msg)(ansi reset)" }
def red [msg: string]: nothing -> nothing { print $"(ansi red)($msg)(ansi reset)" }
