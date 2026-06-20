#!/usr/bin/env bash
# Top up with the widened generator until TARGET productive batches complete, or
# the pool is exhausted. Same contract as run_pool.sh but uses run_batch_wide.sh.
#
# Usage: topup.sh [TARGET] [MODULUS ...]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="${1:-12}"
shift || true
POOL=("$@")
if [ "${#POOL[@]}" -eq 0 ]; then
  POOL=(152 170 171 182 189 195 216 228 255 266 273 315)
fi

done=0
pushed=0
for M in "${POOL[@]}"; do
  [ "$done" -ge "$TARGET" ] && break
  out="$("$SCRIPT_DIR/run_batch_wide.sh" "$M" || true)"
  echo "$out"
  p="$(printf '%s\n' "$out" | sed -n 's/.*pushed=\([0-9]\{1,\}\).*/\1/p')"
  p="${p:-0}"
  if [ "$p" -gt 0 ]; then
    done=$((done + 1))
    pushed=$((pushed + p))
  fi
done
echo "TOPUP COMPLETE batches=$done pushed=$pushed"
