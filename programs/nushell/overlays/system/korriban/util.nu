export def field [pattern: string]: string -> any {
  $in | parse --regex $pattern | get v.0?
}
