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
./scripts/demo-count.sh
./scripts/demo-memdump.sh
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
| `demo-count.sh` | `examples/count.bas` | Minimal `FOR`/`NEXT` smoke test, counts 1..10. |
| `demo-memdump.sh` | `examples/memdump.bas` | `POKE` then `PEEK` round-trip on a low scratch address. Demonstrates the byte-MMIO syntax. |
| *(no wrapper)* | `examples/blink.bas` | LED blink loop targeting the COR24 LED MMIO at `0xFF0000`. **Hardware/cor24-emu only** — `pv24t` traps because the address is outside its VM memory. |

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

### count.bas

The smallest stored-program example: `FOR I=1 TO 10 / PRINT I / NEXT`.
Useful as a baseline when poking at the build pipeline.

### memdump.bas

Pokes the bytes `72`, `73`, `33` ('H', 'I', '!') into addresses
`100..102`, then loops with `PEEK(I)` to print each byte:

```
100=72
101=73
102=33
```

The address range is just regular `pv24t` VM memory; no MMIO. The
demo exists to show that the language form `POKE addr,val` and
`PEEK(addr)` round-trips correctly. For real MMIO targets, see
`blink.bas`.

### blink.bas — hardware only

`POKE 16711680,0` then `POKE 16711680,1` toggles bit 0 at COR24's
`IO_LEDSWDAT` register (`0xFF0000`), where LED D2 lives. On real
hardware (or `cor24-emu`) this physically blinks the LED.

**Under `pv24t` it traps.** The host-side p-code interpreter only
allocates linear VM memory and `0xFF0000` is far outside the
allocated region. There is intentionally **no `demo-blink.sh`
wrapper** — running it would just trap. To exercise it, target the
emulator/hardware p-code VM (`pvm.s`) instead of `pv24t`. That path
isn't wired into `build-basic.sh` yet; it'll come with the unit
build pipeline (steps 018–019) which produces a `.p24m` image
loadable by `cor24-emu`.

Same caveat applies to `LED`/switch-style demos in general: under
`pv24t` the LED syscall (`sys 3`) is a no-op and `READ_SWITCH`
(`sys 6`) always returns 0.

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
