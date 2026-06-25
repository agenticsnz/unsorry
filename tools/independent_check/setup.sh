#!/usr/bin/env bash
# Build the independent-check tools (ADR-096 Phase 3a) and print the env exports
# the swarm needs. Run ONCE on a contributor machine, then `eval "$(...)"` or copy
# the exports into your environment before `UNSORRY_INDEPENDENT_CHECK=1 ./swarm/run.sh`.
#
#   tools/independent_check/setup.sh            # build into ~/.unsorry/independent-check
#   eval "$(tools/independent_check/setup.sh --print-env)"   # re-print exports (no rebuild)
#
# Requires: a Lean toolchain (elan/lake, already present for proving) + Rust (cargo).
# lean4export is pinned to the repo's lean-toolchain tag (ADR-002); nanoda is built
# from its master HEAD (pin a reviewed commit before this becomes load-bearing —
# ADR-096 acceptance gate 2).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PREFIX="${UNSORRY_INDEPENDENT_CHECK_DIR:-$HOME/.unsorry/independent-check}"
L4E_DIR="$PREFIX/lean4export"
NAN_DIR="$PREFIX/nanoda"
L4E_BIN="$L4E_DIR/.lake/build/bin/lean4export"
NAN_BIN="$NAN_DIR/target/release/nanoda_bin"

print_env() {
  printf 'export LEAN4EXPORT_BIN=%q\n' "$L4E_BIN"
  printf 'export NANODA_BIN=%q\n' "$NAN_BIN"
  printf 'export UNSORRY_INDEPENDENT_CHECK=1\n'
}

if [ "${1:-}" = "--print-env" ]; then
  print_env
  exit 0
fi

# `run.sh --independent-check` must be fully self-contained — so if Rust/cargo
# (needed to build nanoda) is missing, install it via rustup non-interactively.
# Idempotent: a prior rustup install just gets re-PATH'd. The PATH export is
# local to this setup process — cargo is only needed to BUILD nanoda; the built
# nanoda_bin runs standalone, so run.sh's environment is unaffected.
ensure_cargo() {
  command -v cargo >/dev/null 2>&1 && return 0
  if [ -x "$HOME/.cargo/bin/cargo" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
    return 0
  fi
  echo "[setup] cargo not found — installing Rust via rustup (non-interactive)…" >&2
  if ! command -v curl >/dev/null 2>&1; then
    echo "[setup] need curl to install Rust automatically — install curl or Rust manually" >&2
    return 1
  fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --profile minimal >&2 || return 1
  export PATH="$HOME/.cargo/bin:$PATH"
  command -v cargo >/dev/null 2>&1
}

# ALL build output goes to stderr — STDOUT must carry ONLY print_env's exports,
# because the run.sh --independent-check flow does `eval "$(setup.sh)"`. A build
# tool writing to stdout (e.g. cargo's `Compiling nanoda_lib (… (path))`) would
# otherwise be eval'd and crash with a syntax error. `{ … } >&2` is a group, not a
# subshell, so ensure_cargo's PATH export persists for the cargo build below.
{
  TAG="$(tr -d '[:space:]' < "$ROOT/lean-toolchain" | sed 's#.*:##')"   # e.g. v4.30.0
  echo "[setup] toolchain tag: $TAG  prefix: $PREFIX"
  mkdir -p "$PREFIX"

  if [ ! -x "$L4E_BIN" ]; then
    echo "[setup] building lean4export@$TAG ..."
    rm -rf "$L4E_DIR"
    git clone --depth 1 --branch "$TAG" https://github.com/leanprover/lean4export.git "$L4E_DIR"
    ( cd "$L4E_DIR" && lake build )
  fi

  if [ ! -x "$NAN_BIN" ]; then
    echo "[setup] building nanoda (nanoda_bin) ..."
    ensure_cargo || { echo "[setup] Rust unavailable — cannot build nanoda"; exit 1; }
    rm -rf "$NAN_DIR"
    git clone --depth 1 https://github.com/ammkrn/nanoda_lib.git "$NAN_DIR"
    ( cd "$NAN_DIR" && cargo build --release --bin nanoda_bin )
  fi

  echo "[setup] done. Add these to your environment:"
} >&2
print_env
