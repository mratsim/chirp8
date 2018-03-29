# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

import ./datatypes

type
  WordBytes = object
    # Word size is 16-bit.
    # Order is big endian
    lo, hi: byte

  Word {.union.} = object
    word: uint16
    bytes: WordBytes

proc initCPU*(): CPU {.noSideEffect.} =
  result.pc = 512

proc fetch(cpu: Cpu): Word {.noSideEffect.} =
  result.bytes.lo = cpu.memory[cpu.pc]
  result.bytes.hi = cpu.memory[cpu.pc + 1]
