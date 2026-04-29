# Feature Request: `INKEY` builtin for entropy and real-time input

**Status**: Proposed
**Filed by**: web-sw-cor24-basic (browser sandbox)
**Date**: 2026-04-29
**Cross-repo dependency**: `sw-cor24-pcode/vm/pvm.s` (new syscall)

## Motivation

COR24 BASIC v1 currently has no source of entropy. The COR24 VM has no
clock, no floating-point rounding, and no asynchronous interrupts — by
construction, a deterministic VM cannot generate randomness from inside
itself. Demos that need a varying seed (`guess-random`, future card and
dice games, anything with shuffled state) currently fall back to either:

1. A hard-coded literal seed — defeats the purpose of "random".
2. A seeded LCG with the same seed every run — deterministic, not random.
3. Cheating via a host-side syscall that exposes `crypto.getRandomValues()`
   — works, but makes the program depend on the browser/OS rather than
   on COR24 itself.

The classic 8-bit microcomputer answer (BBC Micro, Apple II, Commodore)
was to busy-loop a counter while waiting for a keypress and use the
counter as the seed. Reaction time has ~10⁵ ticks of jitter at human
scales, which is plenty of entropy for game-quality RNG. This pattern
requires exactly one new primitive: a **non-blocking** key-poll function.
Adding it gives COR24 BASIC genuine entropy without exposing the host.

The same primitive also unlocks several unrelated features that would
otherwise need separate machinery: ESC-to-cancel inside a loop, real-time
arrow-key game input, animation throttling without `INPUT` blocking the
program, and so on.

## Proposed API

Add a new BASIC builtin:

```basic
INKEY    ; non-blocking; returns 0..255 if a key is buffered, else -1
```

`INKEY` is a function (no arguments) that returns an integer. It
**never blocks**. If a character is currently sitting in the UART
receive buffer it is consumed and returned (0..255). If no character
is available it returns -1 immediately.

This is intentionally distinct from `INPUT` (which still blocks and
reads a full line) — `INKEY` is for polling, `INPUT` is for prompts.

### Reference usage — entropy seed

```basic
10 PRINT "PRESS ANY KEY TO START..."
20 LET R = 0
30 LET R = R + 1
40 IF INKEY < 0 THEN GOTO 30
50 REM R now contains reaction-time entropy (~10^5 ticks of jitter)
60 LET R = (R*97 + 1) MOD 8191
70 LET T = (R MOD 100) + 1
80 PRINT "I PICKED A NUMBER FROM 1 TO 100..."
```

### Reference usage — ESC-to-cancel

```basic
100 FOR I = 1 TO 1000
110   GOSUB 9000      : REM do work
120   IF INKEY = 27 THEN GOTO 200
130 NEXT I
200 PRINT "CANCELLED."
```

## Implementation specification

### Cross-repo: `sw-cor24-pcode/vm/pvm.s`

Add a new syscall, **id 9 = `INKEY`**.

The current GETC syscall (id=2) at `pvm.s:2655` busy-waits on the UART
status register's RX-ready bit before reading the data byte. INKEY
should be the same logic with the wait removed:

```asm
; sys INKEY (id=9): non-blocking read. Push key code (0..255) if RX
; ready, else push -1 (24-bit signed: 0xFFFFFF).
sys_inkey:
    la r2, -65280
    lbu r0, 1(r2)            ; UART status
    lc r2, 1
    and r0, r2               ; bit 0 = RX ready
    ceq r0, z
    brt sys_inkey_empty
    ; RX ready — read data byte
    la r2, -65280
    lbu r0, 0(r2)            ; key code in 0..255
    jmp sys_inkey_push
sys_inkey_empty:
    lc r0, -1                ; sentinel for "no key"
sys_inkey_push:
    la r2, vm_state
    push r2
    pop fp
    lw r2, 3(fp)
    sw r0, 0(r2)
    add r2, 3
    sw r2, 3(fp)
    la r0, vm_loop
    jmp (r0)
```

Wire `id == 9` into the syscall dispatcher around `pvm.s:2596` and add
the `sys_inkey_j` trampoline alongside `sys_dump_j`.

The COR24 emulator side already exposes the UART RX-ready bit
correctly — no changes needed there. INKEY just refrains from polling.

### `sw-cor24-basic/src/basic_tokens.pas`

Bump `NUM_KW` from 24 to 25 and `LAST_KEYWORD` from 151 to 152. Add a
new `kw_set` entry:

```pascal
kw_set(24, 'I','N','K','E','Y',' ',' ',' ');
```

(Or wherever the canonical keyword table now lives in `basic.pas` — the
v1 token list there has grown past what `basic_tokens.pas` shows.)

### `sw-cor24-basic/src/basic.pas`

Add `INKEY` as a parameterless function in the expression evaluator,
parallel to how `ABS` and `PEEK` are dispatched. Its evaluation should
emit (or directly invoke) the new SYS 9 syscall and push the resulting
integer onto the eval stack.

Important: the return value is a **signed 24-bit integer**. -1 must
compare correctly with `< 0` in BASIC expressions. The expected use
pattern `IF INKEY < 0 THEN GOTO 30` must work without surprises around
sign extension.

## Acceptance criteria

1. `INKEY` evaluates to -1 when no key is buffered, never blocks.
2. `INKEY` consumes one character and returns its ASCII code (0..255)
   when a key is buffered.
3. The seed-loop from the reference usage above produces a different
   target on every run (verified by running the demo 10 times and
   observing distinct targets — collisions are possible but should be
   rare given ~10⁵ ticks of jitter).
4. `assets/basic.p24` rebuilds cleanly via `scripts/build-basic.sh`
   and grows by a small amount (one new keyword + one new function
   handler).
5. A new test demo `examples/inkey-demo.bas` is added that exercises
   both reference usages above (entropy seed and ESC-to-cancel).
6. The browser sandbox (`web-sw-cor24-basic`) picks up the new
   interpreter image and a follow-up PR there can rewrite
   `examples/guess-random.bas` to use the entropy seed pattern. (That
   follow-up is out of scope for this feature — only the
   interpreter-side change is requested here.)

## Out of scope (do not implement here)

- `RANDOMIZE` keyword — INKEY is the primitive; `RANDOMIZE` would be a
  convenience wrapper. Defer until INKEY proves useful.
- A built-in `RND` function — would require deciding whether to seed
  from INKEY automatically or expose a separate seed register.
  Designing that wrapper belongs in a separate proposal once INKEY
  ships.
- String-typed return for INKEY (e.g., `INKEY$`) — would require string
  variable support, which COR24 BASIC v1 doesn't have. Integer return
  is sufficient for all current use cases.
- Echo behavior — INKEY should NOT echo the consumed character. If
  callers want to display it they can `PRINT CHR$(K)` themselves.

## Risks and notes

- **Race with line buffering**: if the host UART buffers whole lines
  (rather than per-character) before forwarding to the VM, INKEY will
  appear to block until Enter is pressed. Verify the COR24 emulator's
  UART RX path delivers bytes one at a time. The browser host
  (`web-sw-cor24-basic`) feeds characters one at a time via the input
  ref, so this should be fine — but native/CLI hosts may need a
  one-time tweak to drop line buffering. Worth a note in
  `docs/architecture.md`.
- **Keyboard ghosting**: rapidly polling INKEY in a tight loop should
  not flood the eval stack or starve other VM work. The implementation
  above pushes exactly one value per call, so this is safe.
- **Determinism**: the entropy gained from INKEY-loop seeding is *not*
  cryptographic. It's adequate for game seeding; it is **not** adequate
  for anything security-sensitive. This is the same caveat that applied
  to every 8-bit BASIC's RND.
