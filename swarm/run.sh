#!/usr/bin/env bash
# swarm/run.sh — one-command governed swarm (ADR-058, SPEC-058-A; ADR-069).
#
# Runs the coordinated --prove flow as ONE command instead of three, so an
# operator launches the whole governed swarm at once:
#   * one DISPATCHER loop — ./swarm/agent.sh --dispatch-queue
#       opens queued/prove/* branches as admitted PRs when the submission
#       governor allows more verifier work. Ref-only (gh pr create --head);
#       never mutates the working-tree checkout.
#   * one SOURCER loop    — ./swarm/sourcing.sh --if-pool-empty   (ADR-069)
#       demand-driven goal sourcing: opens one chore(sourcing): PR ONLY when the
#       prove pool is empty (no goals/<slug>.aisp carries status≜open on the
#       synced main) and no-ops with exit 0 otherwise — the complement of the
#       prove arm's empty-pool stop (ADR-067), re-polled on an interval so it
#       fires exactly when, and only when, the provers run dry. This arm ADDS the
#       automatic empty-pool top-up only; it never gates manual sourcing —
#       `./swarm/sourcing.sh` (no flag) still sources on demand regardless of how
#       full the pool is. Default-on; UNSORRY_SOURCE_ON_EMPTY=0 omits it.
#   * one PROVER loop     — ./swarm/supervise.sh --prove "$@"
#       proves goals and pushes verified branches under queued/prove/ (queue mode
#       is the agent.sh default; relocates into a per-agent worktree, ADR-042);
#       resilient via ADR-017.
# All three inherit this shell's UNSORRY_* env and are torn down together on exit.
#
# Concurrent dispatchers and sourcers are SOUND, not a conflict: dispatch dedup
# (ADR-064 + ADR-071) plus first-merge-wins (ADR-004) keep "one PR per goal"
# across passes AND across processes, so the worst case of overlap is a rare
# wasted Gate A slot, never a wrong merge. Prefer ONE dispatcher and ONE sourcer
# per swarm anyway — extra ones are redundant, not harmful. For a multi-node
# swarm, run this once and start additional `./swarm/supervise.sh --prove`
# provers elsewhere.
#
# NOTE: the repository's scheduled `queue-dispatcher` workflow (.github/
# workflows/queue-dispatcher.yml) is an always-on BACKSTOP, not a rival owner —
# it drains the queue even when no swarm node is running locally (#1909), is
# governor-capped, and no-ops when full. Running run.sh's dispatcher alongside it
# is therefore REDUNDANT, not conflicting (the dedup above keeps it sound; at
# worst a duplicate pass wastes a Gate A slot). So on a repo that already runs
# that backstop (e.g. agenticsnz/unsorry), prefer a prover only —
# `./swarm/supervise.sh --prove` — to avoid spending verifier capacity twice.
# Use run.sh's full trio for a standalone/forked deployment that has no scheduled
# dispatcher (and so no scheduled sourcing either — its demand-driven sourcer arm
# is then the backlog's only automatic top-up).
#
# Usage:
#   ./swarm/run.sh [--goal <id>] [--provider <name>] [-pi [<model>]] [...]
# Args are passed through to the prover (see ./swarm/agent.sh --help).
#
# Environment (beyond the prover/dispatcher/sourcer's own UNSORRY_*):
#   UNSORRY_GOVERNOR_WAIT    dispatcher re-poll interval seconds (default 300)
#   UNSORRY_SOURCE_ON_EMPTY  launch the demand-driven sourcer arm (default on;
#                            0/false/no/off omits it — e.g. a deployment whose
#                            backlog is topped up by a scheduled sourcing job)
#   UNSORRY_SOURCING_WAIT    sourcer re-poll interval seconds (default 300)
set -euo pipefail

usage() {
  cat <<'EOF'
swarm/run.sh — launch the governed swarm with a single command (ADR-058, ADR-069).

  ./swarm/run.sh [agent.sh --prove args]

Internally runs, sharing this shell's UNSORRY_* env, stopped together on exit:
  * dispatcher : ./swarm/agent.sh --dispatch-queue     (opens queued PRs)
  * sourcer    : ./swarm/sourcing.sh --if-pool-empty    (sources when pool empty)
  * prover     : ./swarm/supervise.sh --prove ...       (proves + queues branches)

The sourcer only ADDS automatic empty-pool top-up — `./swarm/sourcing.sh` (no
flag) still sources on demand regardless of pool depth. Disable the arm with
UNSORRY_SOURCE_ON_EMPTY=0.

Run ONE dispatcher and ONE sourcer; for more provers, start extra
`supervise.sh --prove` only.

Fork mode (ADR-068): run from a fork of agenticsnz/unsorry (auto-detected, or
forced with --fork / UNSORRY_FORK=1) and run.sh launches the PROVER ONLY — it
proves claimlessly and submits each proof as a cross-repo PR the upstream
re-verifies and auto-merges. No dispatcher or sourcer (a fork cannot open the
upstream's queued branches).

  --self-test   Run hermetic self-tests and exit (0 green / 1 red).
  -h, --help    Show this help.
EOF
}

log() { printf '[run %s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }

# The demand-driven sourcing arm (ADR-069) is ON by default; set
# UNSORRY_SOURCE_ON_EMPTY to a falsey value (0/false/no/off) to omit it — e.g. a
# deployment whose backlog is topped up by a scheduled sourcing job. Pure in the
# environment (mirrors agent.sh:env_truthy, inverted with a default-on), so the
# --self-test exercises it hermetically.
source_arm_enabled() {
  case "${UNSORRY_SOURCE_ON_EMPTY:-1}" in
    0|false|FALSE|no|NO|off|OFF) return 1 ;;
    *) return 0 ;;
  esac
}

# A long-lived run.sh keeps the launcher it was started with: a newer run.sh
# (e.g. one that first gained the credit guard below) can be on origin/main yet
# never in this process, so the guard a stale launcher lacks never runs and the
# whole swarm comes up on old code. agent.sh self-re-execs its harness (#428);
# the launcher must do the same. This pure decision (no I/O, so --self-test
# covers it) reports whether our own blob changed; the caller fetches, fast-
# forwards a clean checkout to origin/main and re-execs when it did.
run_harness_stale() {  # <before-sha> <after-sha> → 0 (stale) iff both known and differ
  [ "$1" != unknown ] && [ "$2" != unknown ] && [ "$1" != "$2" ]
}

# Pull latest and re-exec the launcher before any work is in flight. Best-effort:
# offline (fetch fails) or a dirty/diverged tree (e.g. a fork, or .lake churn) is
# left untouched — the prover/dispatcher/sourcer loops self-sync downstream — so
# the swarm is never blocked from starting. Opt out with UNSORRY_RUN_NO_SELF_UPDATE=1.
self_update_to_latest() {
  [ "${_RUN_REEXECED:-0}" = 1 ] && return 0
  [ "${UNSORRY_RUN_NO_SELF_UPDATE:-0}" = 1 ] && return 0
  command -v git >/dev/null 2>&1 || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local before after
  before="$(git hash-object swarm/run.sh 2>/dev/null || echo unknown)"
  if ! git fetch -q origin main 2>/dev/null; then
    log "self-update: git fetch failed (offline?) — running on the current tree"
    return 0
  fi
  # Only advance a clean checkout sitting on a fast-forwardable main; anything
  # dirty or diverged is left for the downstream loops to reconcile.
  if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    git merge -q --ff-only origin/main 2>/dev/null || true
  fi
  after="$(git hash-object swarm/run.sh 2>/dev/null || echo unknown)"
  if run_harness_stale "$before" "$after"; then
    log "launcher updated on origin/main ($before → $after) — re-exec'ing to run the latest code (#428)"
    _RUN_REEXECED=1 exec "$0" "$@"
  fi
}

# Credit-integrity guard (proof attribution). `agent.sh:resolve_solver` trusts
# UNSORRY_SOLVER verbatim, so a config that hard-codes someone else's handle
# credits THEM for every proof this machine produces — observed in practice as
# multiple contributors funnelling credit to one handle via a shared config, with
# no signal until they checked the leaderboard. This pure decision compares the
# effective solver handle to the operator's GitHub login; the launcher acts on it
# (block/warn) before starting any loop. Pure in its args (no I/O) so --self-test
# exercises every branch hermetically. Echoes one of: ok | ack | block | unknown.
#   solver: $UNSORRY_SOLVER (empty -> defaults to the login downstream, always ok)
#   login : gh-resolved login (empty -> unknown; cannot compare, e.g. offline)
#   ack   : $UNSORRY_SOLVER_OK (truthy -> a mismatch is a deliberate, ack'd override)
solver_credit_decision() {
  local solver="$1" login="$2" ack="$3"
  [ -z "$solver" ] && { echo ok; return; }
  [ -z "$login" ] && { echo unknown; return; }
  if [ "$(printf '%s' "$solver" | tr '[:upper:]' '[:lower:]')" \
     = "$(printf '%s' "$login" | tr '[:upper:]' '[:lower:]')" ]; then
    echo ok; return
  fi
  case "$ack" in
    1|true|TRUE|yes|YES|on|ON) echo ack ;;
    *) echo block ;;
  esac
}

# Resolve the GitHub login and act on solver_credit_decision before launching.
# A `block` exits non-zero so a mis-credited swarm never silently starts.
guard_solver_credit() {
  local login decision
  login="$(gh api user --jq .login 2>/dev/null || true)"
  decision="$(solver_credit_decision "${UNSORRY_SOLVER:-}" "$login" "${UNSORRY_SOLVER_OK:-}")"
  case "$decision" in
    ok) : ;;
    unknown)
      log "WARNING: could not resolve your GitHub login (offline / gh not authenticated) — cannot verify proof credit. Set UNSORRY_SOLVER to your handle to be certain." ;;
    ack)
      log "WARNING: proofs will be credited to '${UNSORRY_SOLVER}', NOT your GitHub account '${login}' (UNSORRY_SOLVER_OK=1 — proceeding as a deliberate override)." ;;
    block)
      cat >&2 <<EOF

  ┌─ STOP: proof credit would go to the wrong account ──────────────────┐
   UNSORRY_SOLVER is '${UNSORRY_SOLVER}', but your GitHub account is
   '${login}'. Every proof this machine produces would be credited to
   '${UNSORRY_SOLVER}' on the leaderboard — not to you.

   Fix, then re-run:
       export UNSORRY_SOLVER=${login}     # credit yourself
       # or:  unset UNSORRY_SOLVER        # default to your gh login
       export UNSORRY_AGENT_ID=${login}-1 # your own agent id (avoid sharing)

   Deliberately proving under another handle (e.g. an org)? Acknowledge:
       export UNSORRY_SOLVER_OK=1
  └─────────────────────────────────────────────────────────────────────┘

EOF
      exit 2 ;;
  esac
}

# Hermetic self-test (no network, no claude, no subprocess) of the pure arm gate
# — the SPEC-007-A quality bar for this launcher (agent-lint.yml).
run_self_test() {
  local fails=0 got v
  unset UNSORRY_SOURCE_ON_EMPTY || true
  got=on; source_arm_enabled || got=off
  [ "$got" = on ] || { printf '  FAIL: unset should default the arm on, got %s\n' "$got" >&2; fails=$((fails + 1)); }
  for v in 1 true TRUE yes YES on ON garbage; do
    UNSORRY_SOURCE_ON_EMPTY="$v"; got=on; source_arm_enabled || got=off
    [ "$got" = on ] || { printf "  FAIL: '%s' should enable the arm, got %s\n" "$v" "$got" >&2; fails=$((fails + 1)); }
  done
  for v in 0 false FALSE no NO off OFF; do
    UNSORRY_SOURCE_ON_EMPTY="$v"; got=on; source_arm_enabled || got=off
    [ "$got" = off ] || { printf "  FAIL: '%s' should disable the arm, got %s\n" "$v" "$got" >&2; fails=$((fails + 1)); }
  done
  unset UNSORRY_SOURCE_ON_EMPTY || true

  # credit guard decision (pure)
  local d
  while IFS='|' read -r solver login ack want; do
    [ -z "$want" ] && continue
    d="$(solver_credit_decision "$solver" "$login" "$ack")"
    [ "$d" = "$want" ] || { printf "  FAIL: credit(solver='%s' login='%s' ack='%s') want %s got %s\n" "$solver" "$login" "$ack" "$want" "$d" >&2; fails=$((fails + 1)); }
  done <<'CASES'
|alice||ok
alice|alice||ok
Alice|alice||ok
alice|Alice||ok
bob|alice||block
bob|alice|1|ack
bob|alice|yes|ack
bob|||unknown
CASES

  # launcher staleness (pure): stale iff the blob changed and both shas are known
  local s before after want
  while IFS='|' read -r before after want; do
    [ -z "$want" ] && continue
    if run_harness_stale "$before" "$after"; then s=stale; else s=fresh; fi
    [ "$s" = "$want" ] || { printf "  FAIL: stale(before='%s' after='%s') want %s got %s\n" "$before" "$after" "$want" "$s" >&2; fails=$((fails + 1)); }
  done <<'STALECASES'
aaa|bbb|stale
aaa|aaa|fresh
aaa|unknown|fresh
unknown|bbb|fresh
STALECASES

  if [ "$fails" -eq 0 ]; then
    echo "run.sh self-test: OK"
    return 0
  fi
  echo "run.sh self-test: $fails failure(s)" >&2
  return 1
}

# ADR-068: a fork (no upstream write access) submits proofs as cross-repo PRs and
# CANNOT run the dispatcher or sourcer, which open the upstream's own branches as
# PRs. Detect a fork origin — or an explicit --fork / UNSORRY_FORK — so run.sh
# launches the prover only (in fork mode) instead of the dispatcher+sourcer+prover
# trio. The fork branch is taken below, after the repo-root check.
UNSORRY_UPSTREAM="${UNSORRY_UPSTREAM:-agenticsnz/unsorry}"
is_fork_run() {
  case " $* " in *" --fork "*) return 0 ;; esac
  case "${UNSORRY_FORK:-}" in 1|true|TRUE|yes|YES|on|ON) return 0 ;; esac
  local url nwo
  url="$(git remote get-url origin 2>/dev/null)" || return 1
  case "$url" in
    *github.com[:/]*) nwo="${url#*github.com}"; nwo="${nwo#[:/]}"; nwo="${nwo%.git}"; nwo="${nwo%/}" ;;
    *) return 1 ;;
  esac
  [ -n "$nwo" ] && [ "$nwo" != "$UNSORRY_UPSTREAM" ] || return 1
  [ "$(gh api "repos/$nwo" --jq '.fork' 2>/dev/null)" = true ]
}

# One dispatcher loop in the background. agent.sh --dispatch-queue self-polls
# (UNSORRY_GOVERNOR_WAIT, default 300s); this wrapper restarts it if it ever
# exits non-zero (transient infra error) so the queue keeps draining.
dispatcher() {
  while :; do
    if ! ./swarm/agent.sh --dispatch-queue; then
      log "dispatcher exited non-zero; restarting after backoff"
    fi
    sleep "${UNSORRY_GOVERNOR_WAIT:-300}"
  done
}

# One demand-driven sourcing loop in the background (ADR-069). Each invocation
# of sourcing.sh --if-pool-empty re-checks the synced main: it no-ops with exit 0
# while any goal is still open and opens a single chore(sourcing): PR only when
# the pool is empty (ADR-067). This wrapper re-invokes it on an interval so the
# pool is re-polled as the provers drain it, and restarts after a backoff if it
# ever exits non-zero (transient infra). The sourcer touches the shared
# working-tree checkout (its Claude session brackets a chore(sourcing) branch);
# the dispatcher is ref-only and the prover is worktree-isolated (ADR-042), so a
# single sourcer co-locates with them safely.
sourcer() {
  while :; do
    if ! ./swarm/sourcing.sh --if-pool-empty; then
      log "sourcer exited non-zero; restarting after backoff"
    fi
    sleep "${UNSORRY_SOURCING_WAIT:-300}"
  done
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --self-test) if run_self_test; then exit 0; else exit 1; fi ;;
esac

if [ ! -f swarm/agent.sh ] || [ ! -f swarm/supervise.sh ] || [ ! -f swarm/sourcing.sh ]; then
  echo "swarm/run.sh: run from the repository root" >&2
  exit 2
fi

# Run the LATEST launcher before guarding credit or starting any loop: a process
# launched before the guard existed would never enforce it on stale code.
self_update_to_latest "$@"

# Credit-integrity guard: refuse to silently run proofs that would be credited to
# someone else (covers fork mode too — it runs before the fork branch below).
guard_solver_credit

# ADR-068: in fork mode, run the prover only (cross-repo PRs); a fork cannot run
# the dispatcher or sourcer against the upstream. --fork reaches agent.sh through
# supervise.sh (added if not already present).
if is_fork_run "$@"; then
  log "fork mode (ADR-068): submitting cross-repo PRs to $UNSORRY_UPSTREAM; running the prover only (no dispatcher, no sourcer)"
  case " $* " in
    *" --fork "*) exec ./swarm/supervise.sh --prove "$@" ;;
    *)           exec ./swarm/supervise.sh --prove --fork "$@" ;;
  esac
fi

# First work package (ADR-083): a swarm *operational task*. Before the proving
# arms start, resolve a Pokémon identity for EVERY model in the distribution that
# lacks one (docs/metrics/model-registry.json), one Pokémon per PR. This BLOCKS:
# if it cannot name every model, run.sh refuses to start the proving arms, so no
# proving/dispatch/sourcing work happens while a model is still unnamed. Disable
# the whole step with UNSORRY_HOUSEKEEPING=0.
if [ "${UNSORRY_HOUSEKEEPING:-1}" = "1" ]; then
  log "first work package: resolving Pokémon for all unnamed models (ADR-083)"
  if ! ./swarm/housekeeping.sh; then
    log "housekeeping could not name every model — NOT starting the proving arms" \
        "(set UNSORRY_HOUSEKEEPING=0 to bypass)"
    exit 1
  fi
fi

dispatcher &
dispatch_pid=$!

source_pid=""
if source_arm_enabled; then
  sourcer &
  source_pid=$!
fi

cleanup() {
  kill "$dispatch_pid" 2>/dev/null || true
  pkill -P "$dispatch_pid" 2>/dev/null || true
  if [ -n "$source_pid" ]; then
    kill "$source_pid" 2>/dev/null || true
    pkill -P "$source_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

msg="governed swarm up: dispatcher pid=$dispatch_pid"
[ -n "$source_pid" ] && msg="$msg, sourcer pid=$source_pid"
log "$msg + prover (supervise.sh --prove $*)"
# Resilient prover loop in the foreground; when it exits, cleanup() stops the
# background dispatcher and sourcer arms.
./swarm/supervise.sh --prove "$@"
