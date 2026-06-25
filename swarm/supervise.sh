#!/usr/bin/env bash
# swarm/supervise.sh — resilience wrapper around agent.sh (ADR-017,
# SPEC-017-A).
#
# The agent loop is deliberately fail-fast: it exits 3 on an infrastructure
# failure (ADR-016), and exits 0 on an empty pool even when the tree is still
# in flight (open PRs awaiting gates, blocked parents awaiting the unblock
# sweep). This wrapper owns "keep the tree moving", so an outage costs
# wall-clock instead of maintainer attention:
#
#   agent exit 3 (infra)       → exponential backoff (base 300s, ×2 per
#                                 consecutive infra failure, cap 3600s), retry
#   agent exit 1 (cycle fail)  → short fixed backoff (120s), retry
#   agent exit 0, scope open   → in-flight wait (180s): PRs merge, sweeps
#                                 unblock parents, then re-run
#   agent exit 0, scope closed → done — every goal in the scope is proved
#   agent exit 2 (config)      → fatal: a human must fix the environment
#
# Every wait also runs scope-limited PR hygiene (best-effort, never fatal):
#   - duplicate open prove PRs on one goal (the claim-race symptom, #184/#185)
#     → close all but the oldest, with a comment;
#   - an open PR sitting CONFLICTING → loud log line. GitHub runs no checks on
#     a conflicted PR, so an armed auto-merge waits forever in silence (the
#     #166 failure mode) — surfacing it is the fix's first half; the resolve
#     stays with the maintainer (records can need semantic resolution).
#
# Usage:
#   ./swarm/supervise.sh --prove --goal <id> [other agent.sh args]
#   ./swarm/supervise.sh --self-test
#
# Environment (beyond agent.sh's own):
#   UNSORRY_SUP_MAX_RUNS      max agent invocations before giving up (default 50)
#   UNSORRY_SUP_BASE_BACKOFF  infra backoff base seconds (default 300)
#   UNSORRY_SUP_MAX_BACKOFF   infra backoff cap seconds (default 3600)
#   UNSORRY_SUP_SHORT_WAIT    cycle-failure backoff seconds (default 120)
#   UNSORRY_SUP_FLIGHT_WAIT   in-flight wait seconds (default 180)
#
# Exit codes: 0 scope closed (or unscoped pool empty) · 1 run budget exhausted
# · 2 configuration error (own or agent's) · 130 interrupted.
set -euo pipefail

log() { printf '[supervise.sh] %s\n' "$*" >&2; }

# ---------------------------------------------------------- pure decisions

# next_action <agent_rc> <consec_infra> <base> <cap> <short>
# Prints "<verb> <delay_s>": done-check 0 | fatal 0 | backoff N | retry N.
# Pure — the supervisor's whole policy lives here so it is testable.
next_action() {
  local rc="$1" consec="$2" base="$3" cap="$4" short="$5" delay shift_n
  case "$rc" in
    0) echo "done-check 0" ;;
    2) echo "fatal 0" ;;
    3)
      shift_n="$consec"; [ "$shift_n" -gt 4 ] && shift_n=4
      delay=$(( base * (1 << shift_n) ))
      [ "$delay" -gt "$cap" ] && delay="$cap"
      echo "backoff $delay"
      ;;
    *) echo "retry $short" ;;
  esac
}

# scope_closed <goals_dir> <goal>
# 0 iff the goal and every descendant (<goal>-s*) is status≜proved. An empty
# scope id never closes (unscoped runs end on the agent's own exit 0).
scope_closed() {
  local dir="$1" goal="$2" f
  [ -n "$goal" ] || return 1
  [ -e "$dir/$goal.aisp" ] || return 1
  for f in "$dir/$goal.aisp" "$dir/$goal"-s*.aisp; do
    [ -e "$f" ] || continue
    grep -q 'status≜proved' "$f" || return 1
  done
  return 0
}

# duplicate_prs — stdin: "<number>\t<createdAt>\t<title>" for OPEN prove PRs;
# stdout: the numbers to close — every PR that is not the OLDEST for its goal
# (key = title up to the first ':', i.e. "prove(<goal>)"). Pure.
duplicate_prs() {
  awk -F'\t' '{
    split($3, t, ":"); key = t[1]
    if (!(key in best)) { best[key] = $1; created[key] = $2; next }
    if ($2 < created[key]) { print best[key]; best[key] = $1; created[key] = $2 }
    else { print $1 }
  }'
}

# ------------------------------------------------------------- gh plumbing

# Scope-limited PR hygiene. Best-effort: any gh failure is logged and ignored
# — hygiene must never take the supervisor down.
sweep_pr_hygiene() {
  local goal="$1" rows n
  rows="$(gh pr list --state open --limit 50 --search "\"$goal\" in:title" \
    --json number,createdAt,title \
    --jq '.[] | select(.title|startswith("prove(")) | [.number, .createdAt, .title] | @tsv' \
    2>/dev/null)" || { log "pr hygiene: gh unavailable — skipped"; return 0; }
  [ -n "$rows" ] || return 0
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    log "closing duplicate prove PR #$n (older sibling kept)"
    gh pr close "$n" --comment \
      "Duplicate prove PR for an already-claimed goal (claim-race window); closed by supervise.sh keeping the oldest open PR (ADR-017)." \
      >/dev/null 2>&1 || log "could not close #$n — leaving it"
  done < <(printf '%s\n' "$rows" | duplicate_prs)
  # Conflicted PRs get no CI runs and an armed auto-merge never fires — shout.
  gh pr list --state open --limit 50 --search "\"$goal\" in:title" \
    --json number,mergeable,title \
    --jq '.[] | select(.mergeable=="CONFLICTING") | "#\(.number) \(.title)"' \
    2>/dev/null | while IFS= read -r n; do
      [ -n "$n" ] || continue
      log "ATTENTION: $n is CONFLICTING — no checks will run and auto-merge will never fire; maintainer resolution needed"
    done
  return 0
}

# ---------------------------------------------------------------- self-test

test_next_action() {
  local got
  got="$(next_action 0 0 300 3600 120)"
  [ "$got" = "done-check 0" ] || { log "  rc0: want 'done-check 0', got '$got'"; return 1; }
  got="$(next_action 2 0 300 3600 120)"
  [ "$got" = "fatal 0" ] || { log "  rc2: want 'fatal 0', got '$got'"; return 1; }
  got="$(next_action 1 0 300 3600 120)"
  [ "$got" = "retry 120" ] || { log "  rc1: want 'retry 120', got '$got'"; return 1; }
  # Infra backoff doubles per consecutive failure and caps.
  got="$(next_action 3 0 300 3600 120)"
  [ "$got" = "backoff 300" ] || { log "  infra0: want 'backoff 300', got '$got'"; return 1; }
  got="$(next_action 3 1 300 3600 120)"
  [ "$got" = "backoff 600" ] || { log "  infra1: want 'backoff 600', got '$got'"; return 1; }
  got="$(next_action 3 3 300 3600 120)"
  [ "$got" = "backoff 2400" ] || { log "  infra3: want 'backoff 2400', got '$got'"; return 1; }
  got="$(next_action 3 9 300 3600 120)"
  [ "$got" = "backoff 3600" ] || { log "  infra9: want capped 'backoff 3600', got '$got'"; return 1; }
}

test_scope_closed() {
  local d; d="$(mktemp -d)" || return 1
  printf 'status≜proved\n' > "$d/g.aisp"
  printf 'status≜proved\n' > "$d/g-s1.aisp"
  printf 'status≜open\n'   > "$d/g-s2.aisp"
  scope_closed "$d" g && { log "  open sub counted as closed"; rm -rf "$d"; return 1; }
  printf 'status≜proved\n' > "$d/g-s2.aisp"
  scope_closed "$d" g || { log "  fully proved tree not closed"; rm -rf "$d"; return 1; }
  # Blocked parents and deep descendants hold the scope open.
  printf 'status≜blocked\n' > "$d/g-s2-s1.aisp"
  scope_closed "$d" g && { log "  blocked grandchild counted as closed"; rm -rf "$d"; return 1; }
  # An empty scope id, or a missing root record, never closes.
  scope_closed "$d" "" && { log "  empty scope closed"; rm -rf "$d"; return 1; }
  scope_closed "$d" missing && { log "  missing root closed"; rm -rf "$d"; return 1; }
  rm -rf "$d"
  return 0
}

test_duplicate_prs() {
  local got want
  got="$(printf '184\t2026-06-11T19:01:00Z\tprove(g-a): thm by alpha\n185\t2026-06-11T19:02:00Z\tprove(g-a): thm by bravo\n190\t2026-06-11T19:03:00Z\tprove(g-b): other by alpha\n' | duplicate_prs)"
  want="185"
  [ "$got" = "$want" ] || { log "  dedupe: want '$want', got '$got'"; return 1; }
  # Order-independent: the oldest survives even when listed last.
  got="$(printf '185\t2026-06-11T19:02:00Z\tprove(g-a): thm by bravo\n184\t2026-06-11T19:01:00Z\tprove(g-a): thm by alpha\n' | duplicate_prs)"
  [ "$got" = "185" ] || { log "  dedupe order: want '185', got '$got'"; return 1; }
  # No duplicates → nothing to close.
  got="$(printf '184\t2026-06-11T19:01:00Z\tprove(g-a): thm by alpha\n' | duplicate_prs)"
  [ -z "$got" ] || { log "  singleton: want '', got '$got'"; return 1; }
}

run_self_test() {
  local tests=(test_next_action test_scope_closed test_duplicate_prs)
  local failures=0 t
  for t in "${tests[@]}"; do
    if "$t"; then printf 'PASS %s\n' "$t"; else printf 'FAIL %s\n' "$t"; failures=$((failures + 1)); fi
  done
  if [ "$failures" -gt 0 ]; then
    printf 'supervise self-test: %d of %d failed\n' "$failures" "${#tests[@]}"
    exit 1
  fi
  printf 'supervise self-test: all %d tests passed\n' "${#tests[@]}"
  exit 0
}

# --------------------------------------------------------------------- main

main() {
  if [ "${1:-}" = "--self-test" ]; then
    run_self_test
  fi
  [ -f swarm/agent.sh ] || { log "run from the repository root"; exit 2; }

  # ADR-096: the advisory kernel-diverse independent check is ON BY DEFAULT.
  # run.sh sets UNSORRY_INDEPENDENT_CHECK (0/1) before calling us, so we only act
  # when it is genuinely UNSET — i.e. supervise.sh was invoked standalone. Opt out
  # with UNSORRY_INDEPENDENT_CHECK set falsey. NON-GATING: a failed bootstrap
  # degrades to a logged skip; proving is never blocked.
  if [ -z "${UNSORRY_INDEPENDENT_CHECK+x}" ] && [ -f tools/independent_check/setup.sh ]; then
    log "independent check (ADR-096, default on): ensuring lean4export + nanoda (builds on first use)…"
    local _ic_env
    if _ic_env="$(./tools/independent_check/setup.sh)"; then
      eval "$_ic_env"
      export LEAN4EXPORT_BIN NANODA_BIN UNSORRY_INDEPENDENT_CHECK
      log "independent check: ENABLED — nanoda re-checks each proof (advisory, non-gating)"
    else
      export UNSORRY_INDEPENDENT_CHECK=0
      log "independent check: dependency setup failed (needs lake + cargo) — proceeding WITHOUT it"
    fi
  fi

  local max_runs="${UNSORRY_SUP_MAX_RUNS:-50}"
  local base="${UNSORRY_SUP_BASE_BACKOFF:-300}"
  local cap="${UNSORRY_SUP_MAX_BACKOFF:-3600}"
  local short="${UNSORRY_SUP_SHORT_WAIT:-120}"
  local flight="${UNSORRY_SUP_FLIGHT_WAIT:-180}"
  local v
  for v in "$max_runs" "$base" "$cap" "$short" "$flight"; do
    [[ "$v" =~ ^[0-9]+$ ]] || { log "non-integer supervisor knob '$v'"; exit 2; }
  done

  # The --goal scope (if any) drives scope_closed; agent.sh re-validates it.
  local goal="" prev=""
  for v in "$@"; do
    [ "$prev" = "--goal" ] && goal="$v"
    prev="$v"
  done

  local runs=0 consec_infra=0 rc action verb delay
  while :; do
    runs=$((runs + 1))
    if [ "$runs" -gt "$max_runs" ]; then
      log "run budget exhausted ($max_runs agent runs) — giving up"
      exit 1
    fi
    git pull -q --ff-only 2>/dev/null || log "git pull failed — running on the current tree"
    if [ -n "$goal" ] && scope_closed goals "$goal"; then
      log "scope $goal is fully proved — done after $((runs - 1)) agent run(s)"
      exit 0
    fi
    rc=0
    ./swarm/agent.sh "$@" || rc=$?
    action="$(next_action "$rc" "$consec_infra" "$base" "$cap" "$short")"
    verb="${action% *}"; delay="${action#* }"
    case "$verb" in
      done-check)
        consec_infra=0
        git pull -q --ff-only 2>/dev/null || true
        if [ -z "$goal" ]; then
          log "agent found nothing to do and no scope is set — done"
          exit 0
        fi
        if scope_closed goals "$goal"; then
          log "scope $goal is fully proved — done after $runs agent run(s)"
          exit 0
        fi
        log "pool empty but scope $goal still open — waiting ${flight}s for PRs/sweeps (run $runs/$max_runs)"
        sweep_pr_hygiene "$goal"
        sleep "$flight"
        ;;
      fatal)
        log "agent exited 2 (configuration) — a human must fix this"
        exit 2
        ;;
      backoff)
        consec_infra=$((consec_infra + 1))
        log "infrastructure failure #$consec_infra — backing off ${delay}s (run $runs/$max_runs)"
        sleep "$delay"
        ;;
      retry)
        consec_infra=0
        log "cycle failure — retrying in ${delay}s (run $runs/$max_runs)"
        [ -n "$goal" ] && sweep_pr_hygiene "$goal"
        sleep "$delay"
        ;;
    esac
  done
}

main "$@"
