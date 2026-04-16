#!/bin/bash
# demo-guess.sh — Run the Guess The Number demo.
#
# This is interactive — the game prompts you for numeric guesses.
# The target number is 42.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PV24T="$REPO_DIR/../sw-cor24-pcode/target/release/pv24t"
P24="$REPO_DIR/build/basic.p24"
BAS="$REPO_DIR/examples/guess.bas"

if [ ! -f "$P24" ]; then
  echo "build/basic.p24 not found — run ./scripts/build-basic.sh first" >&2
  exit 1
fi

# Preload the .bas via -i so pv24t's stdin stays connected to the terminal.
"$PV24T" "$P24" -n 0 -i "$(cat "$BAS")"
