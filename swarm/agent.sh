#!/usr/bin/env bash
# swarm/agent.sh — Phase-0 translation-only agent loop (ADR-007, SPEC-007-A).
#
# Usage:
#   ./swarm/agent.sh --translate-only [--once] [--goal <id>] [--dry-run]
#   ./swarm/agent.sh --self-test
#
# Must be run from the repository root. Record parsing, claim liveness, the
# claim TTL and the translate claim cap all come from tools/gate_b (the same
# code Gate B and the reaper use) — this script never reimplements them.
#
# Exit codes: 0 success or nothing-to-do · 1 cycle failure · 2 configuration
# error (not at repo root, missing tools, unauthenticated gh).
#
# shellcheck disable=SC2317  # test_* functions are invoked indirectly ("$t")
set -euo pipefail

# ----------------------------------------------------------------- constants

PROTOCOL_FILE="swarm/protocol.aisp"
TRANSLATE_PROMPT_FILE="swarm/prompts/translate.md"
EVIDENCE_LINE="⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩"

# ------------------------------------------------------------------- logging

log() {
  printf '[agent.sh] %s\n' "$*" >&2
}

die_config() {
  printf '[agent.sh] config error: %s\n' "$*" >&2
  exit 2
}

usage() {
  cat <<'EOF'
Usage:
  ./swarm/agent.sh --translate-only [--once] [--goal <id>] [--dry-run]
  ./swarm/agent.sh --self-test

Flags:
  --translate-only  Phase-0 mode: only phase≡translate goals are candidates
  --once            Run exactly one cycle then exit
  --goal <id>       Restrict selection to one goal (trial orchestration)
  --dry-run         Stop after selection: print the would-be claim, claim nothing
  --self-test       Run the built-in hermetic tests and exit (0 green / 1 red)

Environment:
  UNSORRY_AGENT_ID  Swarm identity (default: ~/.unsorry/agent-id, created on first run)
  UNSORRY_MODEL     Model for translation calls (default: sonnet)
  UNSORRY_WORKDIR   Claims worktree + metrics.jsonl home (default: ~/.unsorry/work)
  UNSORRY_WALL      Wall-clock seconds per claude call (default: 1800)
  UNSORRY_TTL       Claim TTL seconds (default: tools/gate_b/config.py TTL_SECONDS)
EOF
}

# ----------------------------------------------------------- python helpers
# One inline helper, run from the repo root so `tools` is importable. All
# record parsing, liveness, the TTL and the claim cap are delegated to
# tools.gate_b — DRY with the contract (SPEC-007-A quality bar).

py_helper() {
  python3 - "$@" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

from tools.gate_b import config
from tools.gate_b.claims import is_live, parse_claim, split_claim_filename
from tools.gate_b.records import format_utc_z, is_id, parse_record, parse_utc_z


def _now(arg: str) -> datetime:
    """Injectable clock: empty string means the current UTC time."""
    if arg:
        moment = parse_utc_z(arg)
        if moment is None:
            sys.exit(f"py_helper: unparsable timestamp {arg!r}")
        return moment
    return datetime.now(timezone.utc)


def _live_other_agents(claims_dir: str, goal: str, agent: str, now: datetime):
    """Distinct other agents holding live claims on goal, plus a self flag."""
    others: set[str] = set()
    live_self = False
    directory = Path(claims_dir)
    if directory.is_dir():
        for path in sorted(directory.glob("*.aisp")):
            fields = split_claim_filename(path.name)
            if fields is None or fields[0] != goal:
                continue
            claim = parse_claim(path)
            if not is_live(claim, now):
                continue
            holder = claim.agent or fields[1]
            if holder == agent:
                live_self = True
            else:
                others.add(holder)
    return others, live_self


def _translation_agents(translations_dir: str, goal: str) -> list[str]:
    """Sorted distinct agent ids with a translations/<goal>.<agent>.aisp."""
    agents: set[str] = set()
    directory = Path(translations_dir)
    if directory.is_dir():
        for path in directory.glob(f"{goal}.*.aisp"):
            fields = split_claim_filename(path.name)
            if fields is not None and fields[0] == goal:
                agents.add(fields[1])
    return sorted(agents)


def cmd_ttl(_args):
    print(config.TTL_SECONDS)


def cmd_now(_args):
    print(format_utc_z(datetime.now(timezone.utc)))


def cmd_is_id(args):
    sys.exit(0 if (len(args) == 1 and is_id(args[0])) else 1)


def cmd_candidates(args):
    """candidates <goals-dir> <claims-dir> <translations-dir> <agent> [<at>]

    SPEC-007-A step 2: phase≡translate, status≡open, fewer than the cap of
    live claims by distinct other agents, no live claim by self, no existing
    translation by self, and fewer than two distinct-agent translations on
    main (two ⇒ the goal needs the step-1b sweep, not a third translation).
    Lexicographic goal-id order (step 3).
    """
    goals_dir, claims_dir, translations_dir, agent = args[:4]
    now = _now(args[4] if len(args) > 4 else "")
    for path in sorted(Path(goals_dir).glob("*.aisp")):
        goal = path.stem
        record = parse_record(path.read_text(encoding="utf-8"))
        if record.fields.get("phase") != "translate":
            continue
        if record.fields.get("status") != "open":
            continue
        if (Path(translations_dir) / f"{goal}.{agent}.aisp").is_file():
            continue
        if len(_translation_agents(translations_dir, goal)) >= 2:
            continue
        others, live_self = _live_other_agents(claims_dir, goal, agent, now)
        if live_self or len(others) >= config.TRANSLATE_CLAIM_CAP:
            continue
        print(goal)


def cmd_sweep(args):
    """sweep <goals-dir> <translations-dir>

    SPEC-007-A step 1b: open translate goals that already carry translations
    by two or more distinct agents on main (the overlapping-PR race — no
    check-in saw a sibling, so step 8 never ran for the goal). One line per
    goal: `<goal> <agent-a> <agent-b> <count>` with the two
    lexicographically-first agent ids and the distinct-agent count, in
    lexicographic goal-id order.
    """
    goals_dir, translations_dir = args[:2]
    for path in sorted(Path(goals_dir).glob("*.aisp")):
        goal = path.stem
        record = parse_record(path.read_text(encoding="utf-8"))
        if record.fields.get("phase") != "translate":
            continue
        if record.fields.get("status") != "open":
            continue
        agents = _translation_agents(translations_dir, goal)
        if len(agents) < 2:
            continue
        print(goal, agents[0], agents[1], len(agents))


def cmd_claimable(args):
    """claimable <claims-dir> <goal> <agent> [<at>]

    Post-rebase recheck (SPEC-007-A step 4): exit 0 while the goal still has
    fewer live claims by distinct other agents than the cap, 1 otherwise.
    The agent's own freshly-committed claim is not counted against it.
    """
    claims_dir, goal, agent = args[:3]
    now = _now(args[3] if len(args) > 3 else "")
    others, _ = _live_other_agents(claims_dir, goal, agent, now)
    sys.exit(0 if len(others) < config.TRANSLATE_CLAIM_CAP else 1)


def cmd_rewrite_goal(args):
    """rewrite-goal <path> <status> [<sha>]

    SPEC-007-A step 8: edit ONLY the status≜ and sha≜ lines of a
    template-rigid goal record. Omitting <sha> (or passing '-') leaves the
    sha line untouched (the flagged case).
    """
    path = Path(args[0])
    status = args[1]
    sha = args[2] if len(args) > 2 and args[2] != "-" else None
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    status_hits = sha_hits = 0
    rewritten = []
    for line in lines:
        stripped = line.lstrip()
        indent = line[: len(line) - len(stripped)]
        newline = "\n" if line.endswith("\n") else ""
        if stripped.rstrip("\n").startswith("status≜"):
            status_hits += 1
            rewritten.append(f"{indent}status≜{status}{newline}")
        elif sha is not None and stripped.rstrip("\n").startswith("sha≜"):
            sha_hits += 1
            rewritten.append(f"{indent}sha≜{sha}{newline}")
        else:
            rewritten.append(line)
    if status_hits != 1:
        sys.exit(f"py_helper: {path} has {status_hits} status≜ lines, expected 1")
    if sha is not None and sha_hits != 1:
        sys.exit(f"py_helper: {path} has {sha_hits} sha≜ lines, expected 1")
    path.write_text("".join(rewritten), encoding="utf-8")


COMMANDS = {
    "ttl": cmd_ttl,
    "now": cmd_now,
    "is-id": cmd_is_id,
    "candidates": cmd_candidates,
    "sweep": cmd_sweep,
    "claimable": cmd_claimable,
    "rewrite-goal": cmd_rewrite_goal,
}

if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
    sys.exit(f"py_helper: unknown command {sys.argv[1:]!r}")
COMMANDS[sys.argv[1]](sys.argv[2:])
PY
}

# ------------------------------------------------------------ pure functions

utc_today() {
  date -u +%Y-%m-%d
}

# <short-hostname>-<4 hex> (ADR-007), sanitised to the contract Id grammar.
generate_agent_id() {
  local host hex
  host="$(hostname -s 2>/dev/null || hostname)"
  host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9-' '-' | tr -s '-' | sed -e 's/^-*//' -e 's/-*$//')"
  [ -n "$host" ] || host="agent"
  hex="$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
  printf '%s-%s\n' "$host" "$hex"
}

# Unique feature-branch name: feature/goal-<goal>-<kind>-<AGENT_ID>-<6 hex>.
# The suffix makes cross-cycle branch-name collisions structurally impossible:
# origin retains feature branches from failed (and merged) attempts, so a
# retried cycle that reused the deterministic name was rejected
# non-fast-forward by its own stale remote ref — the Phase-0 trial failure
# mode. PR titles already identify goal + agent, so the name needs no
# stability (SPEC-007-A).
feature_branch() {
  local kind="$1" goal="$2" hex
  hex="$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n')" || return 1
  printf 'feature/goal-%s-%s-%s-%s\n' "$goal" "$kind" "$AGENT_ID" "$hex"
}

# Claim record per the SPEC-003-B template; header date = UTC date of ts.
render_claim_record() {
  local goal="$1" agent="$2" ts="$3" ttl="$4"
  printf '𝔸5.1.claim.%s.%s@%s\n' "$goal" "$agent" "${ts%%T*}"
  printf 'γ≔unsorry.claim\n'
  printf '⟦Ω:Claim⟧{goal≜%s; agent≜%s}\n' "$goal" "$agent"
  printf '⟦Σ:Times⟧{ts≜%s; ttl≜%s}\n' "$ts" "$ttl"
  printf '⟦Γ:Expiry⟧{now>ts+ttl⇒expired}\n'
  printf '⟦Λ:Release⟧{release≜λ_.rm(self)}\n'
  printf '%s\n' "$EVIDENCE_LINE"
}

# Translation record per the SPEC-003-C template; header date = today UTC.
render_translation_record() {
  local goal="$1" agent="$2" stmt="$3" date="$4"
  printf '𝔸5.1.tr.%s.%s@%s\n' "$goal" "$agent" "$date"
  printf 'γ≔unsorry.translation\n'
  printf '⟦Ω:Tr⟧{goal≜%s; agent≜%s}\n' "$goal" "$agent"
  printf '⟦Σ:Stmt⟧{\n'
  printf '  stmt≜%s\n' "$stmt"
  printf '}\n'
  printf '⟦Γ:Provenance⟧{src≜backlog/%s.md; independent≜⊤}\n' "$goal"
  printf '⟦Λ:Norm⟧{norm≜tools/fidelity}\n'
  printf '%s\n' "$EVIDENCE_LINE"
}

# Reduce raw model output to its single non-empty line (SPEC-007-A step 6);
# fails when the output is empty or has more than one non-blank line.
single_nonempty_line() {
  local raw="$1"
  local lines=()
  mapfile -t lines < <(printf '%s\n' "$raw" \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' || true)
  [ "${#lines[@]}" -eq 1 ] || return 1
  printf '%s\n' "${lines[0]}"
}

# Statement body of backlog/<id>.md: the prose after the '# <id>' title.
extract_statement_body() {
  local file="$1" body
  [ -f "$file" ] || return 1
  body="$(sed -e '1{/^#[[:space:]]/d}' "$file" | sed -e '/[^[:space:]]/,$!d')"
  [ -n "$body" ] || return 1
  printf '%s\n' "$body"
}

# Render a translation record for (goal, agent, stmt, date) against the goal
# and backlog records found under <root>, then Gate-B-validate the temp tree
# (SPEC-007-A step 6). Pure given its inputs; used verbatim by --self-test.
validate_candidate_record() {
  local root="$1" goal="$2" agent="$3" stmt="$4" date="$5"
  local tree
  tree="$(mktemp -d "$SESSION_TMP/validate.XXXXXX")" || return 1
  mkdir -p "$tree/goals" "$tree/backlog" "$tree/translations" || return 1
  cp "$root/goals/$goal.aisp" "$tree/goals/" || return 1
  cp "$root/backlog/$goal.md" "$tree/backlog/" || return 1
  render_translation_record "$goal" "$agent" "$stmt" "$date" \
    > "$tree/translations/$goal.$agent.aisp" || return 1
  python3 -m tools.gate_b validate "$tree" >/dev/null
}

# Fidelity convergence of two translation records (SPEC-007-A steps 1b/8):
# diff them, rewrite the goal record in place — status≜translated + sha≜<sha>
# on match, status≜flagged on mismatch, only those lines — and print the
# outcome (matched|flagged). Pure given its inputs; used verbatim by
# --self-test. Returns 1 when the fidelity tool itself errors.
apply_convergence() {
  local goal_record="$1" rec_a="$2" rec_b="$3"
  local rc=0 sha
  python3 -m tools.fidelity diff "$rec_a" "$rec_b" >/dev/null || rc=$?
  case "$rc" in
    0)
      sha="$(python3 -m tools.fidelity sha "$rec_a")" || return 1
      py_helper rewrite-goal "$goal_record" translated "$sha" || return 1
      printf 'matched\n'
      ;;
    1)
      py_helper rewrite-goal "$goal_record" flagged || return 1
      printf 'flagged\n'
      ;;
    *)
      log "fidelity diff errored (exit $rc) on $rec_a vs $rec_b"
      return 1
      ;;
  esac
}

# --------------------------------------------------------------- environment

resolve_agent_id() {
  local id_file="$HOME/.unsorry/agent-id" id
  if [ -n "${UNSORRY_AGENT_ID:-}" ]; then
    id="$UNSORRY_AGENT_ID"
  elif [ -f "$id_file" ]; then
    id="$(tr -d ' \t\n' < "$id_file")"
  else
    id="$(generate_agent_id)"
    mkdir -p "$(dirname "$id_file")"
    printf '%s\n' "$id" > "$id_file"
    log "created agent identity $id at $id_file"
  fi
  py_helper is-id "$id" || die_config "agent id '$id' violates the Id grammar"
  AGENT_ID="$id"
}

require_cmd() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || die_config "required tool '$cmd' not found"
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

# ------------------------------------------------------------------- metrics

# emit_event <event> <goal> [<key> <value>]... — extra pairs land as extra
# string fields between "agent" and "ts" (e.g. the converged outcome).
emit_event() {
  local event="$1" goal="$2" ts extra=""
  shift 2
  while [ $# -ge 2 ]; do
    extra="$extra, \"$1\": \"$2\""
    shift 2
  done
  ts="$(py_helper now)"
  printf '{"event": "%s", "goal": "%s", "agent": "%s"%s, "ts": "%s"}\n' \
    "$event" "$goal" "$AGENT_ID" "$extra" "$ts" >> "$UNSORRY_WORKDIR/metrics.jsonl"
}

# ------------------------------------------------------------- git plumbing

# Step 1: pull main, ensure the claims worktree exists and is freshly pulled.
sync_repo() {
  git fetch -q origin || return 1
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)" || return 1
  if [ "$branch" = "main" ]; then
    git merge -q --ff-only origin/main || return 1
  fi
  ensure_claims_worktree
}

ensure_claims_worktree() {
  CLAIMS_WT="$UNSORRY_WORKDIR/claims-branch"
  if [ -e "$CLAIMS_WT" ]; then
    local theirs ours
    theirs="$(git -C "$CLAIMS_WT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" \
      || die_config "$CLAIMS_WT exists but is not a git worktree"
    ours="$(git rev-parse --path-format=absolute --git-common-dir)"
    [ "$theirs" = "$ours" ] \
      || die_config "$CLAIMS_WT belongs to another clone ($theirs)"
    # A cycle that died mid-rebase leaves rebase state and a detached HEAD
    # behind; recover instead of demanding manual cleanup (SPEC-007-A
    # quality bar: cycle state is re-entrant).
    git -C "$CLAIMS_WT" rebase --abort >/dev/null 2>&1 || true
    if [ "$(git -C "$CLAIMS_WT" rev-parse --abbrev-ref HEAD)" != "claims" ]; then
      git -C "$CLAIMS_WT" checkout -q -f claims \
        || die_config "$CLAIMS_WT cannot be checked out on the claims branch"
    fi
  else
    git worktree prune >/dev/null 2>&1 || true
    git worktree add -q "$CLAIMS_WT" claims || return 1
  fi
  # Unconditional at every cycle start: whatever the previous cycle left
  # behind (unpushed commits, dirty files), start from the true origin tip.
  git -C "$CLAIMS_WT" fetch -q origin claims || return 1
  git -C "$CLAIMS_WT" reset --hard -q origin/claims || return 1
}

# Snapshot of translations/ as it exists on origin/main (step 2 checks main,
# not the local checkout, for existing translations). Prints the dir path.
main_translations_dir() {
  local snap="$SESSION_TMP/main-translations"
  rm -rf "$snap" && mkdir -p "$snap" || return 1
  if git ls-tree -d --name-only origin/main -- translations | grep -q .; then
    git archive origin/main translations | tar -x -C "$snap" || return 1
  fi
  printf '%s/translations\n' "$snap"
}

# A fresh worktree at <prwt> on <branch>, branched from origin/main (shared
# by step 1b and steps 7–9).
open_pr_worktree() {
  local prwt="$1" branch="$2"
  git worktree remove --force "$prwt" >/dev/null 2>&1 || true
  git worktree add -q -B "$branch" "$prwt" origin/main
}

# Gate-B-validate the tree, commit the given paths (title doubles as the
# commit message), push, open an auto-merge PR, clean up the worktree.
submit_pr_tree() {
  local prwt="$1" branch="$2" title="$3" body="$4"
  shift 4
  if ! python3 -m tools.gate_b validate "$prwt" >/dev/null; then
    log "PR tree on $branch fails Gate B — not pushing"
    return 1
  fi
  git -C "$prwt" add "$@" || return 1
  git -C "$prwt" commit -q -m "$title" || return 1
  git -C "$prwt" push -q origin "$branch" || return 1
  (
    cd "$prwt" || exit 1
    gh pr create --base main --head "$branch" --title "$title" --body "$body" \
      && gh pr merge --auto --squash "$branch"
  ) || return 1
  git worktree remove --force "$prwt" >/dev/null 2>&1 || true
  git branch -q -D "$branch" >/dev/null 2>&1 || true
  return 0
}

# ----------------------------------------------------------------- the cycle

# Step 4: write + commit + push the claim; first-push-wins with retry. The
# loop is re-entrant (SPEC-007-A): every retry rebuilds the claim commit from
# scratch on a freshly-fetched, hard-reset origin/claims tip — no incremental
# rebase state to strand — and every exit path leaves the worktree hard-reset
# to origin/claims, so a cycle that dies here never leaves unpushed local
# commits behind for the next cycle.
claim_goal() {
  local goal="$1"
  local file="claims/${goal}.${AGENT_ID}.aisp" ts attempt
  for attempt in 1 2 3 4; do  # initial push + up to 3 from-scratch retries
    if [ "$attempt" -gt 1 ]; then
      log "claim push rejected for $goal (attempt $((attempt - 1))) — rebasing from scratch"
      git -C "$CLAIMS_WT" fetch -q origin claims 2>/dev/null || continue
      git -C "$CLAIMS_WT" reset --hard -q origin/claims || break
      # Post-fetch recheck (step 4): withdraw when the cap filled meanwhile.
      py_helper claimable "$CLAIMS_WT/claims" "$goal" "$AGENT_ID" || break
    fi
    ts="$(py_helper now)" || break
    render_claim_record "$goal" "$AGENT_ID" "$ts" "$UNSORRY_TTL" \
      > "$CLAIMS_WT/$file" || break
    git -C "$CLAIMS_WT" add "$file" || break
    git -C "$CLAIMS_WT" commit -q -m "claim: $goal $AGENT_ID" || break
    if git -C "$CLAIMS_WT" push -q origin claims 2>/dev/null; then
      emit_event claimed "$goal"
      log "claimed $goal (attempt $attempt)"
      return 0
    fi
  done
  git -C "$CLAIMS_WT" reset --hard -q origin/claims
  emit_event collision "$goal"
  log "collision on $goal — withdrawing"
  return 1
}

# Step 5: one claude call. The prompt is translate.md + the statement body;
# --tools "" enforces SPEC-007-A's "no tools are allowed for translation".
call_claude() {
  local prompt="$1"
  timeout "$UNSORRY_WALL" claude -p "$prompt" \
    --model "$UNSORRY_MODEL" --output-format text --tools ""
}

# Steps 5–6: translate with sanity checks; one retry, then give up.
# Prints the accepted statement on success.
run_translation() {
  local goal="$1"
  local body prompt attempt raw stmt
  body="$(extract_statement_body "backlog/$goal.md")" \
    || { log "backlog/$goal.md is missing or has no statement body"; return 1; }
  prompt="$(cat "$TRANSLATE_PROMPT_FILE")
$body"
  for attempt in 1 2; do
    if ! raw="$(call_claude "$prompt")"; then
      log "claude call failed or timed out for $goal (attempt $attempt)"
      continue
    fi
    if ! stmt="$(single_nonempty_line "$raw")"; then
      log "output for $goal is not a single non-empty line (attempt $attempt)"
      continue
    fi
    if ! printf '%s' "$stmt" | python3 -m tools.fidelity normalize - >/dev/null; then
      log "normalizer rejected statement for $goal (attempt $attempt)"
      continue
    fi
    if ! validate_candidate_record . "$goal" "$AGENT_ID" "$stmt" "$(utc_today)"; then
      log "Gate B rejected rendered record for $goal (attempt $attempt)"
      continue
    fi
    printf '%s\n' "$stmt"
    return 0
  done
  return 1
}

# Step 1b: converge one goal that already carries translations by two
# distinct agents on origin/main (the overlapping-PR race: both translators
# checked in before either PR merged, so neither saw a sibling and step 8
# never ran). No claim is taken — convergence is deterministic janitor work
# on already-public data, so a duplicate sweep by a racing agent produces a
# byte-identical edit whose PR merges cleanly or fails fast; both harmless.
converge_goal() {
  local goal="$1" agent_a="$2" agent_b="$3" count="$4"
  local branch prwt outcome
  branch="$(feature_branch converge "$goal")" || return 1
  prwt="$UNSORRY_WORKDIR/converge-${goal}-${AGENT_ID}"

  open_pr_worktree "$prwt" "$branch" || return 1
  outcome="$(apply_convergence "$prwt/goals/$goal.aisp" \
    "$prwt/translations/${goal}.${agent_a}.aisp" \
    "$prwt/translations/${goal}.${agent_b}.aisp")" \
    || { log "fidelity convergence failed for $goal"; return 1; }

  submit_pr_tree "$prwt" "$branch" \
    "converge($goal): $outcome by $AGENT_ID" \
    "Automated convergence sweep (SPEC-007-A step 1b): goal \`$goal\` carries translations by \`$agent_a\` and \`$agent_b\` merged in overlapping PRs, so neither check-in ran the step-8 fidelity diff. Outcome of \`python3 -m tools.fidelity diff\`: **$outcome**. Only the goal record is edited." \
    goals || return 1
  if [ "$count" -gt 2 ]; then
    emit_event converged "$goal" outcome "$outcome" translations "$count"
  else
    emit_event converged "$goal" outcome "$outcome"
  fi
  log "opened convergence PR for $goal ($outcome) on $branch"
  return 0
}

# Step 1b driver: sweep all goals needing convergence, at most once per goal
# per session. With ≥ 3 distinct translations the two lexicographically-first
# agents are diffed and the anomaly lands in the converged event.
convergence_sweep() {
  local translations_dir="$1"
  local failures=0 goal agent_a agent_b count
  while read -r goal agent_a agent_b count; do
    [ -n "$goal" ] || continue
    [ -n "${SWEPT[$goal]:-}" ] && continue
    if [ "$DRY_RUN" -eq 1 ]; then
      printf 'dry-run: would converge goal %s (translations by %s and %s of %s distinct)\n' \
        "$goal" "$agent_a" "$agent_b" "$count"
      continue
    fi
    if [ "$count" -gt 2 ]; then
      log "anomaly: $goal has $count distinct translations — diffing $agent_a vs $agent_b"
    fi
    SWEPT[$goal]=1
    if ! converge_goal "$goal" "$agent_a" "$agent_b" "$count"; then
      log "convergence of $goal failed"
      failures=$((failures + 1))
    fi
  done < <(py_helper sweep goals "$translations_dir")
  [ "$failures" -eq 0 ]
}

# Steps 7–9: write the record on a branch from origin/main, converge if a
# sibling translation exists, validate, push, open an auto-merge PR.
check_in() {
  local goal="$1" stmt="$2"
  local branch prwt record
  branch="$(feature_branch tr "$goal")" || return 1
  prwt="$UNSORRY_WORKDIR/pr-${goal}-${AGENT_ID}"
  record="$prwt/translations/${goal}.${AGENT_ID}.aisp"
  local sibling="" candidate outcome

  open_pr_worktree "$prwt" "$branch" || return 1
  mkdir -p "$prwt/translations" || return 1
  render_translation_record "$goal" "$AGENT_ID" "$stmt" "$(utc_today)" \
    > "$record" || return 1
  emit_event translated "$goal"

  # Step 8 — converge if second.
  for candidate in "$prwt/translations/${goal}."*.aisp; do
    [ -e "$candidate" ] || continue
    [ "$candidate" = "$record" ] && continue
    sibling="$candidate"
    break
  done
  if [ -n "$sibling" ]; then
    outcome="$(apply_convergence "$prwt/goals/$goal.aisp" "$record" "$sibling")" \
      || { log "fidelity convergence failed for $goal"; return 1; }
    emit_event "$outcome" "$goal"
    case "$outcome" in
      matched) log "second translation of $goal matches — goal marked translated" ;;
      flagged) log "second translation of $goal mismatches — goal flagged" ;;
    esac
  fi

  submit_pr_tree "$prwt" "$branch" \
    "tr($goal): translation by $AGENT_ID" \
    "Automated Phase-0 translation of goal \`$goal\` by agent \`$AGENT_ID\` (ADR-007, SPEC-007-A). Statement provenance: \`backlog/$goal.md\`, independent translation per ⟦Γ:Fidelity⟧." \
    translations goals || return 1
  emit_event pr-opened "$goal"
  log "opened auto-merge PR for $goal on $branch"
  return 0
}

# Step 10: remove the claim file, commit, push. Re-entrant like claim_goal:
# every retry rebuilds the release commit from scratch on a freshly-fetched,
# hard-reset origin/claims tip, and the final-failure path also hard-resets —
# a cycle never exits leaving unpushed local commits that strand the next run
# (the Phase-0 trial failure mode after "release push rejected").
release_claim() {
  local goal="$1"
  local file="claims/${goal}.${AGENT_ID}.aisp" attempt
  for attempt in 1 2 3 4; do  # initial push + up to 3 from-scratch retries
    if [ "$attempt" -gt 1 ]; then
      log "release push rejected for $goal (attempt $((attempt - 1))) — rebasing from scratch"
      git -C "$CLAIMS_WT" fetch -q origin claims 2>/dev/null || continue
      git -C "$CLAIMS_WT" reset --hard -q origin/claims || break
    fi
    git -C "$CLAIMS_WT" rm -q --ignore-unmatch "$file" || break
    if ! git -C "$CLAIMS_WT" diff --cached --quiet; then
      git -C "$CLAIMS_WT" commit -q -m "release: $goal $AGENT_ID" || break
    fi
    if git -C "$CLAIMS_WT" push -q origin claims 2>/dev/null; then
      emit_event released "$goal"
      return 0
    fi
  done
  git -C "$CLAIMS_WT" reset --hard -q origin/claims
  log "warning: could not push release of $goal — the TTL will reap it"
  return 1
}

# --------------------------------------------------------------- self-tests
# Hermetic: temp dirs only, injected clock, no network, no claude, no gh.
# The push re-entrancy tests drive the real claim/release helpers against a
# local bare origin (file:// transport) — still no network.

T_FIXTURES="tools/gate_b/tests/fixtures"
T_AT="2026-06-10T01:00:00Z"        # injected clock
T_LIVE_TS="2026-06-10T00:00:00Z"   # live at T_AT for any contract-legal TTL
T_OLD_TS="2026-06-09T00:00:00Z"    # expired at T_AT for the default TTL

test_agent_id_generation() {
  local id
  id="$(generate_agent_id)" || { log "  generate_agent_id failed"; return 1; }
  [[ "$id" =~ ^[a-z0-9][a-z0-9-]*-[0-9a-f]{4}$ ]] \
    || { log "  '$id' is not <short-hostname>-<4 hex>"; return 1; }
  py_helper is-id "$id" || { log "  '$id' violates the contract Id grammar"; return 1; }
}

test_agent_id_validation() {
  local good bad
  for good in agent-alpha box-1a2b a0; do
    py_helper is-id "$good" || { log "  valid id '$good' rejected"; return 1; }
  done
  for bad in "Agent-X" "" "-box-1a2b" "box.1a2b" "box 1a2b"; do
    if py_helper is-id "$bad"; then
      log "  invalid id '$bad' accepted"
      return 1
    fi
  done
}

test_claim_render_golden() {
  local golden="$T_FIXTURES/claims_valid/claims/nat-add-comm.agent-alpha.aisp" ttl
  ttl="$(py_helper ttl)" || return 1
  diff <(render_claim_record nat-add-comm agent-alpha "$T_LIVE_TS" "$ttl") "$golden" \
    || { log "  rendered claim differs from golden $golden"; return 1; }
}

test_translation_render_golden() {
  local golden="$T_FIXTURES/valid_tree/translations/nat-zero-add.agent-alpha.aisp"
  diff <(render_translation_record nat-zero-add agent-alpha "∀n∈ℕ:0+n≡n" 2026-06-10) "$golden" \
    || { log "  rendered translation differs from golden $golden"; return 1; }
}

test_candidate_filtering() {
  local tree claims ttl got
  tree="$(mktemp -d "$SESSION_TMP/cand.XXXXXX")" || return 1
  cp -R "$T_FIXTURES/valid_tree/goals" "$T_FIXTURES/valid_tree/translations" \
    "$T_FIXTURES/valid_tree/backlog" "$tree/" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" || return 1
  ttl="$(py_helper ttl)" || return 1

  # A: no claims — nat-add-comm is the only open translate goal in the fixture.
  got="$(py_helper candidates "$tree/goals" "$claims" "$tree/translations" agent-self "$T_AT")"
  [ "$got" = "nat-add-comm" ] || { log "  A: expected nat-add-comm, got '$got'"; return 1; }

  # B: one live claim by another agent — still claimable (1 < cap).
  render_claim_record nat-add-comm agent-other "$T_LIVE_TS" "$ttl" \
    > "$claims/nat-add-comm.agent-other.aisp"
  got="$(py_helper candidates "$tree/goals" "$claims" "$tree/translations" agent-self "$T_AT")"
  [ "$got" = "nat-add-comm" ] || { log "  B: expected nat-add-comm, got '$got'"; return 1; }

  # C: live claims by two distinct other agents — cap reached, not claimable.
  render_claim_record nat-add-comm agent-more "$T_LIVE_TS" "$ttl" \
    > "$claims/nat-add-comm.agent-more.aisp"
  got="$(py_helper candidates "$tree/goals" "$claims" "$tree/translations" agent-self "$T_AT")"
  [ -z "$got" ] || { log "  C: expected no candidates, got '$got'"; return 1; }

  # D: the same two claims, expired — they no longer count.
  render_claim_record nat-add-comm agent-other "$T_OLD_TS" "$ttl" \
    > "$claims/nat-add-comm.agent-other.aisp"
  render_claim_record nat-add-comm agent-more "$T_OLD_TS" "$ttl" \
    > "$claims/nat-add-comm.agent-more.aisp"
  got="$(py_helper candidates "$tree/goals" "$claims" "$tree/translations" agent-self "$T_AT")"
  [ "$got" = "nat-add-comm" ] || { log "  D: expected nat-add-comm, got '$got'"; return 1; }

  # E: a live claim by self excludes the goal.
  rm "$claims"/nat-add-comm.*.aisp
  render_claim_record nat-add-comm agent-self "$T_LIVE_TS" "$ttl" \
    > "$claims/nat-add-comm.agent-self.aisp"
  got="$(py_helper candidates "$tree/goals" "$claims" "$tree/translations" agent-self "$T_AT")"
  [ -z "$got" ] || { log "  E: expected no candidates, got '$got'"; return 1; }

  # F: an existing translation by self on main excludes the goal.
  rm "$claims"/nat-add-comm.*.aisp
  render_translation_record nat-add-comm agent-self "∀n,m∈ℕ:n+m≡m+n" 2026-06-10 \
    > "$tree/translations/nat-add-comm.agent-self.aisp"
  got="$(py_helper candidates "$tree/goals" "$claims" "$tree/translations" agent-self "$T_AT")"
  [ -z "$got" ] || { log "  F: expected no candidates, got '$got'"; return 1; }

  # G: two distinct-agent translations on main exclude the goal — it needs
  # the step-1b sweep, not a third translation.
  rm "$tree/translations"/nat-add-comm.*.aisp
  render_translation_record nat-add-comm agent-other "∀n,m∈ℕ:n+m≡m+n" 2026-06-10 \
    > "$tree/translations/nat-add-comm.agent-other.aisp"
  render_translation_record nat-add-comm agent-more "∀n,m∈ℕ:m+n≡n+m" 2026-06-10 \
    > "$tree/translations/nat-add-comm.agent-more.aisp"
  got="$(py_helper candidates "$tree/goals" "$claims" "$tree/translations" agent-self "$T_AT")"
  [ -z "$got" ] || { log "  G: expected no candidates, got '$got'"; return 1; }
}

test_sweep_detection() {
  local tree got
  tree="$(mktemp -d "$SESSION_TMP/sweep.XXXXXX")" || return 1
  cp -R "$T_FIXTURES/valid_tree/goals" "$T_FIXTURES/valid_tree/translations" \
    "$tree/" || return 1

  # A: the fixture's only two-translation goal (nat-zero-add) is already
  # status≜translated, and the open goal (nat-add-comm) has none — no sweep.
  got="$(py_helper sweep "$tree/goals" "$tree/translations")"
  [ -z "$got" ] || { log "  A: expected no sweep goals, got '$got'"; return 1; }

  # B: one translation of the open goal — still nothing to converge.
  render_translation_record nat-add-comm agent-beta "∀n,m∈ℕ:n+m≡m+n" 2026-06-10 \
    > "$tree/translations/nat-add-comm.agent-beta.aisp"
  got="$(py_helper sweep "$tree/goals" "$tree/translations")"
  [ -z "$got" ] || { log "  B: expected no sweep goals, got '$got'"; return 1; }

  # C: translations by two distinct agents — listed for convergence.
  render_translation_record nat-add-comm agent-alpha "∀n,m∈ℕ:m+n≡n+m" 2026-06-10 \
    > "$tree/translations/nat-add-comm.agent-alpha.aisp"
  got="$(py_helper sweep "$tree/goals" "$tree/translations")"
  [ "$got" = "nat-add-comm agent-alpha agent-beta 2" ] \
    || { log "  C: expected 'nat-add-comm agent-alpha agent-beta 2', got '$got'"; return 1; }

  # D: a third translation — still the two lexicographically-first agents,
  # with the anomaly visible in the distinct-agent count.
  render_translation_record nat-add-comm agent-zeta "∀n,m∈ℕ:n+m≡m+n" 2026-06-10 \
    > "$tree/translations/nat-add-comm.agent-zeta.aisp"
  got="$(py_helper sweep "$tree/goals" "$tree/translations")"
  [ "$got" = "nat-add-comm agent-alpha agent-beta 3" ] \
    || { log "  D: expected 'nat-add-comm agent-alpha agent-beta 3', got '$got'"; return 1; }
}

test_goal_rewrite() {
  local src="$T_FIXTURES/valid_tree/goals/nat-add-comm.aisp"
  local sha="464ef57ab509beba93c01c02bfab4ddeb157675c3d8df8c253e353ab5c09f262"
  local tmp
  tmp="$(mktemp -d "$SESSION_TMP/rewrite.XXXXXX")" || return 1

  # Matched: status and sha are both rewritten; nothing else changes.
  cp "$src" "$tmp/matched.aisp"
  py_helper rewrite-goal "$tmp/matched.aisp" translated "$sha" || return 1
  grep -qxF "  status≜translated" "$tmp/matched.aisp" \
    || { log "  status line not rewritten"; return 1; }
  grep -qxF "  sha≜$sha" "$tmp/matched.aisp" \
    || { log "  sha line not rewritten"; return 1; }
  diff <(grep -v -e 'status≜' -e 'sha≜' "$src") \
       <(grep -v -e 'status≜' -e 'sha≜' "$tmp/matched.aisp") >/dev/null \
    || { log "  rewrite touched lines other than status≜/sha≜"; return 1; }

  # Flagged: only the status line changes; sha≜∅ survives.
  cp "$src" "$tmp/flagged.aisp"
  py_helper rewrite-goal "$tmp/flagged.aisp" flagged || return 1
  grep -qxF "  status≜flagged" "$tmp/flagged.aisp" \
    || { log "  status line not rewritten to flagged"; return 1; }
  grep -qxF "  sha≜∅" "$tmp/flagged.aisp" \
    || { log "  sha line was modified in the flagged case"; return 1; }
  diff <(grep -v -e 'status≜' "$src") \
       <(grep -v -e 'status≜' "$tmp/flagged.aisp") >/dev/null \
    || { log "  flagged rewrite touched lines other than status≜"; return 1; }
}

test_convergence_rewrite() {
  # The exact step-1b/8 machinery: the fixture pair is α-equivalent, so the
  # goal record converges to translated + the fidelity sha; a mismatching
  # pair flags it and leaves sha≜∅ alone.
  local src="$T_FIXTURES/valid_tree/goals/nat-add-comm.aisp"
  local tr_a="$T_FIXTURES/valid_tree/translations/nat-zero-add.agent-alpha.aisp"
  local tr_b="$T_FIXTURES/valid_tree/translations/nat-zero-add.agent-beta.aisp"
  local sha="73026be938ddd22261b6c55a2a5843465916f04559e06406d91b71b414b797a8"
  local tmp outcome
  tmp="$(mktemp -d "$SESSION_TMP/converge.XXXXXX")" || return 1

  # Matched: status and sha are both rewritten; nothing else changes.
  cp "$src" "$tmp/matched.aisp"
  outcome="$(apply_convergence "$tmp/matched.aisp" "$tr_a" "$tr_b")" \
    || { log "  apply_convergence failed on the matched pair"; return 1; }
  [ "$outcome" = "matched" ] \
    || { log "  expected outcome 'matched', got '$outcome'"; return 1; }
  grep -qxF "  status≜translated" "$tmp/matched.aisp" \
    || { log "  status line not rewritten to translated"; return 1; }
  grep -qxF "  sha≜$sha" "$tmp/matched.aisp" \
    || { log "  sha line does not carry the fidelity sha"; return 1; }
  diff <(grep -v -e 'status≜' -e 'sha≜' "$src") \
       <(grep -v -e 'status≜' -e 'sha≜' "$tmp/matched.aisp") >/dev/null \
    || { log "  convergence touched lines other than status≜/sha≜"; return 1; }

  # Flagged: only the status line changes; sha≜∅ survives.
  cp "$src" "$tmp/flagged.aisp"
  render_translation_record nat-zero-add agent-zeta "∀n∈ℕ:n+0≡n" 2026-06-10 \
    > "$tmp/zeta.aisp"
  outcome="$(apply_convergence "$tmp/flagged.aisp" "$tr_a" "$tmp/zeta.aisp")" \
    || { log "  apply_convergence failed on the mismatched pair"; return 1; }
  [ "$outcome" = "flagged" ] \
    || { log "  expected outcome 'flagged', got '$outcome'"; return 1; }
  grep -qxF "  status≜flagged" "$tmp/flagged.aisp" \
    || { log "  status line not rewritten to flagged"; return 1; }
  grep -qxF "  sha≜∅" "$tmp/flagged.aisp" \
    || { log "  sha line was modified in the flagged case"; return 1; }
  diff <(grep -v -e 'status≜' "$src") \
       <(grep -v -e 'status≜' "$tmp/flagged.aisp") >/dev/null \
    || { log "  flagged convergence touched lines other than status≜"; return 1; }
}

test_record_validation() {
  # The exact step-6 machinery, against the fixture tree: a good statement
  # passes Gate B on a temp tree, quoted English prose does not (GB009).
  validate_candidate_record "$T_FIXTURES/valid_tree" nat-add-comm agent-self \
    "∀n,m∈ℕ:n+m≡m+n" 2026-06-10 \
    || { log "  well-formed record failed Gate B"; return 1; }
  if validate_candidate_record "$T_FIXTURES/valid_tree" nat-add-comm agent-self \
    '"addition of natural numbers is commutative for all n and m"' 2026-06-10; then
    log "  prose-heavy record passed Gate B unexpectedly"
    return 1
  fi
}

# Hermetic git identity for fixture repositories (never the user's config).
fixture_git_id() {
  git -C "$1" config user.email agent@unsorry.test \
    && git -C "$1" config user.name agent-self \
    && git -C "$1" config commit.gpgsign false
}

# Local bare-origin fixture for the push re-entrancy tests: $1/origin.git is
# a bare remote whose default branch is claims, $1/seed is a second writer
# used to move the remote tip, $1/clone is the agent's claims-worktree
# stand-in (CLAIMS_WT). file:// transport only — no network, no gh.
make_claims_fixture() {
  local tmp="$1" ttl="$2"
  git init -q --bare -b claims "$tmp/origin.git" || return 1
  git init -q -b claims "$tmp/seed" || return 1
  fixture_git_id "$tmp/seed" || return 1
  git -C "$tmp/seed" remote add origin "$tmp/origin.git" || return 1
  mkdir -p "$tmp/seed/claims" || return 1
  render_claim_record goal-other agent-other "$T_OLD_TS" "$ttl" \
    > "$tmp/seed/claims/goal-other.agent-other.aisp" || return 1
  git -C "$tmp/seed" add claims || return 1
  git -C "$tmp/seed" commit -q -m "seed claims" || return 1
  git -C "$tmp/seed" push -q origin claims || return 1
  git clone -q "$tmp/origin.git" "$tmp/clone" 2>/dev/null || return 1
  fixture_git_id "$tmp/clone" || return 1
}

# Advance origin/claims from the seeder so $1/clone is stale — the exact
# state a cycle that died mid push-retry leaves behind (remote tip newer
# than the local claims state).
advance_claims_remote() {
  local tmp="$1" ttl="$2" goal="$3"
  git -C "$tmp/seed" fetch -q origin claims || return 1
  git -C "$tmp/seed" reset --hard -q FETCH_HEAD || return 1
  render_claim_record "$goal" agent-other "$T_OLD_TS" "$ttl" \
    > "$tmp/seed/claims/$goal.agent-other.aisp" || return 1
  git -C "$tmp/seed" add claims || return 1
  git -C "$tmp/seed" commit -q -m "advance: $goal" || return 1
  git -C "$tmp/seed" push -q origin claims || return 1
}

test_feature_branch_names() {
  local AGENT_ID=agent-self
  local a b c tmp
  a="$(feature_branch tr nat-add-comm)" || return 1
  b="$(feature_branch tr nat-add-comm)" || return 1
  c="$(feature_branch converge nat-add-comm)" || return 1
  [[ "$a" =~ ^feature/goal-nat-add-comm-tr-agent-self-[0-9a-f]{6}$ ]] \
    || { log "  '$a' does not match feature/goal-<goal>-tr-<agent>-<6 hex>"; return 1; }
  [[ "$c" =~ ^feature/goal-nat-add-comm-converge-agent-self-[0-9a-f]{6}$ ]] \
    || { log "  '$c' does not match feature/goal-<goal>-converge-<agent>-<6 hex>"; return 1; }
  [ "$a" != "$b" ] \
    || { log "  two cycles produced the same branch name '$a'"; return 1; }

  # The trial regression: origin retains the previous attempt's tip under
  # the deterministic name, so reusing it is rejected non-fast-forward while
  # a suffixed name pushes cleanly without --force.
  tmp="$(mktemp -d "$SESSION_TMP/brname.XXXXXX")" || return 1
  git init -q --bare -b main "$tmp/origin.git" || return 1
  git init -q -b main "$tmp/w" || return 1
  fixture_git_id "$tmp/w" || return 1
  git -C "$tmp/w" remote add origin "$tmp/origin.git" || return 1
  printf 'one\n' > "$tmp/w/f" || return 1
  git -C "$tmp/w" add f && git -C "$tmp/w" commit -q -m one || return 1
  git -C "$tmp/w" push -q origin "main:feature/goal-nat-add-comm-tr-agent-self" \
    || return 1
  git -C "$tmp/w" checkout -q --orphan retry || return 1
  printf 'two\n' > "$tmp/w/f" || return 1
  git -C "$tmp/w" add f && git -C "$tmp/w" commit -q -m two || return 1
  if git -C "$tmp/w" push -q origin \
    "retry:feature/goal-nat-add-comm-tr-agent-self" 2>/dev/null; then
    log "  push to the stale deterministic branch name was not rejected"
    return 1
  fi
  git -C "$tmp/w" push -q origin "retry:$a" 2>/dev/null \
    || { log "  push to the suffixed branch name failed"; return 1; }
}

test_claim_push_reentrancy() {
  local AGENT_ID=agent-self UNSORRY_WORKDIR UNSORRY_TTL CLAIMS_WT
  local tmp ttl
  tmp="$(mktemp -d "$SESSION_TMP/claimpush.XXXXXX")" || return 1
  ttl="$(py_helper ttl)" || return 1
  UNSORRY_WORKDIR="$tmp" UNSORRY_TTL="$ttl" CLAIMS_WT="$tmp/clone"
  make_claims_fixture "$tmp" "$ttl" || { log "  fixture setup failed"; return 1; }

  # A: the remote tip moved after the clone last synced (the trial failure
  # state) — the claim must land without manual cleanup.
  advance_claims_remote "$tmp" "$ttl" goal-ahead \
    || { log "  fixture advance failed"; return 1; }
  claim_goal nat-add-comm \
    || { log "  claim_goal did not recover from a stale clone"; return 1; }
  git -C "$tmp/origin.git" ls-tree -r --name-only claims \
    | grep -qx "claims/nat-add-comm.agent-self.aisp" \
    || { log "  claim missing from the pushed origin/claims tip"; return 1; }
  git -C "$tmp/origin.git" ls-tree -r --name-only claims \
    | grep -qx "claims/goal-ahead.agent-other.aisp" \
    || { log "  recovery clobbered the newer remote claim"; return 1; }
  [ -z "$(git -C "$CLAIMS_WT" status --porcelain)" ] \
    || { log "  claim recovery left the worktree dirty"; return 1; }
  [ "$(git -C "$CLAIMS_WT" rev-parse claims)" = "$(git -C "$tmp/origin.git" rev-parse claims)" ] \
    || { log "  local claims tip diverges from origin after claim"; return 1; }
  grep -q '"event": "claimed", "goal": "nat-add-comm"' "$tmp/metrics.jsonl" \
    || { log "  no claimed event emitted"; return 1; }

  # B: final failure (origin unreachable) must fail closed — hard-reset
  # worktree, no unpushed local commits stranded for the next cycle.
  git -C "$CLAIMS_WT" remote set-url origin "$tmp/absent.git" || return 1
  if claim_goal goal-unreach; then
    log "  claim_goal reported success against an unreachable origin"
    return 1
  fi
  [ -z "$(git -C "$CLAIMS_WT" status --porcelain)" ] \
    || { log "  unreachable-origin failure left the worktree dirty"; return 1; }
  [ "$(git -C "$CLAIMS_WT" rev-parse claims)" = "$(git -C "$CLAIMS_WT" rev-parse origin/claims)" ] \
    || { log "  unreachable-origin failure stranded unpushed commits"; return 1; }
}

test_release_push_reentrancy() {
  local AGENT_ID=agent-self UNSORRY_WORKDIR UNSORRY_TTL CLAIMS_WT
  local tmp ttl
  tmp="$(mktemp -d "$SESSION_TMP/releasepush.XXXXXX")" || return 1
  ttl="$(py_helper ttl)" || return 1
  UNSORRY_WORKDIR="$tmp" UNSORRY_TTL="$ttl" CLAIMS_WT="$tmp/clone"
  make_claims_fixture "$tmp" "$ttl" || { log "  fixture setup failed"; return 1; }
  claim_goal nat-add-comm || { log "  setup claim failed"; return 1; }

  # Recreate the observed stranding: a previous cycle died after committing
  # the release but before pushing it, and the remote tip moved on.
  git -C "$CLAIMS_WT" rm -q claims/nat-add-comm.agent-self.aisp || return 1
  git -C "$CLAIMS_WT" commit -q -m "release: nat-add-comm agent-self" || return 1
  advance_claims_remote "$tmp" "$ttl" goal-ahead \
    || { log "  fixture advance failed"; return 1; }

  release_claim nat-add-comm \
    || { log "  release_claim did not recover from stranded state"; return 1; }
  if git -C "$tmp/origin.git" ls-tree -r --name-only claims \
    | grep -qx "claims/nat-add-comm.agent-self.aisp"; then
    log "  released claim still present on the origin/claims tip"
    return 1
  fi
  git -C "$tmp/origin.git" ls-tree -r --name-only claims \
    | grep -qx "claims/goal-ahead.agent-other.aisp" \
    || { log "  recovery clobbered the newer remote claim"; return 1; }
  [ -z "$(git -C "$CLAIMS_WT" status --porcelain)" ] \
    || { log "  release recovery left the worktree dirty"; return 1; }
  [ "$(git -C "$CLAIMS_WT" rev-parse claims)" = "$(git -C "$tmp/origin.git" rev-parse claims)" ] \
    || { log "  local claims tip diverges from origin after release"; return 1; }
  grep -q '"event": "released", "goal": "nat-add-comm"' "$tmp/metrics.jsonl" \
    || { log "  no released event emitted"; return 1; }
}

run_self_tests() {
  local tests=(
    test_agent_id_generation
    test_agent_id_validation
    test_claim_render_golden
    test_translation_render_golden
    test_candidate_filtering
    test_sweep_detection
    test_goal_rewrite
    test_convergence_rewrite
    test_record_validation
    test_feature_branch_names
    test_claim_push_reentrancy
    test_release_push_reentrancy
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

# --------------------------------------------------------------------- main

TRANSLATE_ONLY=0
ONCE=0
GOAL_FILTER=""
DRY_RUN=0
SELF_TEST=0

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --translate-only) TRANSLATE_ONLY=1 ;;
      --once) ONCE=1 ;;
      --goal)
        [ $# -ge 2 ] || { usage >&2; die_config "--goal requires a value"; }
        GOAL_FILTER="$2"
        shift
        ;;
      --dry-run) DRY_RUN=1 ;;
      --self-test) SELF_TEST=1 ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die_config "unknown flag '$1'"
        ;;
    esac
    shift
  done
}

# Candidates for this iteration: lexicographic py_helper order, restricted by
# --goal, minus goals already handled (success or failure) this session.
select_candidates() {
  local translations_dir="$1" cand
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    if [ -n "$GOAL_FILTER" ] && [ "$cand" != "$GOAL_FILTER" ]; then
      continue
    fi
    [ -n "${HANDLED[$cand]:-}" ] && continue
    printf '%s\n' "$cand"
  done < <(py_helper candidates goals "$CLAIMS_WT/claims" "$translations_dir" "$AGENT_ID" "")
}

main() {
  parse_args "$@"
  require_repo_root
  require_cmd python3

  SESSION_TMP="$(mktemp -d)"
  trap 'rm -rf "$SESSION_TMP"' EXIT

  if [ "$SELF_TEST" -eq 1 ]; then
    require_cmd git  # the push re-entrancy tests use local bare fixtures
    run_self_tests
  fi

  [ "$TRANSLATE_ONLY" -eq 1 ] \
    || die_config "Phase 0 only supports --translate-only (or --self-test)"

  require_cmd git timeout date
  require_unsorry_origin
  if [ -n "$GOAL_FILTER" ]; then
    py_helper is-id "$GOAL_FILTER" \
      || die_config "--goal '$GOAL_FILTER' violates the Id grammar"
  fi

  UNSORRY_MODEL="${UNSORRY_MODEL:-sonnet}"
  UNSORRY_WALL="${UNSORRY_WALL:-1800}"
  [[ "$UNSORRY_WALL" =~ ^[0-9]+$ ]] \
    || die_config "UNSORRY_WALL '$UNSORRY_WALL' is not an integer"
  UNSORRY_TTL="${UNSORRY_TTL:-$(py_helper ttl)}"
  [[ "$UNSORRY_TTL" =~ ^[0-9]+$ ]] \
    || die_config "UNSORRY_TTL '$UNSORRY_TTL' is not an integer"
  UNSORRY_WORKDIR="${UNSORRY_WORKDIR:-$HOME/.unsorry/work}"
  mkdir -p "$UNSORRY_WORKDIR" || die_config "cannot create UNSORRY_WORKDIR '$UNSORRY_WORKDIR'"

  resolve_agent_id
  if [ "$DRY_RUN" -eq 0 ]; then
    require_cmd claude gh
    gh auth status >/dev/null 2>&1 || die_config "gh is not authenticated"
  fi

  log "agent $AGENT_ID starting (model=$UNSORRY_MODEL wall=${UNSORRY_WALL}s ttl=${UNSORRY_TTL}s)"

  declare -A HANDLED=()
  declare -A SWEPT=()
  local overall=0 translations_dir candidates goal cand stmt cycle_failed

  while :; do
    # Step 1 — pull main, refresh the claims worktree.
    sync_repo || { log "repository sync failed"; exit 1; }
    translations_dir="$(main_translations_dir)" || exit 1

    # Step 1b — convergence sweep: janitor work, claims nothing.
    convergence_sweep "$translations_dir" || overall=1

    # Steps 2–3 — enumerate and select.
    candidates="$(select_candidates "$translations_dir")"
    if [ -z "$candidates" ]; then
      log "no claimable goal — nothing to do"
      break
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      goal="$(printf '%s\n' "$candidates" | head -n 1)"
      printf 'dry-run: would claim goal %s (translate; %d candidate(s): %s)\n' \
        "$goal" "$(printf '%s\n' "$candidates" | wc -l)" \
        "$(printf '%s\n' "$candidates" | paste -sd ' ' -)"
      exit 0
    fi

    # Step 4 — claim, moving to the next candidate on collision.
    goal=""
    while IFS= read -r cand; do
      if claim_goal "$cand"; then
        goal="$cand"
        break
      fi
    done <<< "$candidates"
    if [ -z "$goal" ]; then
      log "every candidate collided — nothing claimable this pass"
      break
    fi

    # Steps 5–10 — translate, check in, release.
    cycle_failed=0
    if stmt="$(run_translation "$goal")"; then
      check_in "$goal" "$stmt" || cycle_failed=1
      release_claim "$goal" || cycle_failed=1
    else
      release_claim "$goal" || true
      emit_event translate-failed "$goal"
      log "translation of $goal failed after retry — claim released"
      cycle_failed=1
    fi

    HANDLED[$goal]=1
    if [ "$cycle_failed" -ne 0 ]; then
      overall=1
      [ "$ONCE" -eq 1 ] && exit 1
    fi
    [ "$ONCE" -eq 1 ] && break
  done

  exit "$overall"
}

main "$@"
