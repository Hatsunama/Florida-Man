#!/usr/bin/env bash
# Narrow structural policies only. Full validation is scripts/validate.py.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python "$ROOT/scripts/check_contracts.py"
