#!/bin/bash
# run.sh — Run a Pascal test program through the p24p toolchain
# Usage: ./tests/toolchain/run.sh <file.pas> [max_instructions]
#
# Pipeline: .pas → p24p → .spc → pl24r → pa24r → .p24 → pvm.s
set -euo pipefail

PAS="${1:?Usage: $0 <file.pas> [max_instructions]}"
MAX_INSTRS="${2:-200000000}"

# Tool paths (sibling repos under sw-embed)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
EMBED_DIR="$(cd "$REPO_DIR/.." && pwd)"

P24P_S="$EMBED_DIR/sw-cor24-pascal/compiler/p24p.s"
PL24R="$EMBED_DIR/sw-cor24-pcode/target/release/pl24r"
PA24R="$EMBED_DIR/sw-cor24-pcode/target/release/pa24r"
RUNTIME="$EMBED_DIR/sw-cor24-pascal/runtime/runtime.spc"
PVM="$EMBED_DIR/sw-cor24-pcode/vm/pvm.s"
RELOCATE="$EMBED_DIR/sw-cor24-pascal/scripts/relocate_p24.py"

NAME=$(basename "$PAS" .pas)
TMP="/tmp/basic_tc_$$"
mkdir -p "$TMP"
trap "rm -rf $TMP" EXIT

echo "=== Compiling $NAME.pas ==="

# Step 1: Compile Pascal to .spc (p24p needs ~20M instructions for larger programs)
SPC_OUTPUT=$(printf '%s\x04' "$(cat "$PAS")" | \
  cor24-run --run "$P24P_S" --terminal --speed 0 -n 50000000 2>&1)

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

# Step 4: Relocate for load address 0x010000
python3 "$RELOCATE" "$TMP/$NAME.p24" 0x010000 >/dev/null
echo "  Relocated OK"

# Step 5: Find code_ptr address in pvm.s
CODE_PTR_ADDR=$(cor24-run --run "$PVM" -e code_ptr --speed 0 -n 0 2>&1 | \
  grep "Entry point:" | sed 's/.*@ //')
printf '\x00\x00\x01' > "$TMP/code_ptr.bin"
echo "  code_ptr @ $CODE_PTR_ADDR"

# Step 6: Run on PVM
echo "=== Running ==="
cor24-run --run "$PVM" \
  --load-binary "$TMP/$NAME.bin@0x010000" \
  --load-binary "$TMP/code_ptr.bin@${CODE_PTR_ADDR}" \
  --terminal --speed 0 -n "$MAX_INSTRS" 2>&1 | \
  grep -v '^\[' | grep -v '^Assembled' | grep -v '^Running' | \
  grep -v '^Executed' | grep -v '^Loaded' | grep -v '^PVM OK' | \
  grep -v '^$'
