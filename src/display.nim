# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

{.experimental.}

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

proc `destroy=`*(s: SurfacePtr or WindowPtr or RendererPtr or TexturePtr) =
  destroy s

proc newPixel*(R, G, B: uint8): SurfacePtr {.noSideEffect.} =
  result = createRGBSurface(0, DimPix.cint,DimPix.cint,32,0,0,0,0)
  fillRect(result, nil, mapRGB(result.format, R, G, B))

proc drawPixel(gState: var GameState, pix: Pixel) {.noSideEffect.} =
  blitSurface(gState.BlackWhite[pix.color], nil, gState.screen, unsafeAddr pix.pos)

proc newPixels*(): Pixels {.noSideEffect.}=
  for x in 0'u8 ..< Width:
    for y in 0'u8 ..< Height:
      let pos = addr result[x, y].pos
      pos.x = cint x * DimPix
      pos.y = cint y * DimPix

      result[x, y].color = Black

proc clearScreen*(gState: var GameState) {.noSideEffect.} =
  gState.video = newPixels()
  fillRect(gState.screen, nil, Black.uint32)

proc display(gState: GameState) {.noSideEffect.} =
  updateTexture(gState.texture, nil, gState.screen.pixels, gState.screen.pitch)
  gState.renderer.clear()
  gState.renderer.copy(gState.texture, nil, nil)
  gState.renderer.present

proc updateScreen*(gState: var GameState) {.noSideEffect.} =
  for pixel in gState.video:
    drawPixel(gState, pixel)
  gState.display
