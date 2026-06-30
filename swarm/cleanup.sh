#!/usr/bin/env bash
# swarm/cleanup.sh — reclaim the swarm's local disk footprint.
#
# A long-running prover accumulates throwaway state OUTSIDE the repo, and on a
# small box (e.g. a codespace volume) that is what fills the disk — not anything
# tracked in git. The reclaimable categories:
#
#   * per-goal git worktrees under $UNSORRY_WORKDIR — prove-/converge-/pr-/
#     decompose-/demote-/telemetry-<goal>-<agent>, one full checkout each. These
#     are throwaway scratch; the claims-branch worktree is the one keeper.
#   * the nanoda Rust build tree under the independent-check prefix
#     ($UNSORRY_INDEPENDENT_CHECK_DIR/nanoda/target). Only the final
#     target/release/nanoda_bin is needed at runtime; the rest is rebuildable.
#   * pure package caches: the cargo registry cache (pulled in to BUILD nanoda)
#     and the pip cache. Both regenerate on demand.
#   * (--deep only) rebuild-triggering state: the repo's .lake/build output and
#     stale elan toolchains (any toolchain other than the pinned lean-toolchain).
#     Removing these is safe but forces a rebuild / re-download next run.
#
# SAFETY: dry-run by DEFAULT — it prints what each category would reclaim and
# frees nothing. Pass --apply to actually delete. The claims-branch worktree and
# the nanoda/lean4export binaries are never removed. It refuses to remove
# worktrees while a swarm appears to be running (a worktree may be mid-proof)
# unless --force is given.
#
# Exit codes: 0 ok · 2 usage / config error.
set -euo pipefail

WORKDIR="${UNSORRY_WORKDIR:-$HOME/.unsorry/work}"
ICDIR="${UNSORRY_INDEPENDENT_CHECK_DIR:-$HOME/.unsorry/independent-check}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

APPLY=0          # 0 = dry-run (default), 1 = actually delete
DEEP=0           # 1 = also clear rebuild-triggering caches (.lake/build, toolchains)
FORCE=0          # 1 = remove worktrees even if a swarm looks live
RECLAIMED=0      # running total of bytes reported (dry-run) or freed (apply)

log() { printf '%s cleanup: %s\n' "$(date -u +%H:%M:%SZ)" "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: swarm/cleanup.sh [--apply] [--deep] [--force] [--self-test]

Reclaim the swarm's local disk footprint (stale per-goal worktrees, the nanoda
Rust build tree, and package caches). Dry-run by default: prints what would be
freed and deletes nothing. Run from anywhere; paths come from the same env vars
the swarm uses.

  --apply       actually delete (default is a dry-run preview)
  --deep        also clear rebuild-triggering state: the repo's .lake/build and
                stale elan toolchains (forces a rebuild / re-download next run)
  --force       remove worktrees even if a swarm looks live (default: skip them)
  --self-test   run the hermetic unit tests and exit
  -h, --help    this help

Env: UNSORRY_WORKDIR (default ~/.unsorry/work),
     UNSORRY_INDEPENDENT_CHECK_DIR (default ~/.unsorry/independent-check)
EOF
}

# --- pure helpers (hermetic; exercised by --self-test) --------------------

# A worktree basename is throwaway scratch (removable) iff it carries one of the
# per-goal prefixes the agent loop creates. The claims-branch worktree,
# metrics.jsonl, and goal-lock dirs never match, so they are always kept.
removable_worktree() {
  case "$1" in
    prove-*|converge-*|pr-*|decompose-*|demote-*|telemetry-*) return 0 ;;
    *) return 1 ;;
  esac
}

# An installed elan toolchain is stale iff it differs from the pinned keep value.
# An empty keep (unknown pin) means "never stale" — we don't guess.
stale_toolchain() {  # $1 = installed name, $2 = keep (pinned) name
  [ -n "$2" ] || return 1
  [ "$1" = "$2" ] && return 1
  return 0
}

# Size of a path in bytes (0 if missing). du -s sums a directory tree.
bytes_of() {
  [ -e "$1" ] || { printf '0'; return; }
  du -sb "$1" 2>/dev/null | cut -f1 || printf '0'
}

# Human-readable IEC size; falls back to a raw byte count if numfmt is absent.
human() {
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec --suffix=B "$1" 2>/dev/null || printf '%sB' "$1"
  else
    printf '%sB' "$1"
  fi
}

# Report a single path and, under --apply, remove it. Accrues the byte total.
# Usage: reclaim <label> <path>
reclaim() {
  local label="$1" path="$2" b
  [ -e "$path" ] || return 0
  b="$(bytes_of "$path")"
  [ "$b" -gt 0 ] 2>/dev/null || b=0
  RECLAIMED=$((RECLAIMED + b))
  if [ "$APPLY" = 1 ]; then
    rm -rf "$path"
    printf '  freed   %8s  %s\n' "$(human "$b")" "$label"
  else
    printf '  would   %8s  %s\n' "$(human "$b")" "$label"
  fi
}

# --- swarm liveness -------------------------------------------------------

# True if a swarm launcher/agent/supervisor process is running. cleanup.sh
# itself is swarm/cleanup.sh, which the prove|run|agent|supervise pattern below
# deliberately does not match, so we never see ourselves.
swarm_running() {
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f 'swarm/(run|agent|supervise)\.sh' >/dev/null 2>&1
  else
    ps -eo args 2>/dev/null | grep -Eq '[s]warm/(run|agent|supervise)\.sh'
  fi
}

# --- categories -----------------------------------------------------------

clean_worktrees() {
  echo "Stale per-goal worktrees ($WORKDIR):"
  if [ ! -d "$WORKDIR" ]; then
    echo "  (none — $WORKDIR does not exist)"
    return 0
  fi
  if [ "$FORCE" != 1 ] && swarm_running; then
    log "a swarm process is running — skipping worktree removal (use --force to override)"
    echo "  (skipped: swarm appears live; re-run with --force or after stopping it)"
    return 0
  fi
  local found=0 entry name
  for entry in "$WORKDIR"/*; do
    [ -d "$entry" ] || continue
    name="$(basename "$entry")"
    removable_worktree "$name" || continue
    found=1
    reclaim "$name" "$entry"
  done
  [ "$found" = 1 ] || echo "  (none)"
  # Drop git's administrative refs for any worktree dir we removed.
  if [ "$APPLY" = 1 ] && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$ROOT" worktree prune 2>/dev/null || true
  fi
}

clean_nanoda() {
  echo "Nanoda build intermediates ($ICDIR/nanoda/target):"
  local target="$ICDIR/nanoda/target"
  if [ ! -d "$target" ]; then
    echo "  (none)"
    return 0
  fi
  local found=0 entry name
  # Everything under target/ is rebuildable except the release binary. Walk the
  # top two levels and reclaim all but target/release/nanoda_bin.
  if [ -e "$target/debug" ]; then found=1; reclaim "target/debug" "$target/debug"; fi
  for entry in "$target/release"/*; do
    [ -e "$entry" ] || continue
    name="$(basename "$entry")"
    [ "$name" = "nanoda_bin" ] && continue
    found=1
    reclaim "target/release/$name" "$entry"
  done
  [ "$found" = 1 ] || echo "  (none — already lean)"
}

clean_caches() {
  echo "Package caches:"
  local any=0
  for path in "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/src" "$HOME/.cache/pip"; do
    if [ -e "$path" ]; then any=1; reclaim "$path" "$path"; fi
  done
  [ "$any" = 1 ] || echo "  (none)"
}

clean_deep() {
  echo "Rebuild-triggering state (--deep):"
  local any=0
  if [ -d "$ROOT/.lake/build" ]; then any=1; reclaim ".lake/build (repo)" "$ROOT/.lake/build"; fi
  # Stale elan toolchains: anything other than the pinned lean-toolchain.
  if command -v elan >/dev/null 2>&1 && [ -f "$ROOT/lean-toolchain" ]; then
    local keep installed
    keep="$(tr -d '[:space:]' < "$ROOT/lean-toolchain")"
    while IFS= read -r installed; do
      installed="${installed%% (default)}"
      installed="$(printf '%s' "$installed" | tr -d '[:space:]')"
      [ -n "$installed" ] || continue
      if stale_toolchain "$installed" "$keep"; then
        any=1
        if [ "$APPLY" = 1 ]; then
          if elan toolchain uninstall "$installed" >/dev/null 2>&1; then
            printf '  freed   %8s  toolchain %s\n' "(elan)" "$installed"
          else
            log "could not uninstall toolchain $installed"
          fi
        else
          printf '  would   %8s  toolchain %s\n' "(elan)" "$installed"
        fi
      fi
    done < <(elan toolchain list 2>/dev/null)
  fi
  [ "$any" = 1 ] || echo "  (none)"
}

# --- self-test ------------------------------------------------------------

self_test() {
  local pass=0 fail=0
  ok()  { pass=$((pass+1)); echo "PASS $1"; }
  bad() { fail=$((fail+1)); echo "FAIL $1"; }
  # chk DESC CMD...   — pass iff CMD succeeds.  chkno is its negation.
  chk()   { local d="$1"; shift; if "$@"; then ok "$d"; else bad "$d"; fi; }
  chkno() { local d="$1"; shift; if "$@"; then bad "$d"; else ok "$d"; fi; }

  # removable_worktree: throwaway prefixes yes, keepers no.
  local n
  for n in prove-foo-a1 converge-x-a2 pr-y-a3 decompose-z-a4 demote-q-a5 telemetry-r-a6; do
    chk "removable $n" removable_worktree "$n"
  done
  for n in claims-branch metrics.jsonl goallock.AbC random-thing; do
    chkno "keep $n" removable_worktree "$n"
  done

  # stale_toolchain
  chk   "stale: older differs" stale_toolchain v4.22.0 v4.30.0
  chkno "stale: same kept"     stale_toolchain v4.30.0 v4.30.0
  chkno "stale: empty keep"    stale_toolchain v4.30.0 ""

  # bytes_of / human
  local tmp; tmp="$(mktemp -d)"
  head -c 4096 /dev/zero > "$tmp/blob" 2>/dev/null
  chk "bytes_of counts"     test "$(bytes_of "$tmp/blob")"    -ge 4096
  chk "bytes_of missing=0"  test "$(bytes_of "$tmp/missing")" -eq 0
  chk "human prints"        test -n "$(human 4096)"

  # Functional: dry-run reports a removable worktree but frees nothing; --apply
  # removes it while the claims-branch keeper survives. Runs against a fake
  # WORKDIR; ROOT points at a non-git temp dir so the prune step is a no-op.
  functional_worktree() (
    WORKDIR="$tmp/work"; ROOT="$tmp/root"; FORCE=1
    mkdir -p "$WORKDIR/prove-g-a1" "$WORKDIR/claims-branch" "$ROOT"
    head -c 2048 /dev/zero > "$WORKDIR/prove-g-a1/x" 2>/dev/null
    APPLY=0 RECLAIMED=0; clean_worktrees >/dev/null
    [ -d "$WORKDIR/prove-g-a1" ] || return 1            # dry-run kept it
    APPLY=1 RECLAIMED=0; clean_worktrees >/dev/null
    [ ! -d "$WORKDIR/prove-g-a1" ] || return 1          # apply removed it
    [ -d "$WORKDIR/claims-branch" ] || return 1         # keeper survived
    return 0
  )
  chk "worktree dry-run keeps, apply removes, keeper survives" functional_worktree

  rm -rf "$tmp"
  echo "----"
  echo "$pass passed, $fail failed"
  [ "$fail" = 0 ]
}

# --- main -----------------------------------------------------------------

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --apply)     APPLY=1 ;;
      --deep)      DEEP=1 ;;
      --force)     FORCE=1 ;;
      --self-test) self_test; exit $? ;;
      -h|--help)   usage; exit 0 ;;
      *) usage >&2; exit 2 ;;
    esac
    shift
  done

  if [ "$APPLY" = 1 ]; then
    log "APPLY mode — deleting reclaimable state"
  else
    log "dry-run — previewing reclaimable state (pass --apply to delete)"
  fi
  echo

  clean_worktrees; echo
  clean_nanoda;    echo
  clean_caches;    echo
  [ "$DEEP" = 1 ] && { clean_deep; echo; }

  if [ "$APPLY" = 1 ]; then
    printf 'Total freed: %s\n' "$(human "$RECLAIMED")"
  else
    printf 'Total reclaimable: %s   (re-run with --apply to free it)\n' "$(human "$RECLAIMED")"
  fi
}

main "$@"
