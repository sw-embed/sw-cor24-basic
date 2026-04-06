#!/bin/bash
# build-basic.sh — Compile the BASIC interpreter to build/basic.p24
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EMBED_DIR="$(cd "$REPO_DIR/.." && pwd)"

P24P_BIN="$REPO_DIR/build/p24p.bin"
P24P_S="$EMBED_DIR/sw-cor24-pascal/compiler/p24p.s"
PL24R="$EMBED_DIR/sw-cor24-pcode/target/release/pl24r"
PA24R="$EMBED_DIR/sw-cor24-pcode/target/release/pa24r"
RUNTIME="$EMBED_DIR/sw-cor24-pascal/runtime/runtime.spc"
EMU="$EMBED_DIR/sw-cor24-emulator/target/release/cor24-emu"
if [ ! -x "$EMU" ]; then EMU="cor24-run"; fi

mkdir -p "$REPO_DIR/build"
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

# Cache pre-assembled p24p
if [ ! -f "$P24P_BIN" ] || [ "$P24P_S" -nt "$P24P_BIN" ]; then
  cor24-run --assemble "$P24P_S" "$P24P_BIN" /dev/null 2>&1 | head -1
fi

echo "=== Compiling basic.pas ==="

SPC_OUTPUT=$("$EMU" --load-binary "$P24P_BIN@0" --entry 0 --stack-kilobytes 8 \
  -u "$(cat "$REPO_DIR/src/basic.pas")"$'\x04' \
  --speed 0 -n 2000000000 2>&1 | grep -v '^\[UART')

if ! echo "$SPC_OUTPUT" | grep -q "; OK"; then
  echo "Compilation failed:" >&2
  echo "$SPC_OUTPUT" | grep "error" >&2
  exit 1
fi

echo "$SPC_OUTPUT" | sed 's/^UART output: //' | \
  sed -n '/^\.module/,/^\.endmodule/p' > "$TMP/basic.spc"
echo "  .spc: $(wc -l < "$TMP/basic.spc") lines"

"$PL24R" "$TMP/basic.spc" "$RUNTIME" -o "$TMP/linked.spc" 2>/dev/null
echo "  Linked"

# Patch read_line: replace readln(c) with single-char GETC
# p24p emits readln(c) as: call _p24p_read_int + call _p24p_read_ln
# We need: sys 2 (GETC, one char). Remove the read_ln call too.
sed -i '' '/_user_read_line/,/\.end/{
  s/call _p24p_read_int/sys 2/g
  /call _p24p_read_ln/d
}' "$TMP/linked.spc"
echo "  Patched read_line"

"$PA24R" "$TMP/linked.spc" -o "$REPO_DIR/build/basic.p24" 2>&1
echo "=== Built: build/basic.p24 ==="
