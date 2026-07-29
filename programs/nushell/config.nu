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
