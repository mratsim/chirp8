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

proc parseKeyInput(key: cint): char =
  ## parses the key input from SDL2 by the cint constants
  ## TODO: replace hardcoded keys with keys read from .cfg
  case key:
  of K_UP:
    result = '1'
  of K_DOWN:
    result = '4'
  of K_LEFT:
    result = '2'
  of K_RIGHT:
    result = '6'
  of K_Q:
    result = '0'
  of K_W:
    result = '8'
  of K_E:
    result = '3'
  of K_R:
    result = '5'
  of K_A:
    result = '7'
  of K_S:
    result = '9'
  of K_D:
    result = 'A'
  of K_F:
    result = 'B'
  of K_Z:
    result = 'C'
  of K_X:
    result = 'D'
  of K_C:
    result = 'E'
  of K_V:
    result = 'F'
  else:
    result = 'q'

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
        let key = parseKeyInput(gameState.event.key.keysym.sym)
        case key:
        of 'q':
          gameState.running = false
        else:
          gameState.keyDown(key)
      of KeyUp:
        let key = parseKeyInput(gameState.event.key.keysym.sym)
        gameState.keyUp(key)
      else:
        break

    for ins_count in 0 ..< Speed:
      gameState.execute gameState.fetch.decode

    gameState.updateScreen
    gameState.dec_timers
    sdl2.delay(Fps)

main()
