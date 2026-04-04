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
- Commands: LIST, RUN, NEW, BYE
- Functions: PEEK, POKE, ABS
- Variables: A-Z (26 scalar integers)

## Positioning

BASIC complements Pascal in the COR24 ecosystem:

| | Pascal | BASIC |
|---|--------|-------|
| Execution | Compiled to p-code | Interpreted on p-code VM |
| Style | Structured, typed | Dynamic, interactive |
| Use case | Application development | Hardware bring-up, scripting, monitor |

## Status

**Blocked** — toolchain validation complete, waiting on p24p features.

The end-to-end pipeline works (`.pas → p24p → .spc → pl24r → pa24r →
.p24 → pvm.s`) — validated with `tests/toolchain/basic_minimal.pas`.
However, the BASIC interpreter requires p24p features that don't exist
yet:

| Feature    | sw-cor24-pascal issue | Status  |
|------------|----------------------|---------|
| Procedures | #1                   | Blocked |
| Arrays     | #2                   | Blocked |
| Char type  | #3                   | Blocked |
| peek/poke  | #5                   | Needed  |

## Dependencies

| Project | Repo | Role |
|---------|------|------|
| P-code VM | sw-cor24-pcode | Execution substrate |
| Pascal compiler | sw-cor24-pascal | Compiles BASIC interpreter |
| COR24 emulator | sw-cor24-emulator | Testing and running |

## Documentation

- [Product Requirements](docs/prd.md)
- [Architecture](docs/architecture.md)
- [Design](docs/design.md)
- [Implementation Plan](docs/plan.md)
- [Research Notes](docs/research.txt)

## License

MIT — see [LICENSE](LICENSE) for details.

Copyright (c) 2026 Michael A Wright
