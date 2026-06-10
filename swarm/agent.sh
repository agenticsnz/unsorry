#!/usr/bin/env bash
# swarm/agent.sh — swarm agent loop (ADR-006, ADR-007, SPEC-007-A).
# Phase-0 translate-only mode + Phase-1 prove mode.
#
# Usage:
#   ./swarm/agent.sh --translate-only [--once] [--goal <id>] [--dry-run]
#   ./swarm/agent.sh --prove [--once] [--goal <id>] [--dry-run]
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
  ./swarm/agent.sh --prove [--once] [--goal <id>] [--dry-run]
  ./swarm/agent.sh --self-test

Flags:
  --translate-only  Phase-0 mode: only phase≡translate goals are candidates
  --prove           Phase-1 mode: only phase≡prove, unproved goals are candidates
  --once            Run exactly one cycle then exit
  --goal <id>       Restrict selection to one goal (trial orchestration)
  --dry-run         Stop after selection: print the would-be claim, claim nothing
  --self-test       Run the built-in hermetic tests and exit (0 green / 1 red)

Environment:
  UNSORRY_AGENT_ID  Swarm identity (default: ~/.unsorry/agent-id, created on first run)
  UNSORRY_MODEL     Model for translation/proof calls (default: sonnet)
  UNSORRY_WORKDIR   Claims worktree + metrics.jsonl home (default: ~/.unsorry/work)
  UNSORRY_WALL      Wall-clock seconds per claude call (default: 1800)
  UNSORRY_TTL       Claim TTL seconds (default: tools/gate_b/config.py TTL_SECONDS)
  UNSORRY_ATTEMPTS  Prove build/audit attempts (default: config.py BUDGET_ATTEMPTS)
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


def camel_name(goal: str) -> str:
    """CamelCase library-module name from a goal id (the contract Id grammar
    is `[a-z0-9][a-z0-9-]*`): split on '-', capitalize each part, join.
    `nat-add-comm-thm` → `NatAddCommThm`. Deterministic and reversible enough
    to be unique (the goal-id grammar forbids the only collision sources)."""
    parts = [p for p in goal.split("-") if p]
    if not parts:
        sys.exit(f"py_helper: empty goal id {goal!r}")
    return "".join(p[:1].upper() + p[1:] for p in parts)


def lean_statement(lean_text: str) -> str:
    """The canonical statement string of a goal's Lean file: drop `import`
    and `--` comment lines, take the `theorem`/`lemma` declaration, cut the
    proof (everything from the body `:=` onward), and collapse every run of
    whitespace to a single space (strip ends). The theorem name and full
    signature are retained — this string IS the content the index addresses."""
    body = "\n".join(
        ln for ln in lean_text.splitlines()
        if not ln.lstrip().startswith(("--", "import"))
    )
    match = re.search(r"\b(?:theorem|lemma)\b", body)
    if match is None:
        sys.exit("py_helper: goal .lean has no theorem/lemma declaration")
    decl = body[match.start():]
    cut = decl.find(":=")
    if cut == -1:
        sys.exit("py_helper: goal .lean theorem has no ':=' proof separator")
    return re.sub(r"\s+", " ", decl[:cut]).strip()


def lean_theorem_name(lean_text: str) -> str:
    """The declared name of a goal's `theorem <name> …`/`lemma <name> …`."""
    match = re.search(r"\b(?:theorem|lemma)\s+([A-Za-z_][A-Za-z0-9_']*)", lean_text)
    if match is None:
        sys.exit("py_helper: goal .lean has no named theorem/lemma")
    return match.group(1)


def lean_statement_sha(lean_text: str) -> str:
    """Content address of a goal's Lean statement: sha256 (lowercase hex) of
    the UTF-8 bytes of `lean_statement`. This is the prove-cycle analogue of
    `tools.fidelity` statement_sha for translate goals (which have an AISP
    canonical statement to address); a prove goal has only its Lean text, so
    the index is keyed by the sha of that normalized statement string."""
    return hashlib.sha256(lean_statement(lean_text).encode("utf-8")).hexdigest()


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
    """aff-bump <goal.aisp> <delta> — add <delta> to the goal's aff field,
    inserting ``aff≜<delta>`` after the sha≜ line if none exists yet
    (⟦Γ:Affinity⟧ update; +1 on merge, -10 on a failed attempt)."""
    path = Path(args[0])
    delta = int(args[1])
    record = parse_record(path.read_text(encoding="utf-8"))
    new = _affinity(record) + delta
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


def cmd_prove_candidates(args):
    """prove-candidates <goals-dir> <claims-dir> <library-dir> <agent> [<at>]

    SPEC-007-A prove step 2: goals with phase≡prove, status≡open, fewer than
    PROVE_CLAIM_CAP live claims by distinct other agents, no live claim by
    self, and NOT already proved (no library/index entry). Ordered by
    affinity-weighted, gap-based ranking (ADR-010 / SPEC-010-A)."""
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
    for goal in _rank(survivors, proved):
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
    """render-index <sha> <goal> <name> <stmt> — print a library/index entry
    (SPEC-007-A prove step on success), same shape as the existing entries.
    The date header is today UTC; tags and metrics start empty (the affinity
    machine fills `use`/`aff` later; tags are curated by humans)."""
    sha, goal, name, stmt = args[:4]
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    print(f"𝔸5.1.lemma.{sha[:12]}@{today}")
    print("γ≔unsorry.lemma.index")
    print(f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{goal}; name≜{name}}}")
    print("⟦Σ:Stmt⟧{")
    print(f"  stmt≜{stmt}")
    print("}")
    print("⟦Γ:Tags⟧{tags≜⟨⟩}")
    print("⟦Λ:Meta⟧{use≜0; aff≜0}")
    print("⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩")


def cmd_ttl(_args):
    print(config.TTL_SECONDS)


def cmd_attempts(_args):
    print(config.BUDGET_ATTEMPTS)


def cmd_aff_delta(args):
    """aff-delta merge|fail — print the affinity update for that event
    (⟦Γ:Affinity⟧; +1 / -10), so the shell never hardcodes the constant."""
    print(config.AFFINITY_MERGE if args[0] == "merge" else config.AFFINITY_FAIL)


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
    """render-decomp <parent> <agent> <sub-id> <sub-stmt> [<sub-id> <sub-stmt>…]
    — a SPEC-003-C decomposition record. Each sub gets an edge
    Post(subN) ⊆ Pre(parent): every sub is a prerequisite of the parent (a
    DAG; the parent still closes only through the kernel)."""
    parent, agent = args[0], args[1]
    pairs = args[2:]
    subs = [(pairs[i], pairs[i + 1]) for i in range(0, len(pairs), 2)]
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    print(f"𝔸5.1.decomp.{parent}.{agent}@{today}")
    print("γ≔unsorry.decomposition")
    print(f"⟦Ω:Decomp⟧{{parent≜{parent}; agent≜{agent}}}")
    print("⟦Σ:Subs⟧{")
    for i, (sub_id, stmt) in enumerate(subs, 1):
        print(f"  sub{_subscript(i)}≜⟨id≜{sub_id},stmt≜{stmt}⟩")
    print("}")
    print("⟦Γ:Edges⟧{")
    edges = "; ".join(
        f"Post(sub{_subscript(i)})⊆Pre(parent)" for i in range(1, len(subs) + 1)
    )
    print(f"  {edges}")
    print("}")
    print("⟦Λ:Requeue⟧{∀s∈subs:goal(s)≫status≔open}")
    print("⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩")


def cmd_unblockable(args):
    """unblockable <goals-dir> <decompositions-dir> <library-dir> — list blocked
    parent goals whose decomposition's sub-lemmas are ALL proved, so the parent
    can be re-opened (ADR-009). One goal id per line, lexicographic."""
    goals_dir, decomp_dir, library_dir = args[:3]
    proved = _proved_goals(library_dir)
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
    for path in sorted(Path(goals_dir).glob("*.aisp")):
        goal = path.stem
        record = parse_record(path.read_text(encoding="utf-8"))
        if record.fields.get("status") != "blocked":
            continue
        subs = parents.get(goal)
        if subs and subs <= proved:
            print(goal)


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
    "max-decomp": cmd_max_decomp,
    "goal-depth": cmd_goal_depth,
    "render-goal": cmd_render_goal,
    "render-decomp": cmd_render_decomp,
    "unblockable": cmd_unblockable,
    "camel-name": cmd_camel_name,
    "lean-stmt": cmd_lean_stmt,
    "lean-name": cmd_lean_name,
    "lean-sha": cmd_lean_sha,
    "prove-candidates": cmd_prove_candidates,
    "prove-claimable": cmd_prove_claimable,
    "render-index": cmd_render_index,
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

# ───────────────────────────── prove cycle (Phase 1) ─────────────────────────
# Reuses the claim / PR / release plumbing above; the prove arm differs only
# in the work (drive `claude` to write a Lean proof module) and verify
# (lake build --wfail ∧ axiom_audit ∧ check_library_options) steps.

PROVE_PROMPT_FILE="swarm/prompts/prove.md"
DECOMPOSE_PROMPT_FILE="swarm/prompts/decompose.md"
# ADR-009 decomposition on prove failure is on by default; UNSORRY_DECOMPOSE=0
# reverts to the Phase-1 demote-only failure path.
PROVE_DECOMPOSE="${UNSORRY_DECOMPOSE:-1}"

# Prove step 5: one claude call constrained to write the target Lean module.
# --max-turns does not exist on claude 2.1.170 (the translate cycle dropped it
# for the same reason); the $UNSORRY_WALL timeout bounds the call instead.
# Tools are limited to reading/editing/writing and the read-only lake/git
# commands the prover needs to check its own work (build, env, exe, diff).
call_claude_prove() {
  local prompt="$1" workdir="$2"
  ( cd "$workdir" \
    && timeout "$UNSORRY_WALL" claude -p "$prompt" \
         --model "$UNSORRY_MODEL" --output-format text \
         --allowedTools \
           "Read,Edit,Write,Bash(lake build *),Bash(lake env *),Bash(lake exe *),Bash(git diff *)" )
}

# Prove step 3: local soundness verification of a candidate proof tree, BEFORE
# any PR (the agent self-verifying per ADR-006 / design-doc step 6). All three
# must pass on the tree at <root> for module Unsorry.<camel>:
#   1. lake build UnsorryLibrary --wfail   (zero-sorry, zero-warning bar)
#   2. lake exe axiom_audit Unsorry.<camel> (whitelist only, NO --allow-sorry)
#   3. python3 -m tools.gate_a.check_library_options <root>/library
prove_local_verify() {
  local root="$1" camel="$2"
  ( cd "$root" \
    && lake build UnsorryLibrary --wfail \
    && lake exe axiom_audit "Unsorry.$camel" \
    && python3 -m tools.gate_a.check_library_options library ) >/dev/null 2>&1
}

# Prove steps 5–6: drive `claude` to write library/Unsorry/<camel>.lean proving
# the goal's theorem, then locally verify. Up to config.BUDGET_ATTEMPTS (2)
# attempts: on a failed build/audit the error is fed back to a fresh call once,
# then give up. The proof tree is a worktree at <prwt> branched from
# origin/main; on success it carries the proved module ready for check-in.
# Prints nothing; returns 0 with the verified module in place, 1 on failure.
run_proof() {
  local goal="$1" prwt="$2" camel="$3"
  local stmt name target prompt attempt err=""
  name="$(py_helper lean-name "$prwt/goals/$goal.lean")" || return 1
  stmt="$(py_helper lean-stmt "$prwt/goals/$goal.lean")" || return 1
  target="library/Unsorry/$camel.lean"
  # The PR worktree is a fresh checkout with no .lake (it is gitignored), so
  # the mathlib oleans are absent and `lake build UnsorryLibrary --wfail` would
  # otherwise recompile all of mathlib from source and blow the attempt budget
  # (observed in phase1-run-001). Restore the prebuilt cache once, up front.
  # Best-effort: a warm global cache makes this a ~20s no-op; on failure the
  # build still works, just slowly, so we warn rather than abort.
  if ! ( cd "$prwt" && lake exe cache get ) >/dev/null 2>&1; then
    log "warning: 'lake exe cache get' failed in the prove worktree for $goal — verification may be slow"
  fi
  for attempt in $(seq 1 "$UNSORRY_ATTEMPTS"); do  # config.BUDGET_ATTEMPTS
    prompt="$(cat "$PROVE_PROMPT_FILE")
$stmt

Target module file (relative to repo root): $target
Lean module name (for the audit): Unsorry.$camel
Theorem name to re-state and prove: $name"
    if [ -n "$err" ]; then
      prompt="$prompt

A previous attempt's module did NOT pass local verification. The combined
\`lake build UnsorryLibrary --wfail\` / \`lake exe axiom_audit Unsorry.$camel\`
output was:
$err
Fix the module so both pass. Write the corrected $target."
    fi
    rm -f "$prwt/$target"
    if ! call_claude_prove "$prompt" "$prwt" >/dev/null; then
      log "claude prove call failed or timed out for $goal (attempt $attempt)"
      err="(claude call failed or timed out)"
      continue
    fi
    if [ ! -f "$prwt/$target" ]; then
      log "prover did not write $target for $goal (attempt $attempt)"
      err="(no file was written at $target)"
      continue
    fi
    if prove_local_verify "$prwt" "$camel"; then
      log "proof of $goal verified locally (attempt $attempt)"
      return 0
    fi
    log "local verification of $goal failed (attempt $attempt)"
    err="$( ( cd "$prwt" && lake build UnsorryLibrary --wfail \
      && lake exe axiom_audit "Unsorry.$camel" ) 2>&1 | tail -n 40 )"
  done
  return 1
}

# Prove steps 7–9: on a verified proof, compute the goal's Lean-statement
# content address, write library/index/<sha>.aisp, flip the goal record to
# status≜proved + sha≜<sha>, and open an auto-merge PR carrying the library
# module + index entry + goal edit. Reuses submit_pr_tree (Gate B validate,
# commit, push, gh pr create/merge --auto --squash). The PR tree already holds
# the verified module (run_proof wrote it into <prwt>).
check_in_proof() {
  local goal="$1" prwt="$2" camel="$3"
  local name sha
  name="$(py_helper lean-name "$prwt/goals/$goal.lean")" || return 1
  sha="$(py_helper lean-sha "$prwt/goals/$goal.lean")" || return 1
  local stmt
  stmt="$(py_helper lean-stmt "$prwt/goals/$goal.lean")" || return 1

  mkdir -p "$prwt/library/index" || return 1
  py_helper render-index "$sha" "$goal" "$name" "$stmt" \
    > "$prwt/library/index/$sha.aisp" || return 1
  py_helper rewrite-goal "$prwt/goals/$goal.aisp" proved "$sha" || return 1
  # ⊕ a merge reinforces the goal's pattern (+1 affinity, ADR-010); folds
  # into the same gated prove PR.
  py_helper aff-bump "$prwt/goals/$goal.aisp" "$(py_helper aff-delta merge)" || return 1

  submit_pr_tree "$prwt" "$(git -C "$prwt" rev-parse --abbrev-ref HEAD)" \
    "prove($goal): $name by $AGENT_ID" \
    "Automated Phase-1 proof of goal \`$goal\` by agent \`$AGENT_ID\` (ADR-006, ADR-007, SPEC-007-A). New library module \`library/Unsorry/$camel.lean\` re-states and proves \`$name\`; built with \`lake build UnsorryLibrary --wfail\` and audited with \`lake exe axiom_audit Unsorry.$camel\` (whitelist only). Index entry keyed by the content address of the goal's Lean statement." \
    library goals || return 1
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
  local camel prwt branch ok=0
  camel="$(py_helper camel-name "$goal")" || return 1
  branch="$(feature_branch prove "$goal")" || return 1
  prwt="$UNSORRY_WORKDIR/prove-${goal}-${AGENT_ID}"

  open_pr_worktree "$prwt" "$branch" || return 1
  if run_proof "$goal" "$prwt" "$camel"; then
    if check_in_proof "$goal" "$prwt" "$camel"; then
      ok=1
    fi
  fi
  git worktree remove --force "$prwt" >/dev/null 2>&1 || true
  git branch -q -D "$branch" >/dev/null 2>&1 || true

  release_claim "$goal" || true
  if [ "$ok" -eq 1 ]; then
    return 0
  fi
  emit_event prove-failed "$goal"
  # ADR-009: a budget-exhausted goal is decomposed into claimable sub-lemmas and
  # parked `blocked`; the failed attempt now feeds the pool. If decomposition is
  # not possible (depth cap, or claude produced no usable split), fall back to
  # the ADR-010 affinity demote so the goal is at least deprioritised.
  if [ "$PROVE_DECOMPOSE" -eq 1 ] && decompose_goal "$goal"; then
    log "prove of $goal failed — decomposed into sub-lemmas, parent blocked (ADR-009)"
  else
    demote_goal "$goal" || true
    log "prove of $goal failed after $UNSORRY_ATTEMPTS attempt(s) — claim released, flagged, affinity -10"
  fi
  return 1
}

# ADR-009 / SPEC-009-A: on prove-budget exhaustion, drive `claude` to split the
# parent into 2..MAX_DECOMP_SUBS sub-lemmas, requeue each as a fresh open prove
# goal (src = the decomposition record, depth = parent+1), and park the parent
# `blocked`. Soundness is untouched: the parent only ever closes through Gate A
# using the subs; a non-composing split just wastes effort. Returns 0 only if a
# valid decomposition was committed as a PR; 1 (caller falls back to demote) if
# the depth cap is hit, claude produced nothing usable, the subs do not
# type-check, or any guardrail (≤ cap, strictly-smaller) rejects the split.
decompose_goal() {
  local goal="$1" depth maxdepth prwt branch stmt out i=0
  depth="$(py_helper goal-depth "goals/$goal.aisp")" || return 1
  maxdepth="$(py_helper max-decomp depth)" || return 1
  if [ "$depth" -ge "$maxdepth" ]; then
    log "decompose($goal): at depth $depth (cap $maxdepth) — not decomposing"
    return 1
  fi
  stmt="$(py_helper lean-stmt "goals/$goal.lean")" || return 1

  branch="$(feature_branch decompose "$goal")" || return 1
  prwt="$UNSORRY_WORKDIR/decompose-${goal}-${AGENT_ID}"
  open_pr_worktree "$prwt" "$branch" || return 1
  if ! ( cd "$prwt" && lake exe cache get ) >/dev/null 2>&1; then
    log "warning: 'lake exe cache get' failed in the decompose worktree for $goal"
  fi

  # Drive claude to propose sub-lemmas. Each `SUB:` line is a complete Lean
  # theorem signature (no proof). Other lines are ignored.
  out="$(cd "$prwt" && timeout "$UNSORRY_WALL" claude -p "$(cat "$DECOMPOSE_PROMPT_FILE")

PARENT THEOREM (the goal that resisted proof):
$stmt

Output 2 to $(py_helper max-decomp subs) sub-lemma signatures, one per \`SUB:\` line." \
    --model "$UNSORRY_MODEL" --output-format text --allowedTools "Read,Bash(lake build *),Bash(lake env *)" 2>/dev/null)"

  # Materialise the proposed subs into the PR tree.
  local -a sub_ids=() decomp_args=()
  local subline substmt subid subnorm
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
    sub_ids+=("$subid")
    decomp_args+=("$subid" "$subnorm")
  done <<< "$out"

  if [ "${#sub_ids[@]}" -lt 2 ]; then
    log "decompose($goal): claude produced ${#sub_ids[@]} usable sub(s) (need ≥2) — falling back"
    git worktree remove --force "$prwt" >/dev/null 2>&1 || true
    git branch -q -D "$branch" >/dev/null 2>&1 || true
    return 1
  fi

  py_helper render-decomp "$goal" "$AGENT_ID" "${decomp_args[@]}" \
    > "$prwt/decompositions/$goal.$AGENT_ID.aisp" 2>/dev/null || {
      mkdir -p "$prwt/decompositions" \
      && py_helper render-decomp "$goal" "$AGENT_ID" "${decomp_args[@]}" \
        > "$prwt/decompositions/$goal.$AGENT_ID.aisp"; }
  py_helper rewrite-goal "$prwt/goals/$goal.aisp" blocked || return 1

  # The sub statements must type-check as sorried goals (guardrail: a split that
  # does not even parse is worthless). Build only the goals package.
  if ! ( cd "$prwt" && lake build UnsorryGoals ) >/dev/null 2>&1; then
    log "decompose($goal): sub-lemmas do not type-check — falling back to demote"
    git worktree remove --force "$prwt" >/dev/null 2>&1 || true
    git branch -q -D "$branch" >/dev/null 2>&1 || true
    return 1
  fi

  if submit_pr_tree "$prwt" "$branch" \
      "decompose($goal): ${#sub_ids[@]} sub-lemmas by $AGENT_ID" \
      "Automated decomposition (ADR-009, SPEC-009-A): goal \`$goal\` resisted proof within budget, so it is split into ${#sub_ids[@]} claimable sub-lemmas (depth $((depth + 1))) and parked \`blocked\`. The parent re-opens once its subs are proved and still closes only through Gate A — the dependency edges are advisory, never a trust path." \
      goals decompositions; then
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
  local goal="$1" prwt branch
  branch="$(feature_branch demote "$goal")" || return 1
  prwt="$UNSORRY_WORKDIR/demote-${goal}-${AGENT_ID}"
  open_pr_worktree "$prwt" "$branch" || return 1
  if py_helper aff-bump "$prwt/goals/$goal.aisp" "$(py_helper aff-delta fail)"; then
    submit_pr_tree "$prwt" "$branch" \
      "affinity($goal): -10 after a failed prove attempt by $AGENT_ID" \
      "Automated affinity penalty (ADR-010, SPEC-010-A): goal \`$goal\` resisted proof within budget, so its pattern is demoted by 10. Advisory queue state only — never trust-bearing." \
      goals || true
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
  stmt="$(py_helper lean-stmt "$tree/goals/nat-add-zero-thm.lean")" || return 1
  py_helper render-index "$sha" nat-add-zero-thm nat_add_zero_thm "$stmt" \
    > "$tree/library/index/$sha.aisp" || return 1
  py_helper rewrite-goal "$tree/goals/nat-add-zero-thm.aisp" proved "$sha" || return 1
  python3 -m tools.gate_b validate "$tree" >/dev/null \
    || { log "  rendered index entry + proved goal failed Gate B"; return 1; }
}

# Set a prove goal's deps≜⟨⟩ to ⟨<csv>⟩ (test helper for gap ranking).
set_goal_deps() {
  local file="$1" csv="$2"
  sed -i "s/  deps≜⟨⟩/  deps≜⟨$csv⟩/" "$file"
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
  py_helper render-index "$sha" bbb bbb "$(py_helper lean-stmt "$tree/goals/bbb.lean")" \
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

test_affinity_bump_math() {
  # aff-bump inserts when absent, accumulates when present, and reflects the
  # configured +1 / −10 deltas.
  local tree merge fail
  tree="$(mktemp -d "$SESSION_TMP/affbump.XXXXXX")" || return 1
  make_prove_goal "$tree" g "theorem g (n : Nat) : n + 0 = n" || return 1
  grep -q 'aff≜' "$tree/goals/g.aisp" \
    && { log "  fresh goal should carry no aff field"; return 1; }
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
  printf 'theorem s2 (a b : Nat) : a + b = b + a := by sorry\n' > "$tree/goals/parent-s2.lean"
  py_helper render-decomp parent agent-x \
    parent-s1 "forall n, n + 0 = n" parent-s2 "forall a b, a + b = b + a" \
    > "$tree/decompositions/parent.agent-x.aisp" || return 1
  printf '# parent\n\nx\n' > "$tree/backlog/parent.md"
  python3 -m tools.gate_b validate "$tree" >/dev/null \
    || { log "  rendered decomposition + subs failed Gate B"; return 1; }
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
    test_camel_name
    test_lean_statement_helpers
    test_lean_sha_determinism
    test_prove_candidate_filtering
    test_already_proved_excluded
    test_goal_proved_rewrite
    test_render_index_gateb
    test_affinity_ranking
    test_gap_ranking
    test_viability_skip
    test_affinity_bump_math
    test_affinity_degrades_on_garbage
    test_decomp_caps_and_depth
    test_unblockable_detection
    test_render_decomp_gateb
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
ONCE=0
GOAL_FILTER=""
DRY_RUN=0
SELF_TEST=0

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --translate-only) TRANSLATE_ONLY=1 ;;
      --prove) PROVE=1 ;;
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

# Prove candidates for this iteration: same --goal / HANDLED filtering as the
# translate path, over the prove-candidate enumerator (phase≡prove, open,
# uncapped, not already proved).
select_prove_candidates() {
  local cand
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    if [ -n "$GOAL_FILTER" ] && [ "$cand" != "$GOAL_FILTER" ]; then
      continue
    fi
    [ -n "${HANDLED[$cand]:-}" ] && continue
    printf '%s\n' "$cand"
  done < <(py_helper prove-candidates goals "$CLAIMS_WT/claims" library "$AGENT_ID" "")
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

  if [ "$TRANSLATE_ONLY" -eq 1 ] && [ "$PROVE" -eq 1 ]; then
    die_config "--translate-only and --prove are mutually exclusive"
  fi
  [ "$TRANSLATE_ONLY" -eq 1 ] || [ "$PROVE" -eq 1 ] \
    || die_config "select a mode: --translate-only or --prove (or --self-test)"

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
  UNSORRY_ATTEMPTS="${UNSORRY_ATTEMPTS:-$(py_helper attempts)}"
  [[ "$UNSORRY_ATTEMPTS" =~ ^[1-9][0-9]*$ ]] \
    || die_config "UNSORRY_ATTEMPTS '$UNSORRY_ATTEMPTS' is not a positive integer"
  UNSORRY_WORKDIR="${UNSORRY_WORKDIR:-$HOME/.unsorry/work}"
  mkdir -p "$UNSORRY_WORKDIR" || die_config "cannot create UNSORRY_WORKDIR '$UNSORRY_WORKDIR'"

  resolve_agent_id
  if [ "$DRY_RUN" -eq 0 ]; then
    require_cmd claude gh
    gh auth status >/dev/null 2>&1 || die_config "gh is not authenticated"
    [ "$PROVE" -eq 1 ] && require_cmd lake  # prove verify builds locally
  fi

  local mode; [ "$PROVE" -eq 1 ] && mode=prove || mode=translate
  log "agent $AGENT_ID starting ($mode; model=$UNSORRY_MODEL wall=${UNSORRY_WALL}s ttl=${UNSORRY_TTL}s)"

  declare -A HANDLED=()
  declare -A SWEPT=()
  local overall=0 translations_dir candidates goal cand stmt cycle_failed

  while :; do
    # Step 1 — pull main, refresh the claims worktree.
    sync_repo || { log "repository sync failed"; exit 1; }

    # Steps 1b–3 — enumerate and select (mode-specific). The convergence
    # sweep is a translate-only janitor step; the unblock sweep is its prove
    # analogue (ADR-009): re-open blocked parents whose sub-lemmas are all proved.
    if [ "$PROVE" -eq 1 ]; then
      unblock_sweep || overall=1
      candidates="$(select_prove_candidates)"
    else
      translations_dir="$(main_translations_dir)" || exit 1
      convergence_sweep "$translations_dir" || overall=1
      candidates="$(select_candidates "$translations_dir")"
    fi
    if [ -z "$candidates" ]; then
      log "no claimable goal — nothing to do"
      break
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
      goal="$(printf '%s\n' "$candidates" | head -n 1)"
      printf 'dry-run: would claim goal %s (%s; %d candidate(s): %s)\n' \
        "$goal" "$mode" "$(printf '%s\n' "$candidates" | wc -l)" \
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

    # Steps 5–10 — work, check in, release (mode-specific). prove_goal owns
    # its own release + prove-failed handling; the translate arm is unchanged.
    cycle_failed=0
    if [ "$PROVE" -eq 1 ]; then
      prove_goal "$goal" || cycle_failed=1
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
