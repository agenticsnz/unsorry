#!/usr/bin/env bash
# swarm/run.sh — one-command governed swarm (ADR-058, SPEC-058-A).
#
# Runs the two halves of the coordinated --prove flow together, so an operator
# launches ONE command instead of two:
#   * one DISPATCHER loop — ./swarm/agent.sh --dispatch-queue
#       opens queued/prove/* branches as admitted PRs when the submission
#       governor allows more verifier work.
#   * one PROVER loop     — ./swarm/supervise.sh --prove "$@"
#       proves goals and pushes verified branches under queued/prove/ (queue
#       mode is the agent.sh default); resilient via ADR-017.
# Both inherit this shell's UNSORRY_* env and are torn down together on exit.
#
# Run exactly ONE dispatcher. For a multi-node swarm, run this once and start
# additional `./swarm/supervise.sh --prove` provers elsewhere — do not start
# more dispatchers.
#
# Usage:
#   ./swarm/run.sh [--goal <id>] [--provider <name>] [-pi [<model>]] [...]
# Args are passed through to the prover (see ./swarm/agent.sh --help).
set -euo pipefail

usage() {
  cat <<'EOF'
swarm/run.sh — launch the governed swarm with a single command (ADR-058).

  ./swarm/run.sh [agent.sh --prove args]

Internally runs, sharing this shell's UNSORRY_* env, stopped together on exit:
  * dispatcher : ./swarm/agent.sh --dispatch-queue   (opens queued PRs)
  * prover     : ./swarm/supervise.sh --prove ...     (proves + queues branches)

Run ONE dispatcher; for more provers, start extra `supervise.sh --prove` only.
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

if [ ! -f swarm/agent.sh ] || [ ! -f swarm/supervise.sh ]; then
  echo "swarm/run.sh: run from the repository root" >&2
  exit 2
fi

log() { printf '[run %s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }

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

dispatcher &
dispatch_pid=$!
cleanup() {
  kill "$dispatch_pid" 2>/dev/null || true
  pkill -P "$dispatch_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

log "governed swarm up: dispatcher pid=$dispatch_pid + prover (supervise.sh --prove $*)"
# Resilient prover loop in the foreground; when it exits, cleanup() stops the dispatcher.
./swarm/supervise.sh --prove "$@"
