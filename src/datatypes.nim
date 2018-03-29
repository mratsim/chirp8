# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

##############################   Cpu   #########################################

type
  Cpu* = object
    memory*: array[4096, byte] # Chip-8 is capable of addressing 4096 bytes of RAM
                              # The first 512 bytes are reserved to the original interpreter
    V*: array['0'..'F', uint8] # Chip-8 has 16 registers from V0 to VF
    I*: uint16                 # memory address register
    stack*: array[16, uint16]
    sp*: uint8                 # Stack pointer. Point to the top level of the stack
    delay_timer*: uint8
    sound_timer*: uint8
    pc*: uint16                # Program Counter, currently executing address

##############################   Cpu   #########################################

############################## Display #########################################
import sdl2

const
  Width: cint  = 64
  Height: cint = 32
  DimPix* = 8
  WidthScaled* = Width * DimPix
  HeightScaled* = Height * DimPix

type
  Color* = enum
    Black, White

  Pixel* = object
    pos*: Rect # SDL_Rect
    color*: Color

  Pixels* = object
    data*: array[Height * Width, Pixel]

proc `[]`*(pxs: Pixels, x, y: int): Pixel {.noSideEffect.}=
  pxs.data[x * Width + y * Height]

proc `[]`*(pxs: var Pixels, x, y: int): var Pixel {.noSideEffect.}=
  pxs.data[x * Width + y * Height]

proc `[]=`*(pxs: var Pixels, x, y: int, val: Pixel): Pixel {.noSideEffect.}=
  pxs.data[x * Width + y * Height] = val

iterator items*(pxs: Pixels): Pixel {.noSideEffect.} =
  for pixel in pxs.data:
    yield pixel
############################## Display #########################################

###########################   Game State   #####################################

const
  Speed* = 4 # Todo replace by "Cycles per second" and associate each instruction with a number of cycle
  Fps*   = 16 # Frame per second

type
  BlackWhitePixels* = array[Black..White, SurfacePtr]
    ## This will store the "black" and "white" pixel that will be blitted on screen
    ## Black and White can be changed to the color of your choice

  GameState* = object
    cpu*: Cpu
    event*: sdl2.Event
    running*: bool
    video*: Pixels
    window*: WindowPtr
    renderer*: RendererPtr
    screen*: SurfacePtr
    texture*: TexturePtr
    BlackWhite*: BlackWhitePixels

###########################   Game State   #####################################
