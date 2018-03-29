# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import ./datatypes

const
  StartProg = 512'u16 # The first 512 bytes are reserved for the interpreter

type
  ProgMem   = range[StartProg .. MaxMem - 1]

  WordBytes = object
    ## Word size is 16-bit.
    ## Order is big endian
    lo, hi: byte

  Opcode {.union.} = object
    ## Raw 16-bit opcode
    word: uint16
    bytes: WordBytes

  InstructionKind = enum
    Clr,       # 00E0 # Clear screen
    Ret,       # 00EE # Return from subroutine
    # Rca,       # 0NNN # Execute subroutine in RCA 1802 processor
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
    Sub,       # 8XY5 # VX -= VY, VF = Borrow
    Subn,      # 8XY7 # VX = VY - VX, VF = Borrow
    Shr,       # 8X06 # VX shr 1, VF = bit 0
    Shl,       # 8X0E # VX shl 1, VF = bit 7
    Skrne,     # 9XY0 # Skip next instruction if VX != VY
    Movi,      # ANNN # I = NNN
    Jump0,     # BNNN # Jump at NNN + V0
    Rnd,       # CXNN # Generate a random number [0..nn] in VX
    Draw,      # DXYN # Draw N byte sprite at address I at position VX and VY. VF = 1 if pixels are unset
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
    of Skre, Mov, Or, And, Xor, Add, Sub, Subn, Shr, Shl, Skrne, Draw:
      vx, vy: RegisterV
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

proc `$`(mem: ProgMem): string =
  # Workaround otherwise I get ambiguous call
  system.`$`(mem.int)

proc fetch(cpu: Cpu): Opcode {.noSideEffect.} =
  result.bytes.lo = cpu.memory[cpu.pc]
  result.bytes.hi = cpu.memory[cpu.pc + 1]


