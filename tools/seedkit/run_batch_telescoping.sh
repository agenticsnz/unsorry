#!/usr/bin/env bash
# Run one fully-gated batch of telescoping power-sum goals for a shape
# (square | cube | quartic | quintic | sextic). Thin wrapper over
# run_batch_family.sh. Push-only: opens no PRs.
#
# Usage: run_batch_telescoping.sh <shape> [coeffs]
#   run_batch_telescoping.sh cube              # default coefficient range
#   run_batch_telescoping.sh cube 1,2,3,4,5    # explicit coefficients
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHAPE="${1:?usage: run_batch_telescoping.sh <shape> [coeffs]}"
COEFFS="${2:-}"

GEN_ARGS="--shape $SHAPE"
[ -n "$COEFFS" ] && GEN_ARGS="$GEN_ARGS --coeffs $COEFFS"

exec env \
  SEEDKIT_GEN="$SCRIPT_DIR/gen_telescoping.py" \
  SEEDKIT_MK="$SCRIPT_DIR/mkfiles_telescoping.py" \
  SEEDKIT_GEN_ARGS="$GEN_ARGS" \
  SEEDKIT_ARGC=2 \
  SEEDKIT_LABEL="telescoping=$SHAPE" \
  "$SCRIPT_DIR/run_batch_family.sh"
