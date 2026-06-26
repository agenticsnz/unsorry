#!/usr/bin/env bash
# Run one fully-gated batch of shiftsq goals. Thin wrapper over run_batch_family.sh.
# Push-only: opens no PRs.
#
# Usage: run_batch_shiftsq.sh [coeffs-list]
#   run_batch_shiftsq.sh              # default sweep
#   run_batch_shiftsq.sh 31,32,33     # explicit values
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="${1:-}"
GEN_ARGS=""
[ -n "$LIST" ] && GEN_ARGS="--coeffs $LIST"

exec env \
  SEEDKIT_GEN="$SCRIPT_DIR/gen_shiftsq.py" \
  SEEDKIT_MK="$SCRIPT_DIR/mkfiles_shiftsq.py" \
  SEEDKIT_GEN_ARGS="$GEN_ARGS" \
  SEEDKIT_ARGC=1 \
  SEEDKIT_LABEL="shiftsq" \
  "$SCRIPT_DIR/run_batch_family.sh"
