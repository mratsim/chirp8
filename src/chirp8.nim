# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import sdl2
import ./display

discard sdl2.init(INIT_EVERYTHING)

var
  evt = sdl2.defaultEvent
  runGame = true
  pixels: Pixels

let refPix: RefPixels = [newPixel(0,0,0), newPixel(0xFF,0xFF,0xFF)]


var
  window = createWindow("Chirp-8", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 640,480, SDL_WINDOW_SHOWN)
  renderer = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
  screen = newScreen()
  texture = createTextureFromSurface(renderer, screen)

updateScreen(renderer, texture, screen, refPix, pixels)

while runGame:
  while pollEvent(evt):
    case evt.kind:
    of QuitEvent:
      runGame = false
      break
    of KeyDown:
      runGame = false
      break
    else:
      break

