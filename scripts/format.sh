#!/bin/bash
# format.sh — Reformat all .pas source files using emacs pascal-mode
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PAS_FILES=()
while IFS= read -r -d '' f; do
  PAS_FILES+=("$f")
done < <(find "$REPO_DIR/src" -name '*.pas' -print0 2>/dev/null)

if [ ${#PAS_FILES[@]} -eq 0 ]; then
  echo "No .pas files found in src/"
  exit 0
fi

for f in "${PAS_FILES[@]}"; do
  echo "Formatting $(basename "$f")"
  emacs --batch "$f" \
    --eval "(progn (pascal-mode) (indent-region (point-min) (point-max)) (save-buffer))" \
    2>&1 | grep -v '^Indenting region'
done

echo "Done — formatted ${#PAS_FILES[@]} file(s)"
