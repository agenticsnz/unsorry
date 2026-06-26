"""Order queued prove branches for the governed dispatcher (ADR-075 + ADR-106).

The queue-dispatcher (`swarm/agent.sh --dispatch-queue`) opens at most
`UNSORRY_DISPATCH_LIMIT` queued `queued/prove/*` branches as PRs per pass, so the
*order* it reads them in decides what merges first while the governor is capped.
Two reorderings compose here, both pure and both reversible by an env flag:

  * ADR-075 — **per-solver round-robin** (max-min fairness): one branch per
    active solver per round, so a single high-volume contributor (the
    @ohdearquant template flood, ~hundreds of `g…` goals) can't monopolise every
    governed slot while small backlogs starve. ``UNSORRY_FAIR_DISPATCH=0`` reverts.

  * ADR-106 — **difficulty deprioritisation**: a measured supply imbalance
    (2026-06-26) showed the queue dominated by low-difficulty *template* proofs
    (`template-*`, `ring`, `zmod-decide`, …) — which the leaderboard already
    difficulty-discounts — crowding out genuinely hard work (the v2.0.0 benchmark
    suites). So branches are partitioned into difficulty TIERS by their queue-board
    ``model`` and the high tier is dispatched (fairly, ADR-075 within the tier)
    *before* the low tier. High-difficulty and unknown-model branches are never
    deprioritised (fail-safe: only KNOWN-trivial models yield priority).
    ``UNSORRY_DIFFICULTY_DISPATCH=0`` reverts to fairness-only.

Soundness is untouched — this only REORDERS refs. Dedup (ADR-064/071), the
governor (ADR-058) and Gate A still decide what is dispatched and what merges.

The ordering functions are pure (refs + board maps in, ordered refs out) so they
are unit-tested without git; the thin ``main`` reads the board and refs via I/O.
"""
from __future__ import annotations

import collections
import json
import os
import subprocess
import sys

#: A queue-board ``model`` is LOW difficulty (deprioritised) iff it is a template
#: generator or a known trivial closed-form tactic. Matched case-insensitively as
#: a substring set so labels like ``template-ring-cofactor`` / ``python / sympy``
#: / ``lean/decide`` all classify. Anything else — and any branch with no model —
#: is HIGH (never deprioritised). Keep in step with the leaderboard's difficulty
#: discounting; extend here when a new trivial template model appears.
LOW_DIFFICULTY_MARKERS = (
    "template",
    "decide",
    "sympy",
    "ring",
    "norm_num",
    "norm-num",
)


def is_low_difficulty(model: str | None) -> bool:
    """True iff this queue-board model is a known low-difficulty template/tactic."""
    if not model:
        return False                       # unknown ⇒ HIGH (never deprioritise blindly)
    m = model.lower()
    return any(marker in m for marker in LOW_DIFFICULTY_MARKERS)


def _normalise(ref: str) -> str:
    return ref[len("origin/"):] if ref.startswith("origin/") else ref


def token_key(ref: str) -> str:
    """Fallback solver key from the branch name when the board lacks it:
    ``[origin/]queued/prove/<goal>/<agent-id>-<hex>`` -> ``agent:<agent-id>``."""
    seg = ref.rsplit("/", 1)[-1]
    return "agent:" + (seg.rsplit("-", 1)[0] if "-" in seg else seg)


def solver_key(ref: str, solver_map: dict) -> str:
    """Authoritative solver key from the queue board, else the branch token."""
    return solver_map.get(_normalise(ref)) or token_key(ref)


def round_robin(refs, solver_map) -> list:
    """ADR-075 per-solver round-robin over ``refs`` (input order preserved within
    each solver's bucket). Deterministic: buckets are visited in sorted-key order,
    round i emits the i-th branch of every bucket that still has one."""
    buckets: "collections.OrderedDict[str, list]" = collections.OrderedDict()
    for ref in refs:
        buckets.setdefault(solver_key(ref, solver_map), []).append(ref)
    order = sorted(buckets)
    out: list = []
    i = 0
    while True:
        progressed = False
        for k in order:
            lst = buckets[k]
            if i < len(lst):
                out.append(lst[i])
                progressed = True
        if not progressed:
            break
        i += 1
    return out


def order_refs(refs, solver_map, model_map, *, difficulty: bool = True) -> list:
    """The full dispatch order: ADR-106 difficulty tiers (high before low), with
    ADR-075 per-solver round-robin applied WITHIN each tier. ``difficulty=False``
    falls back to a single round-robin over all refs (ADR-075 only)."""
    if not difficulty:
        return round_robin(refs, solver_map)
    high = [r for r in refs if not is_low_difficulty(model_map.get(_normalise(r)))]
    low = [r for r in refs if is_low_difficulty(model_map.get(_normalise(r)))]
    return round_robin(high, solver_map) + round_robin(low, solver_map)


# ---------------------------------------------------------------------------
# I/O shell
# ---------------------------------------------------------------------------

def board_maps():
    """(solver_map, model_map) keyed by normalised branch, from the authoritative
    queue board on origin/main (ADR-066). Any error ⇒ empty maps (degrade to the
    token-key fairness + no difficulty signal — i.e. lexical for unknown)."""
    try:
        out = subprocess.run(["git", "show", "origin/main:docs/queue.json"],
                             capture_output=True, text=True, check=True).stdout
        data = json.loads(out)
    except Exception:
        return {}, {}
    solver_map: dict = {}
    model_map: dict = {}
    for grp in data.get("solvers", []):
        key = grp.get("github") or grp.get("solver") or "unknown"
        for e in grp.get("queued", []):
            b = e.get("branch")
            if not b:
                continue
            solver_map[b] = "solver:" + key
            if e.get("model"):
                model_map[b] = e["model"]
    return solver_map, model_map


def main(argv=None) -> int:
    refs = [ln.rstrip("\n") for ln in sys.stdin if ln.strip()]
    fair = os.environ.get("UNSORRY_FAIR_DISPATCH", "1") != "0"
    difficulty = os.environ.get("UNSORRY_DIFFICULTY_DISPATCH", "1") != "0"
    if not fair:
        # ADR-075 disabled ⇒ verbatim passthrough (legacy lexical order).
        ordered = refs
    else:
        solver_map, model_map = board_maps()
        ordered = order_refs(refs, solver_map, model_map, difficulty=difficulty)
    try:
        for r in ordered:
            print(r)
        sys.stdout.flush()
    except BrokenPipeError:
        # The consumer (dispatch_queue's read loop) closes the pipe once it hits
        # its dispatch limit; the unread refs are exactly the ones it chose not to
        # act on, so a short read is normal. Silence the shutdown-time re-raise.
        os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
