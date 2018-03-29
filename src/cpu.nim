# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import ./datatypes

const
  StartProg = 0x200'u16 # The first 512 bytes are reserved for the interpreter

type
  ProgMem   = range[StartProg .. MaxMem - 1]

  WordBytes = object
    ## Word size is 16-bit.
    ## Order is big endian
    lo, hi: byte

  Opcode {.union.} = object
    ## Raw 16-bit opcode
    ## Can be accessed through its single word
    ## or 2 bytes representation
    word: uint16
    bytes: WordBytes

  InstructionKind = enum
    Clr,       # 00E0 # Clear screen
    Ret,       # 00EE # Return from subroutine
    # Rca,     # 0NNN # Execute subroutine in RCA 1802 processor
    Jump,      # 1NNN # Jump to NNN
    Call,      # 2NNN # Call routine at NNN
    Ske,       # 3XNN # Skip next instruction if VX == NN
    Skne,      # 4XNN # Do not skip if VX == NN
    Skre,      # 5XY0 # Skip if VX == VY
    Movv,      # 6XNN # VX = NN
    Addv,      # 7XNN # VX += NN
    Mov,       # 8XY0 # VX = VY
    Or,        # 8XY1 # VX = VX or VY
    And,       # 8XY3 # VX = VX and VY
    Xor,       # 8XY3 # VX = VX xor VY
    Add,       # 8XY4 # VX += VY, VF = Carry
    Sub,       # 8XY5 # VX -= VY, VF = NO! Borrow
    Subn,      # 8XY7 # VX = VY - VX, VF = NO! Borrow
    Shr,       # 8X06 # VX shr 1, VF = bit 0
    Shl,       # 8X0E # VX shl 1, VF = bit 7
    Skrne,     # 9XY0 # Skip next instruction if VX != VY
    Movi,      # ANNN # I = NNN
    Jump0,     # BNNN # Jump at NNN + V0
    Rnd,       # CXNN # Generate a random number [0..nn] in VX
    Draw,      # DXYN # Draw N height sprite at address I at position VX and VY. VF = 1 if pixels are unset (1 xor 1)
    Skke,      # EX9E # Skip next instruction if key_hex(VX) is pressed
    Skkne,     # EXA1 # Skip next instruction if key_hex(VX) is not pressed
    Movd,      # FX07 # VX = delay_timer
    Key,       # FX0A # VX = key_press (blocking)
    Setd,      # FX15 # delay_timer = VX
    Sets,      # FX18 # sound_timer = VX
    Addi,      # FX1E # I += VX
    Char,      # FX29 # I = Memory address of default sprite characters '0'..'F'
    Storbcd,   # FX33 # memory[I ..< I+3] = Binary-coded-decimal(VX)
    Stor,      # FX55 # memory[I .. I+X] = values(V0 .. VX)
    Load,      # FX65 # V0 .. VX = memory[I .. I+X]

  Instruction = object
    case kind: InstructionKind
    of Clr, Ret:
      discard
    of Jump, Call, Movi, Jump0:
      memaddr: ProgMem
    of Ske, Skne, Movv, Addv, Rnd:
      val: uint8
      reg: RegisterV
    of Skre, Mov, Or, And, Xor, Add, Sub, Subn, Skrne:
      vx, vy: RegisterV
    of Shr, Shl:
      sh_vx: RegisterV
    of Draw:
      draw_vx, draw_vy: RegisterV
      height: uint8
    of Skke, Skkne, Key:
      key_vx: RegisterV
    of Movd, Setd, Sets:
      timer_vx: RegisterV
    of Addi:
      addi_vx: RegisterV
    of Char:
      char_addr: range[0'u16 .. StartProg - 1]
    of Storbcd:
      bcd_vx: RegisterV
    of Stor, Load:
      end_vx: RegisterV

proc initCPU*(): CPU {.noSideEffect.} =
  result.pc = StartProg

proc `$`(mem: ProgMem): string  {.noSideEffect, inline.} =
  # Workaround otherwise I get ambiguous call
  system.`$`(mem.int)

############################## Fetch #########################################

proc fetch(cpu: Cpu): Opcode {.noSideEffect, inline.} =

  # Big Endian fetching
  result.bytes.hi = cpu.memory[cpu.pc]
  result.bytes.lo = cpu.memory[cpu.pc + 1]

############################## Fetch #########################################

############################## Decode #########################################

proc decode(opcode: Opcode): Instruction {.noSideEffect.} =
  if opcode.word == 0x00E0:
    result.kind = Clr
  elif opcode.word == 0x00EE:
    result.kind = Ret
  else:
    assert false

############################## Decode #########################################

############################## Execute #########################################

iterator unpack(sprite_line: byte): tuple[idx: uint8, pixSet: bool] {.noSideEffect, inline.} =
  yield (0'u8, bool((sprite_line and 0b10000000) shr 7))
  yield (1'u8, bool((sprite_line and 0b10000000) shr 6))
  yield (2'u8, bool((sprite_line and 0b10000000) shr 5))
  yield (3'u8, bool((sprite_line and 0b10000000) shr 4))
  yield (4'u8, bool((sprite_line and 0b10000000) shr 3))
  yield (5'u8, bool((sprite_line and 0b10000000) shr 2))
  yield (6'u8, bool((sprite_line and 0b10000000) shr 1))
  yield (7'u8, bool(sprite_line and 0b10000000))

proc draw_dxyn(cpu: var CPU, pixels: var Pixels, ins: Instruction) {.noSideEffect.} =
  # Draw N height sprite at position VX and VY. VF = 1 if pixels are unset (1 xor 1)
  # Data is taken from address starting at I

  assert ins.kind == Draw

  let
    offsetY = cpu.V[ins.draw_vy]
    borderY = min(offsetY + ins.height, Height.uint8) # Don't go past the screen

  for row in offsetY ..< borderY:
    for idx, pix in unpack(cpu.memory[cpu.I + row]):
      let
        offsetX = cpu.V[ins.draw_vx]
        col = offsetX + idx
      if pix and col < Width.uint8: # Don't go past the screen
        if pixels[row, col].color == White:
          # if a pixel is already white, it is unset and VF "detects a collision"
          cpu.V['F'] = 1
        pixels[row, col].color = pixels[row, col].color xor White




############################## Execute #########################################

when isMainModule:

  let a = OpCode(word: 0x00EE)


  echo a.decode
