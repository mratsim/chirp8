# Chirp-8

[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

A Chip-8 emulator in Nim

Status: most of the instructions are properly emulated. This WIP
branch contains hardcoded key presses for two key input instructions:
`Ex9E` (skip next instruction if a key `x` is pressed) and `ExA1` (skip
next instruction if key `x` is not pressed). The instruction `F00A` is
yet to be implemented.

The hardcoded keys will soon be replaced by reading a config file.

Known used keys (in the current hardcoded scheme):

    Pong:
        Arrow up: paddle up
        Arrow down: paddle down
    Space Invaders:
        Arrow down: ship left
        Arrow right: ship right
    Tetris:
        R: move block left
        A: drop block faster
        Arrow down: rotate block
        Arrow right: move block right

As one can see, the keys are all over the place. :)

Some GIFs:

![Pong](images/pong.gif) ![Tetris](images/tetris.gif) ![Space Invaders](images/invaders.gif)
