# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import sdl2
import ./display, ./cpu, ./datatypes, ./gamestate

proc main() =
  discard sdl2.init(INIT_EVERYTHING)

  var gState = startGame()

  updateScreen(gState)

  while gState.running:
    while pollEvent(gState.event):
      case gState.event.kind:
      of QuitEvent:
        gState.running = false
        break
      of KeyDown:
        gState.running = false
        break
      else:
        break

main()
