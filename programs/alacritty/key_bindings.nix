{ pkgs }:
let
  inherit (pkgs) stdenv;

  darwin = [
    {
      key = "F11";
      mods = "None";
      action = ''ToggleFullscreen'';
    }
    {
      key = "N";
      mods = "Command";
      action = ''SpawnNewInstance'';
    }
    {
      key = "A";
      mods = "Alt";
      chars = ''\x1ba'';
    }
    {
      key = "B";
      mods = "Alt";
      chars = ''\x1bb'';
    }
    {
      key = "C";
      mods = "Alt";
      chars = ''\x1bc'';
    }
    {
      key = "D";
      mods = "Alt";
      chars = ''\x1bd'';
    }
    {
      key = "E";
      mods = "Alt";
      chars = ''\x1be'';
    }
    {
      key = "F";
      mods = "Alt";
      chars = ''\x1bf'';
    }
    {
      key = "G";
      mods = "Alt";
      chars = ''\x1bg'';
    }
    {
      key = "H";
      mods = "Alt";
      chars = ''\x1bh'';
    }
    {
      key = "I";
      mods = "Alt";
      chars = ''\x1bi'';
    }
    {
      key = "J";
      mods = "Alt";
      chars = ''\x1bj'';
    }
    {
      key = "K";
      mods = "Alt";
      chars = ''\x1bk'';
    }
    {
      key = "L";
      mods = "Alt";
      chars = ''\x1bl'';
    }
    {
      key = "M";
      mods = "Alt";
      chars = ''\x1bm'';
    }
    {
      key = "N";
      mods = "Alt";
      chars = ''\x1bn'';
    }
    {
      key = "O";
      mods = "Alt";
      chars = ''\x1bo'';
    }
    {
      key = "P";
      mods = "Alt";
      chars = ''\x1bp'';
    }
    {
      key = "Q";
      mods = "Alt";
      chars = ''\x1bq'';
    }
    {
      key = "R";
      mods = "Alt";
      chars = ''\x1br'';
    }
    {
      key = "S";
      mods = "Alt";
      chars = ''\x1bs'';
    }
    {
      key = "T";
      mods = "Alt";
      chars = ''\x1bt'';
    }
    {
      key = "U";
      mods = "Alt";
      chars = ''\x1bu'';
    }
    {
      key = "V";
      mods = "Alt";
      chars = ''\x1bv'';
    }
    {
      key = "W";
      mods = "Alt";
      chars = ''\x1bw'';
    }
    {
      key = "X";
      mods = "Alt";
      chars = ''\x1bx'';
    }
    {
      key = "Y";
      mods = "Alt";
      chars = ''\x1by'';
    }
    {
      key = "Z";
      mods = "Alt";
      chars = ''\x1bz'';
    }
    {
      key = "A";
      mods = "Alt|Shift";
      chars = ''\x1bA'';
    }
    {
      key = "B";
      mods = "Alt|Shift";
      chars = ''\x1bB'';
    }
    {
      key = "C";
      mods = "Alt|Shift";
      chars = ''\x1bC'';
    }
    {
      key = "D";
      mods = "Alt|Shift";
      chars = ''\x1bD'';
    }
    {
      key = "E";
      mods = "Alt|Shift";
      chars = ''\x1bE'';
    }
    {
      key = "F";
      mods = "Alt|Shift";
      chars = ''\x1bF'';
    }
    {
      key = "G";
      mods = "Alt|Shift";
      chars = ''\x1bG'';
    }
    {
      key = "H";
      mods = "Alt|Shift";
      chars = ''\x1bH'';
    }
    {
      key = "I";
      mods = "Alt|Shift";
      chars = ''\x1bI'';
    }
    {
      key = "J";
      mods = "Alt|Shift";
      chars = ''\x1bJ'';
    }
    {
      key = "K";
      mods = "Alt|Shift";
      chars = ''\x1bK'';
    }
    {
      key = "L";
      mods = "Alt|Shift";
      chars = ''\x1bL'';
    }
    {
      key = "M";
      mods = "Alt|Shift";
      chars = ''\x1bM'';
    }
    {
      key = "N";
      mods = "Alt|Shift";
      chars = ''\x1bN'';
    }
    {
      key = "O";
      mods = "Alt|Shift";
      chars = ''\x1bO'';
    }
    {
      key = "P";
      mods = "Alt|Shift";
      chars = ''\x1bP'';
    }
    {
      key = "Q";
      mods = "Alt|Shift";
      chars = ''\x1bQ'';
    }
    {
      key = "R";
      mods = "Alt|Shift";
      chars = ''\x1bR'';
    }
    {
      key = "S";
      mods = "Alt|Shift";
      chars = ''\x1bS'';
    }
    {
      key = "T";
      mods = "Alt|Shift";
      chars = ''\x1bT'';
    }
    {
      key = "U";
      mods = "Alt|Shift";
      chars = ''\x1bU'';
    }
    {
      key = "V";
      mods = "Alt|Shift";
      chars = ''\x1bV'';
    }
    {
      key = "W";
      mods = "Alt|Shift";
      chars = ''\x1bW'';
    }
    {
      key = "X";
      mods = "Alt|Shift";
      chars = ''\x1bX'';
    }
    {
      key = "Y";
      mods = "Alt|Shift";
      chars = ''\x1bY'';
    }
    {
      key = "Z";
      mods = "Alt|Shift";
      chars = ''\x1bZ'';
    }
    {
      key = "Key1";
      mods = "Alt";
      chars = ''\x1b1'';
    }
    {
      key = "Key2";
      mods = "Alt";
      chars = ''\x1b2'';
    }
    {
      key = "Key3";
      mods = "Alt";
      chars = ''\x1b3'';
    }
    {
      key = "Key4";
      mods = "Alt";
      chars = ''\x1b4'';
    }
    {
      key = "Key5";
      mods = "Alt";
      chars = ''\x1b5'';
    }
    {
      key = "Key6";
      mods = "Alt";
      chars = ''\x1b6'';
    }
    {
      key = "Key7";
      mods = "Alt";
      chars = ''\x1b7'';
    }
    {
      key = "Key8";
      mods = "Alt";
      chars = ''\x1b8'';
    }
    {
      key = "Key9";
      mods = "Alt";
      chars = ''\x1b9'';
    }
    {
      key = "Key0";
      mods = "Alt";
      chars = ''\x1b0'';
    }
    {
      key = "Space";
      mods = "Control";
      chars = ''\x00"'';
    } # Ctrl + Space;
    {
      key = "Grave";
      mods = "Alt";
      chars = ''\x1b`'';
    } # Alt + `;
    {
      key = "Grave";
      mods = "Alt|Shift";
      chars = ''\x1b~'';
    } # Alt + ~;
    {
      key = "Period";
      mods = "Alt";
      chars = ''\x1b.'';
    } # Alt + .;
    {
      key = "Key8";
      mods = "Alt|Shift";
      chars = ''\x1b*'';
    } # Alt + *;
    {
      key = "Key3";
      mods = "Alt|Shift";
      chars = ''\x1b#'';
    } # Alt + #;
    {
      key = "Period";
      mods = "Alt|Shift";
      chars = ''\x1b>'';
    } # Alt + >;
    {
      key = "Comma";
      mods = "Alt|Shift";
      chars = ''\x1b<'';
    } # Alt + <;
    {
      key = "Minus";
      mods = "Alt|Shift";
      chars = ''\x1b_'';
    } # Alt + _;
    {
      key = "Key5";
      mods = "Alt|Shift";
      chars = ''\x1b%'';
    } # Alt + %;
    {
      key = "Key6";
      mods = "Alt|Shift";
      chars = ''\x1b^'';
    } # Alt + ^;
    {
      key = "Backslash";
      mods = "Alt";
      chars = ''\x1b\\'';
    } # Alt + \;
    {
      key = "Backslash";
      mods = "Alt|Shift";
      chars = ''\x1b|'';
    } # Alt + |;
  ];

  linux = [
    {
      key = "F11";
      mods = "None";
      action = "ToggleFullscreen";
    }
    {
      key = "Q";
      mods = "Control";
      action = "Quit";
    }
  ];

  default = [
    {
      key = "Paste";
      action = "Paste";
    }
    {
      key = "Copy";
      action = "Copy";
    }
    {
      key = "L";
      mods = "Control";
      action = "ClearLogNotice";
    }
    {
      key = "L";
      mods = "Control";
      mode = "~Vi";
      chars = ''\x0c'';
    }
    {
      key = "PageUp";
      mods = "Shift";
      mode = "~Alt";
      action = "ScrollPageUp";
    }
    {
      key = "PageDown";
      mods = "Shift";
      mode = "~Alt";
      action = "ScrollPageDown";
    }
    {
      key = "Home";
      mods = "Shift";
      mode = "~Alt";
      action = "ScrollToTop";
    }
    {
      key = "End";
      mods = "Shift";
      mode = "~Alt";
      action = "ScrollToBottom";
    }

    # Vi Mode
    {
      key = "Space";
      mods = "Shift|Control";
      mode = "Vi";
      action = "ScrollToBottom";
    }
    {
      key = "Space";
      mods = "Shift|Control";
      action = "ToggleViMode";
    }
    {
      key = "Escape";
      mode = "Vi";
      action = "ClearSelection";
    }
    {
      key = "I";
      mode = "Vi";
      action = "ScrollToBottom";
    }
    {
      key = "I";
      mode = "Vi";
      action = "ToggleViMode";
    }
    {
      key = "Y";
      mods = "Control";
      mode = "Vi";
      action = "ScrollLineUp";
    }
    {
      key = "E";
      mods = "Control";
      mode = "Vi";
      action = "ScrollLineDown";
    }
    {
      key = "G";
      mode = "Vi";
      action = "ScrollToTop";
    }
    {
      key = "G";
      mods = "Shift";
      mode = "Vi";
      action = "ScrollToBottom";
    }
    {
      key = "B";
      mods = "Control";
      mode = "Vi";
      action = "ScrollPageUp";
    }
    {
      key = "F";
      mods = "Control";
      mode = "Vi";
      action = "ScrollPageDown";
    }
    {
      key = "U";
      mods = "Control";
      mode = "Vi";
      action = "ScrollHalfPageUp";
    }
    {
      key = "D";
      mods = "Control";
      mode = "Vi";
      action = "ScrollHalfPageDown";
    }
    {
      key = "Y";
      mode = "Vi";
      action = "Copy";
    }
    {
      key = "Y";
      mode = "Vi";
      action = "ClearSelection";
    }
    {
      key = "Copy";
      mode = "Vi";
      action = "ClearSelection";
    }
    {
      key = "V";
      mode = "Vi";
      action = "ToggleNormalSelection";
    }
    {
      key = "V";
      mods = "Shift";
      mode = "Vi";
      action = "ToggleLineSelection";
    }
    {
      key = "V";
      mods = "Control";
      mode = "Vi";
      action = "ToggleBlockSelection";
    }
    {
      key = "V";
      mods = "Alt";
      mode = "Vi";
      action = "ToggleSemanticSelection";
    }
    {
      key = "Return";
      mode = "Vi";
      action = "Open";
    }
    {
      key = "K";
      mode = "Vi";
      action = "Up";
    }
    {
      key = "J";
      mode = "Vi";
      action = "Down";
    }
    {
      key = "H";
      mode = "Vi";
      action = "Left";
    }
    {
      key = "L";
      mode = "Vi";
      action = "Right";
    }
    {
      key = "Up";
      mode = "Vi";
      action = "Up";
    }
    {
      key = "Down";
      mode = "Vi";
      action = "Down";
    }
    {
      key = "Left";
      mode = "Vi";
      action = "Left";
    }
    {
      key = "Right";
      mode = "Vi";
      action = "Right";
    }
    {
      key = "Key0";
      mode = "Vi";
      action = "First";
    }
    {
      key = "Key4";
      mods = "Shift";
      mode = "Vi";
      action = "Last";
    }
    {
      key = "Key6";
      mods = "Shift";
      mode = "Vi";
      action = "FirstOccupied";
    }
    {
      key = "H";
      mods = "Shift";
      mode = "Vi";
      action = "High";
    }
    {
      key = "M";
      mods = "Shift";
      mode = "Vi";
      action = "Middle";
    }
    {
      key = "L";
      mods = "Shift";
      mode = "Vi";
      action = "Low";
    }
    {
      key = "B";
      mode = "Vi";
      action = "SemanticLeft";
    }
    {
      key = "W";
      mode = "Vi";
      action = "SemanticRight";
    }
    {
      key = "E";
      mode = "Vi";
      action = "SemanticRightEnd";
    }
    {
      key = "B";
      mods = "Shift";
      mode = "Vi";
      action = "WordLeft";
    }
    {
      key = "W";
      mods = "Shift";
      mode = "Vi";
      action = "WordRight";
    }
    {
      key = "E";
      mods = "Shift";
      mode = "Vi";
      action = "WordRightEnd";
    }
    {
      key = "Key5";
      mods = "Shift";
      mode = "Vi";
      action = "Bracket";
    }
    {
      key = "Slash";
      mode = "Vi";
      action = "SearchForward";
    }
    {
      key = "Slash";
      mods = "Shift";
      mode = "Vi";
      action = "SearchBackward";
    }
    {
      key = "N";
      mode = "Vi";
      action = "SearchNext";
    }
    {
      key = "N";
      mods = "Shift";
      mode = "Vi";
      action = "SearchPrevious";
    }
  ];
in
default
++ (
  if stdenv.hostPlatform.isDarwin then
    darwin
  else if stdenv.hostPlatform.isLinux then
    linux
  else
    [ ]
)
