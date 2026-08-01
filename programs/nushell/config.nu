alias e = clear
def --wrapped r [...rest]   { clear; ls ...$rest * }
def --wrapped ra [...rest]  { clear; ls ...$rest -a * }
def --wrapped er [...rest]  { clear; ls ...$rest -l * }
def --wrapped era [...rest] { clear; ls ...$rest -la }
def --wrapped err [...rest] { clear; lsd ...$rest -lR }
def --wrapped re [...rest]  { clear; ls ...$rest */* }
def --wrapped rea [...rest] { clear; ls ...$rest -a */* }
def --wrapped et [...rest]  { clear; lsd ...$rest --tree --depth=1 }
def --wrapped et2 [...rest] { clear; lsd ...$rest --tree --depth=2 }
def --wrapped et3 [...rest] { clear; lsd ...$rest --tree --depth=3 }
def --wrapped et4 [...rest] { clear; lsd ...$rest --tree --depth=4 }
def --wrapped etr [...rest] { clear; lsd ...$rest --tree }

def eg  [] { clear; git status }
def egg [] { clear; git status; echo; git diff }
def egc [] { clear; git status; echo; git diff --cached }


def tf [] { terraform }

def zvi [] { nvim (fzf --preview 'bat --style=numbers --color=always {}') }
def zhx [] { hx (fzf --preview 'bat --style=numbers --color=always {}') }
def zgc [] { git checkout (git branch | fzf) }

# Zellij session management. `zd` multi-selects live sessions to force-delete;
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
      $"  (ansi light_purple)($row.session)(ansi reset)"
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

# Multi-select live Zellij sessions to force-delete; flags any a workspace saved.
def zd [] {
  let names = (zellij-session-names)
  if ($names | is-empty) { print "No Zellij sessions."; return }
  let chosen = ($names | input list --multi --fuzzy "Sessions to delete:")
  if ($chosen | is-empty) { print "Nothing selected."; return }
  workspace list
  | where session in $chosen
  | print-workspace-sessions "Workspace sessions in the selection:"
  for name in $chosen {
    ^zellij delete-session --force -- $name
    print $"deleted (ansi light_purple)($name)(ansi reset)"
  }
}

# Delete all resurrectable (exited) Zellij sessions, warning first about any a
# workspace saved. `zellij delete-all-sessions` prompts for confirmation.
def zda [] {
  workspace list
  | where state == "exited"
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

$env.config.edit_mode = "vi"
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
      mode: [emacs, vi_normal, vi_insert]
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
)
