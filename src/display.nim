# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import sdl2, ./datatypes

proc newScreen*(): SurfacePtr {.noSideEffect.} =
  result = createRGBSurface(0, WidthScaled, HeightScaled, 32,
                            0x00FF0000'u32,
                            0x0000FF00'u32,
                            0x000000FF'u32,
                            0xFF000000'u32)

proc newWindow*(): WindowPtr {.noSideEffect.} =
  result = createWindow("Chirp-8", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WidthScaled, HeightScaled, SDL_WINDOW_SHOWN)

proc newRenderer*(w: WindowPtr): RendererPtr {.noSideEffect.} =
  result = createRenderer(w, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

proc newPixel*(R, G, B: uint8): SurfacePtr {.noSideEffect.} =
  result = createRGBSurface(0, DimPix.cint,DimPix.cint,32,0,0,0,0)
  fillRect(result, nil, mapRGB(result.format, R, G, B))

{.this: self.}
proc drawPixel(self: var GameState, pix: Pixel) {.noSideEffect.} =
  blitSurface(BlackWhite[pix.color], nil, screen, unsafeAddr pix.pos)

proc newPixels*(): Pixels {.noSideEffect.}=
  for x in 0 ..< Width:
    for y in 0 ..< Height:
      let pos = addr result[x, y].pos
      pos.x = cint x * DimPix
      pos.y = cint y * DimPix
      pos.w = DimPix
      pos.h = DimPix

      if (x mod (y+1)) == 0:
        result[x, y].color = Black
      else:
        result[x, y].color = White

proc clearScreen*(self: var GameState) {.noSideEffect.} =
  video = newPixels()
  fillRect(screen, nil, Black.uint32)

proc display(self: GameState) {.noSideEffect.} =
  updateTexture(texture, nil, screen.pixels, screen.pitch)
  renderer.clear()
  renderer.copy(texture, nil, nil)
  renderer.present

proc updateScreen*(self: var GameState) {.noSideEffect.} =
  for pixel in video:
    drawPixel(pixel)
  display()
