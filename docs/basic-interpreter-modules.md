# BASIC Interpreter Module Structure

The interpreter is built from small, independently compilable Pascal
modules. Each produces `.spc` (p-code assembly) that the linker (`pl24r`)
merges into a single binary. Each module is under 8KB source to fit
within the p24p UART input buffer.

## Modules

### basic_tokens — Token Definitions
- Token byte constants (keywords, operators, delimiters, variables, literals)
- Keyword string table (24 × 8-char flat array)
- Classification: `is_keyword`, `is_operator`, `is_variable`
- Variable index conversion: `var_index`, `var_token`
- Detokenizer: `print_keyword`, `print_operator`, `print_variable`

### basic_lex — Tokenizer
- `tokenize` — convert text line to token byte sequence
- Keyword matching (longest match, case-insensitive)
- Integer literals (24-bit), string literals, variables A-Z
- Operators including two-char `<>`, `<=`, `>=`
- Line number extraction
- REM rest-of-line handling

### basic_store — Program Store
- 4KB packed sorted buffer of tokenized lines
- Format: `[line_hi][line_lo][len][tokens...]`
- `store_init`, `store_insert`, `store_delete`
- `store_find`, `store_next`, `store_count`

### basic_expr — Expression Parser (planned)
- Precedence climbing: comparisons, +/-, */÷, unary
- PEEK(addr), ABS(expr) built-in functions
- Reads tokens from buffer via cursor

### basic_vars — Variable Table (planned)
- 26-element integer array for A-Z
- `var_get(idx)`, `var_set(idx, val)`
- `vars_clear` for RUN/NEW

### basic_io — Console I/O (planned)
- `print_char`, `print_string`, `print_integer`, `print_newline`
- `read_line` — line input with echo
- `parse_integer` — string to integer conversion

### basic_stmt — Statement Handlers (planned)
- PRINT, LET, implicit LET, INPUT, POKE
- GOTO, GOSUB, RETURN, IF...THEN
- FOR...NEXT, STOP, END

### basic_exec — Execution Engine (planned)
- Statement dispatch loop
- RUN, LIST, NEW, BYE command handling
- Error handling and recovery

### basic_main — Entry Point (planned)
- REPL loop: read line → tokenize → dispatch
- Startup banner, initialization
- Immediate mode vs stored program mode

## Compilation Strategy

Each module compiles independently:
```
module.pas → p24p → module.spc
```

All modules link together:
```
pl24r runtime.spc tokens.spc lex.spc store.spc ... main.spc → linked.spc
pa24r linked.spc → basic.p24
pv24t basic.p24   (or load into pvm on emulator)
```

## Open Question: Separate Compilation

p24p currently requires each file to be a complete `program ... begin ... end.`
Pascal program. It cannot compile standalone procedure libraries.

Options:
1. **Manual .spc extraction** — compile each module, strip the main block,
   export procedures manually in the .spc
2. **p24p unit support** — add `unit`/`uses` to the compiler
3. **Single-file build** — concatenate all modules into one large .pas file
   (requires solving the 8KB UART limit)
4. **p-code library linker** — new tool that links pre-compiled .spc
   procedure modules without requiring source-level compilation
