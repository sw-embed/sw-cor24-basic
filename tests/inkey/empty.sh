#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PV24T="$REPO_DIR/../sw-cor24-pcode/target/release/pv24t"
P24="$REPO_DIR/build/basic.p24"

INPUT=$'10 PRINT INKEY\nRUN\n'
"$PV24T" "$P24" -i "$INPUT" -n "${BASIC_MAX_INSN:-1000000}" 2>&1 | \
  sed -E 's/^>+//' | grep -v '^$'
