# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import sdl2, streams, os
import ./display, ./cpu, ./datatypes

proc startGame*(): GameState =
  result.cpu = initCPU()
  result.event = sdl2.defaultEvent
  result.running = true
  result.video = newPixels()
  result.window = newWindow()
  result.renderer = newRenderer(result.window)
  result.screen = newScreen()
  result.texture = createTextureFromSurface(result.renderer, result.screen)
  result.BlackWhite = [newPixel(0,0,0), newPixel(0xFF,0xFF,0xFF)]

proc loadRom*(self: var GameState, romPath: string) =
  let fsize = romPath.getFileSize
  doAssert fsize <= MaxMem.int - StartProg.int, "The ROM file is larger than what the CHIP-8 supports"

  let stream = openFileStream(romPath, mode = fmRead)
  discard stream.readData(self.cpu.memory[StartProg].addr, fsize.int)

proc main() =
  assert commandLineParams().len == 1, "There should be only one argument, the path of the rom to load"
  discard sdl2.init(INIT_EVERYTHING)

  var gameState = startGame()
  gameState.loadRom($commandLineParams()[0])

  updateScreen(gameState)

  while gameState.running:
    while sdl2.pollEvent(gameState.event):
      case gameState.event.kind:
      of QuitEvent:
        gameState.running = false
        break
      of KeyDown:
        gameState.running = false
        break
      else:
        break

    for ins_count in 0 ..< Speed:
      gameState.execute gameState.fetch.decode

      gameState.updateScreen
      gameState.dec_timers
      sdl2.delay(Fps)

main()
