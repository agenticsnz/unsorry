#!/usr/bin/env bash
# Run one fully-gated batch using the widened generator/writer (exponent gap up
# to 18, exponents up to 30). Thin wrapper over run_batch.sh.
#
# Usage: run_batch_wide.sh "152"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec env \
  SEEDKIT_GEN="$SCRIPT_DIR/gen_gzmod_wide.py" \
  SEEDKIT_MK="$SCRIPT_DIR/mkfiles_wide.py" \
  "$SCRIPT_DIR/run_batch.sh" "$@"
