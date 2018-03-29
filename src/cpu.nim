# Copyright (c) 2018 Mamy André-Ratsimbazafy
# Distributed under the Apache v2 License (license terms are at http://www.apache.org/licenses/LICENSE-2.0).

type CPU = object
  memory: array[4096, byte] # Chip-8 is capable of addressing 4096 bytes of RAM
                            # The first 512 bytes are reserved to the original interpreter
  V: array['0'..'F', uint8] # Chip-8 has 16 registers from V0 to VF
  I: uint16                 # memory address register
  stack: array[16, uint16]
  SP: uint8                 # Stack pointer. Point to the top level of the stack
  delay_timer: uint8
  sound_timer: uint8
  PC: uint16                # Program Counter, currently executing address

proc initCPU(): CPU {.noSideEffect.} =
  result.PC = 512
