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

"$PV24T" "$P24" -n 0 -i "$(cat "$BAS")"
