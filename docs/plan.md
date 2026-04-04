# COR24 BASIC v1 — Implementation Plan

## Toolchain Dogfooding Strategy

The BASIC interpreter is written in Pascal and dogfoods the full
toolchain. Each layer validates the one below it:

```
tc24r (C cross-compiler, Rust, host-side)
  → p24p (Pascal compiler, written in C, runs on COR24)
    → BASIC interpreter (written in Pascal, runs on p-code VM)
```

**Rule**: If the Pascal compiler is missing a feature needed for BASIC,
BASIC work pauses until p24p is updated. If p24p needs a C compiler
fix, Pascal work pauses until tc24r is updated. Blockers propagate
down, fixes propagate up.

### Current Blocker

p24p is at Phase 0 (globals, basic control flow, writeln). Phase 1
(procedures, arrays, records) is specified but not yet implemented.
BASIC requires procedures and arrays at minimum. Implementation is
blocked until p24p Phase 1 is complete.

### Pascal Features Required by BASIC

| Feature | p24p Phase | Used For |
|---------|-----------|----------|
| Global variables | Phase 0 ✓ | Interpreter state, flags |
| Constants | Phase 0 ✓ | Token values, buffer sizes |
| if/while/for | Phase 0 ✓ | Interpreter logic |
| writeln | Phase 0 ✓ | Debug output (not BASIC PRINT) |
| **Procedures** | **Phase 1** | Module structure, statement handlers |
| **Functions** | **Phase 1** | Expression parser, PEEK/ABS |
| **Arrays** | **Phase 1** | Variable table, program store, stacks |
| **Var parameters** | **Phase 1** | Passing buffers to procedures |
| **Char type** | **Phase 1** | Token/byte manipulation |
| Records | Phase 1 | FOR stack entries (or use parallel arrays) |

## Implementation Phases

### Phase 1: Language & Runtime Spec Documents (this phase)

- Create PRD, architecture, design, and plan documents
- Resolve open design questions with user
- Verify p-code VM capabilities
- Create agentrail saga with step-by-step plan

**Deliverables**: docs/prd.md, docs/architecture.md, docs/design.md,
docs/plan.md, README.md

### Phase 2: Toolchain Validation

Before writing BASIC, verify the build pipeline works end-to-end.

**2a: Verify p24p Phase 1 readiness**
- Check that p24p supports procedures, arrays, var params, char
- If not ready: file feature requests, pause BASIC work
- Track p24p Phase 1 progress

**2b: Build pipeline smoke test**
- Write a small Pascal test program that exercises the features
  BASIC will need: procedures with params, array indexing, char/byte
  manipulation, sys PUTC/GETC
- Compile with p24p → link with pl24r → assemble with pa24r → run on pvm.s
- Verify correct output on emulator

**2c: Pascal runtime inventory**
- Catalog what sw-cor24-pascal/runtime/ provides
- Identify what BASIC needs that doesn't exist yet
- Plan BASIC-specific utility routines

### Phase 3: Tokenizer and Program Store

Build the foundation: tokenize BASIC source into compact byte streams
and manage stored programs.

**3a: Token definitions and keyword table**
- Define token byte values (keywords, operators, delimiters, etc.)
- Build keyword lookup table for tokenizer
- Build detokenizer (token → text) for LIST

**3b: Tokenizer (basic_lex)**
- Line number detection and parsing
- Keyword recognition (case-insensitive)
- Integer literal parsing and encoding
- String literal parsing and encoding
- Variable name recognition (A-Z only)
- Operator and delimiter recognition
- REM: store rest of line verbatim

**3c: Program store (basic_store)**
- Packed sorted buffer management
- Insert line (shift subsequent lines, place new)
- Replace line (delete + insert)
- Delete line (shift subsequent lines down)
- Find line by number (linear search)
- Iterate lines (for RUN and LIST)

**Tests**:
- Tokenize `PRINT 1+2` → verify token bytes
- Tokenize `10 GOTO 200` → verify line number extraction + tokens
- Tokenize `POKE 65280,1` → verify keyword + literal + delimiter
- Insert lines out of order → verify sorted listing
- Replace existing line → verify replacement
- Delete line → verify removal
- Detokenize back to text → verify round-trip fidelity

### Phase 4: Immediate-Mode Evaluator

Get to the first interactive experience: type PRINT and see output.

**4a: Expression parser (basic_expr)**
- Precedence-climbing parser
- Integer literals, variables, parentheses
- Arithmetic: +, -, *, /
- Comparisons: =, <>, <, <=, >, >=
- Unary minus/plus
- Function calls: PEEK(), ABS()

**4b: Core statements for immediate mode (basic_stmt partial)**
- PRINT (expressions, string literals, comma/semicolon formatting)
- LET / implicit assignment
- POKE
- INPUT (with optional string prompt)

**4c: REPL skeleton (basic_repl)**
- Read line from terminal
- Classify: line number → store, no number → execute
- Execute immediate commands
- Error reporting

**Tests**:
- `PRINT 2+3*4` → `14`
- `PRINT "HELLO"` → `HELLO`
- `LET A=5` then `PRINT A` → `5`
- `POKE 65280,1` → LED on
- `PRINT PEEK(65281)` → UART status byte
- `PRINT ABS(-42)` → `42`
- `INPUT "GUESS";A` → prints prompt, reads value
- Syntax errors produce messages

### Phase 5: Stored Program (LIST, RUN, NEW, Line Editing)

Enable entering and managing stored programs.

**5a: LIST command**
- Detokenize and print all stored lines
- LIST n: start from line n
- LIST n-m: range listing

**5b: NEW command**
- Clear program area
- Reset interpreter state

**5c: Line editing**
- Entering a numbered line stores it
- Entering a bare line number deletes it
- Re-entering a line number replaces it

**5d: RUN command (basic execution)**
- Start at lowest line number
- Advance through lines sequentially
- Execute each line via statement dispatch
- Stop at END or end of program

**Tests**:
- Enter `10 PRINT "HELLO"` / `20 END` / `LIST` → shows both lines
- `RUN` → prints HELLO
- `NEW` / `LIST` → empty
- Replace line 10 → LIST shows new content
- Delete line by bare number → LIST confirms removal

### Phase 6: Program Runner (GOTO, IF...THEN, END)

Add control flow for stored programs.

**6a: GOTO**
- Parse target line number
- Search program area
- Update current_line_ptr

**6b: IF...THEN**
- Evaluate condition expression
- If non-zero: execute GOTO to line number after THEN
- If zero: advance to next line

**6c: END / STOP**
- END: stop execution, return to REPL
- STOP: stop execution, print line number, return to REPL
- CONT documented for v2, not implemented

**Tests**:
- Counter loop: `10 LET A=1` / `20 PRINT A` / `30 LET A=A+1` /
  `40 IF A<=10 THEN 20` / `50 END` → prints 1 through 10
- `GOTO` to non-existent line → `BAD LINE NUMBER`

### Phase 7: Subroutines and Loops (GOSUB/RETURN, FOR/NEXT)

Complete the control flow model.

**7a: GOSUB / RETURN**
- GOSUB: push return address, jump to target
- RETURN: pop and jump back
- Stack depth tracking and overflow detection

**7b: FOR / NEXT**
- FOR: set variable, push loop entry
- NEXT: increment, check limit, loop or pop
- STEP support (positive and negative)
- Nested loop support

**Tests**:
- Nested GOSUB (2-3 levels deep)
- `RETURN WITHOUT GOSUB` error
- Simple FOR loop: `FOR I=1 TO 10` / `PRINT I` / `NEXT I`
- Nested FOR loops
- `NEXT WITHOUT FOR` error
- FOR with STEP -1 (countdown)
- LED blink demo (GOSUB delay subroutine)

### Phase 8: Console Polish and Error Handling

Improve the user experience.

**8a: PRINT formatting**
- Comma: tab to next 14-character column
- Semicolon: no separator
- Trailing semicolon suppresses newline
- Mixed string/expression output

**8b: INPUT enhancements**
- `? ` default prompt
- `INPUT "prompt";A` with custom prompt
- Error on non-numeric input (re-prompt)

**8c: Error message polish**
- Consistent format: `ERROR IN LINE nnn`
- All error codes produce messages
- Debug codes accessible via debugger

**8d: Banner and startup**
- Print `COR24 BASIC V1` on startup
- Print memory available
- `READY` prompt

**Tests**:
- `PRINT 1,2,3` → tabbed columns
- `PRINT 1;2;3` → `123`
- `PRINT "A=";A` → `A=5`
- INPUT with valid and invalid values

### Phase 9: Hardware Demos and Validation

Prove the system works end-to-end with real hardware scenarios.

**Demo programs**:

1. **Hello World**
   ```
   10 PRINT "HELLO, WORLD"
   20 END
   ```

2. **Count Loop**
   ```
   10 FOR I=1 TO 10
   20 PRINT I
   30 NEXT I
   40 END
   ```

3. **LED Blink**
   ```
   10 POKE 65280,1
   20 GOSUB 100
   30 POKE 65280,0
   40 GOSUB 100
   50 GOTO 10
   100 FOR D=1 TO 500
   110 NEXT D
   120 RETURN
   ```

4. **UART Poll**
   ```
   10 S=PEEK(65281)
   20 IF S=0 THEN 10
   30 C=PEEK(65280)
   40 PRINT C
   50 GOTO 10
   ```

5. **Memory Dump**
   ```
   10 INPUT "ADDR";A
   20 FOR I=0 TO 15
   30 PRINT PEEK(A+I);" ";
   40 NEXT I
   50 PRINT
   60 END
   ```

**Validation**:
- All demos run correctly on emulator
- PEEK/POKE access real MMIO addresses (LED D2, SW2)
- Interpreter state visible in debugger
- Performance acceptable for interactive use

## Testing Strategy

### Unit-Level Testing

Each module has focused tests:
- Tokenizer: known inputs → expected token byte sequences
- Program store: insert/delete/find operations
- Expression parser: arithmetic expressions → correct results
- Statement handlers: individual statement execution

### Integration Testing

Complete programs that exercise multiple features:
- The 5 demo programs above
- Error condition programs (trigger each error type)
- Edge cases: empty program, single line, max line number

### Regression Testing

A test harness script (`demo.sh` or similar) that:
- Pipes input programs via UART to the interpreter
- Captures output
- Compares against expected output
- Reports pass/fail

## VM Dependency Analysis

### Already Present (no changes needed)

| VM Feature | Used For |
|-----------|----------|
| `loadb` / `storeb` | PEEK/POKE, token scanning, string handling |
| `load` / `store` | Variable access, line pointer manipulation |
| `sys PUTC` | PRINT output |
| `sys GETC` | INPUT, REPL line reading |
| `sys LED` | Direct LED access (alternative to POKE) |
| `sys ALLOC` | Initial memory allocation for interpreter areas |
| `call` / `ret` | Interpreter internal subroutine calls |
| `trap` | Fatal error handling |
| All arithmetic | Expression evaluation |
| All comparisons | IF conditions, loop tests |

### Recently Added to VM (available now)

| Opcode | Capability | Notes |
|--------|-----------|-------|
| 0x70 | MEMCPY | Block copy with memmove semantics |
| 0x71 | MEMSET | Block fill |
| 0x72 | MEMCMP | Lexicographic byte comparison |
| 0x73 | JMP_IND | Indirect jump for dispatch tables |

### Still Needed as Library Routines

| Capability | Priority | Notes |
|-----------|----------|-------|
| Integer-to-string | High | PRINT needs decimal output |
| String-to-integer | High | INPUT and line number parsing |
| Line input routine | High | Read until CR/LF with echo |

### Verify Before Starting Phase 3

1. Can we compile and run a Pascal program with procedures and arrays?
2. Can we call sys PUTC/GETC from Pascal?
3. Can loadb/storeb access MMIO addresses from Pascal?
4. Does the linker (pl24r) support the Pascal runtime + BASIC modules?
5. What is the maximum program size the VM can handle?

## Future Considerations (Not v1)

### SAVE/LOAD
Deferred. Future approach: MMIO + I2C emulated virtual tape
reader/punch. Possible Yew/Rust/WASM browser UI wrapping the
interpreter+emulator.

### CONT (Continue After STOP)
Documented for v2. Requires preserving execution state including
current line pointer and all stacks.

### Monitor Integration
v1 is standalone (own .p24 binary). Future: sw-cor24-monitor launches
BASIC; UART ownership transfers to BASIC while running.

### sws Integration
Future: sw-cor24-script (sws) will "run" BASIC with VM bundled.
Sequential/serialized operation — BASIC runs, exits, returns to sws.
No concurrent resource sharing needed.

### VM Extension Requests
MEMCPY (0x70), MEMSET (0x71), MEMCMP (0x72), and JMP_IND (0x73) have
been added to the VM. Remaining candidates (CALL_IND, FIND_BYTE) are
deferred unless profiling shows a need. Opcodes 0x74-0xFF remain
reserved for future extensions.
