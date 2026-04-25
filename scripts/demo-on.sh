#!/bin/bash
# demo-on.sh — Run the on-demo.bas demo through the BASIC interpreter.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/run-basic.sh" "$SCRIPT_DIR/../examples/on-demo.bas"
