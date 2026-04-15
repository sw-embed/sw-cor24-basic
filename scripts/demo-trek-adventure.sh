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

# Preload the .bas via -i so pv24t's stdin stays connected to the terminal.
# That way the terminal's line discipline (cooked mode, local echo) shows
# your typed characters. Piping via { cat; cat; } makes stdin a pipe, which
# breaks the visible echo feedback on some terminals.
"$PV24T" "$P24" -n 0 -i "$(cat "$BAS")"
