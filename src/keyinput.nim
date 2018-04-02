import parsecfg, tables, strformat
import sdl2

proc getSdlKeybindingMap*(): Table[string, cint] =
  # returns a table mapping string names of keys in SDL2 to the corresponding
  # cint values
  result = { "BACKSPACE" : K_BACKSPACE,
             "TAB" : K_TAB,
             "RETURN" : K_RETURN,
             "ESCAPE" : K_ESCAPE,
             "SPACE" : K_SPACE,
             "EXCLAIM" : K_EXCLAIM,
             "QUOTEDBL" : K_QUOTEDBL,
             "HASH" : K_HASH,
             "DOLLAR" : K_DOLLAR,
             "PERCENT" : K_PERCENT,
             "AMPERSAND" : K_AMPERSAND,
             "QUOTE" : K_QUOTE,
             "LEFTPAREN" : K_LEFTPAREN,
             "RIGHTPAREN" : K_RIGHTPAREN,
             "ASTERISK" : K_ASTERISK,
             "PLUS" : K_PLUS,
             "COMMA" : K_COMMA,
             "MINUS" : K_MINUS,
             "PERIOD" : K_PERIOD,
             "SLASH" : K_SLASH,
             "0" : K_0,
             "1" : K_1,
             "2" : K_2,
             "3" : K_3,
             "4" : K_4,
             "5" : K_5,
             "6" : K_6,
             "7" : K_7,
             "8" : K_8,
             "9" : K_9,
             "COLON" : K_COLON,
             "SEMICOLON" : K_SEMICOLON,
             "LESS" : K_LESS,
             "EQUALS" : K_EQUALS,
             "GREATER" : K_GREATER,
             "QUESTION" : K_QUESTION,
             "AT" : K_AT,
             "LEFTBRACKET" : K_LEFTBRACKET,
             "BACKSLASH" : K_BACKSLASH,
             "RIGHTBRACKET" : K_RIGHTBRACKET,
             "CARET" : K_CARET,
             "UNDERSCORE" : K_UNDERSCORE,
             "BACKQUOTE" : K_BACKQUOTE,
             "A" : K_A,
             "B" : K_B,
             "C" : K_C,
             "D" : K_D,
             "E" : K_E,
             "F" : K_F,
             "G" : K_G,
             "H" : K_H,
             "I" : K_I,
             "J" : K_J,
             "K" : K_K,
             "L" : K_L,
             "M" : K_M,
             "N" : K_N,
             "O" : K_O,
             "P" : K_P,
             "Q" : K_Q,
             "R" : K_R,
             "S" : K_S,
             "T" : K_T,
             "U" : K_U,
             "V" : K_V,
             "W" : K_W,
             "X" : K_X,
             "Y" : K_Y,
             "Z" : K_z,
             "DELETE" : K_DELETE,
             "CAPSLOCK" : K_CAPSLOCK,
             "F1" : K_F1,
             "F2" : K_F2,
             "F3" : K_F3,
             "F4" : K_F4,
             "F5" : K_F5,
             "F6" : K_F6,
             "F7" : K_F7,
             "F8" : K_F8,
             "F9" : K_F9,
             "F10" : K_F10,
             "F11" : K_F11,
             "F12" : K_F12,
             "PRINTSCREEN" : K_PRINTSCREEN,
             "SCROLLLOCK" : K_SCROLLLOCK,
             "PAUSE" : K_PAUSE,
             "INSERT" : K_INSERT,
             "HOME" : K_HOME,
             "PAGEUP" : K_PAGEUP,
             "END" : K_END,
             "PAGEDOWN" : K_PAGEDOWN,
             "RIGHT" : K_RIGHT,
             "LEFT" : K_LEFT,
             "DOWN" : K_DOWN,
             "UP" : K_UP }.toTable()

proc readKeyCfg*(filename: string): array['0'..'F', cint] =
  var dict = loadConfig(filename)
  let keymap = getSdlKeybindingMap()
  # create a key array to store the keys we use
  for c in {'0'..'9', 'A'..'F'}:
    result[c] = keymap[dict.getSectionValue("Keybindings", &"Key_{c}")]
  # now add special keybindings
  # NOTE: we reuse some spare elements left in the output array, since
  # the range '0'..'F' also includes
  # ':', ';', '<', '=', '>', '?', '@'
  # < as exit
  result['<'] = keymap[dict.getSectionValue("Keybindings", "Key_Exit")]
  # > as reload
  result['>'] = keymap[dict.getSectionValue("Keybindings", "Key_Reload")]  

proc parseKeyInput*(keys: array['0'..'F', cint], key: cint): char =
  ## parses the key input from SDL2 by the cint constants
  # set return value to "quit". If given key does not match any known
  # keys, value remains and we quit
  result = 'q'
  for c in {'0'..'9', 'A'..'F'}:
    if keys[c] == key:
      result = c
  # check quit key (see note in readKeyCfg
  if keys['<'] == key:
    # also set to 'q' (may remove the 'q' as default in the future)
    result = 'q'
  # check reload key
  if keys['>'] == key:
    result = '>'

