"""PR label classifier tests — the taxonomy is empirical (every shape below
exists in the repo's PR history)."""
from __future__ import annotations

from tools.repo.pr_labels import classify, diagnose, is_conforming


def test_swarm_surfaces():
    assert classify("tr(nat-add-assoc): translation by trial-alpha") == ["swarm:translate"]
    assert classify("converge(nat-mul-one): matched by trial-bravo") == ["swarm:translate"]
    assert classify("prove(nicomachus-sum-cubes): nicomachus_sum_cubes by e-alpha") == ["swarm:prove"]
    assert classify("decompose(platonic-schlafli-core): split into 3 subs by p3-alpha") == ["swarm:decompose"]
    assert classify("unblock(am-gm-three-cube): sub-lemmas proved, re-opening (ADR-009)") == ["swarm:unblock"]
    assert classify("affinity(platonic-schlafli-core): -10 after a failed prove attempt by p3-alpha") == ["swarm:demote"]


def test_red_team_rounds():
    assert classify("redteam(bare-sorry): attempt to bypass Gate A") == ["red-team"]
    assert classify("redteam2(vacuous-true): probe the binding gate") == ["red-team"]


def test_release_and_docs():
    assert classify("docs(v1.2.0): first mathlib-absent lemma proved") == ["release"]
    assert classify("docs: mathlib upstream path plan (thread C)") == ["docs"]
    assert classify("docs: Phase-2 target run (run 001)") == ["docs", "metrics"]
    assert classify("docs: Phase-0 trial metrics (run 001)") == ["docs", "metrics"]
    assert classify("docs: Gate A red-team round 001 evidence") == ["docs", "metrics"]
    assert classify("docs: binding red-team round 002") == ["docs", "metrics"]


def test_conventional():
    assert classify("feat: model/effort policy for proof runs (ADR-013)") == ["feat"]
    assert classify("fix: decomposition records reference statements by sha (brace-safe)") == ["fix"]
    assert classify("chore: restore platonic-schlafli-core affinity (spurious demote)") == ["chore"]


def test_extended_conventional_types_and_scopes():
    # ADR-026: the full Conventional-Commits set is first-class so machinery PRs
    # are not rejected by the convention gate.
    assert classify("ci: enforce PR title conventions (ADR-026)") == ["ci"]
    assert classify("test: cover run_proof path guard end to end") == ["test"]
    assert classify("refactor: extract the provider adapter") == ["refactor"]
    assert classify("perf: parallelise the axiom audit") == ["perf"]
    assert classify("build: bump the pinned toolchain") == ["build"]
    assert classify("feat(swarm): with a scope") == ["feat"]
    assert classify("fix!: a breaking fix") == ["fix"]


def test_conventional_requires_the_colon():
    # A prose title that merely starts with a type word is not a typed change.
    assert classify("fixed the flaky test") == []
    assert classify("featuring a new idea") == []


def test_swarm_and_redteam_require_the_colon():
    # The documented contract is `prove(<goal>): …`; a missing colon is malformed
    # and must be rejected by the gate, not silently accepted.
    assert classify("prove(goal)") == []
    assert classify("prove(goal) no colon here") == []
    assert classify("decompose(goal) missing colon") == []
    assert classify("redteam(vector) no colon") == []
    assert not is_conforming("prove(goal)")
    assert is_conforming("prove(goal): the_thm by agent-1")


def test_unknown_title_gets_no_labels():
    assert classify("something nonconforming entirely") == []


def test_bracket_prefix_is_rejected_with_a_targeted_hint():
    # A leading [codex]/[tool] prefix pushes the conventional type out of first
    # position, so the title is (correctly) nonconforming — but the diagnostic
    # must name the exact fix so agents that read CI output self-correct.
    assert not is_conforming("[codex] ci: add queued proof dispatcher")
    hint = diagnose("[codex] ci: add queued proof dispatcher")
    assert "[codex]" in hint and "ci: add queued proof dispatcher" in hint
    # No hint for a conforming title, or for a title that is broken some other way.
    assert diagnose("ci: add queued proof dispatcher") == ""
    assert diagnose("totally nonconforming title") == ""


def test_enforce_gate_accepts_known_shapes_rejects_prose():
    # ADR-026: the CI gate is exactly "classify is non-empty".
    assert is_conforming("prove(nat-add-comm): nat_add_comm by agent-1")
    assert is_conforming("decompose(hard-goal): split into 3 subs by agent-2")
    assert is_conforming("unblock(hard-goal): sub-lemmas proved, re-opening (ADR-009)")
    assert is_conforming("affinity(hard-goal): -10 after a failed prove attempt by agent-2")
    assert is_conforming("fix: a real bug")
    assert is_conforming("ci: a new gate")
    assert is_conforming("docs(v2.0.0): release")
    assert not is_conforming("random unscoped title")
    assert not is_conforming("update stuff")
    assert not is_conforming("")
