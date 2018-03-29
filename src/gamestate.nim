# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import sdl2
import ./datatypes, ./display, ./cpu

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
