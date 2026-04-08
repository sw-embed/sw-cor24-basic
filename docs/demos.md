# COR24 BASIC — Demo Programs

A small gallery of programs that exercise the v1 interpreter. Each
demo has a matching `scripts/demo-<name>.sh` wrapper that builds (if
needed) and runs the corresponding `examples/<name>.bas` through
`pv24t`, the host-side p-code interpreter.

## Running

```sh
./scripts/build-basic.sh        # one-time, or after editing src/
./scripts/demo-hello.sh
./scripts/demo-calc.sh
./scripts/demo-fizzbuzz.sh
./scripts/demo-fibonacci.sh
./scripts/demo-factorial.sh
```

Each script feeds the `.bas` file to the interpreter as if it were
typed at the REPL. The files include trailing `RUN` and `BYE` lines
so they run end-to-end and exit cleanly.

## Demo Index

| Script | File | What it shows |
|---|---|---|
| `demo-hello.sh` | `examples/hello.bas` | Immediate-mode `PRINT` and `BYE`. The smallest possible program. |
| `demo-calc.sh` | `examples/calc.bas` | Arithmetic, `LET`, mixed string/expression `PRINT`. *(Note: shows the open ABS bug — see issue #1.)* |
| `demo-fizzbuzz.sh` | `examples/fizzbuzz.bas` | `FOR`/`NEXT`, `IF`...`THEN GOTO`, divisibility via `(I/N)*N=I`, multi-target dispatch. |
| `demo-fibonacci.sh` | `examples/fibonacci.bas` | Iterative two-variable swap inside `FOR`/`NEXT`. First 10 Fibonacci numbers. |
| `demo-factorial.sh` | `examples/factorial.bas` | Iterative product accumulator inside `FOR`/`NEXT`. Mixed-type `PRINT` of `N;"!=";F`. |

## Demo Notes

### hello.bas

```basic
PRINT "HELLO WORLD"
BYE
```

Immediate mode — no line numbers. The simplest possible smoke test.

### calc.bas

Demonstrates arithmetic precedence (`(A+B)*2`), integer division
(`100/7=14`), and the mixed-type `PRINT` form (`PRINT "X=";X`).

> **Open bug:** the last line shows `ABS(-42)=10` instead of `42`.
> `ABS` is declared in `src/basic_tokens.pas` but not initialized in
> the `ik` keyword table, so the tokenizer falls through and consumes
> `A` as variable A. Tracked in
> [sw-cor24-basic#1](https://github.com/sw-embed/sw-cor24-basic/issues/1)
> and queued as saga step `025-fix-abs-bug`.

### fizzbuzz.bas

There is no `MOD` operator in v1. Divisibility is tested with
`(I/N)*N = I` since integer division truncates. The dispatch chain
checks 15 first, then 3, then 5; each branch jumps to a print line
and back to `NEXT` via `GOTO`.

### fibonacci.bas

Classic three-variable rotation:

```basic
50 PRINT A
60 LET C=A+B
70 LET A=B
80 LET B=C
```

Outputs the first ten terms (0..34). Watch out for overflow: integers
are 24-bit signed, so the sequence stays valid up through the low
millions.

### factorial.bas

`N!` via straight `FOR I=1 TO N` accumulation. With `N=7` you get
`5040`. The 24-bit integer ceiling caps you at `12!` (479,001,600);
`13!` overflows.

## Recursion?

**Short answer:** no, not usefully.

COR24 BASIC v1 has `GOSUB`/`RETURN` with a 64-deep return stack, so
you *can* call a subroutine from within itself — the return addresses
nest correctly. But there are no parameters and no per-call locals:
all 26 variables (`A`..`Z`) are global. Each "recursive" call
overwrites the same storage as its caller, so by the time `RETURN`
fires, the supposed "local state" is gone.

There is also no tail-call optimization. `GOSUB` always pushes,
`RETURN` always pops; a `GOSUB` immediately followed by `RETURN`
still consumes a stack slot for the duration of the call. Every level
counts against the 64-slot ceiling.

The practical implication: write loops, not recursion. Factorial,
Fibonacci, GCD, and friends are all comfortable as iterative
`FOR`/`NEXT` or `GOTO` loops, which is exactly the style this
flavor of BASIC was designed for.

## Adding a new demo

1. Drop `examples/<name>.bas` ending with `RUN` and `BYE`.
2. Copy an existing wrapper:
   ```sh
   cp scripts/demo-hello.sh scripts/demo-<name>.sh
   sed -i '' "s/hello/<name>/g" scripts/demo-<name>.sh
   ```
3. Add a row to the table above.
4. `./scripts/demo-<name>.sh` to verify.
