#!/bin/bash
# demo-trek-adventure.sh — Run the Star Trek text adventure demo.
#
# This is interactive — the game prompts you for numeric commands.
# Pick 8 for HELP in-game, or 0 to resign.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PV24T="$REPO_DIR/../sw-cor24-pcode/target/release/pv24t"
P24="$REPO_DIR/build/basic.p24"
BAS="$REPO_DIR/examples/trek-adventure.bas"

if [ ! -f "$P24" ]; then
  echo "build/basic.p24 not found — run ./scripts/build-basic.sh first" >&2
  exit 1
fi

# Pipe the .bas program in, then leave stdin open for interactive play.
{ cat "$BAS"; cat; } | "$PV24T" "$P24" -n 0
