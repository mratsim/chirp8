# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import sdl2, streams, os
import ./display, ./cpu, ./datatypes, ./keyinput

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

proc runRom(gameState: var GameState, romPath: string, keys: array['0'..'F', cint]): bool =
  ## contains main routine, which runs the ROM
  # result variable is used to reload the ROM in case the reload key is
  # pressed. Default we do not 
  result = false
  gameState.loadRom(romPath)

  updateScreen(gameState)
  while gameState.running:
    while sdl2.pollEvent(gameState.event):
      case gameState.event.kind:
      of QuitEvent:
        gameState.running = false
        break
      of KeyDown:
        let key = parseKeyInput(keys, gameState.event.key.keysym.sym)
        case key:
        of 'q':
          gameState.running = false
        of '>':
          # means to reload the ROM
          echo "Reloading the ROM now!"
          result = true
          gameState.running = false
        else:
          gameState.keyDown(key)
      of KeyUp:
        let key = parseKeyInput(keys, gameState.event.key.keysym.sym)
        gameState.keyUp(key)
      else:
        break

    for ins_count in 0 ..< Speed:
      gameState.execute gameState.fetch.decode

    gameState.updateScreen
    gameState.dec_timers
    sdl2.delay(Fps)
  
proc main() =
  assert commandLineParams().len == 1, "There should be only one argument, the path of the rom to load"
  let romPath = $commandLineParams()[0]
  discard sdl2.init(INIT_EVERYTHING)

  # get keybinding
  let keys = readKeyCfg("keybindings.cfg")

  # start the game
  var gameState = startGame()
  # check whether ROM is reloaded
  while gameState.runRom(romPath, keys):
    # if the return value is true, we reload the ROM
    # i.e. clear screen, set CPU to start register again and
    # set it back to running
    gameState.clearScreen()
    gameState.cpu = initCpu()
    gameState.running = true
    
  
main()
