#!/usr/bin/env bash
# Run one fully-gated batch of geometric-series / Faulhaber closed-form goals for
# a family (geometric | faulhaber-square | faulhaber-cube | faulhaber-quartic |
# faulhaber-quintic). Thin wrapper over run_batch_family.sh. Push-only: no PRs.
#
# Usage: run_batch_faulhaber.sh <family> [values]
#   run_batch_faulhaber.sh faulhaber-cube
#   run_batch_faulhaber.sh geometric 2,3,5,7
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAMILY="${1:?usage: run_batch_faulhaber.sh <family> [values]}"
VALUES="${2:-}"

GEN_ARGS="--family $FAMILY"
[ -n "$VALUES" ] && GEN_ARGS="$GEN_ARGS --values $VALUES"

exec env \
  SEEDKIT_GEN="$SCRIPT_DIR/gen_faulhaber.py" \
  SEEDKIT_MK="$SCRIPT_DIR/mkfiles_faulhaber.py" \
  SEEDKIT_GEN_ARGS="$GEN_ARGS" \
  SEEDKIT_ARGC=2 \
  SEEDKIT_LABEL="faulhaber=$FAMILY" \
  "$SCRIPT_DIR/run_batch_family.sh"
