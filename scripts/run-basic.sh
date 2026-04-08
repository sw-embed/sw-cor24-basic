#!/bin/bash
# run-basic.sh — Run a .bas file through the BASIC interpreter
# Usage: ./scripts/run-basic.sh examples/hello.bas
#
# Feeds the .bas file as UART input to the compiled interpreter.
# Uses pv24t (host-side p-code trace interpreter).
set -euo pipefail

BAS="${1:?Usage: $0 <file.bas>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PV24T="$REPO_DIR/../sw-cor24-pcode/target/release/pv24t"
P24="$REPO_DIR/build/basic.p24"

if [ ! -f "$P24" ]; then
  echo "build/basic.p24 not found — run ./scripts/build-basic.sh first" >&2
  exit 1
fi

# Feed .bas content as UART input, strip all > prompts.
# Append EOT (\x04) so the final line terminates cleanly even if the
# file lacks a trailing newline after BYE — otherwise read_line blocks
# waiting for more UART input and the run appears to hang.
INPUT="$(cat "$BAS")"$'\n\x04'
"$PV24T" "$P24" -i "$INPUT" -n 10000000 2>&1 | sed -E 's/^>+//' | grep -v '^$'
