# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

##############################   Cpu   #########################################

const
  StartProg* = 0x200'u16 # The first 512 bytes are reserved for the interpreter
  MaxMem*    = 0xFFF'u16 # Chip-8 can address 0..<4096 bytes

type
  RegisterV* = range['0'..'F']
  Stack*     = object
    data*: array[16, uint16]
    len*:  uint8                     # Stack Pointer. Point to the top level of the stack

  Cpu* = object
    memory*: array[MaxMem+1, byte]  # Chip-8 is capable of addressing 4096 bytes of RAM
                                    # The first 512 bytes are reserved to the original interpreter
    V*: array[RegisterV, uint8]     # Chip-8 has 16 registers from V0 to VF
    key*: array[RegisterV, bool]
    I*: uint16                      # memory address register
    pc*: uint16                     # Program Counter, currently executing address
    stack*: Stack                   # Stack + Stack pointer
    delay_timer*: uint8
    sound_timer*: uint8

proc toRegisterV*(id: range[0x0 .. 0xF]): RegisterV {.inline.} =
  # Convert a register identifier to the matching Register
  char(ord('0') + id)

proc pop*(s: var Stack): uint16 {.inline, noSideEffect.}=
  if unlikely(s.len == 0):
    raise newException(StackOverflowError, "Fatal - stack underflow: trying to pop an empty stack")
  dec s.len
  result = s.data[s.len]
  s.data[s.len] = 0

proc push*(s: var Stack, v: uint16) {.inline, noSideEffect.}=
  if unlikely(s.len == 16):
    raise newException(StackOverflowError, "Fatal: stack is at full capacity")
  s.data[s.len] = v
  inc s.len

##############################   Cpu   #########################################

############################## Display #########################################
import sdl2

const
  Width*  = 64
  Height* = 32
  DimPix* = 8
  WidthScaled* = Width.cint * DimPix.cint   # SDL compat
  HeightScaled* = Height.cint * DimPix.cint

type
  Color* = enum
    Black, White

  Pixel* = object
    pos*: Rect # SDL_Rect
    color*: Color

  Pixels* = object
    data*: array[Width * Height, Pixel]

# Note on representation
# Space invaders alien would be:
#  Sprite map   Binary      Hex
#  X.XXX.X.     0b10111010  $BA
#  .XXXXX..     0b01111100  $7C
#  XX.X.XX.     0b11010110  $D6
#  XXXXXXX.     0b11111110  $FE
#  .X.X.X..     0b01010100  $54
#  X.X.X.X.     0b10101010  $AA

# Loading it would be
#  PC    Opcodes   Assembly
#  0210  620A      MOVV V2,#$0A
#  0212  630C      MOVV V3,#$0C
#  0214  A220      MOVI I,#$220
#  0216  D236      DRAW V2, V3, #$6
#  0218  1240      JUMP $240
#  0220  BA7C      Sprite data for 6 bytes
#  0222  D6FE
#  0224  54AA

# With coordinates
# (x: 0, y:0)              (x:63, y: 0) #
#                                       #
#                                       #
# (x: 0, y:31)             (x:63, y:31) #

# So data is stored in row-major order: the column (x) changes the fastest
{.experimental.}
proc `destroy=`*(s: SurfacePtr or WindowPtr or RendererPtr or TexturePtr) =
  destroy s

proc `[]`*(pxs: Pixels, x, y: Someinteger): Pixel {.noSideEffect, inline.}=
  pxs.data[y * Width + x]

proc `[]`*(pxs: var Pixels, x, y: Someinteger): var Pixel {.noSideEffect, inline.}=
  pxs.data[y * Width + x]

proc `[]=`*(pxs: var Pixels, x, y: Someinteger, val: Pixel): Pixel {.noSideEffect, inline.}=
  pxs.data[y * Width + x] = val

iterator items*(pxs: Pixels): Pixel {.noSideEffect, inline.} =
  for pixel in pxs.data:
    yield pixel

proc `xor`*(c1, c2: Color): Color {.noSideEffect, inline.}=
  Color(bool(c1) xor bool(c2))

############################## Display #########################################

###########################   Game State   #####################################

const
  Speed* = 4  # Todo replace by "Cycles per second" and associate each instruction with a number of cycle
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
