#!/bin/bash
# demo-startrek.sh — Run the Star Trek demo through the BASIC interpreter.
#
# This is interactive — the game prompts you for commands. Use QUI (option 0)
# to resign and exit. The script runs pv24t with no instruction cap so the
# game can sit waiting for your input as long as you like.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PV24T="$REPO_DIR/../sw-cor24-pcode/target/release/pv24t"
P24="$REPO_DIR/build/basic.p24"
BAS="$REPO_DIR/examples/startrek.bas"

if [ ! -f "$P24" ]; then
  echo "build/basic.p24 not found — run ./scripts/build-basic.sh first" >&2
  exit 1
fi

# Pipe the .bas program in, then leave stdin open for interactive play.
{ cat "$BAS"; cat; } | "$PV24T" "$P24" -n 0
