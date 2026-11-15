#!/bin/bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
cd "$repo"
unset PYTHONOPTIMIZE
exec python3 "$repo/scripts/verify-phase-07-update.py" "$@"
