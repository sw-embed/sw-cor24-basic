# COR24 BASIC v1 Interpreter

BASIC interpreter written in Pascal, compiled to p-code via p24p,
running on pvm.s. Dogfoods tc24r → p24p → BASIC toolchain.

## Blocker
p24p Phase 1 (procedures, arrays, records) must be complete before
BASIC implementation can begin. Phase 1 is specified but not yet built.

## Phases
1. Spec documents and saga setup (done)
2. Toolchain validation (blocked on p24p Phase 1)
3. Tokenizer and program store
4. Immediate-mode evaluator (PRINT, LET, PEEK, POKE, INPUT)
5. Stored program (LIST, RUN, NEW, line editing)
6. Program runner (GOTO, IF...THEN, END, STOP)
7. Subroutines and loops (GOSUB/RETURN, FOR/NEXT)
8. Console polish and error handling
9. Hardware demos and validation

## Key Design Decisions
- Implementation language: Pascal (compiled by p24p to p-code)
- Variables: A-Z only (26 scalar integers)
- PEEK/POKE: byte-oriented MMIO (LED D2, SW2)
- SAVE/LOAD: deferred (future MMIO/I2C tape device)
- STOP without CONT in v1
- Standalone operation (no monitor integration in v1)
- Library routines for MEMCPY/MEMSET (not VM opcodes)
