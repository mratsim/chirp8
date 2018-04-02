# Chirp-8

[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

A Chip-8 emulator in Nim

Status: most of the instructions are properly emulated. This WIP
branch contains hardcoded key presses for two key input instructions:
`Ex9E` (skip next instruction if a key `x` is pressed) and `ExA1` (skip
next instruction if key `x` is not pressed). The instruction `F00A` is
yet to be implemented.

The keybindings are defined in the [](config/keybindings.cfg)
file. The location of the config file is currently hardcoded and
depends on the binary being called from `src`.

Some example keys for the current keybindings are as follows:

    Pong:
        Arrow up: paddle up
        Arrow down: paddle down
    Space Invaders:
        Arrow down: ship left
        Arrow right: ship right
    Tetris:
        W: move block left
        A: drop block faster
        Arrow down: rotate block
        Arrow right: move block right

As one can see, the keys are somewhat all over the place and in
principle need to be set for each game individually.

Some GIFs:

![Pong](images/pong.gif) ![Tetris](images/tetris.gif) ![Space Invaders](images/invaders.gif)

## Known issues

The emulation seems to be somewhat broken as of now. Collision
detection does not really work in some cases, e.g. the ball simply
resets before it hits the opposite paddle in pong and the blocks in
tetris fall through the floor. There is also quite some flickering
happening.
