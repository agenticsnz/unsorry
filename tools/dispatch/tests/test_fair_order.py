"""Tests for the dispatch ordering (ADR-075 round-robin + ADR-106 difficulty)."""
from __future__ import annotations

import io

import pytest

from tools.dispatch.fair_order import (
    is_low_difficulty,
    order_refs,
    round_robin,
    solver_key,
    token_key,
)


# --- difficulty classification ---------------------------------------------

@pytest.mark.parametrize("model", [
    "template-ring-cofactor", "template-induction-ring", "template-zmod-decide",
    "ring", "python / sympy", "lean/decide", "norm_num",
])
def test_known_template_tactics_are_low(model):
    assert is_low_difficulty(model) is True


@pytest.mark.parametrize("model", [
    "claude-opus-4-8", "gpt-5", "codex", "lean/aesop-search", None, "",
])
def test_genuine_and_unknown_models_are_high(model):
    # unknown / absent model must NOT be deprioritised (fail-safe)
    assert is_low_difficulty(model) is False


# --- solver key -------------------------------------------------------------

def test_token_key_from_branch():
    assert token_key("queued/prove/g1/mac-158f-4d5146") == "agent:mac-158f"
    assert token_key("origin/queued/prove/g2/claude-web-abc123") == "agent:claude-web"


def test_solver_key_prefers_board():
    smap = {"queued/prove/g1/mac-158f-4d5146": "solver:ohdearquant"}
    assert solver_key("origin/queued/prove/g1/mac-158f-4d5146", smap) == "solver:ohdearquant"
    assert solver_key("origin/queued/prove/g9/x-1", smap) == "agent:x"  # fallback


# --- ADR-075 round-robin (preserved) ---------------------------------------

def test_round_robin_interleaves_solvers():
    refs = ["queued/prove/a/s1-1", "queued/prove/b/s1-2", "queued/prove/c/s1-3",
            "queued/prove/d/s2-1"]
    smap = {}  # token keys: s1 thrice, s2 once
    out = round_robin(refs, smap)
    # round 0: one from each solver (sorted keys agent:s1, agent:s2); then s1's rest
    assert out[0] == "queued/prove/a/s1-1"
    assert out[1] == "queued/prove/d/s2-1"
    assert out[2:] == ["queued/prove/b/s1-2", "queued/prove/c/s1-3"]


def test_round_robin_one_branch_per_solver_per_round_prevents_starvation():
    # a flood of 5 from one solver + 1 from another: the small backlog clears in round 0.
    refs = [f"queued/prove/g{i}/flood-{i}" for i in range(5)] + ["queued/prove/h/small-1"]
    out = round_robin(refs, {})
    assert out[1] == "queued/prove/h/small-1"  # small solver served in the first round


# --- ADR-106 difficulty tiers ----------------------------------------------

def _br(goal, solver, n):
    return f"queued/prove/{goal}/{solver}-{n}"


def test_high_difficulty_dispatched_before_low():
    refs = [_br("tmpl1", "flood", 1), _br("hard1", "alice", 1), _br("tmpl2", "flood", 2)]
    model_map = {_br("tmpl1", "flood", 1): "template-ring-cofactor",
                 _br("tmpl2", "flood", 2): "template-zmod-decide",
                 _br("hard1", "alice", 1): "claude-opus-4-8"}
    out = order_refs(refs, {}, model_map, difficulty=True)
    assert out[0] == _br("hard1", "alice", 1)              # high tier first
    assert set(out[1:]) == {_br("tmpl1", "flood", 1), _br("tmpl2", "flood", 2)}


def test_fairness_preserved_within_each_tier():
    # two solvers both with hard work: round-robin still interleaves them in the high tier
    refs = [_br("h1", "alice", 1), _br("h2", "alice", 2), _br("h3", "bob", 1)]
    model_map = {b: "gpt-5" for b in refs}  # all high
    out = order_refs(refs, {}, model_map, difficulty=True)
    assert out[0] == _br("h1", "alice", 1)
    assert out[1] == _br("h3", "bob", 1)                  # bob served in round 0 (fairness)
    assert out[2] == _br("h2", "alice", 2)


def test_unknown_model_is_high_not_deprioritised():
    refs = [_br("known_tmpl", "f", 1), _br("no_model", "f", 2)]
    model_map = {_br("known_tmpl", "f", 1): "template-ring-cofactor"}  # other absent
    out = order_refs(refs, {}, model_map, difficulty=True)
    assert out[0] == _br("no_model", "f", 2)              # unknown ⇒ high ⇒ first
    assert out[1] == _br("known_tmpl", "f", 1)


def test_difficulty_disabled_falls_back_to_pure_round_robin():
    refs = [_br("tmpl1", "flood", 1), _br("hard1", "alice", 1)]
    model_map = {_br("tmpl1", "flood", 1): "template-ring-cofactor"}
    out = order_refs(refs, {}, model_map, difficulty=False)
    assert out == round_robin(refs, {})  # no tier partition


def test_order_is_a_permutation():
    refs = [_br(f"g{i}", "s", i) for i in range(10)]
    model_map = {refs[i]: "template-ring" for i in range(0, 10, 2)}  # half low
    out = order_refs(refs, {}, model_map, difficulty=True)
    assert sorted(out) == sorted(refs)  # every ref appears exactly once
