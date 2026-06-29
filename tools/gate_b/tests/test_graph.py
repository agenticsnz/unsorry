"""Unit tests for the shared decomposition-graph helpers (tools.gate_b.graph).

These pin the regexes and the DAG check that both Gate B
(:mod:`tools.gate_b.validator`) and the intake validator
(:mod:`tools.intake.skeleton_validate`, SPEC-081-A) depend on.
"""
from __future__ import annotations

from tools.gate_b.graph import EDGE_RE, SUB_RE, has_cycle

SHA = "a" * 64


# ------------------------------------------------------------------- sub refs


def test_sub_re_captures_label_id_sha():
    match = SUB_RE.search(f"sub₁≜⟨id≜nat-sq-lt-two-pow-s1,sha≜{SHA}⟩")
    assert match is not None
    assert match.group("label") == "sub₁"
    assert match.group("id") == "nat-sq-lt-two-pow-s1"
    assert match.group("sha") == SHA


def test_sub_re_finds_all_subs_in_a_body():
    body = f"sub₁≜⟨id≜foo-s1,sha≜{SHA}⟩\nsub₂≜⟨id≜foo-s2,sha≜{SHA}⟩"
    ids = [m.group("id") for m in SUB_RE.finditer(body)]
    assert ids == ["foo-s1", "foo-s2"]


# --------------------------------------------------------------------- edges


def test_edge_re_captures_src_dst():
    match = EDGE_RE.search("Post(sub₁)⊆Pre(parent)")
    assert match is not None
    assert match.group("src") == "sub₁"
    assert match.group("dst") == "parent"


# ----------------------------------------------------------------- has_cycle


def test_empty_graph_is_acyclic():
    assert has_cycle([]) is False


def test_chain_is_acyclic():
    assert has_cycle([("a", "b"), ("b", "c")]) is False


def test_diamond_is_acyclic():
    assert has_cycle([("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")]) is False


def test_simple_cycle_detected():
    assert has_cycle([("a", "b"), ("b", "a")]) is True


def test_self_loop_detected():
    assert has_cycle([("a", "a")]) is True


def test_cycle_in_larger_graph_detected():
    assert has_cycle([("a", "b"), ("b", "c"), ("c", "b")]) is True
