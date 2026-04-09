<!-- SPDX-License-Identifier: MIT -->
# Star Trek Feature Audit

Audits every BASIC v1 feature required by `docs/startrek-spec.md`
against the current interpreter (`src/basic.pas`). Each row notes
status, where it's implemented, how the spec relies on it, and any
gap or workaround.

Legend:

- **OK** — feature works, exercised by an existing test or demo
- **OK\*** — feature works but worth a smoke test before step 023
- **WORKAROUND** — feature missing; spec uses an in-language substitute
- **GAP** — feature missing; needs an interpreter change before step 023

## Statements and commands

| Feature | Status | Notes / spec usage |
|---|---|---|
| `LET v = expr` | OK | All ship-state updates |
| Implicit LET (`v = expr`) | OK | Same |
| `PRINT` literal + expr, mixed | OK | Status panel, scan grids |
| `PRINT` with `;` and `,` separators | OK | Column-aware (step 014) |
| Trailing `;` suppresses newline | OK | Building scan grid rows |
| `INPUT v` (default `?` prompt) | OK | Command codes |
| `INPUT "msg"; v` (custom prompt) | OK | `COURSE 1-8?`, `WARP FACTOR 1-8?`, etc. |
| `?REDO` on bad parse | OK | Bad numeric input retried automatically |
| `IF cond THEN <stmt>` | OK | Re-dispatches via `rd` flag |
| `IF cond THEN GOTO line` | OK | Verified during audit |
| `GOTO line` | OK | Main loop, command dispatch |
| `GOSUB line` / `RETURN` | OK | Verified nested case (`GOSUB → GOSUB → RETURN → RETURN`) |
| `FOR v = a TO b` | OK | Scan grid loops |
| `FOR v = a TO b STEP s` (positive) | OK | |
| `FOR v = a TO b STEP -1` (negative) | OK | Verified in step 013 (`10 TO 1 STEP -1`) |
| Nested `FOR` | OK | Verified in step 013 (`I=1..3 / J=1..2`) |
| `REM rest of line` | OK | LIST reproduces verbatim; runtime no-op |
| `END` / `STOP` | OK | Game-over |
| `RUN` / `LIST` / `NEW` / `BYE` | OK | REPL plumbing |
| `POKE addr,val` | OK | Galaxy/sector arrays |
| `PEEK(addr)` | OK | Galaxy/sector reads |
| `ABS(x)` | OK | Distance/damage math (step 025 fix) |

## Operators and expressions

| Feature | Status | Notes |
|---|---|---|
| `+ - * /` | OK | `/` is integer division (24-bit signed) |
| `=` `<>` `<` `<=` `>` `>=` | OK | All comparison ops emit 0/1 |
| Parenthesized subexpressions | OK | |
| Unary `-` | OK | `-1` parses as TP+1 prefix in p_expr level 1 |
| Operator precedence | OK | 5-level climbing (cmp / add / mul / unary / atom) |
| Modulo via `(I/N)*N` and `I-(I/N)*N` | OK | Verified during audit (`10 mod 3 = 1`) |
| Variables `A..Z` (26 scalars) | OK | All ship state and scratch fits in 17 vars |

## I/O and side effects

| Feature | Status | Notes |
|---|---|---|
| Read line via UART (`read_line`) | OK | Cooked into INPUT and the REPL |
| Print to UART (`pc` / `pn`) | OK | Column tracking included |
| Column-aware tab stops (comma) | OK | Useful for the SRS grid |
| **Emit raw byte (BEL = chr 7)** | **GAP** | Spec §7 wants `*** RED ALERT ***` with three BEL beeps. There is no `CHR$`, no string concatenation, and no way to embed a control byte in a `PRINT` literal from a typed `.bas` file. **See action item below.** |

## Things the spec already works around

| Wanted | Workaround already in spec |
|---|---|
| String variables for command parsing | Numeric menu (`1=SRS 2=LRS ...`) — spec §10.2 |
| `RND` / `RANDOMIZE` builtin | Inline LCG subroutine `R = R*97 + 1; R = R - (R/8191)*8191` — spec §9 |
| Floating point | Whole-stardate costs, integer damage falloff — spec §10.4 |
| Arrays `DIM A(63)` | `PEEK`/`POKE` on fixed low addresses — spec §10.1 |
| Multi-statement lines (`:` separator) | Use one statement per line; line numbers are cheap |
| `INT(x)` | All math is integer; `INT` is a no-op in v1 |

## Things the spec does **not** need

These are absent from the interpreter and the spec sidesteps them:

- String variables, `LEN$`, `LEFT$`, `MID$`, `RIGHT$`, `STR$`
- `READ` / `DATA` / `RESTORE`
- `ON ... GOTO` / `ON ... GOSUB` (the dispatch loop is a chain of `IF`s)
- File I/O, `SAVE` / `LOAD`
- User-defined functions (`DEF FN`)
- `INPUT` of multiple values on one line
- `TAB(n)` / `SPC(n)` (the comma tab stop is enough)
- Trig / `SQR` / `LOG` / `EXP`

## Action items

### A1 — emit BEL for the red alert

The spec's signature moment — `\007*** RED ALERT *** KLINGONS DETECTED ***\007`
— needs a way to write a literal control byte to UART. There is no
`CHR$` and the tokenizer doesn't accept embedded control characters
in string literals from a typed source file.

**Decision:** add a small interpreter feature, scoped narrowly. Create
a saga step `026-print-chr-builtin` that adds a `CHR$(n)` form
recognized only inside a `PRINT` item list. When `do_print` sees
`tb[ep] = FK+24` it consumes `(`, parses the inner expression,
expects `)`, and emits the byte via `pc(chr(ev))` instead of routing
through `print_int`. Outside of `PRINT`, `CHR$` is undefined.

This is the smallest change that unblocks the red alert without
introducing a string type. Estimated cost: ~120 source bytes (well
within the current 4 KB headroom).

### A2 — none for PRNG

The inline LCG (spec §9) is good enough. It costs four lines of BASIC
and avoids adding a `RND` builtin. **No saga step.**

### A3 — none for command parsing

The spec already concedes that the implementation may use the numeric
menu form (spec §10.2). Adding a string-input command parser would
require either string variables or `PEEK`-on-input-buffer trickery —
both significantly larger than the value they add. **No saga step.**

## Spec updates

Section 7 of `docs/startrek-spec.md` will be updated once step 026
ships, replacing the placeholder `POKE` to a UART address with
`PRINT CHR$(7);` repeated three times. Until then, the implementation
in step 023 may print the alert without bells.

## Summary

| Category | Required | OK | Workaround | Gap |
|---|---|---|---|---|
| Statements | 19 | 19 | 0 | 0 |
| Operators | 11 | 11 | 0 | 0 |
| I/O primitives | 4 | 3 | 0 | 1 (`CHR$` in PRINT) |
| Game-design helpers | 6 | 0 | 6 | 0 |

**Net:** one interpreter gap (BEL emission). One new saga step
inserted (`026-print-chr-builtin`). The Star Trek implementation
(`023`) is otherwise unblocked.
