use ../util.nu *

const PAIR_WINDOW = "-10 minutes"

# Answer moonshine's pending Moonlight pairing request.
export def "moonshine pair" [
  pin: string # the four-digit PIN shown by the Moonlight client
]: nothing -> nothing {
  if ($pin !~ '^\d{4}$') {
    error make { msg: $"PIN must be four digits, got '($pin)'" }
  }

  # A request expires, so only the recent journal counts, and a later
  # "registered" line means the last request is already answered.
  let last_event = (
    journalctl --unit moonshine --no-pager --output cat --since $PAIR_WINDOW
    | lines
    | where {|line| $line =~ 'Waiting for pin to be sent at|PIN registered successfully' }
    | last 1
  )
  if ($last_event | is-empty) or ($last_event.0 !~ 'Waiting for pin') {
    error make { msg: "No pairing request is waiting. Pair from Moonlight, then retry." }
  }

  let url = (
    $last_event.0
    | parse --regex 'sent at (?<url>http\S+)'
    | get url.0
    | url parse
  )
  let uniqueid = ($url.params | where key == uniqueid | get value.0)

  (http post
    --content-type application/x-www-form-urlencoded
    $"($url.scheme)://($url.host):($url.port)/submit-pin"
    { uniqueid: $uniqueid, pin: $pin })

  magenta $"Paired client ($uniqueid)."
}
