alias e = clear
alias k = kubectl

def r [...paths: string] { e; lsd ...$paths }
def re [] { e; lsd * }
def er [...paths: string] { e; lsd -l ...$paths }
def err [...paths: string] { e; lsd -lR ...$paths }
def et [...paths: string] { e; lsd --tree --depth=1 ...$paths }
def et2 [...paths: string] { e; lsd --tree --depth=2 ...$paths }
def et3 [...paths: string] { e; lsd --tree --depth=3 ...$paths }
def et4 [...paths: string] { e; lsd --tree --depth=4 ...$paths }
def etr [...paths: string] { e; lsd --tree ...$paths }

def eg  [] { clear; git status }
def egg [] { clear; git status; echo; git diff }
def egc [] { clear; git status; echo; git diff --cached }

# Tmux
def te [] { tmux list-sessions }
def ta [] { tmux attach }

# Zellij
alias za = zellij attach
alias ze = zellij list-sessions
alias zd = zellij delete-all-sessions --yes

# Yazi
alias fe = yazi

def tf [] { terraform }

def zvi [] { nvim (fzf --preview 'bat --style=numbers --color=always {}') }
def zhx [] { hx (fzf --preview 'bat --style=numbers --color=always {}') }
def zgc [] { git checkout (git branch | fzf) }

def cdcopy [] { pwd | pbcopy }
def cdpaste [] { cd $"\"(pbpaste)\"" }

$env.config.show_banner = false

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
          cmd: "commandline (
            history
              | each { |it| $it.command }
              | uniq
              | reverse
              | str join (char -i 0)
              | fzf --read0 --layout=reverse --height=40% -q (commandline)
              | decode utf-8
              | str trim
          )"
        }
      ]
    }
)
