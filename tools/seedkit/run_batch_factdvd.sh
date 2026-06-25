#!/usr/bin/env bash
# Run one fully-gated batch of factdvd goals. Thin wrapper over run_batch_family.sh.
# Push-only: opens no PRs.
#
# Usage: run_batch_factdvd.sh [ks-list]
#   run_batch_factdvd.sh              # default sweep
#   run_batch_factdvd.sh 31,32,33     # explicit values
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="${1:-}"
GEN_ARGS=""
[ -n "$LIST" ] && GEN_ARGS="--ks $LIST"

exec env \
  SEEDKIT_GEN="$SCRIPT_DIR/gen_factdvd.py" \
  SEEDKIT_MK="$SCRIPT_DIR/mkfiles_factdvd.py" \
  SEEDKIT_GEN_ARGS="$GEN_ARGS" \
  SEEDKIT_ARGC=1 \
  SEEDKIT_LABEL="factdvd" \
  "$SCRIPT_DIR/run_batch_family.sh"
