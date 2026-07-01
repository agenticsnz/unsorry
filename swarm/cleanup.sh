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
#   * (--deep only) loose git objects in the shared object store. Every fetch and
#     every queued/prove branch leaves loose objects behind — one inode each —
#     and nothing else here packs them away. `git gc` collapses them.
#
# INODES, NOT JUST BYTES. mkdir can fail with ENOSPC while `df` still shows free
# *bytes*: the filesystem is out of *inodes*. The swarm's footprint is millions
# of tiny files (mathlib .olean trees, loose git objects), so inodes exhaust long
# before bytes. Every category therefore reports an inode count next to its byte
# size, and the run prints the host's df -i pressure so a reclaim that frees few
# bytes but many inodes is never mistaken for a no-op.
#
# SAFETY: dry-run by DEFAULT — it prints what each category would reclaim and
# frees nothing. Pass --apply to actually delete. The claims-branch worktree and
# the nanoda/lean4export binaries are never removed. It refuses to remove
# worktrees (and to run git gc) while a swarm appears to be running — a worktree
# may be mid-proof and gc may race a live checkout — unless --force is given.
#
# Exit codes: 0 ok · 2 usage / config error.
set -euo pipefail

WORKDIR="${UNSORRY_WORKDIR:-$HOME/.unsorry/work}"
ICDIR="${UNSORRY_INDEPENDENT_CHECK_DIR:-$HOME/.unsorry/independent-check}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

APPLY=0          # 0 = dry-run (default), 1 = actually delete
DEEP=0           # 1 = also clear rebuild-triggering caches + pack loose objects
FORCE=0          # 1 = remove worktrees / gc even if a swarm looks live
RECLAIMED=0      # running total of bytes reported (dry-run) or freed (apply)
INODES=0         # running total of inodes reported (dry-run) or freed (apply)

log() { printf '%s cleanup: %s\n' "$(date -u +%H:%M:%SZ)" "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: swarm/cleanup.sh [--apply] [--deep] [--force] [--self-test]

Reclaim the swarm's local disk footprint (stale per-goal worktrees, the nanoda
Rust build tree, and package caches). Dry-run by default: prints what would be
freed — in BOTH bytes and inodes — and deletes nothing. Run from anywhere; paths
come from the same env vars the swarm uses.

  --apply       actually delete (default is a dry-run preview)
  --deep        also clear rebuild-triggering state (the repo's .lake/build and
                stale elan toolchains) and pack loose git objects (git gc),
                which is the usual inode hog on a long-running box
  --force       remove worktrees / run git gc even if a swarm looks live
                (default: skip them so a mid-proof checkout is never pulled out)
  --self-test   run the hermetic unit tests and exit
  -h, --help    this help

Note: mkdir failing with "No space left on device" while df shows free bytes
means you are out of INODES — run with --deep to pack loose git objects.

Env: UNSORRY_WORKDIR (default ~/.unsorry/work),
     UNSORRY_INDEPENDENT_CHECK_DIR (default ~/.unsorry/independent-check),
     UNSORRY_INODE_WARN_PCT (df -i %% at which to warn; default 80)
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

# Inode count of a path — every file and directory in the tree is one inode
# (0 if missing). This is what actually exhausts on a swarm box. Prefer GNU
# `du --inodes`; fall back to counting `find` lines where it is unavailable.
inodes_of() {
  [ -e "$1" ] || { printf '0'; return; }
  if du -s --inodes "$1" >/dev/null 2>&1; then
    du -s --inodes "$1" 2>/dev/null | cut -f1
  else
    find "$1" 2>/dev/null | wc -l | tr -d ' '
  fi
}

# df -i inode-use percentage (integer, no %) for the filesystem backing $HOME,
# or non-zero/empty if it cannot be read. -P forces one POSIX line so column 5
# is always IUse%.
inode_use_pct() {
  local pct
  pct="$(df -iP "$HOME" 2>/dev/null | awk 'NR==2{p=$5; gsub(/%/,"",p); print p}')"
  case "$pct" in ''|*[!0-9]*) return 1 ;; esac
  printf '%s' "$pct"
}

# Human-readable IEC size; falls back to a raw byte count if numfmt is absent.
human() {
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec --suffix=B "$1" 2>/dev/null || printf '%sB' "$1"
  else
    printf '%sB' "$1"
  fi
}

# Report a single path in bytes AND inodes and, under --apply, remove it.
# Accrues both running totals. Usage: reclaim <label> <path>
reclaim() {
  local label="$1" path="$2" b i verb
  [ -e "$path" ] || return 0
  b="$(bytes_of "$path")";  [ "$b" -gt 0 ] 2>/dev/null || b=0
  i="$(inodes_of "$path")"; [ "$i" -gt 0 ] 2>/dev/null || i=0
  RECLAIMED=$((RECLAIMED + b))
  INODES=$((INODES + i))
  if [ "$APPLY" = 1 ]; then rm -rf "$path"; verb=freed; else verb=would; fi
  printf '  %-5s  %8s  %9s inodes  %s\n' "$verb" "$(human "$b")" "$i" "$label"
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

# Paths of every git worktree registered against $ROOT (the main checkout, the
# claims-branch keeper, and every scratch per-goal checkout). Authoritative: the
# agent registers each scratch checkout with `git worktree add`, so this catches
# them regardless of how the directory is named or nested. Empty when $ROOT is
# not a git repo.
registered_worktrees() {
  git -C "$ROOT" worktree list --porcelain 2>/dev/null \
    | awk '/^worktree /{sub(/^worktree /,""); print}'
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
  local found=0 entry name handled=" "
  # Pass 1: direct children carrying a known throwaway prefix.
  for entry in "$WORKDIR"/*; do
    [ -d "$entry" ] || continue
    name="$(basename "$entry")"
    removable_worktree "$name" || continue
    found=1; handled="$handled$entry "
    reclaim "$name" "$entry"
  done
  # Pass 2: any git worktree registered under $WORKDIR that Pass 1 missed
  # (renamed, or grouped under a per-agent subdir), except the claims keeper.
  # This is the fix for "cleanup reports (none) while a worktree hoards inodes":
  # a scratch checkout is a real worktree even when its name dodges the prefix
  # allowlist.
  local wt
  while IFS= read -r wt; do
    [ -n "$wt" ] || continue
    case "$wt/" in "$WORKDIR"/*) ;; *) continue ;; esac   # under WORKDIR only
    case "$handled" in *" $wt "*) continue ;; esac         # not already done
    name="$(basename "$wt")"
    [ "$name" = claims-branch ] && continue                # keeper
    found=1; handled="$handled$wt "
    reclaim "$name (worktree)" "$wt"
  done < <(registered_worktrees)
  [ "$found" = 1 ] || echo "  (none matched the removable set)"
  # Pass 3: surface — never delete — any other direct child still holding inodes,
  # so an inode-exhausted box is never told "(none)" while a hog sits untouched.
  local leftover_inodes=0 leftover_count=0 li
  for entry in "$WORKDIR"/*; do
    [ -d "$entry" ] || continue
    case "$handled" in *" $entry "*) continue ;; esac
    name="$(basename "$entry")"
    [ "$name" = claims-branch ] && continue
    li="$(inodes_of "$entry")"; [ "$li" -gt 0 ] 2>/dev/null || li=0
    [ "$li" -gt 0 ] || continue
    leftover_inodes=$((leftover_inodes + li)); leftover_count=$((leftover_count + 1))
  done
  if [ "$leftover_count" -gt 0 ]; then
    printf '  note: %d unreclaimed entr%s under %s holding %d inodes — not in the removable set; inspect with: ls %s\n' \
      "$leftover_count" "$([ "$leftover_count" = 1 ] && echo y || echo ies)" \
      "$WORKDIR" "$leftover_inodes" "$WORKDIR"
  fi
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
            printf '  freed   %8s  %9s inodes  toolchain %s\n' "(elan)" "?" "$installed"
          else
            log "could not uninstall toolchain $installed"
          fi
        else
          printf '  would   %8s  %9s inodes  toolchain %s\n' "(elan)" "?" "$installed"
        fi
      fi
    done < <(elan toolchain list 2>/dev/null)
  fi
  [ "$any" = 1 ] || echo "  (none)"
}

clean_object_store() {
  echo "Loose git objects (--deep):"
  if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "  (none — $ROOT is not a git repo)"
    return 0
  fi
  if [ "$FORCE" != 1 ] && swarm_running; then
    log "a swarm process is running — skipping git gc (it may race a live worktree)"
    echo "  (skipped: swarm appears live; re-run with --force or after stopping it)"
    return 0
  fi
  # Loose objects are the inode sink: one inode per object, and only `git gc`
  # packs them away. count-objects reports the loose count and their KiB size.
  local stats loose size_kib
  stats="$(git -C "$ROOT" count-objects -v 2>/dev/null)"
  loose="$(printf '%s\n' "$stats"   | awk '/^count:/{print $2}')"
  size_kib="$(printf '%s\n' "$stats" | awk '/^size:/{print $2}')"
  loose="${loose:-0}"; size_kib="${size_kib:-0}"
  if [ "$loose" -eq 0 ] 2>/dev/null; then
    echo "  (none — no loose objects)"
    return 0
  fi
  INODES=$((INODES + loose))
  RECLAIMED=$((RECLAIMED + size_kib * 1024))
  if [ "$APPLY" = 1 ]; then
    git -C "$ROOT" worktree prune 2>/dev/null || true
    if git -C "$ROOT" gc --prune=now >/dev/null 2>&1; then
      printf '  freed   %8s  %9s inodes  loose objects (git gc)\n' "$(human $((size_kib * 1024)))" "$loose"
    else
      log "git gc failed"
    fi
  else
    printf '  would   %8s  %9s inodes  loose objects (git gc --prune=now)\n' "$(human $((size_kib * 1024)))" "$loose"
  fi
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

  # bytes_of / inodes_of / human
  local tmp; tmp="$(mktemp -d)"
  head -c 4096 /dev/zero > "$tmp/blob" 2>/dev/null
  chk "bytes_of counts"      test "$(bytes_of "$tmp/blob")"     -ge 4096
  chk "bytes_of missing=0"   test "$(bytes_of "$tmp/missing")"  -eq 0
  chk "inodes_of counts"     test "$(inodes_of "$tmp")"         -ge 1
  chk "inodes_of missing=0"  test "$(inodes_of "$tmp/missing")" -eq 0
  chk "human prints"         test -n "$(human 4096)"

  # Functional: dry-run reports a removable worktree but frees nothing, and
  # populates BOTH the byte and inode totals; --apply removes it while the
  # claims-branch keeper survives. Runs against a fake WORKDIR; ROOT points at a
  # non-git temp dir so the prune / worktree-list steps are no-ops.
  functional_worktree() (
    WORKDIR="$tmp/work"; ROOT="$tmp/root"; FORCE=1
    mkdir -p "$WORKDIR/prove-g-a1" "$WORKDIR/claims-branch" "$ROOT"
    head -c 2048 /dev/zero > "$WORKDIR/prove-g-a1/x" 2>/dev/null
    APPLY=0 RECLAIMED=0 INODES=0; clean_worktrees >/dev/null
    [ -d "$WORKDIR/prove-g-a1" ] || return 1            # dry-run kept it
    [ "$INODES" -gt 0 ] || return 1                     # inode accounting ran
    [ "$RECLAIMED" -gt 0 ] || return 1                  # byte accounting ran
    APPLY=1 RECLAIMED=0 INODES=0; clean_worktrees >/dev/null
    [ ! -d "$WORKDIR/prove-g-a1" ] || return 1          # apply removed it
    [ -d "$WORKDIR/claims-branch" ] || return 1         # keeper survived
    return 0
  )
  chk "worktree dry-run keeps, apply removes, keeper survives" functional_worktree

  # Functional: an inode hog whose name dodges the prefix allowlist is surfaced
  # (Pass 3 note), never silently reported as "(none)". ROOT is non-git so the
  # worktree-list pass is empty and the unknown dir falls through to the note.
  functional_unmatched() (
    WORKDIR="$tmp/work2"; ROOT="$tmp/root2"; FORCE=1; APPLY=0
    mkdir -p "$WORKDIR/mystery-hog" "$ROOT"
    head -c 1024 /dev/zero > "$WORKDIR/mystery-hog/y" 2>/dev/null
    clean_worktrees 2>/dev/null | grep -q 'unreclaimed'
  )
  chk "unmatched inode hog is surfaced, not hidden" functional_unmatched

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
  if [ "$DEEP" = 1 ]; then clean_deep; echo; clean_object_store; echo; fi

  if [ "$APPLY" = 1 ]; then
    printf 'Total freed: %s across %s inodes\n' "$(human "$RECLAIMED")" "$INODES"
  else
    printf 'Total reclaimable: %s across %s inodes   (re-run with --apply to free it)\n' \
      "$(human "$RECLAIMED")" "$INODES"
  fi

  # Inode pressure is the failure mode this script exists for; surface it so a
  # low byte total never reads as "nothing to do" on an inode-starved box.
  local pct
  if pct="$(inode_use_pct)"; then
    if [ "$pct" -ge "${UNSORRY_INODE_WARN_PCT:-80}" ]; then
      log "inode usage on $HOME is ${pct}% — if little was reclaimed, the hog is likely loose git objects (run with --deep) or caches outside this script's scope"
    fi
  fi
}

main "$@"
