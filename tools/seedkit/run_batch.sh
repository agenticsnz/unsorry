#!/usr/bin/env bash
# Run one fully-gated batch of divisibility (gzmod) goals for a moduli list.
# Thin wrapper over run_batch_family.sh (the generic per-family driver).
# Push-only: opens no PRs.
#
# Usage: run_batch.sh "156"          # one or more comma-separated moduli
#
# Env overrides (used by run_batch_wide.sh): SEEDKIT_GEN, SEEDKIT_MK pick the
# generator/writer; everything else (per-module build, gates, push) is handled
# by run_batch_family.sh. Prints its RESULT line verbatim:
#   RESULT mods=<M> candidates=<n> build=<bc> gateb=<gc> pushed=<p>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODS="${1:?usage: run_batch.sh <moduli, e.g. 156 or 156,160>}"

exec env \
  SEEDKIT_GEN="${SEEDKIT_GEN:-$SCRIPT_DIR/gen_gzmod.py}" \
  SEEDKIT_MK="${SEEDKIT_MK:-$SCRIPT_DIR/mkfiles.py}" \
  SEEDKIT_GEN_ARGS="--mods $MODS" \
  SEEDKIT_ARGC=3 \
  SEEDKIT_LABEL="mods=$MODS" \
  "$SCRIPT_DIR/run_batch_family.sh"
