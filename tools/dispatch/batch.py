"""Combine K independent queued prove branches into one Gate A run (ADR-107, D1b).

Gate A's cost is dominated by a fixed, per-PR environment load — restoring the
~12–20 GB mathlib cache and building the existing library — paid once *per PR*
regardless of how many new proofs the PR adds (each extra proof is a cheap
incremental compile + a seconds-long nanoda check + its replay slice). So K
proofs verified in ONE PR cost ≈ one env-load + K·(small), versus K env-loads
when each rides its own PR. Batching amortises the dominant term: the lever that
lets a fixed verifier budget drain the queue K× faster (the @ohdearquant template
flood is the ideal first batch — homogeneous, low-risk, hundreds deep).

This module is the **pure decision core**; the git assembly + ``gh`` calls live in
``swarm/agent.sh`` (the I/O shell), mirroring ``tools/dispatch/fair_order.py``.

Two invariants the design rests on:

  * **Conflict-free by construction.** A queued prove branch adds only NEW,
    content-addressed files (``library/Unsorry/<Name>.lean``, ``library/index/
    <sha>.aisp``, ``goals/<goal>.{lean,aisp}``, ``proof-runs/…``). Two *distinct*
    goals therefore touch DISJOINT paths, so their commits cherry-pick onto one
    batch branch without conflict. ``select_batch`` still checks disjointness
    defensively and drops any colliding branch back to singleton dispatch.

  * **Soundness is untouched.** Gate A verifies every proof file in the combined
    PR exactly as it verifies a singleton — ``lake build`` compiles all of them,
    nanoda checks each leaf, replay covers every new olean. The Lean kernel still
    decides each proof independently; no proof trusts another (ADR-049, p=1).

Failure handling (``recover_action``): a batch is **all-or-nothing per PR**, so a
single bad proof reddens the whole batch. We then **redispatch its constituents
singly** — each gets an isolated verdict, the bad one is identified by its own red
gate, the K−1 good ones still merge. A batch that "failed" only because the merge
firehose CANCELLED a leg (the ADR-105 cascade) is **re-run**, not split — reusing
``finalization_recovery.gate_failure_is_cancellation`` so the two cases never
confuse. (ADR-105's janitor itself skips ``prove-batch(`` titles, so batch
recovery is owned here.)
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys

from tools.repo.finalization_recovery import gate_failure_is_cancellation

#: A one-line, machine-readable goal manifest carried in the batch PR body. It is
#: the dedup source of truth WHILE the batch PR is open: the dispatcher reads it
#: so it never opens a redundant singleton for an already-batched goal. (A
#: missing/garbled manifest only risks a redundant singleton — first-merge-wins
#: cleans that up — never unsoundness.)
MANIFEST_PREFIX = "Batch-Goals:"

#: Batch PR title prefix (NOT ``prove(`` — distinct so the governor's open-prove
#: count and ADR-105's same-repo arm/rerun janitor treat a batch as its own kind).
BATCH_TITLE_PREFIX = "prove-batch("


def _normalise(ref: str) -> str:
    return ref[len("origin/"):] if ref.startswith("origin/") else ref


def goal_of(ref: str) -> str:
    """``[origin/]queued/prove/<goal>/<agent>-<hex>`` -> ``<goal>``."""
    rest = _normalise(ref)
    if rest.startswith("queued/prove/"):
        rest = rest[len("queued/prove/"):]
    return rest.split("/", 1)[0]


def select_batch(refs, changed_files_of, max_size, *, exclude_goals=()):
    """Pick up to ``max_size`` refs to combine into ONE batch PR, in input order.

    ``refs`` arrives already in dispatch order (ADR-075/106), so the batch fills
    with the highest-priority eligible branches. A ref is skipped (left for
    singleton dispatch) when its goal is excluded or already picked.

    **Disjointness is keyed on the GOAL** — distinct goals add disjoint,
    content-addressed files by construction (the ADR-107 premise), so two distinct
    goals never write the same path. This is the only disjointness signal that is
    robust in the CI dispatcher's *shallow* checkout, where a per-branch file diff
    can't be computed (no merge-base / parent). ``changed_files_of`` is an
    OPPORTUNISTIC extra defence: when a ref's changed files ARE known (e.g. a full
    local clone) and COLLIDE with an already-picked ref, that ref is dropped; an
    empty/unknown file set is NOT a reason to skip (goal-distinctness already
    guarantees disjointness, and assembly's cherry-pick is the hard backstop for
    any true conflict).

    Pure and deterministic. Returns ``[]`` when ``max_size < 2`` (batching off) so
    the caller falls straight through to the singleton path.
    """
    if max_size < 2:
        return []
    excluded = set(exclude_goals)
    picked: list[str] = []
    taken_files: set[str] = set()
    seen_goals: set[str] = set()
    for ref in refs:
        if len(picked) >= max_size:
            break
        g = goal_of(ref)
        if g in excluded or g in seen_goals:
            continue
        files = set(changed_files_of.get(ref) or ())
        if files and files & taken_files:
            continue                      # known path collision ⇒ singleton it instead
        picked.append(ref)
        taken_files |= files
        seen_goals.add(g)
    return picked


def batch_branch_name(goals) -> str:
    """Deterministic batch branch from its goal SET: ``batch/prove/<12-hex>``.

    Content-addressed by the sorted goals so re-running an identical selection is
    idempotent — it targets the same branch, and an already-open PR for it is
    reused, never doubled. Distinct goal sets get distinct names (sha-256), so
    concurrent dispatchers batching different goals never collide on the ref."""
    digest = hashlib.sha256("\n".join(sorted(set(goals))).encode()).hexdigest()
    return f"batch/prove/{digest[:12]}"


def manifest_block(goals) -> str:
    """The ``Batch-Goals:`` manifest line for the PR body (inverse: parse_manifest)."""
    return MANIFEST_PREFIX + " " + " ".join(sorted(set(goals)))


def parse_manifest(body) -> list:
    """Goals from a batch PR body's ``Batch-Goals:`` line; ``[]`` if absent."""
    if not body:
        return []
    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith(MANIFEST_PREFIX):
            return stripped[len(MANIFEST_PREFIX):].split()
    return []


def open_batch_goals(prs) -> list:
    """All goals across the OPEN batch PRs in ``prs`` (``[{title, body}, …]``).

    Union of every ``prove-batch(`` PR's manifest — the dispatcher adds these to
    its dedup set so no singleton is opened for a goal already in a batch PR."""
    goals: list[str] = []
    for pr in prs:
        if str(pr.get("title", "")).startswith(BATCH_TITLE_PREFIX):
            goals.extend(parse_manifest(pr.get("body", "")))
    return goals


def recover_action(conclusion, jobs) -> str:
    """What to do with a batch PR's latest ``gate-a`` run.

    ``conclusion`` is the gate-a check conclusion; ``jobs`` its per-job
    conclusions (the ADR-105 shape). Returns:

      ``none``       green / still running / non-failure ⇒ leave it (auto-merge
                     fires on success).
      ``rerun``      failed ONLY via a cancelled leg (the firehose cascade) ⇒
                     re-run, do not split.
      ``redispatch`` a GENUINE failure (a bad proof, a policy block) ⇒ close the
                     batch and dispatch its constituents singly to isolate it.
    """
    concl = (conclusion or "").lower()
    if concl in ("", "success", "neutral", "skipped"):
        return "none"
    if concl == "cancelled":
        return "rerun"
    # failure / timed_out / action_required / stale: genuine unless it is purely a
    # cancelled-leg cascade of an otherwise-fine run.
    return "rerun" if gate_failure_is_cancellation(jobs) else "redispatch"


# ---------------------------------------------------------------------------
# I/O shell — thin CLI the dispatcher composes. Decision logic above stays pure.
# ---------------------------------------------------------------------------

def _changed_files(ref: str) -> list:
    """Paths a queued branch adds relative to main (its proof files). I/O."""
    branch = _normalise(ref)
    try:
        out = subprocess.run(
            ["git", "diff", "--name-only", f"origin/main...origin/{branch}"],
            capture_output=True, text=True, check=True,
        ).stdout
    except Exception:
        return []
    return [ln for ln in out.splitlines() if ln.strip()]


def _read_lines(stream) -> list:
    return [ln.rstrip("\n") for ln in stream if ln.strip()]


def main(argv=None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    cmd = argv[0] if argv else ""
    rest = argv[1:]

    def _opt(flag, default=None):
        return rest[rest.index(flag) + 1] if flag in rest and rest.index(flag) + 1 < len(rest) else default

    if cmd == "select":
        refs = _read_lines(sys.stdin)
        try:
            max_size = int(_opt("--max", "1"))
        except ValueError:
            max_size = 1
        exclude: set[str] = set()
        ef = _opt("--exclude-file")
        if ef:
            try:
                with open(ef, encoding="utf-8") as handle:
                    exclude = {ln.strip() for ln in handle if ln.strip()}
            except OSError:
                exclude = set()
        changed = {ref: _changed_files(ref) for ref in refs}
        for ref in select_batch(refs, changed, max_size, exclude_goals=exclude):
            print(ref)
        return 0

    if cmd == "meta":
        refs = _read_lines(sys.stdin)
        goals = [goal_of(r) for r in refs]
        print(batch_branch_name(goals))   # line 1: branch
        print(manifest_block(goals))       # line 2: manifest
        return 0

    if cmd == "manifest-goals":
        try:
            data = json.load(sys.stdin)
        except json.JSONDecodeError:
            data = []
        for g in open_batch_goals(data if isinstance(data, list) else []):
            print(g)
        return 0

    if cmd == "parse-manifest":
        # A single PR body on stdin -> its Batch-Goals: goals (the janitor's
        # redispatch path reads one batch PR's manifest at a time).
        for g in parse_manifest(sys.stdin.read()):
            print(g)
        return 0

    if cmd == "recover":
        try:
            jobs = json.load(sys.stdin)
        except json.JSONDecodeError:
            jobs = []
        print(recover_action(_opt("--conclusion", ""), jobs if isinstance(jobs, list) else []))
        return 0

    print(
        "usage: tools.dispatch.batch {select --max N [--exclude-file F] | meta | "
        "manifest-goals | recover --conclusion C}",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
