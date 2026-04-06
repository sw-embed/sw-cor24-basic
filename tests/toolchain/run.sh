#!/bin/bash
# run.sh — Compile and run a Pascal program through the p24p toolchain
# Usage: ./tests/toolchain/run.sh <file.pas>
#
# Pipeline: .pas → p24p → .spc → pl24r → pa24r → .p24 → pv24t
#
# Limitation: p24p reads source via UART. The -u flag has an effective
# ~4KB limit after shell expansion. Keep source files under 4KB.
set -euo pipefail

PAS="${1:?Usage: $0 <file.pas>}"

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

SIZE=$(wc -c < "$PAS")
if [ "$SIZE" -gt 4500 ]; then
  echo "WARNING: $NAME.pas is ${SIZE} bytes (>4KB). May fail due to UART buffer limit." >&2
fi

echo "=== Compiling $NAME.pas ==="

SPC_OUTPUT=$(cor24-run --run "$P24P_S" --stack-kilobytes 8 \
  -u "$(cat "$PAS")"$'\x04' \
  --speed 0 -n 500000000 2>&1 | grep -v '^\[UART')

if ! echo "$SPC_OUTPUT" | grep -q "; OK"; then
  echo "Compilation failed:" >&2
  echo "$SPC_OUTPUT" | grep "error" >&2
  exit 1
fi

echo "$SPC_OUTPUT" | sed 's/^UART output: //' | sed -n '/^\.module/,/^\.endmodule/p' > "$TMP/$NAME.spc"
echo "  .spc: $(wc -l < "$TMP/$NAME.spc") lines"

"$PL24R" "$RUNTIME" "$TMP/$NAME.spc" -o "$TMP/${NAME}_linked.spc" 2>&1 | grep -v "^warning:" || true
echo "  Linked OK"

"$PA24R" "$TMP/${NAME}_linked.spc" -o "$TMP/$NAME.p24" 2>&1
echo "  Assembled OK"

echo "=== Running ==="
"$PV24T" "$TMP/$NAME.p24" 2>&1
