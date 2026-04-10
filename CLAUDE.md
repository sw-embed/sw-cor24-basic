# sw-cor24-basic — Claude Instructions

## Project Overview

COR24 BASIC v1 — a 1970s time-sharing-style, line-numbered, integer-only
BASIC interpreter for the COR24 p-code virtual machine. Inspired by
UNIVAC 1100-series terminal BASIC with teletype and paper-tape workflows.
Emphasizes simplicity, hardware access (PEEK/POKE), and interactive
program development over compatibility with later BASIC standards.

BASIC complements Pascal in the COR24 ecosystem: Pascal is compiled and
structured; BASIC is interpreted, dynamic, and interactive — ideal for
monitor/scripting/hardware bring-up work.

## CRITICAL: AgentRail Session Protocol (MUST follow exactly)

### 1. START (do this FIRST, before anything else)
```bash
agentrail next
```
Read the output carefully. It contains your current step, prompt,
plan context, and any relevant skills/trajectories.

### 2. BEGIN (immediately after reading the next output)
```bash
agentrail begin
```

### 3. WORK (do what the step prompt says)
Do NOT ask "want me to proceed?". The step prompt IS your instruction.
Execute it directly.

### 4. COMMIT (after the work is done)
Commit your code changes with git. Use `/mw-cp` for the checkpoint
process (pre-commit checks, docs, detailed commit, push).
**Run `/mw-cp` in every repo that was modified during the step.**

### 5. COMPLETE (LAST thing, after committing)
```bash
agentrail complete --summary "what you accomplished" \
  --reward 1 \
  --actions "tools and approach used"
```
- If the step failed: `--reward -1 --failure-mode "what went wrong"`
- If the saga is finished: add `--done`

### 6. STOP (after complete, DO NOT continue working)
Do NOT make further code changes after running `agentrail complete`.
Any changes after complete are untracked and invisible to the next
session. Future work belongs in the NEXT step, not this one.

## Key Rules

- **Do NOT skip steps** — the next session depends on accurate tracking
- **Do NOT ask for permission** — the step prompt is the instruction
- **Do NOT continue working** after `agentrail complete`
- **Commit before complete** — always commit first, then record completion

## Useful Commands

```bash
agentrail status          # Current saga state
agentrail history         # All completed steps
agentrail plan            # View the plan
agentrail next            # Current step + context
```

## Code Formatting

All `.pas` source files MUST be formatted with `scripts/format.sh` before
every commit. This uses emacs pascal-mode to apply consistent indentation.

```bash
./scripts/format.sh        # format all src/*.pas files
```

Run this as part of your pre-commit workflow. Do not commit unformatted
Pascal source.

## Build / Test

The BASIC interpreter runs on the COR24 p-code VM. Implementation
language is TBD (Pascal compiled to p-code, p-code assembly, or
host-side prototype in Rust/C first).

- p-code VM: `sw-cor24-pcode` — the execution substrate
- Pascal compiler: `sw-cor24-plsw` — compiles Pascal to p-code
- Emulator: `sw-cor24-emulator` — runs COR24 binaries and p-code VM
- Cross-assembler: `sw-cor24-x-assembler` — if p-code assembly needed
- Cross C compiler: `sw-cor24-x-tinyc` — if C implementation path

## p-code VM / Interpreter Architecture

BASIC sits as a language layer above the p-code VM:

- Layer 0: COR24 hardware/emulator
- Layer 1: p-code VM (language-neutral abstract machine)
- Layer 2: BASIC runtime (terminal I/O, line storage, expression
  helpers, GOSUB/FOR stacks, PEEK/POKE, tape abstraction)
- Layer 3: BASIC interpreter (tokenizer, parser, statement dispatch,
  execution of tokenized lines)

The VM should NOT get BASIC-specific opcodes. Only language-neutral
primitives belong in the VM (byte load/store, memcpy, traps, indirect
jump, generic syscall gateway). Language semantics stay in the
interpreter/runtime layer.

## Cross-Repo Context

All COR24 repos live under `~/github/sw-embed/` as siblings.

### p-code / VM / Pascal ecosystem (most relevant):
- `sw-cor24-pcode` — p-code VM implementation (execution substrate)
- `sw-cor24-pascal` — Pascal language support
- `sw-cor24-plsw` — Pascal-to-p-code compiler
- `sw-cor24-x-pc-aotc` — AOT p-code-to-native compiler (Rust, host-side)
- `sw-cor24-emulator` — emulator + ISA (foundation for everything)

### Other ecosystem repos:
- `sw-cor24-x-assembler` — cross-assembler in Rust (runs on host)
- `sw-cor24-x-tinyc` — cross C compiler in Rust (runs on host)
- `sw-cor24-assembler` — native assembler in C (runs on COR24)
- `sw-cor24-script` — sws scripting language (runs on COR24)
- `sw-cor24-monitor` — resident monitor / service processor
- `sw-cor24-project` — hub/portal repo with migration tracking
- `sw-cor24-macrolisp` — Lisp interpreter
- `sw-cor24-apl` — APL interpreter
- `sw-cor24-forth` — Forth implementation

You are the only agent running for this project and have direct r/w
access to all sw-embed repos.
