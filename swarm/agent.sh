#!/usr/bin/env bash
# swarm/agent.sh — swarm agent loop (ADR-006, ADR-007, SPEC-007-A).
# Phase-0 translate-only mode + Phase-1 prove mode.
#
# Usage:
#   ./swarm/agent.sh --translate-only [--once] [--goal <id>] [--dry-run]
#   ./swarm/agent.sh --prove [--once] [--goal <id>] [--provider claude|codex] [--dry-run]
#   ./swarm/agent.sh --prove-local [--goal <id>] [--provider claude|codex|gemini|openai]
#   ./swarm/agent.sh --dispatch-queue [--once] [--dry-run]
#   ./swarm/agent.sh --self-test
#
# Must be run from the repository root. Swarm modes additionally require `main`
# checked out and synchronized exactly to origin/main. Candidate selection reads
# the checkout while all PR worktrees branch from origin/main, so accepting
# another branch or local-only main commits would mix two queue snapshots.
# `--prove-local` deliberately uses local HEAD instead. Record parsing, claim
# liveness, the claim TTL and the translate claim cap all come from tools/gate_b
# (the same code Gate B and the reaper use) — this script never reimplements
# them.
#
# Exit codes: 0 success or nothing-to-do · 1 cycle failure · 2 configuration
# error (not at repo root, missing tools, unauthenticated gh) · 3
# infrastructure failure — the selected proof CLI cannot run (quota, auth,
# network; the agent stops without applying any queue penalty, ADR-016), or a
# git fetch on the shared object store could not complete after retries
# (ADR-059, #983). Either way supervise.sh backs off and reschedules.
#
# shellcheck disable=SC2317,SC2329  # test_* functions are invoked indirectly ("$t")
set -euo pipefail

# ----------------------------------------------------------------- constants

PROTOCOL_FILE="swarm/protocol.aisp"
TRANSLATE_PROMPT_FILE="swarm/prompts/translate.md"
EVIDENCE_LINE="⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩"

# Shared bootstrap for the Lean build tool: `ensure_lake` puts elan on PATH and
# installs it if `lake` is missing (ADR-100, SPEC-100-A). Sourced relative to this
# script so it resolves regardless of the caller's cwd.
# shellcheck source=swarm/lib/ensure_lake.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/ensure_lake.sh"

# ------------------------------------------------------------------- logging

log() {
  printf '[agent.sh] %s\n' "$*" >&2
}

die_config() {
  printf '[agent.sh] config error: %s\n' "$*" >&2
  exit 2
}

# ADR-059: the infrastructure-failure counterpart to die_config, for the
# pre-loop startup path (relocation) where there is no cycle to return a code
# up through. Exit 3 routes supervise.sh to its ADR-016 exponential backoff.
die_infra() {
  printf '[agent.sh] infrastructure failure: %s\n' "$*" >&2
  exit 3
}

usage() {
  cat <<'EOF'
Usage:
  ./swarm/agent.sh --translate-only [--once] [--goal <id>] [--dry-run]
  ./swarm/agent.sh --prove [--fork] [--once] [--goal <id>] [--provider claude|codex|gemini|openai] [-pi [<model>]] [--dry-run]
  ./swarm/agent.sh --prove-local [--goal <id>] [--provider claude|codex|gemini|openai] [-pi [<model>]]
  ./swarm/agent.sh --dispatch-queue [--once] [--dry-run]
  ./swarm/agent.sh --self-test

Flags:
  --translate-only  Phase-0 mode: only phase≡translate goals are candidates
  --prove           Phase-1 mode: only phase≡prove, unproved goals are candidates
  --prove-local     Prove one goal from local HEAD without any remote, claim,
                    PR, or GitHub operation; auto-selects unless --goal is set
  --dispatch-queue  Open queued proof branches as PRs when the ADR-058
                    submission governor admits more verifier work
  --fork            Fork-native mode (ADR-068): prove with no upstream write
                    access. Claimless (no claims branch), submits each proof as a
                    cross-repo PR the upstream re-verifies + auto-merges. Auto-
                    detected when origin is a fork of UNSORRY_UPSTREAM; --fork
                    forces it. Implies PR submit mode
  --provider <name> Proof provider: claude (default), codex, gemini, or openai
  --once            Run exactly one cycle then exit
  --goal <id>       Restrict or override automatic selection to one goal
  --dry-run         Stop after selection: print the would-be claim, claim nothing
  -pi [<model>]     Use pi-coder's ~/.pi/agent/models.json: resolve the model
                    name/id (the optional <model> arg, else UNSORRY_MODEL) to its
                    OpenAI-compatible endpoint+key and prove with it. Forces
                    --provider openai (ADR-025)
  --self-test       Run the built-in hermetic tests and exit (0 green / 1 red)

Requirement:
  Run from a checkout of the repository. By default (ADR-042) swarm modes
  relocate into a dedicated per-agent worktree pinned to origin/main, so the
  launch dir is left untouched (edit proofs/the harness there freely) and
  concurrent agents do not share a tree; the launch dir need not be on main.
  With UNSORRY_NO_ISOLATE=1 the agent runs in place and the launch dir must be
  on main and equal to origin/main. --prove-local always tests the caller's
  committed local HEAD in place.

Environment:
  UNSORRY_AGENT_ID  Swarm identity (default: ~/.unsorry/agent-id, created on first run)
  UNSORRY_FORK      Set to 1 to force fork-native mode (ADR-068); otherwise it is
                    auto-detected when origin is a fork of UNSORRY_UPSTREAM
  UNSORRY_UPSTREAM  Canonical repo a fork submits to (default: agenticsnz/unsorry)
  UNSORRY_FORK_SHARDS
                    Fork-mode goal-selection shards K (ADR-076; default 8). Each
                    fork prefers goals in cksum(agent)%K so independent forks pick
                    different goals (advisory; falls through when its slice is dry)
  UNSORRY_SOLVER    GitHub handle credited for verified proofs (default: gh api user)
  UNSORRY_SOLVER_NAME, UNSORRY_SOLVER_EMAIL
                    Override the git commit author/committer the harness uses
                    for its own commits (ADR-029). Default: the authenticated
                    GitHub account's display name and no-reply email
                    (<id>+<login>@users.noreply.github.com), so proofs link to
                    a real profile even when local git config is unset
  UNSORRY_PROVIDER  Provider for --prove or --prove-local (default: claude)
  UNSORRY_MODEL     Model for claude calls (default: fable in --prove, else sonnet; ADR-013)
                    For openai: gpt-4o (default), gpt-4o-mini, o1, o3-mini, etc.;
                    on a custom endpoint (OPENAI_BASE_URL / -pi) any model id
  OPENAI_API_KEY    Required when using openai provider
  OPENAI_BASE_URL   OpenAI-compatible endpoint for local/self-hosted models
                    (Ollama/vLLM/LM Studio/proxy). Bypasses the model allow-list;
                    set by -pi from ~/.pi/agent/models.json (ADR-025)
  UNSORRY_EFFORT    Effort for proof-surface calls (default in --prove: the
                    ADR-015 ladder, attempts climb high→xhigh→max; a set value
                    pins every attempt; else unset; dropped fail-soft when the
                    installed claude lacks --effort)
  UNSORRY_WORKDIR   Claims worktree + metrics.jsonl home (default: ~/.unsorry/work)
  UNSORRY_GOAL_LOCK_DIR
                    Fork-mode goal-lock dir shared by co-located provers so they
                    don't all grind the same goal (ADR-068; default:
                    ~/.unsorry/goal-locks). MUST be a path common to every
                    co-located prover — if they run as different users or with
                    isolated homes, point this at a shared path or the lock is a
                    no-op. Ignored outside fork mode
  UNSORRY_NO_ISOLATE
                    Set to 1 to run the swarm loop in the launch dir instead of
                    relocating into a per-agent worktree (ADR-042). The launch
                    dir must then be on main and equal to origin/main
  UNSORRY_AGENT_WORKTREE
                    Override the per-agent worktree path (ADR-042; default:
                    $UNSORRY_WORKDIR/agent-main-<agent-id>). Reused across cycles
                    so its .lake build cache is paid once. Reset with
                    'git worktree remove --force <path>'
  UNSORRY_LOCAL_WORKTREE
                    Exact worktree path for --prove-local (default: a fresh
                    directory under /tmp)
  UNSORRY_WALL      Wall-clock seconds per claude call (default: 1800)
  UNSORRY_FASTFAIL  Seconds under which a failed claude call is suspected to be
                    an infrastructure failure rather than a real attempt
                    (default: 240; confirmed by a health probe, ADR-016)
  UNSORRY_TTL       Claim TTL seconds (default: tools/gate_b/config.py TTL_SECONDS)
  UNSORRY_ATTEMPTS  Prove build/audit attempts (default: 3 in --prove and
                    --prove-local, one per ADR-015 effort rung; else
                    config.py BUDGET_ATTEMPTS)
  UNSORRY_DECOMPOSE Decompose a goal into sub-lemmas when a prove attempt is
                    exhausted (default: 1; set 0 to demote without decomposing)
  UNSORRY_RECOVERY  ADR-044 idle recovery: when --prove finds no claimable
                    viable goal, re-surface a goal orphaned below τ_v into the
                    normal prove pipeline (retry with accumulated lessons,
                    ADR-024; decompose on failure, ADR-009) instead of going
                    idle (default: 1; set 0 to disable)
  UNSORRY_FETCH_RETRIES
                    Attempts for a `git fetch` on the shared object store before
                    it is called an infrastructure failure (ADR-059, #983;
                    default: 3)
  UNSORRY_FETCH_BACKOFF
                    Base seconds for the exponential backoff between fetch
                    retries (default: 2; doubles per attempt, capped at 30)
  UNSORRY_SUBMIT_MODE
                    Coordinated --prove submit mode: queue pushes a verified
                    proof branch under queued/prove/ without opening a PR
                    (default); pr opens the PR immediately
  UNSORRY_DISPATCH_LIMIT
                    Max queued proof branches --dispatch-queue opens per run
                    (default: 1; --once also limits to one)
  UNSORRY_BATCH_SIZE
                    ADR-107 batch verification: combine up to this many
                    independent queued proof branches into ONE Gate A run so the
                    mathlib env-load is amortised across them (default: 1 = one
                    PR per proof, batching off). A batch is one governor
                    admission; recovery is the batch-recovery-janitor
  UNSORRY_GOVERNOR_WAIT
                    Seconds to sleep before polling again when the governor is
                    closed or no work is available (default: 300; --once exits)
  UNSORRY_SUBMISSION_GOVERNOR
                    Coordinated --prove admission control (default: 1). When
                    enabled, the agent checks open prove PR count and Gate A
                    queue pressure before claiming new prove work. Set 0 only
                    for an operator-approved override
  UNSORRY_SUBMISSION_FREEZE
                    Emergency pause for coordinated --prove submissions
                    (default: 0). Truthy values make the agent exit cleanly
                    before claim/PR-producing work
  UNSORRY_MAX_OPEN_PROVE_PRS
                    Pause coordinated --prove when this many open prove PRs
                    already exist (default: 40; set -1 to disable this limit)
  UNSORRY_MAX_GATE_A_IN_FLIGHT
                    Pause coordinated --prove when queued + in-progress Gate A
                    workflow runs reach this count (default: 8; set -1 to
                    disable this limit)
  UNSORRY_MAX_GOALS_IN_FLIGHT
                    Per-contributor fairness cap: pause claiming new goals when
                    this agent already holds this many goals in flight (its own
                    queued-but-unmerged prove branches), so one fleet cannot
                    queue the whole pool and starve others (default: 25)
  UNSORRY_GOVERNOR_SCAN_LIMIT
                    Max PR/runs rows fetched per governor query (default: 200)
EOF
}

# ----------------------------------------------------------- python helpers
# One inline helper, run from the repo root so `tools` is importable. All
# record parsing, liveness, the TTL and the claim cap are delegated to
# tools.gate_b — DRY with the contract (SPEC-007-A quality bar).

py_helper() {
  python3 - "$@" <<'PY'
import hashlib
import re
import secrets
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


# ── prove-cycle pure helpers (Phase 1, SPEC-007-A) ──────────────────────────
# A prove goal carries no AISP statement — only goals/<id>.lean with a
# `theorem <name> <signature> := by sorry`. The proof goes in a NEW library
# module that re-states the SAME theorem and proves it; the library index is
# keyed by the content address of the goal's Lean statement.


# Lean goal-statement parsing is shared with the Gate A binding check
# (tools/gate_a) via tools/lean_sig.py (DRY).
from tools.lean_sig import (  # noqa: E402
    camel_name,
    foralltype as lean_foralltype,
    open_lines as lean_open_lines,
    statement as lean_statement,
    statement_sha as lean_statement_sha,
    theorem_name as lean_theorem_name,
)


def _proved_goals(library_dir: str) -> set[str]:
    """Goal ids that already have a merged proof: any library/index/<sha>.aisp
    whose `goal≜` names them. The index entry is the authoritative 'proved'
    marker (a goal is proved iff it has an index entry)."""
    proved: set[str] = set()
    index_dir = Path(library_dir) / "index"
    if index_dir.is_dir():
        for path in sorted(index_dir.glob("*.aisp")):
            record = parse_record(path.read_text(encoding="utf-8"))
            goal = record.fields.get("goal")
            if goal:
                proved.add(goal)
    return proved


def _affinity(record) -> int:
    """Goal affinity (⟦Γ:Affinity⟧, ADR-010). Absent or garbled ⇒ 0 — the
    score is strictly advisory queue state, never trust-bearing, so a missing
    or malformed value must degrade to neutral, never crash selection."""
    raw = record.fields.get("aff")
    if raw is None:
        return 0
    try:
        return int(raw.strip())
    except ValueError:
        return 0


def _deps(record) -> list[str]:
    """Goal ids in deps≜⟨a,b,…⟩ (empty for ⟨⟩ or absent)."""
    raw = record.fields.get("deps", "").strip()
    inner = raw.strip("⟨⟩").strip()
    return [d.strip() for d in inner.split(",") if d.strip()] if inner else []


def _gap(record, proved: set) -> int:
    """gap ≜ |deps(g) ∖ proved| — a goal's distance to the merged library
    (ADR-010). Fewer unproved dependencies ⇒ closer ⇒ preferred."""
    return sum(1 for dep in _deps(record) if dep not in proved)


def _rank(candidates, proved: set) -> list[str]:
    """Rank claimable goals (ADR-010 / SPEC-010-A): drop the non-viable
    (affinity < τ_v — awaiting re-decomposition), then order by
    (affinity desc, gap asc, id asc). ``candidates`` is a list of
    (goal_id, record). The lexicographic id tie-break keeps trials
    reproducible."""
    scored = []
    for goal, record in candidates:
        affinity = _affinity(record)
        if affinity < config.TAU_V:
            continue  # below viability: skipped, re-queued for re-decomposition
        scored.append((-affinity, _gap(record, proved), goal))
    scored.sort()
    return [goal for _, _, goal in scored]


def cmd_aff_bump(args):
    """aff-bump <goal.aisp> <delta> [<floor>] — add <delta> to the goal's aff
    field, inserting ``aff≜<delta>`` after the sha≜ line if none exists yet
    (⟦Γ:Affinity⟧ update; +1 on merge, -10 on a failed attempt). An optional
    <floor> clamps the result (``new = max(aff+delta, floor)``) — the ADR-034
    recompose demote passes τ_v so a recoverable parent is never buried below
    viability (#388)."""
    path = Path(args[0])
    delta = int(args[1])
    record = parse_record(path.read_text(encoding="utf-8"))
    new = _affinity(record) + delta
    if len(args) > 2:
        new = max(new, int(args[2]))
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    out = []
    hit = 0
    for line in lines:
        stripped = line.lstrip()
        indent = line[: len(line) - len(stripped)]
        newline = "\n" if line.endswith("\n") else ""
        if stripped.rstrip("\n").startswith("aff≜"):
            hit += 1
            out.append(f"{indent}aff≜{new}{newline}")
        else:
            out.append(line)
    if hit == 0:  # insert after the sha≜ line
        rebuilt = []
        inserted = False
        for line in out:
            rebuilt.append(line)
            stripped = line.lstrip()
            if not inserted and stripped.rstrip("\n").startswith("sha≜"):
                indent = line[: len(line) - len(stripped)]
                rebuilt.append(f"{indent}aff≜{new}\n")
                inserted = True
        if not inserted:
            sys.exit(f"py_helper: {path} has no sha≜ line to anchor aff")
        out = rebuilt
    elif hit > 1:
        sys.exit(f"py_helper: {path} has {hit} aff≜ lines, expected ≤1")
    path.write_text("".join(out), encoding="utf-8")


def cmd_camel_name(args):
    """camel-name <goal-id> — print the CamelCase module name."""
    print(camel_name(args[0]))


def cmd_lean_stmt(args):
    """lean-stmt <goal.lean> — print the canonical Lean statement string."""
    print(lean_statement(Path(args[0]).read_text(encoding="utf-8")))


def cmd_lean_name(args):
    """lean-name <goal.lean> — print the declared theorem/lemma name."""
    print(lean_theorem_name(Path(args[0]).read_text(encoding="utf-8")))


def cmd_lean_sha(args):
    """lean-sha <goal.lean> — print the content address of the statement."""
    print(lean_statement_sha(Path(args[0]).read_text(encoding="utf-8")))


def cmd_lean_foralltype(args):
    """lean-foralltype <goal.lean> — print the goal's ∀-closed type (ADR-011)."""
    print(lean_foralltype(Path(args[0]).read_text(encoding="utf-8")))


def cmd_lean_opens(args):
    """lean-opens <goal.lean> — print the goal's top-level `open` commands,
    one per line (ADR-011: they travel with the type into the binding)."""
    for line in lean_open_lines(Path(args[0]).read_text(encoding="utf-8")):
        print(line)


def cmd_prove_candidates(args):
    """prove-candidates <goals-dir> <claims-dir> <library-dir> <agent> [<at>] [--force <goal>]

    SPEC-007-A prove step 2: goals with phase≡prove, status≡open, fewer than
    PROVE_CLAIM_CAP live claims by distinct other agents, no live claim by
    self, and NOT already proved (no library/index entry). Ordered by
    affinity-weighted, gap-based ranking (ADR-010 / SPEC-010-A).

    ``--force <goal>`` (set when the operator named one via --goal): that goal
    is surfaced even if ranking would drop it below the viability floor — an
    explicit --goal overrides the "awaiting re-decomposition" default. It is
    only forced if it still cleared the hard claimability filter above, so a
    proved, self-claimed, capped, blocked, or non-prove goal is never forced."""
    force = None
    if "--force" in args:
        i = args.index("--force")
        force = args[i + 1] if i + 1 < len(args) else None
        args = args[:i] + args[i + 2 :]
    goals_dir, claims_dir, library_dir, agent = args[:4]
    now = _now(args[4] if len(args) > 4 else "")
    proved = _proved_goals(library_dir)
    survivors = []
    for path in sorted(Path(goals_dir).glob("*.aisp")):
        goal = path.stem
        record = parse_record(path.read_text(encoding="utf-8"))
        if record.fields.get("phase") != "prove":
            continue
        if record.fields.get("status") != "open":
            continue
        if goal in proved:
            continue
        others, live_self = _live_other_agents(claims_dir, goal, agent, now)
        if live_self or len(others) >= config.PROVE_CLAIM_CAP:
            continue
        survivors.append((goal, record))
    ranked = _rank(survivors, proved)
    if force and force not in ranked and any(g == force for g, _ in survivors):
        print(force)  # explicit --goal overrides the viability floor only
    for goal in ranked:
        print(goal)


def cmd_recovery_candidates(args):
    """recovery-candidates <goals-dir> <claims-dir> <library-dir> <agent> [<at>]

    ADR-044 idle recovery pool — the inverse of ``prove-candidates``: claimable
    prove goals parked *below* the viability floor (affinity < TAU_V). A failed
    direct prove demotes a goal below TAU_V, where ``_rank`` can never surface it
    again (ADR-010); such a goal is orphaned — its accumulated ⟦Δ:Lesson⟧ history
    (ADR-024) is never reused and nothing retries it. This lists those orphans so
    the idle sweep can re-surface one into the SAME ``prove_goal`` pipeline, which
    retries with the lessons injected (ADR-024) and decomposes on failure
    (ADR-009).

    Same hard claimability filter as ``prove-candidates`` (phase≡prove,
    status≡open, NOT proved, fewer than PROVE_CLAIM_CAP live other-agent claims,
    no live self-claim), but keeps ONLY affinity < TAU_V, ordered least-buried
    first (affinity desc, then id) so the most recoverable goals go first."""
    goals_dir, claims_dir, library_dir, agent = args[:4]
    now = _now(args[4] if len(args) > 4 else "")
    proved = _proved_goals(library_dir)
    out = []
    for path in sorted(Path(goals_dir).glob("*.aisp")):
        goal = path.stem
        record = parse_record(path.read_text(encoding="utf-8"))
        if record.fields.get("phase") != "prove":
            continue
        if record.fields.get("status") != "open":
            continue
        if goal in proved:
            continue
        if _affinity(record) >= config.TAU_V:
            continue  # still viable — the normal prove queue handles it
        others, live_self = _live_other_agents(claims_dir, goal, agent, now)
        if live_self or len(others) >= config.PROVE_CLAIM_CAP:
            continue
        out.append((_affinity(record), goal))
    out.sort(key=lambda t: (-t[0], t[1]))
    for _, goal in out:
        print(goal)


def cmd_prove_claimable(args):
    """prove-claimable <claims-dir> <goal> <agent> [<at>]

    Post-rebase recheck (prove step 4): exit 0 while the goal still has fewer
    live claims by distinct other agents than PROVE_CLAIM_CAP, 1 otherwise."""
    claims_dir, goal, agent = args[:3]
    now = _now(args[3] if len(args) > 3 else "")
    others, _ = _live_other_agents(claims_dir, goal, agent, now)
    sys.exit(0 if len(others) < config.PROVE_CLAIM_CAP else 1)


def cmd_render_index(args):
    """render-index <sha> <goal> <name> [--solver S --agent A --provider P
    --model M --effort E --attempts N --solve-s N] — print an index entry
    (SPEC-007-A prove step on success). The statement is NOT embedded: it
    lives only in goals/<goal>.lean (the record grammar reserves {} for block
    delimiters and Lean statements contain braces); the sha is its content
    address and Gate B recomputes it from the goal file. Tags and metrics
    start empty (the affinity machine fills `use`/`aff` later; tags are
    curated by humans). Optional proof provenance is additive so historical
    index entries remain valid."""
    sha, goal, name = args[:3]
    provenance = {}
    rest = args[3:]
    for i, token in enumerate(rest):
        if token.startswith("--") and i + 1 < len(rest):
            provenance[token[2:]] = rest[i + 1]
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    print(f"𝔸5.1.lemma.{sha[:12]}@{today}")
    print("γ≔unsorry.lemma.index")
    print(f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{goal}; name≜{name}}}")
    print(f"⟦Σ:Source⟧{{src≜goals/{goal}.lean}}")
    print("⟦Γ:Tags⟧{tags≜⟨⟩}")
    print("⟦Λ:Meta⟧{use≜0; aff≜0}")
    if all(provenance.get(key) for key in ("solver", "agent", "provider")):
        fields = [
            f"solver≜{provenance['solver']}",
            f"agent≜{provenance['agent']}",
            f"provider≜{provenance['provider']}",
        ]
        for key in ("model", "effort", "attempts", "solve-s"):
            if provenance.get(key):
                field = "solve_s" if key == "solve-s" else key
                fields.append(f"{field}≜{provenance[key]}")
        print(f"⟦Π:Provenance⟧{{{'; '.join(fields)}}}")
    print("⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩")


def cmd_run_id(_args):
    moment = datetime.now(timezone.utc).strftime("%Y%m%dt%H%M%S%fz")
    print(f"{moment}-{secrets.token_hex(4)}")


#: AISP block/field delimiters and the quote char that must never appear inside
#: a lesson signature: they would break record parsing or inflate the GB009
#: quoted-prose density (ADR-024).
_LESSON_STRIP = str.maketrans({c: None for c in "{};≜⟦⟧⟨⟩\""})


def _lesson_signature(raw: str) -> str:
    """Distil raw verifier output into one bounded, AISP-legal line (ADR-024).

    Whitespace (including newlines) collapses to single spaces and the AISP
    delimiters plus the quote char are removed, so the signature lives unquoted
    inside ⟦Δ:Lesson⟧ without breaking the record grammar or counting toward
    quoted-prose density. Lean error content that is not a delimiter (⊢, →, =,
    identifiers) is preserved. Truncated to config.LESSON_SIG_MAX."""
    collapsed = re.sub(r"\s+", " ", raw.translate(_LESSON_STRIP)).strip()
    return collapsed[: config.LESSON_SIG_MAX]


def cmd_lesson_sig(args):
    """lesson-sig <raw> — print the sanitised single-line lesson signature of
    the raw verifier text in argv[0] (ADR-024). Passed as an argument because
    the py_helper heredoc occupies stdin."""
    print(_lesson_signature(args[0] if args else ""))


def cmd_render_run(args):
    """render-run <run-id> <goal> <agent> <outcome> <solver> <provider>
    <attempts> <solve-s> <sha-or-empty>
    [--model M --effort E --lesson RAW --lessons-used N] — print one
    append-only terminal proof-run fact. Difficulty and current goal state are
    joined from goals/ by analytics instead of copied into every run. A
    non-proved run may carry a bounded ⟦Δ:Lesson⟧ failure signature and a
    lessons≜<n> count of prior lessons injected into it (ADR-024)."""
    run_id, goal, agent, outcome, solver, provider, attempts, solve_s, sha = args[:9]
    optional = {}
    rest = args[9:]
    for i, token in enumerate(rest):
        if token.startswith("--") and i + 1 < len(rest):
            optional[token[2:]] = rest[i + 1]
    now = datetime.now(timezone.utc)
    print(f"𝔸5.1.run.{goal}.{agent}.{run_id}@{now:%Y-%m-%d}")
    print("γ≔unsorry.proof.run")
    print(
        f"⟦Ω:Run⟧{{id≜{run_id}; goal≜{goal}; agent≜{agent}; "
        f"outcome≜{outcome}}}"
    )
    provenance = [f"solver≜{solver}", f"provider≜{provider}"]
    for key in ("model", "effort"):
        if optional.get(key):
            provenance.append(f"{key}≜{optional[key]}")
    print(f"⟦Π:Provenance⟧{{{'; '.join(provenance)}}}")
    # ⟦Γ⟧ is one of the five canonical AISP-5.1 blocks (Ω/Σ/Γ/Λ/Ε). Carrying the
    # goal link here keeps a proof-run record valid under the generic upstream
    # validator (aisp-validator, ADR-003), which rejects a record missing Γ — the
    # advisory cross-check stays clean instead of flagging every run.
    print(f"⟦Γ:Goal⟧{{goal≜{goal}}}")
    metrics = [f"attempts≜{attempts}", f"solve_s≜{solve_s}", f"ended≜{format_utc_z(now)}"]
    used = optional.get("lessons-used")
    if used not in (None, ""):
        metrics.append(f"lessons≜{used}")
    print(f"⟦Λ:Metrics⟧{{{'; '.join(metrics)}}}")
    print(f"⟦Σ:Artifact⟧{{sha≜{sha or '∅'}}}")
    sig = _lesson_signature(optional.get("lesson", ""))
    if outcome != "proved" and sig:
        print(f"⟦Δ:Lesson⟧{{sig≜{sig}}}")
    print("⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩")


def cmd_ttl(_args):
    print(config.TTL_SECONDS)


def cmd_attempts(_args):
    print(config.BUDGET_ATTEMPTS)


def cmd_aff_delta(args):
    """aff-delta merge|fail — print the affinity update for that event
    (⟦Γ:Affinity⟧; +1 / -10), so the shell never hardcodes the constant."""
    print(config.AFFINITY_MERGE if args[0] == "merge" else config.AFFINITY_FAIL)


def cmd_affinity(args):
    """affinity <goal.aisp> — print the goal's current advisory affinity."""
    path = Path(args[0])
    record = parse_record(path.read_text(encoding="utf-8"))
    print(_affinity(record))


def cmd_tau_v(_args):
    """tau-v — print the viability floor TAU_V, so the shell never hardcodes -5
    (used by the ADR-034 recompose demote as the floor)."""
    print(config.TAU_V)


def cmd_max_decomp(args):
    """max-decomp subs|depth — the decomposition fan-out / depth caps (ADR-009)."""
    print(config.MAX_DECOMP_SUBS if args[0] == "subs" else config.MAX_DECOMP_DEPTH)


def _goal_depth(record) -> int:
    """Decomposition depth of a goal (advisory ⟦Λ:Artifact⟧ depth field; 0 if
    absent/garbled). Seeded goals are depth 0; a sub is parent depth + 1."""
    raw = record.fields.get("depth")
    if raw is None:
        return 0
    try:
        return max(0, int(raw.strip()))
    except ValueError:
        return 0


def cmd_goal_depth(args):
    """goal-depth <goal.aisp> — print the goal's decomposition depth."""
    print(_goal_depth(parse_record(Path(args[0]).read_text(encoding="utf-8"))))


def _subscript(n: int) -> str:
    return str(n).translate(str.maketrans("0123456789", "₀₁₂₃₄₅₆₇₈₉"))


def cmd_render_goal(args):
    """render-goal <id> <status> <src> <lean-path> <depth> — a prove goal
    record (the prove-phase shape the seed uses), with a depth field so
    decomposition can cap recursion."""
    gid, status, src, lean, depth = args[:5]
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    print(f"𝔸5.1.goal.{gid}@{today}")
    print("γ≔unsorry.goal")
    print("⟦Ω:Goal⟧{")
    print(f"  id≜{gid}")
    print("  phase≜prove")
    print(f"  status≜{status}")
    print("  difficulty≜1")
    print("}")
    print("⟦Σ:Source⟧{")
    print(f"  src≜{src}")
    print("}")
    print("⟦Γ:Deps⟧{")
    print("  deps≜⟨⟩")
    print("}")
    print("⟦Λ:Artifact⟧{")
    print(f"  lean≜{lean}")
    print("  sha≜∅")
    print(f"  depth≜{depth}")
    print("}")
    print("⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩")


def cmd_render_decomp(args):
    """render-decomp <parent> <agent> <sub-id> <sub-sha> [<sub-id> <sub-sha>…]
    — a SPEC-003-C decomposition record. Subs reference their statement by
    content address (sha of the statement in goals/<id>.lean): the record
    grammar reserves {} for block delimiters and real Lean statements contain
    braces (Finset literals). Each sub gets an edge Post(subN) ⊆ Pre(parent):
    every sub is a prerequisite of the parent (a DAG; the parent still closes
    only through the kernel)."""
    parent, agent = args[0], args[1]
    pairs = args[2:]
    subs = [(pairs[i], pairs[i + 1]) for i in range(0, len(pairs), 2)]
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    print(f"𝔸5.1.decomp.{parent}.{agent}@{today}")
    print("γ≔unsorry.decomposition")
    print(f"⟦Ω:Decomp⟧{{parent≜{parent}; agent≜{agent}}}")
    print("⟦Σ:Subs⟧{")
    for i, (sub_id, sha) in enumerate(subs, 1):
        print(f"  sub{_subscript(i)}≜⟨id≜{sub_id},sha≜{sha}⟩")
    print("}")
    print("⟦Γ:Edges⟧{")
    edges = "; ".join(
        f"Post(sub{_subscript(i)})⊆Pre(parent)" for i in range(1, len(subs) + 1)
    )
    print(f"  {edges}")
    print("}")
    print("⟦Λ:Requeue⟧{∀s∈subs:goal(s)≫status≔open}")
    print("⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩")


def cmd_proved_deps(args):
    """proved-deps <goal.aisp> <goals-dir> <library-dir> <decompositions-dir>
    — ADR-014 dependency reuse. For each PROVED dependency of the goal —
    its deps≜⟨…⟩ entries plus the subs of any decomposition record naming it
    as parent (a recomposing parent reuses its own sub-lemmas) — print one
    line `Unsorry.<Module>\\t<theorem-name>\\t<statement>`. The declaring
    module is located by content (grandfathered lemmas live in Basic.lean, so
    it is not always camel(goal)). Unproved deps are not surfaced; the gap
    ranking (ADR-010) already routes those first."""
    goal_path, goals_dir, library_dir, decomp_dir = args[:4]
    record = parse_record(Path(goal_path).read_text(encoding="utf-8"))
    goal_id = Path(goal_path).stem
    wanted = list(_deps(record))
    ddir = Path(decomp_dir)
    if ddir.is_dir():
        for dpath in sorted(ddir.glob(f"{goal_id}.*.aisp")):
            for m in re.finditer(r"sub[^≜\s;]*≜⟨id≜([A-Za-z0-9-]+)", dpath.read_text(encoding="utf-8")):
                if m.group(1) not in wanted:
                    wanted.append(m.group(1))
    if not wanted:
        return
    name_by_goal: dict = {}
    index_dir = Path(library_dir) / "index"
    if index_dir.is_dir():
        for ipath in sorted(index_dir.glob("*.aisp")):
            text = ipath.read_text(encoding="utf-8")
            g = re.search(r"goal≜([A-Za-z0-9-]+)", text)
            n = re.search(r"name≜([A-Za-z0-9_']+)", text)
            if g and n:
                name_by_goal[g.group(1)] = n.group(1)
    modules = sorted((Path(library_dir) / "Unsorry").glob("*.lean"))
    for dep in wanted:
        name = name_by_goal.get(dep)
        if not name:
            continue  # not proved yet
        module = next(
            (p.stem for p in modules
             if re.search(rf"^theorem {re.escape(name)}\b",
                          p.read_text(encoding="utf-8"), re.MULTILINE)),
            None,
        )
        if module is None:
            continue
        stmt = ""
        lean = Path(goals_dir) / f"{dep}.lean"
        if lean.is_file():
            stmt = lean_statement(lean.read_text(encoding="utf-8"))
        print(f"Unsorry.{module}\t{name}\t{stmt}")


def cmd_prove_lessons(args):
    """prove-lessons <goal> <proof-runs-dir> [<cap>] — ADR-024 lesson reuse.
    Print up to <cap> (default config.LESSON_PROMPT_CAP) prior failure
    signatures for the goal, most recent first and de-duplicated, one per line.
    Only failed and decomposed runs carrying a non-empty ⟦Δ:Lesson⟧ sig count;
    proved runs never carry one. Advisory prompt context, never a trust input."""
    goal = args[0]
    runs_dir = Path(args[1])
    cap = int(args[2]) if len(args) > 2 and args[2] else config.LESSON_PROMPT_CAP
    if not runs_dir.is_dir():
        return
    entries = []
    for path in sorted(runs_dir.glob(f"{goal}.*.aisp")):
        record = parse_record(path.read_text(encoding="utf-8"))
        if record.fields.get("goal") != goal:
            continue
        if record.fields.get("outcome") not in ("failed", "decomposed"):
            continue
        sig = record.fields.get("sig", "").strip()
        if not sig:
            continue
        entries.append((record.fields.get("ended", ""), sig))
    # ended is ISO-8601 UTC, so lexicographic desc == most-recent-first.
    entries.sort(key=lambda e: e[0], reverse=True)
    seen: set = set()
    shown = 0
    for _, sig in entries:
        if sig in seen:
            continue
        seen.add(sig)
        print(sig)
        shown += 1
        if shown >= cap:
            break


def cmd_has_decomposition(args):
    """has-decomposition <goal> <decompositions-dir> — exit 0 if a decomposition
    record already names <goal> as its parent, else 1. ADR-009 idempotency: a goal
    is decomposed at most once. Re-decomposing a goal whose sub-lemmas are already
    proved overwrites their goal records back to open/sha\u2254\u2205 (the #364 euclid
    regression), so decompose_goal refuses when this returns 0."""
    goal, decomp_dir = args[0], args[1]
    ddir = Path(decomp_dir)
    if ddir.is_dir():
        for path in ddir.glob("*.aisp"):
            record = parse_record(path.read_text(encoding="utf-8"))
            if record.fields.get("parent") == goal:
                sys.exit(0)
    sys.exit(1)


def _decomp_subs(decomp_dir: str) -> dict:
    """Map each decomposition parent to the set of its sub-lemma ids
    (the ⟦Σ:Subs⟧ block's `id≜…`), unioned across all of its records."""
    parents: dict = {}
    ddir = Path(decomp_dir)
    if ddir.is_dir():
        for path in sorted(ddir.glob("*.aisp")):
            record = parse_record(path.read_text(encoding="utf-8"))
            parent = record.fields.get("parent")
            if not parent:
                continue
            subs_block = record.block("Σ")
            ids = (
                set(re.findall(r"id≜([^,⟩\s]+)", subs_block.body))
                if subs_block
                else set()
            )
            parents.setdefault(parent, set()).update(ids)
    return parents


def cmd_unblockable(args):
    """unblockable <goals-dir> <decompositions-dir> <library-dir> — list blocked
    parent goals whose decomposition's sub-lemmas are ALL proved, so the parent
    can be re-opened (ADR-009). One goal id per line, lexicographic."""
    goals_dir, decomp_dir, library_dir = args[:3]
    proved = _proved_goals(library_dir)
    parents = _decomp_subs(decomp_dir)
    for path in sorted(Path(goals_dir).glob("*.aisp")):
        goal = path.stem
        record = parse_record(path.read_text(encoding="utf-8"))
        if record.fields.get("status") != "blocked":
            continue
        subs = parents.get(goal)
        if subs and subs <= proved:
            print(goal)


def cmd_recompose_candidate(args):
    """recompose-candidate <goal> <decompositions-dir> <library-dir> — exit 0 iff
    <goal> has a decomposition record whose sub-lemmas are ALL proved. A failed
    prove on such a goal is a RECOMPOSE attempt (not a fresh prove): the #368
    idempotency guard won't re-decompose it, so it must not be demoted below τ_v
    (ADR-034 / #388). Unlike `unblockable` this ignores the goal's status — the
    parent is `open` by recompose time, not `blocked`."""
    goal, decomp_dir, library_dir = args[:3]
    proved = _proved_goals(library_dir)
    subs = _decomp_subs(decomp_dir).get(goal)
    sys.exit(0 if (subs and subs <= proved) else 1)


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
    Ordered by affinity-weighted, gap-based ranking (ADR-010 / SPEC-010-A);
    translate goals carry no deps and start at affinity 0, so the order
    degenerates to lexicographic on a flat backlog.
    """
    goals_dir, claims_dir, translations_dir, agent = args[:4]
    now = _now(args[4] if len(args) > 4 else "")
    survivors = []
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
        survivors.append((goal, record))
    for goal in _rank(survivors, set()):
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
    "attempts": cmd_attempts,
    "now": cmd_now,
    "is-id": cmd_is_id,
    "candidates": cmd_candidates,
    "sweep": cmd_sweep,
    "claimable": cmd_claimable,
    "rewrite-goal": cmd_rewrite_goal,
    "aff-bump": cmd_aff_bump,
    "aff-delta": cmd_aff_delta,
    "affinity": cmd_affinity,
    "tau-v": cmd_tau_v,
    "max-decomp": cmd_max_decomp,
    "goal-depth": cmd_goal_depth,
    "render-goal": cmd_render_goal,
    "render-decomp": cmd_render_decomp,
    "proved-deps": cmd_proved_deps,
    "prove-lessons": cmd_prove_lessons,
    "lesson-sig": cmd_lesson_sig,
    "has-decomposition": cmd_has_decomposition,
    "unblockable": cmd_unblockable,
    "recompose-candidate": cmd_recompose_candidate,
    "camel-name": cmd_camel_name,
    "lean-stmt": cmd_lean_stmt,
    "lean-name": cmd_lean_name,
    "lean-sha": cmd_lean_sha,
    "lean-foralltype": cmd_lean_foralltype,
    "lean-opens": cmd_lean_opens,
    "prove-candidates": cmd_prove_candidates,
    "recovery-candidates": cmd_recovery_candidates,
    "prove-claimable": cmd_prove_claimable,
    "render-index": cmd_render_index,
    "run-id": cmd_run_id,
    "render-run": cmd_render_run,
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
# Normalised short hostname used as the agent-id prefix. Factored out so the
# generator and the copied-identity self-heal (resolve_agent_id) agree exactly.
local_host() {
  local host
  host="$(hostname -s 2>/dev/null || hostname)"
  host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9-' '-' | tr -s '-' | sed -e 's/^-*//' -e 's/-*$//')"
  [ -n "$host" ] || host="agent"
  printf '%s' "$host"
}

generate_agent_id() {
  local hex
  hex="$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
  printf '%s-%s\n' "$(local_host)" "$hex"
}

# Pure: does <id> look like an auto-generated id for <host>? Used to detect a
# COPIED ~/.unsorry/agent-id (one generated on another machine). Only ids in the
# generated `<host>-<4 hex>` shape are judged; a custom-shaped id (suffix not
# 4 hex) is treated as a deliberate operator choice and left alone. Returns 0
# (local / leave it) or 1 (foreign / regenerate).
agent_id_host_matches() {
  local id="$1" host="$2" suffix="${1##*-}"
  case "$suffix" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
    *) return 0 ;;
  esac
  [ "${id%-*}" = "$host" ]
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

queued_prove_branch() {
  local goal="$1" hex
  hex="$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n')" || return 1
  printf 'queued/prove/%s/%s-%s\n' "$goal" "$AGENT_ID" "$hex"
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
    # Self-heal a COPIED identity: the default id encodes this host, so a persisted
    # id whose host-prefix is not this machine's was generated elsewhere (a cloned
    # ~/.unsorry/agent-id from someone's setup). Sharing one swarm id mis-credits
    # proofs and collides on claims, so regenerate a local one. An explicitly
    # EXPORTED UNSORRY_AGENT_ID is honoured above and never auto-changed.
    if ! agent_id_host_matches "$id" "$(local_host)"; then
      local fresh; fresh="$(generate_agent_id)"
      log "agent identity '$id' was generated on another machine (this host is '$(local_host)') — regenerating '$fresh' (copied ~/.unsorry/agent-id; export UNSORRY_AGENT_ID to override)"
      id="$fresh"
      printf '%s\n' "$id" > "$id_file"
    fi
  else
    id="$(generate_agent_id)"
    mkdir -p "$(dirname "$id_file")"
    printf '%s\n' "$id" > "$id_file"
    log "created agent identity $id at $id_file"
  fi
  py_helper is-id "$id" || die_config "agent id '$id' violates the Id grammar"
  AGENT_ID="$id"
}

resolve_solver() {
  local solver="${UNSORRY_SOLVER:-}"
  if [ -z "$solver" ]; then
    solver="$(gh api user --jq .login 2>/dev/null)" \
      || die_config "cannot resolve GitHub solver handle; set UNSORRY_SOLVER"
  fi
  [[ "$solver" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$ ]] \
    || die_config "UNSORRY_SOLVER '$solver' is not a valid GitHub handle"
  SOLVER="$solver"
}

# Credit-integrity guard (proof attribution). resolve_solver trusts UNSORRY_SOLVER
# verbatim, so a config that hard-codes someone else's handle credits THEM for
# every proof this machine produces — observed in practice as several contributors
# funnelling leaderboard credit to one handle via a shared config. This is the
# universal prover chokepoint: run.sh guards before launch, but supervise.sh and a
# direct agent.sh call do not — and it re-runs on every #428 re-exec, so a freshly
# updated harness enforces it even on a long-lived loop. Pure decision (no I/O),
# exercised hermetically by --self-test; echoes one of ok | ack | block | unknown.
#   solver: resolved $SOLVER (resolve_solver already validated it non-empty)
#   login : gh-resolved login (empty -> unknown; cannot compare, e.g. offline)
#   ack   : $UNSORRY_SOLVER_OK (truthy -> a mismatch is a deliberate override)
solver_credit_decision() {
  local solver="$1" login="$2" ack="$3"
  [ -z "$login" ] && { echo unknown; return; }
  [ "${solver,,}" = "${login,,}" ] && { echo ok; return; }
  case "$ack" in
    1|true|TRUE|yes|YES|on|ON) echo ack ;;
    *) echo block ;;
  esac
}

# Resolve the login and act on the decision before any proving. A `block` is a
# configuration error (exit 2 → supervise.sh treats it as fatal, no retry loop),
# so a mis-credited prover never silently runs.
guard_solver_credit() {
  local login decision
  login="$(gh api user --jq .login 2>/dev/null || true)"
  decision="$(solver_credit_decision "$SOLVER" "$login" "${UNSORRY_SOLVER_OK:-}")"
  case "$decision" in
    ok) : ;;
    unknown) log "WARNING: could not resolve your GitHub login (offline / gh not authenticated) — proof credit unverified; proofs will be credited to '$SOLVER'." ;;
    ack) log "WARNING: proofs will be credited to '$SOLVER', NOT your GitHub login '$login' (UNSORRY_SOLVER_OK=1 — deliberate override)." ;;
    block) die_config "proof credit would go to '$SOLVER', but your GitHub account is '$login' — every proof this machine produces would be mis-credited on the leaderboard, not credited to you. Fix: export UNSORRY_SOLVER=$login (or unset it to default to your login). Deliberately proving under another handle, e.g. an org? export UNSORRY_SOLVER_OK=1." ;;
  esac
}

# ADR-029 / SPEC-029-A: author the harness's own commits (proof PRs, claims,
# telemetry) as the authenticated GitHub account so verified work links to a
# real profile regardless of the operator's local git config. A fresh machine
# often carries git's "Your Name <you@example.com>" placeholder, which GitHub
# cannot attribute; the AISP `solver≜` field is still correct (it reads
# `gh api user`), but the commit author is not. The GitHub no-reply email
# `<id>+<login>@users.noreply.github.com` links to the account even when the
# operator keeps their address private. The derived identity is applied through
# git's own GIT_AUTHOR_*/GIT_COMMITTER_* variables, so every later `git commit`
# inherits it without per-call-site changes. UNSORRY_SOLVER_NAME /
# UNSORRY_SOLVER_EMAIL override the derived values; if no GitHub identity is
# resolvable (offline, no override) it fails soft to the local git config
# rather than blocking a proof.
resolve_git_identity() {
  local name="${UNSORRY_SOLVER_NAME:-}" email="${UNSORRY_SOLVER_EMAIL:-}"
  if [ -z "$name" ] || [ -z "$email" ]; then
    local fields login id ghname
    fields="$(gh api user --jq '[.login, (.id|tostring), (.name // "")] | @tsv' 2>/dev/null)" || fields=""
    IFS=$'\t' read -r login id ghname <<<"$fields"
    if [ -n "$login" ] && [ -n "$id" ]; then
      [ -z "$email" ] && email="${id}+${login}@users.noreply.github.com"
      [ -z "$name" ] && name="${ghname:-$login}"
    fi
  fi
  if [ -z "$name" ] || [ -z "$email" ]; then
    log "warning: no GitHub commit identity resolved; using local git config for authorship"
    return 0
  fi
  export GIT_AUTHOR_NAME="$name" GIT_AUTHOR_EMAIL="$email"
  export GIT_COMMITTER_NAME="$name" GIT_COMMITTER_EMAIL="$email"
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

# ADR-068: parse a GitHub remote URL into its owner/repo ("nwo"). Handles the
# https and ssh forms and an optional .git suffix; prints empty for a non-GitHub
# URL. Pure (string in, string out) — hermetically unit-tested.
parse_github_nwo() {
  local url="$1" nwo
  case "$url" in
    *github.com[:/]*) nwo="${url#*github.com}"; nwo="${nwo#[:/]}" ;;
    *) printf '\n'; return 0 ;;
  esac
  nwo="${nwo%.git}"
  nwo="${nwo%/}"
  printf '%s\n' "$nwo"
}

# The owner/repo of a configured remote (default origin), via its URL.
gh_repo_nwo() {
  local url
  url="$(git remote get-url "${1:-origin}" 2>/dev/null)" || return 1
  parse_github_nwo "$url"
}

# ADR-068: ensure the read-only `upstream` remote points at the canonical repo.
ensure_upstream_remote() {
  git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1 && return 0
  git remote add "$UPSTREAM_REMOTE" "https://github.com/$UNSORRY_UPSTREAM.git" \
    || die_config "fork mode: cannot add '$UPSTREAM_REMOTE' remote for $UNSORRY_UPSTREAM"
}

# ADR-068 / SPEC-068-A: decide whether this --prove run is a fork-native
# contribution (no upstream write access) and, if so, prepare it. Fork mode is
# entered when --fork / UNSORRY_FORK is set, or when origin is a fork of the
# canonical upstream. On entry it adds the read-only upstream remote, best-effort
# syncs the fork's main from upstream (so the existing origin/main-based relocate,
# sync, and worktree machinery stays correct and unchanged — the fork's main now
# mirrors the upstream), and records FORK_OWNER for the cross-repo PR head. When
# it is not a fork the canonical path is left completely untouched (FORK_MODE=0).
detect_fork_mode() {
  local origin_nwo
  origin_nwo="$(gh_repo_nwo origin)" || origin_nwo=""
  if [ "$FORK_REQUEST" = 1 ] || env_truthy "${UNSORRY_FORK:-}"; then
    FORK_MODE=1
  elif [ -n "$origin_nwo" ] && [ "$origin_nwo" != "$UNSORRY_UPSTREAM" ]; then
    # origin differs from the canonical repo — treat it as a fork iff GitHub
    # confirms it (a same-name mirror that is not a fork stays on the normal path
    # and will fail later on a real write, which is the honest outcome).
    [ "$(gh api "repos/$origin_nwo" --jq '.fork' 2>/dev/null)" = true ] && FORK_MODE=1
  fi
  [ "$FORK_MODE" = 1 ] || return 0

  FORK_OWNER="${origin_nwo%%/*}"
  if [ -z "$FORK_OWNER" ] || [ "$FORK_OWNER" = "$origin_nwo" ]; then
    die_config "fork mode: cannot determine the fork owner from origin ($origin_nwo); set a GitHub origin or pass --fork on a clone of your fork"
  fi
  ensure_upstream_remote
  # Keep the fork's main current with the upstream so origin/main == upstream/main
  # and every existing origin/main read (selection, dedup, the relocate/worktree
  # base) is canonical without touching that machinery. Best-effort: a real
  # divergence is caught later by require_main_matches_origin with guidance.
  gh repo sync "$origin_nwo" --branch main >/dev/null 2>&1 \
    || log "fork mode: could not auto-sync $origin_nwo main from upstream (continuing; sync it with: gh repo sync $origin_nwo)"
  git fetch -q origin main 2>/dev/null || true
  # A fork cannot push queued/prove/* to the upstream, so submission is always a
  # direct cross-repo PR (the upstream enabler arms auto-merge, SPEC-068-A §6).
  UNSORRY_SUBMIT_MODE="pr"
  log "fork mode (ADR-068): claimless; proving against upstream $UNSORRY_UPSTREAM, submitting from fork $origin_nwo via cross-repo PR"
}

# ADR-068: the PR head ref. Cross-repo `<fork-owner>:<branch>` in fork mode (the
# branch lives on the contributor's fork), plain `<branch>` on the canonical path.
fork_pr_head_ref() {
  local branch="$1"
  if [ "$FORK_MODE" = 1 ]; then printf '%s:%s\n' "$FORK_OWNER" "$branch"
  else printf '%s\n' "$branch"; fi
}

# ADR-076 sharded fork goal selection (Phase-2 step 2c). cksum is CRC-32 and
# portable (Linux + macOS), so every machine maps a given string to the SAME
# shard — that cross-machine stability is what lets two uncoordinated forks
# prefer disjoint slices. Bucket 0..K-1.
fork_shard() {
  local s="$1" k="$2" h
  h="$(printf '%s' "$s" | cksum | cut -d' ' -f1)"
  printf '%s\n' "$(( h % k ))"
}

# The shard count K (UNSORRY_FORK_SHARDS, default 8); a non-positive-integer
# value degrades to the default rather than erroring (selection must not die on
# a misconfigured advisory knob).
fork_shard_count() {
  local k="${UNSORRY_FORK_SHARDS:-8}"
  case "$k" in ''|*[!0-9]*) k=8 ;; esac
  [ "$k" -ge 1 ] || k=8
  printf '%s\n' "$k"
}

# ADR-076: reorder a ranked candidate list (stdin) so goals in THIS agent's shard
# come first, the rest after — each group in input (rank) order, so the ADR-010
# affinity/gap priority is preserved within the shard and across the fall-through
# tail. Pure (stdin + args), hermetically testable.
shard_reorder() {
  local agent="$1" k="$2" mine cand
  mine="$(fork_shard "$agent" "$k")"
  local -a in=() out=()
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    if [ "$(fork_shard "$cand" "$k")" = "$mine" ]; then in+=("$cand"); else out+=("$cand"); fi
  done
  printf '%s\n' ${in[@]+"${in[@]}"} ${out[@]+"${out[@]}"}
}

# ADR-076: in fork mode, shard-reorder the candidate stream so independent
# cross-fork provers prefer different goals (advisory; no coordination). A
# pass-through on the canonical path — selection there is byte-for-byte unchanged.
fork_maybe_shard() {
  if [ "$FORK_MODE" = 1 ]; then
    shard_reorder "$AGENT_ID" "$(fork_shard_count)"
  else
    cat
  fi
}

require_main_checkout() {
  # ADR-042: inside an isolated agent worktree the checkout is a detached HEAD
  # pinned to origin/main by sync_repo every cycle, so the branch-name check
  # doesn't apply. The real invariant — HEAD == origin/main — is enforced by
  # require_main_matches_origin (called in sync_repo) in both modes.
  [ "${UNSORRY_IN_WT:-0}" = 1 ] && return 0
  local branch
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" \
    || die_config "must be run with main checked out (detached HEAD found)"
  [ "$branch" = "main" ] \
    || die_config "must be run with main checked out (current branch: $branch); merge feature-branch goals before claiming them"
}

require_main_matches_origin() {
  local local_head origin_head
  local_head="$(git rev-parse HEAD 2>/dev/null)" \
    || die_config "cannot resolve local main"
  origin_head="$(git rev-parse origin/main 2>/dev/null)" \
    || die_config "cannot resolve origin/main"
  [ "$local_head" = "$origin_head" ] \
    || die_config "local main does not match origin/main after fetch; merge local goal changes through a PR before claiming them"
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

# ADR-059 pure backoff schedule: seconds to wait before the next fetch retry.
# <attempt> is the 1-based index of the just-failed attempt; delay is
# base*2^(attempt-1), the shift clamped at 6 to bound the arithmetic, then
# capped. base 0 yields 0 for every attempt (the self-test uses this to avoid
# real sleeps). Mirrors supervise.sh:next_action's doubling-with-cap shape.
fetch_retry_delay() {
  local attempt="$1" base="$2" cap="$3" delay shift_n
  shift_n=$((attempt - 1)); [ "$shift_n" -gt 6 ] && shift_n=6
  delay=$(( base * (1 << shift_n) ))
  [ "$delay" -gt "$cap" ] && delay="$cap"
  echo "$delay"
}

# ADR-059: git fetch into the SHARED object store (all ADR-042 per-agent
# worktrees on a host share one .git/objects) is not concurrency-safe — a
# sibling agent's fetch, or a gc.auto repack, can leave a thin-pack base object
# momentarily unreadable while this fetch's unpack needs it ("failed to read
# delta-pack base object" / "unpack-objects error", #983). The failure is
# transient, so retry with exponential backoff; -c gc.auto=0 stops a concurrent
# repack from racing this fetch. <dir> is the repo to fetch into ("." for the
# current worktree, "$CLAIMS_WT" for the claims worktree) — one helper covers
# every site. Returns 0 on success, or the infrastructure code 3 once all
# attempts are spent (callers propagate it so the loop exits 3 and supervise.sh
# backs off, rather than dying on the first blip).
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
    log "git fetch ($*) failed (attempt $n/$attempts) — retrying in ${delay}s (#983)"
    sleep "$delay"
    n=$((n + 1))
  done
}

# Step 1: pull main, ensure the claims worktree exists and is freshly pulled.
# ADR-042: an isolated agent worktree is a throwaway detached checkout, so it is
# hard-reset to origin/main (re-entrant: clears anything a dead cycle left
# behind, like the claims worktree does). The non-isolated path keeps the
# conservative --ff-only merge of the operator's own main checkout.
# ADR-068: fork mode is claimless (the claims branch is upstream-only and
# fork-inaccessible). Point CLAIMS_WT at an empty stub directory so the candidate
# enumerator (py_helper, which reads <CLAIMS_WT>/claims) sees an unclaimed pool,
# with no claims worktree and no origin/claims access at all.
ensure_fork_claims_stub() {
  CLAIMS_WT="${SESSION_TMP:-${TMPDIR:-/tmp}}/fork-claims"
  mkdir -p "$CLAIMS_WT/claims"
}

sync_repo() {
  # ADR-068: each cycle, keep the fork's main current with the upstream so
  # origin/main stays canonical and the relocate/worktree base is fresh — without
  # touching any of the origin/main-based machinery below.
  [ "$FORK_MODE" = 1 ] && { gh repo sync "$(gh_repo_nwo origin)" --branch main >/dev/null 2>&1 || true; }
  git_fetch_retry . -q origin || return $?  # ADR-059: 3 on exhausted retries
  if [ "${UNSORRY_IN_WT:-0}" = 1 ]; then
    git reset --hard -q origin/main || return 1
  else
    git merge -q --ff-only origin/main || return 1
  fi
  require_main_matches_origin
  if [ "$FORK_MODE" = 1 ]; then
    ensure_fork_claims_stub
  else
    ensure_claims_worktree
  fi
}

# #428: sync_repo advances the *working tree* to origin/main, but this running
# bash process still holds the agent.sh it was launched with — a newer harness
# is on disk yet not in memory. At the top of a cycle (before any goal is
# claimed, so no in-flight work is lost) re-exec when our own script changed, so
# the next cycle runs the latest code.
harness_is_stale() {  # <running-sha> <current-sha> → 0 (stale) iff they differ and current is known
  [ "$2" != "unknown" ] && [ "$1" != "$2" ]
}

maybe_reexec_on_harness_update() {
  local current
  current="$(git hash-object "${BASH_SOURCE[0]}" 2>/dev/null || echo unknown)"
  if harness_is_stale "${_HARNESS_SHA:-unknown}" "$current"; then
    log "harness updated on origin/main (${_HARNESS_SHA} → ${current}) — re-exec'ing to run the latest code (#428)"
    exec "${BASH_SOURCE[0]}" ${_ORIG_ARGV[@]+"${_ORIG_ARGV[@]}"}
  fi
}

# ADR-042: ensure a dedicated per-agent worktree exists at <wt>, a detached
# checkout of origin/main. Reused across cycles so its .lake/mathlib build cache
# is paid once, not per run. Mirrors ensure_claims_worktree's ownership guard:
# refuse to adopt a path that belongs to a different clone, prune stale registry
# entries before creating a fresh one.
ensure_agent_worktree() {
  local wt="$1"
  if [ -e "$wt" ]; then
    local theirs ours
    theirs="$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" \
      || die_config "$wt exists but is not a git worktree"
    ours="$(git rev-parse --path-format=absolute --git-common-dir)"
    [ "$theirs" = "$ours" ] \
      || die_config "$wt belongs to another clone ($theirs)"
  else
    git worktree prune >/dev/null 2>&1 || true
    git worktree add -q --detach "$wt" origin/main \
      || die_config "cannot create agent worktree at $wt"
  fi
}

# Multi-runner safety (ADR-042): pick an agent identity not already held by a LIVE
# co-located runner, so N runners spawned on one host get DISTINCT ids + worktrees
# instead of silently sharing one worktree/claim and all working the same goal
# (observed when a wrapper forks several runners). The lock is a mkdir'd directory
# holding the owner PID; a directory whose PID is dead is stale and reclaimed
# (self-healing across crashes — no flock, so it works on macOS too). The base id
# is reused whenever free (claim continuity across restarts); only a *live*
# collision forks a random-suffixed id. Sets AGENT_ID to the acquired identity.
claim_agent_identity() {
  local workdir="$1" base="$2" id="$2" lockdir owner attempt=0
  while :; do
    lockdir="$workdir/agent-main-$id.lock"
    if mkdir "$lockdir" 2>/dev/null; then
      printf '%s\n' "$$" > "$lockdir/pid"
      AGENT_ID="$id"
      return 0
    fi
    owner="$(cat "$lockdir/pid" 2>/dev/null)"
    if [ "$owner" = "$$" ]; then AGENT_ID="$id"; return 0; fi
    if [ -z "$owner" ] || ! kill -0 "$owner" 2>/dev/null; then
      rm -rf "$lockdir" 2>/dev/null   # stale (dead owner) -> reclaim the base id
      continue
    fi
    attempt=$((attempt + 1))
    [ "$attempt" -gt 64 ] && die_config "no free agent identity under '$base' after 64 tries"
    id="$base-$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
  done
}

# ADR-068 follow-up (the #3140 author's flagged gap): fork mode is claimless, so
# co-located fork provers — sharing one host but each with its own fork checkout,
# UNSORRY_AGENT_ID and UNSORRY_WORKDIR — have no claims branch to dedup against
# and, because _rank() is fully deterministic, every one of them independently
# picks the SAME top goal and grinds it in parallel. A fork-local goal lock fixes
# that: at selection an agent skips any goal a LIVE sibling already locked. The
# lock dir MUST be shared across the co-located provers (NOT under a per-agent
# UNSORRY_WORKDIR, which is distinct per prover), so it lives at a path common to
# them: UNSORRY_GOAL_LOCK_DIR, default ~/.unsorry/goal-locks — shared by all
# provers that run as the same user (the default keys off $HOME). Provers with
# isolated homes (different Unix users / containers) must set it to a common
# path. Same primitive as claim_agent_identity: a mkdir'd directory holding the
# owner identity (atomic, no flock, macOS-safe); a dead owner is self-healing —
# the next prover reclaims it, so a crashed prover needs no manual cleanup. The
# owner is recorded as "<pid> <starttime>" (not a bare PID) so a PID reused after
# a reboot cannot masquerade as the original holder. This is purely a fork-mode
# coordination layer: the canonical claims path (claim_goal / release_claim,
# ADR-004) is upstream-only and left completely untouched.

# Per-machine lock dir, resolved once. Shared by all co-located provers that run
# as the SAME user (the default keys off $HOME) — that sharing is the whole point,
# a per-agent dir would never collide. Provers with isolated homes (different Unix
# users / containers) MUST point UNSORRY_GOAL_LOCK_DIR at a common path or the
# lock silently does nothing (see usage()).
goal_lock_dir() {
  printf '%s\n' "${UNSORRY_GOAL_LOCK_DIR:-$HOME/.unsorry/goal-locks}"
}

# A PID alone is not a stable owner identity: ~/.unsorry/goal-locks is on
# persistent disk and survives reboots, after which the OS reuses PIDs from 1 —
# a leftover lock whose recorded PID now belongs to an unrelated live process
# would read as "live" and strand the goal forever (no TTL, no reaper). So the
# lock records "<pid> <starttime>" and liveness requires BOTH kill -0 AND a
# start-time match, which a reused PID cannot satisfy. ps -o lstart= is portable
# (Linux + macOS, matching this primitive's flock-free macOS-safe contract);
# empty start-time (kernel thread / race) degrades gracefully to the PID check.
goal_lock_token() {
  printf '%s %s\n' "$1" "$(ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ')"
}

# True if the owner token "<pid> <starttime>" names a live process that is still
# the same process that took the lock (defeats PID reuse across a reboot).
goal_lock_owner_live() {
  local token="$1" pid
  pid="${token%% *}"
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  # Re-derive the current token for that PID; a reused PID yields a different
  # start-time and so fails this match. If we recorded no start-time, fall back
  # to the bare kill -0 result above.
  [ "$token" = "$(goal_lock_token "$pid")" ] || [ "$token" = "$pid " ] || [ "$token" = "$pid" ]
}

# Try to take the fork-local lock for <goal>. No-op success outside fork mode.
# Returns 0 when acquired (or already held by us), 1 when a LIVE sibling holds it
# (caller skips to the next ranked goal). A stale lock (dead owner) is reclaimed.
acquire_goal_lock() {
  [ "$FORK_MODE" = 1 ] || return 0
  local goal="$1" dir lockdir owner mine
  dir="$(goal_lock_dir)"
  if ! mkdir -p "$dir" 2>/dev/null; then
    # best-effort: never block proving on a lock-dir failure, but make the
    # degraded coordination visible — siblings may now duplicate this goal.
    log "warning: cannot create goal-lock dir '$dir' — fork dedup disabled this cycle (ADR-068)"
    return 0
  fi
  lockdir="$dir/goal-$goal.lock"
  mine="$(goal_lock_token "$$")"
  while :; do
    if mkdir "$lockdir" 2>/dev/null; then
      printf '%s\n' "$mine" > "$lockdir/pid"
      return 0
    fi
    owner="$(cat "$lockdir/pid" 2>/dev/null)"
    if [ "${owner%% *}" = "$$" ]; then return 0; fi   # already ours -> idempotent
    if [ -z "$owner" ]; then
      # An empty pid is the brief window between a sibling's mkdir and its pid
      # write, OR a truly stale lock. Re-read once before reclaiming so we never
      # rm -rf a lock an in-progress acquirer is about to own (the read-after-
      # mkdir race the claim_goal/ADR-072 recheck guards against, same reasoning).
      owner="$(cat "$lockdir/pid" 2>/dev/null)"
    fi
    if [ -z "$owner" ] || ! goal_lock_owner_live "$owner"; then
      # Stale (dead owner / reused PID). Reclaim atomically: rename the stale dir
      # aside so two simultaneous reclaimers cannot both rm a third prover's fresh
      # lock — only the mv winner deletes, the losers loop and re-mkdir cleanly.
      mv "$lockdir" "$lockdir.stale.$$.$RANDOM" 2>/dev/null && rm -rf "$lockdir".stale.* 2>/dev/null
      continue
    fi
    return 1   # a live sibling owns it -> skip this goal
  done
}

# Release a fork-local goal lock we own. No-op outside fork mode or if not ours
# (a sibling's lock is never removed). Called on every cycle-exit path, mirroring
# release_claim; a missed release is self-healed by the next prover's PID check.
release_goal_lock() {
  [ "$FORK_MODE" = 1 ] || return 0
  local goal="$1" lockdir owner
  lockdir="$(goal_lock_dir)/goal-$goal.lock"
  [ -d "$lockdir" ] || return 0
  owner="$(cat "$lockdir/pid" 2>/dev/null)"
  [ "${owner%% *}" = "$$" ] && rm -rf "$lockdir" 2>/dev/null
  return 0
}

# ADR-042: relocate the running agent into its own worktree before any work, so
# the operator's launch dir is never synced/built/claimed in (they can edit
# proofs and the harness there freely) and two agents on one host don't share a
# tree. Opt out with UNSORRY_NO_ISOLATE=1; override the path with
# UNSORRY_AGENT_WORKTREE. No-op once already inside the worktree (UNSORRY_IN_WT).
# Like the #428 re-exec, this runs origin/main's agent.sh — the swarm loop must
# act on merged code, not the operator's working copy.
relocate_into_agent_worktree() {
  [ "${UNSORRY_IN_WT:-0}" = 1 ] && return 0
  [ "${UNSORRY_NO_ISOLATE:-0}" = 1 ] && return 0

  require_unsorry_origin
  git_fetch_retry . -q origin \
    || die_infra "cannot fetch origin before relocating into an isolated worktree (ADR-059, #983)"

  local workdir wt
  workdir="${UNSORRY_WORKDIR:-$HOME/.unsorry/work}"
  mkdir -p "$workdir" || die_config "cannot create UNSORRY_WORKDIR '$workdir'"
  [ -n "${AGENT_ID:-}" ] || resolve_agent_id
  # Multi-runner safety: claim a distinct identity if a live sibling already holds
  # this one, then carry it forward so the re-exec (and all claims/worktrees) use
  # the SAME acquired id. An explicit UNSORRY_AGENT_WORKTREE override opts out.
  if [ -z "${UNSORRY_AGENT_WORKTREE:-}" ]; then
    claim_agent_identity "$workdir" "$AGENT_ID"
    export UNSORRY_AGENT_ID="$AGENT_ID"
  fi
  wt="${UNSORRY_AGENT_WORKTREE:-$workdir/agent-main-$AGENT_ID}"

  ensure_agent_worktree "$wt"

  log "relocating into isolated agent worktree $wt (ADR-042); launch dir left untouched"
  cd "$wt" || die_config "cannot enter agent worktree $wt"
  export UNSORRY_IN_WT=1
  exec "$wt/swarm/agent.sh" ${_ORIG_ARGV[@]+"${_ORIG_ARGV[@]}"}
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
  git_fetch_retry "$CLAIMS_WT" -q origin claims || return $?  # ADR-059: 3 on exhausted retries
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
  # NB: the goals/library change here is NOT accompanied by a docs/targets.md or
  # docs/leaderboard regen. Both are generated artifacts refreshed POST-MERGE by
  # the targets-board / proofs-visualisation workflows (ADR-036, #415) —
  # regenerating them in-PR made every concurrent goal PR conflict on them.
  if ! python3 -m tools.gate_b validate "$prwt" >/dev/null; then
    log "PR tree on $branch fails Gate B — not pushing"
    return 1
  fi
  git -C "$prwt" add "$@" || return 1
  # ADR-096: same independent-check verdict carry as queue_pr_tree — as a commit
  # trailer (audit) and, since this path opens the PR in-process, appended to the
  # PR body directly.
  local -a ic_trailer=()
  case "$title" in
    prove\(*)
      if [ -n "${INDEPENDENT_CHECK_VERDICT:-}" ]; then
        ic_trailer=(-m "Independent-Check: $INDEPENDENT_CHECK_VERDICT")
        body="$body"$'\n\n'"_Independent check (advisory, ADR-096): ${INDEPENDENT_CHECK_VERDICT}_"
      fi
      ;;
  esac
  git -C "$prwt" commit -q -m "$title" "${ic_trailer[@]}" || return 1
  # The proof branch is pushed to `origin` in both modes — origin is the canonical
  # repo on the write-access path, and the contributor's own fork in fork mode.
  git -C "$prwt" push -q origin "$branch" || return 1
  if [ "$FORK_MODE" = 1 ]; then
    # ADR-068: open a cross-repo PR from <fork-owner>:<branch> against the upstream;
    # a fork cannot arm auto-merge there (the upstream enabler does, SPEC-068-A §6).
    (
      cd "$prwt" || exit 1
      gh pr create --repo "$UNSORRY_UPSTREAM" --base main \
        --head "$(fork_pr_head_ref "$branch")" --title "$title" --body "$body"
    ) || return 1
  else
    (
      cd "$prwt" || exit 1
      gh pr create --base main --head "$branch" --title "$title" --body "$body" \
        && gh pr merge --auto --squash "$branch"
    ) || return 1
  fi
  git worktree remove --force "$prwt" >/dev/null 2>&1 || true
  git branch -q -D "$branch" >/dev/null 2>&1 || true
  return 0
}

queue_pr_tree() {
  local prwt="$1" branch="$2" title="$3"
  shift 3
  if ! python3 -m tools.gate_b validate "$prwt" >/dev/null; then
    log "queued tree on $branch fails Gate B — not pushing"
    return 1
  fi
  git -C "$prwt" add "$@" || return 1
  # ADR-096: carry the advisory independent-check verdict to the dispatcher as a
  # commit trailer (only on a prove commit, only when the check ran). The
  # dispatcher reads it back from the branch and surfaces it on the PR. The title
  # (commit subject) is unchanged, so the prove-title contract still holds.
  local -a ic_trailer=()
  case "$title" in
    prove\(*) [ -n "${INDEPENDENT_CHECK_VERDICT:-}" ] && ic_trailer=(-m "Independent-Check: $INDEPENDENT_CHECK_VERDICT") ;;
  esac
  git -C "$prwt" commit -q -m "$title" "${ic_trailer[@]}" || return 1
  git -C "$prwt" push -q origin "$branch" || return 1
  return 0
}

# ADR-096: extract the advisory independent-check verdict trailer (if any) from a
# branch's tip commit, as a one-line PR-body addendum. Empty when absent.
independent_check_pr_note() {
  local ref="$1" v
  v="$(git log -1 --format=%b "$ref" 2>/dev/null | sed -n 's/^Independent-Check: //p' | head -1)"
  [ -n "$v" ] && printf '\n\n_Independent check (advisory, ADR-096): %s_' "$v"
}

fetch_queued_prove_branches() {
  git fetch -q origin '+refs/heads/queued/prove/*:refs/remotes/origin/queued/prove/*'
}

queued_branch_has_pr() {
  local branch="$1" count
  count="$(gh pr list --state all --head "$branch" --json number --jq 'length' 2>/dev/null)" \
    || return 1
  [ "$count" -gt 0 ]
}

dispatch_queued_proof_branch() {
  local branch="$1" title body goal name
  local remote_ref="origin/$branch"
  title="$(git log -1 --format=%s "$remote_ref")" || return 1
  case "$title" in
    prove\(*:*) ;;
    *) log "queue dispatcher skipped $branch — commit title is not a prove title"; return 1 ;;
  esac
  goal="${branch#queued/prove/}"
  goal="${goal%%/*}"
  name="${title#*: }"
  name="${name% by *}"
  body="Queued proof dispatch (ADR-058, SPEC-007-A): branch \`$branch\` was produced by coordinated \`--prove\` in \`UNSORRY_SUBMIT_MODE=queue\` after local verification passed. The dispatcher opened this PR only after the submission governor admitted more verifier work. New library proof: \`$name\` for goal \`$goal\`."
  body="$body$(independent_check_pr_note "$remote_ref")"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'dry-run: would dispatch queued branch %s as "%s"\n' "$branch" "$title"
    return 0
  fi
  (
    gh pr create --base main --head "$branch" --title "$title" --body "$body" \
      && gh pr merge --auto --squash "$branch"
  ) || return 1
  log "dispatched queued proof branch $branch"
  return 0
}

fetch_main_ref() {
  git fetch -q origin '+refs/heads/main:refs/remotes/origin/main'
}

# ADR-018: the library/index entry is the authoritative 'proved' marker. Read it
# from freshly-fetched origin/main rather than the working tree — the dispatch
# loop runs without re-syncing the checkout, so its tree can lag main between
# passes. A missing ref or gh/git error degrades to "not proved" (best-effort),
# matching open_prove_pr_exists: dedup must never block on infra health.
goal_already_proved() {
  local goal="$1"
  git grep -qF "goal≜$goal;" origin/main -- library/index 2>/dev/null
}

queued_branch_refs() {
  git for-each-ref --format='%(refname:short)' refs/remotes/origin/queued/prove
}

# ADR-075: re-order the queued branches by a per-solver round-robin so one
# high-volume contributor cannot starve the rest. `git for-each-ref` returns
# refs lexically by name, i.e. by goal — so a contributor whose ~1,585 machine
# -named `g…` goals sort to the front (the @ohdearquant case) monopolises every
# governed dispatch slot while a contributor whose goals sort late (@ruvnet's
# `s…` cluster sat at queue ranks 1850–2002 of 2003) never drains. Round-robin
# gives every *active* solver one branch per round (max-min fairness): small
# backlogs clear promptly, the large one drains at the same per-round rate.
#
# Soundness is untouched — this only reorders; dedup (ADR-064/071), the governor
# (ADR-058) and Gate A still decide what merges. Solver per branch is read from
# the authoritative queue board (`docs/queue.json` on origin/main, which resolves
# `solver≜`/git-author provenance, ADR-066) — note a re-routed branch is authored
# by the operator, so the board's provenance, not the commit author, is the only
# correct solver key. A branch absent from the board (pushed since the last board
# refresh) falls back to its agent-id token; an unreadable board degrades to the
# prior lexical order. Reads refs on stdin, emits them reordered on stdout,
# verbatim. Disable with `UNSORRY_FAIR_DISPATCH=0` (reverts to lexical).
fair_dispatch_order() {
  [ "${UNSORRY_FAIR_DISPATCH:-1}" = 0 ] && { cat; return 0; }
  # ADR-075 per-solver round-robin + ADR-106 difficulty deprioritisation, in the
  # unit-tested module tools/dispatch/fair_order.py (reads refs on stdin, emits
  # them reordered). Both reorderings are pure and reversible (UNSORRY_FAIR_DISPATCH
  # =0 reverts to lexical here; UNSORRY_DIFFICULTY_DISPATCH=0 reverts to fairness-
  # only inside the module). The module handles the early-reader-close (EPIPE) of
  # the dispatch loop, the queue-board read, and the token-key fallback.
  python3 -m tools.dispatch.fair_order
}

# ADR-071: a final fresh "is this goal already taken?" check, run immediately
# before opening a PR. ADR-064's pass-start checks (goal_already_proved /
# open_pr_goals) go stale during a long pass and in the gap before gh pr create:
# a sibling proof of the same goal can MERGE, or a concurrent dispatcher can OPEN
# a PR, leaving this branch a dead "already proved" duplicate (the #2059/#2179
# class, all created after ADR-064 landed). Re-fetch origin/main and re-list open
# PRs for the handful actually being dispatched — cheap (git grep + one core-API
# list, no 30/min search API). Best-effort: any infra error degrades to "not
# taken" so dispatch still proceeds.
goal_taken_fresh() {
  local goal="$1"
  fetch_main_ref || true
  goal_already_proved "$goal" && return 0
  dispatch_open_pr_goals | grep -qxF "$goal"
}

# ADR-064: goals that already have an OPEN prove PR, collected in ONE list-API
# call (core quota, 5000/h). The dispatch loop checks membership in this set
# rather than a per-branch open_prove_pr_exists, whose `gh ... --search` hits the
# GitHub search API (only 30/min) — a per-branch search across a large queue
# exhausts that bucket and stalls the whole pass on retry backoff. Best-effort: a
# gh error yields an empty set and dispatch proceeds, since queued_branch_has_pr
# and the post-create PR state still prevent a genuine double-open.
dispatch_open_pr_goals() {
  gh pr list --state open --limit 1000 --json title \
    --jq '.[].title | select(startswith("prove(")) | sub("^prove\\(";"") | sub("\\):.*$";"")' 2>/dev/null
}

# ADR-064: the queue holds one branch per (goal, agent) but only one proof per
# goal can ever merge. The prove-time selection race (queued_prove_branch_exists
# is a non-atomic pre-check) lets several agents prove the same goal, and a goal
# that merged while its siblings still sit in the queue stays branch-resident.
# Dispatching those duplicates only burns verifier capacity and then closes as a
# conflict (the #1924/#1925 duplicate). The dispatcher therefore opens at most
# one prove PR per goal: it skips a branch whose goal is already proved on main,
# already has an open prove PR, or was already handled earlier in this pass.
dispatch_queue() {
  local limit="${UNSORRY_DISPATCH_LIMIT:-1}" branch goal dispatched=0 failures=0 seen_goals=" "
  [ "$ONCE" -eq 1 ] && limit=1
  validate_integer_knob UNSORRY_DISPATCH_LIMIT "$limit"
  fetch_queued_prove_branches || { log "queue dispatcher: no queued proof branches found"; return 0; }
  fetch_main_ref || true
  local open_pr_goals
  open_pr_goals=" $(dispatch_open_pr_goals | tr '\n' ' ') "
  # ADR-107: when batching is on, also dedup against goals already covered by an
  # OPEN batch PR so no redundant singleton opens for a batched goal. Gated on
  # UNSORRY_BATCH_SIZE>1 so the default singleton path is byte-for-byte unchanged.
  if [ "${UNSORRY_BATCH_SIZE:-1}" -gt 1 ]; then
    open_pr_goals="$open_pr_goals$(dispatch_open_batch_goals | tr '\n' ' ') "
  fi
  while IFS= read -r branch; do
    [ -n "$branch" ] || continue
    branch="${branch#origin/}"
    goal="${branch#queued/prove/}"
    goal="${goal%%/*}"
    case "$seen_goals" in
      *" $goal "*)
        log "queue dispatcher skipped $branch — goal $goal already handled this pass"
        continue ;;
    esac
    if goal_already_proved "$goal"; then
      log "queue dispatcher skipped $branch — goal $goal already proved on main"
      seen_goals="$seen_goals$goal "
      continue
    fi
    # In-memory open-PR check first (free); fall back to the exact-branch list
    # lookup (core API) only when the goal isn't already known to have an open PR
    # — this catches a closed/merged PR for this exact branch.
    local has_pr=0
    case "$open_pr_goals" in *" $goal "*) has_pr=1 ;; esac
    if [ "$has_pr" -eq 1 ] || queued_branch_has_pr "$branch"; then
      log "queue dispatcher skipped $branch — a prove PR for goal $goal already exists"
      seen_goals="$seen_goals$goal "
      continue
    fi
    if ! submission_governor_allows; then
      [ "$dispatched" -gt 0 ] && return "$failures"
      return 0
    fi
    # ADR-071: re-check against current state right before creating the PR — a
    # sibling proof may have merged, or another dispatcher opened a PR, since the
    # pass-start checks. This is where the post-ADR-064 duplicates leaked.
    if goal_taken_fresh "$goal"; then
      log "queue dispatcher skipped $branch — goal $goal was taken during this pass (merged or already PR'd)"
      seen_goals="$seen_goals$goal "
      continue
    fi
    if dispatch_queued_proof_branch "$branch"; then
      dispatched=$((dispatched + 1))
      seen_goals="$seen_goals$goal "
    else
      failures=$((failures + 1))
    fi
    [ "$dispatched" -ge "$limit" ] && break
  done < <(queued_branch_refs | fair_dispatch_order)
  [ "$failures" -eq 0 ]
}

# ------------------------------------------------------------- ADR-107 batching
# Combine K independent queued prove branches into ONE Gate A run so the dominant
# per-PR mathlib env-load is paid once for K proofs (D1b, #5683). Off by default
# (UNSORRY_BATCH_SIZE=1); the pure selection/dedup/recovery logic is unit-tested in
# tools/dispatch/batch.py — these are the thin git/gh shells.

# Goals already covered by an OPEN batch PR (prove-batch(…)), read from its
# Batch-Goals: manifest. Unioned into the dispatcher's dedup set so a batched goal
# never also gets a singleton. Best-effort: a gh error yields nothing (dedup then
# misses, risking only a redundant singleton that first-merge-wins reaps).
dispatch_open_batch_goals() {
  gh pr list --state open --limit 1000 --json title,body 2>/dev/null \
    | python3 -m tools.dispatch.batch manifest-goals 2>/dev/null
}

# The batch PR body: human context + the machine-readable Batch-Goals: manifest
# (the dedup source of truth while the PR is open) + each constituent prove title.
batch_pr_body() {
  local n="$1" manifest="$2"; shift 2
  local b titles=""
  for b in "$@"; do
    titles="$titles- \`$(git log -1 --format=%s "origin/${b#origin/}" 2>/dev/null)\`"$'\n'
  done
  # shellcheck disable=SC2016  # literal backticks + \n: this is a markdown PR body, not shell expansion
  printf 'Batch verification (ADR-107, D1b): %s independent proofs combined into one Gate A run so the mathlib env-load is amortised across them. Gate A re-verifies every proof from scratch (lake build + nanoda per leaf + replay per olean); no proof trusts another (ADR-049). Enrolled with a merge commit (not squash) so each `prove(<goal>)` lands in main history for leaderboard attribution.\n\n%s\n\nProofs:\n%s' \
    "$n" "$manifest" "$titles"
}

_cleanup_batch_worktree() {
  local wt="$1" branch="$2"
  git worktree remove --force "$wt" >/dev/null 2>&1 || true
  git branch -q -D "$branch" >/dev/null 2>&1 || true
  rm -rf "${wt%/*}" 2>/dev/null || true
}

# Assemble the given queued/prove branches into one batch/prove/<hash> PR.
# Cherry-picks each disjoint ADD-only prove commit (never conflicts; preserves the
# prove(<goal>) subject+author so the leaderboard's merge_times/git_add_authors
# resolve every batched proof), Gate-B-validates the combined tree, pushes, opens
# ONE PR enrolled with `--merge` (NOT squash — keeps each proof commit reachable in
# main history). Constituent branches are left intact (recovery redispatches them
# singly on a genuine failure). Returns non-zero on any assembly error, leaving the
# branches for singleton dispatch.
# Build the batch worktree at $wt on $branch (from origin/main) by cherry-picking
# each constituent's single proof commit. Two shallow-clone hazards are handled
# here (the CI dispatcher uses actions/checkout depth 1):
#   1. A queued branch's PARENT is not fetched at depth 1, and cherry-pick needs it
#      to compute the patch — so deepen the selected branches to depth 2 first (a
#      queued proof is exactly one commit atop its base).
#   2. WITHOUT the parent, cherry-pick treats the commit as a ROOT and re-adds its
#      whole tree, RESURRECTING files main has since deleted/archived (verified) —
#      i.e. the depth-2 deepen is load-bearing for soundness, not just for success.
# A cherry-pick conflict aborts and returns 1 (the batch is abandoned; the branches
# fall back to singleton dispatch). No-op deepen on a full local clone.
build_batch_worktree() {
  local wt="$1" branch="$2"; shift 2
  local -a branches=("$@")
  local b
  for b in "${branches[@]}"; do
    b="${b#origin/}"
    git fetch -q --depth=2 origin "+refs/heads/$b:refs/remotes/origin/$b" 2>/dev/null || true
  done
  git worktree add -q -B "$branch" "$wt" origin/main || { log "batch: worktree add for $branch failed"; return 1; }
  for b in "${branches[@]}"; do
    b="${b#origin/}"
    if ! git -C "$wt" cherry-pick "origin/$b" >/dev/null 2>&1; then
      log "batch: cherry-pick of $b conflicted — aborting batch $branch"
      git -C "$wt" cherry-pick --abort >/dev/null 2>&1 || true
      return 1
    fi
  done
  return 0
}

assemble_and_dispatch_batch() {
  local -a branches=("$@")
  local meta branch manifest title body wt n rc=0
  meta="$(printf '%s\n' "${branches[@]}" | python3 -m tools.dispatch.batch meta)" || return 1
  branch="$(printf '%s\n' "$meta" | sed -n '1p')"
  manifest="$(printf '%s\n' "$meta" | sed -n '2p')"
  n="${#branches[@]}"
  [ -n "$branch" ] || return 1
  if queued_branch_has_pr "$branch"; then
    log "batch: a PR for $branch already exists — skipping"
    return 0
  fi
  wt="$(mktemp -d)/wt"
  if ! build_batch_worktree "$wt" "$branch" "${branches[@]}"; then
    _cleanup_batch_worktree "$wt" "$branch"
    return 1
  fi
  if ! python3 -m tools.gate_b validate "$wt" >/dev/null; then
    log "batch: combined tree fails Gate B — aborting batch $branch"
    _cleanup_batch_worktree "$wt" "$branch"
    return 1
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: would dispatch batch $branch with $n proofs ($manifest)"
    _cleanup_batch_worktree "$wt" "$branch"
    return 0
  fi
  if ! git -C "$wt" push -q origin "$branch"; then
    log "batch: push of $branch failed"
    _cleanup_batch_worktree "$wt" "$branch"
    return 1
  fi
  title="prove-batch($n): amortised verification of $n proofs (ADR-107)"
  body="$(batch_pr_body "$n" "$manifest" "${branches[@]}")"
  (
    cd "$wt" || exit 1
    gh pr create --base main --head "$branch" --title "$title" --body "$body" \
      && gh pr merge --auto --merge "$branch"
  ) || rc=1
  _cleanup_batch_worktree "$wt" "$branch"
  [ "$rc" -eq 0 ] && log "dispatched batch $branch with $n proofs"
  return "$rc"
}

# One batch PR per pass, assembled from the highest-priority eligible queued
# branches (a batch is ONE governor admission). Gated on UNSORRY_BATCH_SIZE>1.
# Non-fatal: any failure logs and returns 0 so singleton dispatch still proceeds;
# the remaining/ineligible branches fall through to dispatch_queue, which dedups
# against this batch via dispatch_open_batch_goals.
dispatch_batch_pass() {
  [ "${UNSORRY_BATCH_SIZE:-1}" -gt 1 ] || return 0
  fetch_queued_prove_branches || return 0
  fetch_main_ref || true
  if ! submission_governor_allows; then
    log "batch: governor paused — no batch this pass"
    return 0
  fi
  local exclude_file
  exclude_file="$(mktemp)"
  { dispatch_open_pr_goals; dispatch_open_batch_goals; } 2>/dev/null | sort -u > "$exclude_file"
  local -a picked
  mapfile -t picked < <(queued_branch_refs | fair_dispatch_order \
    | python3 -m tools.dispatch.batch select --max "$UNSORRY_BATCH_SIZE" --exclude-file "$exclude_file" 2>/dev/null)
  rm -f "$exclude_file"
  log "batch: pass start (size=$UNSORRY_BATCH_SIZE) — selected ${#picked[@]} candidate branch(es)"
  if [ "${#picked[@]}" -lt 2 ]; then
    log "batch: fewer than 2 batchable branches this pass — leaving the rest to singleton dispatch"
    return 0
  fi
  # ADR-071 fresh re-check: drop any pick taken (merged/PR'd) since selection.
  local -a final=()
  local b g
  for b in "${picked[@]}"; do
    b="${b#origin/}"
    g="${b#queued/prove/}"; g="${g%%/*}"
    if goal_taken_fresh "$g"; then
      log "batch: dropping $g — taken since selection"
      continue
    fi
    final+=("$b")
  done
  [ "${#final[@]}" -ge 2 ] || return 0
  assemble_and_dispatch_batch "${final[@]}" \
    || log "batch: assembly failed — branches remain for singleton dispatch"
  return 0
}

# ----------------------------------------------------------------- the cycle

# ADR-017: a goal whose prove PR is already open is done being worked — the
# claim was released when the PR opened, so the claims branch alone cannot
# see it, and re-claiming only duplicates an expensive prove run and races
# the goal record (the #166/#168 conflict, the #184/#185 duplicate).
# GitHub search tokenizes punctuation, so "prove(<goal>):" also matches
# SIBLING goals sharing the name's tokens — an open PR for <goal>-s2-s2
# blocked the parent's claim (#198) — so the search is only a coarse
# pre-filter and the verdict comes from an exact title-prefix match.
# Best-effort: a gh error means "unknown" (rc 1) and claiming proceeds —
# selection must not depend on API health.
open_prove_pr_exists() {
  local goal="$1" titles t
  # ADR-068: in fork mode the open-PR dedup must read the UPSTREAM's PRs (gh would
  # otherwise infer the fork from origin and see none).
  local -a repo_args=()
  [ "$FORK_MODE" = 1 ] && repo_args=(--repo "$UNSORRY_UPSTREAM")
  titles="$(gh pr list ${repo_args[@]+"${repo_args[@]}"} --state open --limit 30 \
    --search "\"prove($goal):\" in:title" \
    --json title --jq '.[].title' 2>/dev/null)" || return 1
  [ -n "$titles" ] || return 1
  while IFS= read -r t; do
    case "$t" in "prove($goal):"*) return 0 ;; esac
  done <<< "$titles"
  return 1
}

queued_prove_branch_exists() {
  local goal="$1"
  git ls-remote --exit-code --heads origin "queued/prove/$goal/*" >/dev/null 2>&1
}

env_truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

validate_integer_knob() {
  local name="$1" value="$2" allow_minus_one="${3:-0}"
  if [ "$allow_minus_one" = 1 ] && [ "$value" = -1 ]; then
    return 0
  fi
  [[ "$value" =~ ^[0-9]+$ ]] \
    || {
      if [ "$allow_minus_one" = 1 ]; then
        die_config "$name '$value' must be a non-negative integer or -1"
      else
        die_config "$name '$value' must be a non-negative integer"
      fi
    }
}

# Pure decision helper for the coordinated prove submission governor. Prints a
# pause reason when the agent must not start new claim/PR-producing work; prints
# nothing when admission is allowed.
submission_governor_reason() {
  local freeze="$1" open_prove="$2" gate_a_in_flight="$3" max_open="$4" max_gate="$5" \
        inflight="${6:-}" max_inflight="${7:-}"
  if env_truthy "$freeze"; then
    echo "submission freeze is active"
    return 0
  fi
  if [ "$max_open" -ge 0 ] && [ "$open_prove" -ge "$max_open" ]; then
    echo "open prove PRs $open_prove >= limit $max_open"
    return 0
  fi
  if [ "$max_gate" -ge 0 ] && [ "$gate_a_in_flight" -ge "$max_gate" ]; then
    echo "Gate A queued+in-progress runs $gate_a_in_flight >= limit $max_gate"
    return 0
  fi
  # Per-contributor fairness cap: an agent already holding this many goals in
  # flight (its own queued-but-unmerged prove branches) must let them
  # dispatch/merge before claiming more, so one fleet cannot queue the entire
  # goal pool and starve other contributors. Empty/negative max disables it.
  if [[ "$max_inflight" =~ ^[0-9]+$ ]] && [[ "$inflight" =~ ^[0-9]+$ ]] \
     && [ "$inflight" -ge "$max_inflight" ]; then
    echo "this agent holds $inflight goals in flight >= cap $max_inflight"
    return 0
  fi
  return 1
}

count_open_prove_prs() {
  gh pr list --state open --limit "$UNSORRY_GOVERNOR_SCAN_LIMIT" \
    --json title \
    --jq '[.[].title | select(startswith("prove("))] | length'
}

count_gate_a_runs() {
  local status="$1"
  gh run list --workflow gate-a.yml --status "$status" \
    --limit "$UNSORRY_GOVERNOR_SCAN_LIMIT" \
    --json databaseId --jq 'length'
}

# The cheap admission layer in front of the trusted verifier lane (ADR-058).
# Fail closed on GitHub API errors: if the operator cannot see queue pressure,
# the safe response during a flood is to avoid opening more proof PRs. This only
# applies to coordinated --prove; --prove-local remains fully local.
# Goals this agent is holding in flight = its own queued-but-unmerged prove
# branches (a merged branch is deleted, so a present one is unmerged). Used by the
# per-contributor fairness cap. Prints the count, or nothing if it cannot be read
# (the governor then leaves the cap unenforced — fail-open).
count_agent_inflight() {
  fetch_queued_prove_branches >/dev/null 2>&1 || return 1
  local n
  n="$(queued_branch_refs 2>/dev/null | grep -cE "/${AGENT_ID}-[0-9a-f]+$")" || true
  printf '%s\n' "${n:-0}"
}

submission_governor_allows() {
  [ "$PROVE" -eq 1 ] || return 0
  [ "$DRY_RUN" -eq 1 ] && return 0
  [ "${UNSORRY_SUBMISSION_GOVERNOR:-1}" = 0 ] && return 0

  local open_prove queued in_progress gate_a_total reason inflight
  if ! open_prove="$(count_open_prove_prs 2>/dev/null)"; then
    log "submission governor paused: could not read open proof PR count"
    return 1
  fi
  if ! queued="$(count_gate_a_runs queued 2>/dev/null)"; then
    log "submission governor paused: could not read queued Gate A runs"
    return 1
  fi
  if ! in_progress="$(count_gate_a_runs in_progress 2>/dev/null)"; then
    log "submission governor paused: could not read in-progress Gate A runs"
    return 1
  fi
  [[ "$open_prove" =~ ^[0-9]+$ ]] || { log "submission governor paused: invalid open PR count '$open_prove'"; return 1; }
  [[ "$queued" =~ ^[0-9]+$ ]] || { log "submission governor paused: invalid queued Gate A count '$queued'"; return 1; }
  [[ "$in_progress" =~ ^[0-9]+$ ]] || { log "submission governor paused: invalid in-progress Gate A count '$in_progress'"; return 1; }
  gate_a_total=$((queued + in_progress))

  # Per-contributor fairness cap (UNSORRY_MAX_GOALS_IN_FLIGHT, default 25). Unknown
  # count (fetch failed) leaves it unenforced rather than blocking a live agent.
  inflight="$(count_agent_inflight 2>/dev/null)"
  [[ "$inflight" =~ ^[0-9]+$ ]] || inflight=""

  if reason="$(submission_governor_reason "$UNSORRY_SUBMISSION_FREEZE" "$open_prove" "$gate_a_total" "$UNSORRY_MAX_OPEN_PROVE_PRS" "$UNSORRY_MAX_GATE_A_IN_FLIGHT" "$inflight" "${UNSORRY_MAX_GOALS_IN_FLIGHT:-25}")"; then
    log "submission governor paused: $reason (open_prove_prs=$open_prove gate_a_queued=$queued gate_a_in_progress=$in_progress agent_in_flight=${inflight:-?})"
    return 1
  fi
  log "submission governor open: open_prove_prs=$open_prove gate_a_queued=$queued gate_a_in_progress=$in_progress agent_in_flight=${inflight:-?}"
  return 0
}

decompose_blocked_by_open_prove_pr() {
  local goal="$1"
  if open_prove_pr_exists "$goal"; then
    log "decompose($goal): open prove PR already exists — refusing to decompose"
    return 0
  fi
  return 1
}

# Step 4: write + commit + push the claim; first-push-wins with retry. The
# loop is re-entrant (SPEC-007-A): every retry rebuilds the claim commit from
# scratch on a freshly-fetched, hard-reset origin/claims tip — no incremental
# rebase state to strand — and every exit path leaves the worktree hard-reset
# to origin/claims, so a cycle that dies here never leaves unpushed local
# commits behind for the next cycle.
claim_goal() {
  local goal="$1"
  # ADR-068: fork mode is claimless — the claims branch is upstream-only and
  # fork-inaccessible, so there is no claim to push. Merge-time dedup (ADR-064,
  # checked at selection) plus the upstream kernel are the coordination backstop;
  # a duplicate fork proof wastes only verifier compute, never soundness.
  [ "$FORK_MODE" = 1 ] && return 0
  local file="claims/${goal}.${AGENT_ID}.aisp" ts attempt recheck
  # Post-fetch recheck helper (step 4): the cap is per-mode (SPEC-007-A —
  # prove cap 1, translate cap 2), and a rejected push is most often the
  # rival's claim landing first, so the wrong cap re-claims the same goal
  # (the #184/#185 race).
  recheck=claimable
  [ "$PROVE" -eq 1 ] && recheck=prove-claimable
  for attempt in 1 2 3 4; do  # initial push + up to 3 from-scratch retries
    if [ "$attempt" -gt 1 ]; then
      log "claim push rejected for $goal (attempt $((attempt - 1))) — rebasing from scratch"
      git -C "$CLAIMS_WT" fetch -q origin claims 2>/dev/null || continue
      git -C "$CLAIMS_WT" reset --hard -q origin/claims || break
      # Withdraw when the cap filled meanwhile.
      py_helper "$recheck" "$CLAIMS_WT/claims" "$goal" "$AGENT_ID" || break
    fi
    ts="$(py_helper now)" || break
    render_claim_record "$goal" "$AGENT_ID" "$ts" "$UNSORRY_TTL" \
      > "$CLAIMS_WT/$file" || break
    git -C "$CLAIMS_WT" add "$file" || break
    git -C "$CLAIMS_WT" commit -q -m "claim: $goal $AGENT_ID" || break
    if git -C "$CLAIMS_WT" push -q origin claims 2>/dev/null; then
      # ADR-072: post-SUCCESS recheck. Claim files are per-agent
      # (claims/<goal>.<agent>.aisp), so a rival's claim lands as a CLEAN
      # fast-forward — no push rejection — whenever our base already contained it
      # (we fetched after they pushed). The only recheck above runs on rejection,
      # so two agents whose claims both pushed cleanly would BOTH prove the goal:
      # the prove-time race that creates the sibling branches behind the
      # post-ADR-064 duplicates. Re-fetch and re-apply the per-mode cap; if other
      # agents now meet it, withdraw. Conservative: a tight tie can make both
      # withdraw and the goal is re-selected next cycle — never two provers on one
      # goal. Best-effort: a failed re-fetch leaves the claim (TTL/Gate-B catch it).
      if git -C "$CLAIMS_WT" fetch -q origin claims 2>/dev/null \
        && git -C "$CLAIMS_WT" reset --hard -q origin/claims \
        && ! py_helper "$recheck" "$CLAIMS_WT/claims" "$goal" "$AGENT_ID"; then
        release_claim "$goal" || true
        emit_event collision "$goal"
        log "lost $goal on post-claim recheck — withdrawing"
        return 1
      fi
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
# Falls back from fable to opus if fable is not available.
call_claude() {
  local prompt="$1"
  local model="$UNSORRY_MODEL"
  
  # If model is fable, check availability and fall back to opus if needed
  if [ "$model" = "fable" ] && ! claude_model_available "fable"; then
    log "fable model not available, falling back to opus"
    model="opus"
  fi
  
  timeout "$UNSORRY_WALL" claude -p "$prompt" \
    --model "$model" --output-format text --tools ""
}

# OpenAI translation call (no tools, similar to claude translate)
call_openai_translate() {
  local prompt="$1"
  local model="${UNSORRY_MODEL:-gpt-4o-mini}"
  
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    log "Error: OPENAI_API_KEY environment variable required for OpenAI provider"
    return 1
  fi
  
  python3 "$(dirname "$0")/../tools/llm_providers/openai_cli.py" \
    -p "$prompt" --model "$model" --output-format text
}

# Unified translate call that dispatches to the configured provider
call_translate() {
  local prompt="$1"
  case "${UNSORRY_TRANSLATE_PROVIDER:-$UNSORRY_PROVIDER}" in
    claude) call_claude "$prompt" ;;
    openai) call_openai_translate "$prompt" ;;
    *) call_claude "$prompt" ;;  # Default to claude
  esac
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
    if ! raw="$(call_translate "$prompt")"; then
      log "translate call failed or timed out for $goal (attempt $attempt)"
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

# ───────────────────────────── prove cycle (Phase 1) ─────────────────────────
# Reuses the claim / PR / release plumbing above; the prove arm differs only
# in the work (drive `claude` to write a Lean proof module) and verify
# (lake build --wfail ∧ axiom_audit ∧ check_library_options) steps.

PROVE_PROMPT_FILE="swarm/prompts/prove.md"
DECOMPOSE_PROMPT_FILE="swarm/prompts/decompose.md"
# ADR-009 decomposition on prove failure is on by default; UNSORRY_DECOMPOSE=0
# reverts to the Phase-1 demote-only failure path.
PROVE_DECOMPOSE="${UNSORRY_DECOMPOSE:-1}"

# ADR-024 cross-cycle lesson memory: surface prior failed/decomposed lesson
# signatures into the prove prompt and record this run's own failure signature.
# On by default; UNSORRY_LESSONS=0 makes a run byte-identical to pre-ADR-024
# behaviour, so the feature can be A/B measured.
UNSORRY_LESSONS="${UNSORRY_LESSONS:-1}"

# ADR-013/ADR-015 model/effort policy. Proof-surface calls (prove, decompose)
# default to the most capable model — success-per-attempt is the lever that
# dominates time-to-proved on hard targets; the kernel and gates make model
# choice a performance knob, never a soundness one. Effort defaults to the
# ADR-015 ladder (attempts climb high→xhigh→max, paying for deep reasoning
# only on statements that resisted a cheaper pass); a set UNSORRY_EFFORT pins
# every attempt. Translation is not a proof run and stays on the cheaper
# default. Pure resolver so the policy is testable: prints "<model> <effort>"
# ("-" = no effort flag); the CLI help text drives the --effort fail-soft
# probe (older CLIs lack the flag and contributor agents must not break on it).
resolve_model_effort() {
  local mode="$1" model_env="$2" effort_env="$3" help_text="$4"
  local model effort
  if [ "$mode" = prove ]; then
    model="${model_env:-fable}"
    effort="${effort_env:-ladder}"
  else
    model="${model_env:-sonnet}"
    effort="${effort_env:-}"
  fi
  if [ -n "$effort" ] && ! grep -q -- '--effort' <<<"$help_text"; then
    effort=""
  fi
  printf '%s %s\n' "$model" "${effort:--}"
}

# ADR-015 progressive escalation: maps an attempt number to its effort token
# ("" = no flag). On the ladder, attempt 1 → high, 2 → xhigh, 3+ → max (the
# word "top" also lands on the last rung — used where the ladder is known to
# be exhausted, e.g. decomposition). Anything but "ladder" pins every attempt:
# an explicit UNSORRY_EFFORT passes through, the fail-soft empty stays empty.
effort_for_attempt() {
  local attempt="$1" effort="$2"
  if [ "$effort" != "ladder" ]; then
    printf '%s\n' "$effort"
    return 0
  fi
  case "$attempt" in
    1) echo high ;;
    2) echo xhigh ;;
    *) echo max ;;
  esac
}

# Codex uses a different upper effort vocabulary than Claude. Keep the
# existing Claude ladder unchanged; the local Codex smoke ladder is
# medium→high→xhigh.
provider_effort_for_attempt() {
  local provider="$1" attempt="$2" effort="$3"
  if [ "$provider" = codex ] && [ "$effort" = ladder ]; then
    case "$attempt" in
      1) echo medium ;;
      2) echo high ;;
      *) echo xhigh ;;
    esac
    return 0
  fi
  if [ "$provider" = gemini ] && [ "$effort" = ladder ]; then
    case "$attempt" in
      1) echo high ;;
      2) echo xhigh ;;
      *) echo max ;;
    esac
    return 0
  fi
  effort_for_attempt "$attempt" "$effort"
}

prove_attempt_budget_default() {
  printf '3\n'
}

# ADR-016 pure classifier: a failed claude call counts as an infrastructure
# failure only when it died fast (a real prove attempt cannot fail in under
# the fast-fail threshold — the model has to at least read the goal and try a
# build) AND the follow-up health probe also failed (probe_rc != 0). Anything
# else stays a real attempt. Infrastructure failures must never demote,
# decompose or emit prove-failed: a CLI that never ran is zero evidence about
# the goal — twice now a quota outage has demoted a whole tree below τ_v.
classify_call_failure() {
  local duration="$1" fastfail="$2" probe_rc="$3"
  if [ "$duration" -lt "$fastfail" ] && [ "$probe_rc" -ne 0 ]; then
    echo infra
  else
    echo real
  fi
}

# ADR-016: a near-free call answering "can claude run at all right now?".
# Deliberately the cheap model — the probe must not draw from the premium
# budget whose exhaustion it is diagnosing. Only invoked after a fast-failed
# call, so it costs nothing on the healthy path.
cli_health_probe() {
  case "$UNSORRY_PROVIDER" in
    claude)
      timeout 90 claude -p "Reply with exactly: OK" --model sonnet \
        --output-format text >/dev/null 2>&1
      ;;
    codex)
      PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" \
        timeout 90 codex exec --sandbox read-only --ephemeral \
          --ignore-user-config --ignore-rules -c 'approval_policy="never"' \
          -c 'shell_environment_policy.inherit="all"' \
          --color never "Reply with exactly: OK" >/dev/null 2>&1
      ;;
    gemini)
      # The Gemini CLI can leave model-prompt probe children stopped, which
      # prevents `timeout` from returning. For ADR-016 we only need to know the
      # local CLI is callable; avoid a network/model prompt in the health path.
      timeout 10 gemini --version >/dev/null 2>&1
      ;;
    openai)
      # On a custom OpenAI-compatible endpoint (OPENAI_BASE_URL / -pi, ADR-025)
      # the cheap default model won't exist; probe with the configured model so
      # a real failure isn't misclassified as infrastructure (ADR-016).
      local probe_model="gpt-4o-mini"
      [ -n "${OPENAI_BASE_URL:-}" ] && probe_model="${UNSORRY_MODEL:-gpt-4o-mini}"
      timeout 90 python3 "$(dirname "$0")/../tools/llm_providers/openai_cli.py" \
        -p "Reply with exactly: OK" --model "$probe_model" --output-format text >/dev/null 2>&1
      ;;
    *) return 1 ;;
  esac
}

# Check if a specific Claude model is available.
# Returns 0 if available, 1 otherwise.
claude_model_available() {
  local model="$1"
  timeout 30 claude -p "Reply with exactly: OK" --model "$model" \
    --output-format text >/dev/null 2>&1
}

# Prove step 5: one claude call constrained to write the target Lean module.
# --max-turns does not exist on claude 2.1.170 (the translate cycle dropped it
# for the same reason); the $UNSORRY_WALL timeout bounds the call instead.
# Tools are limited to reading/editing/writing and the read-only lake/git
# commands the prover needs to check its own work (build, env, exe, diff).
# Falls back from fable to opus if fable is not available.
call_claude_prove() {
  local prompt="$1" workdir="$2" effort="$3"
  local -a eff=()
  local model="$UNSORRY_MODEL"
  [ -n "$effort" ] && eff=(--effort "$effort")
  
  # If model is fable, check availability and fall back to opus if needed
  if [ "$model" = "fable" ] && ! claude_model_available "fable"; then
    log "fable model not available, falling back to opus"
    model="opus"
  fi
  PROOF_MODEL_USED="$model"
  
  ( cd "$workdir" \
    && timeout "$UNSORRY_WALL" claude -p "$prompt" \
         --model "$model" "${eff[@]}" --output-format text \
         --allowedTools \
           "Read,Edit,Write,Bash(lake build *),Bash(lake env *),Bash(lake exe *),Bash(git diff *)" )
}

call_codex_prove() {
  local prompt="$1" workdir="$2" effort="$3"
  local -a args=(
    exec
    --cd "$workdir"
    --sandbox workspace-write
    --ephemeral
    --ignore-user-config
    --ignore-rules
    -c 'approval_policy="never"'
    -c 'shell_environment_policy.inherit="all"'
    --color never
  )
  [ -n "$UNSORRY_MODEL" ] && args+=(--model "$UNSORRY_MODEL")
  [ -n "$effort" ] && args+=(-c "model_reasoning_effort=\"$effort\"")
  PROOF_MODEL_USED="${UNSORRY_MODEL:-}"
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" \
    timeout "$UNSORRY_WALL" codex "${args[@]}" - <<<"$prompt"
}

call_gemini_prove() {
  local prompt="$1" workdir="$2" _effort="$3"
  local model="${UNSORRY_MODEL:-gemini-3.1-pro-preview}"
  PROOF_MODEL_USED="$model"
  # Gemini CLI has no --effort flag. Keep the retry ladder as attempt
  # telemetry, but never forward it to the provider binary.
  ( cd "$workdir" \
    && timeout "$UNSORRY_WALL" gemini --skip-trust --yolo --allowed-mcp-server-names none -p "$prompt" \
         --model "$model" --output-format text < /dev/null )
}

# OpenAI API provider for Unsorry
# Supports GPT-4o, o1, o3-mini, and other OpenAI models
# Requires OPENAI_API_KEY environment variable
call_openai_prove() {
  local prompt="$1" workdir="$2" effort="$3"
  local model="${UNSORRY_MODEL:-gpt-4o}"
  PROOF_MODEL_USED="$model"
  
  # Check for API key
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    log "Error: OPENAI_API_KEY environment variable required for OpenAI provider"
    return 1
  fi
  
  ( cd "$workdir" \
    && timeout "$UNSORRY_WALL" python3 "$(dirname "$0")/../tools/llm_providers/openai_cli.py" \
         -p "$prompt" --model "$model" --prove --workdir "$workdir" --output-format text )
}

call_provider_prove() {
  local prompt="$1" workdir="$2" effort="$3"
  case "$UNSORRY_PROVIDER" in
    claude) call_claude_prove "$prompt" "$workdir" "$effort" ;;
    codex) call_codex_prove "$prompt" "$workdir" "$effort" ;;
    gemini) call_gemini_prove "$prompt" "$workdir" "$effort" ;;
    openai) call_openai_prove "$prompt" "$workdir" "$effort" ;;
    *) log "unsupported prove provider '$UNSORRY_PROVIDER'"; return 1 ;;
  esac
}

call_claude_decompose() {
  local prompt="$1" workdir="$2" effort="$3"
  local -a eff=()
  local model="$UNSORRY_MODEL"
  [ -n "$effort" ] && eff=(--effort "$effort")

  if [ "$model" = fable ] && ! claude_model_available fable; then
    log "fable model not available, falling back to opus"
    model=opus
  fi

  ( cd "$workdir" \
    && timeout "$UNSORRY_WALL" claude -p "$prompt" \
         --model "$model" "${eff[@]}" --output-format text \
         --allowedTools "Read,Bash(lake build *),Bash(lake env *)" )
}

call_codex_decompose() {
  local prompt="$1" workdir="$2" effort="$3"
  local -a args=(
    exec
    --cd "$workdir"
    --sandbox read-only
    --ephemeral
    --ignore-user-config
    --ignore-rules
    -c 'approval_policy="never"'
    -c 'shell_environment_policy.inherit="all"'
    --color never
  )
  [ -n "$UNSORRY_MODEL" ] && args+=(--model "$UNSORRY_MODEL")
  [ -n "$effort" ] && args+=(-c "model_reasoning_effort=\"$effort\"")
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" \
    timeout "$UNSORRY_WALL" codex "${args[@]}" - <<<"$prompt"
}

call_gemini_decompose() {
  local prompt="$1" workdir="$2" _effort="$3"
  local model="${UNSORRY_MODEL:-gemini-3.1-pro-preview}"
  # Gemini CLI has no --effort flag; decomposition still runs at the top
  # logical ladder rung for telemetry, but the CLI argv stays effort-free.
  ( cd "$workdir" \
    && timeout "$UNSORRY_WALL" gemini --skip-trust --allowed-mcp-server-names none -p "$prompt" \
         --model "$model" --output-format text < /dev/null )
}

call_provider_decompose() {
  local prompt="$1" workdir="$2" effort="$3"
  case "$UNSORRY_PROVIDER" in
    claude) call_claude_decompose "$prompt" "$workdir" "$effort" ;;
    codex) call_codex_decompose "$prompt" "$workdir" "$effort" ;;
    gemini) call_gemini_decompose "$prompt" "$workdir" "$effort" ;;
    *) log "unsupported decomposition provider '$UNSORRY_PROVIDER'"; return 1 ;;
  esac
}

# Every proof attempt starts from provider-owned output only. Verification
# creates the binding helper after the provider returns; remove residue from a
# failed verification before the next provider call so the strict path guard
# does not misattribute that agent-generated file to the provider.
prepare_proof_attempt() {
  local root="$1" target="$2" binding="$3"
  rm -f "$root/$target" "$root/$binding"
}

extract_provider_text_module() {
  local root="$1" attempt_log="$2" target="$3"
  [ -s "$attempt_log" ] || return 1
  python3 - "$root" "$attempt_log" "$target" <<'PYEXTRACT'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
attempt_log = Path(sys.argv[2])
target = sys.argv[3]

text = attempt_log.read_text(encoding="utf-8", errors="replace")
text = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", text)

match = re.search(r"```[ \t]*lean[ \t]*\r?\n(.*?)```", text, re.DOTALL | re.IGNORECASE)
if match is None:
    match = re.search(r"```[ \t]*[A-Za-z0-9_+-]*[ \t]*\r?\n(.*?)```", text, re.DOTALL)
if match is None:
    sys.exit(1)

body = match.group(1).strip()
if not body:
    sys.exit(1)

target_path = (root / target).resolve()
try:
    target_path.relative_to(root)
except ValueError:
    sys.exit(1)

target_path.parent.mkdir(parents=True, exist_ok=True)
target_path.write_text(body + "\n", encoding="utf-8")
PYEXTRACT
}

# The provider receives a writable proof worktree, but the proof contract
# permits exactly one changed path: the target module. Enforce that boundary
# after every model call independently of provider-specific tool policy.
#
# One tolerated exception keeps an otherwise-sound proof from being discarded
# over provider litter: a ROOT-LEVEL untracked scratch file (some providers,
# notably gemini, drop a `test.lean` beside the repo root despite the prompt).
# It sits outside every Lean package glob (goals/, library/) and is never
# staged for check-in, so it is removed and tolerated — soundness is unaffected
# because a proof written into the wrong file still fails the missing-target
# check, and a tracked-file edit or an untracked file inside any package / spec
# / tooling tree remains a hard violation. (The agent loop's own
# prove-attempt-*.log lives in the worktree too, but .gitignore keeps it out of
# this status output rather than having it deleted here.)
prove_target_only_changed() {
  local root="$1" target="$2" line code path
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    code="${line:0:2}"
    path="${line:3}"
    case "$path" in
      *" -> "*) path="${path##* -> }" ;;
    esac
    [ "$path" = "$target" ] && continue
    if [ "$code" = "??" ] && [ "$path" = "${path##*/}" ]; then
      log "removed stray root-level provider file '$path' (only '$target' is the proof target)"
      rm -f -- "$root/$path"
      continue
    fi
    log "provider changed forbidden path '$path' (only '$target' is allowed)"
    return 1
  done < <(git -C "$root" status --porcelain=v1 --untracked-files=all)
}

# Keep THIS agent checkout's UnsorryLibrary oleans warm. Called once per cycle
# after sync_repo (so the working tree is at origin/main, the same commit each
# prove worktree branches from). The first call pays a full library build; later
# calls are incremental — only newly-merged modules compile. The result is the
# seed source for seed_library_cache. Best-effort and opt-out via
# UNSORRY_SEED_LIBRARY=0; on failure prove verifies just fall back to the prior
# full-build behaviour.
ensure_warm_library() {
  [ "${UNSORRY_SEED_LIBRARY:-1}" = 0 ] && return 0
  WARM_LIBRARY_ROOT=""
  if ( lake exe cache get && lake build UnsorryLibrary ) >/dev/null 2>&1; then
    WARM_LIBRARY_ROOT="$PWD"
  else
    log "warning: warm library build failed — prove verifies will do a full build this cycle"
  fi
}

# Seed <prwt>'s .lake/build from the warm checkout so `lake build UnsorryLibrary`
# in the prove worktree compiles only the agent's new module instead of the
# whole library. A full copy (not a hardlink) keeps the prove worktree's build
# from ever touching the warm tree's oleans. Both trees sit at the same
# origin/main commit, so Lean's content-hashed traces treat the copied oleans as
# up to date. Best-effort: no warm root (build failed or opted out) ⇒ no-op, and
# the verify falls back to a full build.
seed_library_cache() {
  local prwt="$1" warm="${WARM_LIBRARY_ROOT:-}"
  [ -n "$warm" ] || return 0
  [ -d "$warm/.lake/build" ] || return 0
  [ -e "$prwt/.lake/build" ] && return 0
  mkdir -p "$prwt/.lake" || return 0
  cp -a "$warm/.lake/build" "$prwt/.lake/build" 2>/dev/null || true
}

# Prove step 3: local soundness verification of a candidate proof tree, BEFORE
# any PR (the agent self-verifying per ADR-006 / design-doc step 6). All three
# must pass on the tree at <root> for module Unsorry.<camel>:
#   1. lake build UnsorryLibrary --wfail   (zero-sorry, zero-warning bar)
#   2. lake exe axiom_audit Unsorry.<camel> (whitelist only, NO --allow-sorry)
#   3. python3 -m tools.gate_a.check_library_options <root>/library
# ADR-099 / SPEC-099-A §3: the suite verifier context for a goal, as the tab-separated
# line `toolchain<TAB>mathlib<TAB>verify_dir<TAB>build_target`, or empty when the goal is
# not a registered benchmark obligation. A benchmark goal proves at its SUITE's pin in
# the suite's _verify lake project (already in this checkout), not the repo-wide pin.
suite_context_for_goal() {
  python3 -m tools.intake.suite_context "$1" --root "$2" 2>/dev/null
}

prove_local_verify() {
  local root="$1" camel="$2" lib_target="${3:-UnsorryLibrary}" do_audit="${4:-1}"
  # ``library`` is relative to <root>: the repo root for an organic goal, the suite
  # _verify project for a benchmark goal. The repo axiom_audit exe is absent in a suite
  # package, so do_audit=0 there — Gate A's gate-a-benchmark leg (--wfail + forbidden
  # tokens) verifies at the suite pin instead (ADR-099 §2).
  ( cd "$root" \
    && lake build "$lib_target" --wfail \
    && { [ "$do_audit" != 1 ] || lake exe axiom_audit "Unsorry.$camel"; } \
    && python3 -m tools.gate_a.check_library_options library ) >/dev/null 2>&1
}

# Prove steps 5–6: drive `claude` to write library/Unsorry/<camel>.lean proving
# the goal's theorem, then locally verify. Up to UNSORRY_ATTEMPTS attempts
# (default 3 in prove mode — one per ADR-015 effort rung, high→xhigh→max): on
# a failed build/audit the error is fed back to a fresh call at the next rung,
# then give up. The proof tree is a worktree at <prwt> branched from
# origin/main; on success it carries the proved module ready for check-in.
# Prints nothing; returns 0 with the verified module in place, 1 on failure.
run_proof() {
  local goal="$1" prwt="$2" camel="$3"
  local stmt name target binding prompt attempt attempt_log err="" proof_started
  PROOF_MODEL_USED=""
  PROOF_EFFORT_USED=""
  PROOF_ATTEMPTS_USED=""
  PROOF_SOLVE_SECONDS=""
  PROOF_LAST_ERROR=""
  PROOF_LESSONS_USED=""
  INDEPENDENT_CHECK_VERDICT=""
  proof_started="$(date +%s)"
  name="$(py_helper lean-name "$prwt/goals/$goal.lean")" || return 1
  stmt="$(py_helper lean-stmt "$prwt/goals/$goal.lean")" || return 1
  # ADR-099 / SPEC-099-A §3: a benchmark goal proves at its SUITE's pin in the suite
  # verifier context (targets/<suite>/_verify — a lake project pinned to the suite's
  # toolchain+mathlib, already committed in this checkout), not the repo-wide pin.
  # Organic goals leave every variable at its repo default (empty context), so their
  # path below is byte-identical to before.
  local lib_rel="library" lib_target="UnsorryLibrary" do_audit=1 build_dir="$prwt" sctx vdir
  sctx="$(suite_context_for_goal "$goal" "$prwt")"
  if [ -n "$sctx" ]; then
    vdir="$(printf '%s' "$sctx" | cut -f3)"
    lib_rel="$vdir/library"
    lib_target="$(printf '%s' "$sctx" | cut -f4)"
    do_audit=0
    build_dir="$prwt/$vdir"
    log "benchmark goal $goal → proving at the suite pin in $vdir (target $lib_target); repo axiom_audit skipped — Gate A's gate-a-benchmark leg verifies at the suite pin (ADR-099)"
  fi
  target="$lib_rel/Unsorry/$camel.lean"
  binding="$lib_rel/Unsorry/${camel}Binding.lean"
  # The PR worktree is a fresh checkout with no .lake (it is gitignored), so
  # the mathlib oleans are absent and `lake build … --wfail` would otherwise
  # recompile all of mathlib from source and blow the attempt budget (observed in
  # phase1-run-001). Restore the prebuilt cache once, up front, in the build dir
  # (the suite _verify project for a benchmark goal — its own pin's cache).
  # Best-effort: a warm global cache makes this a ~20s no-op; on failure the
  # build still works, just slowly, so we warn rather than abort.
  if ! ( cd "$build_dir" && lake exe cache get ) >/dev/null 2>&1; then
    log "warning: 'lake exe cache get' failed in the prove worktree for $goal — verification may be slow"
  fi
  # cache get restores only *mathlib* oleans; the project's own UnsorryLibrary
  # modules (hundreds, and growing with every merged proof) are not in any cache
  # and would otherwise be recompiled from scratch in this fresh worktree on
  # every verify (~9 min, and far worse when many agents contend for cores).
  # Seed them from this agent's warm checkout (kept built by ensure_warm_library,
  # pinned to the same origin/main commit the prove worktree branches from) so
  # the verify compiles only the new module. Soundness is unaffected: CI Gate A
  # re-verifies the whole library from scratch (ADR-049), so this only speeds the
  # local pre-check. Best-effort: a miss just falls back to the full build.
  seed_library_cache "$prwt"
  # ADR-014 dependency reuse: surface this goal's PROVED dependencies (declared
  # deps + the subs of its own decomposition) as importable library modules, so
  # merged work compounds instead of being re-proved.
  local deps_prompt="" deps_lines
  deps_lines="$(py_helper proved-deps "$prwt/goals/$goal.aisp" "$prwt/goals" \
    "$prwt/library" "$prwt/decompositions" 2>/dev/null)" || deps_lines=""
  if [ -n "$deps_lines" ]; then
    deps_prompt="

PROVED DEPENDENCIES (ADR-014) — these lemmas are already kernel-verified in
THIS repository's library. Import their modules and use them; do not re-prove
them. The import-tightness rule explicitly allows these Unsorry.* imports:
$(printf '%s\n' "$deps_lines" | awk -F'\t' '{printf "- import %s\n    %s\n", $1, ($3 != "" ? $3 : "theorem " $2)}')"
  fi
  # ADR-024 lesson reuse: surface prior failed/decomposed attempt signatures for
  # THIS goal (merged onto origin/main, so cross-cycle and cross-agent) and count
  # them for the run record. Gated by UNSORRY_LESSONS so the off-state matches
  # pre-ADR-024 behaviour exactly.
  local lessons_prompt="" lessons_lines
  if [ "$UNSORRY_LESSONS" = 1 ]; then
    lessons_lines="$(py_helper prove-lessons "$goal" "$prwt/proof-runs" 2>/dev/null)" || lessons_lines=""
    if [ -n "$lessons_lines" ]; then
      PROOF_LESSONS_USED="$(printf '%s\n' "$lessons_lines" | grep -c .)"
      lessons_prompt="

PRIOR FAILED ATTEMPTS (ADR-024) — earlier proof attempts on THIS goal failed
with the local-verifier signatures below. Do NOT repeat these dead ends; choose
a materially different approach:
$(printf '%s\n' "$lessons_lines" | awk 'NF{print "- " $0}')"
    else
      PROOF_LESSONS_USED=0
    fi
  fi
  local eff_tok t0 dur probe_rc
  for attempt in $(seq 1 "$UNSORRY_ATTEMPTS"); do  # ADR-015 ladder, default 3
    eff_tok="$(provider_effort_for_attempt "$UNSORRY_PROVIDER" "$attempt" "$UNSORRY_EFFORT")"
    PROOF_EFFORT_USED="$eff_tok"
    PROOF_ATTEMPTS_USED="$attempt"
    log "prove attempt $attempt/$UNSORRY_ATTEMPTS for $goal (effort ${eff_tok:-default})"
    prompt="$(cat "$PROVE_PROMPT_FILE")
$stmt

Target module file (relative to repo root): $target
Lean module name (for the audit): Unsorry.$camel
Theorem name to re-state and prove: $name$deps_prompt$lessons_prompt"
    if [ -n "$err" ]; then
      prompt="$prompt

A previous attempt's module did NOT pass local verification. The combined
\`lake build UnsorryLibrary --wfail\` / \`lake exe axiom_audit Unsorry.$camel\`
output was:
$err
Fix the module so both pass. Write the corrected $target."
    fi
    prepare_proof_attempt "$prwt" "$target" "$binding"
    t0="$(date +%s)"
    attempt_log="$prwt/prove-attempt-$attempt.log"
    log "running proof generation (logging to $attempt_log)..."
    if ! call_provider_prove "$prompt" "$prwt" "$eff_tok" > "$attempt_log" 2>&1; then
      dur=$(( $(date +%s) - t0 ))
      # ADR-016: a call that died fast probably never reached the model.
      if [ "$dur" -lt "$UNSORRY_FASTFAIL" ]; then
        probe_rc=0; cli_health_probe || probe_rc=$?
        if [ "$(classify_call_failure "$dur" "$UNSORRY_FASTFAIL" "$probe_rc")" = infra ]; then
          log "$UNSORRY_PROVIDER call for $goal died in ${dur}s and the health probe failed — infrastructure failure, aborting cycle (ADR-016)"
          return 2
        fi
      fi
      log "$UNSORRY_PROVIDER prove call failed or timed out for $goal (attempt $attempt)"
      err="($UNSORRY_PROVIDER call failed or timed out)"
      continue
    fi
    if [ ! -f "$prwt/$target" ] \
      && extract_provider_text_module "$prwt" "$attempt_log" "$target"; then
      log "extracted $target from provider text output (attempt $attempt)"
    fi
    if ! prove_target_only_changed "$prwt" "$target"; then
      log "provider path policy failed for $goal (attempt $attempt)"
      PROOF_SOLVE_SECONDS=$(( $(date +%s) - proof_started ))
      return 1
    fi
    if [ ! -f "$prwt/$target" ]; then
      log "prover did not write $target for $goal (attempt $attempt)"
      err="(no file was written at $target)"
      continue
    fi
    # ADR-011 statement binding: emit a kernel obligation asserting the proved
    # theorem inhabits the GOAL's exact type. Built by prove_local_verify's
    # --wfail build below (and by Gate A in CI), so a proof of a weakened or
    # vacuous statement under the goal's name fails here, not just in review.
    write_binding_module "$prwt" "$goal" "$camel" "$lib_rel" || { err="(could not emit binding obligation)"; continue; }
    if prove_local_verify "$build_dir" "$camel" "$lib_target" "$do_audit"; then
      # ADR-074/096 import-narrowing + kernel-diverse confirm are repo-pin-only
      # best-effort/advisory passes; skip them for a benchmark goal (its module
      # lives in the suite package, at the suite pin) — they never gate the proof.
      if [ -z "$sctx" ]; then
        minimize_proof_imports "$prwt" "$camel"   # ADR-074: best-effort, never fails the proof
        independent_check_advisory "$prwt" "$camel"  # ADR-096: best-effort kernel-diverse confirm, never fails the proof
      fi
      PROOF_SOLVE_SECONDS=$(( $(date +%s) - proof_started ))
      log "proof of $goal verified locally — statement bound (attempt $attempt)"
      return 0
    fi
    log "local verification of $goal failed (attempt $attempt)"
    err="$( ( cd "$build_dir" && lake build "$lib_target" --wfail \
      && { [ "$do_audit" != 1 ] || lake exe axiom_audit "Unsorry.$camel"; } ) 2>&1 | tail -n 40 )"
  done
  PROOF_SOLVE_SECONDS=$(( $(date +%s) - proof_started ))
  # ADR-024: the final attempt's verifier output becomes this run's lesson,
  # consumed by write_proof_run_record on the failed/decomposed outcome.
  PROOF_LAST_ERROR="$err"
  return 1
}

# ADR-074: after a proof verifies, try a deterministically narrower import set and
# re-verify; on ANY failure restore the original file byte-for-byte. Best-effort by
# design — narrowing can never reject a sound proof, it only shrinks the mathlib
# closure that Gate A's build / kernel replay / axiom audit must load (~2x faster
# audit when it applies, #2397). Gated by UNSORRY_MIN_IMPORTS (default 1; set 0 to
# disable). tools.proof.min_imports prints the narrowed module (rc 0) or nothing
# (rc 1 when there is no known narrowing for this proof).
minimize_proof_imports() {
  [ "${UNSORRY_MIN_IMPORTS:-1}" = "1" ] || return 0
  local prwt="$1" camel="$2"
  local rel="library/Unsorry/$camel.lean"
  local target="$prwt/$rel"
  [ -f "$target" ] || return 0
  local narrowed bak
  narrowed="$(mktemp)" || return 0
  if ! ( cd "$prwt" && python3 -m tools.proof.min_imports "$rel" ) > "$narrowed" 2>/dev/null \
     || [ ! -s "$narrowed" ]; then
    rm -f "$narrowed"; return 0
  fi
  bak="$(mktemp)" || { rm -f "$narrowed"; return 0; }
  cp "$target" "$bak"
  cp "$narrowed" "$target"
  if prove_local_verify "$prwt" "$camel" >/dev/null 2>&1; then
    log "narrowed imports for $camel — re-verified (ADR-074)"
  else
    cp "$bak" "$target"
    log "narrowed imports for $camel did not build — kept import Mathlib (ADR-074)"
  fi
  rm -f "$narrowed" "$bak"
  return 0
}

# ADR-096 Phase 3a: advisory kernel-diverse independent check. Opt-in via
# UNSORRY_INDEPENDENT_CHECK (default off), NON-GATING. After a proof verifies
# locally, re-check it with an independent Lean kernel (nanoda) over a
# declaration-scoped lean4export of the proved theorem — a second-kernel
# confirmation. ADVISORY ONLY: it admits nothing and is strictly subordinate to
# ADR-049's p=1 Lean gate (which still runs in CI regardless). It NEVER fails the
# prove loop — if the tools (LEAN4EXPORT_BIN / NANODA_BIN) are absent or the check
# errors, it logs and returns 0. A nanoda disagreement is surfaced as a warning,
# never a block. Mirrors minimize_proof_imports's best-effort pattern.
independent_check_advisory() {
  env_truthy "${UNSORRY_INDEPENDENT_CHECK:-}" || return 0
  local prwt="$1" camel="$2"
  local l4e="${LEAN4EXPORT_BIN:-}" nan="${NANODA_BIN:-}"
  if [ -z "$l4e" ] || [ -z "$nan" ] || [ ! -x "$nan" ]; then
    log "independent-check: requested but lean4export/nanoda unavailable (set LEAN4EXPORT_BIN and an executable NANODA_BIN) — skipping (ADR-096)"
    return 0
  fi
  local out
  out="$( ( cd "$prwt" && python3 -m tools.independent_check \
            --module "Unsorry.$camel" \
            --lean4export-cmd "lake env $l4e" --nanoda-cmd "$nan" ) 2>&1 )" || true
  [ -n "$out" ] && log "$out"
  # Capture the one-line verdict (drop the "independent-check: <module> " prefix
  # and any ::warning:: noise) so the proof commit can carry it to the PR.
  local verdict
  verdict="$(printf '%s\n' "$out" | sed -n 's/^independent-check: [^ ]* //p' | head -1)"
  [ -n "$verdict" ] && INDEPENDENT_CHECK_VERDICT="$verdict"
  return 0
}

# ADR-096: the verdict rides the proof commit as an `Independent-Check:` trailer
# and the dispatcher surfaces it on the PR via independent_check_pr_note. A commit
# WITHOUT the trailer yields an empty note (a normal proof shows nothing extra).
test_independent_check_pr_note_roundtrip() {
  local d; d="$(mktemp -d)" || return 1
  ( git -C "$d" init -q \
    && git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty \
         -m "prove(g): foo by a" -m "Independent-Check: nanoda=ok decls=3965 target=✓ 0.4s" ) \
    || { rm -rf "$d"; log "  setup failed"; return 1; }
  local note
  note="$(cd "$d" && independent_check_pr_note HEAD)"
  case "$note" in
    *"advisory, ADR-096"*"nanoda=ok decls=3965 target=✓"*) ;;
    *) rm -rf "$d"; log "  trailer not surfaced: [$note]"; return 1 ;;
  esac
  # a plain prove commit (no trailer) → empty note
  ( git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "prove(g2): bar by a" )
  note="$(cd "$d" && independent_check_pr_note HEAD)"
  rm -rf "$d"
  [ -z "$note" ] || { log "  expected empty note for a plain proof, got [$note]"; return 1; }
  return 0
}

# ADR-096: the independent check is opt-in and never breaks proving. Off by
# default → no-op exit 0; on but tools absent → skip (no python invoked) exit 0.
test_independent_check_advisory_opt_in() {
  local ran=0
  python3() { ran=1; return 0; }  # tripwire: must NOT be invoked in either case
  # default (unset) → no-op, returns 0, python untouched
  ( unset UNSORRY_INDEPENDENT_CHECK; independent_check_advisory /tmp/x Foo ) \
    || { log "  default-off should return 0"; unset -f python3; return 1; }
  # on, but NANODA_BIN absent → skips gracefully, returns 0, python untouched
  ( UNSORRY_INDEPENDENT_CHECK=1 LEAN4EXPORT_BIN='' NANODA_BIN='' independent_check_advisory /tmp/x Foo ) \
    || { log "  on-but-tools-absent should return 0"; unset -f python3; return 1; }
  [ "$ran" = 0 ] || { log "  python must not run without the tools present"; unset -f python3; return 1; }
  unset -f python3
  return 0
}

# ADR-011 / SPEC-011-A: write library/Unsorry/<Camel>Binding.lean — a kernel
# obligation `theorem <name>_binding_check : <∀-goal-type> := <name>`. It
# type-checks iff the proved theorem's type is definitionally equal to the
# goal's stated type (a more-general proof still satisfies it via implicit
# insertion; a weaker/vacuous one does not). Built under --wfail, so the kernel
# itself performs the defeq binding — no metaprogram, no name clash.
write_binding_module() {
  local prwt="$1" goal="$2" camel="$3" lib_rel="${4:-library}" name ftype opens
  name="$(py_helper lean-name "$prwt/goals/$goal.lean")" || return 1
  ftype="$(py_helper lean-foralltype "$prwt/goals/$goal.lean")" || return 1
  # The goal's own `open` commands travel with the type (a statement written
  # under `open Finset` names `range` unqualified) — same as Gate A's
  # regenerated obligation, so the local self-verify matches CI.
  opens="$(py_helper lean-opens "$prwt/goals/$goal.lean")" || return 1
  {
    printf 'import Unsorry.%s\n\n' "$camel"
    if [ -n "$opens" ]; then printf '%s\n' "$opens"; fi
    # linter.unusedVariables is suppressed to match Gate A's regenerated
    # obligation (tools/gate_a/check_statement_binding.py): the binding restates
    # the goal's binders verbatim, so a goal hypothesis a correct proof leaves
    # unused (or a named binder eta-expanded after an implicit one) is flagged
    # unused and fails this --wfail self-verify — wrongly rejecting a proof CI
    # accepts and forcing a needless decomposition. The binding's force is
    # type-checking, not lints.
    printf 'set_option linter.unusedVariables false in\n'
    printf 'theorem %s_binding_check : %s := %s\n' "$name" "$ftype" "$name"
  } > "$prwt/$lib_rel/Unsorry/${camel}Binding.lean"
}

# Persist one terminal proof-run fact in the same PR as its durable outcome.
# Infrastructure failures are deliberately excluded: they provide no evidence
# about goal or model performance (ADR-016). Runs that fail before a provider
# attempt are also omitted because attempts≜0 is not comparable telemetry.
write_proof_run_record() {
  local prwt="$1" goal="$2" outcome="$3" sha="${4:-}"
  local run_id path
  [ -n "$PROOF_ATTEMPTS_USED" ] || return 0
  [ -n "$PROOF_SOLVE_SECONDS" ] || return 0
  run_id="$(py_helper run-id)" || return 1
  path="proof-runs/$goal.$AGENT_ID.$run_id.aisp"
  mkdir -p "$prwt/proof-runs" || return 1
  local -a optional=()
  [ -n "$PROOF_MODEL_USED" ] && optional+=(--model "$PROOF_MODEL_USED")
  [ -n "$PROOF_EFFORT_USED" ] && optional+=(--effort "$PROOF_EFFORT_USED")
  # ADR-024: record how many prior lessons this run consumed (the measurement
  # hook) and, on a non-proved outcome, its own failure signature. render-run
  # sanitises the raw error and omits an empty signature.
  [ -n "$PROOF_LESSONS_USED" ] && optional+=(--lessons-used "$PROOF_LESSONS_USED")
  if [ "$outcome" != proved ] && [ -n "$PROOF_LAST_ERROR" ]; then
    optional+=(--lesson "$PROOF_LAST_ERROR")
  fi
  py_helper render-run "$run_id" "$goal" "$AGENT_ID" "$outcome" \
    "$SOLVER" "$UNSORRY_PROVIDER" "$PROOF_ATTEMPTS_USED" \
    "$PROOF_SOLVE_SECONDS" "$sha" "${optional[@]}" > "$prwt/$path"
}

# A proof budget may be genuinely exhausted even when the subsequent
# decomposition call hits infrastructure. Preserve that evidence without
# applying the ADR-010 demotion or pretending decomposition completed.
check_in_failed_run_only() {
  local goal="$1" reason="${2:-proof attempts exhausted their budget, but the subsequent decomposition call hit an infrastructure failure}" prwt branch
  branch="$(feature_branch telemetry "$goal")" || return 1
  prwt="$UNSORRY_WORKDIR/telemetry-${goal}-${AGENT_ID}"
  open_pr_worktree "$prwt" "$branch" || return 1
  if write_proof_run_record "$prwt" "$goal" failed; then
    submit_pr_tree "$prwt" "$branch" \
      "chore: record failed proof run for $goal by $AGENT_ID" \
      "Automated terminal-run telemetry (ADR-023, SPEC-023-A): $reason. This records the proof evidence only; it does not demote, block, or otherwise change the goal." \
      proof-runs || true
  fi
  git worktree remove --force "$prwt" >/dev/null 2>&1 || true
  git branch -q -D "$branch" >/dev/null 2>&1 || true
}

# Prove steps 7–9: on a verified proof, compute the goal's Lean-statement
# content address, write library/index/<sha>.aisp, flip the goal record to
# status≜proved + sha≜<sha>, and open an auto-merge PR carrying the library
# module + index entry + goal edit. Reuses submit_pr_tree (Gate B validate,
# commit, push, gh pr create/merge --auto --squash). The PR tree already holds
# the verified module (run_proof wrote it into <prwt>).
check_in_proof() {
  local goal="$1" prwt="$2" camel="$3"
  local name sha title body branch
  local -a provenance=(
    --solver "$SOLVER"
    --agent "$AGENT_ID"
    --provider "$UNSORRY_PROVIDER"
    --effort "$PROOF_EFFORT_USED"
    --attempts "$PROOF_ATTEMPTS_USED"
    --solve-s "$PROOF_SOLVE_SECONDS"
  )
  [ -n "$PROOF_MODEL_USED" ] && provenance+=(--model "$PROOF_MODEL_USED")
  name="$(py_helper lean-name "$prwt/goals/$goal.lean")" || return 1
  sha="$(py_helper lean-sha "$prwt/goals/$goal.lean")" || return 1

  # ADR-099 / SPEC-099-A §3: a benchmark proof lives in its suite's _verify package
  # (kernel-verified at the suite pin), not the repo library — route the index +
  # binding + staged tree accordingly. Organic goals stay byte-identical (empty sctx).
  local lib_rel="library" stage_root="library" sctx vdir
  sctx="$(suite_context_for_goal "$goal" "$prwt")"
  if [ -n "$sctx" ]; then
    vdir="$(printf '%s' "$sctx" | cut -f3)"
    lib_rel="$vdir/library"
    stage_root="$(printf '%s' "$vdir" | cut -d/ -f1)"  # "targets"
  fi

  mkdir -p "$prwt/$lib_rel/index" || return 1
  py_helper render-index "$sha" "$goal" "$name" "${provenance[@]}" \
    > "$prwt/$lib_rel/index/$sha.aisp" || return 1
  write_proof_run_record "$prwt" "$goal" proved "$sha" || return 1
  py_helper rewrite-goal "$prwt/goals/$goal.aisp" proved "$sha" || return 1
  # ⊕ a merge reinforces the goal's pattern (+1 affinity, ADR-010); folds
  # into the same gated prove PR.
  py_helper aff-bump "$prwt/goals/$goal.aisp" "$(py_helper aff-delta merge)" || return 1
  # The self-check binding (run_proof) is not committed: Gate A REGENERATES the
  # binding obligation from the goal so a contributor cannot weaken or omit it
  # (ADR-011, SPEC-011-A). Remove it from the PR tree.
  rm -f "$prwt/$lib_rel/Unsorry/${camel}Binding.lean"

  branch="$(git -C "$prwt" rev-parse --abbrev-ref HEAD)" || return 1
  title="prove($goal): $name by $AGENT_ID"
  body="Automated Phase-1 proof of goal \`$goal\` by agent \`$AGENT_ID\` (ADR-006, ADR-007, SPEC-007-A). New library module \`$lib_rel/Unsorry/$camel.lean\` re-states and proves \`$name\`; built with \`lake build --wfail\` at the suite/repo pin. Index entry keyed by the content address of the goal's Lean statement."
  if [ "$UNSORRY_SUBMIT_MODE" = queue ]; then
    queue_pr_tree "$prwt" "$branch" "$title" "$stage_root" goals proof-runs || return 1
    emit_event proved "$goal"
    emit_event queued "$goal"
    log "queued verified proof branch $branch for $goal (sha ${sha:0:12})"
    return 0
  fi

  submit_pr_tree "$prwt" "$branch" "$title" "$body" "$stage_root" goals proof-runs || return 1
  emit_event proved "$goal"
  emit_event pr-opened "$goal"
  log "opened auto-merge prove PR for $goal (sha ${sha:0:12})"
  return 0
}

# Prove cycle driver (steps 4–10 for one claimed prove goal): claim, open a
# proof worktree, run_proof, check_in_proof, release. On any failure after the
# claim: release the claim and emit prove-failed (Phase-1 keeps it simple — the
# design doc's decomposition path is Phase-2). Returns 0 on a clean cycle.
prove_goal() {
  local goal="$1"
  local camel prwt branch ok=0 prc=0 drc=0
  camel="$(py_helper camel-name "$goal")" || return 1
  if [ "$UNSORRY_SUBMIT_MODE" = queue ]; then
    branch="$(queued_prove_branch "$goal")" || return 1
  else
    branch="$(feature_branch prove "$goal")" || return 1
  fi
  prwt="$UNSORRY_WORKDIR/prove-${goal}-${AGENT_ID}"

  open_pr_worktree "$prwt" "$branch" || return 1
  run_proof "$goal" "$prwt" "$camel" || prc=$?
  if [ "$prc" -eq 0 ]; then
    if check_in_proof "$goal" "$prwt" "$camel"; then
      ok=1
    fi
  fi
  git worktree remove --force "$prwt" >/dev/null 2>&1 || true
  git branch -q -D "$branch" >/dev/null 2>&1 || true

  release_claim "$goal" || true
  # ADR-068: drop the fork-local goal lock taken at selection so the next prover
  # (or this one) can re-surface the goal. Co-located with release_claim, this
  # frees it on the work-path exits below (success, decompose, demote, infra/
  # error); the EARLY `return 1` setup failures above (camel-name/branch/
  # open_pr_worktree) are covered by the belt-and-braces release in the cycle
  # loop (after prove_goal returns) — between them every exit is covered. No-op
  # outside fork mode; release is idempotent and only removes a lock we own.
  release_goal_lock "$goal"
  if [ "$ok" -eq 1 ]; then
    return 0
  fi
  # ADR-016: an infrastructure failure (the CLI never ran) is zero evidence
  # about the goal — release with no event, no decomposition, no demote.
  if [ "$prc" -eq 2 ]; then
    log "infrastructure failure while proving $goal — claim released, no penalty (ADR-016)"
    return 2
  fi
  emit_event prove-failed "$goal"
  # ADR-009: a budget-exhausted goal is decomposed into claimable sub-lemmas and
  # parked `blocked`; the failed attempt now feeds the pool. If decomposition is
  # not possible (depth cap, or claude produced no usable split), fall back to
  # the ADR-010 affinity demote so the goal is at least deprioritised — unless
  # the decompose call itself hit an infrastructure failure (ADR-016).
  if [ "$PROVE_DECOMPOSE" -eq 1 ]; then
    decompose_goal "$goal" || drc=$?
    if [ "$drc" -eq 0 ]; then
      log "prove of $goal failed — decomposed into sub-lemmas, parent blocked (ADR-009)"
      return 1
    fi
    if [ "$drc" -eq 2 ]; then
      check_in_failed_run_only "$goal" || true
      log "infrastructure failure during decompose of $goal — no demote (ADR-016)"
      return 2
    fi
  fi
  # ADR-034 (#388): a failed prove on a parent whose decomposition's sub-lemmas
  # are all proved is a RECOMPOSE attempt, not a fresh prove. The #368 guard
  # (rightly) refuses to re-decompose it, so a full -10 demote here can bury it
  # below τ_v where the unblock→recompose sweep can never auto-retry it. Floor
  # the demote at τ_v so it stays selectable (lowest priority) — recoverable work
  # is never buried (the ADR-016 principle, for a distinct condition).
  if py_helper recompose-candidate "$goal" decompositions library; then
    demote_goal "$goal" "$(py_helper tau-v)" || true
    log "prove of $goal failed (recompose of a proved subtree) — demote floored at τ_v, stays viable (ADR-034, #388)"
    return 1
  fi
  demote_goal "$goal" || true
  log "prove of $goal failed after $UNSORRY_ATTEMPTS attempt(s) — claim released, flagged, affinity -10"
  return 1
}

# Local provider smoke: create a detached worktree from local HEAD, run the
# same proof generation and kernel verification as the swarm, then preserve
# the tree for inspection. This path deliberately performs no fetch, claim,
# push, PR, metrics, decomposition, affinity, or GitHub operation.
prove_local_goal() {
  local goal="$1" camel prwt prc=0 binding target
  camel="$(py_helper camel-name "$goal")" || return 1
  target="library/Unsorry/$camel.lean"
  binding="library/Unsorry/${camel}Binding.lean"
  prwt="${UNSORRY_LOCAL_WORKTREE:-}"
  if [ -z "$prwt" ]; then
    prwt="$(mktemp -d "${TMPDIR:-/tmp}/unsorry-prove-local-${goal}-${UNSORRY_PROVIDER}.XXXXXX")" \
      || return 1
    rmdir "$prwt" || return 1
  elif [ -e "$prwt" ]; then
    die_config "UNSORRY_LOCAL_WORKTREE '$prwt' already exists"
  else
    mkdir -p "$(dirname "$prwt")" || return 1
  fi

  git worktree add -q --detach "$prwt" HEAD || return 1
  log "local proof worktree: $prwt"
  run_proof "$goal" "$prwt" "$camel" || prc=$?
  rm -f "$prwt/$binding"

  if [ "$prc" -eq 0 ]; then
    prove_target_only_changed "$prwt" "$target" || return 1
    log "local proof verified; no remote operations were performed"
    log "inspect with: git -C '$prwt' diff -- '$target'"
    return 0
  fi
  if [ "$prc" -eq 2 ]; then
    log "$UNSORRY_PROVIDER CLI unavailable; worktree preserved at $prwt"
    return 3
  fi
  log "local proof did not verify; worktree preserved at $prwt"
  return 1
}

# ADR-009 / SPEC-009-A: on prove-budget exhaustion, drive the proof provider to split the
# parent into 2..MAX_DECOMP_SUBS sub-lemmas, requeue each as a fresh open prove
# goal (src = the decomposition record, depth = parent+1), and park the parent
# `blocked`. Soundness is untouched: the parent only ever closes through Gate A
# using the subs; a non-composing split just wastes effort. Returns 0 only if a
# valid decomposition was committed as a PR; 1 (caller falls back to demote) if
# the depth cap is hit, the provider produced nothing usable, the subs do not
# type-check, or any guardrail (≤ cap, strictly-smaller) rejects the split.
decompose_goal() {
  local goal="$1" depth maxdepth prwt branch stmt out i=0 d0 ddur probe_rc
  if decompose_blocked_by_open_prove_pr "$goal"; then
    return 1
  fi
  depth="$(py_helper goal-depth "goals/$goal.aisp")" || return 1
  maxdepth="$(py_helper max-decomp depth)" || return 1
  if [ "$depth" -ge "$maxdepth" ]; then
    log "decompose($goal): at depth $depth (cap $maxdepth) — not decomposing"
    return 1
  fi
  # ADR-009 idempotency: never re-decompose a goal that already has a
  # decomposition. When an unblock re-opens a parent whose sub-lemmas are proved
  # and the recompose (prove) then fails, the fallback must NOT re-decompose \u2014
  # that overwrites the proved sub-lemma goal records back to open (the #364
  # euclid regression). Refuse; the caller demotes/releases instead.
  if py_helper has-decomposition "$goal" decompositions; then
    log "decompose($goal): already has a decomposition \u2014 refusing to re-decompose (ADR-009 idempotency)"
    return 1
  fi
  stmt="$(py_helper lean-stmt "goals/$goal.lean")" || return 1

  branch="$(feature_branch decompose "$goal")" || return 1
  prwt="$UNSORRY_WORKDIR/decompose-${goal}-${AGENT_ID}"
  open_pr_worktree "$prwt" "$branch" || return 1
  if ! ( cd "$prwt" && lake exe cache get ) >/dev/null 2>&1; then
    log "warning: 'lake exe cache get' failed in the decompose worktree for $goal"
  fi

  # Drive the provider to propose sub-lemmas. Each `SUB:` line is a complete Lean
  # theorem signature (no proof). Other lines are ignored. Decomposition only
  # fires after the prove ladder is exhausted, so it runs at the top rung
  # (ADR-015).
  local eff_tok prompt
  eff_tok="$(provider_effort_for_attempt "$UNSORRY_PROVIDER" top "$UNSORRY_EFFORT")"
  prompt="$(cat "$DECOMPOSE_PROMPT_FILE")

PARENT THEOREM (the goal that resisted proof):
$stmt

Output 2 to $(py_helper max-decomp subs) sub-lemma signatures, one per \`SUB:\` line."
  d0="$(date +%s)"
  out="$(call_provider_decompose "$prompt" "$prwt" "$eff_tok" 2>/dev/null)"
  ddur=$(( $(date +%s) - d0 ))

  # Materialise the proposed subs into the PR tree.
  local -a sub_ids=() decomp_args=()
  local subline substmt subid subnorm subsha
  while IFS= read -r subline; do
    case "$subline" in
      SUB:*) ;;
      *) continue ;;
    esac
    substmt="$(printf '%s' "${subline#SUB:}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$substmt" ] || continue
    i=$((i + 1))
    [ "$i" -le "$(py_helper max-decomp subs)" ] || break
    subid="${goal}-s${i}"
    printf 'import Mathlib\n\n%s := by\n  sorry\n' "$substmt" > "$prwt/goals/$subid.lean"
    # Reject a sub whose statement is the parent's (strictly-smaller guard).
    subnorm="$(py_helper lean-stmt "$prwt/goals/$subid.lean" 2>/dev/null)" || { i=$((i - 1)); rm -f "$prwt/goals/$subid.lean"; continue; }
    if [ "$subnorm" = "$stmt" ]; then
      log "decompose($goal): sub $i re-states the parent — dropped"
      i=$((i - 1)); rm -f "$prwt/goals/$subid.lean"; continue
    fi
    py_helper render-goal "$subid" open "decompositions/$goal.$AGENT_ID.aisp" \
      "goals/$subid.lean" "$((depth + 1))" > "$prwt/goals/$subid.aisp"
    # The record references the sub's statement by content address (the
    # statement itself lives only in goals/<sub>.lean — single source of
    # truth; raw statements contain braces the record grammar reserves).
    subsha="$(py_helper lean-sha "$prwt/goals/$subid.lean")" || {
      i=$((i - 1)); rm -f "$prwt/goals/$subid.lean" "$prwt/goals/$subid.aisp"; continue; }
    sub_ids+=("$subid")
    decomp_args+=("$subid" "$subsha")
  done <<< "$out"

  if [ "${#sub_ids[@]}" -lt 2 ]; then
    # ADR-016: an unusable split from a call that died fast is no evidence the
    # goal cannot be decomposed — check the CLI before falling back to demote.
    if [ "$ddur" -lt "$UNSORRY_FASTFAIL" ]; then
      probe_rc=0; cli_health_probe || probe_rc=$?
      if [ "$(classify_call_failure "$ddur" "$UNSORRY_FASTFAIL" "$probe_rc")" = infra ]; then
        log "decompose($goal): $UNSORRY_PROVIDER call died in ${ddur}s and the health probe failed — infrastructure failure (ADR-016)"
        git worktree remove --force "$prwt" >/dev/null 2>&1 || true
        git branch -q -D "$branch" >/dev/null 2>&1 || true
        return 2
      fi
    fi
    log "decompose($goal): $UNSORRY_PROVIDER produced ${#sub_ids[@]} usable sub(s) (need ≥2) — falling back"
    git worktree remove --force "$prwt" >/dev/null 2>&1 || true
    git branch -q -D "$branch" >/dev/null 2>&1 || true
    return 1
  fi

  # decompositions/ may not exist in the tree yet (git tracks no empty dirs;
  # this is the first write on a tree that has never decomposed).
  mkdir -p "$prwt/decompositions"
  py_helper render-decomp "$goal" "$AGENT_ID" "${decomp_args[@]}" \
    > "$prwt/decompositions/$goal.$AGENT_ID.aisp" || return 1
  py_helper rewrite-goal "$prwt/goals/$goal.aisp" blocked || return 1

  # The sub statements must type-check as sorried goals (guardrail: a split that
  # does not even parse is worthless). Build only the goals package.
  if ! ( cd "$prwt" && lake build UnsorryGoals ) >/dev/null 2>&1; then
    log "decompose($goal): sub-lemmas do not type-check — falling back to demote"
    git worktree remove --force "$prwt" >/dev/null 2>&1 || true
    git branch -q -D "$branch" >/dev/null 2>&1 || true
    return 1
  fi

  write_proof_run_record "$prwt" "$goal" decomposed || return 1
  if decompose_blocked_by_open_prove_pr "$goal"; then
    git worktree remove --force "$prwt" >/dev/null 2>&1 || true
    git branch -q -D "$branch" >/dev/null 2>&1 || true
    return 1
  fi
  if submit_pr_tree "$prwt" "$branch" \
      "decompose($goal): ${#sub_ids[@]} sub-lemmas by $AGENT_ID" \
      "Automated decomposition (ADR-009, SPEC-009-A): goal \`$goal\` resisted proof within budget, so it is split into ${#sub_ids[@]} claimable sub-lemmas (depth $((depth + 1))) and parked \`blocked\`. The parent re-opens once its subs are proved and still closes only through Gate A — the dependency edges are advisory, never a trust path." \
      goals decompositions proof-runs; then
    emit_event decomposed "$goal"
    git worktree remove --force "$prwt" >/dev/null 2>&1 || true
    git branch -q -D "$branch" >/dev/null 2>&1 || true
    return 0
  fi
  git worktree remove --force "$prwt" >/dev/null 2>&1 || true
  git branch -q -D "$branch" >/dev/null 2>&1 || true
  return 1
}

# ⊖ on a failed prove attempt, persist a -10 affinity penalty on the goal
# (ADR-010): a small gated PR editing only goals/<goal>.aisp's aff field, so
# the goal is deprioritised and, below τ_v, skipped pending re-decomposition
# (Stage C). Editing a goal .aisp is not a Lean path, so Gate A short-circuits;
# Gate B validates. Best-effort — a failed demote never blocks the cycle.
demote_goal() {
  # demote_goal <goal> [<floor>]. With a <floor> (the ADR-034 recompose case) the
  # -10 is clamped so the goal never drops below it (τ_v), keeping a recoverable
  # parent selectable; without one it is the ordinary -10 leaf demote.
  local goal="$1" floor="${2:-}" prwt branch title note old_aff new_aff
  local -a floorarg=()
  [ -n "$floor" ] && floorarg=("$floor")
  if open_prove_pr_exists "$goal"; then
    check_in_failed_run_only "$goal" \
      "proof attempts for \`$goal\` exhausted their budget, but an open direct proof PR already exists for the same goal"
    log "demote($goal): open prove PR already exists — recorded telemetry only"
    return 0
  fi
  branch="$(feature_branch demote "$goal")" || return 1
  prwt="$UNSORRY_WORKDIR/demote-${goal}-${AGENT_ID}"
  open_pr_worktree "$prwt" "$branch" || return 1
  old_aff="$(py_helper affinity "$prwt/goals/$goal.aisp")" || {
    git worktree remove --force "$prwt" >/dev/null 2>&1 || true
    git branch -q -D "$branch" >/dev/null 2>&1 || true
    return 1
  }
  if [ -n "$floor" ]; then
    title="affinity($goal): failed recompose, demote floored at τ_v by $AGENT_ID"
    note="Automated affinity floor (ADR-010/ADR-034, SPEC-034-A): \`$goal\` is a fully-decomposed parent whose sub-lemmas are all proved, so a failed recompose floors the -10 demote at τ_v ($floor) instead of burying it — it stays selectable (lowest priority) for the unblock→recompose sweep to retry. Advisory queue state only — never trust-bearing."
  else
    title="affinity($goal): -10 after a failed prove attempt by $AGENT_ID"
    note="Automated affinity penalty (ADR-010, SPEC-010-A): goal \`$goal\` resisted proof within budget, so its pattern is demoted by 10. Advisory queue state only — never trust-bearing."
  fi
  if py_helper aff-bump "$prwt/goals/$goal.aisp" "$(py_helper aff-delta fail)" "${floorarg[@]}"; then
    new_aff="$(py_helper affinity "$prwt/goals/$goal.aisp")" || new_aff=""
    if [ -n "$floor" ] && [ "$new_aff" = "$old_aff" ]; then
      title="chore: record failed proof run for $goal by $AGENT_ID"
      note="Automated terminal-run telemetry (ADR-023, SPEC-023-A): \`$goal\` is already at the ADR-034 recompose floor τ_v ($floor), so this failed recompose records proof evidence only and does not open a misleading affinity-demote PR."
    fi
    if write_proof_run_record "$prwt" "$goal" failed; then
      if [ -n "$floor" ] && [ "$new_aff" = "$old_aff" ]; then
        submit_pr_tree "$prwt" "$branch" "$title" "$note" proof-runs || true
      else
        submit_pr_tree "$prwt" "$branch" "$title" "$note" goals proof-runs || true
      fi
    fi
  fi
  git worktree remove --force "$prwt" >/dev/null 2>&1 || true
  git branch -q -D "$branch" >/dev/null 2>&1 || true
}

# Step 10: remove the claim file, commit, push. Re-entrant like claim_goal:
# every retry rebuilds the release commit from scratch on a freshly-fetched,
# hard-reset origin/claims tip, and the final-failure path also hard-resets —
# a cycle never exits leaving unpushed local commits that strand the next run
# (the Phase-0 trial failure mode after "release push rejected").
release_claim() {
  local goal="$1"
  # ADR-068: nothing was claimed in fork mode, so there is nothing to release.
  [ "$FORK_MODE" = 1 ] && return 0
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

test_claim_agent_identity_multi_runner() {
  # Nest under the suite sandbox (auto-removed by the run_self_test EXIT trap) and
  # never `rm -rf` a path ourselves — a bare `mktemp -d` + manual cleanup here was
  # the #3140 agent-lint regression on Linux CI.
  local d live dead
  d="$(mktemp -d "$SESSION_TMP/multirun.XXXXXX")" || return 1
  # free identity -> base id is taken
  AGENT_ID=""; claim_agent_identity "$d" "host-aa11"
  [ "$AGENT_ID" = "host-aa11" ] || { log "  free id not taken: '$AGENT_ID'"; return 1; }
  # a LIVE sibling holding the id -> caller must fork a distinct suffixed id
  sleep 30 & live=$!
  mkdir -p "$d/agent-main-host-bb22.lock"; printf '%s\n' "$live" > "$d/agent-main-host-bb22.lock/pid"
  AGENT_ID=""; claim_agent_identity "$d" "host-bb22"
  kill "$live" 2>/dev/null; wait "$live" 2>/dev/null
  case "$AGENT_ID" in
    host-bb22) log "  live collision was NOT forked"; return 1 ;;
    host-bb22-*) : ;;
    *) log "  forked id malformed: '$AGENT_ID'"; return 1 ;;
  esac
  # a STALE lock (dead owner) -> base id reclaimed
  sleep 30 & dead=$!; kill "$dead" 2>/dev/null; wait "$dead" 2>/dev/null
  mkdir -p "$d/agent-main-host-cc33.lock"; printf '%s\n' "$dead" > "$d/agent-main-host-cc33.lock/pid"
  AGENT_ID=""; claim_agent_identity "$d" "host-cc33"
  [ "$AGENT_ID" = "host-cc33" ] || { log "  stale lock not reclaimed: '$AGENT_ID'"; return 1; }
}

test_fork_goal_lock() {
  # ADR-068 fork-local goal lock. Hermetic: temp dirs + a real backgrounded PID
  # for liveness, no network/lake/claude. Nest under the suite sandbox (the
  # run_self_test EXIT trap removes it) — never rm -rf a path of our own (the
  # #3140 agent-lint regression). FORK_MODE drives the lock on; outside it both
  # helpers are no-ops, so the canonical claims path is untouched.
  local FORK_MODE=1 UNSORRY_GOAL_LOCK_DIR live
  UNSORRY_GOAL_LOCK_DIR="$(mktemp -d "$SESSION_TMP/goallock.XXXXXX")" || return 1

  # The owner is recorded as "<pid> <starttime>" (PID-reuse hardening), so assert
  # on the leading PID field, not the whole token.
  local pidfield
  # free goal -> acquired, owner pid recorded.
  acquire_goal_lock g-free || { log "  free goal was not acquired"; return 1; }
  [ -d "$UNSORRY_GOAL_LOCK_DIR/goal-g-free.lock" ] \
    || { log "  acquire did not create the lock dir"; return 1; }
  pidfield="$(cut -d' ' -f1 "$UNSORRY_GOAL_LOCK_DIR/goal-g-free.lock/pid" 2>/dev/null)"
  [ "$pidfield" = "$$" ] || { log "  lock pid is not ours"; return 1; }
  # re-acquiring our own lock is idempotent (success).
  acquire_goal_lock g-free || { log "  re-acquire of own lock failed"; return 1; }

  # a LIVE sibling holding the goal -> we must skip (rc 1) and not touch the lock.
  # Fixture the token exactly as acquire would (pid + matching start-time).
  sleep 30 & live=$!
  mkdir -p "$UNSORRY_GOAL_LOCK_DIR/goal-g-busy.lock"
  goal_lock_token "$live" > "$UNSORRY_GOAL_LOCK_DIR/goal-g-busy.lock/pid"
  if acquire_goal_lock g-busy; then
    kill "$live" 2>/dev/null; wait "$live" 2>/dev/null
    log "  live-owner collision was NOT skipped"; return 1
  fi
  pidfield="$(cut -d' ' -f1 "$UNSORRY_GOAL_LOCK_DIR/goal-g-busy.lock/pid" 2>/dev/null)"
  [ "$pidfield" = "$live" ] \
    || { kill "$live" 2>/dev/null; wait "$live" 2>/dev/null
         log "  skip clobbered a live sibling's lock"; return 1; }

  # PID-reuse defense: a live PID but a MISMATCHED start-time (the reboot-then-
  # reuse scenario) must read as STALE and be reclaimed, not honoured as live.
  mkdir -p "$UNSORRY_GOAL_LOCK_DIR/goal-g-reused.lock"
  printf '%s 999\n' "$live" > "$UNSORRY_GOAL_LOCK_DIR/goal-g-reused.lock/pid"
  acquire_goal_lock g-reused \
    || { kill "$live" 2>/dev/null; wait "$live" 2>/dev/null
         log "  reused-pid (start-time mismatch) lock not reclaimed"; return 1; }
  pidfield="$(cut -d' ' -f1 "$UNSORRY_GOAL_LOCK_DIR/goal-g-reused.lock/pid" 2>/dev/null)"
  [ "$pidfield" = "$$" ] \
    || { kill "$live" 2>/dev/null; wait "$live" 2>/dev/null
         log "  reused-pid lock not re-owned by us"; return 1; }
  kill "$live" 2>/dev/null; wait "$live" 2>/dev/null

  # a STALE lock (dead owner) -> reclaimed (rc 0, pid becomes ours).
  local dead; sleep 30 & dead=$!; kill "$dead" 2>/dev/null; wait "$dead" 2>/dev/null
  mkdir -p "$UNSORRY_GOAL_LOCK_DIR/goal-g-stale.lock"
  printf '%s\n' "$dead" > "$UNSORRY_GOAL_LOCK_DIR/goal-g-stale.lock/pid"
  acquire_goal_lock g-stale || { log "  stale lock not reclaimed"; return 1; }
  pidfield="$(cut -d' ' -f1 "$UNSORRY_GOAL_LOCK_DIR/goal-g-stale.lock/pid" 2>/dev/null)"
  [ "$pidfield" = "$$" ] || { log "  reclaimed lock pid is not ours"; return 1; }

  # release frees our lock; a sibling's lock is never removed by our release.
  release_goal_lock g-free
  [ ! -e "$UNSORRY_GOAL_LOCK_DIR/goal-g-free.lock" ] \
    || { log "  release did not remove our lock"; return 1; }
  mkdir -p "$UNSORRY_GOAL_LOCK_DIR/goal-g-other.lock"
  printf '%s\n' "999999" > "$UNSORRY_GOAL_LOCK_DIR/goal-g-other.lock/pid"
  release_goal_lock g-other
  [ -e "$UNSORRY_GOAL_LOCK_DIR/goal-g-other.lock" ] \
    || { log "  release removed a lock we do not own"; return 1; }
  # releasing a goal we never locked is a safe no-op (covers the early-return /
  # loop-level belt-and-braces release for a goal whose lock was never taken).
  release_goal_lock g-never || { log "  release of an unheld goal errored"; return 1; }

  # outside fork mode both helpers are inert (canonical claims path untouched).
  local FORK_MODE=0
  acquire_goal_lock g-nofork || { log "  non-fork acquire returned failure"; return 1; }
  [ ! -e "$UNSORRY_GOAL_LOCK_DIR/goal-g-nofork.lock" ] \
    || { log "  non-fork acquire created a lock"; return 1; }
}

test_agent_id_host_matches() {
  # generated shape, prefix == host -> local (0)
  agent_id_host_matches "oma-2-a3f9" "oma-2" || { log "  local id judged foreign"; return 1; }
  agent_id_host_matches "mac-158f" "mac"     || { log "  local id judged foreign (2)"; return 1; }
  # generated shape, prefix != host -> foreign (1): the copied-config case
  if agent_id_host_matches "mac-158f" "oma-2"; then log "  copied id judged local"; return 1; fi
  if agent_id_host_matches "oma-2-a3f9" "mac"; then log "  copied id judged local (2)"; return 1; fi
  # custom-shaped id (suffix not 4 hex) -> intentional, left alone (0)
  agent_id_host_matches "myfleet-prod" "oma-2" || { log "  custom id judged foreign"; return 1; }
  agent_id_host_matches "myfleet" "oma-2"      || { log "  hyphenless id judged foreign"; return 1; }
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

test_solver_resolution() {
  local UNSORRY_SOLVER=perttu SOLVER=""
  resolve_solver || return 1
  [ "$SOLVER" = perttu ] \
    || { log "  solver override was not used"; return 1; }

  UNSORRY_SOLVER=""
  SOLVER=""
  gh() { [ "$1 $2 $3" = "api user --jq" ] && printf 'github-user\n'; }
  resolve_solver || { unset -f gh; return 1; }
  unset -f gh
  [ "$SOLVER" = github-user ] \
    || { log "  authenticated GitHub solver was not resolved"; return 1; }
}

test_solver_credit_decision() {
  local got
  while IFS='|' read -r solver login ack want; do
    [ -z "$want" ] && continue
    got="$(solver_credit_decision "$solver" "$login" "$ack")"
    [ "$got" = "$want" ] \
      || { log "  credit(solver='$solver' login='$login' ack='$ack'): want $want got $got"; return 1; }
  done <<'CASES'
alice|alice||ok
Alice|alice||ok
alice|Alice||ok
bob|alice||block
bob|alice|1|ack
bob|alice|yes|ack
bob|||unknown
CASES
  return 0
}

test_git_identity_resolution() {
  local UNSORRY_SOLVER_NAME="" UNSORRY_SOLVER_EMAIL=""
  local GIT_AUTHOR_NAME="" GIT_AUTHOR_EMAIL=""
  local GIT_COMMITTER_NAME="" GIT_COMMITTER_EMAIL=""

  # Derived from the authenticated account: no-reply email + display name.
  gh() { [ "$1 $2 $3" = "api user --jq" ] && printf 'perttu\t201641\tPerttu Isotalo\n'; }
  resolve_git_identity || { unset -f gh; return 1; }
  unset -f gh
  [ "$GIT_AUTHOR_EMAIL" = "201641+perttu@users.noreply.github.com" ] \
    || { log "  derived no-reply email wrong: '$GIT_AUTHOR_EMAIL'"; return 1; }
  [ "$GIT_AUTHOR_NAME" = "Perttu Isotalo" ] \
    || { log "  derived name wrong: '$GIT_AUTHOR_NAME'"; return 1; }
  [ "$GIT_COMMITTER_EMAIL" = "$GIT_AUTHOR_EMAIL" ] \
    || { log "  committer email not set to match author"; return 1; }
  [ "$GIT_COMMITTER_NAME" = "$GIT_AUTHOR_NAME" ] \
    || { log "  committer name not set to match author"; return 1; }

  # A user with no display name falls back to the login.
  GIT_AUTHOR_NAME=""; GIT_AUTHOR_EMAIL=""
  gh() { [ "$1 $2 $3" = "api user --jq" ] && printf 'octocat\t583231\t\n'; }
  resolve_git_identity || { unset -f gh; return 1; }
  unset -f gh
  [ "$GIT_AUTHOR_NAME" = "octocat" ] \
    || { log "  empty GitHub name did not fall back to login: '$GIT_AUTHOR_NAME'"; return 1; }

  # Explicit overrides win and must not consult gh.
  UNSORRY_SOLVER_NAME="Team Bot"; UNSORRY_SOLVER_EMAIL="bot@example.org"
  GIT_AUTHOR_NAME=""; GIT_AUTHOR_EMAIL=""
  gh() { log "  gh must not be called when both overrides are set"; return 99; }
  resolve_git_identity || { unset -f gh; return 1; }
  unset -f gh
  [ "$GIT_AUTHOR_EMAIL" = "bot@example.org" ] \
    || { log "  explicit email override was not honored: '$GIT_AUTHOR_EMAIL'"; return 1; }
  [ "$GIT_AUTHOR_NAME" = "Team Bot" ] \
    || { log "  explicit name override was not honored: '$GIT_AUTHOR_NAME'"; return 1; }
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

test_require_main_checkout() {
  local tmp rc=0
  tmp="$(mktemp -d "$SESSION_TMP/main-checkout.XXXXXX")" || return 1
  git init -q -b main "$tmp" || return 1
  fixture_git_id "$tmp" || return 1
  git -C "$tmp" commit -q --allow-empty -m seed || return 1
  ( cd "$tmp" && require_main_checkout ) \
    || { log "  main checkout was rejected"; return 1; }
  git -C "$tmp" switch -q -c feature/test || return 1
  ( cd "$tmp" && require_main_checkout ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] \
    || { log "  feature checkout returned $rc, expected config error 2"; return 1; }
}

test_require_main_matches_origin() {
  local tmp rc=0
  tmp="$(mktemp -d "$SESSION_TMP/main-origin.XXXXXX")" || return 1
  git init -q -b main "$tmp" || return 1
  fixture_git_id "$tmp" || return 1
  git -C "$tmp" commit -q --allow-empty -m seed || return 1
  git -C "$tmp" update-ref refs/remotes/origin/main HEAD || return 1
  ( cd "$tmp" && require_main_matches_origin ) \
    || { log "  matching main and origin/main were rejected"; return 1; }
  git -C "$tmp" commit -q --allow-empty -m local-only || return 1
  ( cd "$tmp" && require_main_matches_origin ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] \
    || { log "  local-only main returned $rc, expected config error 2"; return 1; }
}

# ADR-059: the pure fetch-retry backoff — base*2^(attempt-1), capped, and a
# zero base never sleeps (the self-test relies on that to stay fast).
test_fetch_retry_delay() {
  local got
  got="$(fetch_retry_delay 1 2 30)"; [ "$got" = 2 ]  || { log "  attempt1: want 2, got $got"; return 1; }
  got="$(fetch_retry_delay 2 2 30)"; [ "$got" = 4 ]  || { log "  attempt2: want 4, got $got"; return 1; }
  got="$(fetch_retry_delay 3 2 30)"; [ "$got" = 8 ]  || { log "  attempt3: want 8, got $got"; return 1; }
  got="$(fetch_retry_delay 9 2 30)"; [ "$got" = 30 ] || { log "  cap: want 30, got $got"; return 1; }
  got="$(fetch_retry_delay 1 0 30)"; [ "$got" = 0 ]  || { log "  zero-base: want 0, got $got"; return 1; }
  return 0
}

# ADR-059 (#983): git_fetch_retry succeeds against a healthy origin, and after
# exhausting its attempts against a dead remote returns the infra code 3, having
# really looped (attempts-1 inter-attempt retry logs). Hermetic: a bare file://
# origin, no network, zero backoff so it never sleeps.
test_git_fetch_retry() {
  local tmp origin rc=0 err retries=3
  tmp="$(mktemp -d "$SESSION_TMP/fetch-retry.XXXXXX")" || return 1
  origin="$tmp/origin.git"
  git init -q --bare "$origin" || return 1
  git init -q -b main "$tmp/clone" || return 1
  fixture_git_id "$tmp/clone" || return 1
  git -C "$tmp/clone" commit -q --allow-empty -m seed || return 1
  git -C "$tmp/clone" remote add origin "$origin" || return 1
  git -C "$tmp/clone" push -q origin main || return 1
  # Success path: a fetch against the healthy origin returns 0.
  ( cd "$tmp/clone" && UNSORRY_FETCH_BACKOFF=0 git_fetch_retry . -q origin ) \
    || { log "  fetch against a healthy origin failed"; return 1; }
  # Exhaustion path: a non-existent remote returns infra 3 after the retries.
  err="$( ( cd "$tmp/clone" && UNSORRY_FETCH_RETRIES="$retries" UNSORRY_FETCH_BACKOFF=0 \
            git_fetch_retry . -q "$tmp/nonexistent.git" ) 2>&1 )" || rc=$?
  [ "$rc" -eq 3 ] \
    || { log "  exhausted fetch returned $rc, expected infra 3"; return 1; }
  printf '%s\n' "$err" | grep -q "after $retries attempt" \
    || { log "  exhausted fetch did not log the attempt count"; return 1; }
  [ "$(printf '%s\n' "$err" | grep -c "retrying in")" -eq $((retries - 1)) ] \
    || { log "  expected $((retries - 1)) retry logs before exhaustion"; return 1; }
  return 0
}

# #428: the re-exec decision — stale iff the running and on-disk shas differ and
# the current sha is known (a git-hash failure must never trigger a re-exec).
test_harness_is_stale() {
  harness_is_stale abc abc && { log "  identical shas treated as stale"; return 1; }
  harness_is_stale abc unknown && { log "  unknown current sha treated as stale"; return 1; }
  harness_is_stale abc def || { log "  differing shas not detected as stale"; return 1; }
  return 0
}

# ADR-042: relocation is a no-op once already isolated or explicitly opted out —
# in both cases it must return 0 without touching git or exec'ing (the guards
# short-circuit before require_unsorry_origin / fetch).
test_relocate_into_worktree_noop() {
  ( UNSORRY_IN_WT=1 relocate_into_agent_worktree ) \
    || { log "  relocate did not no-op when already inside the worktree"; return 1; }
  ( UNSORRY_IN_WT=0 UNSORRY_NO_ISOLATE=1 relocate_into_agent_worktree ) \
    || { log "  relocate did not no-op when isolation was opted out"; return 1; }
  return 0
}

# ADR-042: require_main_checkout's branch-name gate is bypassed inside an
# isolated worktree (UNSORRY_IN_WT=1), where HEAD is a detached origin/main that
# require_main_matches_origin polices instead.
test_require_main_checkout_isolated() {
  local tmp rc=0
  tmp="$(mktemp -d "$SESSION_TMP/iso-checkout.XXXXXX")" || return 1
  git init -q -b main "$tmp" || return 1
  fixture_git_id "$tmp" || return 1
  git -C "$tmp" commit -q --allow-empty -m seed || return 1
  git -C "$tmp" switch -q -c feature/wip || return 1
  # On a feature branch the strict check still rejects (regression guard)...
  ( cd "$tmp" && require_main_checkout ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] \
    || { log "  non-isolated feature checkout returned $rc, expected 2"; return 1; }
  # ...but inside the worktree the same branch is accepted.
  ( cd "$tmp" && UNSORRY_IN_WT=1 require_main_checkout ) \
    || { log "  isolated worktree checkout was rejected"; return 1; }
}

# ADR-042: ensure_agent_worktree creates a detached origin/main worktree, reuses
# it idempotently, and refuses to adopt a path owned by a foreign clone.
test_ensure_agent_worktree() {
  local tmp wt rc=0
  tmp="$(mktemp -d "$SESSION_TMP/agentwt.XXXXXX")" || return 1
  git init -q -b main "$tmp/repo" || return 1
  fixture_git_id "$tmp/repo" || return 1
  git -C "$tmp/repo" commit -q --allow-empty -m seed || return 1
  git -C "$tmp/repo" update-ref refs/remotes/origin/main HEAD || return 1
  wt="$tmp/agent-wt"   # outside the repo, like the real $UNSORRY_WORKDIR path

  ( cd "$tmp/repo" && ensure_agent_worktree "$wt" ) \
    || { log "  ensure_agent_worktree failed to create the worktree"; return 1; }
  [ -e "$wt" ] || { log "  worktree path was not created"; return 1; }
  [ "$(git -C "$wt" rev-parse HEAD)" = "$(git -C "$tmp/repo" rev-parse origin/main)" ] \
    || { log "  worktree HEAD is not at origin/main"; return 1; }
  git -C "$wt" symbolic-ref -q HEAD >/dev/null 2>&1 \
    && { log "  worktree HEAD is not detached"; return 1; }

  # Idempotent reuse: a second call on the existing worktree succeeds.
  ( cd "$tmp/repo" && ensure_agent_worktree "$wt" ) \
    || { log "  ensure_agent_worktree did not reuse the existing worktree"; return 1; }

  # Ownership guard: a plain directory (not a worktree) outside the repo, like a
  # path owned by another clone, is rejected rather than adopted.
  mkdir -p "$tmp/not-a-wt" || return 1
  ( cd "$tmp/repo" && ensure_agent_worktree "$tmp/not-a-wt" ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] \
    || { log "  adopting a non-worktree path returned $rc, expected config error 2"; return 1; }
}

test_provider_effort_ladder() {
  [ "$(provider_effort_for_attempt codex 1 ladder)" = medium ] || return 1
  [ "$(provider_effort_for_attempt codex 2 ladder)" = high ] || return 1
  [ "$(provider_effort_for_attempt codex 3 ladder)" = xhigh ] || return 1
  [ "$(provider_effort_for_attempt gemini 1 ladder)" = high ] || return 1
  [ "$(provider_effort_for_attempt gemini 2 ladder)" = xhigh ] || return 1
  [ "$(provider_effort_for_attempt gemini 3 ladder)" = max ] || return 1
  [ "$(provider_effort_for_attempt claude 3 ladder)" = max ] || return 1
  [ "$(provider_effort_for_attempt codex 2 low)" = low ] || return 1
}

test_prove_attempt_budget_default() {
  [ "$(prove_attempt_budget_default)" = 3 ] \
    || { log "  prove attempt budget default drifted"; return 1; }
}

test_gemini_prove_mutes_cli_effort() {
  local tmp args
  tmp="$(mktemp -d "$SESSION_TMP/gemini-effort.XXXXXX")" || return 1
  mkdir -p "$tmp/bin" "$tmp/work" || return 1
  args="$tmp/args"
  # The fake gemini script is written verbatim; $@ / $GEMINI_ARGS_OUT must stay
  # literal so they expand when the fake binary runs, not now.
  # shellcheck disable=SC2016
  printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$@" > "$GEMINI_ARGS_OUT"' \
    'exit 0' > "$tmp/bin/gemini" || return 1
  chmod +x "$tmp/bin/gemini" || return 1

  GEMINI_ARGS_OUT="$args" \
    PATH="$tmp/bin:$PATH" \
    UNSORRY_MODEL=gemini-test \
    UNSORRY_WALL=5 \
    call_gemini_prove "prove something" "$tmp/work" high \
    || { log "  fake gemini prove call failed"; return 1; }

  [ -s "$args" ] || { log "  fake gemini did not capture arguments"; return 1; }
  ! grep -qx -- '--effort' "$args" \
    || { log "  gemini prove forwarded unsupported --effort"; return 1; }
  grep -qx -- '--model' "$args" \
    || { log "  gemini prove omitted --model"; return 1; }
  grep -qx -- 'gemini-test' "$args" \
    || { log "  gemini prove omitted configured model"; return 1; }
}

test_gemini_decompose_mutes_cli_effort() {
  local tmp args out
  tmp="$(mktemp -d "$SESSION_TMP/gemini-decompose.XXXXXX")" || return 1
  mkdir -p "$tmp/bin" "$tmp/work" || return 1
  args="$tmp/args"
  # shellcheck disable=SC2016  # fake helper must receive literal "$@" / env vars
  printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$@" > "$GEMINI_ARGS_OUT"' \
    'printf "%s\n" "SUB: theorem sub_one : True" "SUB: theorem sub_two : True"' \
    'exit 0' > "$tmp/bin/gemini" || return 1
  chmod +x "$tmp/bin/gemini" || return 1

  out="$(GEMINI_ARGS_OUT="$args" \
    PATH="$tmp/bin:$PATH" \
    UNSORRY_MODEL=gemini-test \
    UNSORRY_WALL=5 \
    call_gemini_decompose "split something" "$tmp/work" max)" \
    || { log "  fake gemini decompose call failed"; return 1; }

  printf '%s' "$out" | grep -q '^SUB: theorem sub_one : True$' \
    || { log "  gemini decompose did not return provider output"; return 1; }
  ! grep -qx -- '--effort' "$args" \
    || { log "  gemini decompose forwarded unsupported --effort"; return 1; }
  grep -qx -- '--model' "$args" \
    || { log "  gemini decompose omitted --model"; return 1; }
  grep -qx -- 'gemini-test' "$args" \
    || { log "  gemini decompose omitted configured model"; return 1; }
}

test_gemini_health_probe_uses_version() {
  local tmp args
  tmp="$(mktemp -d "$SESSION_TMP/gemini-probe.XXXXXX")" || return 1
  mkdir -p "$tmp/bin" || return 1
  args="$tmp/args"
  # shellcheck disable=SC2016  # fake helper must receive literal "$@" / env vars
  printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$@" > "$GEMINI_ARGS_OUT"' \
    'exit 0' > "$tmp/bin/gemini" || return 1
  chmod +x "$tmp/bin/gemini" || return 1

  GEMINI_ARGS_OUT="$args" \
    PATH="$tmp/bin:$PATH" \
    UNSORRY_PROVIDER=gemini \
    cli_health_probe \
    || { log "  fake gemini health probe failed"; return 1; }

  grep -qx -- '--version' "$args" \
    || { log "  gemini health probe did not use --version"; return 1; }
  ! grep -qx -- '-p' "$args" \
    || { log "  gemini health probe used a model prompt"; return 1; }
  ! grep -qx -- '--model' "$args" \
    || { log "  gemini health probe used a model call"; return 1; }
}

test_prove_target_path_guard() {
  local tmp target="library/Unsorry/Goal.lean"
  tmp="$(mktemp -d "$SESSION_TMP/path-guard.XXXXXX")" || return 1
  git init -q -b main "$tmp" || return 1
  fixture_git_id "$tmp" || return 1
  mkdir -p "$tmp/library/Unsorry" "$tmp/goals" || return 1
  printf 'seed\n' > "$tmp/goals/g.lean"
  git -C "$tmp" add goals/g.lean || return 1
  git -C "$tmp" commit -q -m seed || return 1
  # target-only edit passes.
  printf 'theorem goal : True := by trivial\n' > "$tmp/$target"
  prove_target_only_changed "$tmp" "$target" \
    || { log "  target-only edit was rejected"; return 1; }
  # a root-level stray scratch file is removed and tolerated (e.g. gemini drops
  # a test.lean beside the repo root) — the proof must not be discarded over it.
  printf 'scratch\n' > "$tmp/test.lean"
  prove_target_only_changed "$tmp" "$target" \
    || { log "  root-level stray file was rejected"; return 1; }
  [ -e "$tmp/test.lean" ] && { log "  stray root file was not cleaned up"; return 1; }
  # an untracked file inside a package/spec tree is still a hard violation.
  printf 'forbidden\n' > "$tmp/goals/extra"
  if prove_target_only_changed "$tmp" "$target" >/dev/null 2>&1; then
    log "  untracked file in goals/ was accepted"
    return 1
  fi
  rm -f "$tmp/goals/extra"
  # modifying a tracked file is a hard violation.
  printf 'tampered\n' > "$tmp/goals/g.lean"
  if prove_target_only_changed "$tmp" "$target" >/dev/null 2>&1; then
    log "  tracked-file modification was accepted"
    return 1
  fi
}

test_prove_attempt_log_does_not_trip_guard() {
  # Regression lock for the #292 break: run_proof writes prove-attempt-<n>.log
  # INTO the proof worktree, and the path guard runs over that same worktree.
  # Unless the log is gitignored, the harness's own log trips its own guard and
  # blocks every proof (which is exactly what happened). This reproduces the
  # real interaction — repo .gitignore + a written attempt log — and asserts the
  # guard passes and the log is preserved for inspection.
  local tmp target="library/Unsorry/Goal.lean"
  tmp="$(mktemp -d "$SESSION_TMP/attempt-log-guard.XXXXXX")" || return 1
  git init -q -b main "$tmp" || return 1
  fixture_git_id "$tmp" || return 1
  mkdir -p "$tmp/library/Unsorry" || return 1
  # The repo ships this ignore (see .gitignore); the guard must honour it.
  printf 'prove-attempt-*.log\n' > "$tmp/.gitignore"
  printf 'seed\n' > "$tmp/seed.txt"
  git -C "$tmp" add .gitignore seed.txt || return 1
  git -C "$tmp" commit -q -m seed || return 1
  # The provider wrote only the target; the harness wrote its attempt log.
  printf 'theorem goal : True := by trivial\n' > "$tmp/$target"
  printf 'YOLO mode is enabled.\n[ERROR] Invalid stream\n' > "$tmp/prove-attempt-1.log"
  prove_target_only_changed "$tmp" "$target" \
    || { log "  attempt log tripped the guard (the #292 regression)"; return 1; }
  [ -e "$tmp/prove-attempt-1.log" ] \
    || { log "  attempt log was deleted; it must be preserved for inspection"; return 1; }
}

test_provider_text_module_extraction() {
  local tmp target="library/Unsorry/Goal.lean"
  tmp="$(mktemp -d "$SESSION_TMP/text-extract.XXXXXX")" || return 1
  mkdir -p "$tmp/library/Unsorry" || return 1
  cat > "$tmp/prove-attempt-1.log" <<'EOF' || return 1
The proof module is below.
```lean
import Mathlib

theorem goal : True := by
  trivial
```
EOF

  extract_provider_text_module "$tmp" "$tmp/prove-attempt-1.log" "$target" \
    || { log "  fenced Lean output was not extracted"; return 1; }
  diff -u "$tmp/$target" - <<'EOF' >/dev/null \
    || { log "  extracted Lean module did not match expected content"; return 1; }
import Mathlib

theorem goal : True := by
  trivial
EOF

  rm -f "$tmp/$target"
  printf '%s\n' 'No fenced Lean here.' > "$tmp/prove-attempt-2.log"
  if extract_provider_text_module "$tmp" "$tmp/prove-attempt-2.log" "$target"; then
    log "  non-fenced prose was extracted as a module"
    return 1
  fi
  [ ! -e "$tmp/$target" ] \
    || { log "  target was written for non-fenced prose"; return 1; }
}

test_proof_attempt_cleanup() {
  local tmp target="library/Unsorry/Goal.lean"
  local binding="library/Unsorry/GoalBinding.lean"
  tmp="$(mktemp -d "$SESSION_TMP/attempt-cleanup.XXXXXX")" || return 1
  mkdir -p "$tmp/library/Unsorry" || return 1
  printf 'failed proof\n' > "$tmp/$target"
  printf 'generated binding\n' > "$tmp/$binding"

  prepare_proof_attempt "$tmp" "$target" "$binding" || return 1
  [ ! -e "$tmp/$target" ] \
    || { log "  prior proof target survived attempt cleanup"; return 1; }
  [ ! -e "$tmp/$binding" ] \
    || { log "  prior binding helper survived attempt cleanup"; return 1; }
}

test_run_proof_mock_provider_smoke() {
  # End-to-end smoke of run_proof with a MOCK provider, no Lean toolchain: drives
  # the real orchestration (prompt build, the provider call, the path guard, the
  # statement-binding emit) while stubbing only the two seams that need Lean — the
  # provider itself and the local kernel verify. The mock reproduces the #292
  # shape (target + a stray root file + the harness attempt log) and the smoke
  # must still succeed: target in place, stray cleaned, attempt log ignored.
  local tree camel="GoalSmoke" rc=0
  # Function-local (dynamic scope reaches run_proof) so the subshell holds only
  # the function overrides — no subshell variable-modification noise.
  local UNSORRY_ATTEMPTS=1 UNSORRY_PROVIDER=mock UNSORRY_EFFORT="" \
    UNSORRY_LESSONS=0 UNSORRY_FASTFAIL=1 UNSORRY_WALL=5
  tree="$(mktemp -d "$SESSION_TMP/run-proof-smoke.XXXXXX")" || return 1
  git init -q -b main "$tree" || return 1
  fixture_git_id "$tree" || return 1
  printf 'prove-attempt-*.log\n' > "$tree/.gitignore"
  mkdir -p "$tree/library/Unsorry" || return 1
  make_prove_goal "$tree" goal-smoke "theorem goal_smoke (n : Nat) : n + 0 = n" || return 1
  git -C "$tree" add -A || return 1
  git -C "$tree" commit -q -m seed || return 1
  (
    # Mock provider: write the target proof, plus a stray root file. run_proof's
    # own redirect writes prove-attempt-1.log into the worktree (the #292 shape).
    call_provider_prove() {
      printf 'theorem goal_smoke (n : Nat) : n + 0 = n := rfl\n' \
        > "$2/library/Unsorry/GoalSmoke.lean"
      printf 'scratch\n' > "$2/test.lean"
      return 0
    }
    # Kernel verify needs Lean; stub it green so we exercise orchestration only.
    prove_local_verify() { return 0; }
    run_proof goal-smoke "$tree" "$camel"
  ) || rc=$?
  [ "$rc" -eq 0 ] || { log "  run_proof mock smoke returned $rc"; return 1; }
  [ -f "$tree/library/Unsorry/GoalSmoke.lean" ] \
    || { log "  target module missing after smoke"; return 1; }
  [ -e "$tree/test.lean" ] && { log "  stray root file survived run_proof"; return 1; }
  return 0
}

test_binding_module_suppresses_unused_linter() {
  # Regression for the swarm/Gate-A binding divergence (issue #612): the local
  # self-verify binding must suppress linter.unusedVariables exactly as Gate A's
  # generator does (tools/gate_a/check_statement_binding.py). Without it, a goal
  # hypothesis a correct proof leaves unused trips --wfail here, wrongly failing
  # the self-verify and forcing a needless decomposition.
  local tree camel="UnusedHyp" binding sopt_line thm_line
  tree="$(mktemp -d "$SESSION_TMP/binding-unused.XXXXXX")" || return 1
  mkdir -p "$tree/library/Unsorry" || return 1
  make_prove_goal "$tree" unused-hyp \
    "theorem unused_hyp (a b : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b) : 4 * (a * b) ≤ (a + b) ^ 2" \
    || return 1
  write_binding_module "$tree" unused-hyp "$camel" \
    || { log "  write_binding_module failed"; return 1; }
  binding="$tree/library/Unsorry/${camel}Binding.lean"
  [ -f "$binding" ] || { log "  binding module not written"; return 1; }
  grep -q 'set_option linter.unusedVariables false in' "$binding" \
    || { log "  binding lacks linter.unusedVariables suppression (issue #612)"; return 1; }
  # The suppression must precede the obligation it guards.
  sopt_line="$(grep -n 'set_option linter.unusedVariables false in' "$binding" | head -1 | cut -d: -f1)"
  thm_line="$(grep -n 'unused_hyp_binding_check' "$binding" | head -1 | cut -d: -f1)"
  if ! { [ -n "$sopt_line" ] && [ -n "$thm_line" ] && [ "$sopt_line" -lt "$thm_line" ]; }; then
    log "  suppression does not precede the binding theorem"; return 1
  fi
  return 0
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
  local tmp="$1" ttl="$2" goal="$3" ts="${4:-$T_OLD_TS}"
  git -C "$tmp/seed" fetch -q origin claims || return 1
  git -C "$tmp/seed" reset --hard -q FETCH_HEAD || return 1
  render_claim_record "$goal" agent-other "$ts" "$ttl" \
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

# The #184/#185 claim race, reproduced live 2026-06-12: a rival's LIVE claim
# on the SAME goal lands inside the push round-trip, so the first push is
# rejected and the post-rebase recheck is the only cap-1 enforcement left
# (claim filenames are per-agent — first-push-wins never collides on path).
# Prove mode must withdraw (SPEC-007-A prove step 4: PROVE_CLAIM_CAP, cap 1);
# translate mode must still claim (TRANSLATE_CLAIM_CAP, cap 2).
test_claim_post_success_recheck() {
  # ADR-072: when a rival's per-agent claim is already in our base, our own claim
  # pushes as a CLEAN fast-forward (no rejection) — the on-rejection recheck never
  # runs. The post-SUCCESS recheck must then catch the rival and withdraw, so two
  # agents never both prove one goal.
  local AGENT_ID=agent-self UNSORRY_WORKDIR UNSORRY_TTL CLAIMS_WT PROVE FORK_MODE=0
  local tmp ttl now_ts
  tmp="$(mktemp -d "$SESSION_TMP/postrecheck.XXXXXX")" || return 1
  ttl="$(py_helper ttl)" || return 1
  UNSORRY_WORKDIR="$tmp" UNSORRY_TTL="$ttl" CLAIMS_WT="$tmp/clone"
  make_claims_fixture "$tmp" "$ttl" || { log "  fixture setup failed"; return 1; }
  now_ts="$(py_helper now)" || return 1
  # Live rival claim on origin AND synced into our worktree → our push is a clean
  # fast-forward that succeeds without rejection.
  advance_claims_remote "$tmp" "$ttl" nat-add-comm "$now_ts" \
    || { log "  fixture advance failed"; return 1; }
  git -C "$CLAIMS_WT" fetch -q origin claims || return 1
  git -C "$CLAIMS_WT" reset --hard -q origin/claims || return 1
  PROVE=1
  if claim_goal nat-add-comm; then
    log "  post-success recheck did not withdraw on a live rival (clean-ff race)"
    return 1
  fi
  if git -C "$tmp/origin.git" ls-tree -r --name-only claims \
    | grep -qx "claims/nat-add-comm.agent-self.aisp"; then
    log "  withdrawn claim still on origin/claims after clean-ff race"
    return 1
  fi
  grep -q '"event": "collision", "goal": "nat-add-comm"' "$tmp/metrics.jsonl" \
    || { log "  no collision event on post-success withdrawal"; return 1; }
}

test_claim_recheck_prove_cap() {
  local AGENT_ID=agent-self UNSORRY_WORKDIR UNSORRY_TTL CLAIMS_WT PROVE
  local tmp ttl now_ts
  tmp="$(mktemp -d "$SESSION_TMP/proverecheck.XXXXXX")" || return 1
  ttl="$(py_helper ttl)" || return 1
  UNSORRY_WORKDIR="$tmp" UNSORRY_TTL="$ttl" CLAIMS_WT="$tmp/clone"
  make_claims_fixture "$tmp" "$ttl" || { log "  fixture setup failed"; return 1; }

  now_ts="$(py_helper now)" || return 1
  advance_claims_remote "$tmp" "$ttl" nat-add-comm "$now_ts" \
    || { log "  fixture advance failed"; return 1; }

  PROVE=1
  if claim_goal nat-add-comm; then
    log "  prove-mode recheck re-claimed a goal with a live rival claim"
    return 1
  fi
  if git -C "$tmp/origin.git" ls-tree -r --name-only claims \
    | grep -qx "claims/nat-add-comm.agent-self.aisp"; then
    log "  withdrawn claim still reached origin/claims"
    return 1
  fi
  [ -z "$(git -C "$CLAIMS_WT" status --porcelain)" ] \
    || { log "  withdrawal left the worktree dirty"; return 1; }
  grep -q '"event": "collision", "goal": "nat-add-comm"' "$tmp/metrics.jsonl" \
    || { log "  no collision event emitted"; return 1; }

  # Same live rival, translate mode: cap 2 admits the second claim. Advance
  # the remote again so the push is rejected and the recheck actually runs.
  advance_claims_remote "$tmp" "$ttl" goal-ahead \
    || { log "  second fixture advance failed"; return 1; }
  PROVE=0
  claim_goal nat-add-comm \
    || { log "  translate-mode recheck refused a second claim under cap 2"; return 1; }
  git -C "$tmp/origin.git" ls-tree -r --name-only claims \
    | grep -qx "claims/nat-add-comm.agent-self.aisp" \
    || { log "  translate-mode claim missing from origin/claims"; return 1; }
}

# ── prove-cycle pure-function tests (Phase 1) ───────────────────────────────
# Hermetic: temp prove-goal fixtures, injected clock; no claude/gh/lake/network.

# Write a minimal prove-phase goal (record + .lean) under <tree>/goals.
make_prove_goal() {
  local tree="$1" id="$2" decl="$3"
  mkdir -p "$tree/goals" || return 1
  cat > "$tree/goals/$id.aisp" <<EOF
𝔸5.1.goal.$id@2026-06-10
γ≔unsorry.goal
⟦Ω:Goal⟧{
  id≜$id
  phase≜prove
  status≜open
  difficulty≜1
}
⟦Σ:Source⟧{
  src≜backlog/$id.md
}
⟦Γ:Deps⟧{
  deps≜⟨⟩
}
⟦Λ:Artifact⟧{
  lean≜goals/$id.lean
  sha≜∅
}
⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩
EOF
  printf '%s := by\n  sorry\n' "$decl" > "$tree/goals/$id.lean"
}

test_camel_name() {
  local got
  for pair in \
    "nat-add-comm-thm:NatAddCommThm" \
    "int-neg-neg:IntNegNeg" \
    "a0:A0" \
    "list-reverse-reverse:ListReverseReverse"; do
    got="$(py_helper camel-name "${pair%%:*}")" || return 1
    [ "$got" = "${pair#*:}" ] \
      || { log "  camel-name ${pair%%:*}: expected '${pair#*:}', got '$got'"; return 1; }
  done
}

test_lean_statement_helpers() {
  local tree decl name stmt
  tree="$(mktemp -d "$SESSION_TMP/leanstmt.XXXXXX")" || return 1
  decl="theorem nat_add_comm_thm (a b : Nat) : a + b = b + a"
  make_prove_goal "$tree" nat-add-comm-thm "$decl" || return 1
  name="$(py_helper lean-name "$tree/goals/nat-add-comm-thm.lean")" || return 1
  [ "$name" = "nat_add_comm_thm" ] \
    || { log "  lean-name: expected nat_add_comm_thm, got '$name'"; return 1; }
  # The statement string drops the proof and collapses whitespace.
  stmt="$(py_helper lean-stmt "$tree/goals/nat-add-comm-thm.lean")" || return 1
  [ "$stmt" = "$decl" ] \
    || { log "  lean-stmt: expected '$decl', got '$stmt'"; return 1; }
}

test_lean_sha_determinism() {
  local tree a b spaced
  tree="$(mktemp -d "$SESSION_TMP/leansha.XXXXXX")" || return 1
  make_prove_goal "$tree" g1 "theorem t (n : Nat) : n + 0 = n" || return 1
  a="$(py_helper lean-sha "$tree/goals/g1.lean")" || return 1
  b="$(py_helper lean-sha "$tree/goals/g1.lean")" || return 1
  [ "$a" = "$b" ] || { log "  lean-sha not deterministic ($a vs $b)"; return 1; }
  [ "${#a}" -eq 64 ] || { log "  lean-sha is not a 64-hex digest: '$a'"; return 1; }
  [[ "$a" =~ ^[0-9a-f]{64}$ ]] || { log "  lean-sha not lowercase hex: '$a'"; return 1; }
  # Whitespace and the proof body are normalized out: a re-indented goal with
  # a different proof but the same statement addresses to the same sha.
  printf 'theorem t (n : Nat)  :   n + 0 = n  := by\n  simp\n' \
    > "$tree/goals/g1.lean"
  spaced="$(py_helper lean-sha "$tree/goals/g1.lean")" || return 1
  [ "$spaced" = "$a" ] \
    || { log "  lean-sha changed under whitespace/proof variation ($spaced)"; return 1; }
}

test_prove_candidate_filtering() {
  local tree claims ttl got
  tree="$(mktemp -d "$SESSION_TMP/provecand.XXXXXX")" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" "$tree/library/index" || return 1
  ttl="$(py_helper ttl)" || return 1
  make_prove_goal "$tree" gamma "theorem g (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" alpha "theorem a (n : Nat) : 0 + n = n" || return 1
  # A translate goal is never a prove candidate.
  cp "$T_FIXTURES/valid_tree/goals/nat-add-comm.aisp" "$tree/goals/" || return 1

  # A: two open prove goals, no claims — both candidates, lexicographic order.
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "$(printf 'alpha\ngamma')" ] \
    || { log "  A: expected 'alpha gamma', got '$got'"; return 1; }

  # B: one live claim by another agent on alpha — cap 1 reached, excluded.
  render_claim_record alpha agent-other "$T_LIVE_TS" "$ttl" \
    > "$claims/alpha.agent-other.aisp"
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "gamma" ] \
    || { log "  B: expected 'gamma' (alpha capped), got '$got'"; return 1; }

  # C: that claim expired — alpha is claimable again.
  render_claim_record alpha agent-other "$T_OLD_TS" "$ttl" \
    > "$claims/alpha.agent-other.aisp"
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "$(printf 'alpha\ngamma')" ] \
    || { log "  C: expected 'alpha gamma', got '$got'"; return 1; }

  # D: a live self-claim on alpha excludes it (no double-claim).
  rm -f "$claims"/alpha.*.aisp
  render_claim_record alpha agent-self "$T_LIVE_TS" "$ttl" \
    > "$claims/alpha.agent-self.aisp"
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "gamma" ] \
    || { log "  D: expected 'gamma' (self-claimed alpha), got '$got'"; return 1; }

  # E: a status≜translated/non-open prove goal is excluded.
  rm -f "$claims"/alpha.*.aisp
  py_helper rewrite-goal "$tree/goals/alpha.aisp" blocked || return 1
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "gamma" ] \
    || { log "  E: expected 'gamma' (alpha blocked), got '$got'"; return 1; }
}

test_local_prove_auto_selection() {
  local tree got
  tree="$(mktemp -d "$SESSION_TMP/localpick.XXXXXX")" || return 1
  mkdir -p "$tree/claims" "$tree/library/index" || return 1
  make_prove_goal "$tree" gamma "theorem g (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" alpha "theorem a (n : Nat) : 0 + n = n" || return 1
  got="$(select_local_prove_goal "$tree/goals" "$tree/library" "$tree/claims")"
  [ "$got" = "alpha" ] \
    || { log "  expected automatic local selection 'alpha', got '$got'"; return 1; }
}

test_already_proved_excluded() {
  local tree claims sha got
  tree="$(mktemp -d "$SESSION_TMP/proved.XXXXXX")" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" "$tree/library/index" || return 1
  make_prove_goal "$tree" delta "theorem d (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" gamma "theorem g (n : Nat) : 0 + n = n" || return 1

  # Both open, no index — both candidates.
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "$(printf 'delta\ngamma')" ] \
    || { log "  expected 'delta gamma', got '$got'"; return 1; }

  # An index entry naming delta marks it proved ⇒ no longer a candidate, even
  # though the goal record still reads status≜open (the merge edits both, but
  # the index entry is the authoritative proved marker).
  sha="$(py_helper lean-sha "$tree/goals/delta.lean")" || return 1
  py_helper render-index "$sha" delta d \
    "$(py_helper lean-stmt "$tree/goals/delta.lean")" \
    > "$tree/library/index/$sha.aisp" || return 1
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "gamma" ] \
    || { log "  expected 'gamma' (delta proved), got '$got'"; return 1; }
}

test_goal_proved_rewrite() {
  # The exact prove step-8 machinery on a prove goal: status≜proved + sha.
  local tree sha
  tree="$(mktemp -d "$SESSION_TMP/proverewrite.XXXXXX")" || return 1
  make_prove_goal "$tree" omega "theorem o (n : Nat) : n + 0 = n" || return 1
  sha="$(py_helper lean-sha "$tree/goals/omega.lean")" || return 1
  py_helper rewrite-goal "$tree/goals/omega.aisp" proved "$sha" || return 1
  grep -qxF "  status≜proved" "$tree/goals/omega.aisp" \
    || { log "  status not rewritten to proved"; return 1; }
  grep -qxF "  sha≜$sha" "$tree/goals/omega.aisp" \
    || { log "  sha line not set to the proof's content address"; return 1; }
  # Nothing but status and sha changes (and the lean≜ artifact line survives).
  grep -qxF "  lean≜goals/omega.lean" "$tree/goals/omega.aisp" \
    || { log "  lean artifact line was disturbed"; return 1; }
}

test_render_index_gateb() {
  # A rendered index entry + a proved goal validate under the real Gate B,
  # given the goal's .lean and backlog src exist (as they do in a real PR
  # tree branched from origin/main).
  local tree sha stmt
  tree="$(mktemp -d "$SESSION_TMP/idxgateb.XXXXXX")" || return 1
  mkdir -p "$tree/library/index" "$tree/library/Unsorry" "$tree/backlog" || return 1
  make_prove_goal "$tree" nat-add-zero-thm \
    "theorem nat_add_zero_thm (n : Nat) : n + 0 = n" || return 1
  printf '# nat-add-zero-thm\n\nAdding zero on the right leaves a natural unchanged.\n' \
    > "$tree/backlog/nat-add-zero-thm.md"
  # A library module must exist for the lib to be non-empty (its contents are
  # not parsed by Gate B — soundness is Gate A's job).
  cp "$T_FIXTURES/valid_tree/library/Unsorry/Basic.lean" "$tree/library/Unsorry/" \
    2>/dev/null || printf 'theorem placeholder : True := trivial\n' \
      > "$tree/library/Unsorry/Basic.lean"
  sha="$(py_helper lean-sha "$tree/goals/nat-add-zero-thm.lean")" || return 1
  py_helper render-index "$sha" nat-add-zero-thm nat_add_zero_thm \
    > "$tree/library/index/$sha.aisp" || return 1
  py_helper rewrite-goal "$tree/goals/nat-add-zero-thm.aisp" proved "$sha" || return 1
  python3 -m tools.gate_b validate "$tree" >/dev/null \
    || { log "  rendered index entry + proved goal failed Gate B"; return 1; }
  # The platonic-schlafli-core regression, index-record surface: a proved goal
  # whose statement carries braces must index + validate cleanly (statement by
  # content address, never inline).
  make_prove_goal "$tree" brace-goal \
    "theorem brace_goal (p q : Nat) : (p, q) ∈ ({(3,3),(3,4)} : Finset (Nat × Nat))" || return 1
  printf '# brace-goal\n\nx\n' > "$tree/backlog/brace-goal.md"
  sha="$(py_helper lean-sha "$tree/goals/brace-goal.lean")" || return 1
  py_helper render-index "$sha" brace-goal brace_goal \
    > "$tree/library/index/$sha.aisp" || return 1
  py_helper rewrite-goal "$tree/goals/brace-goal.aisp" proved "$sha" || return 1
  python3 -m tools.gate_b validate "$tree" >/dev/null \
    || { log "  brace-statement index entry failed Gate B"; return 1; }
}

test_index_provenance_render() {
  local sha got legacy
  sha="$(printf 'a%.0s' {1..64})"
  got="$(py_helper render-index "$sha" proof-goal proof_goal \
    --solver perttu --agent oma-2-c50d --provider codex \
    --model gpt-5.1-codex --effort xhigh --attempts 2 --solve-s 842)"
  grep -qF '⟦Π:Provenance⟧{solver≜perttu; agent≜oma-2-c50d; provider≜codex; model≜gpt-5.1-codex; effort≜xhigh; attempts≜2; solve_s≜842}' \
    <<<"$got" || { log "  rendered index provenance is missing or malformed"; return 1; }

  legacy="$(py_helper render-index "$sha" proof-goal proof_goal)"
  if grep -qF '⟦Π:Provenance⟧' <<<"$legacy"; then
    log "  legacy index render unexpectedly gained provenance"
    return 1
  fi
}

test_proof_run_render() {
  local got run_id sha
  run_id="20260613t120000000000z-1234abcd"
  sha="$(printf 'a%.0s' {1..64})"
  got="$(py_helper render-run "$run_id" proof-goal oma-2-c50d proved \
    perttu codex 2 842 "$sha" --model gpt-5.1-codex --effort xhigh)"
  grep -qF "⟦Ω:Run⟧{id≜$run_id; goal≜proof-goal; agent≜oma-2-c50d; outcome≜proved}" \
    <<<"$got" || { log "  rendered proof-run identity is missing"; return 1; }
  grep -qF '⟦Λ:Metrics⟧{attempts≜2; solve_s≜842; ended≜' \
    <<<"$got" || { log "  rendered proof-run metrics are missing"; return 1; }
  grep -qF "⟦Σ:Artifact⟧{sha≜$sha}" \
    <<<"$got" || { log "  rendered proof-run artifact is missing"; return 1; }
  # The canonical ⟦Γ⟧ block keeps the record valid under the upstream AISP
  # validator (goals/decompositions carry it; proof-runs must too).
  grep -qF '⟦Γ:Goal⟧{goal≜proof-goal}' \
    <<<"$got" || { log "  rendered proof-run is missing the ⟦Γ⟧ goal-link block"; return 1; }
  # ADR-024: a proved run never carries a lesson sig, even if one is passed.
  grep -qF '⟦Δ:Lesson⟧' <<<"$got" \
    && { log "  proved run leaked a lesson block"; return 1; }
  grep -qF 'lessons≜' <<<"$got" \
    && { log "  proved run emitted a lessons count it was not given"; return 1; }
  # ADR-024: a failed run carries the injected-lesson count and a bounded sig.
  got="$(py_helper render-run "$run_id" proof-goal oma-2-c50d failed \
    perttu codex 3 900 "" --lessons-used 2 --lesson 'unsolved goals ⊢ n + 0 = n')"
  grep -qF '; lessons≜2}' <<<"$got" \
    || { log "  failed-run lessons count missing from metrics"; return 1; }
  grep -qF '⟦Δ:Lesson⟧{sig≜unsolved goals ⊢ n + 0 = n}' <<<"$got" \
    || { log "  failed-run lesson signature block missing"; return 1; }
  # A delimiter-laden raw error is sanitised to a clean single-line sig.
  got="$(py_helper render-run "$run_id" proof-goal oma-2-c50d failed \
    perttu codex 1 5 "" --lesson "$(printf 'type mismatch\n{a};b≜c "q"')")"
  grep -qF '⟦Δ:Lesson⟧{sig≜type mismatch abc q}' <<<"$got" \
    || { log "  lesson sig was not sanitised: $got"; return 1; }
}

test_lesson_signature() {
  # ADR-024: raw verifier output collapses to one bounded AISP-legal line;
  # delimiters are stripped while Lean error content is preserved.
  local got long
  got="$(py_helper lesson-sig "$(printf 'error: unsolved goals\n⊢ n * 0 = 0\n{x};y≜z "q"')")"
  case "$got" in
    *'{'*|*'}'*|*';'*|*'"'*|*'≜'*|*'⟦'*|*'⟧'*)
      log "  delimiter leaked into signature: '$got'"; return 1 ;;
  esac
  [ "$(printf '%s' "$got" | wc -l | tr -d ' ')" = 0 ] \
    || { log "  signature is multi-line: '$got'"; return 1; }
  printf '%s' "$got" | grep -q '⊢ n \* 0 = 0' \
    || { log "  Lean error content lost: '$got'"; return 1; }
  # Bounded length (config.LESSON_SIG_MAX = 280).
  long="$(py_helper lesson-sig "$(printf 'x%.0s' {1..600})")"
  [ "${#long}" -le 280 ] || { log "  signature not truncated: ${#long}"; return 1; }
}

_emit_run_record() {
  # <dir> <goal> <agent> <run> <outcome> <ended> <sig> — write a minimal proof-run
  # record with a controlled ended timestamp (render-run stamps now(), so the
  # reader's recency ordering needs hand-authored timestamps to be testable).
  local dir="$1" goal="$2" agent="$3" run="$4" outcome="$5" ended="$6" sig="$7"
  {
    printf '𝔸5.1.run.%s.%s.%s@2026-06-13\n' "$goal" "$agent" "$run"
    printf 'γ≔unsorry.proof.run\n'
    printf '⟦Ω:Run⟧{id≜%s; goal≜%s; agent≜%s; outcome≜%s}\n' "$run" "$goal" "$agent" "$outcome"
    printf '⟦Λ:Metrics⟧{attempts≜3; solve_s≜100; ended≜%s}\n' "$ended"
    printf '⟦Δ:Lesson⟧{sig≜%s}\n' "$sig"
    printf '⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n'
  } > "$dir/$goal.$agent.$run.aisp"
}

test_prove_lessons_surfacing() {
  # ADR-024: prior failed/decomposed lessons for a goal surface most-recent
  # first, de-duplicated and capped; proved runs never contribute.
  local tree got dir
  tree="$(mktemp -d "$SESSION_TMP/lessons.XXXXXX")" || return 1
  dir="$tree/proof-runs"
  mkdir -p "$dir" || return 1
  _emit_run_record "$dir" g ag1 run-a failed     2026-06-13T12:00:00Z 'OLD unsolved goals A'
  _emit_run_record "$dir" g ag2 run-b failed     2026-06-13T13:00:00Z 'NEW type mismatch B'
  # Same sig as ag2 but more recent and decomposed — proves dedup + recency.
  _emit_run_record "$dir" g ag3 run-c decomposed 2026-06-13T14:00:00Z 'NEW type mismatch B'
  # A proved run must not contribute even when it carries a lesson block.
  _emit_run_record "$dir" g ag4 run-d proved     2026-06-13T15:00:00Z 'should not appear'
  # A different goal must not bleed in.
  _emit_run_record "$dir" other ag5 run-e failed 2026-06-13T16:00:00Z 'OTHER goal sig'
  got="$(py_helper prove-lessons g "$dir")"
  [ "$got" = "$(printf 'NEW type mismatch B\nOLD unsolved goals A')" ] \
    || { log "  prove-lessons wrong order/dedup: '$got'"; return 1; }
  printf '%s' "$got" | grep -q 'should not appear' \
    && { log "  proved-run lesson leaked"; return 1; }
  printf '%s' "$got" | grep -q 'OTHER goal sig' \
    && { log "  other goal's lesson leaked"; return 1; }
  # Cap is honoured.
  got="$(py_helper prove-lessons g "$dir" 1)"
  [ "$got" = "NEW type mismatch B" ] || { log "  cap not honoured: '$got'"; return 1; }
  # Missing dir is silent, not an error.
  got="$(py_helper prove-lessons g "$tree/absent")" || { log "  missing dir errored"; return 1; }
  [ -z "$got" ] || { log "  missing dir produced output: '$got'"; return 1; }
}

# Set a prove goal's deps≜⟨⟩ to ⟨<csv>⟩ (test helper for gap ranking).
set_goal_deps() {
  local file="$1" csv="$2"
  # ${csv} braced: bash 5.3 under UTF-8 locales pulls the ⟩ glyph into the
  # identifier (csv⟩: unbound variable). Write+mv instead of sed -i: BSD sed
  # (macOS) requires a backup-suffix argument, GNU sed does not.
  sed "s/  deps≜⟨⟩/  deps≜⟨${csv}⟩/" "$file" > "$file.sedtmp" && mv "$file.sedtmp" "$file"
}

test_affinity_ranking() {
  # ADR-010: order by (affinity desc, gap asc, id asc). Pure queue logic.
  local tree claims got
  tree="$(mktemp -d "$SESSION_TMP/affrank.XXXXXX")" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" "$tree/library/index" || return 1
  make_prove_goal "$tree" lo "theorem lo (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" hi "theorem hi (n : Nat) : 0 + n = n" || return 1
  make_prove_goal "$tree" mid "theorem mid (n : Nat) : n * 1 = n" || return 1
  py_helper aff-bump "$tree/goals/hi.aisp" 5 || return 1
  py_helper aff-bump "$tree/goals/mid.aisp" 2 || return 1
  # lo stays at affinity 0 (no aff field at all — degrades to 0).
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "$(printf 'hi\nmid\nlo')" ] \
    || { log "  affinity order: expected 'hi mid lo', got '$got'"; return 1; }

  # Tie on affinity ⇒ lexicographic id. Give zzz and aaa equal affinity 5.
  make_prove_goal "$tree" zzz "theorem zzz (n : Nat) : n * 0 = 0" || return 1
  make_prove_goal "$tree" aaa "theorem aaa (n : Nat) : 0 ≤ n" || return 1
  py_helper aff-bump "$tree/goals/zzz.aisp" 5 || return 1
  py_helper aff-bump "$tree/goals/aaa.aisp" 5 || return 1
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  # aff5: aaa, hi, zzz (lexicographic); then mid(2), then lo(0).
  [ "$got" = "$(printf 'aaa\nhi\nzzz\nmid\nlo')" ] \
    || { log "  tie-break: expected 'aaa hi zzz mid lo', got '$got'"; return 1; }
}

test_gap_ranking() {
  # gap ≜ |deps ∖ proved|; smaller gap preferred even against lexicographic.
  local tree claims got
  tree="$(mktemp -d "$SESSION_TMP/gaprank.XXXXXX")" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" "$tree/library/index" || return 1
  make_prove_goal "$tree" aaa "theorem aaa (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" bbb "theorem bbb (n : Nat) : 0 + n = n" || return 1
  set_goal_deps "$tree/goals/aaa.aisp" bbb   # aaa depends on bbb (gap 1)
  # bbb has gap 0; both affinity 0. By (0, gap, id): bbb(gap0) before aaa(gap1)
  # despite aaa < bbb lexicographically.
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "$(printf 'bbb\naaa')" ] \
    || { log "  gap order: expected 'bbb aaa', got '$got'"; return 1; }

  # Once bbb is proved (index entry), aaa's gap drops to 0 — and bbb leaves the
  # pool — so aaa is the sole candidate.
  local sha
  sha="$(py_helper lean-sha "$tree/goals/bbb.lean")" || return 1
  py_helper render-index "$sha" bbb bbb \
    > "$tree/library/index/$sha.aisp" || return 1
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "aaa" ] \
    || { log "  post-proof gap: expected 'aaa', got '$got'"; return 1; }
}

test_viability_skip() {
  # A goal below τ_v (−5) is skipped — non-viable, awaiting re-decomposition.
  local tree claims got tau
  tree="$(mktemp -d "$SESSION_TMP/viability.XXXXXX")" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" "$tree/library/index" || return 1
  tau="$(python3 -c 'import tools.gate_b.config as c; print(c.TAU_V)')" || return 1
  [ "$tau" = "-5" ] || { log "  τ_v drifted from -5 (got $tau)"; return 1; }
  make_prove_goal "$tree" ok "theorem ok (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" bad "theorem bad (n : Nat) : 0 + n = n" || return 1
  py_helper aff-bump "$tree/goals/bad.aisp" -6 || return 1   # below τ_v
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "ok" ] \
    || { log "  viability: expected only 'ok' (bad below τ_v), got '$got'"; return 1; }
  # Exactly at τ_v is still viable (the cut is strictly below) — but ranks
  # below ok, since -5 < 0 affinity.
  py_helper aff-bump "$tree/goals/bad.aisp" 1 || return 1    # -6 → -5
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "$(printf 'ok\nbad')" ] \
    || { log "  at τ_v should be viable but rank below ok; expected 'ok bad', got '$got'"; return 1; }
}

test_recovery_candidates() {
  # ADR-044: recovery-candidates is the exact inverse of prove-candidates —
  # it surfaces ONLY goals parked below τ_v, ordered least-buried first, with
  # the same claimability filter.
  local tree claims got ttl
  tree="$(mktemp -d "$SESSION_TMP/recovery.XXXXXX")" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" "$tree/library/index" || return 1
  ttl="$(py_helper ttl)" || return 1
  make_prove_goal "$tree" viable "theorem v (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" buried "theorem b (n : Nat) : 0 + n = n" || return 1
  make_prove_goal "$tree" deeper "theorem d (a b : Nat) : a + b = b + a" || return 1
  py_helper aff-bump "$tree/goals/buried.aisp" -10 || return 1   # parked
  py_helper aff-bump "$tree/goals/deeper.aisp" -20 || return 1   # more buried

  # A: only the parked goals, least-buried first; the viable goal is excluded
  # (it is the normal prove queue's job).
  got="$(py_helper recovery-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "$(printf 'buried\ndeeper')" ] \
    || { log "  A: expected 'buried deeper' (viable excluded, least-buried first), got '$got'"; return 1; }

  # B: exactly at τ_v is viable, not recoverable — the cut is strictly below.
  py_helper aff-bump "$tree/goals/buried.aisp" 5 || return 1     # -10 → -5
  got="$(py_helper recovery-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "deeper" ] \
    || { log "  B: -5 is viable; expected only 'deeper', got '$got'"; return 1; }

  # C: a live claim by another agent on a parked goal excludes it (cap 1) — the
  # recovery pool respects the same claimability filter as prove-candidates.
  render_claim_record deeper agent-other "$T_LIVE_TS" "$ttl" \
    > "$claims/deeper.agent-other.aisp"
  got="$(py_helper recovery-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ -z "$got" ] \
    || { log "  C: deeper claimed by another agent should be excluded, got '$got'"; return 1; }
}

test_goal_override_bypasses_viability() {
  # An explicit --goal (passed as --force) surfaces a goal ranked below τ_v —
  # the operator overrides the "awaiting re-decomposition" default — but never
  # one a HARD guard excluded (proved/claimed/capped/blocked/non-prove).
  local tree claims got sha
  tree="$(mktemp -d "$SESSION_TMP/forceviab.XXXXXX")" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" "$tree/library/index" || return 1
  make_prove_goal "$tree" ok "theorem ok (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" bad "theorem bad (n : Nat) : 0 + n = n" || return 1
  py_helper aff-bump "$tree/goals/bad.aisp" -10 || return 1   # below τ_v = -5
  # ('solved', not 'done' — 'done' is a bash reserved word, trips SC1010.)
  make_prove_goal "$tree" solved "theorem d (n : Nat) : n = n" || return 1

  # Baseline (no --force): the sub-viable 'bad' is dropped; 'ok'/'solved' remain.
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")"
  [ "$got" = "$(printf 'ok\nsolved')" ] \
    || { log "  baseline: expected 'ok solved' (bad below τ_v), got '$got'"; return 1; }

  # --force surfaces the sub-viable goal without dropping the normal candidates.
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT" --force bad)"
  printf '%s\n' "$got" | grep -qx bad \
    || { log "  force: --force did not surface sub-viable 'bad', got '$got'"; return 1; }
  printf '%s\n' "$got" | grep -qx ok \
    || { log "  force: --force dropped normal candidate 'ok', got '$got'"; return 1; }

  # Hard guard holds: a proved goal is never forced back into candidacy.
  sha="dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
  py_helper render-index "$sha" solved solved_thm > "$tree/library/index/$sha.aisp" || return 1
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT" --force solved)"
  printf '%s\n' "$got" | grep -qx solved \
    && { log "  guard: --force resurrected the proved goal 'solved'"; return 1; }
  return 0
}

test_affinity_bump_math() {
  # aff-bump inserts when absent, accumulates when present, and reflects the
  # configured +1 / −10 deltas.
  local tree merge fail got
  tree="$(mktemp -d "$SESSION_TMP/affbump.XXXXXX")" || return 1
  make_prove_goal "$tree" g "theorem g (n : Nat) : n + 0 = n" || return 1
  grep -q 'aff≜' "$tree/goals/g.aisp" \
    && { log "  fresh goal should carry no aff field"; return 1; }
  got="$(py_helper affinity "$tree/goals/g.aisp")" || return 1
  [ "$got" = "0" ] || { log "  absent affinity should read as 0, got $got"; return 1; }
  merge="$(py_helper aff-delta merge)" || return 1
  fail="$(py_helper aff-delta fail)" || return 1
  if [ "$merge" != "1" ] || [ "$fail" != "-10" ]; then
    log "  deltas drifted: merge=$merge fail=$fail"
    return 1
  fi
  py_helper aff-bump "$tree/goals/g.aisp" "$merge" || return 1   # absent → 1
  grep -qxF "  aff≜1" "$tree/goals/g.aisp" \
    || { log "  aff not inserted as 1"; return 1; }
  py_helper aff-bump "$tree/goals/g.aisp" "$fail" || return 1    # 1 → -9
  grep -qxF "  aff≜-9" "$tree/goals/g.aisp" \
    || { log "  aff not accumulated to -9"; return 1; }
  got="$(py_helper affinity "$tree/goals/g.aisp")" || return 1
  [ "$got" = "-9" ] || { log "  affinity readback should be -9, got $got"; return 1; }
  # The inserted aff line sits inside the artifact block; the tree still
  # validates under Gate B (aff is an ignored advisory field).
  mkdir -p "$tree/backlog" || return 1
  printf '# g\n\nx\n' > "$tree/backlog/g.md"
  python3 -m tools.gate_b validate "$tree" >/dev/null \
    || { log "  goal with aff field failed Gate B"; return 1; }
}

test_affinity_degrades_on_garbage() {
  # A garbled aff value must not crash selection — it degrades to 0 (advisory).
  local tree claims got
  tree="$(mktemp -d "$SESSION_TMP/affgarbage.XXXXXX")" || return 1
  claims="$tree/claims"
  mkdir -p "$claims" "$tree/library/index" || return 1
  make_prove_goal "$tree" g "theorem g (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" h "theorem h (n : Nat) : 0 + n = n" || return 1
  py_helper aff-bump "$tree/goals/h.aisp" 3 || return 1
  # Corrupt g's aff to a non-integer; it must be read as 0, not error out.
  sed -i 's/  sha≜∅/  sha≜∅\n  aff≜oops/' "$tree/goals/g.aisp"
  got="$(py_helper prove-candidates "$tree/goals" "$claims" "$tree/library" agent-self "$T_AT")" \
    || { log "  selection crashed on a garbled aff"; return 1; }
  [ "$got" = "$(printf 'h\ng')" ] \
    || { log "  garbled aff should rank as 0; expected 'h g', got '$got'"; return 1; }
}

test_demote_open_prove_records_telemetry_only() {
  # If a direct proof PR is already open, a stale/concurrent failed attempt must
  # not race the goal record with an affinity PR. Keep the failed-run evidence.
  local captured_goal="" captured_reason="" opened=0
  open_prove_pr_exists() { [ "$1" = "parent" ]; }
  check_in_failed_run_only() { captured_goal="$1"; captured_reason="$2"; return 0; }
  open_pr_worktree() { opened=1; return 0; }

  demote_goal parent || {
    unset -f open_prove_pr_exists check_in_failed_run_only open_pr_worktree
    log "  demote with open prove PR failed"
    return 1
  }
  unset -f open_prove_pr_exists check_in_failed_run_only open_pr_worktree
  [ "$captured_goal" = "parent" ] \
    || { log "  telemetry helper not called for parent"; return 1; }
  case "$captured_reason" in
    *"open direct proof PR"*) ;;
    *) log "  telemetry reason did not mention open proof PR: $captured_reason"; return 1 ;;
  esac
  [ "$opened" -eq 0 ] || { log "  demote worktree opened despite open proof PR"; return 1; }
}

test_floored_recompose_noop_records_telemetry_only() {
  # A recompose parent already sitting at τ_v should not open another
  # misleading affinity(<goal>) PR. It records proof-run telemetry only.
  local src captured_title="" captured_paths="" tau
  src="$(mktemp -d "$SESSION_TMP/floornoop.XXXXXX")" || return 1
  make_prove_goal "$src" parent "theorem p (n : Nat) : n = n" || return 1
  tau="$(py_helper tau-v)" || return 1
  py_helper aff-bump "$src/goals/parent.aisp" "$tau" || return 1
  UNSORRY_WORKDIR="$SESSION_TMP"
  AGENT_ID="agent-test"

  open_prove_pr_exists() { return 1; }
  feature_branch() { printf 'test-branch\n'; }
  open_pr_worktree() {
    mkdir -p "$1" || return 1
    cp -R "$src/." "$1/"
  }
  write_proof_run_record() {
    mkdir -p "$1/proof-runs" || return 1
    printf 'run\n' > "$1/proof-runs/parent.agent.run.aisp"
  }
  submit_pr_tree() {
    captured_title="$3"
    shift 4
    captured_paths="$*"
    return 0
  }
  git() {
    case "$1 $2" in
      "worktree remove"|"branch -q") return 0 ;;
      *) command git "$@" ;;
    esac
  }

  demote_goal parent "$tau" || {
    unset -f open_prove_pr_exists feature_branch open_pr_worktree write_proof_run_record submit_pr_tree git
    log "  floored no-op demote failed"
    return 1
  }
  unset -f open_prove_pr_exists feature_branch open_pr_worktree write_proof_run_record submit_pr_tree git
  case "$captured_title" in
    "chore: record failed proof run for parent by "*) ;;
    *) log "  expected telemetry title, got '$captured_title'"; return 1 ;;
  esac
  [ "$captured_paths" = "proof-runs" ] \
    || { log "  expected proof-runs-only submit, got '$captured_paths'"; return 1; }
}

test_decomp_caps_and_depth() {
  # max-decomp exposes the config caps; render-goal carries a depth field that
  # goal-depth reads; an absent depth is 0 (ADR-009).
  local tree
  tree="$(mktemp -d "$SESSION_TMP/decdepth.XXXXXX")" || return 1
  mkdir -p "$tree/goals" || return 1
  [ "$(py_helper max-decomp subs)" = "8" ] \
    || { log "  max-decomp subs drifted from 8"; return 1; }
  [ "$(py_helper max-decomp depth)" = "3" ] \
    || { log "  max-decomp depth drifted from 3"; return 1; }
  make_prove_goal "$tree" base "theorem b (n : Nat) : n + 0 = n" || return 1
  [ "$(py_helper goal-depth "$tree/goals/base.aisp")" = "0" ] \
    || { log "  seeded goal should be depth 0"; return 1; }
  py_helper render-goal kid open decompositions/base.agent-x.aisp goals/kid.lean 2 \
    > "$tree/goals/kid.aisp" || return 1
  [ "$(py_helper goal-depth "$tree/goals/kid.aisp")" = "2" ] \
    || { log "  render-goal depth not read back as 2"; return 1; }
}

test_has_decomposition() {
  # ADR-009 idempotency: a goal with an existing decomposition record must be
  # detected, so decompose_goal refuses to re-decompose it (the #364 regression).
  local tree
  tree="$(mktemp -d "$SESSION_TMP/hasdecomp.XXXXXX")" || return 1
  mkdir -p "$tree/goals" "$tree/decompositions" || return 1
  make_prove_goal "$tree" parent "theorem p (a b : Nat) : a + b = b + a" || return 1
  make_prove_goal "$tree" parent-s1 "theorem s1 (n : Nat) : n + 0 = n" || return 1
  if py_helper has-decomposition parent "$tree/decompositions"; then
    log "  no decomposition record yet, but helper reported one"; return 1
  fi
  py_helper render-decomp parent agent-x \
    parent-s1 "$(py_helper lean-stmt "$tree/goals/parent-s1.lean")" \
    > "$tree/decompositions/parent.agent-x.aisp" || return 1
  py_helper has-decomposition parent "$tree/decompositions" \
    || { log "  parent IS decomposed, but helper reported none"; return 1; }
  if py_helper has-decomposition other "$tree/decompositions"; then
    log "  'other' has no decomposition, but helper reported one"; return 1
  fi
}

test_unblockable_detection() {
  # A blocked parent whose decomposition subs are all proved is unblockable;
  # if any sub is unproved, it is not (ADR-009).
  local tree got sha1 sha2
  tree="$(mktemp -d "$SESSION_TMP/unblock.XXXXXX")" || return 1
  mkdir -p "$tree/goals" "$tree/decompositions" "$tree/library/index" "$tree/backlog" || return 1
  make_prove_goal "$tree" parent "theorem p (a b : Nat) : a + b = b + a" || return 1
  py_helper rewrite-goal "$tree/goals/parent.aisp" blocked || return 1
  make_prove_goal "$tree" parent-s1 "theorem s1 (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" parent-s2 "theorem s2 (a b : Nat) : a + (b + 1) = (a + b) + 1" || return 1
  py_helper render-decomp parent agent-x \
    parent-s1 "$(py_helper lean-stmt "$tree/goals/parent-s1.lean")" \
    parent-s2 "$(py_helper lean-stmt "$tree/goals/parent-s2.lean")" \
    > "$tree/decompositions/parent.agent-x.aisp" || return 1

  # No subs proved yet ⇒ parent not unblockable.
  got="$(py_helper unblockable "$tree/goals" "$tree/decompositions" "$tree/library")"
  [ -z "$got" ] || { log "  parent should not be unblockable yet, got '$got'"; return 1; }

  # Prove only s1 ⇒ still not unblockable.
  sha1="$(py_helper lean-sha "$tree/goals/parent-s1.lean")" || return 1
  py_helper render-index "$sha1" parent-s1 s1 "$(py_helper lean-stmt "$tree/goals/parent-s1.lean")" \
    > "$tree/library/index/$sha1.aisp" || return 1
  got="$(py_helper unblockable "$tree/goals" "$tree/decompositions" "$tree/library")"
  [ -z "$got" ] || { log "  one sub proved is not enough, got '$got'"; return 1; }

  # Prove s2 too ⇒ now unblockable.
  sha2="$(py_helper lean-sha "$tree/goals/parent-s2.lean")" || return 1
  py_helper render-index "$sha2" parent-s2 s2 "$(py_helper lean-stmt "$tree/goals/parent-s2.lean")" \
    > "$tree/library/index/$sha2.aisp" || return 1
  got="$(py_helper unblockable "$tree/goals" "$tree/decompositions" "$tree/library")"
  [ "$got" = "parent" ] || { log "  all subs proved ⇒ unblockable; got '$got'"; return 1; }
}

test_recompose_fail_floors_at_viability() {
  # ADR-034 / #388: a failed recompose of a parent whose subs are all proved
  # floors the demote at τ_v (parent stays selectable); an ordinary leaf fail is
  # still the full -10. `recompose-candidate` ignores status (parent is `open`).
  local tree tau sha1 sha2 paff laff
  tree="$(mktemp -d "$SESSION_TMP/recompose-floor.XXXXXX")" || return 1
  mkdir -p "$tree/goals" "$tree/decompositions" "$tree/library/index" "$tree/backlog" || return 1
  tau="$(py_helper tau-v)" || return 1
  [ "$tau" = "-5" ] || { log "  τ_v drifted from -5 (got $tau)"; return 1; }

  make_prove_goal "$tree" parent "theorem p (a b : Nat) : a + b = b + a" || return 1
  make_prove_goal "$tree" parent-s1 "theorem s1 (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" parent-s2 "theorem s2 (n : Nat) : 0 + n = n" || return 1
  make_prove_goal "$tree" leaf "theorem l (n : Nat) : n = n" || return 1
  py_helper render-decomp parent agent-x \
    parent-s1 "$(py_helper lean-sha "$tree/goals/parent-s1.lean")" \
    parent-s2 "$(py_helper lean-sha "$tree/goals/parent-s2.lean")" \
    > "$tree/decompositions/parent.agent-x.aisp" || return 1

  # Not a recompose candidate until ALL subs are proved.
  py_helper recompose-candidate parent "$tree/decompositions" "$tree/library" \
    && { log "  parent is not a recompose candidate with 0 subs proved"; return 1; }
  sha1="$(py_helper lean-sha "$tree/goals/parent-s1.lean")" || return 1
  py_helper render-index "$sha1" parent-s1 s1 > "$tree/library/index/$sha1.aisp" || return 1
  py_helper recompose-candidate parent "$tree/decompositions" "$tree/library" \
    && { log "  one sub proved is not enough for a recompose candidate"; return 1; }
  sha2="$(py_helper lean-sha "$tree/goals/parent-s2.lean")" || return 1
  py_helper render-index "$sha2" parent-s2 s2 > "$tree/library/index/$sha2.aisp" || return 1

  # All subs proved ⇒ parent is a recompose candidate; a leaf (no decomp) is not.
  py_helper recompose-candidate parent "$tree/decompositions" "$tree/library" \
    || { log "  all subs proved ⇒ parent should be a recompose candidate"; return 1; }
  py_helper recompose-candidate leaf "$tree/decompositions" "$tree/library" \
    && { log "  a goal with no decomposition is not a recompose candidate"; return 1; }

  # Criterion 1: floored demote keeps the parent at τ_v (not below). aff 0 → max(-10, -5) = -5.
  py_helper aff-bump "$tree/goals/parent.aisp" "$(py_helper aff-delta fail)" "$tau" || return 1
  paff="$(grep -oE 'aff≜-?[0-9]+' "$tree/goals/parent.aisp" | grep -oE -- '-?[0-9]+')"
  [ "$paff" = "$tau" ] || { log "  recompose demote should floor at τ_v ($tau), got $paff"; return 1; }
  # Criterion 2: an ordinary leaf demote is unchanged (-10, below τ_v).
  py_helper aff-bump "$tree/goals/leaf.aisp" "$(py_helper aff-delta fail)" || return 1
  laff="$(grep -oE 'aff≜-?[0-9]+' "$tree/goals/leaf.aisp" | grep -oE -- '-?[0-9]+')"
  [ "$laff" = "-10" ] || { log "  ordinary leaf demote should be -10, got $laff"; return 1; }
}

test_proved_deps_surfacing() {
  # ADR-014: a goal's proved deps (declared + own-decomposition subs) surface
  # as importable modules; unproved deps stay silent (gap routing owns those).
  local tree got sha
  tree="$(mktemp -d "$SESSION_TMP/depsurf.XXXXXX")" || return 1
  mkdir -p "$tree/library/index" "$tree/library/Unsorry" "$tree/decompositions" || return 1
  make_prove_goal "$tree" target-goal "theorem target_goal (n : Nat) : n = n" || return 1
  make_prove_goal "$tree" dep-proved "theorem dep_proved (n : Nat) : n + 0 = n" || return 1
  make_prove_goal "$tree" dep-open "theorem dep_open (n : Nat) : 0 + n = n" || return 1
  set_goal_deps "$tree/goals/target-goal.aisp" dep-proved dep-open
  # dep-proved is proved: index entry + a library module declaring it.
  sha="$(py_helper lean-sha "$tree/goals/dep-proved.lean")" || return 1
  py_helper render-index "$sha" dep-proved dep_proved \
    > "$tree/library/index/$sha.aisp" || return 1
  printf 'theorem dep_proved (n : Nat) : n + 0 = n := rfl\n' \
    > "$tree/library/Unsorry/DepProved.lean"
  got="$(py_helper proved-deps "$tree/goals/target-goal.aisp" "$tree/goals" \
    "$tree/library" "$tree/decompositions")" || return 1
  [ "$got" = "$(printf 'Unsorry.DepProved\tdep_proved\ttheorem dep_proved (n : Nat) : n + 0 = n')" ] \
    || { log "  declared-dep surfacing wrong: '$got'"; return 1; }
  # A decomposition naming target-goal as parent adds its proved subs too.
  local s2sha
  make_prove_goal "$tree" target-goal-s1 "theorem tg_s1 (n : Nat) : n * 1 = n" || return 1
  s2sha="$(py_helper lean-sha "$tree/goals/target-goal-s1.lean")" || return 1
  py_helper render-index "$s2sha" target-goal-s1 tg_s1 \
    > "$tree/library/index/$s2sha.aisp" || return 1
  printf 'theorem tg_s1 (n : Nat) : n * 1 = n := Nat.mul_one n\n' \
    > "$tree/library/Unsorry/TgS1.lean"
  py_helper render-decomp target-goal agent-x target-goal-s1 "$s2sha" \
    > "$tree/decompositions/target-goal.agent-x.aisp" || return 1
  got="$(py_helper proved-deps "$tree/goals/target-goal.aisp" "$tree/goals" \
    "$tree/library" "$tree/decompositions")" || return 1
  printf '%s' "$got" | grep -q 'Unsorry.TgS1	tg_s1' \
    || { log "  decomposition-sub surfacing missing: '$got'"; return 1; }
  printf '%s' "$got" | grep -q 'dep-open' \
    && { log "  unproved dep was surfaced"; return 1; }
  return 0
}

test_model_effort_policy() {
  local help_with='Options:
  --model <model>                       Model for the current session
  --effort <level>                      Effort level (low, medium, high, xhigh, max)'
  local help_without='Options:
  --model <model>                       Model for the current session'
  local got
  # ADR-013/ADR-015: prove mode defaults to the most capable model on the
  # progressive effort ladder.
  got="$(resolve_model_effort prove "" "" "$help_with")"
  [ "$got" = "fable ladder" ] || { log "  prove defaults: want 'fable ladder', got '$got'"; return 1; }
  # Translation is not a proof run: sonnet, no effort flag.
  got="$(resolve_model_effort translate "" "" "$help_with")"
  [ "$got" = "sonnet -" ] || { log "  translate defaults: want 'sonnet -', got '$got'"; return 1; }
  # Env overrides win over both defaults.
  got="$(resolve_model_effort prove sonnet high "$help_with")"
  [ "$got" = "sonnet high" ] || { log "  env override: want 'sonnet high', got '$got'"; return 1; }
  # Fail-soft: a CLI that does not advertise --effort drops the flag.
  got="$(resolve_model_effort prove "" "" "$help_without")"
  [ "$got" = "fable -" ] || { log "  fail-soft: want 'fable -', got '$got'"; return 1; }
  # Explicit effort on translate is honoured when the CLI supports it.
  got="$(resolve_model_effort translate "" xhigh "$help_with")"
  [ "$got" = "sonnet xhigh" ] || { log "  explicit translate effort: want 'sonnet xhigh', got '$got'"; return 1; }
  # Explicit effort is also dropped fail-soft on an old CLI.
  got="$(resolve_model_effort translate "" xhigh "$help_without")"
  [ "$got" = "sonnet -" ] || { log "  fail-soft explicit: want 'sonnet -', got '$got'"; return 1; }
}

test_effort_ladder() {
  local got
  # ADR-015: on the ladder, attempts climb high → xhigh → max.
  got="$(effort_for_attempt 1 ladder)"
  [ "$got" = high ] || { log "  rung 1: want 'high', got '$got'"; return 1; }
  got="$(effort_for_attempt 2 ladder)"
  [ "$got" = xhigh ] || { log "  rung 2: want 'xhigh', got '$got'"; return 1; }
  got="$(effort_for_attempt 3 ladder)"
  [ "$got" = max ] || { log "  rung 3: want 'max', got '$got'"; return 1; }
  # Attempts past the last rung stay at the top, as does the explicit word
  # "top" (the decomposition call).
  got="$(effort_for_attempt 7 ladder)"
  [ "$got" = max ] || { log "  rung 7: want 'max', got '$got'"; return 1; }
  got="$(effort_for_attempt top ladder)"
  [ "$got" = max ] || { log "  top rung: want 'max', got '$got'"; return 1; }
  # A pinned UNSORRY_EFFORT short-circuits the ladder at every attempt.
  got="$(effort_for_attempt 1 xhigh)"
  [ "$got" = xhigh ] || { log "  pinned attempt 1: want 'xhigh', got '$got'"; return 1; }
  got="$(effort_for_attempt 3 xhigh)"
  [ "$got" = xhigh ] || { log "  pinned attempt 3: want 'xhigh', got '$got'"; return 1; }
  # The fail-soft empty value pins to "no flag" on every attempt.
  got="$(effort_for_attempt 2 "")"
  [ -z "$got" ] || { log "  fail-soft attempt: want '', got '$got'"; return 1; }
}

test_infra_failure_classifier() {
  local got
  # ADR-016: fast death + failed probe = infrastructure, never goal evidence.
  got="$(classify_call_failure 45 240 1)"
  [ "$got" = infra ] || { log "  fast+probe-fail: want 'infra', got '$got'"; return 1; }
  # A fast failure with a healthy CLI is a real (if odd) attempt.
  got="$(classify_call_failure 45 240 0)"
  [ "$got" = real ] || { log "  fast+probe-ok: want 'real', got '$got'"; return 1; }
  # A slow failure is a real attempt even if the probe later fails — the model
  # had its chance (e.g. wall timeout, then quota died afterwards).
  got="$(classify_call_failure 1800 240 1)"
  [ "$got" = real ] || { log "  slow+probe-fail: want 'real', got '$got'"; return 1; }
  # Boundary: exactly the threshold is not "under" it.
  got="$(classify_call_failure 240 240 1)"
  [ "$got" = real ] || { log "  boundary: want 'real', got '$got'"; return 1; }
}

test_seed_library_cache() {
  local warm prwt rc
  warm="$(mktemp -d)"; prwt="$(mktemp -d)"
  mkdir -p "$warm/.lake/build/lib/lean/Unsorry" "$warm/.lake/build/bin"
  : > "$warm/.lake/build/lib/lean/Unsorry/Foo.olean"
  : > "$warm/.lake/build/bin/axiom_audit"
  # Warm root set → the prove worktree is seeded with the oleans and the exe.
  WARM_LIBRARY_ROOT="$warm"
  seed_library_cache "$prwt"
  rc=0
  [ -f "$prwt/.lake/build/lib/lean/Unsorry/Foo.olean" ] || { log "  olean not seeded"; rc=1; }
  [ -f "$prwt/.lake/build/bin/axiom_audit" ] || { log "  audit exe not seeded"; rc=1; }
  # An existing build dir is never clobbered (a started build owns it).
  local prwt2; prwt2="$(mktemp -d)"; mkdir -p "$prwt2/.lake/build"; : > "$prwt2/.lake/build/SENTINEL"
  seed_library_cache "$prwt2"
  [ -f "$prwt2/.lake/build/SENTINEL" ] || { log "  clobbered an existing build dir"; rc=1; }
  [ -e "$prwt2/.lake/build/lib" ] && { log "  seeded over an existing build dir"; rc=1; }
  # No warm root (build failed or UNSORRY_SEED_LIBRARY=0) → no-op, no crash.
  local prwt3; prwt3="$(mktemp -d)"
  WARM_LIBRARY_ROOT=""
  seed_library_cache "$prwt3"
  [ -e "$prwt3/.lake" ] && { log "  seeded with no warm root"; rc=1; }
  rm -rf "$warm" "$prwt" "$prwt2" "$prwt3"
  return "$rc"
}

# ADR-099 / SPEC-099-A §3: a benchmark goal resolves to its suite's verifier context
# (toolchain/mathlib/_verify/target); an organic goal resolves to empty so the prove
# path keeps the repo pin. Exercises the run_proof / check_in_proof routing seam.
test_suite_context_for_goal() {
  local root rc=0 out
  root="$(mktemp -d)"
  mkdir -p "$root/targets/minif2f-v1"
  {
    printf '𝔸5.1.skeleton.minif2f-v1@2026-06-25\n'
    printf 'γ≔unsorry.skeleton\n'
    printf '⟦Μ:Manifest⟧{top≜minif2f-v1-suite;supplier≜acme;domain≜math;toolchain≜leanprover/lean4:v4.24.0;mathlib≜rev24}\n'
    printf '⟦Σ:Subs⟧{sub₁≜⟨id≜minif2f-a,sha≜%s⟩}\n' "$(printf 'a%.0s' $(seq 64))"
    printf '⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n'
  } > "$root/targets/minif2f-v1/skeleton.aisp"
  # a registered obligation → resolves to the suite verifier context
  out="$(suite_context_for_goal "minif2f-a" "$root")"
  case "$out" in
    "leanprover/lean4:v4.24.0"$'\t'"rev24"$'\t'"targets/minif2f-v1/_verify"$'\t'"Minif2fV1") ;;
    *) log "  benchmark goal context wrong: [$out]"; rc=1 ;;
  esac
  # an organic goal → empty (keeps the repo pin path)
  [ -z "$(suite_context_for_goal "some-organic-goal" "$root")" ] || { log "  organic goal not empty"; rc=1; }
  rm -rf "$root"
  return "$rc"
}

test_open_pr_claim_guard() {
  local rc
  # ADR-017: an open prove PR for exactly this goal → skip it (rc 0). gh is
  # stubbed — the suite stays hermetic.
  gh() { printf 'prove(some-goal): thm_name by agent-x\n'; }
  if ! open_prove_pr_exists some-goal; then
    unset -f gh; log "  open PR not detected"; return 1
  fi
  # A SIBLING goal's PR shares the name's search tokens but must not match
  # (the #198 regression: an open PR for <goal>-s2-s2 blocked the parent).
  gh() { printf 'prove(some-goal-s2-s2): other_thm by agent-x\n'; }
  rc=0; open_prove_pr_exists some-goal || rc=$?
  [ "$rc" -eq 1 ] || { unset -f gh; log "  sibling PR matched the parent goal"; return 1; }
  # ...and the parent's PR must not match a sub-goal either.
  gh() { printf 'prove(some-goal): thm_name by agent-x\n'; }
  rc=0; open_prove_pr_exists some-goal-s1 || rc=$?
  [ "$rc" -eq 1 ] || { unset -f gh; log "  parent PR matched a sub-goal"; return 1; }
  # No open PR → proceed (rc 1).
  gh() { :; }
  rc=0; open_prove_pr_exists some-goal || rc=$?
  [ "$rc" -eq 1 ] || { unset -f gh; log "  empty list treated as an open PR"; return 1; }
  # A gh failure means "unknown" and must fail open (rc 1) — selection never
  # depends on API health.
  gh() { return 9; }
  rc=0; open_prove_pr_exists some-goal || rc=$?
  [ "$rc" -eq 1 ] || { unset -f gh; log "  gh failure did not fail open"; return 1; }
  unset -f gh
  return 0
}

# ADR-068 fork-native contribution mode (SPEC-068-A) -------------------------

test_parse_github_nwo() {
  local got
  got="$(parse_github_nwo https://github.com/alice/unsorry.git)"
  [ "$got" = alice/unsorry ] || { log "  https .git: '$got'"; return 1; }
  got="$(parse_github_nwo https://github.com/agenticsnz/unsorry)"
  [ "$got" = agenticsnz/unsorry ] || { log "  https no-suffix: '$got'"; return 1; }
  got="$(parse_github_nwo git@github.com:bob/unsorry.git)"
  [ "$got" = bob/unsorry ] || { log "  ssh: '$got'"; return 1; }
  got="$(parse_github_nwo https://github.com/alice/unsorry/)"
  [ "$got" = alice/unsorry ] || { log "  trailing slash: '$got'"; return 1; }
  got="$(parse_github_nwo https://example.com/x/y.git)"
  [ -z "$got" ] || { log "  non-github should be empty: '$got'"; return 1; }
  return 0
}

test_fork_pr_head_ref() {
  local got FORK_MODE=0 FORK_OWNER=""
  got="$(fork_pr_head_ref prove/g/agent-x)"
  [ "$got" = prove/g/agent-x ] || { log "  canonical head: '$got'"; return 1; }
  FORK_MODE=1 FORK_OWNER=alice
  got="$(fork_pr_head_ref prove/g/agent-x)"
  [ "$got" = "alice:prove/g/agent-x" ] || { log "  fork head: '$got'"; return 1; }
  return 0
}

test_fork_shard() {
  # ADR-076: deterministic, in range, default-on bad K.
  local a b
  a="$(fork_shard hello 8)"; b="$(fork_shard hello 8)"
  [ "$a" = "$b" ] || { log "  fork_shard not deterministic ($a/$b)"; return 1; }
  if [ "$a" -lt 0 ] || [ "$a" -ge 8 ]; then log "  fork_shard out of range: $a"; return 1; fi
  ( UNSORRY_FORK_SHARDS=garbage; [ "$(fork_shard_count)" = 8 ] ) \
    || { log "  bad K did not default to 8"; return 1; }
  ( UNSORRY_FORK_SHARDS=0; [ "$(fork_shard_count)" = 8 ] ) \
    || { log "  K=0 did not default to 8"; return 1; }
  ( UNSORRY_FORK_SHARDS=4; [ "$(fork_shard_count)" = 4 ] ) \
    || { log "  valid K not honoured"; return 1; }
  return 0
}

test_shard_reorder() {
  # In-shard goals come first (rank order preserved within each group), the rest
  # after; with K=1 every goal is in-shard so order is unchanged; empty is safe.
  local agent=agent-x k=8 mine out
  mine="$(fork_shard "$agent" "$k")"
  # Build a list with a known in-shard and out-of-shard goal so we can assert the
  # partition without hardcoding cksum values.
  local g list="" in_goal="" out_goal=""
  for g in g1 g2 g3 g4 g5 g6 g7 g8 g9 g10; do
    if [ "$(fork_shard "$g" "$k")" = "$mine" ]; then [ -z "$in_goal" ] && in_goal="$g"; \
    else [ -z "$out_goal" ] && out_goal="$g"; fi
    list="$list$g"$'\n'
  done
  if [ -z "$in_goal" ] || [ -z "$out_goal" ]; then
    log "  fixture lacked both in- and out-of-shard goals"; return 1
  fi
  out="$(printf '%s' "$list" | shard_reorder "$agent" "$k")"
  # Every in-shard goal must appear before every out-of-shard goal.
  local in_pos out_pos
  in_pos="$(printf '%s\n' "$out" | grep -nxF "$in_goal" | cut -d: -f1)"
  out_pos="$(printf '%s\n' "$out" | grep -nxF "$out_goal" | cut -d: -f1)"
  [ "$in_pos" -lt "$out_pos" ] || { log "  in-shard $in_goal ($in_pos) not before out $out_goal ($out_pos)"; return 1; }
  # K=1 ⇒ no reorder (every goal in-shard, rank order intact).
  out="$(printf 'a\nb\nc\n' | shard_reorder agent-x 1)"
  [ "$out" = "$(printf 'a\nb\nc')" ] || { log "  K=1 changed order: '$out'"; return 1; }
  # Empty input is safe.
  out="$(printf '' | shard_reorder agent-x 8)"
  [ -z "$out" ] || { log "  empty input produced output: '$out'"; return 1; }
  return 0
}

test_detect_fork_mode() {
  # --fork override enters fork mode, derives the owner, and forces PR submit mode.
  local FORK_MODE=0 FORK_REQUEST=1 FORK_OWNER="" UNSORRY_FORK="" \
        UNSORRY_UPSTREAM=agenticsnz/unsorry UPSTREAM_REMOTE=upstream UNSORRY_SUBMIT_MODE=""
  git() { case "$* " in "remote get-url origin "*) echo https://github.com/alice/unsorry.git ;; *) return 0 ;; esac; }
  gh() { return 0; }
  detect_fork_mode
  [ "$FORK_MODE" = 1 ] || { unset -f git gh; log "  --fork did not enter fork mode"; return 1; }
  [ "$FORK_OWNER" = alice ] || { unset -f git gh; log "  fork owner '$FORK_OWNER'"; return 1; }
  [ "$UNSORRY_SUBMIT_MODE" = pr ] || { unset -f git gh; log "  submit mode not forced to pr"; return 1; }
  unset -f git gh
  # Auto-detect: origin differs from upstream and GitHub reports it is a fork.
  local FORK_MODE=0 FORK_REQUEST=0 FORK_OWNER="" UNSORRY_FORK="" UNSORRY_SUBMIT_MODE=""
  git() { case "$* " in "remote get-url origin "*) echo https://github.com/bob/unsorry ;; *) return 0 ;; esac; }
  gh() { case "$1 $2" in "api repos/bob/unsorry") echo true ;; *) return 0 ;; esac; }
  detect_fork_mode
  [ "$FORK_MODE" = 1 ] || { unset -f git gh; log "  fork not auto-detected"; return 1; }
  unset -f git gh
  # Canonical origin is never fork mode.
  local FORK_MODE=0 FORK_REQUEST=0 FORK_OWNER="" UNSORRY_FORK="" UNSORRY_SUBMIT_MODE=""
  git() { case "$* " in "remote get-url origin "*) echo https://github.com/agenticsnz/unsorry.git ;; *) return 0 ;; esac; }
  gh() { return 0; }
  detect_fork_mode
  [ "$FORK_MODE" = 0 ] || { unset -f git gh; log "  canonical origin entered fork mode"; return 1; }
  unset -f git gh
  return 0
}

test_fork_claimless() {
  # ADR-068: claim/release are no-ops in fork mode and must touch no git/claims.
  local FORK_MODE=1 rc=0
  git() { echo "  unexpected git call in fork claimless path: $*" >&2; return 99; }
  claim_goal some-goal || rc=$?
  [ "$rc" -eq 0 ] || { unset -f git; log "  claim_goal not a no-op in fork mode (rc=$rc)"; return 1; }
  rc=0; release_claim some-goal || rc=$?
  [ "$rc" -eq 0 ] || { unset -f git; log "  release_claim not a no-op in fork mode (rc=$rc)"; return 1; }
  unset -f git
  return 0
}

test_fork_open_pr_dedup_targets_upstream() {
  # In fork mode the open-PR dedup must query the UPSTREAM repo; the stub only
  # answers when it sees --repo <upstream>, so rc 0 proves the arg was passed.
  local FORK_MODE=1 UNSORRY_UPSTREAM=agenticsnz/unsorry rc=0
  gh() { case "$*" in *"--repo agenticsnz/unsorry"*) printf 'prove(g): t by a\n' ;; esac; }
  open_prove_pr_exists g || rc=$?
  [ "$rc" -eq 0 ] || { unset -f gh; log "  fork dedup did not target the upstream repo"; return 1; }
  # Canonical mode lets gh infer origin (no --repo) and still detects the PR.
  local FORK_MODE=0
  gh() { printf 'prove(g): t by a\n'; }
  rc=0; open_prove_pr_exists g || rc=$?
  [ "$rc" -eq 0 ] || { unset -f gh; log "  canonical dedup broke"; return 1; }
  unset -f gh
  return 0
}

test_decompose_open_prove_guard() {
  local rc
  gh() { printf 'prove(parent-goal): theorem_name by agent-a\n'; }
  if ! decompose_blocked_by_open_prove_pr parent-goal; then
    unset -f gh; log "  decompose did not detect open direct proof PR"; return 1
  fi

  gh() { printf 'prove(parent-goal-s1): theorem_name by agent-a\n'; }
  rc=0; decompose_blocked_by_open_prove_pr parent-goal || rc=$?
  [ "$rc" -eq 1 ] || { unset -f gh; log "  decompose was blocked by sibling proof PR"; return 1; }

  gh() { return 9; }
  rc=0; decompose_blocked_by_open_prove_pr parent-goal || rc=$?
  [ "$rc" -eq 1 ] || { unset -f gh; log "  gh failure blocked decomposition"; return 1; }
  unset -f gh
  return 0
}

test_submission_governor_reason() {
  local got
  got="$(submission_governor_reason 1 0 0 40 20)"
  [ "$got" = "submission freeze is active" ] \
    || { log "  freeze reason mismatch: '$got'"; return 1; }
  got="$(submission_governor_reason 0 40 0 40 20)"
  [ "$got" = "open prove PRs 40 >= limit 40" ] \
    || { log "  open PR threshold mismatch: '$got'"; return 1; }
  got="$(submission_governor_reason 0 10 20 40 20)"
  [ "$got" = "Gate A queued+in-progress runs 20 >= limit 20" ] \
    || { log "  Gate A threshold mismatch: '$got'"; return 1; }
  if submission_governor_reason 0 100 100 -1 -1 >/dev/null; then
    log "  disabled thresholds still paused"
    return 1
  fi
  # per-contributor in-flight cap (args 6,7)
  got="$(submission_governor_reason 0 0 0 40 20 25 25)"
  [ "$got" = "this agent holds 25 goals in flight >= cap 25" ] \
    || { log "  in-flight cap mismatch: '$got'"; return 1; }
  if submission_governor_reason 0 0 0 40 20 10 25 >/dev/null; then
    log "  under in-flight cap still paused"; return 1
  fi
  # cap omitted (5-arg form) or unreadable count must not pause
  if submission_governor_reason 0 0 0 40 20 >/dev/null; then
    log "  omitted in-flight args paused"; return 1
  fi
  if submission_governor_reason 0 0 0 40 20 "" 25 >/dev/null; then
    log "  unreadable in-flight count paused"; return 1
  fi
}

test_submission_governor_allows_with_stubbed_gh() {
  local calls=0
  local PROVE=1
  local UNSORRY_SUBMISSION_GOVERNOR=1
  local UNSORRY_SUBMISSION_FREEZE=0
  local UNSORRY_MAX_OPEN_PROVE_PRS=40
  local UNSORRY_MAX_GATE_A_IN_FLIGHT=20
  local UNSORRY_GOVERNOR_SCAN_LIMIT=200
  # keep this test focused on the open-PR / Gate A thresholds: stub the
  # per-contributor in-flight count to a benign value (its own logic is covered
  # by test_submission_governor_reason).
  count_agent_inflight() { echo 0; }

  gh() {
    case "$1 $2 $3" in
      "pr list --state") echo 12 ;;
      "run list --workflow")
        calls=$((calls + 1))
        if [ "$calls" -eq 1 ]; then echo 3; else echo 4; fi
        ;;
      *) return 1 ;;
    esac
  }
  submission_governor_allows \
    || { unset -f gh; log "  below threshold was paused"; return 1; }
  unset -f gh

  gh() {
    case "$1 $2 $3" in
      "pr list --state") echo 41 ;;
      "run list --workflow") echo 0 ;;
      *) return 1 ;;
    esac
  }
  if submission_governor_allows; then
    unset -f gh
    log "  above open-PR threshold was allowed"
    return 1
  fi
  unset -f gh

  UNSORRY_SUBMISSION_GOVERNOR=0
  submission_governor_allows \
    || { unset -f count_agent_inflight; log "  disabled governor did not allow"; return 1; }
  unset -f count_agent_inflight
}

test_queued_branch_claim_guard() {
  local PROVE=1 CLAIMED_GOAL="" claimed=""
  open_prove_pr_exists() { return 1; }
  queued_prove_branch_exists() { [ "$1" = queued-goal ]; }
  claim_goal() { claimed="$1"; return 0; }
  claim_from_pool "$(printf 'queued-goal\nfree-goal\n')" || {
    unset -f open_prove_pr_exists queued_prove_branch_exists claim_goal
    log "  claim_from_pool failed"
    return 1
  }
  unset -f open_prove_pr_exists queued_prove_branch_exists claim_goal
  [ "$CLAIMED_GOAL" = free-goal ] \
    || { log "  expected free-goal after queued skip, got '$CLAIMED_GOAL'"; return 1; }
  [ "$claimed" = free-goal ] \
    || { log "  expected claim of free-goal, got '$claimed'"; return 1; }
}

test_render_decomp_gateb() {
  # A rendered decomposition record + its sub goal records validate under the
  # real Gate B (acyclic, subs are known goals, none re-emits the parent).
  local tree
  tree="$(mktemp -d "$SESSION_TMP/decgateb.XXXXXX")" || return 1
  mkdir -p "$tree/goals" "$tree/decompositions" "$tree/backlog" || return 1
  make_prove_goal "$tree" parent "theorem p (a b : Nat) : a + b = b + a" || return 1
  py_helper rewrite-goal "$tree/goals/parent.aisp" blocked || return 1
  py_helper render-goal parent-s1 open decompositions/parent.agent-x.aisp \
    goals/parent-s1.lean 1 > "$tree/goals/parent-s1.aisp" || return 1
  printf 'theorem s1 (n : Nat) : n + 0 = n := by sorry\n' > "$tree/goals/parent-s1.lean"
  py_helper render-goal parent-s2 open decompositions/parent.agent-x.aisp \
    goals/parent-s2.lean 1 > "$tree/goals/parent-s2.aisp" || return 1
  # s2 carries braces in its statement — the platonic-schlafli-core regression:
  # the record must reference it by sha, never embed it (grammar reserves {}).
  printf 'theorem s2 (p q : Nat) : (p, q) ∈ ({(3,3),(3,4)} : Finset (Nat × Nat)) := by sorry\n' > "$tree/goals/parent-s2.lean"
  local s1sha s2sha
  s1sha="$(py_helper lean-sha "$tree/goals/parent-s1.lean")" || return 1
  s2sha="$(py_helper lean-sha "$tree/goals/parent-s2.lean")" || return 1
  py_helper render-decomp parent agent-x \
    parent-s1 "$s1sha" parent-s2 "$s2sha" \
    > "$tree/decompositions/parent.agent-x.aisp" || return 1
  printf '# parent\n\nx\n' > "$tree/backlog/parent.md"
  python3 -m tools.gate_b validate "$tree" >/dev/null \
    || { log "  rendered decomposition + subs failed Gate B"; return 1; }
}

test_dispatch_goal_dedup() {
  # ADR-064: the dispatcher opens at most one prove PR per goal, resolving open-PR
  # membership from the upfront dispatch_open_pr_goals set (one list call) rather
  # than a per-branch search (the search API is 30/min). Given two queued branches
  # for g1, one for an already-proved goal g2, and one for g3 that already has an
  # open prove PR, exactly one branch (a g1) is dispatched — g2 skipped as proved,
  # g3 skipped via the open-PR set, the g1 duplicate skipped as handled-this-pass.
  # NB: accumulator must not be named `dispatched` — dispatch_queue uses that as
  # its internal integer counter and dynamic scoping would let the stub clobber it.
  local ONCE=0 DRY_RUN=0 UNSORRY_DISPATCH_LIMIT=10 sent="" rc
  fetch_queued_prove_branches() { return 0; }
  fetch_main_ref() { return 0; }
  queued_branch_refs() {
    printf 'origin/queued/prove/g1/agent-a-1111\n'
    printf 'origin/queued/prove/g1/agent-b-2222\n'
    printf 'origin/queued/prove/g2/agent-c-3333\n'
    printf 'origin/queued/prove/g3/agent-d-4444\n'
  }
  goal_already_proved() { [ "$1" = g2 ]; }
  dispatch_open_pr_goals() { printf 'g3\n'; }
  queued_branch_has_pr() { return 1; }
  submission_governor_allows() { return 0; }
  dispatch_queued_proof_branch() { printf -v sent '%s%s\n' "$sent" "$1"; return 0; }
  dispatch_queue
  rc=$?
  unset -f fetch_queued_prove_branches fetch_main_ref queued_branch_refs \
    goal_already_proved dispatch_open_pr_goals queued_branch_has_pr \
    submission_governor_allows dispatch_queued_proof_branch
  [ "$rc" -eq 0 ] || { log "  dispatch_queue returned $rc"; return 1; }
  local count
  count="$(printf '%s' "$sent" | grep -c '^queued/prove/g1/')"
  [ "$count" -eq 1 ] \
    || { log "  expected exactly one g1 dispatch (one per goal), got '$sent'"; return 1; }
  [ "$(printf '%s' "$sent" | grep -cv '^$')" -eq 1 ] \
    || { log "  expected one dispatch total (g2 proved, g3 has open PR), got '$sent'"; return 1; }
}

test_dispatch_skips_taken_midpass() {
  # ADR-071: a goal that passes the pass-start checks (not proved, no open PR)
  # but is taken — merged or PR'd by a sibling/concurrent dispatcher — by the
  # time the pre-create fresh check runs must NOT be dispatched. This is the
  # post-ADR-064 duplicate leak.
  local ONCE=0 DRY_RUN=0 UNSORRY_DISPATCH_LIMIT=10 sent="" rc
  fetch_queued_prove_branches() { return 0; }
  fetch_main_ref() { return 0; }
  queued_branch_refs() { printf 'origin/queued/prove/g1/agent-a-1111\n'; }
  goal_already_proved() { return 1; }      # not proved at pass start
  dispatch_open_pr_goals() { return 0; }   # no open PRs at pass start
  queued_branch_has_pr() { return 1; }
  submission_governor_allows() { return 0; }
  goal_taken_fresh() { [ "$1" = g1 ]; }    # but taken by the time we re-check
  dispatch_queued_proof_branch() { printf -v sent '%s%s\n' "$sent" "$1"; return 0; }
  dispatch_queue
  rc=$?
  unset -f fetch_queued_prove_branches fetch_main_ref queued_branch_refs \
    goal_already_proved dispatch_open_pr_goals queued_branch_has_pr \
    submission_governor_allows goal_taken_fresh dispatch_queued_proof_branch
  [ "$rc" -eq 0 ] || { log "  dispatch_queue returned $rc"; return 1; }
  [ "$(printf '%s' "$sent" | grep -cv '^$')" -eq 0 ] \
    || { log "  expected 0 dispatches (g1 taken mid-pass), got '$sent'"; return 1; }
}

test_dispatch_solver_fairness() {
  # ADR-075: dispatch order is a per-solver round-robin (by agent-id token when a
  # branch is not in the board), not lexical-by-goal, so a minority backlog is not
  # starved behind a high-volume one. Five branches from token "big" (goals that
  # sort first) and one from "small" (a goal that sorts last): with a dispatch
  # limit of 2, the round-robin must still dispatch the lone "small" branch — under
  # the old lexical order limit=2 would take two "big" goals and never reach it.
  local ONCE=0 DRY_RUN=0 UNSORRY_DISPATCH_LIMIT=2 sent="" sent_lex="" rc
  unset UNSORRY_FAIR_DISPATCH
  fetch_queued_prove_branches() { return 0; }
  fetch_main_ref() { return 0; }
  queued_branch_refs() {
    printf 'origin/queued/prove/abig1/big-1111\n'
    printf 'origin/queued/prove/abig2/big-2222\n'
    printf 'origin/queued/prove/abig3/big-3333\n'
    printf 'origin/queued/prove/abig4/big-4444\n'
    printf 'origin/queued/prove/abig5/big-5555\n'
    printf 'origin/queued/prove/zsmall/small-9999\n'
  }
  goal_already_proved() { return 1; }
  dispatch_open_pr_goals() { return 0; }
  queued_branch_has_pr() { return 1; }
  submission_governor_allows() { return 0; }
  goal_taken_fresh() { return 1; }
  dispatch_queued_proof_branch() { printf -v sent '%s%s\n' "$sent" "$1"; return 0; }
  dispatch_queue
  rc=$?
  # Toggle off -> lexical fall-through: the same limit dispatches two "big" goals
  # and never the "small" one, proving the round-robin is what surfaces it.
  UNSORRY_FAIR_DISPATCH=0
  dispatch_queued_proof_branch() { printf -v sent_lex '%s%s\n' "$sent_lex" "$1"; return 0; }
  dispatch_queue
  unset UNSORRY_FAIR_DISPATCH
  unset -f fetch_queued_prove_branches fetch_main_ref queued_branch_refs \
    goal_already_proved dispatch_open_pr_goals queued_branch_has_pr \
    submission_governor_allows goal_taken_fresh dispatch_queued_proof_branch
  [ "$rc" -eq 0 ] || { log "  dispatch_queue returned $rc"; return 1; }
  printf '%s' "$sent" | grep -q '^queued/prove/zsmall/' \
    || { log "  fair order must dispatch the starved 'small' branch within the limit, got '$sent'"; return 1; }
  [ "$(printf '%s' "$sent" | grep -cv '^$')" -eq 2 ] \
    || { log "  expected 2 dispatches under the limit, got '$sent'"; return 1; }
  ! printf '%s' "$sent_lex" | grep -q '^queued/prove/zsmall/' \
    || { log "  toggle off should fall back to lexical (no 'small' within limit), got '$sent_lex'"; return 1; }
}

test_fair_dispatch_order_survives_early_reader_close() {
  # dispatch_queue stops reading fair_dispatch_order's output the moment it hits
  # its dispatch limit or the submission governor pauses (agent.sh dispatch_queue),
  # closing the pipe under the reordering python. The python must exit cleanly on
  # the resulting EPIPE, NOT dump a BrokenPipeError traceback to stderr — that
  # traceback reads as a crash in run.sh's logs even though dispatch succeeded.
  # Feed far more refs than a pipe buffer can hold so the writer is still emitting
  # when the reader closes, take exactly one line, and assert no traceback leaked.
  # Command substitution waits for the whole pipeline, so the python has fully
  # exited (and flushed its stderr) before we inspect errfile — no race.
  local errfile first
  errfile="$(mktemp)"
  first="$(yes 'origin/queued/prove/gpipe/agent-x-0' | head -n 20000 \
            | fair_dispatch_order 2>"$errfile" | head -n 1)" || true
  if [ "$first" != 'origin/queued/prove/gpipe/agent-x-0' ]; then
    log "  fair_dispatch_order did not emit the expected first ref, got '$first'"
    rm -f "$errfile"; return 1
  fi
  if grep -qE 'BrokenPipeError|Traceback' "$errfile"; then
    log "  fair_dispatch_order leaked a broken-pipe traceback on early reader close:"
    log "    $(tr '\n' ' ' < "$errfile")"
    rm -f "$errfile"; return 1
  fi
  rm -f "$errfile"
}

test_dispatch_open_batch_goals_parses_manifests() {
  # ADR-107: dispatch_open_batch_goals extracts goals ONLY from open prove-batch(…)
  # PRs' Batch-Goals: manifest. A regular prove PR (even one mentioning Batch-Goals)
  # contributes nothing — the title prefix is the discriminator.
  gh() {
    printf '%s' '[{"title":"prove(solo): x","body":"Batch-Goals: solo"},{"title":"prove-batch(2): amortised","body":"intro\n\nBatch-Goals: ga gb\n\nfooter"}]'
  }
  local out
  out="$(dispatch_open_batch_goals | sort | tr '\n' ' ')"
  unset -f gh
  [ "$out" = "ga gb " ] \
    || { log "  expected 'ga gb' from the batch manifest only, got '$out'"; return 1; }
}

test_batch_dedup_skips_batched_goal() {
  # ADR-107: with batching ON, dispatch_queue dedups its singletons against goals
  # already in an open batch PR, so no redundant singleton opens for a batched goal.
  local ONCE=0 DRY_RUN=0 UNSORRY_DISPATCH_LIMIT=10 UNSORRY_BATCH_SIZE=2 sent="" rc
  fetch_queued_prove_branches() { return 0; }
  fetch_main_ref() { return 0; }
  queued_branch_refs() {
    printf 'origin/queued/prove/gb/agent-a-1111\n'
    printf 'origin/queued/prove/g1/agent-b-2222\n'
  }
  goal_already_proved() { return 1; }
  dispatch_open_pr_goals() { return 0; }
  dispatch_open_batch_goals() { printf 'gb\n'; }   # gb is already in an open batch PR
  queued_branch_has_pr() { return 1; }
  submission_governor_allows() { return 0; }
  goal_taken_fresh() { return 1; }
  dispatch_queued_proof_branch() { printf -v sent '%s%s\n' "$sent" "$1"; return 0; }
  dispatch_queue
  rc=$?
  unset -f fetch_queued_prove_branches fetch_main_ref queued_branch_refs \
    goal_already_proved dispatch_open_pr_goals dispatch_open_batch_goals \
    queued_branch_has_pr submission_governor_allows goal_taken_fresh \
    dispatch_queued_proof_branch
  [ "$rc" -eq 0 ] || { log "  dispatch_queue returned $rc"; return 1; }
  printf '%s' "$sent" | grep -q '^queued/prove/g1/' \
    || { log "  expected g1 dispatched, got '$sent'"; return 1; }
  ! printf '%s' "$sent" | grep -q '^queued/prove/gb/' \
    || { log "  gb is in an open batch — must NOT singleton-dispatch, got '$sent'"; return 1; }
}

test_batch_dedup_inactive_at_size_one() {
  # ADR-107: at the default UNSORRY_BATCH_SIZE=1 the batch-dedup augmentation is NOT
  # consulted — dispatch_queue is byte-for-byte its old self (gb dispatches as a
  # normal singleton). A file marker (survives the command-subst subshell) proves
  # dispatch_open_batch_goals is never called.
  local ONCE=0 DRY_RUN=0 UNSORRY_DISPATCH_LIMIT=10 UNSORRY_BATCH_SIZE=1 sent="" rc marker
  marker="$(mktemp)"
  fetch_queued_prove_branches() { return 0; }
  fetch_main_ref() { return 0; }
  queued_branch_refs() { printf 'origin/queued/prove/gb/agent-a-1111\n'; }
  goal_already_proved() { return 1; }
  dispatch_open_pr_goals() { return 0; }
  dispatch_open_batch_goals() { echo called >> "$marker"; printf 'gb\n'; }
  queued_branch_has_pr() { return 1; }
  submission_governor_allows() { return 0; }
  goal_taken_fresh() { return 1; }
  dispatch_queued_proof_branch() { printf -v sent '%s%s\n' "$sent" "$1"; return 0; }
  dispatch_queue
  rc=$?
  unset -f fetch_queued_prove_branches fetch_main_ref queued_branch_refs \
    goal_already_proved dispatch_open_pr_goals dispatch_open_batch_goals \
    queued_branch_has_pr submission_governor_allows goal_taken_fresh \
    dispatch_queued_proof_branch
  local called_size; called_size="$(wc -c < "$marker")"; rm -f "$marker"
  [ "$rc" -eq 0 ] || { log "  dispatch_queue returned $rc"; return 1; }
  [ "$called_size" -eq 0 ] \
    || { log "  dispatch_open_batch_goals must not run at UNSORRY_BATCH_SIZE=1"; return 1; }
  printf '%s' "$sent" | grep -q '^queued/prove/gb/' \
    || { log "  gb must dispatch as a normal singleton at size 1, got '$sent'"; return 1; }
}

test_batch_build_worktree_shallow_safe() {
  # ADR-107: assembling a batch on a SHALLOW clone (the CI dispatcher's checkout)
  # must (a) cherry-pick the proofs successfully and (b) NOT resurrect files main
  # has since deleted/archived. Without the depth-2 deepen, cherry-pick treats the
  # parentless commit as a root and re-adds its whole tree — re-introducing deleted
  # content to main (a soundness bug). Builds a hermetic file:// origin so --depth
  # is honoured (it is ignored for local-path clones).
  local tmp ci rc=0 resurrected=1 hasproof=0
  tmp="$(mktemp -d)"
  (
    set -e
    cd "$tmp"
    git init -q --bare origin.git
    git clone -q origin.git w
    cd w
    git config user.email t@t; git config user.name t
    mkdir -p library/Unsorry
    echo old > library/Unsorry/Archived.lean
    echo base > library/Unsorry/Base.lean
    git add -A; git commit -qm base; git push -q origin HEAD:main
    git checkout -q -b queued/prove/gx/agent-x
    echo px > library/Unsorry/Gx.lean
    git add -A; git commit -qm "prove(gx): gx by agent"; git push -q origin HEAD
    git checkout -q main
    git rm -q library/Unsorry/Archived.lean
    git commit -qm "archive: remove Archived.lean"; git push -q origin main
  ) || { log "  fixture build failed"; rm -rf "$tmp"; return 1; }
  ci="$tmp/ci"
  if ! git clone -q --depth=1 --branch main "file://$tmp/origin.git" "$ci" 2>/dev/null; then
    log "  shallow clone failed"; rm -rf "$tmp"; return 1
  fi
  test -f "$ci/.git/shallow" || { log "  test clone was not shallow — invalid fixture"; rm -rf "$tmp"; return 1; }
  git -C "$ci" config user.email t@t; git -C "$ci" config user.name t
  git -C "$ci" fetch -q --depth=1 origin '+refs/heads/queued/prove/*:refs/remotes/origin/queued/prove/*'
  ( cd "$ci" && build_batch_worktree ".bwt" "batch/test" queued/prove/gx/agent-x ) || rc=$?
  [ -f "$ci/.bwt/library/Unsorry/Gx.lean" ] && hasproof=1
  [ -f "$ci/.bwt/library/Unsorry/Archived.lean" ] || resurrected=0
  git -C "$ci" worktree remove --force .bwt >/dev/null 2>&1 || true
  rm -rf "$tmp"
  [ "$rc" -eq 0 ] || { log "  build_batch_worktree failed on a shallow clone (rc=$rc)"; return 1; }
  [ "$hasproof" -eq 1 ] || { log "  proof Gx.lean missing from the assembled batch"; return 1; }
  [ "$resurrected" -eq 0 ] || { log "  UNSOUND: deleted Archived.lean was resurrected by the batch assembly"; return 1; }
}

run_self_tests() {
  local tests=(
    test_agent_id_generation
    test_agent_id_host_matches
    test_claim_agent_identity_multi_runner
    test_fork_goal_lock
    test_agent_id_validation
    test_solver_resolution
    test_git_identity_resolution
    test_claim_render_golden
    test_translation_render_golden
    test_candidate_filtering
    test_sweep_detection
    test_goal_rewrite
    test_seed_library_cache
    test_suite_context_for_goal
    test_convergence_rewrite
    test_record_validation
    test_require_main_checkout
    test_require_main_matches_origin
    test_fetch_retry_delay
    test_git_fetch_retry
    test_harness_is_stale
    test_solver_credit_decision
    test_relocate_into_worktree_noop
    test_require_main_checkout_isolated
    test_ensure_agent_worktree
    test_provider_effort_ladder
    test_prove_attempt_budget_default
    test_gemini_prove_mutes_cli_effort
    test_gemini_decompose_mutes_cli_effort
    test_gemini_health_probe_uses_version
    test_prove_target_path_guard
    test_prove_attempt_log_does_not_trip_guard
    test_provider_text_module_extraction
    test_run_proof_mock_provider_smoke
    test_binding_module_suppresses_unused_linter
    test_proof_attempt_cleanup
    test_feature_branch_names
    test_claim_push_reentrancy
    test_release_push_reentrancy
    test_claim_recheck_prove_cap
    test_claim_post_success_recheck
    test_camel_name
    test_lean_statement_helpers
    test_lean_sha_determinism
    test_prove_candidate_filtering
    test_decompose_open_prove_guard
    test_local_prove_auto_selection
    test_already_proved_excluded
    test_goal_proved_rewrite
    test_render_index_gateb
    test_index_provenance_render
    test_proof_run_render
    test_affinity_ranking
    test_gap_ranking
    test_viability_skip
    test_recovery_candidates
    test_goal_override_bypasses_viability
    test_affinity_bump_math
    test_affinity_degrades_on_garbage
    test_decomp_caps_and_depth
    test_has_decomposition
    test_unblockable_detection
    test_recompose_fail_floors_at_viability
    test_proved_deps_surfacing
    test_lesson_signature
    test_prove_lessons_surfacing
    test_model_effort_policy
    test_effort_ladder
    test_infra_failure_classifier
    test_open_pr_claim_guard
    test_parse_github_nwo
    test_fork_pr_head_ref
    test_fork_shard
    test_shard_reorder
    test_detect_fork_mode
    test_fork_claimless
    test_fork_open_pr_dedup_targets_upstream
    test_submission_governor_reason
    test_submission_governor_allows_with_stubbed_gh
    test_queued_branch_claim_guard
    test_dispatch_goal_dedup
    test_dispatch_skips_taken_midpass
    test_dispatch_solver_fairness
    test_fair_dispatch_order_survives_early_reader_close
    test_dispatch_open_batch_goals_parses_manifests
    test_batch_dedup_skips_batched_goal
    test_batch_dedup_inactive_at_size_one
    test_batch_build_worktree_shallow_safe
    test_demote_open_prove_records_telemetry_only
    test_floored_recompose_noop_records_telemetry_only
    test_render_decomp_gateb
    test_independent_check_advisory_opt_in
    test_independent_check_pr_note_roundtrip
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
PROVE=0
PROVE_LOCAL=0
DISPATCH_QUEUE=0
ONCE=0
GOAL_FILTER=""
DRY_RUN=0
SELF_TEST=0
PI_MODE=0
UNSORRY_PROVIDER="${UNSORRY_PROVIDER:-claude}"
SOLVER=""
PROOF_MODEL_USED=""
PROOF_EFFORT_USED=""
PROOF_ATTEMPTS_USED=""
PROOF_SOLVE_SECONDS=""
# ADR-096: the advisory independent-check verdict for the current proof (empty
# when the check did not run). Set by independent_check_advisory, attached as a
# commit trailer on the proof commit so the dispatcher can surface it on the PR.
INDEPENDENT_CHECK_VERDICT=""

# ADR-068 fork-native contribution mode. A contributor with no write access to
# the canonical upstream runs the prover from a fork: it proves CLAIMLESS (no
# origin/claims push — fork-inaccessible), keeps the fork's main synced to the
# upstream so the ADR-042 relocate/sync machinery is unchanged, and submits each
# proof by a cross-repo fork→PR that the upstream kernel re-verifies (Gate A/B).
# Default off; the canonical (write-access) path is unchanged when FORK_MODE=0.
FORK_MODE=0
FORK_REQUEST=0
FORK_OWNER=""
UNSORRY_UPSTREAM="${UNSORRY_UPSTREAM:-agenticsnz/unsorry}"
UPSTREAM_REMOTE="upstream"

# -pi (ADR-025): source endpoint/key/model from pi-coder's ~/.pi/agent/models.json
# by the existing UNSORRY_MODEL name, then drive the OpenAI-compatible path. The
# seam to the existing OpenAI provider is environment variables only — this sets
# OPENAI_BASE_URL / OPENAI_API_KEY / UNSORRY_PROVIDER=openai / UNSORRY_MODEL=<id>
# and the rest of the run is provider-openai with a custom base_url.
resolve_pi_config() {
  [ -n "${UNSORRY_MODEL:-}" ] \
    || die_config "-pi requires a model name (as '-pi <model>' or UNSORRY_MODEL — the name/id in ~/.pi/agent/models.json)"
  local out
  out="$(python3 "$(dirname "$0")/../tools/llm_providers/pi_config.py" \
           resolve --model "$UNSORRY_MODEL" 2>&1)" \
    || die_config "-pi: $out"
  # three lines, in the order pi_config.main() prints them
  OPENAI_BASE_URL="$(printf '%s\n' "$out" | sed -n '1p')"
  OPENAI_API_KEY="$(printf '%s\n' "$out" | sed -n '2p')"
  UNSORRY_MODEL="$(printf '%s\n' "$out" | sed -n '3p')"
  export OPENAI_BASE_URL OPENAI_API_KEY
  UNSORRY_PROVIDER=openai
  log "-pi: provider=openai model=$UNSORRY_MODEL base_url=$OPENAI_BASE_URL"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --translate-only) TRANSLATE_ONLY=1 ;;
      --prove) PROVE=1 ;;
      --prove-local) PROVE_LOCAL=1; PROVE=1; ONCE=1 ;;
      --fork) FORK_REQUEST=1 ;;
      --dispatch-queue) DISPATCH_QUEUE=1; PROVE=1 ;;
      --provider)
        [ $# -ge 2 ] || { usage >&2; die_config "--provider requires a value"; }
        UNSORRY_PROVIDER="$2"
        shift
        ;;
      --once) ONCE=1 ;;
      --goal)
        [ $# -ge 2 ] || { usage >&2; die_config "--goal requires a value"; }
        GOAL_FILTER="$2"
        shift
        ;;
      --dry-run) DRY_RUN=1 ;;
      -pi)
        PI_MODE=1
        # Optional model argument: `-pi <model>` sets the model to resolve from
        # ~/.pi/agent/models.json (else falls back to UNSORRY_MODEL). The next
        # token is taken only when it is not another flag.
        if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then
          UNSORRY_MODEL="$2"
          shift
        fi
        ;;
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
# True when a candidate is in --goal scope: the goal itself, or one of its
# decomposition descendants (`<goal>-s1`, `<goal>-s1-s2`, …). This lets a Phase-2
# run focus an agent on a target tree without naming the machine-minted sub ids.
goal_in_scope() {
  local cand="$1"
  [ -z "$GOAL_FILTER" ] && return 0
  case "$cand" in
    "$GOAL_FILTER" | "$GOAL_FILTER"-*) return 0 ;;
    *) return 1 ;;
  esac
}

# --goal, minus goals already handled (success or failure) this session.
select_candidates() {
  local translations_dir="$1" cand
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    goal_in_scope "$cand" || continue
    [ -n "${HANDLED[$cand]:-}" ] && continue
    printf '%s\n' "$cand"
  done < <(py_helper candidates goals "$CLAIMS_WT/claims" "$translations_dir" "$AGENT_ID" "")
}

# Prove candidates for this iteration: same --goal / HANDLED filtering as the
# translate path, over the prove-candidate enumerator (phase≡prove, open,
# uncapped, not already proved).
select_prove_candidates() {
  local cand
  # An explicit --goal is an override of auto-selection: pass it as --force so a
  # named-but-sub-viable goal is still surfaced (ids are space-free, validated
  # by is-id, so the unquoted expansion splits into exactly two args).
  # ADR-076: fork mode shard-reorders the ranked list (advisory; cat otherwise).
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    goal_in_scope "$cand" || continue
    [ -n "${HANDLED[$cand]:-}" ] && continue
    printf '%s\n' "$cand"
  done < <(py_helper prove-candidates goals "$CLAIMS_WT/claims" library "$AGENT_ID" "" \
             ${GOAL_FILTER:+--force "$GOAL_FILTER"}) | fork_maybe_shard
}

# Local smoke has no claims or coordination. Reuse the production prove ranking
# over local HEAD and take its highest-ranked open, unproved goal.
select_local_prove_goal() {
  local goals_dir="${1:-goals}"
  local library_dir="${2:-library}"
  local claims_dir="${3:-$SESSION_TMP/local-no-claims}"
  py_helper prove-candidates \
    "$goals_dir" "$claims_dir" "$library_dir" local-provider "" | sed -n '1p'
}

# ADR-009 unblock sweep: re-open any blocked parent whose decomposition's
# sub-lemmas are now all proved, so an agent can claim the parent and prove its
# own signature with the subs available as imports. A small gated PR per parent
# (editing only the goal record's status, not a Lean path → Gate A
# short-circuits). Best-effort and idempotent: a racing duplicate re-open
# produces the same edit. Tracks parents swept this session to avoid re-trying.
unblock_sweep() {
  local parent prwt branch
  while IFS= read -r parent; do
    [ -n "$parent" ] || continue
    [ -n "${SWEPT[$parent]:-}" ] && continue
    SWEPT[$parent]=1
    branch="$(feature_branch unblock "$parent")" || continue
    prwt="$UNSORRY_WORKDIR/unblock-${parent}-${AGENT_ID}"
    open_pr_worktree "$prwt" "$branch" || continue
    if py_helper rewrite-goal "$prwt/goals/$parent.aisp" open; then
      submit_pr_tree "$prwt" "$branch" \
        "unblock($parent): sub-lemmas proved, re-opening (ADR-009)" \
        "Automated re-open (ADR-009, SPEC-009-A): all of \`$parent\`'s decomposition sub-lemmas are proved, so the parent returns to \`open\` and can be proved with the subs as imports. It still closes only through Gate A." \
        goals || true
    fi
    git worktree remove --force "$prwt" >/dev/null 2>&1 || true
    git branch -q -D "$branch" >/dev/null 2>&1 || true
  done < <(py_helper unblockable goals decompositions library)
}

# ADR-044 recovery pool selector: parked prove orphans (affinity < τ_v) the
# normal queue can never surface, filtered by scope and what this session has
# already handled — the same shaping select_prove_candidates applies.
select_recovery_candidates() {
  local cand
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    goal_in_scope "$cand" || continue
    [ -n "${HANDLED[$cand]:-}" ] && continue
    printf '%s\n' "$cand"
  done < <(py_helper recovery-candidates goals "$CLAIMS_WT/claims" library "$AGENT_ID") | fork_maybe_shard
}

# Walk a newline-separated candidate list (highest priority first), skipping
# prove goals whose work is already in flight (an open prove PR — ADR-017), and
# claim the first that is free. Sets CLAIMED_GOAL to that goal, or "" if the
# whole list was in flight or lost the claim race. Diagnostics go to stderr via
# log(), so stdout stays clean for the caller.
claim_from_pool() {
  local pool="$1" cand
  CLAIMED_GOAL=""
  [ -n "$pool" ] || return 0
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    if [ "$PROVE" -eq 1 ] && open_prove_pr_exists "$cand"; then
      log "skipping $cand — an open prove PR is already in flight"
      continue
    fi
    if [ "$PROVE" -eq 1 ] && queued_prove_branch_exists "$cand"; then
      log "skipping $cand — a queued prove branch is waiting for dispatch"
      continue
    fi
    # ADR-068 fork-local goal lock: in fork mode claim_goal is a claimless no-op,
    # so a mkdir-lock on a per-machine path is the only dedup between co-located
    # provers. Skip past any goal a LIVE sibling already locked (no-op otherwise),
    # mirroring the "in flight" skips above. Released by prove_goal on every exit.
    if [ "$PROVE" -eq 1 ] && ! acquire_goal_lock "$cand"; then
      log "skipping $cand — locked by a co-located fork prover (ADR-068)"
      continue
    fi
    if claim_goal "$cand"; then
      CLAIMED_GOAL="$cand"
      return 0
    fi
    # Claim race lost (non-fork path only — claim_goal cannot fail in fork mode):
    # drop the goal lock we just took so it does not strand this candidate.
    release_goal_lock "$cand"
  done <<< "$pool"
  return 0
}

main() {
  # #428: remember the argv and the on-disk sha of the script this process was
  # launched with, so the cycle can re-exec the latest harness after sync_repo.
  _ORIG_ARGV=("$@")
  _HARNESS_SHA="$(git hash-object "${BASH_SOURCE[0]}" 2>/dev/null || echo unknown)"
  parse_args "$@"
  require_repo_root
  require_cmd python3

  SESSION_TMP="$(mktemp -d)"
  trap 'rm -rf "$SESSION_TMP"' EXIT

  if [ "$SELF_TEST" -eq 1 ]; then
    require_cmd git  # the push re-entrancy tests use local bare fixtures
    run_self_tests
  fi

  if [ "$TRANSLATE_ONLY" -eq 1 ] && [ "$PROVE" -eq 1 ]; then
    die_config "--translate-only, --prove, and --dispatch-queue are mutually exclusive"
  fi
  [ "$TRANSLATE_ONLY" -eq 1 ] || [ "$PROVE" -eq 1 ] \
    || die_config "select a mode: --translate-only, --prove, or --dispatch-queue (or --self-test)"

  if [ "$DISPATCH_QUEUE" -eq 1 ]; then
    [ -z "$GOAL_FILTER" ] || die_config "--goal is not supported with --dispatch-queue"
    require_cmd git gh
    require_unsorry_origin
    require_main_checkout
    UNSORRY_SUBMISSION_GOVERNOR="${UNSORRY_SUBMISSION_GOVERNOR:-1}"
    UNSORRY_SUBMISSION_FREEZE="${UNSORRY_SUBMISSION_FREEZE:-0}"
    UNSORRY_MAX_OPEN_PROVE_PRS="${UNSORRY_MAX_OPEN_PROVE_PRS:-40}"
    UNSORRY_MAX_GATE_A_IN_FLIGHT="${UNSORRY_MAX_GATE_A_IN_FLIGHT:-8}"
    UNSORRY_GOVERNOR_SCAN_LIMIT="${UNSORRY_GOVERNOR_SCAN_LIMIT:-200}"
    UNSORRY_DISPATCH_LIMIT="${UNSORRY_DISPATCH_LIMIT:-1}"
    UNSORRY_BATCH_SIZE="${UNSORRY_BATCH_SIZE:-1}"
    UNSORRY_GOVERNOR_WAIT="${UNSORRY_GOVERNOR_WAIT:-300}"
    case "$UNSORRY_SUBMISSION_GOVERNOR" in
      0|1) ;;
      *) die_config "UNSORRY_SUBMISSION_GOVERNOR '$UNSORRY_SUBMISSION_GOVERNOR' must be 0 or 1" ;;
    esac
    validate_integer_knob UNSORRY_MAX_OPEN_PROVE_PRS "$UNSORRY_MAX_OPEN_PROVE_PRS" 1
    validate_integer_knob UNSORRY_MAX_GATE_A_IN_FLIGHT "$UNSORRY_MAX_GATE_A_IN_FLIGHT" 1
    validate_integer_knob UNSORRY_GOVERNOR_SCAN_LIMIT "$UNSORRY_GOVERNOR_SCAN_LIMIT"
    validate_integer_knob UNSORRY_DISPATCH_LIMIT "$UNSORRY_DISPATCH_LIMIT"
    validate_integer_knob UNSORRY_BATCH_SIZE "$UNSORRY_BATCH_SIZE"
    validate_integer_knob UNSORRY_GOVERNOR_WAIT "$UNSORRY_GOVERNOR_WAIT"
    gh auth status >/dev/null 2>&1 || die_config "gh is not authenticated"
    while :; do
      # ADR-107: assemble a batch PR first (when enabled), then singleton-dispatch
      # the remainder. Batching is one governor admission for K proofs; dispatch_queue
      # dedups its singletons against the open batch via dispatch_open_batch_goals.
      [ "$UNSORRY_BATCH_SIZE" -gt 1 ] && dispatch_batch_pass
      dispatch_queue || exit 1
      [ "$ONCE" -eq 1 ] && exit 0
      [ "$UNSORRY_GOVERNOR_WAIT" -gt 0 ] || exit 0
      log "queue dispatcher waiting ${UNSORRY_GOVERNOR_WAIT}s before next dispatch pass"
      sleep "$UNSORRY_GOVERNOR_WAIT"
    done
  fi

  # ADR-068: decide fork mode before relocating, so the per-agent worktree bases
  # on a fork-main already synced to the upstream. The prove arm only; --prove-local
  # is HEAD-only with no submission, and --dispatch-queue exited above.
  if [ "$PROVE" -eq 1 ] && [ "$PROVE_LOCAL" -eq 0 ]; then
    require_cmd git gh
    detect_fork_mode
  fi

  # ADR-042: relocate into a dedicated per-agent worktree before any provider,
  # auth, or model resolution, so all of it runs once in the isolated tree.
  # --self-test exits above; --prove-local operates on the caller's committed
  # HEAD by design, so neither relocates.
  if [ "$PROVE_LOCAL" -eq 0 ]; then
    relocate_into_agent_worktree
  fi

  # -pi resolves to provider=openai with a custom base_url before provider
  # validation and before either prove branch, so both modes inherit it.
  if [ "${PI_MODE:-0}" -eq 1 ]; then
    resolve_pi_config
  fi

  if [ -n "$GOAL_FILTER" ]; then
    py_helper is-id "$GOAL_FILTER" \
      || die_config "--goal '$GOAL_FILTER' violates the Id grammar"
  fi
  case "$UNSORRY_PROVIDER" in
    claude|codex|gemini|openai) ;;
    *) die_config "unsupported provider '$UNSORRY_PROVIDER' (expected claude, codex, gemini, or openai)" ;;
  esac

  require_cmd git timeout date

  if [ "$PROVE_LOCAL" -eq 1 ]; then
    if [ -z "$GOAL_FILTER" ]; then
      GOAL_FILTER="$(select_local_prove_goal)"
      if [ -z "$GOAL_FILTER" ]; then
        log "no open, unproved local proof goals"
        exit 0
      fi
      log "auto-selected local goal $GOAL_FILTER"
    fi
    git cat-file -e "HEAD:goals/$GOAL_FILTER.lean" 2>/dev/null \
      || die_config "goal statement goals/$GOAL_FILTER.lean does not exist at local HEAD"
    git cat-file -e "HEAD:goals/$GOAL_FILTER.aisp" 2>/dev/null \
      || die_config "goal record goals/$GOAL_FILTER.aisp does not exist at local HEAD"
    # Non-login automation often sees an obsolete NVM Node first and omits
    # elan entirely. Normalize both toolchain locations before probing or
    # launching a provider; retain the caller's remaining PATH entries.
    PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.elan/bin:$PATH"
    export PATH
    ensure_lake || die_config "the Lean build tool 'lake' is required and could not be installed automatically"
    case "$UNSORRY_PROVIDER" in
      claude) require_cmd claude ;;
      codex) require_cmd codex ;;
      gemini) require_cmd gemini ;;
      openai) [ -n "${OPENAI_API_KEY:-}" ] || die_config "OPENAI_API_KEY is required for --provider openai" ;;
    esac
    UNSORRY_MODEL="${UNSORRY_MODEL:-}"
    if [ "$UNSORRY_PROVIDER" = claude ] || [ "$UNSORRY_PROVIDER" = gemini ]; then
      local local_resolved cmd_help
      if [ "$UNSORRY_PROVIDER" = claude ]; then
        cmd_help="$(claude --help 2>/dev/null || true)"
      else
        cmd_help="$(gemini --help 2>/dev/null || true)"
      fi
      local_resolved="$(resolve_model_effort prove "$UNSORRY_MODEL" "${UNSORRY_EFFORT:-}" "$cmd_help")"
      UNSORRY_MODEL="${local_resolved% *}"
      UNSORRY_EFFORT="${local_resolved#* }"
      [ "$UNSORRY_EFFORT" = "-" ] && UNSORRY_EFFORT=""
    else
      UNSORRY_EFFORT="${UNSORRY_EFFORT:-high}"
    fi
    UNSORRY_WALL="${UNSORRY_WALL:-1800}"
    [[ "$UNSORRY_WALL" =~ ^[0-9]+$ ]] \
      || die_config "UNSORRY_WALL '$UNSORRY_WALL' is not an integer"
    UNSORRY_FASTFAIL="${UNSORRY_FASTFAIL:-240}"
    [[ "$UNSORRY_FASTFAIL" =~ ^[0-9]+$ ]] \
      || die_config "UNSORRY_FASTFAIL '$UNSORRY_FASTFAIL' is not an integer"
    UNSORRY_ATTEMPTS="${UNSORRY_ATTEMPTS:-$(prove_attempt_budget_default)}"
    [[ "$UNSORRY_ATTEMPTS" =~ ^[1-9][0-9]*$ ]] \
      || die_config "UNSORRY_ATTEMPTS '$UNSORRY_ATTEMPTS' is not a positive integer"
    log "local prover starting (provider=$UNSORRY_PROVIDER model=${UNSORRY_MODEL:-default} effort=${UNSORRY_EFFORT:-default} attempts=$UNSORRY_ATTEMPTS wall=${UNSORRY_WALL}s; HEAD only, no remote operations)"
    prove_local_goal "$GOAL_FILTER"
    exit $?
  fi

  if [ "$PROVE" -eq 0 ] && [ "$UNSORRY_PROVIDER" != claude ]; then
    die_config "--provider $UNSORRY_PROVIDER is supported only with --prove or --prove-local"
  fi
  require_unsorry_origin
  require_main_checkout

  # ADR-013/ADR-015: Claude keeps its mode-specific model/effort resolver.
  # Codex, Gemini, and OpenAI use their default models unless overridden and
  # map the prove ladder.
  local mode; [ "$PROVE" -eq 1 ] && mode=prove || mode=translate
  if [ "$UNSORRY_PROVIDER" = codex ] || [ "$UNSORRY_PROVIDER" = gemini ] || [ "$UNSORRY_PROVIDER" = openai ]; then
    UNSORRY_MODEL="${UNSORRY_MODEL:-}"
    UNSORRY_EFFORT="${UNSORRY_EFFORT:-ladder}"
  else
    local resolved
    resolved="$(resolve_model_effort "$mode" "${UNSORRY_MODEL:-}" "${UNSORRY_EFFORT:-}" \
      "$(claude --help 2>/dev/null || true)")"
    UNSORRY_MODEL="${resolved% *}"
    UNSORRY_EFFORT="${resolved#* }"
    [ "$UNSORRY_EFFORT" = "-" ] && UNSORRY_EFFORT=""
  fi
  UNSORRY_WALL="${UNSORRY_WALL:-1800}"
  [[ "$UNSORRY_WALL" =~ ^[0-9]+$ ]] \
    || die_config "UNSORRY_WALL '$UNSORRY_WALL' is not an integer"
  UNSORRY_FASTFAIL="${UNSORRY_FASTFAIL:-240}"
  [[ "$UNSORRY_FASTFAIL" =~ ^[0-9]+$ ]] \
    || die_config "UNSORRY_FASTFAIL '$UNSORRY_FASTFAIL' is not an integer"
  UNSORRY_TTL="${UNSORRY_TTL:-$(py_helper ttl)}"
  [[ "$UNSORRY_TTL" =~ ^[0-9]+$ ]] \
    || die_config "UNSORRY_TTL '$UNSORRY_TTL' is not an integer"
  # ADR-015: prove's default budget is one attempt per ladder rung.
  if [ "$mode" = prove ]; then
    UNSORRY_ATTEMPTS="${UNSORRY_ATTEMPTS:-$(prove_attempt_budget_default)}"
  else
    UNSORRY_ATTEMPTS="${UNSORRY_ATTEMPTS:-$(py_helper attempts)}"
  fi
  [[ "$UNSORRY_ATTEMPTS" =~ ^[1-9][0-9]*$ ]] \
    || die_config "UNSORRY_ATTEMPTS '$UNSORRY_ATTEMPTS' is not a positive integer"
  UNSORRY_WORKDIR="${UNSORRY_WORKDIR:-$HOME/.unsorry/work}"
  mkdir -p "$UNSORRY_WORKDIR" || die_config "cannot create UNSORRY_WORKDIR '$UNSORRY_WORKDIR'"
  UNSORRY_SUBMISSION_GOVERNOR="${UNSORRY_SUBMISSION_GOVERNOR:-1}"
  UNSORRY_SUBMISSION_FREEZE="${UNSORRY_SUBMISSION_FREEZE:-0}"
  UNSORRY_SUBMIT_MODE="${UNSORRY_SUBMIT_MODE:-queue}"
  UNSORRY_MAX_OPEN_PROVE_PRS="${UNSORRY_MAX_OPEN_PROVE_PRS:-40}"
  UNSORRY_MAX_GATE_A_IN_FLIGHT="${UNSORRY_MAX_GATE_A_IN_FLIGHT:-8}"
  UNSORRY_GOVERNOR_SCAN_LIMIT="${UNSORRY_GOVERNOR_SCAN_LIMIT:-200}"
  UNSORRY_GOVERNOR_WAIT="${UNSORRY_GOVERNOR_WAIT:-300}"
  case "$UNSORRY_SUBMISSION_GOVERNOR" in
    0|1) ;;
    *) die_config "UNSORRY_SUBMISSION_GOVERNOR '$UNSORRY_SUBMISSION_GOVERNOR' must be 0 or 1" ;;
  esac
  case "$UNSORRY_SUBMIT_MODE" in
    pr|queue) ;;
    *) die_config "UNSORRY_SUBMIT_MODE '$UNSORRY_SUBMIT_MODE' must be pr or queue" ;;
  esac
  validate_integer_knob UNSORRY_MAX_OPEN_PROVE_PRS "$UNSORRY_MAX_OPEN_PROVE_PRS" 1
  validate_integer_knob UNSORRY_MAX_GATE_A_IN_FLIGHT "$UNSORRY_MAX_GATE_A_IN_FLIGHT" 1
  validate_integer_knob UNSORRY_GOVERNOR_SCAN_LIMIT "$UNSORRY_GOVERNOR_SCAN_LIMIT"
  validate_integer_knob UNSORRY_GOVERNOR_WAIT "$UNSORRY_GOVERNOR_WAIT"

  resolve_agent_id
  if [ "$DRY_RUN" -eq 0 ]; then
    require_cmd gh
    case "$UNSORRY_PROVIDER" in
      claude) require_cmd claude ;;
      codex)
        PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.elan/bin:$PATH"
        export PATH
        require_cmd codex
        ;;
      gemini)
        PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.elan/bin:$PATH"
        export PATH
        require_cmd gemini
        ;;
    esac
    gh auth status >/dev/null 2>&1 || die_config "gh is not authenticated"
    [ "$PROVE" -eq 1 ] && resolve_solver
    [ "$PROVE" -eq 1 ] && guard_solver_credit
    [ "$PROVE" -eq 1 ] && resolve_git_identity
    # prove verify builds locally — install lake (elan) if it is missing
    [ "$PROVE" -eq 1 ] && { ensure_lake || die_config "the Lean build tool 'lake' is required and could not be installed automatically"; }
  fi

  local effort_disp="${UNSORRY_EFFORT:-default}"
  if [ "$UNSORRY_EFFORT" = ladder ]; then
    if [ "$UNSORRY_PROVIDER" = codex ]; then
      effort_disp="ladder(medium→high→xhigh)"
    else
      effort_disp="ladder(high→xhigh→max)"
    fi
  fi
  log "agent $AGENT_ID starting ($mode; provider=$UNSORRY_PROVIDER model=${UNSORRY_MODEL:-default} effort=$effort_disp attempts=$UNSORRY_ATTEMPTS wall=${UNSORRY_WALL}s ttl=${UNSORRY_TTL}s submit=$UNSORRY_SUBMIT_MODE governor=${UNSORRY_SUBMISSION_GOVERNOR})"

  declare -A HANDLED=()
  declare -A SWEPT=()
  local overall=0 translations_dir candidates goal cand stmt cycle_failed prc rc

  while :; do
    # Step 1 — pull main, refresh the claims worktree, then re-exec if main
    # brought a newer agent.sh (so the cycle runs the latest code, #428).
    # ADR-059: an exhausted fetch returns 3 (infra → supervise.sh backs off);
    # other sync failures (reset/merge) stay 1 (cycle retry).
    sync_repo || { rc=$?; log "repository sync failed (rc=$rc)"; exit "$rc"; }
    maybe_reexec_on_harness_update
    if [ "$PROVE" -eq 1 ] && ! submission_governor_allows; then
      if [ "$UNSORRY_GOVERNOR_WAIT" -gt 0 ] && [ "$ONCE" -eq 0 ]; then
        log "submission governor waiting ${UNSORRY_GOVERNOR_WAIT}s before retry"
        sleep "$UNSORRY_GOVERNOR_WAIT"
        continue
      fi
      break
    fi

    # Steps 1b–3 — enumerate and select (mode-specific). The convergence
    # sweep is a translate-only janitor step; the unblock sweep is its prove
    # analogue (ADR-009): re-open blocked parents whose sub-lemmas are all proved.
    if [ "$PROVE" -eq 1 ]; then
      # Warm this checkout's library oleans (at origin/main) so each prove
      # worktree's verify is seeded and compiles only its new module.
      ensure_warm_library
      unblock_sweep || overall=1
      candidates="$(select_prove_candidates)"
    else
      translations_dir="$(main_translations_dir)" || exit 1
      convergence_sweep "$translations_dir" || overall=1
      candidates="$(select_candidates "$translations_dir")"
    fi
    # An empty viable queue is terminal for translate mode, but in prove mode it
    # may still have recoverable orphans (ADR-044) — fall through to step 4.
    if [ -z "$candidates" ] && [ "$PROVE" -eq 0 ]; then
      log "no claimable goal — nothing to do"
      break
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      if [ -n "$candidates" ]; then
        goal="$(printf '%s\n' "$candidates" | head -n 1)"
        printf 'dry-run: would claim goal %s (%s; %d candidate(s): %s)\n' \
          "$goal" "$mode" "$(printf '%s\n' "$candidates" | wc -l)" \
          "$(printf '%s\n' "$candidates" | paste -sd ' ' -)"
      else
        # prove mode, empty viable queue: report what recovery would re-surface.
        local recovery
        recovery="$(select_recovery_candidates)"
        if [ -n "$recovery" ] && [ "${UNSORRY_RECOVERY:-1}" != 0 ]; then
          printf 'dry-run: no viable goal; would recover parked goal %s (%d parked below τ_v: %s)\n' \
            "$(printf '%s\n' "$recovery" | head -n 1)" \
            "$(printf '%s\n' "$recovery" | wc -l)" \
            "$(printf '%s\n' "$recovery" | paste -sd ' ' -)"
        else
          printf 'dry-run: no viable or recoverable goal\n'
        fi
      fi
      exit 0
    fi

    # Step 4 — claim from the viable pool, skipping a candidate whose work is in
    # flight (open prove PR, ADR-017) and moving on past a claim-race loss. If
    # nothing viable is claimable, fall back to the ADR-044 recovery pool: parked
    # orphans (affinity < τ_v) the normal queue never surfaces. A recovered goal
    # runs the SAME prove_goal path below, so it retries with its accumulated
    # lessons (ADR-024) and decomposes on failure (ADR-009) — no special casing.
    claim_from_pool "$candidates"
    goal="$CLAIMED_GOAL"
    if [ -z "$goal" ] && [ "$PROVE" -eq 1 ] && [ "${UNSORRY_RECOVERY:-1}" != 0 ]; then
      claim_from_pool "$(select_recovery_candidates)"
      goal="$CLAIMED_GOAL"
      [ -n "$goal" ] \
        && log "recovery: re-surfaced parked goal $goal (below τ_v) for a lessons-armed retry (ADR-044)"
    fi
    if [ -z "$goal" ]; then
      log "no viable or recoverable prove work this pass"
      if [ "$PROVE" -eq 1 ] && [ "$UNSORRY_GOVERNOR_WAIT" -gt 0 ] && [ "$ONCE" -eq 0 ]; then
        log "waiting ${UNSORRY_GOVERNOR_WAIT}s for new prove work"
        sleep "$UNSORRY_GOVERNOR_WAIT"
        continue
      fi
      break
    fi

    # Steps 5–10 — work, check in, release (mode-specific). prove_goal owns
    # its own release + prove-failed handling; the translate arm is unchanged.
    cycle_failed=0
    if [ "$PROVE" -eq 1 ]; then
      prc=0
      prove_goal "$goal" || prc=$?
      # ADR-068: release the fork-local goal lock here, in the loop, so it is
      # dropped for EVERY prove_goal return — including the early `return 1`
      # setup failures (camel-name, branch, open_pr_worktree) that exit before
      # prove_goal's own release_claim/release_goal_lock line. Without this a
      # transient worktree-add failure would strand the lock for the whole life
      # of this (still-live) prover, blocking every co-located sibling off the
      # goal — the inverse of the dedup this fix exists to provide. Belt-and-
      # braced with the in-prove_goal release, mirroring how the translate arm
      # also release_claim's at loop level; release_goal_lock is idempotent.
      release_goal_lock "$goal"
      if [ "$prc" -eq 2 ]; then
        # ADR-016: the CLI cannot run (quota, auth, network). Every further
        # cycle would fail identically and poison the queue — stop cleanly.
        log "stopping: $UNSORRY_PROVIDER CLI unavailable — no queue penalties applied (ADR-016)"
        exit 3
      fi
      [ "$prc" -ne 0 ] && cycle_failed=1
    elif stmt="$(run_translation "$goal")"; then
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
