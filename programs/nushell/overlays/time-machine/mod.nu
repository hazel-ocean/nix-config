# Time Machine backup management (macOS `tmutil`).

const data_volume = "/System/Volumes/Data"

# List backups. Lists local snapshots unless `--target` names a backup volume.
export def list [
    --target (-t): path  # Mounted backup volume to list
]: nothing -> table {
    let volume = $target | default $data_volume
    print -e $"($volume) in use: (volume-used $volume)"
    backups $target
}

# Remove all but the newest `k` backups, after confirmation.
# Trims local snapshots unless `--target` names a backup volume.
export def trim [
    --keeping (-k): int = 1  # Keep the newest `k` backups
    --target (-t): path      # Mounted backup volume to trim
    --yes (-y)               # Skip the confirmation prompt
]: nothing -> nothing {
    let keeping = [0, $keeping] | math max
    let doomed = (
        backups $target
        | sort-by id
        | drop $keeping
    )

    if ($doomed | is-empty) {
        print "Nothing to remove"
        return
    }

    print ($doomed | table)
    if not $yes {
        let answer = input $"Remove ($doomed | length) backup\(s\), keeping ($keeping)? [y/N] "
        if ($answer | str lowercase) != "y" {
            print "Aborted"
            return
        }
    }

    ^sudo -v
    let volume = $target | default $data_volume
    let before = volume-used $volume
    let results = $doomed | each {|b| remove $b.id $target }
    let removed = $results | where $it | length
    let failed = ($results | length) - $removed
    # APFS can release blocks after the delete returns, so this can under-report.
    let freed = $before - (volume-used $volume)

    print $"Removed ($removed) backup\(s\), freed ($freed)"
    if $failed > 0 { red $"Failed to remove ($failed) backup\(s\)" }
}

# Run a single Time Machine backup.
export def start-backup [
    --blocking = false
]: nothing -> nothing {
    yellow "Starting backup..."
    let args = if $blocking { [--block] } else { [] }
    ^tmutil startbackup ..args
}

def backups [target?: path]: nothing -> table<id: string, date: any, age: any> {
    let ids = match $target {
        null => (
            ^tmutil listlocalsnapshots /
            | lines
            | parse "com.apple.TimeMachine.{id}.local"
            | get id
        )
        _ => (^tmutil listbackups -d $target -t | lines)
    }

    $ids | each {|id|
        let date = try { $id | into datetime --format "%Y-%m-%d-%H%M%S" } catch { null }
        {
            id: $id
            date: $date
            age: (if $date == null { null } else { (date now) - $date })
        }
    }
}

def remove [id: string, target?: path]: nothing -> bool {
    let result = match $target {
        null => (^sudo tmutil deletelocalsnapshots $id | complete)
        _ => (^sudo tmutil delete -d $target -t $id | complete)
    }
    if $result.exit_code != 0 {
        red $"Failed to remove ($id): ($result.stderr | str trim)"
    }
    $result.exit_code == 0
}

def volume-used [volume: path]: nothing -> filesize {
    ^diskutil info -plist $volume
    | ^plutil -extract CapacityInUse raw -
    | into int
    | into filesize
}

def yellow [msg: string]: nothing -> nothing { print $"(ansi yellow)($msg)(ansi reset)" }
def red [msg: string]: nothing -> nothing { print $"(ansi red)($msg)(ansi reset)" }
