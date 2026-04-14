<!--
SPDX-License-Identifier: MIT
Copyright (c) 2026 Michael A Wright

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
-->

# COR24 BASIC — STAR TREK Game Specification

A clean-room, memory-faithful command-line clone of the 1970s teletype
"Star Trek" family of BASIC games, written from fuzzy recollection of a
Univac 1100-series version played in 1976. **Not a port.** No source
listing, help text, prose, or distinctive UI strings have been copied
from the Ahl, Leedom, or Mayfield versions. The high-level mechanics
(8×8 galaxy, scan/move/fight, time-and-energy budget) come from the
public game-design space; everything else is original.

## 1. Story

You command the starship `ENTERPRISE`. The Federation is under attack
by a Klingon battle fleet scattered across the galaxy. You have until
the **final stardate** to find and destroy every Klingon ship. Run out
of time, energy, or hull, and the mission ends in failure.

## 2. World Model

### 2.1 Galaxy

The galaxy is an **8×8 grid of quadrants**, addressed by row (`QR`)
and column (`QC`), each in `0..7`.

### 2.2 Quadrant

Each quadrant is an **8×8 grid of sectors**, addressed by row (`SR`)
and column (`SC`), each in `0..7`.

Sector contents (one symbol per cell):

| Symbol | Meaning |
|---|---|
| `.` | empty space |
| `E` | the `Enterprise` (you) |
| `K` | a Klingon ship |
| `*` | a star |
| `B` | a starbase |

Display borders use simple ASCII; no graphics characters.

### 2.3 Galaxy summary

Each quadrant has a three-digit summary `KBS` where:

- `K` = number of Klingons in the quadrant (`0..3`)
- `B` = number of starbases (`0..1`)
- `S` = number of stars (`0..7`)

## 3. Ship State

All state is held in BASIC `A`..`Z` integer variables (the v1 dialect
has no arrays beyond what `PEEK`/`POKE` simulates; see §10).

| Var | Meaning | Initial |
|---|---|---|
| `E` | energy | 3000 |
| `T` | photon torpedoes | 10 |
| `H` | shield strength | 0 |
| `D` | current stardate | 2300 |
| `F` | final stardate (loss after this) | `D + 30` |
| `K` | total Klingons remaining in galaxy | computed at start |
| `N` | Klingons in current quadrant | derived from galaxy summary |
| `B` | starbases in current quadrant | derived |
| `I` | stars in current quadrant | derived |
| `Q` | current quadrant index, `QR*8 + QC` | random at start |
| `S` | current sector index, `SR*8 + SC` | random at start |
| `R` | PRNG state (see §9) | seeded from `D` |
| `W,X,Y,Z` | scratch / loop counters | — |
| `M` | last command code (see §4) | — |
| `J,L,O,P,U,V,A,C,G` | reserved for command parameters and temps | — |

`A`..`Z` is 26 variables. The 17 used above leave 9 scratch slots — enough
for the loops and helpers in §6–§8.

### 3.1 Shields

Energy can be transferred between the energy pool and the shields with
the `SHE` command (§4.6). Klingon attacks reduce shields first; when
shields hit 0, further damage drains energy. Energy at 0 ⇒ ship lost.

## 4. Commands

The REPL prompt is:

```
COMMAND>
```

After printing the prompt, the game reads a line via `INPUT`, parses
the first letter (or two-letter mnemonic), dispatches, and re-prompts
unless the game ended.

| Mnemonic | Long form | Code | Description |
|---|---|---|---|
| `SRS` | short range scan | 1 | Print the current quadrant's 8×8 sector grid plus a one-line status block. |
| `LRS` | long range scan | 2 | Print a 3×3 grid showing the summary `KBS` of the current quadrant and its eight neighbours. |
| `WAR` | warp move | 3 | Move between quadrants. Prompts for direction (`1..8`, see §6.1) and warp factor (`1..8`). |
| `IMP` | impulse move | 4 | Move within the current quadrant. Prompts for direction and step count. |
| `PHA` | phaser fire | 5 | Drain energy into a phaser blast distributed across all Klingons in the current quadrant. |
| `TOR` | torpedo fire | 6 | Launch one photon torpedo on a course (`1..8`); travels in a straight line until it hits something or leaves the quadrant. |
| `SHE` | shield control | 7 | Transfer energy between the pool and shields. Prompts for amount (positive = into shields, negative = out). |
| `STA` | status report | 8 | Print all ship state on one screen. |
| `HEL` | help | 9 | Print the command list. |
| `QUI` | quit | 0 | Resign command and exit. |

(Optional, not required for v1: `DAM` damage report.)

Lookup is by **first three letters, case-insensitive**. A command of
fewer than three letters with no ambiguity (e.g. `S`, `L`, `W`) is
acceptable; the parser may pick the first matching entry. Unknown
input prints `?WHAT` and re-prompts without consuming a stardate.

### 4.1 Stardate cost

Most actions consume stardates:

| Action | Cost |
|---|---|
| `SRS`, `LRS`, `STA`, `HEL` | 0 |
| `IMP` | 0 (just energy) |
| `WAR` factor `f` | `f` (warp 1 = 1 day, warp 8 = 8 days) |
| `PHA`, `TOR`, `SHE` | 0 (Klingons return fire same turn) |

When `D > F`, the game ends with `*** TIME UP ***`.

### 4.2 SRS display

```
   1  2  3  4  5  6  7  8
1  .  .  .  *  .  .  .  .   STARDATE  2305
2  .  K  .  .  .  .  .  .   ENERGY    2840
3  .  .  .  .  .  *  .  .   SHIELDS    150
4  .  .  E  .  .  .  .  .   TORPEDOES   10
5  .  .  .  .  .  .  .  .   KLINGONS    11
6  .  *  .  .  .  B  .  .   QUADRANT   3-5
7  .  .  .  .  .  .  .  .   SECTOR     4-3
8  .  .  .  .  .  .  .  .
```

Row labels `1..8`, column header `1..8`. Two spaces between cells. The
right-side status block lists current values of `D`, `E`, `H`, `T`, `K`,
the quadrant `QR+1 - QC+1`, and the sector `SR+1 - SC+1`. The status
block is optional if it cramps the line; a separate `STA` printout is
acceptable.

### 4.3 LRS display

```
LONG RANGE SCAN AT QUADRANT 3-5

  -1   0   1
 ----------------
| 002 | 010 | 100 |  -1
 ----------------
| 000 | 102 | 003 |   0
 ----------------
| 000 | 001 | 010 |   1
 ----------------
```

Each cell shows the three-digit summary `KBS` of a neighbouring
quadrant; the centre cell is the current quadrant. Cells off the
galaxy edge print `***` instead of digits. After the first time a
quadrant has been scanned by `LRS`, its summary is "known" — `SRS`
displays remembered counts in the right-side status. (The "known"
flag is one bit per quadrant; see §10.)

### 4.4 Movement directions

Directions are encoded as integers `1..8`:

```
        1
    8       2
  7    +    3
    6       4
        5
```

`1` = north (decreasing row), `3` = east (increasing column), `5` =
south, `7` = west, and the diagonals `2 4 6 8` follow chess-king moves.
This is simpler than the floating-point compass headings of the
original family and is well within integer-only BASIC.

### 4.5 PHA — phasers

Prompts:

```
ENERGY TO FIRE? 
```

Input is in `0..E`. Damage is divided equally across all Klingons in
the current quadrant, with a 50% falloff per sector of distance
(Chebyshev/king-move distance, an integer). A Klingon takes damage
in **shield units**; each Klingon starts with 200 shield units. When a
Klingon's shields hit 0 it is destroyed:

```
KLINGON AT 4-7 DESTROYED
```

After phasers fire, all surviving Klingons in the quadrant return fire
on `Enterprise` (see §4.7).

### 4.6 TOR — torpedoes

Prompts:

```
COURSE 1-8? 
```

Decrements `T` by 1; consumes 100 energy. The torpedo moves one sector
per step in the direction given. On each step:

- If it leaves the 8×8 quadrant → `MISS`, log entry, return to prompt.
- If it lands on a `K` → Klingon destroyed, decrement `K` and `N`.
- If it lands on a `*` → star absorbs the torpedo, return to prompt.
- If it lands on a `B` → starbase destroyed (severe Federation
  reprimand printed but game continues).
- Otherwise → continue to next sector.

### 4.7 Klingon return fire

Each surviving Klingon fires on `Enterprise` at the end of any
combat-ending turn (after `PHA` or `TOR`). Damage per Klingon is
`30..60` random units, falling off with distance. Damage hits shields
first; overflow drains energy. If `H` reaches a negative value or
`E ≤ 0`, the game ends with `*** ENTERPRISE LOST ***`.

## 5. Win/Lose Conditions

| Outcome | Trigger |
|---|---|
| **WIN** — `*** MISSION COMPLETE ***` | `K = 0` (all Klingons destroyed) |
| **LOSS — TIME UP** — `*** STARDATE EXPIRED ***` | `D > F` |
| **LOSS — DESTROYED** — `*** ENTERPRISE LOST ***` | `E ≤ 0` after damage |
| **LOSS — RESIGNED** — `*** COMMAND RESIGNED ***` | `QUI` command |

The end-of-game line is followed by a one-line summary
(`KLINGONS REMAINING: n`, `STARDATE: d`, `ENERGY: e`) and `END`.

## 6. Movement

### 6.1 WAR — warp drive

Prompts:

```
COURSE 1-8? 
WARP FACTOR 1-8? 
```

Energy cost: `8 * factor`. The new quadrant is `(QR + dr*factor, QC + dc*factor)`,
where `(dr, dc)` is the unit step for the chosen direction. If the
result lies outside `0..7`, the move is clamped to the galaxy edge and
a warning is printed (`OUT OF GALAXY — POSITION CLAMPED`).

Sector position after a warp is randomized within the destination
quadrant (you re-emerge at a random empty sector).

### 6.2 IMP — impulse drive

Prompts:

```
COURSE 1-8? 
SECTORS 1-8? 
```

Energy cost: `1 * sectors`. The Enterprise moves one sector per step
in the chosen direction. If a step would land on a non-empty sector,
the move stops one sector short and prints `OBSTRUCTED AT s-r`. If a
step would leave the quadrant, the Enterprise re-enters the next
quadrant in the appropriate direction (a soft warp 1) and the move
ends.

## 7. Red Alert

Whenever `Enterprise` enters a quadrant where `N > 0` (one or more
Klingons), the game prints:

```
\007*** RED ALERT *** RED ALERT *** RED ALERT ***
```

`\007` = ASCII BEL (`CHR$(7)`). Each alert line is emitted via
`PRINT CHR$(7);"*** RED ALERT *** RED ALERT *** RED ALERT ***"`.
The alert is also printed on game start if the starting quadrant
happens to contain Klingons.

## 8. Random Galaxy Generation

At game start (before the first prompt) the game:

1. Seeds the PRNG `R` from the stardate `D` (which is itself a small
   constant in v1; the seed becomes `D + 1` if a re-roll is needed).
2. For each of the 64 quadrants, rolls:
   - `K` = 0 with probability ~85%, else `1..3`
   - `B` = 1 with probability ~10%, else `0`
   - `S` = `1..5` (always at least one star, for visual interest)
3. Stores the packed `KBS` summary in the galaxy memory array (§10).
4. Sums all `K` values into the global `K` counter.
5. Picks a random quadrant for the Enterprise.
6. Picks a random empty sector within that quadrant.
7. Computes `F = D + 30`.

If the galaxy generates with zero Klingons, re-roll once.

## 9. Pseudo-Random Number Generator

BASIC v1 has no `RND` builtin. The game uses an inline subroutine
implementing a small linear congruential generator that fits within
24-bit signed integer arithmetic:

```
9000 REM PRNG: ENTRY R, EXIT R IN 0..8190
9010 LET R=R*97+1
9020 LET R=R-(R/8191)*8191
9030 RETURN
```

Modulus `8191` (a Mersenne prime) and multiplier `97` are chosen so
that `R*97 + 1` cannot overflow the 24-bit signed range
(`8190 * 97 + 1 = 794431 < 8388607`). To get a value in `0..N-1`,
the caller does `R - (R/N)*N` after `GOSUB 9000`.

If `R` is ever zero at entry, line 9010 sets it to 1 first. The seed
should be initialized to a small positive integer at game start
(`LET R = D` works fine).

## 10. BASIC v1 Workarounds

### 10.1 Arrays via PEEK/POKE

BASIC v1 has only 26 scalar variables. The galaxy and current sector
grid live in low VM memory and are accessed with `POKE`/`PEEK`:

| Address range | Size | Purpose |
|---|---|---|
| `100..163` | 64 bytes | galaxy `K` count per quadrant |
| `200..263` | 64 bytes | galaxy `B` count per quadrant |
| `300..363` | 64 bytes | galaxy `S` count per quadrant |
| `400..463` | 64 bytes | "known" flag from prior LRS scan |
| `500..563` | 64 bytes | current sector grid (one byte per cell) |
| `600..663` | 64 bytes | per-Klingon shield strength (current quadrant only) |

Accessor pattern:

```
REM SET GALAXY K[QR,QC] = N
LET A=100+QR*8+QC
POKE A,N

REM READ SECTOR[SR,SC] INTO X
LET A=500+SR*8+SC
LET X=PEEK(A)
```

These addresses are within `pv24t`'s VM memory and were verified safe
in step 017. On real hardware they map to ordinary RAM as well.

### 10.2 No string variables

`PRINT` literals are the only strings. Command parsing uses `INPUT` to
read a single integer command code from the user (the spec above shows
mnemonic prompts; the implementation may either parse a 1–3 letter
mnemonic via `PEEK`-on-input-buffer trickery, or simply present a
numeric menu like `1=SRS 2=LRS 3=WAR ...`). The numeric-menu
fallback is acceptable for v1 if mnemonic parsing proves too costly.

### 10.3 CHR$ for control characters

The interpreter provides `CHR$(n)` inside `PRINT` item lists, so BEL
and other control characters are emitted directly via
`PRINT CHR$(7);` (see §7). No `POKE`-to-UART workaround is needed.
`CHR$` is only valid as a `PRINT` item; it cannot appear in
expressions or `LET`.

### 10.4 No floating-point

All distances, damages, and energy values are integers. The 50% phaser
falloff per sector is approximated by `dam = dam / 2` per step. Klingon
return fire uses `30 + (R mod 31)` for a `30..60` damage roll.

## 11. Implementation Notes

The implementation lives at `examples/startrek.bas`. It is a
single-file BASIC program ending in `RUN` and `BYE` so that
`./scripts/demo-startrek.sh` runs it through `pv24t` like every other
demo.

Suggested line-number layout:

| Range | Section |
|---|---|
| `100..199` | initialization, galaxy generation |
| `200..299` | main command loop |
| `300..399` | SRS |
| `400..499` | LRS |
| `500..599` | WARP movement |
| `600..699` | IMPULSE movement |
| `700..799` | PHASER fire + Klingon return fire |
| `800..899` | TORPEDO fire |
| `900..999` | SHIELD control + STATUS + HELP |
| `1000..1099` | game-over handling |
| `9000..9099` | PRNG and small utilities |

Stardate is integer in v1, so movement that costs "0.5 stardate" in
the original family is rounded to whole-day costs (warp 1 = 1 day).

## 12. Open Questions

These are deferred to step 022 (feature audit):

- Does the interpreter need a `RND` builtin or is the BASIC-level LCG
  in §9 acceptable?
- Does it need `CHR$` for the BEL alert or can a literal control byte
  be embedded in a `PRINT` string?
- Mnemonic command parser vs. numeric menu — which fits the source
  budget?
- Does `STA` need a `DAM` companion for damage reporting, or is the
  consolidated status block in `SRS`/`STA` enough?

These will be answered in step 022 when feature requirements are
audited against the interpreter as it stands today.
