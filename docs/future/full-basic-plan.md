# ELIZA Scan Analysis And Future BASIC Plan

## What Was Preserved

- [chandra2-scanned-eliza.txt](/Users/mike/github/sw-embed/sw-cor24-basic/docs/future/chandra2-scanned-eliza.txt) is a verbatim preservation of the scanned listing that had been stored as `examples/eliza-chandra2.bas`.
- [eliza-using-string-functions,bas](/Users/mike/github/sw-embed/sw-cor24-basic/docs/future/eliza-using-string-functions,bas) is a repaired listing with only obvious OCR and scan-join fixes applied. It is not translated to COR24 BASIC v1.

## OCR Repairs Applied

- Restored missing spaces in obvious keyword joins:
  `FORX` -> `FOR X`, `THEN360` -> `THEN 360`, `GOTO390` -> `GOTO 390`, `GOTO557` -> `GOTO 557`, `IFR(K)` -> `IF R(K)`.
- Repaired the most likely apostrophe OCR issue in line 230:
  `"-"` -> `"'"`.
- Removed stray backslashes before `*` in reply data lines, treating them as scan artifacts rather than intentional source text.
- Normalized a few spacing glitches such as `FOR L= 1` -> `FOR L=1`.

## Why The Repaired Listing Still Cannot Run

The repaired listing still targets a larger string-capable BASIC than COR24 BASIC v1.

Current COR24 BASIC v1 supports only:

- Integer scalar variables `A` through `Z`
- `LET`, `PRINT`, `INPUT`, `IF ... THEN`, `GOTO`, `GOSUB`, `RETURN`
- `FOR ... TO ... STEP`, `NEXT`, `STOP`, `END`, `REM`
- `PEEK`, `POKE`, `ABS`, `CHR$`

ELIZA depends on features that are absent:

- String variables: `I$`, `P$`, `F$`, `C$`, `K$`, `S$`, `R$`
- Arrays: `DIM S(36),R(36),N(36)` and indexed references like `S(X)`
- String functions: `LEN`, `LEFT$`, `MID$`, `RIGHT$`
- Data statements and data cursor control: `DATA`, `READ`, `RESTORE`
- `TAB(n)` in `PRINT`
- Multi-statement lines with `:`
- Multi-character numeric variable names like `N1`, `N2`, `N3`

## What A Direct Compatibility Upgrade Would Require

To execute this repaired listing mostly as written, the interpreter would need at least:

1. Colon-separated statement sequencing in the executor.
2. Extended identifier support beyond single-letter numeric scalars.
3. Array storage and `DIM`.
4. A string type with assignment, comparison, and concatenation.
5. String slicing and utility builtins: `LEN`, `LEFT$`, `MID$`, `RIGHT$`.
6. `DATA`, `READ`, and `RESTORE`, including mixed string/numeric data.
7. `TAB(n)` or compatible print-position control.

This is no longer a small v1 extension. It is a substantial dialect expansion.

## Recommended Path

The lowest-risk path is not to teach v1 to run this program directly.

Recommended sequence:

1. Keep the repaired listing as a historical reference.
2. Translate ELIZA into native COR24 BASIC v1 style.
3. Replace arrays with fixed `PEEK`/`POKE` tables or flattened numeric memory blocks.
4. Replace string-heavy parsing with a reduced command or token scheme.
5. Keep the original repaired listing alongside the translation for provenance.

## If We Want A Richer BASIC Later

If the project wants a future "full BASIC" tier rather than a one-off ELIZA translation, the staged implementation order should be:

1. `:` multi-statement execution.
2. Longer identifiers and better tokenizer support.
3. `DIM` and numeric arrays.
4. `DATA` / `READ` / `RESTORE`.
5. String variables and string expressions.
6. `LEN`, `LEFT$`, `MID$`, `RIGHT$`, `TAB`.

That order gets the interpreter structurally ready before adding full string manipulation, which is the largest runtime and storage change.
