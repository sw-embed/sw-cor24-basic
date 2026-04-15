#!/bin/bash
# tests/trek-adventure/run.sh — Regression tests for examples/trek-adventure.bas
#
# Each test case is a pair of files under cases/:
#   <name>.in       — lines fed to INPUT prompts in order
#   <name>.expect   — grep-style fixed strings that MUST appear in output
#   <name>.reject   — (optional) strings that must NOT appear
#
# Exit status: 0 if all cases pass, 1 otherwise.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PV24T="$REPO_DIR/../sw-cor24-pcode/target/release/pv24t"
P24="$REPO_DIR/build/basic.p24"
BAS="$REPO_DIR/examples/trek-adventure.bas"

if [ ! -x "$PV24T" ]; then
  echo "pv24t not found at $PV24T" >&2; exit 2
fi
if [ ! -f "$P24" ]; then
  echo "$P24 not found — run ./scripts/build-basic.sh first" >&2; exit 2
fi
if [ ! -f "$BAS" ]; then
  echo "$BAS not found" >&2; exit 2
fi

PROG=$(cat "$BAS")

pass=0
fail=0
failed_cases=""

for in_file in "$SCRIPT_DIR"/cases/*.in; do
  [ -f "$in_file" ] || continue
  name=$(basename "$in_file" .in)
  expect_file="$SCRIPT_DIR/cases/$name.expect"
  reject_file="$SCRIPT_DIR/cases/$name.reject"
  inputs=$(cat "$in_file")
  # Trailing newline is required: read_line discards the last partial line
  # buffered before EOF, so every input must be terminated by a newline.
  out=$("$PV24T" "$P24" -n 0 -i "$PROG"$'\n'"$inputs"$'\n' </dev/null 2>&1)
  ok=1
  if [ -f "$expect_file" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      if ! printf '%s\n' "$out" | grep -qF -- "$line"; then
        echo "  [$name] MISSING: $line"
        ok=0
      fi
    done < "$expect_file"
  fi
  if [ -f "$reject_file" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      if printf '%s\n' "$out" | grep -qF -- "$line"; then
        echo "  [$name] UNWANTED: $line"
        ok=0
      fi
    done < "$reject_file"
  fi
  if [ "$ok" = "1" ]; then
    echo "PASS $name"
    pass=$((pass+1))
  else
    echo "FAIL $name"
    fail=$((fail+1))
    failed_cases="$failed_cases $name"
  fi
done

echo "---"
echo "$pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
  echo "failed:$failed_cases"
  exit 1
fi
exit 0
