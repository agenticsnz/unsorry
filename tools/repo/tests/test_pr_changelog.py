"""Tests for the changelog-fragment advisory (ADR-040).

The advisory reminds a contributor when a *user-facing harness change* lands
without a `changelog.d/` fragment. It must never fire on the swarm's proof
traffic (the overwhelming majority of PRs), and it is advisory only — it never
blocks a PR.
"""
from __future__ import annotations

from tools.repo.pr_changelog import check, has_fragment, needs_fragment


# --- exemptions: the swarm and its housekeeping never need a fragment ----------

def test_proof_pr_is_exempt():
    # A proof PR touches only the proof surface — never the harness — so it can
    # never trigger the advisory regardless of its title.
    assert not needs_fragment(
        "prove(nicomachus-sum-cubes): nicomachus_sum_cubes by binto-labs",
        ["library/Unsorry/Nicomachus.lean", "library/index/abc.aisp", "goals/foo.aisp"],
    )


def test_swarm_decompose_affinity_exempt():
    assert not needs_fragment("decompose(foo): split", ["goals/foo-s1.aisp", "goals/foo.aisp"])
    assert not needs_fragment("affinity(foo): -10", ["goals/foo.aisp"])


def test_release_and_docs_refresh_exempt():
    # Release housekeeping consumes fragments, it does not add them; bot docs
    # refreshes touch only neutral doc paths.
    assert not needs_fragment("docs(v1.13.0): release", ["CHANGELOG.md", "docs/leaderboard.md"])
    assert not needs_fragment("docs: refresh leaderboard", ["docs/leaderboard.md"])


def test_unknown_title_shape_exempt():
    # Nonconforming titles are the pr-conventions gate's job, not ours.
    assert not needs_fragment("just some words", ["tools/repo/foo.py"])


def test_user_facing_type_but_no_harness_surface_exempt():
    assert not needs_fragment("fix: correct a typo", ["README.md", "docs/recovery.md"])


def test_pure_test_change_is_exempt():
    # A test-only change is not user-facing — no nag.
    assert not needs_fragment("test(gate-a): add coverage", ["tools/gate_a/tests/test_x.py"])


# --- the advisory fires: user-facing harness change, no fragment --------------

def test_harness_fix_without_fragment_advises():
    assert needs_fragment(
        "fix(gate-a): suppress unusedVariables lint",
        ["tools/gate_a/check_statement_binding.py", "tools/gate_a/tests/test_check_statement_binding.py"],
    )


def test_harness_feat_without_fragment_advises():
    assert needs_fragment("feat(swarm): add --foo flag", ["swarm/agent.sh"])


def test_ci_workflow_change_without_fragment_advises():
    assert needs_fragment("ci(gate-a): bump runner", [".github/workflows/gate-a.yml"])


# --- the advisory is silenced once a fragment is present ----------------------

def test_harness_change_with_fragment_is_silent():
    assert not needs_fragment(
        "feat(ci): advisory changelog check",
        ["tools/repo/pr_changelog.py", "changelog.d/added-changelog-advisory-445.md"],
    )


def test_readme_in_changelog_dir_is_not_a_fragment():
    # changelog.d/README.md is documentation, not a fragment — it must not
    # silence the advisory.
    assert needs_fragment("fix(ci): x", ["tools/repo/foo.py", "changelog.d/README.md"])


# --- has_fragment helper ------------------------------------------------------

def test_has_fragment_helper():
    assert has_fragment(["changelog.d/added-foo-1.md"])
    assert has_fragment(["tools/x.py", "changelog.d/fixed-bar-2.md"])
    assert not has_fragment(["changelog.d/README.md"])
    assert not has_fragment(["tools/x.py"])
    assert not has_fragment([])


# --- check(): advisory message, never raises ----------------------------------

def test_check_returns_advisory_message_when_missing():
    msgs = check("fix(swarm): behaviour change", ["swarm/agent.sh"])
    assert len(msgs) == 1
    assert "changelog.d/" in msgs[0]
    assert "ADR-040" in msgs[0]


def test_check_is_silent_when_exempt_or_satisfied():
    assert check("prove(foo): bar", ["library/Unsorry/Foo.lean"]) == []
    assert check("feat(ci): x", ["tools/x.py", "changelog.d/added-x-445.md"]) == []
