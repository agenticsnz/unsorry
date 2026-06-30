#!/usr/bin/env bash
# Generate, validate, and (only if every gate is green) push one batch of goals
# for any seedkit family. Push-only: opens no PRs. This is the generic driver
# behind run_batch.sh and the per-family wrappers (run_batch_residue.sh, …).
#
# A family is fully described by environment:
#   SEEDKIT_GEN       generator script (emits one '<args…>|gid|name|Mod|sha' line)
#   SEEDKIT_MK        writer script (positional args = the generator's leading
#                     SEEDKIT_ARGC fields; prints the canonical 'gid|name|Mod|sha')
#   SEEDKIT_GEN_ARGS  args passed verbatim to the generator (e.g. "--family … --limit 8")
#   SEEDKIT_ARGC      number of leading '|'-fields of each generator line that are
#                     the writer's positional args (gzmod=3, residue=3, …)
#   SEEDKIT_LABEL     RESULT-line token identifying the batch (e.g. "mods=156")
#   SEEDKIT_BRANCH    working branch (default current branch)
#   SEEDKIT_BUILD_TIMEOUT  seconds for the lake build (default 540)
#   SEEDKIT_CLEAN_BUILD    1 (default) ⇒ `rm -rf .lake/build` after each batch
#                          so the per-module `.c`/`.olean` output cannot pile up
#                          and exhaust the disk over a long pool run (the mathlib
#                          binary cache lives in .lake/packages and is untouched);
#                          set 0 to keep build artifacts between batches.
#
# Pipeline per batch:
#   gen -> writer (per goal) -> Gate A statement-binding generate
#       -> lake build (ONLY the new modules + their bindings, --wfail)
#       -> Gate B (record validation) -> split_push (one branch per goal)
#
# Why per-module and not `lake build UnsorryLibrary`: a fresh runner has no
# library oleans, so a whole-library build recompiles ~1k modules and times out.
# The new modules import only Mathlib (binary-cached) and their own statement,
# so building `Unsorry.<Mod> Unsorry.<Mod>Binding` is seconds. CI's Gate A still
# builds the whole library on each queued/prove/* branch — this is the local
# pre-push gate, identical in strictness (--wfail) on the changed surface.
#
# Prints: RESULT <label> candidates=<n> build=<bc> gateb=<gc> pushed=<p>
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

GEN="${SEEDKIT_GEN:?SEEDKIT_GEN (generator script) is required}"
MK="${SEEDKIT_MK:?SEEDKIT_MK (writer script) is required}"
GEN_ARGS="${SEEDKIT_GEN_ARGS:-}"
ARGC="${SEEDKIT_ARGC:-3}"
LABEL="${SEEDKIT_LABEL:-batch}"
WORK_BRANCH="${SEEDKIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
BUILD_TIMEOUT="${SEEDKIT_BUILD_TIMEOUT:-540}"
CLEAN_BUILD="${SEEDKIT_CLEAN_BUILD:-1}"

git checkout -q "$WORK_BRANCH"
git reset --hard origin/main --quiet
git clean -fdq backlog goals library 2>/dev/null || true

batch="$(mktemp)"; made="$(mktemp)"
# Bound disk use: drop the per-module build output after the batch (the mathlib
# cache in .lake/packages is untouched, so the next batch just recompiles its own
# few modules). Runs on every exit path — success, gate fail, or no candidates.
trap 'rm -f "$batch" "$made"; [ "$CLEAN_BUILD" = 1 ] && rm -rf "$REPO_ROOT/.lake/build" 2>/dev/null' EXIT

# shellcheck disable=SC2086  # GEN_ARGS is an intentional word-split arg string
python3 "$GEN" $GEN_ARGS > "$batch"
n="$(wc -l < "$batch" | tr -d ' ')"
if [ "$n" -eq 0 ]; then
  echo "RESULT $LABEL candidates=0 build=- gateb=- pushed=0"
  exit 0
fi

while IFS= read -r line; do
  [ -n "$line" ] || continue
  IFS='|' read -ra fields <<< "$line"
  python3 "$MK" "${fields[@]:0:$ARGC}" >> "$made"
done < "$batch"

# Build ONLY the new modules + their generated bindings (see header).
python3 -m tools.gate_a.check_statement_binding generate . >/dev/null 2>&1
targets=()
while IFS='|' read -r _gid _name mod _sha; do
  [ -n "$mod" ] || continue
  targets+=("Unsorry.$mod" "Unsorry.${mod}Binding")
done < "$made"

if timeout "$BUILD_TIMEOUT" lake build "${targets[@]}" --wfail >/dev/null 2>&1; then bc=0; else bc=$?; fi
if python3 -m tools.gate_b validate . >/dev/null 2>&1; then gc=0; else gc=$?; fi

if [ "$bc" -ne 0 ] || [ "$gc" -ne 0 ]; then
  echo "RESULT $LABEL candidates=$n build=$bc gateb=$gc pushed=0 (GATE FAIL)"
  exit 1
fi

SEEDKIT_BRANCH="$WORK_BRANCH" "$SCRIPT_DIR/split_push.sh" "$made" >/dev/null
echo "RESULT $LABEL candidates=$n build=$bc gateb=$gc pushed=$n"
