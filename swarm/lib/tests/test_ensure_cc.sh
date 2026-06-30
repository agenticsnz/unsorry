#!/usr/bin/env bash
# Hermetic acceptance tests for swarm/lib/ensure_cc.sh. No system package manager
# is touched: the install step is stubbed by redefining `_ensure_cc_install`.
# Run from anywhere.
#
# Each case runs in a `( … )` subshell so its PATH overrides stay local — that
# isolation is the point (the host's real `cc` must never leak into the
# "cc absent" cases), and the install stubs are invoked indirectly by ensure_cc,
# so the corresponding shellcheck notes are expected, not bugs.
# shellcheck disable=SC1090,SC2030,SC2031,SC2317,SC2015
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$HERE/../ensure_cc.sh"

SYSPATH="$PATH"   # real coreutils, for stubs/asserts that need mkdir/chmod/grep

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }

# Each test runs in a subshell with a minimal PATH (a dir we control) so the
# host's real `cc` never leaks in. `command`, `case`, `echo` are bash builtins,
# so an empty-ish PATH is enough to run ensure_cc itself with the install stubbed.

# 1. cc already on PATH → returns 0, install never attempted.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; bin="$sand/bin"; mkdir -p "$bin"
  printf '#!/bin/sh\n' > "$bin/cc"; chmod +x "$bin/cc"
  export PATH="$bin"
  _ensure_cc_install() { touch "$sand/INSTALL_CALLED"; return 0; }
  ensure_cc; rc=$?
  [ "$rc" = 0 ] || { echo "  rc=$rc"; exit 1; }
  [ -e "$sand/INSTALL_CALLED" ] && { echo "  install ran despite cc present"; exit 1; }
  exit 0
) && ok "cc present → ok, no install" || bad "cc present → ok, no install"

# 2. cc absent, install succeeds (stub drops a cc shim onto PATH) → returns 0
#    and cc resolves afterward.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; bin="$sand/bin"; mkdir -p "$bin"
  export PATH="$bin"               # no cc yet
  _ensure_cc_install() {
    printf '#!/bin/sh\n' > "$bin/cc"
    PATH="$SYSPATH" chmod +x "$bin/cc"
    return 0
  }
  ensure_cc; rc=$?
  [ "$rc" = 0 ] || { echo "  rc=$rc"; exit 1; }
  command -v cc >/dev/null 2>&1 || { echo "  cc still not on PATH"; exit 1; }
  exit 0
) && ok "cc absent, install succeeds → ok" || bad "cc absent, install succeeds → ok"

# 3. cc absent, install cannot run (stub returns 1 — macOS / no sudo / unknown
#    pkg mgr) → returns 1 AND prints an actionable hint to stderr.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; bin="$sand/bin"; mkdir -p "$bin"
  export PATH="$bin"
  _ensure_cc_install() { return 1; }
  ensure_cc 2>"$sand/err"; rc=$?
  [ "$rc" = 1 ] || { echo "  rc=$rc (want 1)"; exit 1; }
  PATH="$SYSPATH" grep -q "install" "$sand/err" || { echo "  no install hint on stderr"; exit 1; }
  exit 0
) && ok "no install possible → returns 1 + hint" || bad "no install possible → returns 1 + hint"

# 4. install "succeeds" but cc is still absent afterward → returns 1.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; bin="$sand/bin"; mkdir -p "$bin"
  export PATH="$bin"
  _ensure_cc_install() { return 0; }   # claims success but installs nothing
  ensure_cc; rc=$?
  [ "$rc" = 1 ] || { echo "  rc=$rc (want 1)"; exit 1; }
  exit 0
) && ok "install no-op → returns 1" || bad "install no-op → returns 1"

echo "----"
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
