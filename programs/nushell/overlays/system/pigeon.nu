use ./util.nu *

# Drop into the Jellyfin volume with its Justfile listed.
export def jellyfin []: nothing -> nothing {
  let volume = "/Volumes/Jellyfin"
  if not ($volume | path exists) {
    error make { msg: $"Jellyfin volume not mounted at ($volume)" }
  }
  cd $volume
  clear -k
  magenta "Starting interactive shell..."
  ^nu --execute 'just --list'
}
