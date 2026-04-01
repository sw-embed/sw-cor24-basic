# COR24 BASIC v1 — Architecture

## 1. System Layers

```
┌─────────────────────────────────────────────┐
│  Layer 3: BASIC Interpreter                 │
│  Tokenizer, parser, statement dispatch,     │
│  execution of tokenized lines               │
├─────────────────────────────────────────────┤
│  Layer 2: BASIC Runtime                     │
│  Terminal I/O, line storage, expression     │
│  helpers, GOSUB/FOR stacks, PEEK/POKE,     │
│  tape abstraction, variable table           │
├─────────────────────────────────────────────┤
│  Layer 1: P-Code VM                         │
│  Stack machine, eval+call stacks, globals,  │
│  heap, traps, sys calls (PUTC/GETC/LED),   │
│  byte/word memory access                    │
├─────────────────────────────────────────────┤
│  Layer 0: COR24 Hardware / Emulator         │
│  24-bit RISC ISA, SRAM, UART, LED/switch,  │
│  MMIO at 0xFF0000+                          │
└─────────────────────────────────────────────┘
```

BASIC is an **interpreter running on the VM**, not compiled to p-code.
The VM executes the BASIC interpreter's code (written in Pascal,
compiled to p-code by p24p); the interpreter in turn parses and
executes BASIC programs stored in its own memory area.

### Implementation Language

The BASIC interpreter is a Pascal program. The toolchain:
```
basic.pas → p24p (Pascal→p-code) → basic.spc → pa24r → basic.p24 → pvm.s
```

This dogfoods the Pascal compiler. If p24p lacks a needed feature
(e.g., arrays, procedures), BASIC work pauses until p24p is updated.

## 2. How BASIC Maps onto P-Code VM Execution

The BASIC interpreter is a p-code program that:

1. Uses `sys GETC` / `sys PUTC` for terminal I/O
2. Uses `loadb` / `storeb` for byte-level token/string manipulation
3. Uses `load` / `store` for word-level data (variables, line pointers)
4. Uses `call` / `ret` for internal interpreter subroutines
5. Uses globals for interpreter state (or a state struct in the heap)
6. Uses the VM eval stack for expression evaluation
7. Uses `trap` for fatal errors

The interpreter's own GOSUB stack and FOR stack are **not** the VM
call/eval stacks — they are BASIC-level data structures stored in the
interpreter's memory area.

## 3. Memory Layout

Within the VM's address space, the BASIC interpreter allocates its
working memory from the globals/heap area:

```
┌──────────────────────────────────┐  High addresses
│  Input Buffer (256 bytes)        │  Raw terminal input line
├──────────────────────────────────┤
│  Token Buffer (256 bytes)        │  Tokenized form of current line
├──────────────────────────────────┤
│  String Pool (512 bytes)         │  String literals from tokenized
│                                  │  program (referenced by tokens)
├──────────────────────────────────┤
│  GOSUB Stack (64 entries)        │  Return line pointers
│  (64 × 3 = 192 bytes)           │
├──────────────────────────────────┤
│  FOR Stack (16 entries)          │  var, limit, step, restart ptr
│  (16 × 12 = 192 bytes)          │
├──────────────────────────────────┤
│  Variable Table                  │  26 words (A-Z) or 286 (A-Z,
│  (78-858 bytes)                  │  A0-Z9)
├──────────────────────────────────┤
│  Program Area (~8-16 KB)         │  Packed sorted tokenized lines
│                                  │  [line#][len][tokens...] ...
├──────────────────────────────────┤
│  Interpreter State               │  Pointers, flags, counters
│  (~30 words)                     │
└──────────────────────────────────┘  Low addresses (globals base)
```

### 3.1 Program Area

Stored as a packed sorted buffer of tokenized lines:

```
┌───────┬─────┬──────────────────────┐
│ line# │ len │ tokenized content ... │
│ (word)│(byte)│                      │
└───────┴─────┴──────────────────────┘
```

- Lines sorted by line number
- Insertion/deletion requires shifting subsequent lines
- Linear search for line lookup (index table optional later)
- `program_start` and `program_end` pointers track bounds

### 3.2 Variable Table

- 26 integer words for A-Z (minimal)
- Optionally 286 words for A-Z plus A0-Z9 (extended)
- Direct index: variable letter maps to offset
- All variables are signed 24-bit integers
- Initialized to 0 on `NEW` or `RUN`

### 3.3 GOSUB Stack

- Fixed-size stack of return-line pointers
- Push on `GOSUB`, pop on `RETURN`
- Stack pointer tracks depth
- Overflow: `OUT OF MEMORY` error

### 3.4 FOR Stack

Each entry stores:
- Variable index (which loop variable)
- Limit value
- Step value
- Restart pointer (line pointer to loop body)

Push on `FOR`, pop on `NEXT` when limit reached.
Nested FORs stack naturally. `NEXT` matches by variable name.

## 4. Token Format

Tokens are single bytes, with multi-byte payloads for literals
and strings:

| Token Type | Encoding | Description |
|------------|----------|-------------|
| Keyword | `0x80-0x9F` | PRINT, IF, GOTO, etc. |
| Operator | `0xA0-0xAF` | +, -, *, /, =, <>, etc. |
| Delimiter | `0xB0-0xB7` | (, ), comma, semicolon |
| Variable | `0xC0-0xD9` | A=0xC0, B=0xC1, ... Z=0xD9 |
| Integer literal | `0xE0` + 3 bytes | 24-bit value follows |
| String literal | `0xE1` + len + bytes | Length-prefixed string |
| End of line | `0x00` | Terminator |

Keywords, operators, and delimiters are single-byte tokens.
This makes scanning fast and storage compact.

## 5. Execution Flow

### 5.1 REPL Loop

```
loop:
    print "READY"
    read_line(input_buffer)
    if line starts with digit:
        tokenize(input_buffer, token_buffer)
        store_line(token_buffer)       ; insert/replace/delete
    else:
        tokenize(input_buffer, token_buffer)
        execute_immediate(token_buffer) ; run now
    goto loop
```

### 5.2 Immediate vs Stored Execution

- **Immediate**: tokenize and execute the single line directly
- **Stored (RUN)**: start at lowest line number, advance
  `current_line_ptr` through program area, executing each line

### 5.3 RUN Execution

```
RUN:
    clear variables
    clear GOSUB stack
    clear FOR stack
    current_line_ptr = program_start
    while current_line_ptr < program_end:
        next_line_ptr = advance(current_line_ptr)
        execute_line(current_line_ptr)
        if goto/gosub changed current_line_ptr:
            continue
        current_line_ptr = next_line_ptr
```

### 5.4 Statement Dispatch

Each line's first token determines the handler:

```
switch first_token:
    TOK_LET    -> stmt_let()
    TOK_PRINT  -> stmt_print()
    TOK_INPUT  -> stmt_input()
    TOK_IF     -> stmt_if()
    TOK_GOTO   -> stmt_goto()
    TOK_GOSUB  -> stmt_gosub()
    TOK_RETURN -> stmt_return()
    TOK_FOR    -> stmt_for()
    TOK_NEXT   -> stmt_next()
    TOK_STOP   -> stmt_stop()
    TOK_END    -> stmt_end()
    TOK_REM    -> (skip)
    TOK_VAR    -> stmt_implicit_let()  ; A = expr
    default    -> SYNTAX ERROR
```

## 6. Interaction with VM Facilities

### 6.1 I/O via sys Calls

| BASIC Operation | VM Mechanism |
|-----------------|-------------|
| PRINT character | `sys 1` (PUTC) |
| INPUT character | `sys 2` (GETC) |
| LED control | `sys 3` (LED) |

### 6.2 Memory Access

| BASIC Operation | VM Mechanism |
|-----------------|-------------|
| PEEK(addr) | `push addr` + `loadb` |
| POKE addr,val | `push val` + `push addr` + `storeb` |
| Variable read | `loadg` or indexed `load` |
| Token scanning | `loadb` through token buffer |

### 6.3 Traps

| Error Condition | VM Trap |
|-----------------|---------|
| Division by zero | VM trap 1 (DIV_ZERO) — caught by interpreter |
| Out of memory | Interpreter checks bounds, reports error |
| Bad address | Interpreter validates, or VM trap 5 |

### 6.4 Potential VM Extensions

These language-neutral primitives would benefit BASIC and future
interpreters. Status based on current VM (sw-cor24-pcode):

| Primitive | Status | Notes |
|-----------|--------|-------|
| `loadb` / `storeb` | **Present** | Byte access exists |
| `load` / `store` | **Present** | Word access exists |
| `trap` | **Present** | Trap with code exists |
| `sys` (PUTC/GETC) | **Present** | Console I/O exists |
| `sys` (ALLOC/FREE) | **Present** | Heap allocation exists |
| MEMCPY | **Missing** | Block copy — useful for line insertion |
| MEMSET | **Missing** | Block fill — useful for NEW/clear |
| JMP_IND | **Missing** | Indirect jump — useful for dispatch |
| CALL_IND | **Missing** | Indirect call — useful for dispatch |
| MEMCMP | **Missing** | Block compare — useful for keyword match |
| FIND_BYTE | **Missing** | Byte scan — useful for token scanning |

Missing primitives can be implemented in p-code library routines.
Whether to promote them to VM opcodes depends on profiling across
multiple language implementations.

## 7. Module Breakdown

```
basic_repl      REPL loop, prompt, line classification
basic_lex       Tokenizer: source text -> token stream
basic_tokens    Token definitions, keyword table, detokenizer
basic_store     Program storage: insert, delete, find, list
basic_expr      Expression parser (Pratt/precedence climbing)
basic_stmt      Statement handlers (LET, PRINT, IF, GOTO, etc.)
basic_exec      Execution engine: RUN, line dispatch, flow control
basic_runtime   Runtime state, variable table, stacks, init/reset
basic_errors    Error codes, error messages, error reporting
basic_io        Terminal I/O and tape abstraction layer
```

### Module Dependencies

```
basic_repl
  ├── basic_lex
  ├── basic_store
  ├── basic_exec
  │     ├── basic_stmt
  │     │     ├── basic_expr
  │     │     └── basic_runtime
  │     └── basic_runtime
  ├── basic_io
  └── basic_errors

basic_tokens (shared definitions, used by lex, store, expr, stmt)
```

## 8. Relationship to Ecosystem

```
sw-cor24-basic (this project)
    │
    │ runs on
    ▼
sw-cor24-pcode/vm (p-code VM)
    │
    │ executes on
    ▼
sw-cor24-emulator (COR24 emulator / hardware)

sw-cor24-pascal (Pascal compiler) ──► also targets p-code VM
sw-cor24-pcode/assembler (pa24r)  ──► assembles .spc to .p24
sw-cor24-pcode/linker (pl24r)     ──► links .spc modules
```
