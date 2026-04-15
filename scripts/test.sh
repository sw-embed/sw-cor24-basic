#!/usr/bin/env bash
# Run the reg-rs regression test suite for sw-cor24-basic.
set -euo pipefail
reg-rs run -p basic_ --parallel "$@"
