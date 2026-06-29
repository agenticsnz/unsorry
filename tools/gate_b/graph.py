"""Shared decomposition-graph helpers for AISP coordination records.

Pure, stdlib-only parsing and DAG primitives for the ``⟦Σ:Subs⟧`` content-addressed
sub references and ``⟦Γ:Edges⟧`` dependency edges of a decomposition record (ADR-009).
Factored out of :mod:`tools.gate_b.validator` so the curated-package intake validator
(:mod:`tools.intake.skeleton_validate`, SPEC-081-A) reuses the *exact* same regexes and
cycle check rather than copying them — one authoritative representation of "what an
edge is" and "what a cycle is" (DRY). No policy lives here; codes and severities belong
to the callers.
"""
from __future__ import annotations

import re

# Subs reference their statement by content address, never inline: the record
# grammar reserves {} for block delimiters, and real Lean statements contain
# braces (Finset literals — the platonic-schlafli-core regression).
SUB_RE = re.compile(
    r"(?P<label>sub[^≜\s;]*)≜⟨id≜(?P<id>[^,⟩\s]+)\s*,\s*sha≜(?P<sha>[^⟩\s]+)⟩"
)
EDGE_RE = re.compile(r"Post\((?P<src>[^)]*)\)\s*⊆\s*Pre\((?P<dst>[^)]*)\)")


def has_cycle(edges: list[tuple[str, str]]) -> bool:
    """True if the directed edge set (src enables dst) contains a cycle.

    ``Post(A)⊆Pre(B)`` means A is a prerequisite of B, i.e. an edge A→B; a
    decomposition's dependency graph must be a DAG (ADR-009).
    """
    adj: dict[str, list[str]] = {}
    for src, dst in edges:
        adj.setdefault(src, []).append(dst)
    WHITE, GREY, BLACK = 0, 1, 2
    colour: dict[str, int] = {}

    def visit(node: str) -> bool:
        colour[node] = GREY
        for nxt in adj.get(node, []):
            c = colour.get(nxt, WHITE)
            if c == GREY or (c == WHITE and visit(nxt)):
                return True
        colour[node] = BLACK
        return False

    return any(colour.get(n, WHITE) == WHITE and visit(n) for n in list(adj))
