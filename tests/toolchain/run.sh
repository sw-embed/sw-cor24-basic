#!/bin/bash
# run.sh — Compile and run a Pascal program through the p24p toolchain
# Usage: ./tests/toolchain/run.sh <file.pas>
#
# Pipeline: .pas → p24p → .spc → pl24r → pa24r → .p24 → pv24t
#
# Uses pre-assembled p24p.bin (cached) + cor24-emu -u for source input.
# This supports source files up to ~8KB (vs ~3.5KB with --run + -u).
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
EMU="$EMBED_DIR/sw-cor24-emulator/target/release/cor24-emu"
if [ ! -x "$EMU" ]; then EMU="cor24-run"; fi

# Cache pre-assembled p24p binary
P24P_BIN="$REPO_DIR/build/p24p.bin"
if [ ! -f "$P24P_BIN" ] || [ "$P24P_S" -nt "$P24P_BIN" ]; then
  mkdir -p "$REPO_DIR/build"
  cor24-run --assemble "$P24P_S" "$P24P_BIN" /dev/null 2>&1 | head -1
fi

NAME=$(basename "$PAS" .pas)
TMP="/tmp/basic_tc_$$"
mkdir -p "$TMP"
trap "rm -rf $TMP" EXIT

echo "=== Compiling $NAME.pas ==="

# Step 1: Compile Pascal to .spc using pre-assembled p24p binary
SPC_OUTPUT=$("$EMU" --load-binary "$P24P_BIN@0" --entry 0 --stack-kilobytes 8 \
  -u "$(cat "$PAS")"$'\x04' \
  --speed 0 -n 2000000000 2>&1 | grep -v '^\[UART')

if ! echo "$SPC_OUTPUT" | grep -q "; OK"; then
  echo "Compilation failed:" >&2
  echo "$SPC_OUTPUT" | grep "error" >&2
  exit 1
fi

echo "$SPC_OUTPUT" | sed 's/^UART output: //' | sed -n '/^\.module/,/^\.endmodule/p' > "$TMP/$NAME.spc"
echo "  .spc: $(wc -l < "$TMP/$NAME.spc") lines"

# Step 2: Link with runtime
"$PL24R" "$RUNTIME" "$TMP/$NAME.spc" -o "$TMP/${NAME}_linked.spc" 2>&1 | grep -v "^warning:" || true
echo "  Linked OK"

# Step 3: Assemble to .p24
"$PA24R" "$TMP/${NAME}_linked.spc" -o "$TMP/$NAME.p24" 2>&1
echo "  Assembled OK"

# Step 4: Run on pv24t
echo "=== Running ==="
"$PV24T" "$TMP/$NAME.p24" 2>&1
