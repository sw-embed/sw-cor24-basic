# COR24 BASIC v1 — Design Document

## 1. Tokenizer Specification

### 1.1 Tokenization Process

Input: a line of text from the terminal (with or without line number).
Output: a byte sequence of tokens in the token buffer.

Steps:
1. Skip leading whitespace
2. If first characters are digits, parse line number (stored separately)
3. For each remaining token:
   - Skip whitespace
   - Match keywords (longest match)
   - Match operators and delimiters
   - Match variable names (letter, optionally followed by digit)
   - Match integer literals (decimal digits)
   - Match string literals (quoted with `"`)
   - Emit token byte(s) to token buffer
4. Emit end-of-line token (0x00)

### 1.2 Keyword Tokens (0x80-0x9F)

| Byte | Keyword |
|------|---------|
| 0x80 | LET |
| 0x81 | PRINT |
| 0x82 | INPUT |
| 0x83 | IF |
| 0x84 | THEN |
| 0x85 | GOTO |
| 0x86 | GOSUB |
| 0x87 | RETURN |
| 0x88 | FOR |
| 0x89 | TO |
| 0x8A | STEP |
| 0x8B | NEXT |
| 0x8C | STOP |
| 0x8D | END |
| 0x8E | REM |
| 0x8F | LIST |
| 0x90 | RUN |
| 0x91 | NEW |
| 0x92 | SAVE |
| 0x93 | LOAD |
| 0x94 | BYE |
| 0x95 | PEEK |
| 0x96 | POKE |
| 0x97 | ABS |

Keywords are case-insensitive. The tokenizer uppercases input before
matching.

After `REM`, the rest of the line is stored verbatim as a string token
(for faithful listing).

### 1.3 Operator Tokens (0xA0-0xAF)

| Byte | Operator |
|------|----------|
| 0xA0 | `+` |
| 0xA1 | `-` |
| 0xA2 | `*` |
| 0xA3 | `/` |
| 0xA4 | `=` |
| 0xA5 | `<>` |
| 0xA6 | `<` |
| 0xA7 | `<=` |
| 0xA8 | `>` |
| 0xA9 | `>=` |

### 1.4 Delimiter Tokens (0xB0-0xB7)

| Byte | Delimiter |
|------|-----------|
| 0xB0 | `(` |
| 0xB1 | `)` |
| 0xB2 | `,` |
| 0xB3 | `;` |

### 1.5 Variable Tokens (0xC0-0xD9)

Single-letter variables A-Z map to 0xC0-0xD9 (26 tokens).

If extended variables (A0-Z9) are supported, they use a two-byte
encoding: 0xDA + index byte (0-259), where index = (letter-'A')*10 +
digit. This reserves 0xC0-0xD9 for the common single-letter case.

### 1.6 Literal Tokens

**Integer literal** (0xE0):
```
0xE0  byte2  byte1  byte0    (24-bit value, big-endian)
```

**String literal** (0xE1):
```
0xE1  length  char0  char1 ... charN
```
Length is a single byte (max 255 characters).

### 1.7 End of Line (0x00)

Terminates the token stream for a line.

## 2. Expression Parser

### 2.1 Approach: Precedence Climbing (Pratt-style)

The expression parser uses precedence climbing, which naturally handles:
- Binary operators with varying precedence
- Unary prefix operators
- Parenthesized sub-expressions
- Function calls (PEEK, ABS)

### 2.2 Operator Precedence Table

| Precedence | Operators | Associativity |
|-----------|-----------|---------------|
| 1 (lowest) | `=`, `<>`, `<`, `<=`, `>`, `>=` | Left |
| 2 | `+`, `-` | Left |
| 3 | `*`, `/` | Left |
| 4 (highest) | unary `-`, unary `+` | Right (prefix) |

### 2.3 Expression Grammar

```
expr        = comparison
comparison  = addition ( ( "=" | "<>" | "<" | "<=" | ">" | ">=" ) addition )*
addition    = term ( ( "+" | "-" ) term )*
term        = unary ( ( "*" | "/" ) unary )*
unary       = ( "-" | "+" ) unary | primary
primary     = INTEGER
            | VARIABLE
            | "(" expr ")"
            | "PEEK" "(" expr ")"
            | "ABS" "(" expr ")"
```

### 2.4 Expression Evaluation

The parser evaluates directly from the token stream, returning an
integer result. It maintains a token pointer into the current line's
token buffer.

For the p-code implementation, expression evaluation uses the VM's
eval stack naturally: each operand is pushed, each operator pops
operands and pushes the result.

## 3. Statement Dispatch

### 3.1 Dispatch Model

The executor reads the first token of a line and dispatches to the
corresponding handler. Each handler consumes tokens from the line
and may call the expression parser.

### 3.2 Statement Handlers

**LET var = expr** (or implicit: `var = expr`)
1. Read variable token
2. Expect `=` operator
3. Evaluate expression
4. Store result in variable table

**PRINT expr [sep expr ...]**
1. Loop:
   - If string literal: print string
   - Else: evaluate expression, print as decimal integer
   - If `,`: advance to next tab column (every 14 chars)
   - If `;`: no separator
   - If end of line: print newline
2. Trailing `;` suppresses newline

**INPUT var** or **INPUT "prompt"; var**
1. If string literal present: print it; else print `? `
2. Read line from terminal
3. Parse integer from input
4. Store in variable

**IF expr THEN line**
1. Evaluate expression
2. If non-zero: execute `GOTO line`
3. If zero: advance to next line

**GOTO line**
1. Parse line number from token stream
2. Search program area for that line
3. Set `current_line_ptr` to found line
4. Error if not found: `BAD LINE NUMBER`

**GOSUB line**
1. Push current `next_line_ptr` onto GOSUB stack
2. Execute as GOTO

**RETURN**
1. Pop from GOSUB stack
2. Set `current_line_ptr` to popped value
3. Error if stack empty: `RETURN WITHOUT GOSUB`

**FOR var = expr TO expr [STEP expr]**
1. Parse variable, start, limit, optional step (default 1)
2. Store start value in variable
3. Push FOR entry: variable, limit, step, restart pointer
4. If step > 0 and start > limit: skip to matching NEXT
5. If step < 0 and start < limit: skip to matching NEXT

**NEXT var**
1. Find matching FOR entry on stack (by variable)
2. Add step to variable
3. If step > 0 and variable > limit: pop FOR entry, continue
4. If step < 0 and variable < limit: pop FOR entry, continue
5. Else: set `current_line_ptr` to restart pointer (loop back)
6. Error if no match: `NEXT WITHOUT FOR`

**STOP**
1. Set `stopped_flag`
2. Print `STOPPED AT LINE nnn`
3. Return to REPL
(CONT to resume after STOP is documented for v2, not implemented in v1)

**END**
1. Clear running flag
2. Return to REPL

**REM**
1. Skip rest of line (already stored as string token)

## 4. Variable Model

### 4.1 Minimal (26 variables)

Variables A through Z. Each is a signed 24-bit integer word.
Variable token byte directly indexes the table: `vars[token - 0xC0]`.

### 4.2 Extended (286 variables)

A-Z plus A0-A9, B0-B9, ... Z0-Z9.
Two-letter+digit names common in 1970s BASIC.
Index: single-letter = 0-25, extended = 26 + (letter*10 + digit).

**Decision: A-Z only (26 variables) for v1.** Extend to A0-Z9 later if needed.

## 5. PEEK/POKE Design

### 5.1 Semantics

- `PEEK(addr)`: read one byte from VM address space, return as integer (0-255)
- `POKE addr, val`: write low 8 bits of val to VM address space

### 5.2 Address Space

Addresses are against the COR24 MMIO byte address space.
Primary v1 use cases:
- LED D2: write via `POKE` to LED port (0xFF0000)
- Button SW2: read via `PEEK` of switch port (0xFF0000)
- UART data/status: 0xFF0100 / 0xFF0101

Full COR24 memory map:
- SRAM: 0x000000 - 0x0FFFFF
- MMIO: 0xFF0000+ (LED/switch at 0xFF0000, UART at 0xFF0100)

### 5.3 Safety

v1: no protection. PEEK/POKE can read/write anything, including
the VM's own state. This is intentional for hardware bring-up use.
Document the danger.

v2 consideration: optional SAFE/UNSAFE mode flag.

### 5.4 Implementation

PEEK uses the VM's `loadb` instruction.
POKE uses the VM's `storeb` instruction.
Both operate on the full COR24 address space.

## 6. I/O Model

### 6.1 Console Device

The primary I/O device. Maps to UART:
- Output: `sys PUTC` (one byte at a time)
- Input: `sys GETC` (one byte, blocking)
- Line-oriented: interpreter assembles chars into lines
- Echo: characters echoed as typed
- CR/LF normalization: accept CR, LF, or CR+LF as line end

### 6.2 SAVE/LOAD (Deferred)

SAVE/LOAD is deferred from v1. The future approach will use MMIO and
I2C emulated virtual tape reader/punch devices. A Yew/Rust/WASM
browser UI may wrap the interpreter+emulator and provide tape I/O
through the browser interface.

When implemented, the save format will be plain text BASIC source
(one line per stored line, detokenized from internal storage).

## 7. Error Handling

### 7.1 User-Facing Messages

Short, teletype-era messages printed to console.
Format: `ERROR_TEXT` or `ERROR_TEXT IN LINE nnn`

### 7.2 Internal Debug Codes

Each error has a numeric code for debugger use:

| Code | Message | Condition |
|------|---------|-----------|
| 1 | SYNTAX ERROR | Unexpected token |
| 2 | WHAT? | Unrecognized command |
| 3 | BAD LINE NUMBER | Line not found |
| 4 | OUT OF MEMORY | Program or stack full |
| 5 | DIVISION BY ZERO | Divide/mod by zero |
| 6 | RETURN WITHOUT GOSUB | GOSUB stack empty |
| 7 | NEXT WITHOUT FOR | No matching FOR |
| 8 | BAD ADDRESS | Invalid PEEK/POKE address |
| 9 | STOPPED | STOP statement executed |
| 10 | TYPE MISMATCH | Wrong value type |
| 11 | OVERFLOW | Arithmetic overflow (if checked) |
| 12 | STRING TOO LONG | String exceeds buffer |
| 13 | OUT OF DATA | DATA exhausted (future) |
| 14 | END OF TAPE | Reader/punch exhausted |
| 15 | DEVICE ERROR | I/O failure |

### 7.3 Error Recovery

On error during RUN:
1. Print error message with line number
2. Stop execution
3. Return to REPL
4. Program and variables preserved (user can inspect/fix)

## 8. Runtime State

### 8.1 InterpreterState Structure

Conceptually a struct; implemented as parallel arrays or a memory
block depending on implementation language:

```
InterpreterState:
    ; Program storage
    program_start       ; pointer to start of program area
    program_end         ; pointer to end of used program area
    program_limit       ; pointer to end of program area (max)

    ; Execution state
    current_line_ptr    ; pointer to line being executed
    next_line_ptr       ; pointer to next line after current
    token_ptr           ; current position in token buffer

    ; Variable table
    vars[26]            ; A-Z integer values

    ; GOSUB stack
    gosub_stack[64]     ; return line pointers
    gosub_sp            ; stack pointer (0 = empty)

    ; FOR stack
    for_var[16]         ; variable index
    for_limit[16]       ; limit value
    for_step[16]        ; step value
    for_restart[16]     ; restart line pointer
    for_sp              ; stack pointer (0 = empty)

    ; Buffers
    input_buffer[256]   ; raw input line
    token_buffer[256]   ; tokenized current line

    ; Flags
    running             ; 1 = executing program, 0 = immediate
    stopped             ; 1 = STOP executed
    error_code          ; last error (0 = none)
```

### 8.2 Initialization

On startup:
- Clear all state
- Set program area pointers
- Print banner: `COR24 BASIC V1`

On `NEW`:
- Clear program area
- Clear variables
- Clear stacks

On `RUN`:
- Clear variables
- Clear GOSUB and FOR stacks
- Set `current_line_ptr` to `program_start`
- Set `running = 1`

## 9. GOSUB Stack Design

Fixed-size stack of word-sized entries (line pointers).

```
gosub_push(line_ptr):
    if gosub_sp >= GOSUB_MAX: error OUT OF MEMORY
    gosub_stack[gosub_sp] = line_ptr
    gosub_sp += 1

gosub_pop() -> line_ptr:
    if gosub_sp == 0: error RETURN WITHOUT GOSUB
    gosub_sp -= 1
    return gosub_stack[gosub_sp]
```

Maximum depth: 64 (configurable at build time).

## 10. FOR Stack Design

Each entry is 4 words:

```
for_push(var_idx, limit, step, restart_ptr):
    ; First check if this variable already has a FOR entry
    ; If so, overwrite it (re-entering a FOR loop)
    for i = for_sp-1 downto 0:
        if for_var[i] == var_idx:
            for_limit[i] = limit
            for_step[i] = step
            for_restart[i] = restart_ptr
            return
    ; New entry
    if for_sp >= FOR_MAX: error OUT OF MEMORY
    for_var[for_sp] = var_idx
    for_limit[for_sp] = limit
    for_step[for_sp] = step
    for_restart[for_sp] = restart_ptr
    for_sp += 1

for_find(var_idx) -> index or -1:
    for i = for_sp-1 downto 0:
        if for_var[i] == var_idx: return i
    return -1
```

Maximum depth: 16 (configurable at build time).

## 11. VM Extension Candidates

Based on reading sw-cor24-pcode, these language-neutral primitives
are not present but would benefit interpreter implementations:

### 11.1 Now Available in VM

These were added to sw-cor24-pcode as language-neutral opcodes:

| Opcode | Primitive | Stack Effect | Used For |
|--------|-----------|-------------|----------|
| 0x70 | **MEMCPY** | ( src dst len -- ) | Line insertion/deletion, string copy |
| 0x71 | **MEMSET** | ( dst val len -- ) | Clear program area, zero-fill buffers |
| 0x72 | **MEMCMP** | ( a b len -- result ) | Keyword matching in tokenizer |
| 0x73 | **JMP_IND** | ( addr -- ) | Dispatch table for statement handlers |

MEMCPY uses memmove semantics (overlapping-safe). MEMCMP returns
0 (equal), -1 (a<b), or 1 (a>b).

### 11.2 Deferred

| Primitive | Status |
|-----------|--------|
| **CALL_IND** | Not needed unless virtual dispatch required |
| **FIND_BYTE** | Not needed unless token scanning is a bottleneck |

### 11.3 Keep Out of VM

Everything BASIC-specific: line lookup, tokenization, FOR/GOSUB
management, number parsing, PRINT formatting. These belong in the
interpreter/runtime layer.
