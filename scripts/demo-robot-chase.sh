#!/bin/bash
# demo-robot-chase.sh — Run the Robot Chase demo.
#
# Interactive. Type 99 to resign. Commands:
#   7 8 9   NW N NE
#   4 5 6   W WAIT E
#   1 2 3   SW S SE
#   0=TELEPORT  10=LRS  99=RESIGN
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PV24T="$REPO_DIR/../sw-cor24-pcode/target/release/pv24t"
P24="$REPO_DIR/build/basic.p24"
BAS="$REPO_DIR/examples/robot-chase.bas"

if [ ! -f "$P24" ]; then
  echo "build/basic.p24 not found — run ./scripts/build-basic.sh first" >&2
  exit 1
fi

# Pre-seed the PRNG from the shell so each launch gets a different board.
# The program uses `IF R=0 THEN LET R=5237`, so any nonzero R we inject
# here wins over the default. $RANDOM is 15 bits on bash/zsh; multiply by
# PID ($$) for a bit more spread. Override with REG_RS_SEED for repro.
SEED="${REG_RS_SEED:-$(( ($RANDOM * 31 + $$) | 1 ))}"

"$PV24T" "$P24" -n 0 -i "LET R=$SEED"$'\n'"$(cat "$BAS")"
