#!/usr/bin/env bash
# Drive run_batch.sh over a pool of moduli until TARGET productive batches (those
# that actually pushed at least one goal) complete, or the pool is exhausted.
# Moduli that yield no valid candidates are skipped and do not count.
#
# Usage: run_pool.sh [TARGET] [MODULUS ...]
#   run_pool.sh 25                  # default narrow pool, target 25 batches
#   run_pool.sh 5 156 160 168       # custom pool
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="${1:-25}"
shift || true
POOL=("$@")
if [ "${#POOL[@]}" -eq 0 ]; then
  POOL=(156 160 168 180 208 210 234 252 260 280 312 336 360)
fi

done=0
pushed=0
for M in "${POOL[@]}"; do
  [ "$done" -ge "$TARGET" ] && break
  out="$("$SCRIPT_DIR/run_batch.sh" "$M" || true)"
  echo "$out"
  p="$(printf '%s\n' "$out" | sed -n 's/.*pushed=\([0-9]\{1,\}\).*/\1/p')"
  p="${p:-0}"
  if [ "$p" -gt 0 ]; then
    done=$((done + 1))
    pushed=$((pushed + p))
  fi
done
echo "POOL COMPLETE batches=$done pushed=$pushed"
