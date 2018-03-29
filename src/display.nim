# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

{.experimental.}

import sdl2

const
  Width: cint  = 64
  Height: cint = 32
  DimPix = 8
  WidthScaled = Width * DimPix
  HeightScaled = Height * DimPix

type
  Color* = enum
    Black, White

  Pixel* = object
    pos: Rect # SDL_Rect
    color: Color

  RefPixels* = array[Black..White, SurfacePtr] # This will store the black and white pixel that will be blitted on screen

  Pixels* = object
    data: array[Height * Width, Pixel]

proc `[]`*(pxs: Pixels, x, y: int): Pixel {.noSideEffect.}=
  pxs.data[x * Width + y * Height]

proc `[]`*(pxs: var Pixels, x, y: int): var Pixel {.noSideEffect.}=
  pxs.data[x * Width + y * Height]

proc `[]=`*(pxs: var Pixels, x, y: int, val: Pixel): Pixel {.noSideEffect.}=
  pxs.data[x * Width + y * Height] = val

iterator items(pxs: Pixels): Pixel {.noSideEffect.} =
  for pixel in pxs.data:
    yield pixel

proc newScreen*(): SurfacePtr {.noSideEffect.} =
  result = createRGBSurface(0, WidthScaled, HeightScaled, 32,
                            0x00FF0000'u32,
                            0x0000FF00'u32,
                            0x000000FF'u32,
                            0xFF000000'u32)

proc `destroy=`*(s: SurfacePtr) =
  destroy s

# proc newRenderer(screen: SurfacePtr): RendererPtr =
#   result = createRenderer(screen, )

proc newPixel*(R, G, B: uint8): SurfacePtr {.noSideEffect.} =
  result = createRGBSurface(0,DimPix,DimPix,32,0,0,0,0)
  fillRect(result, nil, mapRGB(result.format, R, G, B))

proc drawPixel(screen: SurfacePtr, refPix: RefPixels, pix: Pixel) {.noSideEffect.} =
  blitSurface(refPix[pix.color], nil, screen, unsafeAddr pix.pos)

proc clearScreen*(screen: SurfacePtr, pxs: var Pixels) {.noSideEffect.} =
  pxs = Pixels()
  fillRect(screen, nil, Black.uint32)
  # render

proc display(texture: TexturePtr, screen: SurfacePtr, renderer: RendererPtr) {.noSideEffect.} =
  updateTexture(texture, nil, screen.pixels, screen.pitch)
  renderer.clear()
  renderer.copy(texture, nil, nil)
  renderer.present

proc updateScreen*(renderer: RendererPtr, texture: TexturePtr, screen: SurfacePtr, refPix: RefPixels, pxs: Pixels) {.noSideEffect.} =
  for pixel in pxs:
    drawPixel(screen, refPix, pixel)
  display(texture, screen, renderer)
