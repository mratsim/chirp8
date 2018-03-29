packageName   = "chirp8"
version       = "0.0.1"
author        = "Mamy André-Ratsimbazafy"
description   = "A Chip-8 emulator written in Nim"
license       = "Apache License 2.0 or MIT"
srcDir        = "src"

### Dependencies

requires "nim >= 0.18", "sdl2"

proc test(name: string, lang: string = "c") =
  if not dirExists "build":
    mkDir "build"
  if not dirExists "nimcache":
    mkDir "nimcache"
  --run
  --nimcache: "nimcache"
  switch("out", ("./build/" & name))
  setCommand lang, "tests/" & name & ".nim"
