# COR24 BASIC v1 Interpreter

BASIC interpreter written in Pascal, compiled to p-code via p24p,
running on pvm.s. Dogfoods tc24r → p24p → BASIC toolchain.

## Current State
- Steps 001-007 complete: spec, toolchain, tokens, tokenizer, program
  store, expression parser, statement handlers (PRINT, LET)
- Step 008 (REPL skeleton) in progress: monolithic basic.pas compiles
  and runs but is at the ~8KB UART input limit
- Waiting on p-code unit system (sw-cor24-pcode load-time-resolution)
  to split into independently compiled modules

## Phases
1. Spec documents and saga setup (done)
2. Toolchain validation (done — p24p has procedures, arrays, chars)
3. Tokenizer and program store (done)
4. Immediate-mode statements: PRINT, LET (done as monolith)
5. **Unit system integration** (blocked on sw-cor24-pcode)
   - Build pipeline for multi-unit compilation
   - Split monolith into unit modules
   - Remove 8KB source size constraint
6. Stored program (LIST, RUN, NEW, line editing)
7. Program runner (GOTO, IF...THEN, END, STOP)
8. Subroutines and loops (GOSUB/RETURN, FOR/NEXT)
9. Console polish, INPUT, error handling
10. Hardware demos and validation

## Key Design Decisions
- Implementation language: Pascal (compiled by p24p to p-code)
- Variables: A-Z only (26 scalar integers)
- PEEK/POKE: byte-oriented MMIO (LED D2, SW2)
- SAVE/LOAD: deferred (future MMIO/I2C tape device)
- STOP without CONT in v1
- Standalone operation (no monitor integration in v1)
- Library routines for MEMCPY/MEMSET (not VM opcodes)
- **Multi-unit build**: each module compiles to a .p24 unit,
  combined via p24-load into a single .p24m image

## Toolchain Dependencies
- sw-cor24-pcode: p-code unit system (load-time-resolution.md)
  - .unit/.export/.import/.extern directives in .spc
  - xcall instruction for cross-unit calls
  - p24-load tool to combine units
  - v2 .p24 binary format with export/import tables
- sw-cor24-pascal: p24p compiler
  - Emit .unit/.export directives (or post-process .spc)
  - Forward declarations (#7) — nice to have
  - Nested procedures (#8) — nice to have
