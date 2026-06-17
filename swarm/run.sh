#!/usr/bin/env bash
# swarm/run.sh — one-command governed swarm (ADR-058, SPEC-058-A; ADR-068).
#
# Runs the coordinated --prove flow as ONE command instead of three, so an
# operator launches the whole governed swarm at once:
#   * one DISPATCHER loop — ./swarm/agent.sh --dispatch-queue
#       opens queued/prove/* branches as admitted PRs when the submission
#       governor allows more verifier work. Ref-only (gh pr create --head);
#       never mutates the working-tree checkout.
#   * one SOURCER loop    — ./swarm/sourcing.sh --if-pool-empty   (ADR-068)
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
# Run exactly ONE dispatcher and ONE sourcer. For a multi-node swarm, run this
# once and start additional `./swarm/supervise.sh --prove` provers elsewhere — do
# not start more dispatchers or sourcers.
#
# NOTE: if the repository's scheduled `queue-dispatcher` workflow (.github/
# workflows/queue-dispatcher.yml) is enabled, IT is already that one dispatcher.
# Launching run.sh then adds a SECOND dispatcher. ADR-064 goal-level dedup makes
# this mostly safe — both read the same open-PR set and skip a goal already
# proved or already PR'd — but two passes can still both open a PR for the same
# goal inside the window before one is visible to the other (first-merge-wins
# then closes the loser as a conflict, wasting a Gate A slot). So on a repo with
# the scheduled dispatcher, run a prover only — `./swarm/supervise.sh --prove` —
# rather than run.sh. Use run.sh for a standalone/forked deployment that has no
# scheduled dispatcher (and so no scheduled sourcing either — its demand-driven
# sourcer arm is then the backlog's only automatic top-up).
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
swarm/run.sh — launch the governed swarm with a single command (ADR-058, ADR-068).

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

  --self-test   Run hermetic self-tests and exit (0 green / 1 red).
  -h, --help    Show this help.
EOF
}

log() { printf '[run %s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }

# The demand-driven sourcing arm (ADR-068) is ON by default; set
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
  if [ "$fails" -eq 0 ]; then
    echo "run.sh self-test: OK"
    return 0
  fi
  echo "run.sh self-test: $fails failure(s)" >&2
  return 1
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

# One demand-driven sourcing loop in the background (ADR-068). Each invocation
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
