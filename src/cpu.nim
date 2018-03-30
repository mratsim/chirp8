# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import ./datatypes, ./display, strutils, random

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
    Skne,      # 4XNN # Skip if VX != NN
    Skre,      # 5XY0 # Skip if VX == VY
    Movv,      # 6XNN # VX = NN
    Addv,      # 7XNN # VX += NN
    Mov,       # 8XY0 # VX = VY
    Or,        # 8XY1 # VX = VX or VY
    And,       # 8XY2 # VX = VX and VY
    Xor,       # 8XY3 # VX = VX xor VY
    Add,       # 8XY4 # VX += VY, VF = Carry
    Sub,       # 8XY5 # VX -= VY, VF = NO! Borrow
    Subn,      # 8XY7 # VX = VY - VX, VF = NO! Borrow
    Shr,       # 8X06 # VX shr 1, VF = bit 0
    Shl,       # 8X0E # VX shl 1, VF = bit 7
    Skrne,     # 9XY0 # Skip next instruction if VX != VY
    Movi,      # ANNN # I = NNN
    Jump0,     # BNNN # Jump at NNN + V0
    Rand,      # CXNN # Generate a random number 0.. 255 and "and" with the content of VX
    Draw,      # DXYN # Draw N height sprite at address I at position VX and VY. VF = 1 if pixels are unset (1 xor 1)
    Skke,      # EX9E # Skip next instruction if key_hex(VX) is pressed
    Skkne,     # EXA1 # Skip next instruction if key_hex(VX) is not pressed
    Movdelay,  # FX07 # VX = delay_timer
    Key,       # FX0A # VX = key_press (blocking)
    Delay,     # FX15 # delay_timer = VX
    Sound,     # FX18 # sound_timer = VX
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
    of Ske, Skne, Movv, Addv, Rand:
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
    of Movdelay, Delay, Sound:
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

{.this: self.}
proc dec_timers*(self: var GameState) {.noSideEffect.} =
  if cpu.delay_timer != 0:
    dec cpu.delay_timer
  if cpu.sound_timer != 0:
    dec cpu.sound_timer

############################## Fetch #########################################

proc fetch*(self: GameState): Opcode {.noSideEffect, inline.} =

  # Big Endian fetching
  result.bytes.hi = cpu.memory[cpu.pc]
  result.bytes.lo = cpu.memory[cpu.pc + 1]

############################## Fetch #########################################

############################## Decode #########################################

proc decode*(opcode: Opcode): Instruction {.noSideEffect.} =

  # Templates to avoid copy paste
  template fatal() =
    raise newException(KeyError, "Fatal: unknown instruction: " & $opcode.word.toHex)

  template check_lo(mask: byte) =
    if unlikely((opcode.bytes.lo and mask) != 0x00):
      fatal()

  template isEven(x: SomeInteger): bool =
    (x and 1) == 0

  # Note: Nim will auto check that we assign to the proper Kind
  template setMemAddr(Kind: InstructionKind) =
    result.kind = Kind
    result.memaddr = opcode.word and 0x0FFF

  template setRegVal(Kind: InstructionKind) =
    result.kind = Kind
    result.reg = toRegisterV opcode.bytes.hi and 0x0F
    result.val = opcode.bytes.lo

  template setVxVy(Kind: InstructionKind) =
    result.kind = Kind
    result.vx = toRegisterV opcode.bytes.hi and 0x0F
    result.vy = toRegisterV `shr`(opcode.bytes.lo and 0xF0, 4)

  template setShift(Kind: InstructionKind) =
    result.kind = Kind
    result.sh_vx = toRegisterV opcode.bytes.hi and 0x0F

  template setDraw(Kind: InstructionKind) =
    result.kind = Kind
    result.draw_vx = toRegisterV opcode.bytes.hi and 0x0F
    result.draw_vy = toRegisterV `shr`(opcode.bytes.lo and 0xF0, 4)
    result.height = opcode.bytes.lo and 0x0F

  template setKey(Kind: InstructionKind) =
    result.kind = Kind
    result.key_vx = toRegisterV opcode.bytes.hi and 0x0F

  template setTimer(Kind: InstructionKind) =
    result.kind = Kind
    result.timer_vx = toRegisterV opcode.bytes.hi and 0x0F

  template setAddi(Kind: InstructionKind) =
    result.kind = Kind
    result.addi_vx = toRegisterV opcode.bytes.hi and 0x0F

  template setChar(Kind: InstructionKind) =
    result.kind = Kind
    result.char_addr = opcode.bytes.hi and 0x0F

  template setBCD(Kind: InstructionKind) =
    result.kind = Kind
    result.bcd_vx = toRegisterV opcode.bytes.hi and 0x0F

  template setLoadStor(Kind: InstructionKind) =
    result.kind = Kind
    result.end_vx = toRegisterV opcode.bytes.hi and 0x0F

  when defined(debug):
    debugecho "\nNext raw opcode: " & opcode.word.toHex

  # At first level we check the most significant byte.
  # Case statements should be transformed into a jump table
  # which should perform in logarithmic time
  case opcode.bytes.hi and 0xF0:
  of 0x00:
    case opcode.word:
    of 0x00E0: result.kind = Clr
    of 0x00EE: result.kind = Ret
    else: fatal()
  of 0x10: setMemAddr(Jump)
  of 0x20: setMemAddr(Call)
  of 0x30: setRegVal(Ske)
  of 0x40: setRegVal(Skne)
  of 0x50: check_lo(0x0F); setVxVy(Skre)
  of 0x60: setRegVal(Movv)
  of 0x70: setRegVal(Addv)
  of 0x80:
    case opcode.bytes.lo and 0x0F:
    of 0x00: setVxVy(Mov)
    of 0x01: setVxVy(Or)
    of 0x02: setVxVy(And)
    of 0x03: setVxVy(Xor)
    of 0x04: setVxVy(Add)
    of 0x05: setVxVy(Sub)
    of 0x07: setVxVy(Subn)
    of 0x06: check_lo(0xF0); setShift(Shr)
    of 0x0E: check_lo(0xF0); setShift(Shl)
    else: fatal()
  of 0x90: check_lo(0x0F); setVxVy(Skrne)
  of 0xA0: setMemAddr(Movi)
  of 0xB0: setMemAddr(Jump0)
  of 0xC0: setRegVal(Rand)
  of 0xD0: setDraw(Draw)
  of 0xE0:
    case opcode.bytes.lo:
    of 0x9E: setKey(Skke)
    of 0xA1: setKey(Skkne)
    else: fatal()
  of 0xF0:
    case opcode.bytes.lo:
    of 0x07: setTimer(Movdelay)
    of 0x0A: setKey(Key)
    of 0x15: setTimer(Delay)
    of 0x18: setTimer(Sound)
    of 0x1E: setAddi(Addi)
    of 0x29: setChar(Char)
    of 0x33: setBCD(StorBCD)
    of 0x55: setLoadStor(Stor)
    of 0x65: setLoadStor(Load)
    else: fatal()
  else: fatal()

############################## Decode #########################################

############################## Execute #########################################

iterator unpack(sprite_line: byte): tuple[idx: int, pixSet: bool] {.noSideEffect, inline.} =
  yield (0, bool((sprite_line and 0b10000000) shr 7))
  yield (1, bool((sprite_line and 0b01000000) shr 6))
  yield (2, bool((sprite_line and 0b00100000) shr 5))
  yield (3, bool((sprite_line and 0b00010000) shr 4))
  yield (4, bool((sprite_line and 0b00001000) shr 3))
  yield (5, bool((sprite_line and 0b00000100) shr 2))
  yield (6, bool((sprite_line and 0b00000010) shr 1))
  yield (7, bool( sprite_line and 0b00000001))

proc draw_dxyn(self: var GameState, ins: Instruction) {.noSideEffect.} =
  # Draw N height sprite at position VX and VY. VF = 1 if pixels are unset (1 xor 1)
  # Data is taken from address starting at I

  assert ins.kind == Draw

  let
    offsetX = int cpu.V[ins.draw_vx]
    offsetY = int cpu.V[ins.draw_vy]
    borderY = int min(offsetY + ins.height.int, Height) # Don't go past the screen

  for iy in 0 ..< borderY - offsetY:
    let y = offsetY + iy
    for ix, pixel in unpack(cpu.memory[cpu.I + iy.uint16]):
      let x = offsetX + ix
      if pixel and (x < Width): # Don't go past the screen
        if video[x, y].color == White:
          # if a pixel is already white, it is unset and VF "detects a collision"
          cpu.V['F'] = 1
        video[x, y].color = video[x, y].color xor White

proc execute*(self: var GameState, ins: Instruction) {.noSideEffect.} =
  template next() =
    # Next instruction is 2 bytes away
    inc cpu.pc, 2

  when defined(debug):
    debugecho "V: " & $self.cpu.V
    debugecho "pc: " & $self.cpu.pc
    debugecho "stack: " & $self.cpu.stack
    debugecho "I: " & $self.cpu.I
    debugecho "To be executed: " & $ins

  case ins.kind:
  of Clr: clearScreen();                                         next()
  of Ret: cpu.pc = cpu.stack.pop;                                next()
  of Jump: cpu.pc = ins.memaddr                                  ######
  of Call: cpu.stack.push cpu.pc; cpu.pc = ins.memaddr           ######
  of Ske:
    if cpu.V[ins.reg] == ins.val: next()
    next()
  of Skne:
    if cpu.V[ins.reg] != ins.val: next()
    next()
  of Skre:
    if cpu.V[ins.vx] == cpu.V[ins.vy]: next()
    next()
  of Movv: cpu.V[ins.reg] = ins.val;                             next()
  of Addv: cpu.V[ins.reg] += ins.val;                            next()
  of Mov: cpu.V[ins.vx] = cpu.V[ins.vy];                         next()
  of Or: cpu.V[ins.vx] = cpu.V[ins.vx] or cpu.V[ins.vy];         next()
  of And: cpu.V[ins.vx] = cpu.V[ins.vx] and cpu.V[ins.vy];       next()
  of Xor: cpu.V[ins.vx] = cpu.V[ins.vx] xor cpu.V[ins.vy];       next()
  of Add:
    cpu.V[ins.vx] += cpu.V[ins.vy]
    # test if carry
    cpu.V['F'] = (cpu.V[ins.vx] < cpu.V[ins.vy]).uint8
    next()
  of Sub:
    cpu.V[ins.vx] -= cpu.V[ins.vy]
    # test if NO! borrow
    cpu.V['F'] = (cpu.V[ins.vx] <= not cpu.V[ins.vy]).not.uint8
    next()
  of Subn:
    cpu.V[ins.vx] = cpu.V[ins.vy] - cpu.V[ins.vx]
    # test if NO! borrow
    cpu.V['F'] = (cpu.V[ins.vx] > cpu.V[ins.vy]).not.uint8
    next()
  of Shr:
    cpu.V['F'] = cpu.V[ins.vx] and 1 # extract bit 0
    cpu.V[ins.vx] = cpu.V[ins.vx] shr 1
    next()
  of Shl:
    cpu.V['F'] = (cpu.V[ins.vx] shr 7) and 1 # extract bit 7
    cpu.V[ins.vx] = cpu.V[ins.vx] shl 1
    next()
  of Skrne:
    if cpu.V[ins.vx] != cpu.V[ins.vy]: next()
    next()
  of Movi: cpu.I = ins.memaddr;                                  next()
  of Jump0: cpu.pc = ins.memaddr + cpu.V['0']                    ######
  of Rand: cpu.V[ins.reg] = rand(0 .. 255).uint8 and ins.val;    next()
  of Draw: draw_dxyn(self, ins);                                 next()
  of Skke: discard; next()                            ### TODO Stub ###
  of Skkne:discard; next()                            ### TODO Stub ###
  of Movdelay: cpu.V[ins.timer_vx] = cpu.delay_timer;            next()
  of Key:  discard; next()                            ### TODO Stub ###
  of Delay: cpu.delay_timer = cpu.V[ins.timer_vx];               next()
  of Sound: cpu.sound_timer = cpu.V[ins.timer_vx];               next()
  of Addi: cpu.I += cpu.V[ins.addi_vx];                          next()
  of Char: cpu.I = ins.char_addr;                                next()
  of Storbcd: discard; next()                         ### TODO Stub ###
  of Stor:    discard; next()                         ### TODO Stub ###
  of Load:    discard; next()                         ### TODO Stub ###

############################## Execute #########################################
