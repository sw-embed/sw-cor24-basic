#!/bin/bash
# run.sh — Compile and run a Pascal program through the p24p toolchain
# Usage: ./tests/toolchain/run.sh <file.pas>
#
# Pipeline: .pas → p24p → .spc → pl24r → pa24r → .p24 → pv24t
#
# Uses pv24t (trace interpreter) instead of pvm.s because pvm.s has
# a fixed 8-word globals segment that's too small for programs with
# arrays (see sw-cor24-pcode issue #1).
set -euo pipefail

PAS="${1:?Usage: $0 <file.pas>}"

# Tool paths (sibling repos under sw-embed)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
EMBED_DIR="$(cd "$REPO_DIR/.." && pwd)"

P24P_S="$EMBED_DIR/sw-cor24-pascal/compiler/p24p.s"
PL24R="$EMBED_DIR/sw-cor24-pcode/target/release/pl24r"
PA24R="$EMBED_DIR/sw-cor24-pcode/target/release/pa24r"
PV24T="$EMBED_DIR/sw-cor24-pcode/target/release/pv24t"
RUNTIME="$EMBED_DIR/sw-cor24-pascal/runtime/runtime.spc"

NAME=$(basename "$PAS" .pas)
TMP="/tmp/basic_tc_$$"
mkdir -p "$TMP"
trap "rm -rf $TMP" EXIT

echo "=== Compiling $NAME.pas ==="

# Step 1: Compile Pascal to .spc
SPC_OUTPUT=$(printf '%s\x04' "$(cat "$PAS")" | \
  cor24-run --run "$P24P_S" --terminal --speed 0 -n 200000000 2>&1)

if ! echo "$SPC_OUTPUT" | grep -q "; OK"; then
  echo "Compilation failed:" >&2
  echo "$SPC_OUTPUT" | grep "error" >&2
  exit 1
fi

echo "$SPC_OUTPUT" | sed -n '/^\.module/,/^\.endmodule/p' > "$TMP/$NAME.spc"
echo "  .spc: $(wc -l < "$TMP/$NAME.spc") lines"

# Step 2: Link with runtime
"$PL24R" "$RUNTIME" "$TMP/$NAME.spc" -o "$TMP/${NAME}_linked.spc" 2>&1 | grep -v "^warning:" || true
echo "  Linked OK"

# Step 3: Assemble to .p24
"$PA24R" "$TMP/${NAME}_linked.spc" -o "$TMP/$NAME.p24" 2>&1
echo "  Assembled OK"

# Step 4: Run on pv24t (trace interpreter)
echo "=== Running ==="
"$PV24T" "$TMP/$NAME.p24" 2>&1
