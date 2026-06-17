#!/usr/bin/env bash
# swarm/sourcing.sh — swarm goal-sourcing runner (ADR-062, SPEC-062-A).
#
# The sourcing counterpart to swarm/agent.sh's prove arm: it fires up Claude to
# run ONE cycle of the unsorry-goal-sourcing skill (ADR-060 / SPEC-060-A) — pick
# a hard theme, invent candidate theorems, run the four sourcing gates
# (absence -> type-check -> non-triviality -> provable+skeptic), promote the
# survivors to triples with tools.sourcing.gen_triples, and open one
# `chore(sourcing):` PR of at most UNSORRY_MAX_GOALS goals. The skill is the
# playbook; this script is the harness (preflight, prompt assembly, the
# timeout-wrapped Claude call, exit-code classification) — exactly as agent.sh
# is the harness around the prove/translate skills.
#
# Usage:
#   ./swarm/sourcing.sh [--once] [--theme <name>] [--max-goals <N>] [--dry-run]
#   ./swarm/sourcing.sh --cycles <N> [--theme <name>] [--max-goals <N>]
#   ./swarm/sourcing.sh --self-test
#
# Unlike agent.sh, the default is a BOUNDED run. Sourcing has no empty-pool
# terminator (Claude can always invent another theorem), so an unbounded loop
# would open PRs forever. The script runs UNSORRY_SOURCING_CYCLES cycles
# (default 1) and stops; --cycles N overrides, --once forces 1. Each cycle is
# one theme and one PR (the skill's "one theme per session" discipline).
#
# Must be run from the repository root with main checked out and synchronized to
# origin/main: the cycle deduplicates new slugs against the live origin/main
# `goals/` and opens its PR from main — agent.sh's swarm-mode requirement.
#
# Exit codes: 0 success or nothing-to-do · 1 cycle failure · 2 configuration
# error (not at repo root, missing tools, unauthenticated gh) · 3 infrastructure
# failure — the Claude CLI cannot run (quota, auth, network; ADR-016), or a git
# fetch on the shared object store could not complete after retries (ADR-059).
# Both route supervise.sh to its ADR-016 backoff, so this script is
# supervise-compatible.
#
# shellcheck disable=SC2317,SC2329  # test_* functions are invoked indirectly ("$t")
set -euo pipefail

PROTOCOL_FILE="swarm/protocol.aisp"
SOURCE_PROMPT_FILE="swarm/prompts/source.md"

# Claude write/exec surface for a sourcing cycle: the sourcing toolchain, the
# goal-only build, a scratch elaboration, fetch/dedup git reads, and the single
# chore(sourcing): PR. It deliberately cannot touch library/, the lakefiles, the
# gates or the harness (the skill enforces the same boundary in prose).
SOURCE_ALLOWED_TOOLS="Read,Edit,Write,\
Bash(python3 -m tools.sourcing.*),\
Bash(python3 -m tools.gate_b *),\
Bash(lake build UnsorryGoals*),\
Bash(lake env *),\
Bash(lake exe *),\
Bash(git fetch *),Bash(git checkout *),Bash(git switch *),Bash(git add *),\
Bash(git commit *),Bash(git push *),Bash(git diff *),Bash(git status*),\
Bash(git rev-parse *),Bash(git log *),Bash(git branch *),Bash(git restore *),\
Bash(gh pr *),Bash(gh api *),Bash(gh auth status*)"

# ------------------------------------------------------------- flags / knobs
ONCE=0
DRY_RUN=0
SELF_TEST=0
THEME=""
MAX_GOALS=""
CYCLES=""
UNSORRY_PROVIDER="${UNSORRY_PROVIDER:-claude}"

# --------------------------------------------------------------- log / die
log() {
  printf '[sourcing.sh] %s\n' "$*" >&2
}

die_config() {
  printf '[sourcing.sh] config error: %s\n' "$*" >&2
  exit 2
}

# ADR-016/ADR-059: infrastructure failure on the startup/cycle path. Exit 3
# routes supervise.sh to its exponential backoff.
die_infra() {
  printf '[sourcing.sh] infrastructure failure: %s\n' "$*" >&2
  exit 3
}

usage() {
  cat <<'EOF'
Usage:
  ./swarm/sourcing.sh [--once] [--theme <name>] [--max-goals <N>] [--dry-run]
  ./swarm/sourcing.sh --cycles <N> [--theme <name>] [--max-goals <N>]
  ./swarm/sourcing.sh --self-test

Fires up Claude to run the unsorry-goal-sourcing skill (ADR-060) for one or more
cycles: pick a hard theme, source up to --max-goals new open goals through the
four sourcing gates, promote the survivors to triples, and open one
chore(sourcing): PR. The sourcing counterpart to swarm/agent.sh (ADR-062).

Flags:
  --once           Run exactly one cycle then exit (the default is one cycle)
  --cycles <N>     Run N cycles (one theme/PR each), sleeping between them
  --theme <name>   Force the theme for every cycle (default: Claude chooses one)
  --max-goals <N>  Hard cap on new goals per cycle/PR (1..50, default 50)
  --dry-run        Print the assembled prompt and exit; no Claude call, no PR
  --provider <p>   Sourcing CLI; only 'claude' is supported (default: claude)
  --self-test      Run the built-in hermetic tests and exit (0 green / 1 red)
  -h, --help       Show this help

Requirement: run from the repo root with main checked out and equal to
origin/main; gh authenticated. The cycle deduplicates against live origin/main.

Environment:
  UNSORRY_MODEL             Claude model (default: opus)
  UNSORRY_EFFORT            Optional --effort passed to Claude (default: unset)
  UNSORRY_WALL              Wall-clock seconds per Claude call (default: 2400)
  UNSORRY_FASTFAIL          Below this, a failed call is suspected infra (default: 240)
  UNSORRY_MAX_GOALS         Default --max-goals (default: 50)
  UNSORRY_SOURCING_CYCLES   Default cycle count (default: 1)
  UNSORRY_SOURCING_INTERVAL Sleep seconds between cycles (default: 60)
  UNSORRY_SOLVER            Leaderboard handle credited (default: gh api user)
  UNSORRY_FETCH_RETRIES, UNSORRY_FETCH_BACKOFF   ADR-059 fetch-resilience knobs

Exit codes: 0 ok/nothing-to-do · 1 cycle failure · 2 config error · 3 infra.
EOF
}

# ------------------------------------------------------------- arg parsing
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --once) ONCE=1 ;;
      --theme) [ $# -ge 2 ] || die_config "--theme needs an argument"; THEME="$2"; shift ;;
      --max-goals) [ $# -ge 2 ] || die_config "--max-goals needs an argument"; MAX_GOALS="$2"; shift ;;
      --cycles) [ $# -ge 2 ] || die_config "--cycles needs an argument"; CYCLES="$2"; shift ;;
      --provider) [ $# -ge 2 ] || die_config "--provider needs an argument"; UNSORRY_PROVIDER="$2"; shift ;;
      --dry-run) DRY_RUN=1 ;;
      --self-test) SELF_TEST=1 ;;
      -h|--help) usage; exit 0 ;;
      *) die_config "unknown flag '$1'" ;;
    esac
    shift
  done
}

# ----------------------------------------------------------- pure helpers
require_cmd() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || die_config "required command not found: $c"
  done
}

require_repo_root() {
  [ -f "$PROTOCOL_FILE" ] \
    || die_config "must be run from the repository root ($PROTOCOL_FILE not found)"
}

require_unsorry_origin() {
  local url
  url="$(git remote get-url origin 2>/dev/null)" \
    || die_config "no 'origin' remote configured"
  case "$url" in
    *unsorry*) ;;
    *) die_config "'origin' ($url) does not point at an unsorry repository" ;;
  esac
}

require_main_checkout() {
  local branch
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" \
    || die_config "must be run with main checked out (detached HEAD found)"
  [ "$branch" = "main" ] \
    || die_config "must be run with main checked out (current branch: $branch)"
}

require_main_matches_origin() {
  local local_head origin_head
  local_head="$(git rev-parse HEAD 2>/dev/null)" || die_config "cannot resolve local main"
  origin_head="$(git rev-parse origin/main 2>/dev/null)" || die_config "cannot resolve origin/main"
  [ "$local_head" = "$origin_head" ] \
    || die_config "local main does not match origin/main after fetch; sync before sourcing"
}

# Clamp the per-cycle goal count to the SPEC-060-A PR-discipline range [1, 50].
# A non-integer or empty value falls back to the 50-goal default.
clamp_max_goals() {
  local n="$1"
  case "$n" in
    ''|*[!0-9]*) n=50 ;;
  esac
  [ "$n" -lt 1 ] && n=1
  [ "$n" -gt 50 ] && n=50
  printf '%s\n' "$n"
}

# Sourcing is reasoning- and tool-heavy; default to a strong model, overridable.
resolve_model() {
  printf '%s\n' "${UNSORRY_MODEL:-opus}"
}

# Cycle count: --once forces 1; else --cycles / UNSORRY_SOURCING_CYCLES / 1.
resolve_cycles() {
  if [ "$ONCE" -eq 1 ]; then
    echo 1
    return 0
  fi
  local c="${CYCLES:-${UNSORRY_SOURCING_CYCLES:-1}}"
  case "$c" in
    ''|*[!0-9]*) die_config "cycles must be a positive integer (got '$c')" ;;
  esac
  [ "$c" -ge 1 ] || die_config "cycles must be >= 1 (got '$c')"
  echo "$c"
}

resolve_solver() {
  if [ -n "${UNSORRY_SOLVER:-}" ]; then
    printf '%s\n' "$UNSORRY_SOLVER"
    return 0
  fi
  local login
  login="$(gh api user -q .login 2>/dev/null || true)"
  printf '%s\n' "${login:-unknown}"
}

# The slugs of every goal currently on disk (one goals/<slug>.aisp per goal).
# Sorted + unique; non-.aisp files are ignored.
goal_slugs() {
  local dir="${1:-goals}"
  [ -d "$dir" ] || return 0
  local f
  for f in "$dir"/*.aisp; do
    [ -e "$f" ] || continue
    basename "$f" .aisp
  done | sort -u
}

# Assemble the Claude prompt: the sourcing playbook (source.md) plus a runtime
# block fixing this cycle's theme, goal cap, solver, and dedup snapshot. Pure in
# its arguments (the snapshot is passed in) so it is hermetically testable.
build_prompt() {
  local theme="$1" max_goals="$2" solver="$3" snapshot="$4" theme_line
  if [ -n "$theme" ]; then
    theme_line="Theme for THIS cycle (use exactly this one): $theme"
  else
    theme_line="Theme for THIS cycle: choose ONE hard family yourself (see the skill's references/themes-and-difficulty.md); take only one backlog/candidates/<theme>.md file."
  fi
  cat "$SOURCE_PROMPT_FILE"
  cat <<EOF

--- RUNTIME PARAMETERS (this cycle) ---
$theme_line
Maximum new goals this cycle (hard cap; ONE PR): $max_goals
Credit the sourced goals to solver handle: $solver
  (the harness exported UNSORRY_SOLVER=$solver — keep it set so leaderboard credit lands on this handle.)

Existing goal slugs on the freshly-synced main. DEDUPLICATE against these: never
re-source a slug or a statement that collides with one of them, and re-fetch and
re-check immediately before you open the PR.
$snapshot
--- END RUNTIME PARAMETERS ---
EOF
}

# ADR-059 pure backoff schedule, mirroring swarm/agent.sh:fetch_retry_delay (the
# canonical fetch-resilience logic). delay = base*2^(attempt-1), shift clamped at
# 6, then capped; base 0 yields 0 (tests use this to avoid real sleeps).
fetch_retry_delay() {
  local attempt="$1" base="$2" cap="$3" delay shift_n
  shift_n=$((attempt - 1)); [ "$shift_n" -gt 6 ] && shift_n=6
  delay=$(( base * (1 << shift_n) ))
  [ "$delay" -gt "$cap" ] && delay="$cap"
  echo "$delay"
}

# ADR-059: a fetch into the shared .git/objects store is not concurrency-safe
# (#983) — retry transient failures with exponential backoff; -c gc.auto=0 stops
# a concurrent repack racing the unpack. Returns 3 once all attempts are spent so
# the caller can propagate the infrastructure code.
git_fetch_retry() {
  local dir="$1"; shift
  local attempts="${UNSORRY_FETCH_RETRIES:-3}" base="${UNSORRY_FETCH_BACKOFF:-2}" cap=30
  local n=1 delay
  while :; do
    if git -C "$dir" -c gc.auto=0 fetch "$@"; then
      return 0
    fi
    if [ "$n" -ge "$attempts" ]; then
      log "git fetch ($*) failed after $attempts attempt(s) — infrastructure failure (#983, ADR-059)"
      return 3
    fi
    delay="$(fetch_retry_delay "$n" "$base" "$cap")"
    log "git fetch ($*) failed (attempt $n/$attempts) — retrying in ${delay}s"
    sleep "$delay"
    n=$((n + 1))
  done
}

# ADR-016 pure classifier: a failed Claude call is infrastructure only when it
# died fast (under the fast-fail threshold) AND the health probe also failed.
classify_call_failure() {
  local duration="$1" fastfail="$2" probe_rc="$3"
  if [ "$duration" -lt "$fastfail" ] && [ "$probe_rc" -ne 0 ]; then
    echo infra
  else
    echo real
  fi
}

# ADR-016: a cheap "can Claude run at all right now?" probe on the sonnet model,
# so the premium budget whose exhaustion it diagnoses is not what it draws from.
cli_health_probe() {
  timeout 90 claude -p "Reply with exactly: OK" --model sonnet \
    --output-format text >/dev/null 2>&1
}

claude_model_available() {
  local model="$1"
  timeout 30 claude -p "Reply with exactly: OK" --model "$model" \
    --output-format text >/dev/null 2>&1
}

# ---------------------------------------------------------- the Claude call
call_claude_source() {
  local prompt="$1" model
  local -a eff=()
  model="$(resolve_model)"
  [ -n "${UNSORRY_EFFORT:-}" ] && eff=(--effort "$UNSORRY_EFFORT")
  if [ "$model" = fable ] && ! claude_model_available fable; then
    log "fable model not available — falling back to opus"
    model="opus"
  fi
  timeout "$UNSORRY_WALL" claude -p "$prompt" \
    --model "$model" "${eff[@]}" --output-format text \
    --allowedTools "$SOURCE_ALLOWED_TOOLS"
}

# ----------------------------------------------------------------- a cycle
run_cycle() {
  local theme="$1" max_goals="$2" solver="$3"
  local prompt snapshot start dur rc=0 probe_rc=0
  snapshot="$(goal_slugs goals)"
  prompt="$(build_prompt "$theme" "$max_goals" "$solver" "$snapshot")"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s\n' "$prompt"
    log "dry-run: prompt above; no Claude call, no PR"
    return 0
  fi

  log "sourcing cycle: theme='${theme:-<model-choice>}' max_goals=$max_goals solver=$solver model=$(resolve_model)"
  start="$(date +%s)"
  call_claude_source "$prompt" || rc=$?
  dur=$(( $(date +%s) - start ))

  if [ "$rc" -ne 0 ]; then
    cli_health_probe || probe_rc=$?
    if [ "$(classify_call_failure "$dur" "$UNSORRY_FASTFAIL" "$probe_rc")" = infra ]; then
      die_infra "Claude CLI unavailable (rc=$rc after ${dur}s) — no queue penalty (ADR-016)"
    fi
    log "sourcing cycle failed (rc=$rc after ${dur}s)"
    return 1
  fi
  log "sourcing cycle complete (${dur}s)"
  return 0
}

# ------------------------------------------------------------------- main
main() {
  parse_args "$@"
  require_repo_root
  require_cmd python3 git timeout date

  if [ "$SELF_TEST" -eq 1 ]; then
    run_self_tests
  fi

  case "$UNSORRY_PROVIDER" in
    claude) : ;;
    *) die_config "sourcing supports only --provider claude (got '$UNSORRY_PROVIDER')" ;;
  esac

  UNSORRY_WALL="${UNSORRY_WALL:-2400}"
  UNSORRY_FASTFAIL="${UNSORRY_FASTFAIL:-240}"
  local v
  for v in "$UNSORRY_WALL" "$UNSORRY_FASTFAIL"; do
    case "$v" in
      ''|*[!0-9]*) die_config "UNSORRY_WALL and UNSORRY_FASTFAIL must be integers (got '$v')" ;;
    esac
  done

  local max_goals cycles solver
  max_goals="$(clamp_max_goals "${MAX_GOALS:-${UNSORRY_MAX_GOALS:-50}}")"
  cycles="$(resolve_cycles)"

  if [ "$DRY_RUN" -eq 0 ]; then
    require_cmd claude gh
    require_unsorry_origin
    require_main_checkout
    gh auth status >/dev/null 2>&1 || die_config "gh is not authenticated (run: gh auth login)"
    git_fetch_retry . origin main || exit $?
    require_main_matches_origin
    cli_health_probe || die_infra "Claude CLI is not callable (ADR-016 health probe failed)"
  fi
  solver="$(resolve_solver)"

  local i rc overall=0
  for (( i = 1; i <= cycles; i++ )); do
    [ "$cycles" -gt 1 ] && log "=== sourcing cycle $i/$cycles ==="
    rc=0
    run_cycle "$THEME" "$max_goals" "$solver" || rc=$?
    [ "$rc" -ne 0 ] && overall=1
    if [ "$i" -lt "$cycles" ] && [ "$DRY_RUN" -eq 0 ]; then
      # Refresh main between cycles so the next dedup snapshot stays current.
      git_fetch_retry . origin main || exit $?
      git merge --ff-only origin/main >/dev/null 2>&1 || log "could not fast-forward main between cycles"
      sleep "${UNSORRY_SOURCING_INTERVAL:-60}"
    fi
  done
  exit "$overall"
}

# ----------------------------------------------------------------- self-tests
_assert_eq() {  # <expected> <actual> <msg>
  if [ "$1" != "$2" ]; then
    printf '  assert failed: %s (expected %q, got %q)\n' "$3" "$1" "$2" >&2
    return 1
  fi
}

test_clamp_max_goals() {
  _assert_eq 50 "$(clamp_max_goals 100)" "100 clamps to 50" || return 1
  _assert_eq 50 "$(clamp_max_goals 50)"  "50 stays 50"      || return 1
  _assert_eq 25 "$(clamp_max_goals 25)"  "25 stays 25"      || return 1
  _assert_eq 1  "$(clamp_max_goals 0)"   "0 floors to 1"    || return 1
  _assert_eq 50 "$(clamp_max_goals '')"  "empty -> 50"      || return 1
  _assert_eq 50 "$(clamp_max_goals abc)" "non-int -> 50"    || return 1
}

test_resolve_model() {
  ( unset UNSORRY_MODEL; _assert_eq opus   "$(resolve_model)" "default opus" ) || return 1
  ( UNSORRY_MODEL=sonnet; _assert_eq sonnet "$(resolve_model)" "override honoured" ) || return 1
}

test_resolve_cycles() {
  # Drive the real globals directly (no subshell), saving/restoring around the
  # test; $(resolve_cycles) only reads them, so it stays subshell-clean.
  local saved_once="$ONCE" saved_cycles="$CYCLES" rc=0
  local UNSORRY_SOURCING_CYCLES=""
  ONCE=1; CYCLES=9; _assert_eq 1 "$(resolve_cycles)" "--once forces 1"   || rc=1
  ONCE=0; CYCLES=3; _assert_eq 3 "$(resolve_cycles)" "--cycles honoured" || rc=1
  ONCE=0; CYCLES=""; _assert_eq 1 "$(resolve_cycles)" "default 1"        || rc=1
  ONCE="$saved_once"; CYCLES="$saved_cycles"
  return "$rc"
}

test_goal_slugs() {
  local d out
  d="$(mktemp -d)" || return 1
  : > "$d/zeta-goal.aisp"; : > "$d/alpha-goal.aisp"; : > "$d/note.txt"
  out="$(goal_slugs "$d")"
  rm -rf "$d"
  _assert_eq "alpha-goal"$'\n'"zeta-goal" "$out" "slugs sorted, non-.aisp ignored" || return 1
}

test_build_prompt() {
  local out
  out="$(build_prompt "euler-substrate" 7 "alice" "foo-goal"$'\n'"bar-goal")"
  case "$out" in *unsorry-goal-sourcing*) ;; *) echo "  missing skill ref" >&2; return 1 ;; esac
  case "$out" in *euler-substrate*)      ;; *) echo "  missing theme"     >&2; return 1 ;; esac
  case "$out" in *"max-goals"*|*"Maximum new goals this cycle (hard cap; ONE PR): 7"*) ;; *) echo "  missing cap" >&2; return 1 ;; esac
  case "$out" in *alice*)                ;; *) echo "  missing solver"    >&2; return 1 ;; esac
  case "$out" in *foo-goal*)             ;; *) echo "  missing snapshot"  >&2; return 1 ;; esac
}

test_build_prompt_model_choice() {
  local out
  out="$(build_prompt "" 50 "bob" "")"
  case "$out" in *"choose ONE hard family yourself"*) ;; *) return 1 ;; esac
}

test_fetch_retry_delay() {
  _assert_eq 0  "$(fetch_retry_delay 1 0 30)" "base 0 -> 0"       || return 1
  _assert_eq 2  "$(fetch_retry_delay 1 2 30)" "attempt1 base2 -> 2" || return 1
  _assert_eq 4  "$(fetch_retry_delay 2 2 30)" "attempt2 base2 -> 4" || return 1
  _assert_eq 30 "$(fetch_retry_delay 8 2 30)" "caps at 30"        || return 1
}

test_infra_failure_classifier() {
  _assert_eq infra "$(classify_call_failure 10 240 1)"  "fast + probe-down = infra" || return 1
  _assert_eq real  "$(classify_call_failure 10 240 0)"  "fast + probe-ok = real"    || return 1
  _assert_eq real  "$(classify_call_failure 300 240 1)" "slow = real"               || return 1
}

test_parse_args() {
  # parse_args writes the script globals; drive it in-process and reset after
  # (run_self_tests exits when done, so the reset is just test hygiene).
  local rc=0
  THEME=""; MAX_GOALS=""; CYCLES=""; DRY_RUN=0; ONCE=0
  parse_args --theme foo --max-goals 9 --cycles 2 --dry-run
  _assert_eq foo "$THEME"     "theme parsed"     || rc=1
  _assert_eq 9   "$MAX_GOALS" "max-goals parsed" || rc=1
  _assert_eq 2   "$CYCLES"    "cycles parsed"    || rc=1
  _assert_eq 1   "$DRY_RUN"   "dry-run parsed"   || rc=1
  THEME=""; MAX_GOALS=""; CYCLES=""; DRY_RUN=0; ONCE=0
  parse_args --once
  _assert_eq 1 "$ONCE" "once parsed" || rc=1
  THEME=""; MAX_GOALS=""; CYCLES=""; DRY_RUN=0; ONCE=0
  return "$rc"
}

test_usage_smoke() {
  local out; out="$(usage)"
  case "$out" in *sourcing.sh*)  ;; *) return 1 ;; esac
  case "$out" in *"--max-goals"*) ;; *) return 1 ;; esac
}

run_self_tests() {
  local tests=(
    test_clamp_max_goals
    test_resolve_model
    test_resolve_cycles
    test_goal_slugs
    test_build_prompt
    test_build_prompt_model_choice
    test_fetch_retry_delay
    test_infra_failure_classifier
    test_parse_args
    test_usage_smoke
  )
  local failures=0 t
  for t in "${tests[@]}"; do
    if "$t"; then
      printf 'PASS %s\n' "$t"
    else
      printf 'FAIL %s\n' "$t"
      failures=$((failures + 1))
    fi
  done
  if [ "$failures" -gt 0 ]; then
    printf 'self-test: %d of %d tests failed\n' "$failures" "${#tests[@]}"
    exit 1
  fi
  printf 'self-test: all %d tests passed\n' "${#tests[@]}"
  exit 0
}

main "$@"
