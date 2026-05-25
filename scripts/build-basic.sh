#!/bin/bash
# build-basic.sh — Compile the BASIC interpreter to build/basic.p24
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBDIR="${LIBDIR:-/disk1/github/softwarewrighter/devgroup/work/lib}"

P24P_BIN="$REPO_DIR/build/p24p.bin"
P24P_S="$LIBDIR/pascal/p24p.s"
RUNTIME="$LIBDIR/pascal/runtime.spc"
BASIC_SYS_SPI="$REPO_DIR/src/basic_sys.spi"
BASIC_SYS="$REPO_DIR/src/basic_sys.spc"

mkdir -p "$REPO_DIR/build"
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

# Cache pre-assembled p24p
if [ ! -f "$P24P_BIN" ] || [ "$P24P_S" -nt "$P24P_BIN" ]; then
  cor24-asm "$P24P_S" --bin "$P24P_BIN" 2>&1 | head -1
fi

echo "=== Compiling basic.pas ==="

SPC_OUTPUT=$(cor24-emu --load-binary "$P24P_BIN@0" --entry 0 --stack-kilobytes 8 \
  -u "$(cat "$BASIC_SYS_SPI"; cat "$REPO_DIR/src/basic.pas")"$'\x04' \
  --speed 0 -n 2000000000 2>&1 | grep -v '^\[UART')

# Use a native bash glob match instead of `echo $SPC_OUTPUT | grep -q`:
# the piped form races on SIGPIPE (grep -q exits on first match, echo is
# killed mid-write, pipefail then trips and we wrongly print "Compilation
# failed"). The race fires more often as the .spc output grows.
if [[ "$SPC_OUTPUT" != *"; OK"* ]]; then
  echo "Compilation failed:" >&2
  echo "$SPC_OUTPUT" | grep "error" >&2
  exit 1
fi

echo "$SPC_OUTPUT" | sed 's/^UART output: //' | \
  sed -n '/^\.module/,/^\.endmodule/p' > "$TMP/basic.spc"
echo "  .spc: $(wc -l < "$TMP/basic.spc") lines"

pl24r "$TMP/basic.spc" "$BASIC_SYS" "$RUNTIME" -o "$TMP/linked.spc" 2>/dev/null
echo "  Linked"

# Patch rc and read_line: replace readln(c) with single-char GETC
# p24p emits readln(c) as: call _p24p_read_int + call _p24p_read_ln
# We need: sys 2 (GETC, one char). Remove the read_ln call too.
sed -i '/_user_rc\|_user_read_line/,/\.end/{
  s/call _p24p_read_int/sys 2/g
  /call _p24p_read_ln/d
}' "$TMP/linked.spc"
echo "  Patched rc/read_line"

pa24r "$TMP/linked.spc" -o "$REPO_DIR/build/basic.p24" 2>&1
echo "=== Built: build/basic.p24 ==="
