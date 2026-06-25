#!/usr/bin/env bash
# swarm/lib/ensure_lake.sh — make `lake` available, installing the Lean toolchain
# manager (elan) non-interactively if it is missing (ADR-100, SPEC-100-A).
#
# Source this file and call `ensure_lake` before any `lake` invocation in a
# client-side swarm script. It is the single authoritative bootstrap for the Lean
# build tool (DRY, protocol §12): every swarm entry point that builds locally
# routes its `lake` dependency through here instead of failing hard when `lake`
# is absent.
#
# Behaviour (idempotent, safe to call repeatedly):
#   1. Put the standard toolchain locations on PATH (non-login shells often see an
#      obsolete NVM Node first and omit elan), then probe for `lake`.
#   2. If `lake` resolves, return 0 — nothing to do.
#   3. Otherwise install elan non-interactively via its official installer. elan
#      shims `lake`/`lean` into ~/.elan/bin and selects the toolchain per-directory
#      from `lean-toolchain` on first use (ADR-002 — never builds mathlib; mathlib
#      arrives as a binary cache). `--default-toolchain none` means the install
#      itself pulls no toolchain; the pinned one lands when `lake` first runs in
#      the repo.
#   4. Re-PATH and re-probe; return 0 iff `lake` is now resolvable.
#
# Mirrors tools/independent_check/setup.sh's `ensure_cargo` (the same
# install-the-toolchain-manager-if-missing pattern for Rust). All progress output
# goes to stderr so a caller that captures stdout (e.g. `eval "$(setup.sh)"`) is
# unaffected.
#
# The installer URL is overridable via ELAN_INIT_URL for mirrors/air-gapped
# installs; the network install is isolated in `_ensure_lake_install_elan` so the
# self-tests can stub it hermetically.

# The official elan installer (leanprover/elan). Overridable for a private mirror.
: "${ELAN_INIT_URL:=https://elan.lean-lang.org/elan-init.sh}"

# Prepend ~/.elan/bin (and the common Homebrew prefixes) to PATH if absent, so a
# freshly-installed or already-present elan shim is found. Pure PATH hygiene —
# no I/O — so it is always safe to run.
_ensure_lake_path() {
  case ":$PATH:" in
    *":$HOME/.elan/bin:"*) ;;
    *) PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.elan/bin:$PATH"; export PATH ;;
  esac
}

# The one side-effecting step: download and run the elan installer. Isolated so
# the self-tests override it without touching the network. `-y` accepts defaults,
# `--no-modify-path` leaves the user's shell profile untouched (we manage PATH
# ourselves), `--default-toolchain none` defers the toolchain to lean-toolchain.
_ensure_lake_install_elan() {
  curl --proto '=https' --tlsv1.2 -sSf "$ELAN_INIT_URL" \
    | sh -s -- -y --no-modify-path --default-toolchain none
}

# Ensure `lake` is on PATH, installing elan if necessary. Returns 0 on success,
# 1 if `lake` could not be made available (caller decides whether that is fatal).
ensure_lake() {
  _ensure_lake_path
  command -v lake >/dev/null 2>&1 && return 0

  echo "[ensure_lake] lake not found — installing the Lean toolchain manager (elan)…" >&2
  if ! command -v curl >/dev/null 2>&1; then
    echo "[ensure_lake] need curl to install elan automatically — install curl or elan manually" >&2
    return 1
  fi
  if ! _ensure_lake_install_elan >&2; then
    echo "[ensure_lake] elan install failed — install the Lean toolchain manually (https://lean-lang.org)" >&2
    return 1
  fi

  _ensure_lake_path
  if command -v lake >/dev/null 2>&1; then
    echo "[ensure_lake] elan installed — lake is now available" >&2
    return 0
  fi
  echo "[ensure_lake] elan install completed but lake is still not on PATH" >&2
  return 1
}
