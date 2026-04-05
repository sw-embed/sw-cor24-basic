# Toolchain Validation Tests

Tests that validate the Pascal → p-code pipeline can build the BASIC
interpreter. Run with `./run.sh <file.pas>`.

## Pipeline

```
.pas → p24p (compiler) → .spc → pl24r (linker) → pa24r (assembler) → .p24 → pv24t (trace)
```

Uses `pv24t` (trace interpreter) instead of `pvm.s` because pvm.s has
a fixed 8-word globals segment too small for programs with arrays
(sw-cor24-pcode #1).

## Test Programs

### basic_minimal.pas — PASS
Exercises Phase 0 features: arithmetic, while/if, boolean `and`,
`mod`/`div`, writeln.

### basic_features.pas — BLOCKED
Exercises features for the full interpreter. Will compile once p24p
compiler performance issue is resolved (hangs on >155-line programs
with 12+ user procedures).

## Known Issues

### pvm.s globals segment too small (sw-cor24-pcode #1)
The PVM allocates only 8 words (24 bytes) for globals. Programs
with arrays need much more. Using pv24t as workaround.

## Build Notes

- Use `-u` flag (not piped `--terminal`) to feed source to p24p —
  piped terminal blocks on UART reads after input is exhausted.
- Use `--stack-kilobytes 8` for p24p — the compiler needs more than
  the default 3KB stack for larger programs.
