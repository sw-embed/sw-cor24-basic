# COR24 BASIC v1 — Product Requirements Document

## 1. Problem Statement

The COR24 ecosystem has a Pascal compiler targeting the p-code VM, but
lacks an interactive language for hardware bring-up, monitor scripting,
and VM validation. Developers working with COR24 hardware or the
emulator need a dynamic, immediate-mode environment where they can
inspect memory, toggle I/O ports, and write quick test programs without
the compile-link-run cycle of Pascal.

BASIC fills this gap: interpreted, interactive, and historically
appropriate for terminal/teletype workflows.

## 2. Target Users

- Developers working with COR24 hardware (FPGA) or emulator
- Anyone doing hardware bring-up, peripheral testing, or memory inspection
- Users validating the p-code VM with a second language front-end
- Educational users exploring a 1970s-style computing environment

## 3. Product Description

COR24 BASIC v1 is a 1970s time-sharing-style, line-numbered,
integer-only BASIC interpreter for the COR24 p-code VM. Inspired by
UNIVAC 1100-series terminal BASIC with teletype and paper-tape
workflows. Emphasizes simplicity, hardware access (PEEK/POKE), and
interactive program development over compatibility with later BASIC
standards.

Dialect name: **COR24 BASIC v1**

## 4. Functional Requirements

### 4.1 Interactive REPL

- Immediate mode: commands without line numbers execute instantly
- Program mode: lines with numbers are tokenized and stored
- Prompt displays `READY` when awaiting input
- Input is line-oriented (teletype model)

### 4.2 Line-Numbered Program Storage

- Programs consist of numbered lines (1–32767)
- Entering a numbered line inserts or replaces it
- Entering a bare line number deletes that line
- Lines are tokenized on entry for compact storage
- Lines stored in a packed sorted buffer

### 4.3 Integer Arithmetic Expressions

- Signed 24-bit integer arithmetic
- Operators: `+`, `-`, `*`, `/`, `MOD`
- Comparisons: `=`, `<>`, `<`, `<=`, `>`, `>=`
- Unary: `+`, `-`
- Parentheses for grouping
- Operator precedence (standard mathematical order)
- Wraparound arithmetic at VM level

### 4.4 Statements (v1)

| Statement | Syntax | Description |
|-----------|--------|-------------|
| `LET` | `LET var = expr` | Assignment (LET optional) |
| `PRINT` | `PRINT expr [; expr ...]` | Output values and strings |
| `INPUT` | `INPUT var` | Read integer from terminal |
| `IF` | `IF expr THEN line` | Conditional branch |
| `GOTO` | `GOTO line` | Unconditional branch |
| `GOSUB` | `GOSUB line` | Call subroutine |
| `RETURN` | `RETURN` | Return from subroutine |
| `FOR` | `FOR var = expr TO expr [STEP expr]` | Loop start |
| `NEXT` | `NEXT var` | Loop end |
| `STOP` | `STOP` | Stop execution (resumable) |
| `END` | `END` | Terminate program |
| `REM` | `REM ...` | Comment |

### 4.5 Immediate Commands (v1)

| Command | Description |
|---------|-------------|
| `LIST` | Display stored program |
| `LIST n` | List from line n |
| `LIST n-m` | List lines n through m |
| `RUN` | Execute stored program |
| `NEW` | Clear stored program |
| `BYE` | Exit BASIC |

Note: SAVE/LOAD deferred. Future approach will use MMIO and I2C
emulated virtual tape reader/punch, possibly wrapped in a Yew/Rust/WASM
UI that hosts the interpreter running in the emulator in-browser.

### 4.6 Functions (v1)

| Function | Description |
|----------|-------------|
| `PEEK(addr)` | Read byte from memory address |
| `POKE addr, val` | Write byte to memory address |
| `ABS(expr)` | Absolute value |

### 4.7 Terminal I/O

- PRINT outputs to console (UART via VM sys calls)
- INPUT reads a line from console, parses integer
- INPUT with string prompt: `INPUT "GUESS";A`
- String literals in PRINT: `PRINT "HELLO"`
- Comma separator in PRINT: tab to next column
- Semicolon separator in PRINT: no space between items

### 4.8 Hardware Access (PEEK/POKE)

- Byte-oriented MMIO: PEEK reads 8 bits, POKE writes 8 bits
- Primary use: SW2 button (read) and D2 LED (write) via MMIO
- Addresses are against the COR24 MMIO address space
- No bounds checking in v1 (documented as intentionally dangerous)
- Word access (PEEKW/POKEW) deferred to v2

### 4.9 SAVE/LOAD (Deferred)

SAVE/LOAD is deferred from v1. Future implementation will use MMIO
and I2C emulated virtual tape reader/punch devices. A Yew/Rust/WASM
browser UI may wrap the interpreter+emulator and provide tape I/O
through the browser.

### 4.10 Error Reporting

Classic terse error messages:

- `SYNTAX ERROR`
- `WHAT?`
- `BAD LINE NUMBER`
- `OUT OF MEMORY`
- `DIVISION BY ZERO`
- `RETURN WITHOUT GOSUB`
- `NEXT WITHOUT FOR`
- `BAD ADDRESS`
- `STOPPED`

Richer internal debug codes underneath for emulator/debugger use.

## 5. Non-Functional Requirements

### 5.1 Execution Platform

- Runs on the COR24 p-code VM (not native COR24 code)
- Uses only existing p-code opcodes plus any language-neutral
  extensions added to the VM
- No BASIC-specific VM opcodes

### 5.2 Memory Model

- Fixed-size memory: no garbage collector, no dynamic allocation
- Fixed-size program area, variable table, stacks, buffers
- Predictable memory usage

### 5.3 Educational Clarity

- Simple, readable implementation over performance
- Debugger-friendly design (interpreter state, stacks, variables
  all inspectable)
- Clear layering between runtime and interpreter

### 5.4 Positioning

- Complements Pascal: BASIC is interactive/dynamic, Pascal is
  compiled/structured
- BASIC = monitor / scripting / hardware bring-up
- Pascal = structured program development

## 6. Out of Scope (v1)

- Floating point / real numbers
- Arrays (DIM)
- String variables (string literals in PRINT/INPUT prompts only)
- Multi-statement lines (colon separator)
- SAVE / LOAD (deferred; future MMIO/I2C tape device)
- DATA / READ / RESTORE
- ON ... GOTO / ON ... GOSUB
- User-defined functions (DEF FN)
- CONT (continue after STOP) — documented for v2
- RND function — maybe v2
- Screen editing / cursor control
- ANSI BASIC compliance
- Microsoft BASIC compatibility
- Monitor integration (standalone only in v1)

## 7. Implementation Language

The BASIC interpreter is written in **Pascal**, compiled by p24p to
p-code (.spc), assembled to .p24, and run on the p-code VM. This
dogfoods the Pascal toolchain and enables on-target development.

### Toolchain Dependency Chain

```
tc24r (C cross-compiler, Rust)
  → p24p (Pascal compiler, written in C)
    → BASIC interpreter (written in Pascal)
      → runs on pvm.s (p-code VM)
```

Each layer dogfoods the one below it. If the Pascal compiler is
missing a feature needed for BASIC, BASIC work pauses until p24p is
updated. If p24p needs a C compiler fix, Pascal work pauses until
tc24r is updated. Blockers propagate down, fixes propagate up.

### Current Pascal Compiler Status

p24p is at Phase 0: global variables, basic control flow, writeln.
Phase 1 (procedures, arrays, records) is specified but not yet
implemented. BASIC requires at minimum procedures and arrays, so
implementation is blocked until p24p Phase 1 is complete.

## 8. Dependencies

| Dependency | Repo | Required For |
|------------|------|-------------|
| p-code VM | sw-cor24-pcode | Execution substrate |
| p-code assembler | sw-cor24-pcode (pa24r) | Building BASIC if written in p-code asm |
| Pascal compiler | sw-cor24-pascal (p24p) | Building BASIC if written in Pascal |
| COR24 emulator | sw-cor24-emulator | Testing and running |

## 9. Success Criteria

- Interactive REPL works: can type expressions and see results
- Can enter, list, edit, and run stored programs
- Demo programs execute correctly:
  - Hello World
  - Count loop (FOR/NEXT)
  - LED blink (POKE + GOSUB delay)
  - UART poll (PEEK + IF/GOTO)
- SAVE/LOAD round-trips a program correctly
- Error messages display for common mistakes
- All interpreter state visible to debugger
