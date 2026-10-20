# Hex color helpers. Loaded with `--prefix`: subcommands -> `color <sub>`.

# Whether a value is a `#rrggbb` string.
export def 'is-hex' [v]: nothing -> bool {
  ($v | describe) == 'string' and ($v =~ '^#[0-9a-fA-F]{6}$')
}

# `#rrggbb` -> `{r, g, b}`, each 0-255.
export def 'to-rgb' []: string -> record<r: int, g: int, b: int> {
  let hex = $in
  if not (is-hex $hex) {
    error make --unspanned { msg: $'not a #rrggbb color: ($hex)' }
  }
  let channel = {|i| $hex | str substring (1 + 2 * $i)..(2 + 2 * $i) | into int --radix 16 }
  { r: (do $channel 0), g: (do $channel 1), b: (do $channel 2) }
}

# `{r, g, b}` -> `#rrggbb`. Channels are rounded and clamped to 0-255.
export def 'from-rgb' []: record -> string {
  let rgb = $in
  [$rgb.r $rgb.g $rgb.b]
  | each {|v|
    [0 ([255 ($v | math round)] | math min)]
    | math max
    | format number
    | get lowerhex
    | str substring 2..
    | fill --alignment right --character '0' --width 2
  }
  | str join
  | $'#($in)'
}

# Blend two `#rrggbb` colors, `t` of the way from `a` to `b`.
export def 'mix' [a: string, b: string, t: float]: nothing -> string {
  let x = ($a | to-rgb)
  let y = ($b | to-rgb)
  let lerp = {|k| ($x | get $k) + (($y | get $k) - ($x | get $k)) * $t }
  { r: (do $lerp r), g: (do $lerp g), b: (do $lerp b) } | from-rgb
}
