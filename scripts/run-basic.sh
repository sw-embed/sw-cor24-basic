#!/bin/bash
# run-basic.sh — Run a .bas file through the BASIC interpreter
# Usage: ./scripts/run-basic.sh [--quiet] examples/hello.bas
#
# Feeds the .bas file as UART input to the compiled interpreter.
# Uses pv24t (host-side p-code trace interpreter).
set -euo pipefail

QUIET="${BASIC_QUIET:-0}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -q|--quiet)
      QUIET=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--quiet] <file.bas>"
      echo "Set BASIC_QUIET=1 to suppress the startup banner without a flag."
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Usage: $0 [--quiet] <file.bas>" >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

BAS="${1:?Usage: $0 [--quiet] <file.bas>}"
if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [--quiet] <file.bas>" >&2
  exit 2
fi

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
# pv24t: -n 0 means unlimited. Override with BASIC_MAX_INSN if you want a cap
# (e.g. for tight CI loops). Interactive game demos can spin forever waiting
# on input, so the default has to be unlimited.
: "${BASIC_MAX_INSN:=0}"
"$PV24T" "$P24" -i "$INPUT" -n "$BASIC_MAX_INSN" 2>&1 | \
  awk -v quiet="$QUIET" '
    {
      sub(/^>+/, "")
      if (quiet != "0" && quiet != "" && NR == 1 && $0 == "COR24 BASIC V1") next
      if (quiet != "0" && quiet != "" && NR == 2 && $0 == "READY") next
      if ($0 != "") print
    }'
