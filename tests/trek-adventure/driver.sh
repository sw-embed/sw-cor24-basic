#!/bin/bash
# driver.sh — Feed examples/trek-adventure.bas plus a scripted input file
# through the BASIC interpreter. Used by reg-rs tests.
#
# Usage: driver.sh <case-name>
#   where cases/<case-name>.in holds one INPUT line per line.
set -euo pipefail
case="${1:?Usage: $0 <case-name>}"
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
pv24t="$repo/../sw-cor24-pcode/target/release/pv24t"
p24="$repo/build/basic.p24"
bas="$repo/examples/trek-adventure.bas"
in_file="$here/cases/${case}.in"

for f in "$pv24t" "$p24" "$bas" "$in_file"; do
  [ -e "$f" ] || { echo "missing: $f" >&2; exit 2; }
done

{ cat "$bas"; cat "$in_file"; } | "$pv24t" "$p24" -n 0 2>&1
