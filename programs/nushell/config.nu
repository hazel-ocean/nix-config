alias e = clear

# Hold a zellij pane visually empty: clear, then block so no prompt is drawn.
# Ctrl-C returns to the prompt.
def blank []: nothing -> nothing {
  clear
  loop { sleep 1hr }
}
alias eb = blank

def --wrapped r [...rest]   { clear; ls ...$rest * }
def --wrapped ra [...rest]  { clear; ls ...$rest -a * }
def --wrapped er [...rest]  { clear; ls ...$rest -l * }
def --wrapped era [...rest] { clear; ls ...$rest -la }
def --wrapped err [...rest]  { clear; ^eza --color=never ...$rest -lR }
def --wrapped erra [...rest] { clear; ^eza --color=never ...$rest -lRa }
def --wrapped re [...rest]  { clear; ls ...$rest */* }
def --wrapped rea [...rest] { clear; ls ...$rest -a */* }
def --wrapped et [...rest]  { clear; ^eza --color=never ...$rest --tree --level=1 }
def --wrapped eta [...rest] { clear; ^eza --color=never ...$rest -a --tree --level=1 }
def --wrapped et0 [...rest] { clear; ^eza --color=never ...$rest --tree --level=0 }
def --wrapped et1 [...rest] { clear; ^eza --color=never ...$rest --tree --level=1 }
def --wrapped et2 [...rest] { clear; ^eza --color=never ...$rest --tree --level=2 }
def --wrapped et3 [...rest] { clear; ^eza --color=never ...$rest --tree --level=3 }
def --wrapped et4 [...rest] { clear; ^eza --color=never ...$rest --tree --level=4 }
def --wrapped etr [...rest] { clear; ^eza --color=never ...$rest --tree }

def eg  [...rest] { clear; git status ...$rest }
def egg [...rest] { clear; git status; echo; git diff ...$rest }
def egc [...rest] { clear; git status; echo; git diff --cached ...$rest }

def tf [] { terraform }

def zvi [] { nvim (fzf --preview 'bat --style=numbers --color=always {}') }
def zhx [] { hx (fzf --preview 'bat --style=numbers --color=always {}') }
def zgc [] { git checkout (git branch | fzf) }

# Zellij session management. `zd` multi-selects sessions to force-delete;
# `zda` drops all resurrectable (exited) sessions via `zellij delete-all-sessions`
# (its own y/N prompt confirms). Both first flag any workspace-tracked sessions
# that would be affected. `workspace list` resolves once its overlay is loaded.

# Heads-up for a pending Zellij deletion: workspace-tracked sessions (rows from
# `workspace list`), session names in light purple. No-op on empty.
def print-workspace-sessions [header: string] {
  let rows = $in
  if ($rows | is-empty) { return }
  print $"(ansi light_blue)($header)(ansi reset)"
  for row in $rows {
    print (
      $"  ($row.zellij)"
      + $" (ansi dark_gray)<- ($row.workspace) [($row.state)](ansi reset)"
    )
  }
}

def zellij-session-names []: nothing -> list<string> {
  let r = (^zellij list-sessions --no-formatting --short | complete)
  if $r.exit_code != 0 { return [] }
  $r.stdout
  | lines
  | each {|l| $l | str trim }
  | where {|l| $l | is-not-empty }
}

# Names can contain spaces, so split on the `[Created ...]` marker.
def zellij-sessions []: nothing -> table<name: string, exited: bool> {
  let r = (^zellij list-sessions --no-formatting | complete)
  if $r.exit_code != 0 { return [] }
  $r.stdout
  | lines
  | parse --regex '^(?<name>.*?) \[Created [^\]]*\](?<tail>.*)$'
  | each {|s| {name: $s.name, exited: ($s.tail | str contains "EXITED")} }
}

# Blue for an active session, red for an exited one.
def zellij-session-label []: record<name: string, exited: bool> -> string {
  let colour = if $in.exited { ansi red } else { ansi blue }
  $"($colour)($in.name)(ansi reset)"
}

# Multi-select Zellij sessions to force-delete; flags any a workspace saved.
def zd [] {
  let sessions = (zellij-sessions)
  if ($sessions | is-empty) { print "No Zellij sessions."; return }
  let chosen = (
    $sessions
    | input list --multi --fuzzy --display {|s| $s | zellij-session-label }
      "Sessions to delete:"
  )
  if ($chosen | is-empty) { print "Nothing selected."; return }
  let names = ($chosen | get name)
  # `workspace list` paints session names, so strip the colour before matching.
  workspace list
  | where ($it.zellij | default "" | ansi strip) in $names
  | where ($it.workspace | ansi strip) != "(orphan)"
  | print-workspace-sessions "Workspace sessions in the selection:"
  for session in $chosen {
    ^zellij delete-session --force -- $session.name
    print $"deleted ($session | zellij-session-label)"
  }
}

# Attach to a live Zellij session: single-select picker, or attach directly on an
# exact name, else narrow the picker to sessions whose name contains the input.
def za [
  name?: string # session to attach; omit to pick from all sessions
] {
  let names = (zellij-session-names)
  if ($names | is-empty) { print "No Zellij sessions."; return }
  let chosen = if ($name | is-empty) {
    $names | input list --fuzzy "Session to attach:"
  } else if ($name in $names) {
    $name
  } else {
    let matches = ($names | where {|n| $n | str contains -i $name })
    if ($matches | is-empty) { print $"No session matches ($name)."; return }
    $matches | input list --fuzzy "Session to attach:"
  }
  if ($chosen | is-empty) { print "Nothing selected."; return }
  if ("ZELLIJ" in $env) {
    ^zellij action switch-session $chosen
  } else {
    ^zellij attach -- $chosen
  }
}

# Delete all resurrectable (exited) Zellij sessions, warning first about any a
# workspace saved. `zellij delete-all-sessions` prompts for confirmation.
def zda [] {
  let sessions = (zellij-sessions)
  if ($sessions | is-not-empty) {
    print $"Sessions \((ansi red)exited(ansi reset) are deleted\):"
    for session in $sessions {
      print $"  ($session | zellij-session-label)"
    }
  }
  workspace list
  | where state == "exited" and ($it.workspace | ansi strip) != "(orphan)"
  | print-workspace-sessions "Workspace sessions to be deleted:"
  ^zellij delete-all-sessions
}

def cdcopy [] { pwd | pbcopy }
def cdpaste [] { cd $"\"(pbpaste)\"" }

# Render λ here (not via starship) so it tracks vi mode: only these indicators
# re-render on a keymap change. Starship's `[character]` is disabled in the
# Nushell-only config (default.nix). purple = ok, red = failed, blue = vi normal.
$env.PROMPT_INDICATOR_VI_INSERT = {||
  let c = if $env.LAST_EXIT_CODE == 0 { ansi purple_bold } else { ansi red_bold }
  $"\n($c) λ (ansi reset)"
}
$env.PROMPT_INDICATOR_VI_NORMAL = {|| $"\n(ansi blue_bold) λ (ansi reset)" }

$env.config.edit_mode = "helix"
# Use cursor shapes to differentiate instead
$env.config.cursor_shape.vi_insert = "blink_block"
$env.config.cursor_shape.vi_normal = "block"

$env.config.show_banner = "short"
$env.config.completions.algorithm = "fuzzy"

$env.config.keybindings = (
  try { $env.config.keybindings } catch { [] }
    | append {
      name: fuzzy_history
      modifier: control
      keycode: char_r
      mode: [emacs, vi_normal, vi_insert, helix_normal, helix_insert]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "commandline edit --insert (
            (history).command
              | uniq
              | reverse
              | str join (char -i 0)
              | fzf --scheme history
                    --read0
                    --layout=reverse
                    --height=40%
                    --bind 'ctrl-/:change-preview-window(right,70%|right)'
                    --preview='echo -n {} | nu --stdin -c \'nu-highlight\''
                    --preview-window=left
              | decode utf-8
              | str trim
          )"
        }
      ]
    }
    | append {
      name: fuzzy_file
      modifier: control
      keycode: char_t
      mode: [emacs, vi_normal, vi_insert, helix_normal, helix_insert]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "commandline edit --insert (
            fd --type f
              | fzf --multi
                    --layout=reverse
                    --height=40%
              | lines
              | each { to nuon }
              | str join ' '
          )"
        }
      ]
    }
    | append {
      name: fuzzy_cd
      modifier: alt
      keycode: char_c
      mode: [emacs, vi_normal, vi_insert, helix_normal, helix_insert]
      event: [
        {
          send: ExecuteHostCommand
          cmd: "let dir = (
            fd --type d
              | fzf --layout=reverse
                    --height=40%
              | str trim
          )
          if $dir != '' { cd $dir }"
        }
      ]
    }
)

$env.config.completions.external = {
  enable: true
  completer: {|place|
    carapace $place.command.0 nushell ...$place.command
      | from json
  }
}
