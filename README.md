# sw-cor24-basic

COR24 BASIC v1 — a 1970s time-sharing BASIC interpreter for the COR24
p-code VM.

## Overview

COR24 BASIC is a line-numbered, integer-only BASIC interpreter inspired
by UNIVAC 1100-series terminal BASIC with teletype and paper-tape
workflows. It runs on the COR24 p-code virtual machine and emphasizes
simplicity, hardware access (PEEK/POKE), and interactive program
development over compatibility with later BASIC standards.

## Architecture

```
BASIC interpreter (Pascal) → p24p → .spc → pa24r → .p24 → pvm.s → COR24
```

The interpreter is a Pascal program compiled to p-code. It runs on the
p-code VM as a language layer:

- **Layer 0**: COR24 hardware / emulator
- **Layer 1**: P-code VM (language-neutral abstract machine)
- **Layer 2**: BASIC runtime (I/O, line storage, stacks, PEEK/POKE)
- **Layer 3**: BASIC interpreter (tokenizer, parser, dispatch, execution)

## Dialect: COR24 BASIC v1

- Line-numbered stored programs, tokenized on entry
- Signed 24-bit integer arithmetic (no floating point)
- Interactive: immediate mode + stored program mode (RUN)
- Terminal/teletype oriented
- Statements: LET, PRINT, INPUT, IF...THEN, GOTO, GOSUB, RETURN,
  FOR...TO...STEP, NEXT, STOP, END, REM
- Commands: LIST, RUN, NEW, BYE (or Ctrl-D / Ctrl-] at prompt)
- Functions: PEEK, POKE, ABS, CHR$ (PRINT only)
- Logical operators: AND, OR (below comparison in precedence)
- Variables: A-Z (26 scalar integers)

## Positioning

BASIC complements Pascal in the COR24 ecosystem:

| | Pascal | BASIC |
|---|--------|-------|
| Execution | Compiled to p-code | Interpreted on p-code VM |
| Style | Structured, typed | Dynamic, interactive |
| Use case | Application development | Hardware bring-up, scripting, monitor |

## Status

**v1 in progress** — interpreter is end-to-end functional under
`pv24t`. All v1 statements work: LET, PRINT (with column-aware
formatting), INPUT (with `?REDO`), IF...THEN, GOTO, GOSUB/RETURN,
FOR/TO/STEP/NEXT, REM, STOP, END, PEEK/POKE. Commands LIST, RUN,
NEW, BYE all work.

Pipeline: `.pas → p24p → .spc → pl24r → pa24r → .p24 → pv24t`

The whole interpreter currently lives in a single file
`src/basic.pas`. Splitting into p-code units (steps 018–019) is
queued and will lift the remaining single-file source ceiling.

Known limitations:
- Source ceiling: p24p input buffer is currently 16384 bytes
  (bumped from 8192 in sw-cor24-pascal#2). Step 018/019 will
  remove this entirely via the unit build.
- LED MMIO and switch input are no-ops under `pv24t`. Real
  hardware paths via `cor24-emu` aren't wired into the build yet.
- One known runtime bug: ABS not initialized in keyword table
  (sw-cor24-basic#1).

## Building and running

```sh
./scripts/build-basic.sh        # compile src/basic.pas to build/basic.p24
./scripts/run-basic.sh examples/hello.bas
```

## Star Trek demo

`examples/startrek.bas` is a full Star Trek game showcasing GOSUB,
PEEK/POKE, FOR/NEXT, INPUT, and the PRNG. Commands: SRS, LRS, warp,
impulse, phasers, photon torpedoes, shields, status, help, and resign.
Coordinates use rows A-H and columns 1-8.

```sh
./scripts/demo-startrek.sh        # interactive play (requires pv24t)
./scripts/run-basic.sh examples/startrek.bas   # batch/scripted
```

A validation transcript is at `tests/startrek-transcript.txt`.

## Trek Adventure demo

`examples/trek-adventure.bas` is a text adventure translated from an
early-1980s magazine BASIC listing (see `docs/trek-adventure.txt`).
You wake alone on a doomed Enterprise, find tools and a tribble, and
have to patch the engine room before orbit decays. Commands are
numeric menus (integer-only dialect, no string variables).

```sh
./scripts/demo-trek-adventure.sh
```

Regression tests use `reg-rs` (golden-output regression tool, mirrors
the convention in sibling `sw-cor24-*` repos). Baselines live at
`reg-rs/basic_trek_*.{rgt,out}`; the input sequences live at
`tests/trek-adventure/cases/*.in` and are fed through
`tests/trek-adventure/driver.sh`. Run the full suite with:

```sh
./scripts/test.sh          # wraps: reg-rs run -p basic_ --parallel
```

## Demos

CLI demos under `scripts/demo-*.sh`. See [docs/demos.md](docs/demos.md)
for the full gallery.

```sh
./scripts/demo-hello.sh
./scripts/demo-calc.sh
./scripts/demo-fizzbuzz.sh
./scripts/demo-fibonacci.sh
./scripts/demo-factorial.sh
./scripts/demo-count.sh
./scripts/demo-memdump.sh
./scripts/demo-startrek.sh
./scripts/demo-trek-adventure.sh
```

## Dependencies

| Project | Repo | Role |
|---------|------|------|
| P-code VM | sw-cor24-pcode | Execution substrate |
| Pascal compiler | sw-cor24-pascal | Compiles BASIC interpreter |
| COR24 emulator | sw-cor24-emulator | Testing and running |

## Documentation

- [Demo gallery](docs/demos.md)
- [Product Requirements](docs/prd.md)
- [Architecture](docs/architecture.md)
- [Design](docs/design.md)
- [Implementation Plan](docs/plan.md)
- [Research Notes](docs/research.txt)

## License

MIT — see [LICENSE](LICENSE) for details.

Copyright (c) 2026 Michael A Wright
