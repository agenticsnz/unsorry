#!/usr/bin/env bash
# Hermetic acceptance tests for swarm/lib/ensure_lake.sh (SPEC-100-A).
# No network: the elan install step is stubbed by redefining
# `_ensure_lake_install_elan`. Run from anywhere.
#
# Each case runs in a `( … )` subshell so its HOME/PATH overrides stay local —
# that isolation is the point, and the install stubs are invoked indirectly by
# ensure_lake, so the corresponding shellcheck notes are expected, not bugs.
# shellcheck disable=SC1090,SC2030,SC2031,SC2317,SC2015
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$HERE/../ensure_lake.sh"

SYSPATH="$PATH"   # real coreutils, for install stubs that need mkdir/chmod

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }

# Each test runs in a subshell with an isolated HOME and a minimal PATH so the
# host's real lake/elan never leaks in. `command`, `case`, `echo`, `export` are
# bash builtins, so an empty PATH is enough to run ensure_lake itself.

# 1. lake already on PATH → returns 0, install never attempted.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; export HOME="$sand/home"; mkdir -p "$HOME"
  bin="$sand/bin"; mkdir -p "$bin"
  printf '#!/bin/sh\n' > "$bin/lake"; chmod +x "$bin/lake"
  export PATH="$bin"
  _ensure_lake_install_elan() { touch "$sand/INSTALL_CALLED"; return 0; }
  ensure_lake; rc=$?
  [ "$rc" = 0 ] || { echo "  rc=$rc"; exit 1; }
  [ -e "$sand/INSTALL_CALLED" ] && { echo "  install ran despite lake present"; exit 1; }
  exit 0
) && ok "lake present → ok, no install" || bad "lake present → ok, no install"

# 2. lake absent, install succeeds (stub drops a shim into ~/.elan/bin) →
#    returns 0 and lake resolves afterward.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; export HOME="$sand/home"; mkdir -p "$HOME"
  curlbin="$sand/bin"; mkdir -p "$curlbin"
  printf '#!/bin/sh\nexit 0\n' > "$curlbin/curl"; chmod +x "$curlbin/curl"
  export PATH="$curlbin"          # curl present, lake absent
  _ensure_lake_install_elan() {
    PATH="$SYSPATH" mkdir -p "$HOME/.elan/bin"
    printf '#!/bin/sh\n' > "$HOME/.elan/bin/lake"
    PATH="$SYSPATH" chmod +x "$HOME/.elan/bin/lake"
    return 0
  }
  ensure_lake; rc=$?
  [ "$rc" = 0 ] || { echo "  rc=$rc"; exit 1; }
  command -v lake >/dev/null 2>&1 || { echo "  lake still not on PATH"; exit 1; }
  exit 0
) && ok "lake absent, install succeeds → ok" || bad "lake absent, install succeeds → ok"

# 3. lake absent AND curl absent → returns 1, install never attempted.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; export HOME="$sand/home"; mkdir -p "$HOME"
  empty="$sand/bin"; mkdir -p "$empty"   # no curl, no lake
  export PATH="$empty"
  _ensure_lake_install_elan() { touch "$sand/INSTALL_CALLED"; return 0; }
  ensure_lake; rc=$?
  [ "$rc" = 1 ] || { echo "  rc=$rc (want 1)"; exit 1; }
  [ -e "$sand/INSTALL_CALLED" ] && { echo "  install ran with no curl"; exit 1; }
  exit 0
) && ok "no curl → returns 1, no install" || bad "no curl → returns 1, no install"

# 4. lake absent on PATH but present in ~/.elan/bin → PATH prepend finds it,
#    install never attempted.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; export HOME="$sand/home"; mkdir -p "$HOME/.elan/bin"
  printf '#!/bin/sh\n' > "$HOME/.elan/bin/lake"; chmod +x "$HOME/.elan/bin/lake"
  empty="$sand/bin"; mkdir -p "$empty"
  export PATH="$empty"            # lake only reachable via ~/.elan/bin
  _ensure_lake_install_elan() { touch "$sand/INSTALL_CALLED"; return 0; }
  ensure_lake; rc=$?
  [ "$rc" = 0 ] || { echo "  rc=$rc"; exit 1; }
  [ -e "$sand/INSTALL_CALLED" ] && { echo "  install ran despite elan-shim present"; exit 1; }
  exit 0
) && ok "elan shim on ~/.elan/bin → ok, no install" || bad "elan shim → ok, no install"

# 5. install runs but lake still absent afterward → returns 1.
( set +e
  source "$LIB"
  sand="$(mktemp -d)"; export HOME="$sand/home"; mkdir -p "$HOME"
  curlbin="$sand/bin"; mkdir -p "$curlbin"
  printf '#!/bin/sh\nexit 0\n' > "$curlbin/curl"; chmod +x "$curlbin/curl"
  export PATH="$curlbin"
  _ensure_lake_install_elan() { return 0; }   # "succeeds" but installs nothing
  ensure_lake; rc=$?
  [ "$rc" = 1 ] || { echo "  rc=$rc (want 1)"; exit 1; }
  exit 0
) && ok "install no-op → returns 1" || bad "install no-op → returns 1"

echo "----"
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
