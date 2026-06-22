#!/usr/bin/env bash
# Generate, validate, and (only if every gate is green) push one batch of goals
# for a moduli list. Push-only: opens no PRs.
#
# Usage: run_batch.sh "156"          # one or more comma-separated moduli
#
# Pipeline per batch:
#   gen -> mkfiles -> Gate A (statement-binding + lake build --wfail)
#       -> Gate B (record validation) -> split_push (one branch per goal)
#
# Prints: RESULT mods=<M> candidates=<n> build=<bc> gateb=<gc> pushed=<p>
#
# Env: SEEDKIT_GEN, SEEDKIT_MK       (generator / writer scripts to use)
#      SEEDKIT_BRANCH                (working branch, default current branch)
#      SEEDKIT_BUILD_TIMEOUT         (seconds for the lake build, default 540)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

MODS="${1:?usage: run_batch.sh <moduli, e.g. 156 or 156,160>}"
GEN="${SEEDKIT_GEN:-$SCRIPT_DIR/gen_gzmod.py}"
MK="${SEEDKIT_MK:-$SCRIPT_DIR/mkfiles.py}"
WORK_BRANCH="${SEEDKIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
BUILD_TIMEOUT="${SEEDKIT_BUILD_TIMEOUT:-540}"

git checkout -q "$WORK_BRANCH"
git reset --hard origin/main --quiet
git clean -fdq backlog goals library 2>/dev/null || true

batch="$(mktemp)"; made="$(mktemp)"
trap 'rm -f "$batch" "$made"' EXIT

python3 "$GEN" --mods "$MODS" > "$batch"
n="$(wc -l < "$batch" | tr -d ' ')"
if [ "$n" -eq 0 ]; then
  echo "RESULT mods=$MODS candidates=0 build=- gateb=- pushed=0"
  exit 0
fi

while IFS='|' read -r M a b _gid _name _mod _sha; do
  python3 "$MK" "$M" "$a" "$b" >> "$made"
done < "$batch"

python3 -m tools.gate_a.check_statement_binding generate . >/dev/null 2>&1
if timeout "$BUILD_TIMEOUT" lake build UnsorryLibrary --wfail >/dev/null 2>&1; then bc=0; else bc=$?; fi
if python3 -m tools.gate_b validate . >/dev/null 2>&1; then gc=0; else gc=$?; fi

if [ "$bc" -ne 0 ] || [ "$gc" -ne 0 ]; then
  echo "RESULT mods=$MODS candidates=$n build=$bc gateb=$gc pushed=0 (GATE FAIL)"
  exit 1
fi

SEEDKIT_BRANCH="$WORK_BRANCH" "$SCRIPT_DIR/split_push.sh" "$made" >/dev/null
echo "RESULT mods=$MODS candidates=$n build=$bc gateb=$gc pushed=$n"
