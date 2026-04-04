# Toolchain Validation Tests

Tests that validate the Pascal → p-code pipeline can build the BASIC
interpreter. Run with `./run.sh <file.pas>`.

## Pipeline

```
.pas → p24p (compiler) → .spc → pl24r (linker) → pa24r (assembler) → .p24 → pvm.s (VM)
```

## Test Programs

### basic_minimal.pas — PASS

Exercises features that p24p supports today: arithmetic, while/if,
boolean `and`, `mod`/`div`, writeln. Validates the pipeline works
end-to-end.

### basic_features.pas — BLOCKED

Exercises features the BASIC interpreter requires but p24p doesn't
support yet: user-defined procedures/functions, arrays, char manipulation.

## Blockers (sw-cor24-pascal issues)

| Feature         | Issue | Status  | BASIC needs it for                     |
|-----------------|-------|---------|----------------------------------------|
| Procedures      | #1    | Blocked | Interpreter structure (tokenizer, parser, eval, I/O) |
| Arrays          | #2    | Blocked | Program store, buffers, variable table, stacks |
| Char type       | #3    | Blocked | Tokenizer, input parsing, string handling |
| peek/poke       | #5    | Needed  | PEEK/POKE statements, hardware demos   |
| Script bug      | #4    | Bug     | test-all.sh uses stale code_ptr address |
