#!/usr/bin/env bash
# Run one fully-gated batch of ZMod residue non-membership goals for a family
# (sum-two-squares | sum-three-squares | sum-two-cubes). Thin wrapper over
# run_batch_family.sh. Push-only: opens no PRs.
#
# Usage: run_batch_residue.sh <family> [limit]
#   run_batch_residue.sh sum-two-squares 8
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAMILY="${1:?usage: run_batch_residue.sh <family> [limit]}"
LIMIT="${2:-8}"

exec env \
  SEEDKIT_GEN="$SCRIPT_DIR/gen_residue.py" \
  SEEDKIT_MK="$SCRIPT_DIR/mkfiles_residue.py" \
  SEEDKIT_GEN_ARGS="--family $FAMILY --limit $LIMIT" \
  SEEDKIT_ARGC=3 \
  SEEDKIT_LABEL="residue=$FAMILY" \
  "$SCRIPT_DIR/run_batch_family.sh"
